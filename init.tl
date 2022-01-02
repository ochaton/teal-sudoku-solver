#!/usr/bin/env tl

-- local function count(t: table):integer
-- 	local n = 0
-- 	for _ in pairs(t) do
-- 		n = n + 1
-- 	end
-- 	return n
-- end

local function clone(t: any): any
	if type(t) ~= 'table' then
		return t
	end
	local r: {any:any} = {}
	for k, v in pairs(t as {any:any}) do
		r[k] = clone(v)
	end
	return r
end

local function contains<T>(list: {T}, item: T): boolean
	for _, x in ipairs(list) do
		if x == item then return true end
	end
	return false
end

local enum Cell
	" " "1" "2" "3" "4" "5" "6" "7" "8" "9"
end

local function isEmpty(c: Cell): boolean
	return c == " "
end

local record Board
	type cell = record
		id: integer
		set: Cell
		discard: {Cell:boolean}
	end

	cells: {cell}
end

function Board.new(): Board
	local cs = {} as {Board.cell}
	for _ = 1, 9 do
		for _ = 1, 9 do
			table.insert(cs, { id = #cs+1, set = " " })
		end
	end
	return setmetatable({ cells = cs } as Board, { __index = Board })
end

function Board:set(v: {integer,Cell})
	self.cells[v[1]].set = v[2]
end

function Board:unset(v: {integer,Cell})
	if self.cells[v[1]].set == v[2] then
		self.cells[v[1]].set = " "
	end
end

function Board:emptyCells(): ((function(any, integer): integer, Board.cell), any, any)
	return function(_, s: integer): integer, Board.cell
		for i = s, #self.cells do
			if isEmpty(self.cells[i].set) then
				return i+1, self.cells[i]
			end
		end
	end, nil, 1
end

function Board:horizontal(id: integer): {integer}
	local lineId = math.floor((id-1)/9)
	local startId = lineId*9+1

	assert(startId <= id)
	assert(startId+9 >= id)

	local r: {integer} = {}
	for i = startId, startId+8 do
		table.insert(r, i)
	end
	return r
end

function Board:vertical(id: integer): {integer}
	local colId = (id-1)%9+1
	local r: {integer} = {}
	for i = 0, 8 do
		table.insert(r, 9*i+colId)
	end
	return r
end

function Board:square(id: integer): {integer}
	local function stripeH(x: integer): integer
		return 1+math.floor(math.floor((x-1)/9)/3)
	end

	local function stripeV(x: integer): integer
		return 1+math.floor((x-1)%9/3)
	end

	local h, v = stripeH(id), stripeV(id)

	local start = (h-1)*27+(v-1)*3+1
	return {
		start, start+1, start+2,
		start+9, start+10, start+11,
		start+18, start+19, start+20,
	}
end

function Board:print()
	local n = 1
	for i = 1, 9 do
		local line: {string} = {}
		for j = 1, 9 do
			table.insert(line, self.cells[n].set)
			n = n + 1
			if j % 3 == 0 then
				table.insert(line, "|")
			end
		end
		print(table.concat(line))
		if i % 3 == 0 then
			print("------------")
		end
	end
end

function Board:printId()
	local n = 1
	for i = 1, 9 do
		local line: {string} = {}
		for j = 1, 9 do
			table.insert(line, ("%02d"):format(n))
			if j % 3 == 0 then
				table.insert(line, "|")
			end
			n=n+1
		end
		print(table.concat(line, " "))
		if i % 3 == 0 then
			print("--------------------------------")
		end
	end
end

function Board:load(nums: {{Cell}}): Board
	local n = 1
	for i = 1, 9 do
		for j = 1, 9 do
			self.cells[n].set = nums[i][j]
			n = n + 1
		end
	end
	return self
end

function Board:dump(): {{Cell}}
	local dump: {{Cell}} = {}
	local n = 1
	for i = 1, 9 do
		local r: {Cell} = {}
		for j = 1, 9 do
			r[j] = self.cells[n].set
			n = n + 1
		end
		dump[i] = r
	end
	return dump
end

function Board:clone(): Board
	return Board.new():load(self:dump())
end

function Board:discard(id: integer): {Cell:boolean}
	local discard_map: {Cell:boolean} = {}
	self.cells[id].discard = discard_map

	if not isEmpty(self.cells[id].set) then
		for i = 1, 9 do
			local v = tostring(i) as Cell
			if v ~= self.cells[id].set then
				discard_map[v] = true
			end
		end
	end

	local sets = { self:horizontal(id), self:vertical(id), self:square(id) }

	for _, s in ipairs(sets) do
		for _, nid in ipairs(s) do
			if not isEmpty(self.cells[nid].set) then
				discard_map[self.cells[nid].set] = true
			end
		end
	end

	return discard_map
end

function Board:choices(id: integer): {Cell}
	local c = self.cells[id]
	c.discard = self:discard(id)

	local r: {Cell} = {}
	for i = 1, 9 do
		local v = tostring(i) as Cell
		if not c.discard[v] then
			table.insert(r, v)
		end
	end
	return r
end

function Board:collides():boolean
	for _, c in ipairs(self.cells) do
		for _, set in ipairs{ self:horizontal(c.id), self:vertical(c.id), self:square(c.id) } do
			local map: {Cell:boolean} = {}
			for _, sid in ipairs(set) do
				local s = self.cells[sid]
				if not isEmpty(s.set) then
					if map[s.set] then
						return true
					else
						map[s.set] = true
					end
				end
			end
		end
	end
	return false
end

function Board:solved(): boolean
	return not self:collides() and self:emptyCells()(nil, 1) == nil
end

local record Game
	input: {{Cell}}
	board: Board
end

function Game:readFile(input: string): {{Cell}}
	local file = assert(io.open(input, "r"))
	local field: {{Cell}} = {}

	for line in file:lines() do
		if line:find('-') then
			goto skip
		end

		local cells: {Cell} = {}
		table.insert(field, cells)

		for chunk in line:gmatch("(.)") do
			if chunk == "|" or chunk == "-" then
			else
				if chunk == " " or #chunk == 1 and tonumber(chunk) >= 1 and tonumber(chunk) <= 9 then
					table.insert(cells, chunk as Cell)
				else
					error(("Malformed cell: %q"):format(chunk))
				end
			end
		end

		if #cells ~= 9 then
			error(("Malformed row %d: %s"):format(#field, line))
		end

		::skip::
	end

	if #field ~= 9 then
		error(("Malformed field: required 9 rows got %d"):format(#field))
	end

	return field
end

function Game.new(): Game
	return setmetatable({}, { __index = Game })
end

function Game:loadBoardFromFile(input: string): Game
	self.board = Board.new():load(self:readFile(input))
	return self
end

local record State
	blackList: {integer:{Cell}}
	guess: {integer,Cell}
	board: Board
end

function State.new(b: Board, bl: {integer:{Cell}}): State
	return setmetatable({ board = b, blackList = bl }, { __index = State })
end

function State:clone(): State
	return State.new(self.board:clone(), clone(self.blackList) as {integer:{Cell}})
end

function State:print()
	self.board:print()
	for id, cells in pairs(self.blackList) do
		print(("%d => {%s}"):format(id, table.concat(cells, ",")))
	end
end

local stack = require 'stack'

local record Solver
	state: State
	history: stack<State>
end

function Solver.new(b: Board): Solver
	return setmetatable({
		state = State.new(b, {}),
		history = stack.new() as stack<State>,
	}, {__index = Solver})
end

function Solver:guess(): {integer,Cell}
	assert(not self.state.board:collides(), "board must be ok")

	local choices: {integer:{Cell}} = {}
	local nextCells: {integer} = {}
	for _, cell in self.state.board:emptyCells() do
		local chs = self.state.board:choices(cell.id)
		table.insert(nextCells, cell.id)

		local r: {Cell} = {}
		if self.state.blackList[cell.id] then
			for _, choice in ipairs(chs) do
				if not contains(self.state.blackList[cell.id], choice) then
					table.insert(r, choice)
				end
			end
		else
			r = chs
		end

		choices[cell.id] = r
		if #r == 0 then
			return
		end
	end

	---
	table.sort(nextCells, function(a: integer, b :integer): boolean
		return #choices[a] < #choices[b]
	end)

	if #nextCells == 0 then
		return
	end

	-- print(("Guessing cell %d => {%s}"):format(
	-- 	nextCells[1],
	-- 	table.concat(choices[nextCells[1]], ",")
	-- ))

	return { nextCells[1], choices[nextCells[1]][1] }
end

function Solver:solve(): Board
	print("START")
	local n = 1
	repeat
		n = n + 1
		if n > 2000 then
			return
		end
		if n % 1000 == 0 then
			self.state:print()
			print("Stack len:", #self.history.items)
		end
		local guess = self:guess()

		if guess then
			self.history:push(self.state)
			self.state = self.state:clone()
			self.state.guess = guess
			self.state.board:set(guess)
		else
			-- print("no guess")
			local prev_guess = self.state.guess
			self.state = self.history:pop()

			local id = prev_guess[1]
			local bl = self.state.blackList[id] or {}

			table.insert(bl, prev_guess[2])
			self.state.blackList[id] = bl
		end

	until self.state.board:solved()

	self.state.board:print()
	print("END", self.state.board:collides(), n)
end

local g = Game.new():loadBoardFromFile("field.txt")
g.board:print()

Solver.new(g.board):solve()
