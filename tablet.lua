local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")
local filesystem = require("filesystem")
local term = require("term")
local tty = require("tty")
local keyboard = require("keyboard")
local gpu, modem, internet = component.gpu
local args = {...}
local pairedCard, port = "", 0
local tablet

if not component.isAvailable("modem") then
    io.stderr:write("This program requires network card!")
    os.exit()
else
    modem = component.modem
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
        help = "[0xffffff]Помощь — [0x7fcc19]H",
        exit = "[0xffffff]Выход — [0x7fcc19]Q",

        side = {
            [0] = "Низ",
            "Верх",
            "Север",
            "Юг",
            "Запад",
            "Восток"
        },

        droneInfo = {
            acceleration = "[0xffffff]Ускорение: [0x7fcc19]",
            activeSide = "[0xffffff]Активная сторона: [0x7fcc19]",
            activeSlot = "[0xffffff]Активный слот: [0x7fcc19]",
            distance = "[0xffffff]Расстояние до дрона: [0x7fcc19]",
            items = "[0xffffff]Кол-во вещей в активном слоте: [0x7fcc19]"
        },

        fullHelp = {
            "[0x7fcc19]CTRL+ALT+U [0xffffff]— Отвязать дрона",
            "[0x7fcc19]LSHIFT/LCTRL [0xffffff]— Вверх/Вниз",
            "[0x7fcc19]I/CTRL+D [0xffffff]— Открыть/Закрыть интерпретатор",
            "[0x7fcc19]ALT+0-5 [0xffffff]— Активная сторона",
            "[0x7fcc19]WASD [0xffffff]— Перемещение",
            "[0x7fcc19]1-8 [0xffffff]— Активный слот",
            "[0x7fcc19]Z/X [0xffffff]— Сломать/Установить блок",
            "[0x7fcc19]R/F [0xffffff]— Забрать/Выбросить вещи из активной стороны",
            "[0x7fcc19]С/V [0xffffff]— Захватить/Отцепить ближайших существ",
            "[0x7fcc19]+/- [0xffffff]— Увеличить/Уменьшить силу сигнала",
            "[0x7fcc19]P [0xffffff]— Включить/Выключить дрона",
            "[0x7fcc19]B [0xffffff]— Смена ускорения",
            "[0x7fcc19]L [0xffffff]— Установить цвет дрона на случайный",
            "[0x7fcc19]E [0xffffff]— Принудительно обновить данные",
            "[0x7fcc19]G [0xffffff]— Вернуть дрона домой",
            "[0x7fcc19]O [0xffffff]— Перезагрука дрона",
            "[0x7fcc19]N [0xffffff]— Перемещение по координата",
            "[0x7fcc19]M [0xffffff]— Односимвольный экран",
            exit = "[0xffffff]Чтобы закрыть нажмите [0x7fcc19]H [0xffffff]..."
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
        help = "[0xffffff]Help — [0x7fcc19]H",
        exit = "[0xffffff]Exit — [0x7fcc19]Q",

        side = {
            [0] = "Down",
            "Up",
            "North",
            "South",
            "West",
            "East"
        },

        droneInfo = {
            acceleration = "[0xffffff]Acceleration: [0x7fcc19]",
            activeSide = "[0xffffff]Active side: [0x7fcc19]",
            activeSlot = "[0xffffff]Active slot: [0x7fcc19]",
            distance = "[0xffffff]Distance to drone: [0x7fcc19]",
            items = "[0xffffff]Items in active slot: [0x7fcc19]"
        },

        fullHelp = {
            "[0x7fcc19]CTRL+ALT+U [0xffffff]— Unpair",
            "[0x7fcc19]LSHIFT/LCTRL [0xffffff]— Up/Down",
            "[0x7fcc19]I/CTRL+D [0xffffff]— Open/Close interpreter",
            "[0x7fcc19]ALT+0-5 [0xffffff]— Active side",
            "[0x7fcc19]WASD [0xffffff]— Move",
            "[0x7fcc19]1-8 [0xffffff]— Active slot",
            "[0x7fcc19]Z/X [0xffffff]— Break/Place block",
            "[0x7fcc19]R/F [0xffffff]— Take/Drop",
            "[0x7fcc19]C/V [0xffffff]— Leash/Unleash",
            "[0x7fcc19]+/- [0xffffff]— Increase/Reduce modem strength",
            "[0x7fcc19]P [0xffffff]— Enable/Disable drone",
            "[0x7fcc19]B [0xffffff]— Change acceleration",
            "[0x7fcc19]L [0xffffff]— Random color",
            "[0x7fcc19]E [0xffffff]— Force update",
            "[0x7fcc19]G [0xffffff]— Back to home",
            "[0x7fcc19]O [0xffffff]— Reboot drone",
            "[0x7fcc19]N [0xffffff]— Move by coords",
            "[0x7fcc19]M [0xffffff]— One pixel screen",
            exit = "[0xffffff]To close press [0x7fcc19]H [0xffffff]..."
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
    lastError = false,

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
    pattern = "%[0x(%x%x%x%x%x%x)]",

    white = 0xffffff,
    black  = 0x000000,
    lime = 0x7fcc19,
    orange = 0xf2b233,
    gray = 0x3c3c48,
    lightGray = 0xe5e5e5,
    blue = 0x269fd8,
    red = 0xff5555,
}

local droneData = {
    acceleration = false,
    activeSide = false,
    activeSlot = false,
    distance = false,
    items = false,

    color = color.gray,
    charge = 0,
    ram = 0
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
    autoComplete = {cmd = [=[function keys(t) local r={} for k in pairs(t) do table.insert(r,k) end return r end _G.cmd["tab"] = function(contextFromTablet) local func=load("return " .. contextFromTablet) local context = func and func() or {} context = (type(context)=="table") and context or {} send("tab-results",table.concat(keys(context), ",")) end]=]},
    nbsPlayer = {path = "/etc/drc-modules/nbsPlayer.lua", cmd = [=[_G["nbsPlayer"] = module]=], link = "https://raw.githubusercontent.com/BrightYC/DRC/master/modules/NBS/player.lua"},
    nbsParser = {path = "/etc/drc-modules/nbsParser.lua", cmd = [=[_G["nbsParser"] = module]=], link = "https://raw.githubusercontent.com/BrightYC/DRC/master/modules/NBS/parser.lua"},
    nbsFreqtab = {path = "/etc/drc-modules/nbsFreqtab.lua", cmd = [=[_G["nbsFreqtab"] = module]=], link = "https://raw.githubusercontent.com/BrightYC/DRC/master/modules/NBS/freqtab.lua"},
    nbsPlay = {path = "/etc/drc-modules/nbsPlay.lua", link = "https://raw.githubusercontent.com/BrightYC/DRC/master/modules/NBS/play.lua"}
}

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

local function setColorText(x, y, str, background)
    local begin = 1

    while true do
        local b, e, color = str:find(color.pattern, begin)
        local precedingString = str:sub(begin, b and (b - 1))

        if precedingString then
            set(x, y, precedingString, background)
            x = x + unicode.len(precedingString)
        end

        if not color then
            break
        end

        gpu.setForeground(tonumber(color, 16))
        begin = e + 1
    end
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

local function signal(strength)
    if not strength then
        if droneData.distance then
            if droneData.distance <= modem.getStrength() / 100 * 25 then
                setColorText(72, 1, "[0x7fcc19]⣀⣤⣶⣿", color.black)
            elseif droneData.distance <= modem.getStrength() / 100 * 50 then
                setColorText(72, 1, "[0x7fcc19]⣀⣤⣶[0xf2b233]⣿", color.black)
            elseif droneData.distance <= modem.getStrength() / 100 * 75 then
                setColorText(72, 1, "[0x7fcc19]⣀⣤[0xf2b233]⣶⣿", color.black)
            elseif droneData.distance <= modem.getStrength() then
                setColorText(72, 1, "[0x7fcc19]⣀[0xf2b233]⣤⣶⣿", color.black)
            end
        else
            setColorText(72, 1, "[0xf2b233]⣀⣤⣶⣿", color.black)
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

    if not (drone and stuff.droneOldBatteryCharge == batteryCharge or not drone and stuff.oldBatteryCharge == batteryCharge) and true or redraw then
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

local function ram(redraw)
    gpu.setBackground(color.black)
    gpu.fill(47, 1, 4, 1, " ")
    if redraw then
        set(42, 1, "RAM: ", color.black, color.white)
    end
    set(47, 1, droneData.ram .. "%", color.black, color.white)

    if droneData.ram >= 95 then
        setColorText(51, 1, "[0xff5555]⠒⠒⠒⠒⠒⠒⠒", color.black)
    elseif droneData.ram >= 81 then
        setColorText(51, 1, "[0xff5555]⠒⠒⠒⠒⠒⠒[0x3c3c48]⠒", color.black)
    elseif droneData.ram >= 67 then
        setColorText(51, 1, "[0xf2b233]⠒⠒⠒⠒⠒[0x3c3c48]⠒⠒", color.black)
    elseif droneData.ram >= 50 then 
        setColorText(51, 1, "[0xf2b233]⠒⠒⠒⠒[0x3c3c48]⠒⠒⠒", color.black)
    elseif droneData.ram >= 36 then
        setColorText(51, 1, "[0x7fcc19]⠒⠒⠒[0x3c3c48]⠒⠒⠒⠒", color.black)
    elseif droneData.ram >= 22 then
        setColorText(51, 1, "[0x7fcc19]⠒⠒[0x3c3c48]⠒⠒⠒⠒⠒", color.black)
    else
        setColorText(51, 1, "[0x7fcc19]⠒[0x3c3c48]⠒⠒⠒⠒⠒⠒", color.black)
    end
end

local function drawHelp()
    if not stuff.hide then
        gpu.setBackground(color.gray)
        gpu.fill(1, 2, 80, 24, " ")

        for str = 1, #language[stuff.language].fullHelp do 
            setColorText(1, str + 2, language[stuff.language].fullHelp[str])
        end

        setColorText(1, #language[stuff.language].fullHelp + 4, language[stuff.language].fullHelp.exit)
    end
end

local function drawDroneInfo(redraw)
    if not stuff.helpIsDrawed then
        setColorText(3, 3, language[stuff.language].droneInfo.acceleration .. " " .. (droneData.acceleration and droneData.acceleration .. "          " or "N/A              "), color.gray)
        setColorText(3, 5, language[stuff.language].droneInfo.activeSide .. " " .. (droneData.activeSide and droneData.activeSide .. "          " or "N/A              "), color.gray)
        setColorText(3, 7, language[stuff.language].droneInfo.activeSlot .. " " .. (droneData.activeSlot and droneData.activeSlot .. "          " or "N/A              "), color.gray)
        setColorText(3, 9, language[stuff.language].droneInfo.distance .. " " .. (droneData.distance and droneData.distance .. "          " or "N/A              "), color.gray)
        setColorText(3, 11, language[stuff.language].droneInfo.items .. " " .. (droneData.items and droneData.items .. "          " or "N/A              "), color.gray)
    end
end

local function drawGui(redraw)
    gpu.setBackground(color.gray)
    gpu.fill(1, 2, 80, 24, " ")
    setColorText(1, 13, language[stuff.language].help)
    setColorText(81 - unicode.len(language[stuff.language].exit:gsub(color.pattern, "")), 13, language[stuff.language].exit)

    gpu.setForeground(color.lightGray)
    gpu.fill(1, 14, 80, 1, "⠉")

    droneDraw()
    drawDroneInfo(true)   

    if redraw then
        gpu.setBackground(color.black)
        gpu.fill(1, 1, 80, 1, " ")
        ram(true)
        battery(false, true)
        battery(true, true)
        signal()
        signal(true)
    end
end

local function send(...)
    modem.send(pairedCard, port, ...)
end

local function chunkSend(...)
    local data = {...}
    local copy = data

    for str = 1, #copy do
        copy[str] = tostring(copy[str])
    end

    if #table.concat(copy) >= 65535 then
        if stuff.write then
            io.stderr:write("Maximum data of 64 KB =(\n")
        end

        return false
    else
        if #table.concat(data) >= stuff.maxPacketSize then
            data = (">s2"):rep(#data):pack(table.unpack(data))
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
    filesystem.makeDirectory("/etc/drc-modules")

    for module in pairs(modules) do 
        if not filesystem.exists("/etc/drc-modules/" .. module .. ".lua") and modules[module].link then
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
        if modules[module].path then
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
end

local function sendModules()
    for module in pairs(modules) do 
        if not chunkSend("loadModule", module, modules[module].data, modules[module].cmd) then 
            exit()
            io.stderr:write("Module" .. module .. " contains more than 64 kb of data")
            os.exit()
        end
    end
end

local function replPrint(stderr, data)
    if not stuff.hide then
        gpu.setBackground(color.gray)
        gpu.setForeground(color.white)

        if stderr then
            io.stderr:write(data .. "\n")
        else
            io.write(data .. "\n")
        end
    elseif stuff.hide and stderr then
        computer.beep(2000, .5)
        stuff.lastError = data
    end
end

local function waitResponse(e)
    stuff.waitResponse = true
    repeat
        local response = event.pull(0, "modem_message")
    until not stuff.interpretation
    stuff.waitResponse = false
end

map = function(t,f)
    local out={}
    for k, v in pairs(t) do
        local k1,v1=f(k,v)
        out[k1]=v1
    end
    return out
end

filterList = function(t, filterIter)
  local out = {}

  for k, v in pairs(t) do
    if filterIter(v, k, t) then table.insert(out,v) end
  end

  return out
end

local hintCache={}

local function keysOfTable(context)
    local r = hintCache[context]
    if not r then
        send("tab", context)
        local response = {event.pull(.2, "modem_message")}
        if response[6] == "tab-results" then
            r = {}
            for i in response[7]:gmatch("[A-z][A-z0-9]*") do
                table.insert(r, i)
            end
            hintCache[context] = r
        end
    end

    return r
end

local history = {
    hint = function(line, index)
        line = line or ""
        local tail = line:sub(index)
        line = line:sub(1, index - 1)
        local lastIndexOfDot=line:reverse():find("%.") or -1

        local context=line:sub(1,-lastIndexOfDot-1)
        local fragment = (lastIndexOfDot == -1) and line or line:sub(#line-lastIndexOfDot+2)

        context = (context=="") and "_G" or context
        return map(filterList(keysOfTable(context),function(v) return v:find(fragment)==1 end),function(k,v)return k, ((context=="_G") and "" or context..".")..v..tail end)
    end
}

local function replWrite()
    if not stuff.helpIsDrawed and not stuff.hide then 
        stuff.write = true
        local result 

        repeat 
            gpu.setBackground(color.gray)
            gpu.setForeground(color.lime)
            io.write("lua>")
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
        stuff.requesting = false
        computer.beep(1500, .1)

        droneData.acceleration = false
        droneData.activeSide = false
        droneData.activeSlot = false
        droneData.distance = false
        droneData.items = false

        droneData.color = color.gray
        droneData.charge = 0
        droneData.ram = 0

        droneChangeColor()
        drawDroneInfo()
        ram()
        battery(true)
        signal()
    end
end

local function updateData(response)
    if not response and not stuff.requesting then
        send("data")
        connectionLostTimer = event.timer(5, connectionLost)
        stuff.requesting = true
    elseif response and type(response) == "table" and response[1] then
        if connectionLostTimer then
            event.cancel(connectionLostTimer)
        end

        stuff.requesting = false
        droneData.acceleration = response[7]
        droneData.activeSide = math.ceil(response[8]) .. " (" .. language[stuff.language].side[response[8]] .. ")"
        droneData.activeSlot = math.ceil(response[9])
        droneData.distance = math.ceil(response[5])
        droneData.items = math.ceil(response[10])

        droneData.charge = response[12]
        droneData.ram = math.ceil(response[13])

        drawDroneInfo()
        ram()
        battery(true)
        signal()

        if response[11] ~= droneData.color then
            droneData.color = response[11]
            droneChangeColor()
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
        dataTimer = event.timer(20, updateData, math.huge)
    else
        event.cancel(batteryTimer) 
        event.cancel(dataTimer)
    end
end

local function start()
    gpu.setResolution(80, 25)
    term.setViewport(80, 11, 0, 14, 1, 1)
    tty.window.fullscreen = false
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
    [22] = function() if keyboard.isControlDown() and keyboard.isAltDown() then send("unpair") local file = io.open("/etc/drc.cfg", "w") file:write() file:close() exit(true) end end,
    [35] = function() if stuff.helpIsDrawed then stuff.helpIsDrawed = false term.setCursor(1, 1) drawGui() else stuff.helpIsDrawed = true term.setCursor(1, 1) drawHelp() end end,
    [13] = function() if stuff.strength + 5 ~= 105 then stuff.strength = stuff.strength + 5 end strength() signal(true) end,
    [12] = function() if stuff.strength - 5 ~= 0 then stuff.strength = stuff.strength - 5 end strength() signal(true) end,
    [50] = function() if not stuff.hide then timers(false) stuff.hide = true gpu.setBackground(color.black) gpu.setResolution(1, 1) gpu.set(1, 1, " ") stuff.helpIsDrawed = false else timers(true) stuff.hide = false gpu.setResolution(80, 25) tty.window.fullscreen = false drawGui(true) if stuff.lastError then replPrint(true, stuff.lastError) stuff.lastError = false end end end,
    [16] = function() if not stuff.write then exit() end end
}

local function listenMessage(...)
    local data = {...}

    if data[3] == pairedCard and data[4] == port then
        if data[6] == "data" then
            updateData(data)
        elseif data[6] == "getModules" then
            sendModules()
        elseif data[6] == "ping" then
            send("pong")
        elseif data[6] == "print" then
            replPrint(data[7], data[8])
        elseif data[6] == "r-end" then
           stuff.interpretation = false
        end
    end
end

local function listenKey(_, _, char, code)
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
        os.sleep(.2)
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
            port = tonumber(args[1])

            if not port then
                io.write(help)
                os.exit()
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

function exit(forcibly)
    event.ignore("key_down", listenKey)
    event.ignore("modem_message", listenMessage)
    event.cancel(batteryTimer)
    event.cancel(dataTimer)
    gpu.setBackground(color.black)
    gpu.setForeground(color.white)
    gpu.setResolution(80, 25)
    term.setViewport(gpu.getViewport())
    tty.window.fullscreen = false
    term.clear()
    stuff.work, exit = false, nil

    if forcibly then
        os.exit()
    end
end

parseArgs()
loadModules()
require("process").info().data.signal = function() exit(true) end
start()

event.listen("key_down", listenKey)
event.listen("modem_message", listenMessage)

while stuff.work do 
    os.sleep(0)
end
