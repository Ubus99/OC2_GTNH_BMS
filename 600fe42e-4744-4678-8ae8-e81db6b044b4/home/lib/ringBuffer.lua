--[[
Copyright (c) 2010 Matthias Richter
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Modified by Lukas Berghegger
]]--

local ringbuffer = {}
ringbuffer.__index = ringbuffer

local function new(size)
	local rb = {}
	rb.data = {}
	rb.head = 1
	rb.size = size
	return setmetatable(rb, ringbuffer)
end

function ringbuffer:append(item, ...)
	if not item then
		return
	end
	
	if #self.data < self.size then
		self.head = #self.data + 1
		self.data[self.head] = item
	else 
		self.head = (self.head % #self.data) + 1
		self.data[self.head] = item
	end
	return self:append(...)
end

function ringbuffer:removeAt(k)
	-- wrap position
	local pos = (self.head + k) % #self.data
	while pos < 1 do pos = pos + #self.data end

	-- remove item
	local item = table.remove(self.data, pos)

	-- possibly adjust head pointer
	if pos < self.head then self.head = self.head - 1 end
	if self.head > #self.data then self.head = 1 end

	-- return item
	return item
end

function ringbuffer:remove()
	return table.remove(self.data, self.head)
end

function ringbuffer:get()
	return self.data[self.head]
end

function ringbuffer:size()
	return #self.data
end

function ringbuffer:next()
	self.head = (self.head % #self.data) + 1
	return self:get()
end

function ringbuffer:prev()
	self.head = self.head - 1
	if self.head < 1 then
		self.head = #self.data
	end
	return self:get()
end

function ringbuffer:unwrap()
	local buffer
	for i = 0, #self.data - head, 1 do
		buffer[i] = self.data[(i + head) % #self.data]
		print(buffer [i])
	end
	return buffer
end

-- the module
return setmetatable({new = new},
	{__call = function(_, ...) return new(...) end})