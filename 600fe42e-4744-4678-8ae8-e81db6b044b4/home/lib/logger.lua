local logger = {}
logger.__index = logger

local function new(path, name, mode)
	local l = {}

    l.filePath = path
    l.fileName = name
    l.mode = mode
    l.file = nil

    if mode ~="console" then
        os.execute("mkdir " .. path)
        l.file = io.open(path .. name, "a")
	    print("created log at " .. path .. name)
    end
    
	return setmetatable(l, logger)
end

function logger:print(str)
    if self.mode == "file" then
        self.file:write(DateString()," ", str)
    elseif self.mode == "combined" then
        self.file:write(DateString()," ", str)
        io.write(DateString()," ", str)
    elseif self.mode == "console" then
        io.write(DateString()," ", str)
    end
end

function logger:println(str)
    self:print(str .. "\n")
end

function logger:close()
    if not self.mode == "console" then
        self.file:close()
    end
end

function DateString()
    return os.date('[%Y-%m-%d %H:%M:%S]')
end

-- the module
return setmetatable({new = new},
	{__call = function(_, ...) return new(...) end})