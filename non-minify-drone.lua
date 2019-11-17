local component_, debug_ = component, debug
for address, cpt in component.list() do if cpt ~= "computer" then _G[cpt] = component.proxy(address) end end
local drone_, modem_, computer_, eeprom_, leash_ = drone, modem, computer, eeprom, leash
local setColor, getColor, inventorySize, getAcceleration, setAcceleration, selectSlot, setStatusText, getDeviceInfo, uptime, modemAddress = drone_.setLightColor, drone_.getLightColor, drone_.inventorySize, drone_.getAcceleration, drone_.setAcceleration, drone_.select, drone_.setStatusText, computer_.getDeviceInfo, computer_.uptime, modem_.address
local tonumber_, tostring_, math_, true_, false_, table_ = tonumber, tostring, math, true, false, table
 
setColor(0x42dff4)
if computer_.getArchitecture() == "Lua 5.2" then
    computer_.setArchitecture("Lua 5.3")
end

local activeSide, activeSlot, port, allModulesReceived, codeExecution, ignore, pairedCard, data, maxModemStrength, maxPacketSize, env = 0, 0, 0, false_, false_, false_, "", "", tonumber_(getDeviceInfo()[modemAddress].width), tonumber_(getDeviceInfo()[modemAddress].capacity) - 128, setmetatable({}, {__index = _G, __metatable = ""})
 
local function sendToTablet(...)
    modem_.send(pairedCard, port, ...)
end
 
local function concat(tableData)
    for i = 1, tableData.n do
        if type(tableData[i]) == "table" then
            if serialization then
                tableData[i] = serialization.serialize(tableData[i], true_) .. "\t"
            else
                tableData[i] = tostring_(tableData[i])
            end
        else
            tableData[i] = tostring_(tableData[i])
        end
    end
 
    return table_.concat(tableData, ",  ")
end
 
local function stderrPrint(stderr, ...)
    local tableData = table_.pack(...)
    sendToTablet("print", stderr, concat(tableData):sub(1, maxPacketSize))
end
 
local function sendData()
    sendToTablet("data", getAcceleration(), activeSide, activeSlot, drone_.count(), getColor(), computer_.energy() / (computer_.maxEnergy() / 100), (computer_.totalMemory() - computer_.freeMemory()) / (computer_.totalMemory() / 100))

    if not allModulesReceived then
        sendToTablet("getModules")
        allModulesReceived = true_
    end
end
 
local function readyState()
    setColor(0xffffff)
    setStatusText("I'm ready!")
    sendData()
end
 
local function pair(modemAddress, unpair)
    if unpair then
        pairedCard = ""
        eeprom_.setData()
        pair()
    else
        if modemAddress then
            pairedCard = modemAddress
            eeprom_.setData(modemAddress .. "," .. port)
            sendToTablet("OK")
            readyState()
        else        
            local data = eeprom_.getData()
            local portCheck = tonumber_(data:match(",(%d+)"))

            if portCheck then 
                pairedCard, port = data:match("([%w%p+]+),"), portCheck
                modem_.open(port)
                readyState()
            else
                port = math_.floor(math_.random(65535))
                modem_.close()
                modem_.open(port)
                setColor(0xe0b714)
                setStatusText("Pair Me!\n" .. tostring_(port))
            end
        end
    end
end 

local function blockMove(x, y, z, sleepTime)
    drone_.move(x, y, z)
    sleepTime = sleepTime or .1
 
    while drone_.getOffset() > .7 or drone_.getVelocity() > .7 do
        sleep(sleepTime, true_)
    end
end
 
local function checkNumber(number, ifNotValidNumber)
    return type(number) == "number" and number or ifNotValidNumber
end
 
local function getDistanceToUser()
    sendToTablet("ping")
    return checkNumber(select(5, pull(3, true_)), 0)
end
 
local function goToUser()
    if getDistanceToUser() > 5 then
        local oldLightColor = getColor()
        setColor(0x0094ff)
        sendData()
 
        repeat
            ignore = true_
            local r = getDistanceToUser()
 
            blockMove(1, 0, 0)
            local r1 = getDistanceToUser()
 
            blockMove(-1, 1, 0)
            local r2 = getDistanceToUser()
 
            blockMove(0, -1, 1)
            local r3 = getDistanceToUser()
 
            blockMove(0, 0, -1)
 
            local x = (r*r - r1*r1 +1) / 2
            local y = (r*r - r2*r2 +1) / 2
            local z = (r*r - r3*r3 +1) / 2 - 1
 
            if math_.ceil(r) == math_.ceil(getDistanceToUser()) then
                ignore = false_
                blockMove(x, y, z)
            end
        until getDistanceToUser() <= 5

        setColor(oldLightColor)
        sendData()
    end
end
 
