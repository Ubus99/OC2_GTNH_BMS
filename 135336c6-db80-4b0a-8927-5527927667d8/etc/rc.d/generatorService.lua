-- background process providing data of a Battery buffer
--import
local component = require("component")
local event = require("event")
local sides = require("sides")
local thread = require("thread")

logger = require("logger")

--globals

--locals
local running = false

local modemProxy = component.getPrimary("modem")
local redstoneProxy = component.getPrimary("redstone")

local priority = 0
local generatorOn = false

local pairedServers = {}

local logPath = tostring("generatorService/logs/" .. os.date('%Y/%m/%d/'))
local logName = tostring(os.date('%H%M%S') .. ".log")
local logFile = nil

local timers = {}

--functions 
function NetworkISR(_, _, from, port, _, type, command, message)
    logFile:println("message from " .. type .. " @ ".. from .. ":")
    logFile:println("> " .. command .. ", " .. message)

    if type == "ctrlServer" then 
        if command == "register" then --register call
            modemProxy.send(from, port, "generator", command, "handshake")
            logFile:println("registered myself with " .. from)
            table.insert(pairedServers, from)
        elseif command == "sendData" then
            modemProxy.send(from, port, "generator", "priority", os.time() .. ", " .. priority .. ", " .. generatorOn)
            logFile:println("transferred generator data to " .. from)
        elseif command == "set" then
            logFile:println("generator " .. message .. " from " .. from)
        end
    end
end

function Table_contains(tbl, x)
    local found = false
    for _, v in pairs(tbl) do
        if v == x then 
            found = true 
        end
    end
    return found
end

local function init()
    --logger init
    logFile = logger.new(logPath, logName, args.logMode)

    --generator init
    priority = args.priority

    --modem init
    modemProxy.open(1299)
    if modemProxy.isOpen(1299) then
        event.listen("modem_message", NetworkISR)
        logFile:println("network init successful")
        logFile:println("reachable on address " .. modemProxy.address)
        modemProxy.broadcast(1299, "generator", "register", "advertise")
        logFile:println("advertise self")
    else
        logFile:println("network init unsuccessful")
        os.exit()
    end
end

local function deInit()
    logFile:println("stop detected")

    logFile:println("unsubsribing events...")
    event.ignore("modem_message", NetworkISR)
    
    logFile:println("killing timers...")
    for k, v in ipairs(timers) do
        event.cancel(v)
        logFile:println("> killed timer #" .. tostring(v))
    end

    logFile:println("closing modem...")
    modemProxy.close(1299)

    logFile:println("closing log...")
    logFile:close()
end

function start()
    --thread.create(function()
        os.sleep(1)

        running = true

        init()

        while running do
            os.sleep()
        end
    --end):detach()
end

function stop()
    deInit()

    running = false
end