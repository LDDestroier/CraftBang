--[[
if not craftbang then
	print "Must be run under CraftBang desktop environment."
	return
end
]]

local history = {}

local function setColors()
	if term.isColor() then
		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.lightGray)
	else
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
	end
end

setColors()
term.clear()
term.setCursorPos(1,1)

print [[

     ##   ##     ##
     ##   ##     ##
  #############  ##
  #############  ##
     ##   ##     ##
     ##   ##     ##
  #############  ##
  #############    
     ##   ##     ##
     ##   ##     ##
]]

while true do
	setColors()

	local dir = shell.dir()
	local line = string.format("%s> ", dir)
	write(line)

	term.setTextColor(colors.white)
	local input = read(nil, history):match('%s*(.+)%s*')

	if input == 'exit' then
		break
	else
		if input then
			local args = {}
			for v in input:gmatch('%S+') do
				table.insert(args, v)
			end

			local program = shell.resolveProgram(args[1])
			if program then
				shell.run(unpack(args))
			elseif fs.isDir(args[1]) then
				print(args[1] .. " is a directory.")
			else
				print(args[1] .. " does not exist.")
			end
			history[#history + 1] = input
		end
	end
end