local function safeSelectSlot(slot)
    if inventorySize() > 1 then
        if slot > inventorySize() then
            selectSlot(inventorySize())
            activeSlot = inventorySize()
        else
            selectSlot(slot)
            activeSlot = slot
        end
    end
end
 
local function sandboxLoad(code, sandbox)
    return load(code, "=stdin", "t", not sandbox and env)
end
 
local function runCode(code, traceback, moduleName)
    if code:sub(1, 1) == "=" then
       code = code:sub(2, #code)
    end
 
    local chunk, error_ = sandboxLoad("return " .. code, moduleName)
 
    if not chunk then
        chunk, error_ = sandboxLoad(code, moduleName)
       
        if not chunk then
            stderrPrint(true_, moduleName and "Syntax error(" .. moduleName .. "): " .. error_ or "Syntax error: " .. error_)
        end
    end
 
    if chunk then
        codeExecution = true_
 
        local returnData = table_.pack(xpcall(chunk, debug_.traceback))
 
        if returnData[1] then
            if returnData.n > 1 and not moduleName then
                table_.remove(returnData, 1)
                stderrPrint(false_, table_.unpack(returnData, 1, returnData.n - 1))
            end
        else
            if traceback then
                error_ = returnData[2]
            else
                error_ = returnData[2]:match("(.+)\nstack")
 
                if not error_ then
                    if returnData[2]:match("stack") then
                        error_ = "error?"
                    else
                        error_ = returnData[2]
                    end
                end
            end
            
            stderrPrint(true_, moduleName and "Runtime error(" .. moduleName .. "): " .. error_ or "Runtime error: " .. error_)
        end
 
        codeExecution = false_
    end

    sendToTablet("r-end")
end
 
local function loadModule(name, code, command)
    module = code
    runCode(command or code, false_, name)
end
 
function pull(timeout)
    local deadline = uptime() + checkNumber(timeout, math_.huge)
    local signal = {computer_.pullSignal(deadline - uptime())}
 
    if signal[1] == "modem_message" then
        if signal[3] == pairedCard then
            if signal[6] == "chunk" then
                data = data .. signal[7]
            elseif signal[6] == "d-end" then
                local args = {}
                local pos, arg = 1, ""
 
                while pos < #data do
                    arg, pos = string.unpack(">s2", data, pos)
                    table_.insert(args, arg)
                end
 
                if cmd[args[1]] then
                    cmd[args[1]](table_.unpack(args, 2, #args))
                end
 
                data = ""
            elseif cmd[signal[6]] then
                cmd[signal[6]](table_.unpack(signal, 7, #signal))
            elseif signal[6] == "unpair" then
                pair(false_, true_)
            elseif signal[6] == "strength" then
                modem_.setStrength(maxModemStrength / 100 * signal[7])
            elseif signal[6] == "interrupt" and codeExecution then
                error("interrupted")
            end
        elseif signal[5] <= 5 and signal[6] == "pair" and #pairedCard == 0 then
            pair(signal[3])
        end
    end
 
    return table_.unpack(signal, 1, #signal)
end

function sleep(timeout)
    local deadline = uptime() + checkNumber(timeout, 0)

    repeat
        pull(deadline - uptime())
    until uptime() >= deadline
end
 
cmd = {
    move = function(...) if not ignore then drone_.move(...) end end,
    swing = function() drone_.swing(activeSide) end,
    place = function() drone_.place(activeSide) end,
    suck = function() if inventorySize() > 1 then for i = 1, inventorySize() do selectSlot(i) drone_.suck(activeSide) end selectSlot(activeSlot) end end,
    drop = function() if inventorySize() > 1 then for i = 1, inventorySize() do selectSlot(i) drone_.drop(activeSide) end selectSlot(activeSlot) end end,
    leash = function() if leash_ then for side = 0, 5 do leash_.leash(side) end end end,
    unleash = function() if leash_ then leash_.unleash() end end,
    shutboot = computer_.shutdown,
    acceleration = function() if getAcceleration() + 0.5 < 2.5 then setAcceleration(getAcceleration() + .5) else setAcceleration(.5) end sendData() end,
    selectSide = function(side) activeSide = side end,
    selectSlot = safeSelectSlot,
    light = function(color) setColor(color) sendData() end,
    runCode = runCode,
    goToMe = goToUser,
    goToCoords = function(x, y, z) blockMove(0, y, 0) blockMove(x, 0, z) blockMove(0, -y, 0) end,
    data = sendData,
    loadModule = loadModule
}

print, move, send, update, distance, moveToUser, slot = function(...) stderrPrint(false_, ...) end, blockMove, sendToTablet, sendData, getDistanceToUser, goToUser, safeSelectSlot
 
modem_.setWakeMessage("shutboot")
safeSelectSlot(1)
pair()

while true_ do
    pull()
end
