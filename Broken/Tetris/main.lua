--[[
TETRIS BECAUSE I'M BORED AT WORK
Daedalus Young, 2021
--]]

local lg = love.graphics
local droprate
local blocks = {}
local bcol = {}
local bactive = {}
local bnext
local field = {}
local buttons = {}
local buttpress, buttpressvisible
local blocksize, offsetx, offsety, edge
local winw, winh
local prevx
local dropwait
local state
local removelines = {}
local removex1, removex2, removetimer, removestage
local score, totalblocks, level

local function drawsquare(x, y)
	local tx = ((x - 1) * blocksize) + offsetx
	local ty = ((y - 1) * blocksize) + offsety
	lg.rectangle('fill', tx, ty, blocksize, blocksize)
	lg.setColor(1, 1, 1, 0.3)
	lg.polygon('fill', tx, ty, tx + edge, ty + edge, tx + edge, ty + (blocksize - edge), tx, ty + blocksize)
	lg.polygon('fill', tx, ty, tx + blocksize, ty, tx + (blocksize - edge), ty + edge, tx + edge, ty + edge)
	lg.setColor(0, 0, 0, .3)
	lg.polygon('fill', tx + blocksize, ty, tx + blocksize, ty + blocksize, tx + (blocksize - edge), ty + (blocksize - edge), tx + (blocksize - edge), ty + edge)
	lg.polygon('fill', tx, ty + blocksize, tx + blocksize, ty + blocksize, tx + (blocksize - edge), ty + (blocksize - edge), tx + edge, ty + (blocksize - edge))
end

local function drawblock()
	for y = 1, 4 do
		for x = 1, 4 do
			if (bactive.shape[x][y] == 1) and (bactive.y + (y - 1) > 0) then
				lg.setColor(bcol[bactive.num])
				drawsquare(bactive.x + (x - 1), bactive.y + (y -1))
			end
		end
	end
end

local function newblock()
	totalblocks = totalblocks + 1
	bactive = { num = bnext, x = 4, y = -3, rotation = 1, shape = {{1,1,1,1},{1,1,1,1},{1,1,1,1},{1,1,1,1}}, ismovablel = true, ismovabler = true, ismovabled = true, isrotatablel = true, isrotatabler = true }
	for y = 1, 4 do
		for x = 1, 4 do
		bactive.shape[x][y] = blocks[bactive.num][y][x]
		end
	end
	bnext = love.math.random(1, 7)
end

local function dorotate(num, rot)
	local newx, newy = 1, 1
	local srcx, srcy = 1, 1
	local tempblock = { {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0} }
	if rot == 2 then
		srcx, srcy = 4, 1
	elseif rot == 3 then
		srcx, srcy = 4, 4
	elseif rot == 4 then
		srcx, srcy = 1, 4
	end
	for lp = 1, 16 do
		tempblock[newx][newy] = blocks[num][srcy][srcx]
		newx = newx + 1
		if newx == 5 then
			newx = 1
			newy = newy + 1
		end
		if rot == 1 then
			srcx = srcx + 1
			if srcx == 5 then
				srcx = 1
				srcy = srcy + 1
			end
		elseif rot == 2 then
			srcy = srcy + 1
			if srcy == 5 then
				srcy = 1
				srcx = srcx - 1
			end
		elseif rot == 3 then
			srcx = srcx - 1
			if srcx == 0 then
				srcx = 4
				srcy = srcy - 1
			end
		elseif rot == 4 then
			srcy = srcy - 1
			if srcy == 0 then
				srcy = 4
				srcx = srcx + 1
			end
		end
	end
	return tempblock
end

