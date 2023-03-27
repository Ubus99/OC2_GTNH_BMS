local batteryBuffer = {}
batteryBuffer.__index = batteryBuffer

local function new(logger, inventory, direction)
	local bb = {}
	--properties
	if logger == nil then
		print("no logger set")
		return nil
	else
		bb.logger = logger
	end

	if inventory == nil then
		bb.logger:println("invalid inventory")
		return nil
	else
		bb.inv = inventory
	end

	if direction == nil then
		bb.logger:println("invalid direction: " .. tostring(direction))
		return nil
	else
		bb.dir = direction
	end

	bb.cells = {}
	--values
	bb.storedEU = 0
	bb.maxEU = 0
	bb.chargePercent = 0

	bb.logger:print("new batteryBuffer has been initialized")
	return setmetatable(bb, batteryBuffer)
end

function batteryBuffer:refresh()
	self.cells = self.inv.getAllStacks(self.dir)
	self.logger:println("refreshed cell data")
end

function batteryBuffer:calc()
	self.logger:println("starting battery calculation...")
	local i = 0

	for c in self.cells do
		self.logger:println("measuring cell " .. i)

		if c.charge ~= nil then
			self.storedEU = self.storedEU + c.charge
			self.maxEU = self.maxEU + c.maxCharge
		else	
			self.logger:println(i .. " is not a cell")
		end

		i = i + 1
	end
	
	self.chargePercent = (self.storedEU * 100) / self.maxEU
	self.logger:println("finished calculating, " .. self.chargePercent .. "% charged")
end 

-- the module
return setmetatable({new = new},
	{__call = function(_, ...) return new(...) end})