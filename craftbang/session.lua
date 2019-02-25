local craftbang = {
	colors = term.isColor() and {
		background = colors.gray;

		panel = colors.lightGray;
		panelText = colors.gray;
		activePanel = colors.gray;
		activePanelText = colors.lightGray;

		icon = colors.lightGray;

		dialog = colors.lightGray;
		dialogBorder = colors.gray;
		dialogText = colors.gray;
		dialogButton = colors.gray;
		dialogButtonText = colors.lightGray;
	}
	or {
		background = colors.black;

		panel = colors.white;
		panelText = colors.black;
		activePanel = colors.black;
		activePanelText = colors.white;

		icon = colors.white;

		dialog = colors.white;
		dialogBorder = colors.black;
		dialogText = colors.black;
		dialogButton = colors.black;
		dialogButtonText = colors.white;
	};
	screen = {};
	running = true;

	version = 51;
}

function craftbang.background(color)
	term.setBackgroundColor(color or craftbang.colors.background)
	term.setCursorPos(1,1)
	term.clear()
end

function craftbang.output(text, x, y, color, bg)
	if color then
		term.setTextColor(color)
	end
	if bg then
		term.setBackgroundColor(bg)
	end
	term.setCursorPos(x, y)
	term.write(text)
end

function craftbang.readFile(path)
	local file = fs.open(path,'r')
	if file then
		return file.readAll(), file.close()
	end
	return nil
end

function craftbang.writeFile(path, content, append)
	local file = fs.open(path, append and 'a' or 'w')
	if file then
		return file.write(content), file.close()
	end
	return nil
end

local function components()
	local env = getfenv()
	craftbang.panel 	= loadfile('/craftbang/panel.lua'	)(env)
	craftbang.desktop 	= loadfile('/craftbang/desktop.lua'	)(env)
	craftbang.dialog 	= loadfile('/craftbang/dialog.lua'	)(env)
end

local function main()
	os.loadAPI('craftbang/lib/arealib.lua')
	os.loadAPI('craftbang/lib/redirect.lua')

	craftbang.screen.width, craftbang.screen.height = term.getSize()

	local colorsPath = '.cb-colors'
	if fs.exists(colorsPath) then
		local content = craftbang.readFile(colorsPath)
		local line = 1
		for key, value in content:gmatch("(%w+)%s+(%w+)") do
			if colors[value] and craftbang.colors[key] then
				if term.isColor() or (colors[value] == 1 or colors[value] == 32768) then
					craftbang.colors[key] = colors[value]
					line = line + 1
				end
			end
		end
	end

	local file = fs.open(colorsPath, 'w')
	for k,v in pairs(craftbang.colors) do
		local name
		for cname, cvalue in pairs(colors) do
			if cvalue == v then
				name = cname
			end
		end
		file.writeLine(k..string.rep(' ', 20 - #k)..name)
	end
	file.close()
	local thisenv = _ENV
	local env = setmetatable(
		{ craftbang = craftbang },
		{
			__index = function(self, key)
				if rawget(self, key) == nil then
					rawset(self, key, thisenv[key])
				end
				return rawget(self, key)
			end;
		}
	)
	setfenv(components, env)()
	--components()
	arealib.add(craftbang.desktop)
	arealib.add(craftbang.panel)

	craftbang.desktop:loadShortcuts()
	craftbang.desktop:genShortcutIcons()

	local redraw = true
	local function draw()
		if redraw then
			--craftbang.background()
			term.setCursorBlink(false)
			arealib.draw()
			craftbang.dialog:draw()

			if craftbang.panel.activeTask then
				local buffer = craftbang.panel.activeTask.buffer
				term.setCursorBlink(buffer.cursorBlink)
				if buffer.cursorBlink then
					term.setTextColor(buffer.textColor)
					term.setCursorPos(buffer.curX, buffer.curY)
				end
			end

			if craftbang.dialog.active
			and craftbang.dialog.type == "textInput" then
				craftbang.dialog:positionCursor()
			end
		end
		redraw = true
	end

	draw()

	if not os.getComputerLabel() then
		craftbang.dialog:textInput('Give this computer a name?', 20, nil,
		function (newName)
			os.setComputerLabel(newName)
		end)
	end

	if fs.exists('autorun') then
		local files = fs.list('autorun')
		for i=1, #files do
			craftbang.panel:addTask('autorun/'..files[i], files[i], true)
		end
	else
		fs.makeDir('autorun')
	end

	local updateTimer = os.startTimer(1)

	local altClock = 0
	local altPeriod = 0.75
	local altTimer

	while craftbang.running do
		craftbang.screen.width, craftbang.screen.height = term.getSize()

		draw()

		local ev = {os.pullEventRaw()}

		if ev[1] == 'timer' then
			if ev[2] == updateTimer then
				updateTimer = os.startTimer(1)
				craftbang.desktop:saveShortcuts()
			elseif ev[2] == altTimer then
				craftbang.dialog:close()
			end
		end

		if (ev[1] == 'key' or ev[1] == 'char') then
			if ev[2] == keys.leftAlt or ev[2] == keys.rightAlt then
				if os.clock() - altClock < altPeriod then
					craftbang.panel:events(unpack(ev))
				end
				altClock = os.clock()
			end
		end

		if (ev[1] == 'key' or ev[1] == 'char') and os.clock() - altClock < altPeriod then
			craftbang.panel:altKey(ev[2])
			altClock = os.clock()

			craftbang.dialog:notice("Alt Mode")
			altTimer = os.startTimer(altPeriod)
		else
			craftbang.panel:events(unpack(ev))
			if not craftbang.panel.activeTask then
				if ev[1] == 'terminate' then
					break
				end

				if craftbang.dialog.active then
					craftbang.dialog:events(unpack(ev))
				else
					if ev[1] == 'mouse_click' then
						arealib.clicked(ev[2], ev[3], ev[4])
					elseif ev[1] == 'mouse_drag' then
						arealib.dragged(ev[2], ev[3], ev[4])
					elseif ev[1] == 'mouse_scroll' then
						arealib.scrolled(ev[2], ev[3], ev[4])
					elseif ev[1] == 'key' then
						craftbang.desktop:key(ev[2])
						craftbang.panel:key(ev[2])
					end
				end
			else
				craftbang.dialog:events(unpack(ev))
				local panel = craftbang.panel
				if ev[1] == 'mouse_click' then
					if panel:contains(ev[3], ev[4]) then
						panel:clicked(ev[2], ev[3], ev[4])
					end
				elseif ev[1] == 'mouse_drag' then
					if panel:contains(ev[3], ev[4]) then
						panel:dragged(ev[2], ev[3], ev[4])
					end
				elseif ev[1] == 'key' then
					panel:key(ev[2])
				end
			end
		end
	end
end

--goroutine2.run(main)
local ok, err = pcall(main)

craftbang.background(colors.black)
if not ok then
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1,1)
	print "Whoops! CraftBang seems to have crashed..."
	printError(err)
	print "Press any key to restart."
	repeat
		local event = os.pullEvent()
	until event == 'key' or event == 'mouse_click'
	os.reboot()
end

--os.shutdown()
