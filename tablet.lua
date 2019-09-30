local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local term = require("term")
local keyboard = require("keyboard")
local gpu = component.gpu
local modem = component.modem
local args = {...}
local pairedCard, port = "", 0
local tablet

if not component.isAvailable("modem") then
	io.stderr:write("This program requires network card!")
end
if component.isAvailable("tablet") then
    tablet = component.tablet
end
if component.isAvailable("internet") then
    internet = component.internet
end
if computer.getArchitecture() == "Lua 5.2" then
    io.write("This program requires Lua 5.3. Install? [Y/n] ")
    local enter = io.read()

    if enter and (unicode.lower(enter) == "y" or enter == "") then
        computer.setArchitecture("Lua 5.3")
    else
        os.exit()
    end
end

local language = {
    RU = {
        help = "Помощь —",
        exit = "Выход —",

        side = {
            [0] = "Низ",
            "Верх",
            "Север",
            "Юг",
            "Запад",
            "Восток"
        },

        droneInfo = {
            "Ускорение:",
            "Активная сторона:",
            "Активный слот:",
            "Расстояние до дрона:",
            "Кол-во вещей в активном слоте:"
        },

        fullHelp = {
            "Перемещение — WASD",
            "Вверх/Вниз — LSHIFT/LCTRL",
            "Сломать/Установить блок — Z/X",
            "Забрать/Выбросить вещи из активной стороны — R/F",
            "Захватить/Отцепить ближайших существ — С/V",
            "Открыть/Закрыть интерпретатор — I/CTRL+D",
            "Включить/Выключить дрона — P",
            "Увеличить/Уменьшить силу сигнала — +/-",
            "Смена ускорения — B",
            "Активный слот — 1-8",
            "Активная сторона — ALT+0-5",
            "Установить цвет дрона на случайный — L",
            "Принудительно обновить данные — E",
            "Вернуть дрона домой — G",
            "Перезагрука дрона — O",
            "Перемещение по координатам — N",
            "Односимвольный экран — M",
            "Отвязать дрона — CTRL+ALT+U",
            exit = "Чтобы закрыть нажмите"
        },

        coordsMove = {
            x = "Введите X:",
            z = "Введите Z:",
            dX = "Ведите dX:",
            dZ = "Введите dZ:",
            y = "Введите безопасную высоту:",
            moving = "Перемещение...",
            invalidInput = "Неправильный ввод, пожалуйста, повторите ещё раз."
        }
    },

    EN = {
        help = "Help —",
        exit = "Exit —",

        side = {
            [0] = "Down",
            "Up",
            "North",
            "South",
            "West",
            "East"
        },

        droneInfo = {
            "Acceleration:",
            "Active side:",
            "Active slot:",
            "Distance to drone:",
            "Items in active slot:"
        },

        fullHelp = {
            "Move — WASD",
            "Up/Down — LSHIFT/LCTRL",
            "Break/Place block — Z/X",
            "Take/Drop — R/F",
            "Leash/Unleash — С/V",
            "Open/Close interpreter — I/CTRL+D",
            "Enable/Disable drone — P",
            "Increase/Reduce modem strength — +/-",
            "Change acceleration — B",
            "Active slot — 1-8",
            "Active side — ALT+0-5",
            "Random color — L",
            "Force update — E",
            "Back to home — G",
            "Reboot drone — O",
            "Move by coords — N",
            "One pixel screen — M",
            "Unpair — CTRL+ALT+U",
            exit = "To close press"
        },

        coordsMove = {
            x = "Enter X:",
            z = "Enter Z:",
            dX = "Enter dX:",
            dZ = "Enter dZ:",
            y = "Enter safe height:",
            moving = "Moving...",
            invalidInput = "Invalind input, please try again"
        }
    }
}

local stuff = {
    timezone = 3, --gmt+3
    language = "EN", 
    --do not change!!!
    work = true,
    write = false,
    helpIsDrawed = false,
    hide = false,
    strength = 20,

    drone = {
        x = 60,
        y = 3,
        {x = 2, y = 1},
        {x = 2, y = 6},
        {x = 12, y = 1},
        {x = 12, y = 6}
    }
}

