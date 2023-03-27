--import
local component = require("component")
local event = require("event")
local thread = require("thread")

local logger = require("logger")
local ringbuffer = require("ringBuffer")
local utions = require("utils")

--locals
running = false

local modemProxy = component.getPrimary("modem")

local timers = {}

local pairedBatteries = {}
local pairedGenerators = {}

local logPath = tostring("ctrlServer/logs/" .. os.date('%Y/%m/%d/'))
local logName = tostring(os.date('%H%M%S') .. ".log")
local logFile = nil

local BMS_buffer = {}

--functions

function NetworkISR(_, _, from, port, _, type, command, message)
    logFile:println("message from " .. type .. " @ ".. from .. ":")
    logFile:println(">  " .. command .. ", " .. message)

    if command == "register" then
        if type == "BMS" then --register call
            if not Table_contains(pairedBatteries, from) then
                logFile:println(">> " .. from .. " wants to " .. message)
                logFile:println(">> registering...")
                table.insert(pairedBatteries, from)
                table.insert(BMS_buffer, from, ringBuffer:new())
            end
        elseif type == "generator" then --register call
            if not Table_contains(pairedGenerators, from) then
                logFile:println(">> " .. from .. " wants to " .. message)
                logFile:println(">> registering...")
                table.insert(pairedGenerators, from)
                --table.insert(buffer, from, ringBuffer:new())
            end
        end
    elseif command == "charge" then
        logFile:println(">> Received data from battery")
    elseif command == "charge" then
        logFile:println(">> Received data from generator")
    end
    --terminate
    logFile:println("")
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

function UpdateData()
end

function RegisterBatteries()
    logFile:println("start pairing with batteries")
    modemProxy.broadcast(1299, "ctrlServer", "register", "")
end

function PollBatteries()
    logFile:println("polling batteries: ")
    for k, v in ipairs(pairedBatteries) do
        modemProxy.send(v, 1299, "ctrlServer", "sendData", "")    
        logFile:println("> " .. v)

        --local _, _, _, _, _, _, message = event.pull(10, "modem_message", nil, nil, v, nil, "BMS", "charge", nil)
        --logFile:println("Received result from battery " .. v)
        --buffer[from]:append("")
    end
    logFile:println("")
end

function RegisterGenerators()
    logFile:println("start pairing with generators")
    modemProxy.broadcast(1299, "ctrlServer", "register", "")
end

function PollGenerators()
    logFile:println("polling generators: ")
    for k, v in ipairs(pairedGenerators) do
        modemProxy.send(v, 1299, "ctrlServer", "sendData", "")    
        logFile:println("> " .. v)

        --local _, _, _, _, _, _, message = event.pull(10, "modem_message", nil, nil, v, nil, "generator", nil, nil)
        --logFile:println("Received result from battery " .. v)
    end
    logFile:println("")
end

local function deInit()
    logFile:println("stopping server")

    logFile:println("unsubsribing events")
    event.ignore("modem_message", NetworkISR)
    
    logFile:println("killing timers")
    for k, v in ipairs(timers) do
        event.cancel(v)
    end

    logFile:println("closing modem")
    modemProxy.close(1299)

    logFile:println("closing log")
    logFile:close()
end

local function init()
    logFile = logger.new(logPath, logName, args.logMode)
    logFile:println("initialised logger")

    modemProxy.open(1299)
    if modemProxy.isOpen(1299) then
        event.listen("modem_message", NetworkISR)
        logFile:println("network init successful")
        logFile:println("reachable on address " .. modemProxy.address)
    else
        logFile:println("network init unsuccessful")
        os.exit()
    end
    
    event.listen("modem_message", NetworkISR)
    logFile:println("registered events")

    table.insert(timers, event.timer(1, UpdateData, math.huge))
    table.insert(timers, event.timer(5, PollBatteries, math.huge))
    table.insert(timers, event.timer(10, RegisterBatteries, math.huge))
    table.insert(timers, event.timer(5, PollGenerators, math.huge))
    table.insert(timers, event.timer(10, RegisterGenerators, math.huge))
    logFile:println("registered timers")

    RegisterBatteries()
end

--start point
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
end