setfenv(1, ...)
local dialog = arealib.new(1, 1, craftbang.colors.dialog)
local border = arealib.new(1, 1, craftbang.colors.dialogBorder)

dialog.active = false

function border:draw()
	local left, top, right, bottom = dialog:bounds()
	self:topLeft(left - 1, top - 1)
		:sizeBottomRight(right + 1, bottom + 1)
		:fill()
end

function dialog:close()
	function self.events() end
	function self.draw() end
	self.active = false
	self.type = nil
end

function dialog:textInput(title, limit, default, callback)
	limit = limit or math.huge

	self.height = 6
	self:sizeLeft(5):sizeRight(5, true):center()

	local input = default or ''

	local cancelText = " Cancel "
	local cancel = arealib.new(#cancelText, 1, craftbang.colors.dialogButton)

	function self:events(ev, p1, p2, p3)
		if ev == 'char' then
			if #input < limit then
				input = input .. p1
			end
		elseif ev == 'key' then
			if p1 == keys.backspace then
				input = input:sub(1, -2)
			elseif p1 == keys.enter then
				self:close()
				callback(input)
			elseif p1 == keys.leftCtrl or p1 == keys.rightCtrl then
				self:close()
			end
		elseif ev == 'mouse_click' then
			if cancel:contains(p2, p3) then
				self:close()
			end
		end
	end

	function self:draw()
		border:draw()
		self:fill()

		craftbang.output(title,
			self.x + self.width/2 - #title/2,
			self.y + 1,
			craftbang.colors.dialogText, self.color)

		craftbang.output(input,
			self.x + self.width/2 - #input/2,
			self.y + 3)

		cancel:midBottom(25, self:bounds('bottom')):fill()
		craftbang.output(cancelText,
			cancel.x, cancel.y,
			craftbang.colors.dialogButtonText)
	end

	function self:positionCursor()
		term.setTextColor(craftbang.colors.dialogText)
		term.setCursorBlink(true)
		term.setCursorPos(
			self.x + self.width/2 + #input/2,
			self.y + 3)
	end

	self.active = true
	self.type = 'textInput'
end

function dialog:menu(x, y, options, callback)
	local width = 0
	for i=1, #options do
		if #options[i] > width then
			width = #options[i]
		end
	end
	width = width + 2

	self:topLeft(x, y)
	self.width = width
	self.height = #options + 1

	local w, h = term.getSize()
	if self:bounds('bottom') > h - 1 then
		self:bottom(y)
	end
	if self:bounds('right') > w then
		self:right(x)
	end

	areas = {}

	for i=1, #options do
		if options[i] ~= '' then
			local area = arealib.new(self.width, 1, self.color)
			area:topLeft(self.x, self.y + i)
			area.name = options[i]
			table.insert(areas, area)
		end
	end

	local selection

	function self:events(ev, p1, p2, p3)
		if ev == 'mouse_click' then
			self:close()
			for i=1, #areas do
				local v = areas[i]
				if v:contains(p2, p3) then
					callback(i)
					break
				end
			end
		elseif ev == 'key' then
			local key = keys.getName(p1)
			if selection then
				if key == 'up' then
					selection = selection > 1
					and selection - 1
					or #areas
				elseif key == 'down' then
					selection = selection < #areas
					and selection + 1
					or 1
				elseif key == 'enter' then
					self:close()
					callback(selection)
				end
			else
				selection = key == 'down' and 1
				or key == 'up' and #areas
			end
			if key == 'leftCtrl' or key == 'rightCtrl' then
				self:close()
			end
		end
	end

	function self:draw()
		self:fill()

		for i=1, #areas do
			local area = areas[i]
			area:fill()

			term.setTextColor(craftbang.colors.dialogText)
			if selection == i then
				craftbang.output('>' .. area.name, area.x, area.y)
			else
				craftbang.output(area.name, area.x + 1, area.y)
			end
		end
	end

	self.active = true
	self.type = 'menu'
end

function dialog:notice(...)
	local lines = {...}
	local width = 0
	for i=1, #lines do
		if #lines[i] > width then
			width = #lines[i]
		end
	end

	self.width = width + 4
	self.height = #lines + 2
	self:center()

	function self:events(ev)
		if ev == 'mouse_click' or ev == 'key' then
			self:close()
		end
	end

	function self:draw()
		border:draw()
		self:fill()
		for i=1, #lines do
			craftbang.output(lines[i],
				self.x + self.width/2 - #lines[i]/2,
				self.y + i,
				craftbang.colors.background)
		end
	end

	self.active = true
	self.type = 'notice'
end

dialog:close()
return dialog
