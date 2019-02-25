setfenv(1, ...)
local desktop = arealib.new(1, 1, craftbang.colors.background):sizeBottomRight(1, 2, true)

local icons = {}
local scroll = 0
local scrollTime = 0

local tileWidth = 5
local tileHeight = 3

local lastClick = 0
local dragFocus

local selected

local lastRun

local shortcuts = {
	{ name = "Terminal", x = 42, y = 12, path = "craftbang/terminal" }
}

local shortcutsPath = '.cb-shortcuts'

function desktop:clearIcons()
	icons = {}
end

function desktop:addIcon(name, x, y, path)
	local area = arealib.new(tileWidth, tileHeight, craftbang.colors.icon):topLeft(x, y)

	area.width = tileWidth
	area.height = tileHeight
	area.name = name
	area.path = path

	icons[#icons + 1] = area
	return area
end

function desktop:loadShortcuts()
	if not fs.exists(shortcutsPath) then
		self:saveShortcuts()
	else
		shortcuts = textutils.unserialize(craftbang.readFile(shortcutsPath)) or shortcuts
	end
end

function desktop:saveShortcuts()
	craftbang.writeFile(shortcutsPath, textutils.serialize(shortcuts))
end

function desktop:genShortcutIcons()
	self:clearIcons()
	for i=1, #shortcuts do
		local v = shortcuts[i]
		local area = self:addIcon(v.name, v.x, v.y, v.path)
		area.shortcut = v
		area.shortcutIndex = i
	end
	self:saveShortcuts()
end

function desktop:removeShortcut(icon)
	for i=1, #shortcuts do
		if i == icon.shortcutIndex then
			table.remove(shortcuts, i)
			break
		end
	end
	self:genShortcutIcons()
end

local function newShortcutDialog(self, x, y)
	craftbang.dialog:textInput('Program?', nil, nil,
	function(path)
		local program = shell.resolveProgram(path)
		if program then
			table.insert(shortcuts, {
				name = fs.getName(program),
				x = x, y = y,
				path = program
			})
			self:genShortcutIcons()
		elseif fs.isDir(path) then
			craftbang.dialog:notice(path.." is a directory.")
		else
			craftbang.dialog:notice(path.." does not exist!")
		end
	end)
end

local function editShortcutDialog(self, x, y, tile)
	if tile.shortcut then
		craftbang.dialog:menu(x, y, {"Rename..", "Remove"},
		function (choice)
			if choice == 1 then
				craftbang.dialog:textInput('New name?', 15, tile.name,
				function (name)
					tile.shortcut.name = name
					self:genShortcutIcons()
				end)
			elseif choice == 2 then
				self:removeShortcut(tile)
				self:genShortcutIcons()
			end
		end)
	end
end

local function desktopDialog(self, x, y)
	craftbang.dialog:menu(x, y, {
		"Run..";
		"New Shortcut..";
		"";
		"Set Name..";
		"Edit Colors..";
		"";
		"Restart";
		"Shutdown";
		"Exit CraftBang";
	},
	function(choice)
		if choice == 1 then
			craftbang.dialog:textInput('Run...', nil, lastRun,
			function (input)
				if craftbang.panel:addTask(input) then
					lastRun = input
				end
			end)
		elseif choice == 2 then
			newShortcutDialog(self, x, y)

		elseif choice == 3 then
			craftbang.dialog:textInput('Rename this Computer: ', 20, os.getComputerLabel(),
			function(name)
				os.setComputerLabel(name)
			end)

		elseif choice == 4 then
			craftbang.panel:addTask("edit .cb-colors")

		elseif choice == 5 then
			os.reboot()
		elseif choice == 6 then
			os.shutdown()
		elseif choice == 7 then
			craftbang.running = false
		end
	end)
end

function desktop:clicked(button, x, y)
	for i=1, #icons do
		local v = icons[i]
		if v:contains(x, y) then
			if button == 1 then
				if os.clock() - lastClick < 0.3 then
					-- Opened program on desktop by double-clicking.
					craftbang.panel:addTask(v.path, v.name)
				else
					dragFocus = { icon = v, x = x - v.x, y = y - v.y }
				end
				lastClick = os.clock()
			elseif button == 2 then
				editShortcutDialog(self, x, y, v)
			end
			return
		end
	end

	dragFocus = nil
	selected = nil

	if button == 2 then
		desktopDialog(self, x, y)
	end
end

function desktop:dragged(button, x, y)
	if button == 1 and dragFocus then
		local icon = dragFocus.icon
		icon.shortcut.x = x - dragFocus.x
		icon.shortcut.y = y - dragFocus.y
		icon.x = icon.shortcut.x
		icon.y = icon.shortcut.y
	end
end

function desktop:key(key)
	local key = keys.getName(key)
	local movementKeys = { left = true, right = true, up = true, down = true }

	if movementKeys[key] then
		local sorted = {}
		for i=1, #icons do
			sorted[i] = icons[i]
		end

		if key == 'left' or key == 'right' then
			table.sort(sorted, function(a, b)
				return a.x < b.x
			end)
		elseif key == 'up' or key == 'down' then
			table.sort(sorted, function(a, b)
				return a.y < b.y
			end)
		end

		if not selected then
			if key == 'left' or key == 'up' then
				selected = sorted[1]
			elseif key == 'right' or key == 'down' then
				selected = sorted[#sorted]
			end
		else
			local selectedIndex
			for i=1, #sorted do
				if sorted[i] == selected then
					selectedIndex = i
					break
				end
			end
			if key == 'left' or key == 'up' then
				selected = selectedIndex > 1
					and sorted[selectedIndex - 1]
					or sorted[#sorted]
			elseif key == 'right' or key == 'down' then
				selected = selectedIndex < #sorted
					and sorted[selectedIndex + 1]
					or sorted[1]
			end
		end
	elseif key == 'enter' then
		if selected then
			craftbang.panel:addTask(selected.path, selected.name)
		end
	elseif key == 'a' then
		selected.x = selected.x - 1
	elseif key == 'd' then
		selected.x = selected.x + 1
	elseif key == 'w' then
		selected.y = selected.y - 1
	elseif key == 's' then
		selected.y = selected.y + 1
	elseif key == 'leftCtrl' or key == 'rightCtrl' then
		local w, h = term.getSize()
		desktopDialog(self, 1, h - 1)
	elseif key == 'leftShift' or key == 'rightShift' then
		if selected then
			editShortcutDialog(self, selected.x, selected.y, selected)
		end
	end
end

function desktop:scrolled(dir)
end

function desktop:draw()
	local time = textutils.formatTime(os.time(), true)..' r'..craftbang.version
	local name = os.getComputerLabel()
	local id = os.computerID()
	local w,h = term.getSize()

	craftbang.output(time, w - #time, 2, craftbang.colors.icon)
	if name then
		craftbang.output(name..' #'..id, 2, 2)
	end

	for i=1, #icons do
		local v = icons[i]
		v:fill()

		local left, top, right, bottom = v:bounds()
		if left < 1 then
			v:left(1)
		elseif right > w then
			v:right(w)
		end
		if top < 1 then
			v:top(1)
		elseif bottom > h then
			v:bottom(h)
		end

		v.shortcut.x = v.x
		v.shortcut.y = v.y

		local text = v.name
		if v == selected then
			text = '['..text..']'
		end

		craftbang.output(text,
			math.ceil(v.x + v.width/2 - #text/2),
			v:bounds('bottom') + 2,
			craftbang.colors.icon,
			craftbang.colors.background)
	end
end

return desktop
