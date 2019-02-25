local trueCursor={term.getCursorPos()}

local redirectBufferBase = {
	write=
		function(buffer,...)
			local cy=buffer.curY
			if cy>0 and cy<=buffer.height then
				local text=table.concat({...}," ")
				local cx=buffer.curX
				local px, py
				if buffer.isActive and not buffer.cursorBlink then
					term.native.setCursorPos(cx+buffer.scrX, cy+buffer.scrY)
				end
				for i=1,#text do
					if cx<=buffer.width and cx >= 1 then
						local curCell=buffer[cy][cx]
						local char,textColor,backgroundColor=string.char(text:byte(i)),buffer.textColor,buffer.backgroundColor
						if buffer[cy].isDirty or curCell.char~=char or curCell.textColor~=textColor or curCell.backgroundColor~=backgroundColor then
							buffer[cy][cx].char=char
							buffer[cy][cx].textColor=textColor
							buffer[cy][cx].backgroundColor=backgroundColor
							buffer[cy].isDirty=true
						end
					end
					cx=cx+1
				end
				buffer.curX=cx
				if buffer.isActive then
					buffer.drawDirty()
					if not buffer.cursorBlink then
						trueCursor={cx+buffer.scrX-1,cy+buffer.scrY-1}
						term.native.setCursorPos(unpack(trueCursor))
					end
				end
			end
		end,

	blit=
		function(buffer, char, text, back)
			--error("penis")
			assert(type(char) == "string", "bad argument #1 (expected string, got " .. type(char)..")")
			assert(type(text) == "string", "bad argument #2 (expected string, got " .. type(text)..")")
			assert(type(back) == "string", "bad argument #3 (expected string, got " .. type(back)..")")
			assert(#char == #text and #text == #back, "Arguments must be the same length")
			local btc = {
				["0"] = colors.white,
				["1"] = colors.orange,
				["2"] = colors.magenta,
				["3"] = colors.lightBlue,
				["4"] = colors.yellow,
				["5"] = colors.lime,
				["6"] = colors.pink,
				["7"] = colors.gray,
				["8"] = colors.lightGray,
				["9"] = colors.cyan,
				["a"] = colors.purple,
				["b"] = colors.blue,
				["c"] = colors.brown,
				["d"] = colors.green,
				["e"] = colors.red,
				["f"] = colors.black
			}
			local cx=buffer.curX
			for i = 1, #char do
				if cx <= buffer.width then
					buffer[buffer.curY][cx].char = char:sub(i,i)
					buffer[buffer.curY][cx].textColor = btc[text:sub(i,i)] or colors.white
					buffer[buffer.curY][cx].backgroundColor = btc[back:sub(i,i)] or colors.black
					cx = cx + 1
				end
			end
			buffer[buffer.curY].isDirty = true
			buffer.curX=cx
			if buffer.isActive then
				buffer.drawDirty()
				if not buffer.cursorBlink then
					trueCursor={cx+buffer.scrX-1,cy+buffer.scrY-1}
					term.native.setCursorPos(unpack(trueCursor))
				end
			end
		end,

	setCursorPos=
		function(buffer,x,y)
			if x == nil and y == nil then
				error("Expected number, number", 2)
			end
			buffer.curX=math.floor(x)
			buffer.curY=math.floor(y)
			if buffer.isActive and buffer.cursorBlink then
				term.native.setCursorPos(x+buffer.scrX-1,y+buffer.scrY-1)
				trueCursor={x+buffer.scrX-1,y+buffer.scrY-1}
			end
		end,

	getCursorPos=
		function(buffer)
			return buffer.curX,buffer.curY
		end,

	scroll=
		function(buffer,offset)
			if offset == nil then
				error("Expected number", 2)
			end
			for j=1,offset do
				local temp=table.remove(buffer,1)
				table.insert(buffer,temp)
				for i=1,#temp do
					temp[i].char=" "
					temp[i].textColor=buffer.textColor
					temp[i].backgroundColor=buffer.backgroundColor
				end
			end
			if buffer.isActive then
				term.redirect(term.native)
				buffer.render()
				term.restore()
			end
		end,

	isColor=
		function(buffer)
			return buffer._isColor
		end,

	isColour=
		function(buffer)
			return buffer._isColor
		end,

	clear=
		function(buffer)
			for y=1,buffer.height do
				for x=1,buffer.width do
					buffer[y][x]={char=" ",textColor=buffer.textColor,backgroundColor=buffer.backgroundColor}
				end
			end
			if buffer.isActive then
				term.redirect(term.native)
				buffer.render()
				term.restore()
			end
		end,

	clearLine=
		function(buffer)
			local line=buffer[buffer.curY]
			local fg,bg = buffer.textColor, buffer.backgroundColor
			for x=1,buffer.width do
				line[x]={char=" ",textColor=fg,backgroundColor=bg}
			end
			buffer[buffer.curY].isDirty=true
			if buffer.isActive then
				buffer.drawDirty()
			end
		end,

	setCursorBlink=
		function(buffer,onoff)
			if onoff == nil then
				error("Expected boolean", 2)
			end
			buffer.cursorBlink=onoff
			if buffer.isActive then
				term.native.setCursorBlink(onoff)
				if onoff then
					term.native.setCursorPos(buffer.curX,buffer.curY)
					trueCursor={buffer.curX,buffer.curY}
				end
			end
		end,

	getCursorBlink=
		getCursorBlink and function(buffer)
			return term.native.getCursorBlink()
		end,

	getSize=
		function(buffer)
			return buffer.width, buffer.height
		end,

	setTextColor=
		function(buffer,color)
			if color == nil then
				error("Expected number", 2)
			end
			buffer.textColor=color
			if buffer.isActive then
				if term.native.isColor() or color==colors.black or color==colors.white then
					term.native.setTextColor(color)
				end
			end
		end,

	setTextColour=
		function(buffer,color)
			if color == nil then
				error("Expected number", 2)
			end
			buffer.textColor=color
			if buffer.isActive then
				if term.native.isColor() or color==colors.black or color==colors.white then
					term.native.setTextColor(color)
				end
			end
		end,

	setBackgroundColor=
		function(buffer,color)
			if color == nil then
				error("Expected number", 2)
			end
			buffer.backgroundColor=color
			if buffer.isActive then
				if term.native.isColor() or color==colors.black or color==colors.white then
					term.native.setBackgroundColor(color)
				end
			end
		end,

	setBackgroundColour=
		function(buffer,color)
			if color == nil then
				error("Expected number", 2)
			end
			buffer.backgroundColor=color
			if buffer.isActive then
				if term.native.isColor() or color==colors.black or color==colors.white then
					term.native.setBackgroundColor(color)
				end
			end
		end,

	getTextColor=
		function(buffer)
			return buffer.textColor
		end,

	getTextColour=
		function(buffer)
			return buffer.textColor
		end,

	getBackgroundColor=
		function(buffer)
			return buffer.backgroundColor
		end,

	getBackgroundColour=
		function(buffer)
			return buffer.backgroundColor
		end,

	nativePaletteColor=
		term.nativePaletteColor and function(buffer, col)
			return term.native.nativePaletteColor(col)
		end,

	getPaletteColor=
		term.getPaletteColor and function(buffer, col)
			return term.native.getPaletteColor(col)
		end,

	setPaletteColor=
		term.setPaletteColor and function(buffer, col, red, green, blue)
			return term.native.setPaletteColor(col, red, green, blue)
		end,

	nativePaletteColour=
		term.nativePaletteColor and function(buffer, col)
			return term.native.nativePaletteColor(col)
		end,

	getPaletteColour=
		term.getPaletteColor and function(buffer, col)
			return term.native.getPaletteColor(col)
		end,

	setPaletteColour=
		term.setPaletteColor and function(buffer, col, red, green, blue)
			return term.native.setPaletteColor(col, red, green, blue)
		end,

	resize=
		function(buffer,width,height)
			if width == nil and height == nil then
				error("Expected number, number", 2)
			end
			if buffer.width~=width or buffer.height~=height then
				local fg, bg=buffer.textColor, buffer.backgroundColor
				if width>buffer.width then
					for y=1,buffer.height do
						for x=#buffer[y]+1,width do
							buffer[y][x]={char=" ",textColor=fg,backgroundColor=bg}
						end
					end
				end

				if height>buffer.height then
					local w=width>buffer.width and width or buffer.width
					for y=#buffer+1,height do
						local row={}
						for x=1,width do
							row[x]={char=" ",textColor=fg,backgroundColor=bg}
						end
						buffer[y]=row
					end
				end
				buffer.width=width
				buffer.height=height
			end
		end,

	render=
		function(buffer, sx, sy, dx, dy, width,height)
			sx=sx or 1
			sy=sy or 1
			dx=dx or buffer.scrX
			dy=dy or buffer.scrY
			width=width or buffer.width
			height=height or buffer.height

			local h=sy+height>buffer.height and buffer.height-sy or height-1
			for y=0,h do
				local row=buffer[sy+y]
				local x=0
				local cell=row[sx]
				local fg,bg=cell.textColor,cell.backgroundColor
				local str=""
				local tx=x
				while true do
					str=str..cell.char
					x=x+1
					if x==width or sx+x>buffer.width then
						break
					end
					cell=row[sx+x]
					if cell.textColor~=fg or cell.backgroundColor~=bg then
						--write
						term.setCursorPos(dx+tx,dy+y)
						term.setTextColor(fg)
						term.setBackgroundColor(bg)
						term.write(str)
						str=""
						tx=x
						fg=cell.textColor
						bg=cell.backgroundColor
					end
				end
				term.setCursorPos(dx+tx,dy+y)
				term.setTextColor(fg)
				term.setBackgroundColor(bg)
				term.write(str)
			end
		end,

	drawDirty =
		function(buffer)
			term.redirect(term.native)
			for y=1,buffer.height do
				if buffer[y].isDirty then
					term.redirect(term.native)
					buffer.render(1,y,buffer.scrX,buffer.scrY+y-1,buffer.width,buffer.height)
					term.restore()
					buffer[y].isDirty=false
				end
			end
			term.restore()
		end,

	makeActive =
		function(buffer,posX, posY)
			posX=posX or 1
			posY=posY or 1
			buffer.scrX=posX
			buffer.scrY=posY
			term.redirect(term.native)
			buffer.render(1,1,posX,posY,buffer.width,buffer.height)
			term.setCursorPos(buffer.curX,buffer.curY)
			term.setCursorBlink(buffer.cursorBlink)
			term.setTextColor(buffer.textColor)
			term.setBackgroundColor(buffer.backgroundColor)
			buffer.isActive=true
			term.restore()
		end,

	isBuffer = true,
}


function createRedirectBuffer(width,height,fg,bg,isColor)
	bg=bg or colors.black
	fg=fg or colors.white
	if isColor==nil then
		isColor=term.isColor()
	end
	local buffer={}

	do
		local w,h=term.getSize()
		width,height=width or w,height or h
	end

	for y=1,height do
		local row={}
		for x=1,width do
			row[x]={char=" ",textColor=fg,backgroundColor=bg}
		end
		buffer[y]=row
	end
	buffer.scrX=1
	buffer.scrY=1
	buffer.width=width
	buffer.height=height
	buffer.cursorBlink=false
	buffer.textColor=fg
	buffer.backgroundColor=bg
	buffer._isColor=isColor
	buffer.curX=1
	buffer.curY=1

	local meta={}
	local function wrap(f,o)
		return function(...)
			return f(o,...)
		end
	end
	for k,v in pairs(redirectBufferBase) do
		if type(v)=="function" then
			meta[k]=wrap(v,buffer)
		else
			meta[k]=v
		end
	end
	setmetatable(buffer,{__index=meta})
	return buffer
	--return meta
end