local color = {
    white = 0xffffff,
    black  = 0x000000,
    lime = 0x7fcc19,
    orange = 0xf2b233,
    gray = 0x3c3c48,
    lightGray = 0xe5e5e5,
    blue = 0x269fd8
}

local droneData = {
    false, --acceleration
    false, --activeSide
    false, --activeSlot
    false, --distance
    false, --items

    color = color.gray,
    charge = 0
}

local facings = {
    [0] = {
        front = {x = -1, z = 0},
        back = {x = 1, z = 0},
        left = {x = 0, z = 1},
        right = {x = 0, z = -1}
    },
    {
        front = {x = 0, z = -1},
        back = {x = 0, z = 1},
        left = {x = -1, z = 0},
        right = {x = 1, z = 0}
    },
    {
        front = {x = 1, z = 0},
        back = {x = -1, z = 0},
        left = {x = 0, z = -1},
        right = {x = 0, z = 1}
    },
    {
        front = {x = 0, z = 1},
        back = {x = 0, z = -1},
        left = {x = 1, z = 0},
        right = {x = -1, z = 0}
    }
}

local modules = {
    serialization = {path = "/lib/serialization.lua", cmd = [=[_G["serialization"] = load(module, "@/lib/serialization.lua")()]=]},
    nbsPlayer = {path = "/etc/drc-modules/nbsPlayer.lua", cmd = [=[_G["nbsPlayer"] = module]=], link = "https://raw.githubusercontent.com/ewwhash/DRC/master/modules/NBS/player.lua"},
    nbsParser = {path = "/etc/drc-modules/nbsParser.lua", cmd = [=[_G["nbsParser"] = module]=], link = "https://raw.githubusercontent.com/ewwhash/DRC/master/modules/NBS/parser.lua"},
    nbsFreqtab = {path = "/etc/drc-modules/nbsFreqtab.lua", cmd = [=[_G["nbsFreqtab"] = module]=], link = "https://raw.githubusercontent.com/ewwhash/DRC/master/modules/NBS/freqtab.lua"},
    nbsMain = {path = "/etc/drc-modules/nbsMain.lua", link = "https://raw.githubusercontent.com/ewwhash/DRC/master/modules/NBS/main.lua"}
}

local history = {}

local function set(x, y, str, background, foreground)
    if background and gpu.getBackground() ~= background then
        gpu.setBackground(background)
    end

    if foreground and gpu.getForeground() ~= foreground then
        gpu.setForeground(foreground)
    end

    gpu.set(x, y, str)

    if stuff.write then
        gpu.setBackground(color.gray)
        gpu.setForeground(color.white)
    end
end

local function exit()
    event.cancel(batteryTimer)
    event.cancel(clockTimer)
    event.cancel(dataTimer)
    gpu.setBackground(color.black)
    gpu.setForeground(color.white)
    gpu.setResolution(80, 25)
    term.setViewport(gpu.getViewport())
    term.clear()
    stuff.work = false
end

local function droneChangeColor()
    if not stuff.helpIsDrawed then
        gpu.setBackground(droneData.color)

        for pos = 1, 4 do
            gpu.fill(60 + stuff.drone[pos].x, 3 + stuff.drone[pos].y, 4, 2, " ")
        end
    end
end

local function droneDraw()
    if not stuff.helpIsDrawed then
        local x, y = stuff.drone.x, stuff.drone.y

        gpu.setBackground(color.black)
        gpu.fill(x, y, 8, 1, " ")
        gpu.fill(x, y + 3, 8, 1, " ")
        gpu.fill(x, y + 1, 2, 2, " ")
        gpu.fill(x + 6, y + 1, 2, 2, " ")

        gpu.copy(x, y, 8, 4, x - x + 10, y - y)

        gpu.copy(x, y, 8, 4, x - x, y - y + 5)
        gpu.copy(x, y, 8, 4, x - x + 10, y - y + 5)

        set(x + 4, y + 4, "  ")
        set(x + 12, y + 4, "  ")

        set(x + 8, y + 2, "  ")
        set(x + 8, y + 6, "  ")

        set(x + 8, y + 4, "  ", color.black, color.lightGray)

        set(x + 6, y + 4, "  ", color.black, color.gray)
        set(x + 10, y + 4, "  ", color.black, color.gray)
        set(x + 8, y + 3, "  ", color.black, color.gray)
        set(x + 8, y + 5, "  ", color.black, color.gray)

        droneChangeColor()
    end
