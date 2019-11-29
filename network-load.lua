local component = require("component")
local computer = require("computer")
local event = require("event")
local keyboard = require("keyboard")
local modem = component.modem
local args = {...}
local pairedCard, port, code = "", 0, 0
local maxPacketSize
 
local help = [[Usage: net <path> <var name>]]
 
local function send(...)  
    modem.send(pairedCard, port, ...)
end
 
local function chunkSend(...)
    local data = {...}
 
    if #table.concat(data) >= 65535 then
        io.stderr:write("Maximum data of 64 KB =(")
        os.exit()
    else
        if #table.concat(data) >= maxPacketSize then
            local data = (">s2"):rep(#data):pack(table.unpack(data))
            local chunks = math.ceil(#data / maxPacketSize)
            local startLen, endLen, maxLen = 1, maxPacketSize, maxPacketSize
 
            for chunk = 1, chunks do
                io.write("Sending " .. chunk .. "/" .. chunks .. " chunk\n")
                send("chunk", data:sub(startLen, endLen))
                startLen, endLen = startLen + maxLen, endLen + maxLen
            end
 
            send("d-end")
        else
            io.write("Sending 1/1 chunk\n")
            send(table.unpack(data))
        end
 
        io.write("File sent. Press CTRL+D for interrupt, Q for exit.\n")
    end
end
 
local function getCfg()
    local file = io.open("/etc/drc.cfg", "r")
    local notCfg = [[Configuration file not found or empty. Please, run main program]]
 
    if not file then
        io.stderr:write(notCfg)
        os.exit()
    end
 
    local data = file:read("a")
    file:close()
    if data == "" then
        io.stderr:write(notCfg)
        os.exit()
    end
    pairedCard, port = data:match("pairedCard=(.+),"), tonumber(data:match(",port=(%d+)"))
   
    modem.close()
    modem.open(port)
end
 
local function parseArgs() 
    if not args[1] then
        io.write(help)
        os.exit()
    end
 
    local file = io.open(args[1], "r")
    local data
 
    if not file then
        io.write(help)
        os.exit()
    else
        code = file:read("a")
        file:close()
        maxPacketSize = tonumber(computer.getDeviceInfo()[modem.address].capacity) - 128
    end
 
    if args[2] then
        code = args[2] .. "= [=[" .. code .. "]=]"
    end
 
    getCfg()
end
 
parseArgs()
chunkSend("runCode", code)
 
while true do
    local evt = {event.pull()}
 
    if evt[1] == "modem_message" and evt[3] == pairedCard and evt[4] == port then
        if evt[6] == "print" then
            if evt[7] then
                io.stderr:write(evt[8])
            else
                io.write(evt[8] .. "\n")
            end
        elseif evt[6] == "r-end" then
            os.exit()
        end
    elseif evt[1] == "key_down" then
        if evt[4] == 32 and keyboard.isControlDown() then
            send("interrupt")
            os.exit()
        elseif evt[4] == 16 then
            os.exit()
        end
    end
end