local function checkmovable()
	bactive.ismovabled = true
	bactive.ismovablel = true
	bactive.ismovabler = true
	bactive.isrotatablel = true
	bactive.isrotatabler = true
	local newrot = bactive.rotation - 1
	if newrot == 0 then newrot = 4 end
	local tempblockr = dorotate(bactive.num, newrot)
	newrot = bactive.rotation + 1
	if newrot == 5 then newrot = 1 end
	local tempblockl = dorotate(bactive.num, newrot)
	for y = 1, 4 do
		for x = 1, 4 do
			local blockcur, blockl, blockr, blockd = false, false, false, false
			if field[bactive.y + (y - 1)] then
				if field[bactive.y + (y - 1)][bactive.x + (x - 1)] then
					blockcur = field[bactive.y + (y - 1)][bactive.x + (x - 1)].filled
				end
				if field[bactive.y + (y - 1)][bactive.x + (x - 2)] then
					blockl = field[bactive.y + (y - 1)][bactive.x + (x - 2)].filled
				end
				if field[bactive.y + (y - 1)][bactive.x + x] then
					blockr = field[bactive.y + (y - 1)][bactive.x + x].filled
				end
			end
			if field[bactive.y + y] then
				if field[bactive.y + y][bactive.x + (x - 1)] then
					blockd = field[bactive.y + y][bactive.x + (x - 1)].filled
				end
			end
			if tempblockl[x][y] == 1 then
				if (x - 1) + bactive.x < 1 or (x - 1) + bactive.x > 10 or (y - 1) + bactive.y > 20 or blockcur then
					bactive.isrotatablel = false
				end
			end
			if tempblockr[x][y] == 1 then
				if (x - 1) + bactive.x < 1 or (x - 1) + bactive.x > 10 or (y - 1) + bactive.y > 20 or blockcur then
					bactive.isrotatabler = false
				end
			end
			if bactive.shape[x][y] == 1 then
				if y + bactive.y == 21 or blockd then
					bactive.ismovabled = false
				end
				if bactive.x + (x - 2) == 0 or blockl then
					bactive.ismovablel = false
				end
				if bactive.x + x == 11 or blockr then
					bactive.ismovabler = false
				end
			end
		end
	end
end

function love.load()
	state = 'play'
	score = 0
	droprate = 1
	dropwait = 0
	totalblocks, level = 0, 1
	prevx = -1
	for y = 1, 20 do
		field[y] = {}
		for x = 1, 10 do
			field[y][x] = { filled = false }
		end
	end
	blocks[1] = {	{ 0, 0, 1, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 0, 1, 0 }	}
	bcol[1] = { .8, 0, 0 }
	blocks[2] = {	{ 0, 0, 0, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 1, 0, 0 }	}
	bcol[2] = { 0, .8, 0 }
	blocks[3] = {	{ 0, 0, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 1, 0 }	}
	bcol[3] = { 0, .8, .8 }
	blocks[4] = {	{ 0, 0, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 0, 0 }	}
	bcol[4] = { 0, 0, .8 }
	blocks[5] = {	{ 0, 0, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 0, 0 }	}
	bcol[5] = { .8, .8, .8 }
	blocks[6] = {	{ 0, 0, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 0, 1, 0 },
					{ 0, 0, 1, 0 }	}
	bcol[6] = { .8, 0, .8 }
	blocks[7] = {	{ 0, 0, 0, 0 },
					{ 0, 1, 0, 0 },
					{ 0, 1, 1, 0 },
					{ 0, 1, 0, 0 }	}
	bcol[7] = { .8, .8, 0 }
	bcol[8] = { .9, .9, .9 }
	winw, winh = love.window.getMode()
	blocksize = winh / 21
	edge = blocksize / 16
	offsetx, offsety = (winw / 2) - (blocksize * 5), (winh / 2) - (blocksize * 10)
	bnext = love.math.random(1, 7)
	newblock()
	buttons = { left = { label = '<<', x = 11, y = 18 }, right = { label = '>>', x = 16, y = 18 }, down = { label = 'vv', x = 13.5, y = 18 }, rotl = { label = '<^', x = 11, y = 15 }, rotr = { label = '^>', x = 16, y = 15 } }
