setfenv(1, ...)
local panel = arealib.new(1, 1, craftbang.colors.panel)
	:bottom(1, true)
	:sizeRight(1, true)

panel.tasks = {}
panel.activeTask = nil
panel.lastActive = nil
panel.dragFocus = nil

-- Start new program.
function panel:addTask(program, name, silent)
	if not shell.resolveProgram(program:match("%S+")) then
		craftbang.dialog:notice(program.." does not exist!")
		return false
	end

	local w,h = term.getSize()
	local task = arealib.new(1, 1)
	local buffer = redirect.createRedirectBuffer(
		craftbang.screen.width,
		craftbang.screen.height - 1
	)

	local function run()
		shell.run(program)
		task.name = "[X] " .. task.name
	end

	task.name = name or fs.getName(program):match('%S+')
	task.buffer = buffer
	task.run = coroutine.create(run)

	-- FIX: SHOW ALL BUFFER KEYS
	if false then
		local x, y = 1, 1
		term.setTextColor(colors.white)
		term.setBackgroundColor(colors.black)
		for k,v in pairs(buffer) do
			if not tonumber(k) then
				term.setCursorPos(x, y)
				term.write(k)
				y = y + 1
				if y > 20 then
					y = 1
					x = x + 20
				end
			end
		end
		x = x + 20
		y = 1
		for k,v in pairs(term) do
			if not tonumber(k) then
				term.setCursorPos(x, y)
				term.write(k)
				y = y + 1
				if y > 20 then
					y = 1
					x = x + 20
				end
			end
		end
		sleep(1000)
	end
	-- DONE

	function task:resume(...)
		local pe = os.pullEvent
		function os.pullEvent(filter)
			while true do
				local ev = { coroutine.yield() }
				if ev[1] == 'terminate' then
					error("Terminated", 0)
				else
					if filter == nil or ev[1] == filter then
						return unpack(ev)
					end
				end
			end
		end

		if coroutine.status(self.run) == 'dead' then
			return
		end
		if self.run then

			local oldTerm = term.redirect(buffer)	-- Causes error and reboot

			local ok, err = coroutine.resume(self.run, ...)
			if not ok then
				term.setTextColor(colors.red)
				term.setBackgroundColor(colors.black)
				print(err)
			end

			term.redirect(oldTerm)
		end
		os.pullEvent = pe
	end

	table.insert(self.tasks, task)
	self:resizeTasks()

	if not silent then
		self:setActive(task)
	end

	task:resume()

	return true
end

function panel:killTask(task)
	for i=#self.tasks, 1, -1 do
		local v = self.tasks[i]
		if task == v then
			if self.activeTask == v then
				self.activeTask = self.tasks[i - 1] or self.tasks[i + 1]
			end
			table.remove(self.tasks, i)
			v.run = nil
			break
		end
	end
	self:resizeTasks()
end

function panel:setActive(task)
	self.activeTask = task
	self:resizeTasks()
end

function panel:resizeTasks()
	for i=1, #self.tasks do
		local v = self.tasks[i]
		v.x = self.width / #self.tasks * (i - 1) + 1
		v.y = self.y
		v.width = math.ceil(self.width / #self.tasks)
	end
end

function panel:events(ev, ...)
	if #self.tasks < 1 then return end

	if ev == 'mouse_click'
	or ev == 'mouse_drag'
	or ev == 'mouse_scroll' then
		local _, _, y = ...
		if y == self.y then
			return
		end
	end

	local inputEvents = {
		key = true;
		char = true;
		mouse_click = true;
		mouse_drag = true;
		mouse_scroll = true;
		monitor_touch = true;
		terminate = true;
	}

	for i=1, #self.tasks do
		local v = self.tasks[i]
		if v == self.activeTask or not inputEvents[ev] then
			v:resume(ev, ...)
		end
	end

	for i=#self.tasks, 1, -1 do
		local v = self.tasks[i]
		if v.run and coroutine.status(v.run) == 'dead' then
			--self:killTask(v)
		end
	end
end

function panel:clicked(button, x, y)
	for i=1, #self.tasks do
		local v = self.tasks[i]
		if v:contains(x, y) then
			if button == 1 then
				if self.activeTask ~= v then
					self.activeTask = v
				else
					self.activeTask = nil
				end
				self.dragFocus = { task = v, index = i }
			else
				self:killTask(v)
			end
			break
		end
	end
end

function panel:dragged(button, x, y)
	for i=1, #self.tasks do
		local v = self.tasks[i]
		if v:contains(x, y) and v ~= self.dragFocus.task then
			table.insert(self.tasks, i, table.remove(self.tasks, self.dragFocus.index))
			self.dragFocus.index = i
			self.activeTask = self.dragFocus.task
			panel:resizeTasks()
			break
		end
	end
end

function panel:key(key)
end

function panel:altKey(key)
	local prev = keys.left
	local next = keys.right
	local toggle = key == keys.down and keys.down or keys.up
	local close = keys.x
	local moveLeft = keys.a
	local moveRight = keys.d

	local tasks = self.tasks
	if key == prev or key == next then
		if self.activeTask then
			local index
			for i=1, #tasks do
				if tasks[i] == self.activeTask then
					index = i
					break
				end
			end
			if key == prev then
				self:setActive(tasks[index > 1 and index - 1 or #tasks])
			elseif key == next then
				self:setActive(tasks[index < #tasks and index + 1 or 1])
			end
		end
	elseif key == toggle then
		if self.activeTask then
			self.lastActive = self.activeTask
			self:setActive(nil)
		else
			if self.lastActive then
				self:setActive(self.lastActive)
			else
				self:setActive(tasks[1])
			end
		end
	elseif key == close then
		if self.activeTask then
			self:killTask(self.activeTask)
		end
	elseif key == moveLeft or key == moveRight then
		if self.activeTask then
			local activeIndex
			for i=1, #tasks do
				if tasks[i] == self.activeTask then
					activeIndex = i
					break
				end
			end
			if key == moveLeft and activeIndex > 1 then
				table.insert(tasks, activeIndex - 1,
					table.remove(tasks, activeIndex))
			elseif key == moveRight and activeIndex < #tasks then
				table.insert(tasks, activeIndex + 1,
					table.remove(tasks, activeIndex))
			end
			self:resizeTasks()
		end
	end
end

function panel:draw()
	for i=#self.tasks, 1, -1 do
		local v = self.tasks[i]
		if self.activeTask == v then
			v.color = craftbang.colors.activePanel
			term.setTextColor(craftbang.colors.activePanelText)
		else
			v.color = craftbang.colors.panel
			term.setTextColor(craftbang.colors.panelText)
		end
		v:fill()

		local text = v.name
		if #text > v.width - 2 then
			text = text:sub(1, v.width - 4) .. '..'
		end
		craftbang.output(text, v.x + v.width/2 - #text/2, v.y)

		if self.activeTask == v then
			v.buffer.render()
		end
	end
end

return panel
