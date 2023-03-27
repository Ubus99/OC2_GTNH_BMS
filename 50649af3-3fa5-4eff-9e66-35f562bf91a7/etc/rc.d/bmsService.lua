-- background process providing data of a Battery buffer
--import
local component = require("component")
local event = require("event")
local sides = require("sides")
local thread = require("thread")

batteryBuffer = require("batteryBuffer")
logger = require("logger")

--globals

--locals
local running = false

local bufferProxy = component.getPrimary("gt_batterybuffer")
local bufferInvProxy = component.getPrimary("inventory_controller")
local modemProxy = component.getPrimary("modem")

local pairedServers = {}

local bufferInvDir = nil
local battery = nil

local logPath = tostring("bmsService/logs/" .. os.date('%Y/%m/%d/'))
local logName = tostring(os.date('%H%M%S') .. ".log")
local logFile = nil

local timers = {}

--functions 
function MeasureBMS()
    battery:refresh()
    battery:calc()
end

function NetworkISR(_, _, from, port, _, type, command, message)
    logFile:println("message from " .. type .. "@".. from .. ", " .. command .. " " .. message)
    if type == "ctrlServer" then 
        if command == "register" then --register call
            modemProxy.send(from, port, "BMS", command, "handshake")
            logFile:println("registered myself with " .. from)
            table.insert(pairedServers, from)
        elseif command == "sendData" then
            modemProxy.send(from, port, "BMS", "charge", os.time() .. ", " .. battery.maxEU .. ", " .. battery.storedEU .. ", " .. battery.chargePercent)
            logFile:println("transferred cell data to " .. from)
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

    --battery init
    battery = batteryBuffer.new(logFile, bufferInvProxy, args.bufferInvDir)

    local eventID = event.timer(1, MeasureBMS, math.huge)
    table.insert(timers, eventID)
    logFile:println("startet BMS timer " .. tostring(eventID))

    --modem init
    modemProxy.open(1299)
    if modemProxy.isOpen(1299) then
        event.listen("modem_message", NetworkISR)
        logFile:println("network init successful")
        logFile:println("reachable on address " .. modemProxy.address)
        modemProxy.broadcast(1299, "BMS", "register", "advertise")
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
    thread.create(function()
        os.sleep(1)

        running = true

        init()

        while running do
            os.sleep()
        end
    end):detach()
end

function stop()
    deInit()

    running = false
end