end

function love.update(dt)
	if not (state == 'gameover') then
		level = math.ceil(totalblocks / 25)
		droprate = (1 - (level / 10)) ^ 2
		if droprate < 0.1 then droprate = .1 end
		local lockblock = false
		if #removelines > 0 then
			removetimer = removetimer + dt
			if removetimer >= .04 then
				removetimer = removetimer - .04
				removex1 = removex1 + 1
				if removex1 == 11 then
					removex1 = 1
					removestage = removestage + 1
				end
				for y = 1, #removelines do
					if removestage == 1 or removestage == 2 then
						local filler = 8
						if removestage == 2 then filler = false end
						field[removelines[y]][removex1] = { filled = filler }
					end
				end
				if removestage == 3 then
					for y = 1, #removelines do
						table.remove(field, removelines[y])
						table.insert(field, 1, { })
						for x = 1, 10 do
							field[1][x] = { filled = false }
						end
					end
					if #removelines == 1 then
						score = score + 10
					elseif #removelines == 2 then
						score = score + 25
					elseif #removelines == 3 then
						score = score + 50
					elseif #removelines == 4 then
						score = score + 100
					end
					removelines = {}
				end
			end
		else
			dropwait = dropwait + dt
			checkmovable()
			if buttpress == 'left' then
				if bactive.ismovablel then
					bactive.x = bactive.x - 1
				end
			elseif buttpress == 'right' then
				if bactive.ismovabler then
					bactive.x = bactive.x + 1
				end
			elseif buttpress == 'down' then
				if bactive.ismovabled then
					bactive.y = bactive.y + 1
				end
			elseif buttpress == 'rotr' then
				if bactive.isrotatabler then
					bactive.rotation = bactive.rotation - 1
					if bactive.rotation == 0 then bactive.rotation = 4 end
					bactive.shape = dorotate(bactive.num, bactive.rotation)
				end
			elseif buttpress == 'rotl' then
				if bactive.isrotatablel then
					bactive.rotation = bactive.rotation + 1
					if bactive.rotation == 5 then bactive.rotation = 1 end
					bactive.shape = dorotate(bactive.num, bactive.rotation)
				end
			end
			if dropwait >= droprate then
				dropwait = dropwait - droprate
				checkmovable()
				if bactive.ismovabled then
					bactive.y = bactive.y + 1
				else
					lockblock = true
				end
			end
			if lockblock then
				for y = 1, 4 do
					for x = 1, 4 do
						if bactive.shape[x][y] == 1 then
							if bactive.y + (y - 1) > 0 then
								field[bactive.y + (y - 1)][bactive.x + (x - 1)].filled = bactive.num
							end
						end
					end
				end
				for y = 1, 4 do
					local fillblocks = 0
					for x = 1, 10 do
						if bactive.y + (y - 1) < 21 and bactive.y + (y - 1) > 0 then
							if field[bactive.y + (y - 1)][x].filled then
								fillblocks = fillblocks + 1
							end
						end
					end
					if fillblocks == 10 then
						table.insert(removelines, bactive.y + (y - 1))
						removestage = 1
						removetimer = 0
						removex1, removex2 = 0, 0
					end
				end
				score = score + math.ceil(bactive.y / 5)
				bactive = nil
			end
			buttpress = false
			for x = 5, 6 do
				if field[1][x].filled then
					state = 'gameover'
					buttons = { restart = { label = 'play\nagain', x = 4, y = 12 } }
				end
			end
		end
	else
		if buttpress == 'restart' then
			love.load()
		end
	end
	if not bactive then
		dropwait = 0
		newblock()
	end
end

function love.mousepressed(x, y)
	local pressx = (x - offsetx) / blocksize
	local pressy = (y - offsety) / blocksize
	for i, v in pairs(buttons) do
		if (pressx > v.x) and (pressx < (v.x + 2)) and (pressy > v.y) and (pressy < (v.y + 2)) then
			buttpress = i
			buttpressvisible = i
		end
	end
