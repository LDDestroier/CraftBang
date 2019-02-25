version = 1.0

local states = {
	default = {}
}
local curState = states.default
local target = term

local area = {
	x = 1;
	y = 1;
	width = 1;
	height = 1;
	global = false;
}

function area:init()
	-- our api loads before colors
	-- do this when an object is created
	-- not when the API is loaded
	self.color = self.color or colors.white
	-- shoutouts to Grim Reaper!
	return self
end

-- setting callbacks
function area:draw() end
function area:clicked(button, x, y, rx, ry) end
function area:dragged(button, x, y, rx, ry) end
function area:scrolled(dir, x, y, rx, ry) end

-- edge positioning
function area:left(left)
	return self:topLeft(left, self.y)
end

function area:top(top)
	return self:topLeft(self.x, top)
end

function area:right(right, anchored)
	if anchored == true then
		local w,h = target.getSize()
		right = w - right + 1
	end
	return self:left(right - self.width + 1)
end

function area:bottom(bottom, anchored)
	if anchored == true then
		local w,h = target.getSize()
		bottom = h - bottom + 1
	end
	return self:top(bottom - self.height + 1)
end

-- corner positioning
function area:topLeft(x, y)
	self.x = math.floor(x)
	self.y = math.floor(y)
	return self
end

function area:topRight(x, y, anchored)
	self:right(x, anchored)
	return self:top(y)
end

function area:bottomLeft(x, y, anchored)
	self:left(x)
	return self:bottom(y, anchored)
end

function area:bottomRight(x, y, anchored)
	self:right(x, anchored)
	return self:bottom(y, anchored)
end

-- centering
function area:centerx(x)
	local w,h = target.getSize()
	x = x or w/2
	return self:left(x - self.width/2 + 1)
end

function area:centery(y)
	local w,h = target.getSize()
	y = y or h/2
	return self:top(y - self.height/2 + 1)
end

function area:center(x, y)
	self:centerx(x)
	return self:centery(y)
end

-- edge midpoint positioning
function area:midLeft(x, y)
	self:left(x)
	return self:centery(y)
end

function area:midTop(x, y)
	self:centerx(x)
	return self:top(y)
end

function area:midRight(x, y, anchored)
	self:right(x, anchored)
	return self:centery(y)
end

function area:midBottom(x, y, anchored)
	self:centerx(x)
	return self:bottom(y, anchored)
end

-- absolute edge sizing
function area:sizeLeft(x)
	local right = self.x + self.width - 1
	self:left(x)
	self.width = math.floor(right - self.x + 1)
	return self
end

function area:sizeTop(y)
	local bottom = self.y + self.height - 1
	self:top(y)
	self.height = math.floor(bottom - self.x + 1)
	return self
end

function area:sizeRight(x, anchored)
	if anchored == true then
		local w,h = target.getSize()
		x = w - x + 1
	end
	self.width = math.floor(x - self.x + 1)
	return self
end

function area:sizeBottom(y, anchored)
	if anchored == true then
		local w,h = target.getSize()
		y = h - y + 1
	end
	self.height = math.floor(y - self.y + 1)
	return self
end

-- absolute corner sizing
function area:sizeTopLeft(x, y)
	self:sizeLeft(x)
	return self:sizeTop(y)
end

function area:sizeTopRight(x, y, anchored)
	self:sizeRight(x, anchored)
	return self:sizeTop(y)
end

function area:sizeBottomLeft(x, y, anchored)
	self:sizeLeft(x)
	return self:sizeBottom(y, anchored)
end

function area:sizeBottomRight(x, y, anchored)
	self:sizeRight(x, anchored)
	return self:sizeBottom(y, anchored)
end

-- drawing
function area:fill()
	local line = string.rep(' ', self.width)
	target.setBackgroundColor(self.color)
	for y=self.y, self.y + self.height - 1 do
		target.setCursorPos(self.x, y)
		target.write(line)
	end
	return self
end

function area:goToFront()
	for i=1, #curState do
		local v = curState[i]
		if v == self then
			--[[
			for i=1, #self.attached do
				local v = self.attached[i]
				v:goToFront()
			end
			]]
			table.insert(curState, 1, table.remove(curState, i))
			break
		end
	end
end

-- bound access and checking
function area:bounds(which)
	if which then
		return which == 'left' and self.x
		or which == 'top' and self.y
		or which == 'right' and self.x + self.width - 1
		or which == 'bottom' and self.y + self.height - 1
	else
		return self.x, self.y, self.x + self.width - 1, self.y + self.height - 1
	end
end

function area:contains(x, y)
	local left, top, right, bottom = self:bounds()
	return x >= left and x <= right and y >= top and y <= bottom
end

-- api functions
function new(width, height, color, global)
	local obj = {}

	for k,v in pairs(area) do
		obj[k] = v
	end

	obj.width = width
	obj.height = height
	obj.color = color
	obj.global = global

	return obj:init()
end

function add(area)
	for i=1, #curState do
		if curState[i] == area then
			return false
		end
	end
	table.insert(curState, 1, area)
	return true
end

function remove(area)
	for i=1, #curState do
		if curState[i] == area then
			table.remove(curState, i)
			return true
		end
	end
	return false
end

function draw()
	for i=#curState, 1, -1 do
		local v = curState[i]
		v:fill()
		v:draw()
	end
end

local function eventCall(fname, p1, x, y, global)
	for i=1, #curState do
		local v = curState[i]
		if global == true or v.global == true or v:contains(x, y) then
			v[fname](v, p1, x, y, x - v.x, y - v.y)
			if not (global or v.global) then
				break
			end
		end
	end
end

function clicked(button, x, y, global)
	eventCall('clicked', button, x, y, global)
end

function dragged(button, x, y, global)
	eventCall('dragged', button, x, y, global)
end

function scrolled(dir, x, y, global)
	eventCall('scrolled', dir, x, y, global)
end

function setTarget(newTarget)
	assert(newTarget, "arealib.setTarget: No target given")
	target = newTarget
	return target
end

function setState(name)
	if not states[name] then
		states[name] = {}
	end
	curState = states[name]
end