end

local function clock()
    local f = io.open("/tmp/time", "w")
    f:write("time")
    f:close()
    local timestamp = fs.lastModified("/tmp/time") / 1000 + 3600 * stuff.timezone
    set(33, 1, os.date("%H:%M", timestamp), color.black, color.white)
end

local function signalBlock(x, block, signal)
    set(x, 1, block, color.black, signal and color.lime or color.orange)
end

local function signal(strength)
    if not strength then
        if droneData[4] then
            if droneData[4] <= modem.getStrength() / 100 * 25 then
                signalBlock(72, "⣀⣤⣶⣿", true)
            elseif droneData[4] <= modem.getStrength() / 100 * 50 then
                signalBlock(72, "⣀⣤⣶", true)
                signalBlock(75, "⣿")
            elseif droneData[4] <= modem.getStrength() / 100 * 75 then
                signalBlock(72, "⣀⣤", true)
                signalBlock(74, "⣶⣿")
            elseif droneData[4] <= modem.getStrength() then
                signalBlock(72, "⣀", true)
                signalBlock(73, "⣤⣶⣿")
            end
        else
            signalBlock(72, "⣀⣤⣶⣿")
        end
    else
        set(77, 1, stuff.strength .. "%  ", color.black, color.white)
    end
end

local function batteryBlock(x, block, empty, drone)
    set(x, 1, block, empty and color.black or drone and color.blue or color.lime, drone and color.blue or color.lime)
end

local function battery(drone, redraw)
    local x, batteryCharge, foreground = drone and 60 or 1

    if drone then
        batteryCharge = math.ceil(droneData.charge or 0)
        foreground = color.blue
    else
        batteryCharge = math.ceil(computer.energy() / (computer.maxEnergy() / 100))
        foreground = color.lime
    end

    if not (drone and stuff.droneOldBatteryCharge == batteryCharge or not drone and stuff.oldBatteryCharge == batteryCharge) and true then
        if redraw then
            set(x + 5, 1, "⠆", color.black, drone and color.blue or color.lime)
        end

        if batteryCharge >= 80 then
            batteryBlock(x, "⢸⣉⣉⣉⣉", false, drone)
        elseif batteryCharge >= 60 then
            batteryBlock(x, "⢸⣉⣉⣉", false, drone)
            batteryBlock(x + 4, "⣉", true, drone)
        elseif batteryCharge >= 40 then
            batteryBlock(x, "⢸⣉⣉", false, drone)
            batteryBlock(x + 3, "⣉⣉", true, drone)
        elseif batteryCharge < 40 and batteryCharge > 5 then
            batteryBlock(x, "⢸⣉", false, drone)
            batteryBlock(x + 2, "⣉⣉⣉", true, drone)
        else
            batteryBlock(x, "⣏⣉⣉⣉⣉", true, drone)
        end

        gpu.setBackground(color.black)
        gpu.fill(x + 6, 1, 5, 1, " ")
        set(x + 7, 1, batteryCharge .. "%", color.black, color.white)

        if drone then
            stuff.droneOldBatteryCharge = batteryCharge
        else
            stuff.oldBatteryCharge = batteryCharge
        end
    end
end