end

function love.mousereleased()
	buttpressvisible = false
end

function love.touchpressed(id, x, y, dx, dy, pressure)
	love.mousepressed(x, y)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
	buttpressvisible = false
end

function love.keypressed(key)
	if key == 'left' or key == 'right' or key == 'down' then
		buttpress = key
		buttpressvisible = key
	elseif key == ',' or key == 'up' then
		buttpress = 'rotl'
		buttpressvisible = 'rotl'
	elseif key == '.' then
		buttpress = 'rotr'
		buttpressvisible = 'rotr'
	end
end

function love.keyreleased()
	buttpressvisible = false
end

function love.draw()
	lg.setColor(.4, .4, .8)
	lg.rectangle('fill', 0, 0, winw, winh)
	lg.setColor(0, 0, 0)
	lg.rectangle('fill', offsetx, offsety, blocksize * 10, blocksize * 20)
	lg.setColor(1, 1, 1)
	lg.rectangle('line', offsetx - .5, offsety - .5, (blocksize * 10) + 1, (blocksize * 20) + 1)
	for y, cols in pairs(field) do
		for x, square in pairs(cols) do
		lg.setColor(1, 1, 1)
			if square.filled then
				lg.setColor(bcol[square.filled])
				drawsquare(x, y)
			else
				lg.setColor(1, 1, 1, 0.1)
				lg.rectangle('line', ((x - 1) * blocksize) + offsetx + .5, ((y - 1) * blocksize) + offsety + .5, blocksize - 1, blocksize - 1)
			end
		end
	end
	for i, v in pairs(buttons) do
		if buttpressvisible == i then
			lg.setColor(.4, .4, .8)
		else
			lg.setColor(0, 0, 0)
		end
		lg.rectangle('fill', (v.x * blocksize) + offsetx, (v.y * blocksize) + offsety, blocksize * 2, blocksize * 2)
		lg.setColor(1, 1, 1)
		lg.rectangle('line', (v.x * blocksize) + offsetx - .5, (v.y * blocksize) + offsety - .5, (blocksize * 2) + 1, (blocksize * 2) + 1)
		lg.print(v.label, (v.x * blocksize) + offsetx + (edge * 2), (v.y * blocksize) + offsety + (edge * 2))
	end
	if bactive then
		drawblock()
	end
	lg.setColor(0, 0, 0)
	lg.rectangle('fill', (-6.5 * blocksize) + offsetx, (.5 * blocksize) + offsety, 5 * blocksize, 5 * blocksize)
	lg.setColor(1, 1, 1)
	lg.rectangle('line', (-6.5 * blocksize) + offsetx - .5, (.5 * blocksize) + offsety - .5, (5 * blocksize) + 1, (5 * blocksize) + 1)
	lg.print('Score:\n' .. score .. '\n\nLevel:\n' .. level, (-6 * blocksize) + offsetx, (6 * blocksize) + offsety)
	for x = 1, 4 do
		for y = 1, 4 do
			if blocks[bnext][y][x] == 1 then
				lg.setColor(bcol[bnext])
				drawsquare(x - 6, y + 1)
			end
		end
	end
	if state == 'gameover' then
		lg.setColor(0, 0, 0)
		lg.rectangle('fill', (-1 * blocksize) + offsetx, (9 * blocksize) + offsety, 12 * blocksize, 2 * blocksize)
		lg.setColor(1, 1, 1)
		lg.rectangle('line', (-1 * blocksize) + offsetx - .5, (9 * blocksize) + offsety -.5, (12 * blocksize) + 1, (2 * blocksize) + 1)
		lg.printf('GAME OVER', (-1 * blocksize) + offsetx, (9.75 * blocksize) + offsety, 12 * blocksize, 'center')
	end
end