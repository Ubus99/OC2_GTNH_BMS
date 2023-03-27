--import
local component = require("component")
local event = require("event")

local logger = require("logger")

--globals

--locals
local running = true

local modemProxy = component.getPrimary("modem")

local logPath = tostring("logs/" .. os.date('%Y/%m/%d/'))
local logName = tostring(os.date('%H%M%S') .. ".log")
local logFile = nil
local logMode = "file"

--functions
local function onClose()
    logFile:println("stopping server")
    event.ignore("interrupted", onClose)
    event.ignore("modem_message", NetworkISR)
    running = false
end

function NetworkISR(_, _, from, port, _, type, command, message)
    logFile:println("message from " .. type .. " @ ".. from .. ":")
    logFile:println("> " .. command .. ", " .. message)
end

local function parseArgs(...)
    local buff = {...}
    if buff[1] ~= nil then
        logMode = buff[1]
    end
end

local function init()
    event.listen("interrupted", onClose)

    logFile = logger.new(logPath, logName)
    logFile.mode = logMode
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
end

--start point
parseArgs(...)
init()

while running do
    os.sleep()
end