local function drawHelp()
    if not stuff.hide then
        gpu.setBackground(color.gray)
        gpu.fill(1, 2, 80, 24, " ")
        local y = 2

        for str = 1, #language[stuff.language].fullHelp do
            local strMatch = language[stuff.language].fullHelp[str]:match(".+—")
            set(1, y + str, strMatch, color.gray, color.white)
            set(unicode.len(strMatch) + 1, y + str, language[stuff.language].fullHelp[str]:match("—(.+)"), color.gray, color.lime)
        end

        set(1, #language[stuff.language].fullHelp + 4, language[stuff.language].fullHelp.exit .. "   ...", color.gray, color.white)
        set(unicode.len(language[stuff.language].fullHelp.exit) + 2, #language[stuff.language].fullHelp + 4, "H", color.gray, color.lime)
    end
end

local function drawDroneInfo(redraw)
    if not stuff.helpIsDrawed then
        local y = 3

        for str = 1, #language[stuff.language].droneInfo do
            if redraw then
                set(3, y, language[stuff.language].droneInfo[str], color.gray, color.white)
            end

            set(unicode.len(language[stuff.language].droneInfo[str]) + 5, y, droneData[str] and droneData[str] .. "          " or "N/A", color.gray, color.lime)
            y = y + 2
        end
    end
end

local function drawGui(redraw)
    gpu.setBackground(color.gray)
    gpu.fill(1, 2, 80, 24, " ")
    set(1, 13, language[stuff.language].help, color.gray, color.white)
    set(80 - unicode.len(language[stuff.language].exit) - 1, 13, language[stuff.language].exit, color.gray, color.white)
    set(unicode.len(language[stuff.language].help) + 2, 13, "H", color.gray, color.lime)
    set(80, 13, "Q", color.gray, color.lime)

    gpu.setForeground(color.lightGray)
    gpu.fill(1, 14, 80, 1, "⠉")

    droneDraw()
    drawDroneInfo(true)   

    if redraw then
        gpu.setBackground(color.black)
        gpu.fill(1, 1, 80, 1, " ")
        battery(false, true)
        battery(true, true)
        signal()
        signal(true)
        clock()
    end
end

local function send(...)
    modem.send(pairedCard, port, ...)
end

local function chunkSend(...)
    local data = {...}

    if #table.concat(data) >= 65535 then
        if stuff.write then
            io.stderr:write("Maximum data of 64 KB =(\n")
        end

        return false
    else
        if #table.concat(data) >= stuff.maxPacketSize then
            local data = (">s2"):rep(#data):pack(table.unpack(data))
            local chunks = math.ceil(#data / stuff.maxPacketSize)
            local startLen, endLen, maxLen = 1, stuff.maxPacketSize, stuff.maxPacketSize

            for chunk = 1, chunks do 
                send("chunk", data:sub(startLen, endLen))
                startLen, endLen = startLen + maxLen, endLen + maxLen 
            end

            send("d-end")
        else
            send(table.unpack(data))
        end

        return true
    end
end

local function downloadModules()
    fs.makeDirectory("/etc/drc-modules")

    for module in pairs(modules) do 
        if not fs.exists("/etc/drc-modules/" .. module .. ".lua") and modules[module].link then
            if internet then
                io.write("Download module: " .. module .. "...\n")
                local handle, data, chunk = internet.request(modules[module].link), ""
                   
                while true do
                    chunk = handle.read(math.huge)
                    if chunk then
                        data = data .. chunk
                    else
                        break
                    end
                end
                 
                handle.close()

                local file = io.open("/etc/drc-modules/" .. module .. ".lua", "w")
                file:write(data)
                file:close()
            else
                modules[module] = nil
            end
        end
    end
end

local function loadModules()
    downloadModules()

    for module in pairs(modules) do 
        local file = io.open(modules[module].path, "r")

        if not file then
            io.stderr:write("Unable to open module: " .. module)
            os.exit()
        else
            local strModule = file:read("a")
            modules[module].data = strModule
        end

        file:close()
    end
end

local function sendModules()
    for module in pairs(modules) do 
        if not chunkSend("module", modules[module].data, modules[module].cmd) then 
            exit()
            io.stderr:write("Module" .. module .. " contains more than 64 kb of data")
            os.exit()
        end
    end

    send("module", false, "end")
end

local function replPrint(stderr, data)
    if not stuff.helpIsDrawed and stuff.write and not stuff.hide and stuff.interpretation then
        gpu.setBackground(color.gray)
        if stderr then
            io.stderr:write(data .. "\n")
        else
            gpu.setForeground(color.white)
            term.write(data .. "\n")
        end
    end
end

local function waitResponse()
    stuff.waitResponse = true
    repeat
        event.pull(0, "modem_message")
    until not stuff.interpretation
    stuff.waitResponse = false
end

local function replWrite()
    if not stuff.helpIsDrawed and not stuff.hide then 
        stuff.write = true
        local result 

        repeat 
            gpu.setBackground(color.gray)
            gpu.setForeground(color.lime)
            term.write("lua>")
            gpu.setForeground(color.white)
            result = term.read(history)

            if result and unicode.len(result) > 1 then
                if result:match("(.+)\n") == "clear" then
                    term.clear()
                else 
                    if chunkSend("runCode", result) then
                        stuff.interpretation = true
                        waitResponse() 
                        stuff.interpretation = false
                    end
                end
            end
        until not result

        term.clear()
        stuff.write = false
    end
end

local function strength()
    modem.setStrength(stuff.maxStrength / 100 * stuff.strength)
    send("strength", stuff.strength)
end

local function connectionLost()
    if stuff.work then
        computer.beep(1500, .1)

        for data = 1, #droneData do 
            droneData[data] = false
        end

        droneData.color = color.gray
        droneData.charge = 0

        droneChangeColor()
        drawDroneInfo()
        battery(true)
        signal()

        stuff.requesting = false
    end
end

local function updateData(response)
    if not response and not stuff.requesting then
        send("data")
        connectionLostTimer = event.timer(3, connectionLost)
        stuff.requesting = true
    elseif response then
        if connectionLostTimer then
            event.cancel(connectionLostTimer)
        end

        stuff.requesting = false
        droneData[1] = response[7]
        droneData[2] = math.ceil(response[8]) .. " (" .. language[stuff.language].side[response[8]] .. ")"
        droneData[3] = math.ceil(response[9])
        droneData[4] = math.ceil(response[5])
        droneData[5] = math.ceil(response[10])
        droneData.charge = response[12]

        drawDroneInfo()
        battery(true)
        signal()

        if response[11] ~= droneData.color then
            droneData.color = response[11]
            droneChangeColor()
        end

        if not response[13] then 
            sendModules()
        end
    end
end

local function coordsMove()
    if not stuff.helpIsDrawed and not stuff.hide then
        stuff.write = true
        gpu.setBackground(color.gray)
        gpu.setForeground(color.white)
        
        term.write(language[stuff.language].coordsMove.x)
        local x = term.read()
        term.write(language[stuff.language].coordsMove.z)
        local z = term.read()
        term.write(language[stuff.language].coordsMove.dX)
        local dX = term.read()
        term.write(language[stuff.language].coordsMove.dZ)
        local dZ = term.read()
        term.write(language[stuff.language].coordsMove.y)
        local y = term.read()

        if tonumber(x) and tonumber(z) and tonumber(dX) and tonumber(dZ) and tonumber(y) then 
            x, z, dX, dZ, y = tonumber(x), tonumber(z), tonumber(dX), tonumber(dZ), tonumber(y)
            term.write(language[stuff.language].coordsMove.moving)
            send("goToCoords", dX-x, y, dZ-z)
        else
            io.stderr:write(language[stuff.language].coordsMove.invalidInput)
        end
        os.sleep(2)
        stuff.write = false
        term.clear()
    end
end

local function facingMove(side)
    local facing = math.floor(tablet.getYaw() / 90 - .5) % 4
    send("move", facings[facing][side].x, 0, facings[facing][side].z)
end

local function pair()
    modem.close()
    modem.open(port)

    if pairedCard == "" then
        local strength = modem.getStrength()
        modem.setStrength(5)
        term.write("Trying to pair...")
        modem.broadcast(port, "pair")

        local response = {event.pull(5, "modem_message")}

        if response and response[6] == "OK" then
            term.write("\nPairing successful!\n")
            pairedCard = response[3] 
            local file = io.open("/etc/drc.cfg", "w")
            file:write("pairedCard=" .. response[3] .. "," .. "port=" .. port)
            file:close()
        else
            io.stderr:write("\nPairing failed, try get closer.")
            modem.setStrength(strength)
            modem.close()
            os.exit()
        end
    end

    stuff.maxStrength = tonumber(computer.getDeviceInfo()[modem.address].width)
    stuff.maxPacketSize = tonumber(computer.getDeviceInfo()[modem.address].capacity) - 128
    strength()
end

local function timers(enable)
    if enable then
        batteryTimer = event.timer(5, battery, math.huge) 
        clockTimer = event.timer(60, clock, math.huge) 
        dataTimer = event.timer(20, updateData, math.huge)
    else
        event.cancel(batteryTimer) 
        event.cancel(clockTimer) 
        event.cancel(dataTimer)
    end
end

local function start()
    term.setViewport(80, 11, 0, 14, 1, 1)
    drawGui(true)
    timers(true)
    send("data")
end

local commands = {
    [17] = function() if tablet and tablet.getYaw then facingMove("front") else send("move", 1, 0, 0) end end,
    [31] = function() if tablet and tablet.getYaw then facingMove("back") else send("move", -1, 0, 0) end end, 
    [30] = function() if tablet and tablet.getYaw then facingMove("left") else send("move", 0, 0, 1) end end,
    [32] = function() if tablet and tablet.getYaw then facingMove("right") else send("move", 0, 0, -1) end end,
    [42] = function() send("move", 0, 1, 0) end,
    [29] = function() send("move", 0, -1, 0) end,
    [44] = function() send("swing") end,
    [45] = function() send("place") end,
    [19] = function() send("suck") send("data") end,
    [33] = function() send("drop") send("data") end,
    [46] = function() send("leash") end,
    [47] = function() send("unleash") end,
    [24] = function() send("shutboot", true) end,
    [25] = function() send("shutboot") end,
    [48] = function() send("acceleration") send("data") end,
    [38] = function() send("light", math.random(0x0, 0xffffff)) end,
    [34] = function() send("goToMe") end,
    [49] = function() coordsMove() end,

    [18] = function() updateData() end,
    [23] = function() replWrite() end,
    [22] = function() if keyboard.isControlDown() and keyboard.isAltDown() then send("unpair") local file = io.open("/etc/drc.cfg", "w") file:write() file:close() exit() end end,
    [35] = function() if stuff.helpIsDrawed then stuff.helpIsDrawed = false term.setCursor(1, 1) drawGui() else stuff.helpIsDrawed = true term.setCursor(1, 1) drawHelp() end end,
    [13] = function() if stuff.strength + 5 ~= 105 then stuff.strength = stuff.strength + 5 end strength() signal(true) end,
    [12] = function() if stuff.strength - 5 ~= 0 then stuff.strength = stuff.strength - 5 end strength() signal(true) end,
    [50] = function() if not stuff.hide then timers(false) stuff.hide = true gpu.setBackground(color.black) gpu.set(1, 1, " ") gpu.setResolution(1, 1) stuff.helpIsDrawed = false else timers(true) stuff.hide = false gpu.setResolution(80, 25) drawGui(true) end end,
    [16] = function() exit() end
}

local function listenMessage(...)
    local data = {...}

    if data[3] == pairedCard and data[4] == port then
        if data[6] == "data" then
            updateData(data)
        elseif data[6] == "ping" then
            send("pong")
        elseif data[6] == "print" then
            replPrint(data[7], data[8])
        elseif data[6] == "r-end" then
           stuff.interpretation = false
        end
    end
end

local function listenKey(evt, _, char, code)
    if not stuff.write and commands[code] then
        commands[code]()
    elseif code >= 2 and code <= 11 and not stuff.write then
        if code <= 6 and keyboard.isAltDown() then
            send("selectSide", code - 1)
        elseif code == 11 then
            send("selectSide", 0)
        elseif code <= 9 and not keyboard.isAltDown() then
            send("selectSlot", code - 1)
        end

        send("data")
    elseif code == 32 and keyboard.isControlDown() and (stuff.write and stuff.waitResponse) then
        send("interrupt")
        event.pull(.2, "modem_message")
        stuff.interpretation = false
    end
end

local function parseArgs()
    local help = [[Usage: drc <port>]]
    
    if args[1] == "-help" or args[1] == "-h" or args[1] == "help" then
        io.write(help)
        os.exit()
    else
        if not io.open("/etc/drc.cfg") then
            local file = io.open("/etc/drc.cfg", "w")
            file:write()
            file:close()
        end

        local file = io.open("/etc/drc.cfg", "r")
        local data = file:read("a")

        if args[1] then
            if not tonumber(args[1]) then
                io.write(help)
                os.exit()
            else
                port = tonumber(args[1])
            end
        elseif data == "" then
            io.write(help)
            os.exit()
        else
            pairedCard, port = data:match("pairedCard=(.+),"), tonumber(data:match(",port=(%d+)"))
        end

        pair()
    end
end

parseArgs()
loadModules()
require("process").info().data.signal = function() end
start()

event.listen("key_down", listenKey)
event.listen("modem_message", listenMessage)

while stuff.work do 
    os.sleep(0)
end

event.ignore("key_down", listenKey)
event.ignore("modem_message", listenMessage)
os.exit()
