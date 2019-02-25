local url = "https://raw.github.com/LDDestroier/CraftBang/master/craftbang/"
local files = {}
local filelist = {
	'desktop.lua';
	'dialog.lua';
	'panel.lua';
	'session.lua';
	'terminal.lua';
	'lib/arealib.lua';
	'lib/redirect.lua';
}

local function clear()
	term.clear()
	term.setCursorPos(1,1)
end

clear()
local errors = false
for i=1, #filelist do
	local filename = filelist[i]
	local fullurl = url .. filename
	local localpath = '/craftbang/'..filename

	local download = http.get(fullurl)
	if download then
		print("Fetching "..filename)
		files[localpath] = download.readAll()
		download.close()
	else
		print("Couldn't get '"..filename .. "'.")
		print "Installation failed."
		return
	end
end
sleep(1)

local installed = false
if fs.exists('/craftbang') then
	clear()
	installed = true

	write "Overwrite current installation? [Y/n] "
	local input = read():lower():sub(1,1)
	if input == 'n' then
		print "Will not write files."
		return
	end
	fs.delete('/craftbang')
end

clear()
fs.makeDir('/craftbang')
fs.makeDir('/craftbang/lib')
for path, content in pairs(files) do
	print("Writing "..path)
	local file = fs.open(path, 'w')
	file.write(content)
	file.close()
end
print "Installation complete!"
sleep(1)

if not installed then
	clear()

	local startupContent = [[
	shell.run("craftbang/session.lua")
	]]

	write "Run CraftBang on startup? "
	if fs.exists('startup.lua') then
		print "\nYour current startup file will be renamed to 'startup-old.lua'."
	end
	write "[Y/n] "

	local input = read():lower():sub(1,1)

	if input == 'n' then
		print "In that case, run 'craftbang/session.lua' to start CraftBang."
	else
		if fs.exists('startup.lua') then
			if fs.exists('startup-old.lua') then
				fs.delete('startup-old.lua')
			end
			fs.move('startup.lua','startup-old.lua')
		end

		local startup = fs.open('startup.lua', 'w')
		startup.write(startupContent)
		startup.close()
		print "CraftBang will now run on startup."
	end
end
