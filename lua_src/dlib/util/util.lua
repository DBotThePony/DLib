
-- Copyright (C) 2017-2018 DBot

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

jit.on()

local util = setmetatable(DLib.util or {}, {__index = util})
DLib.util = util
local DLib = DLib
local vgui = vgui
local type = type
local ipairs = ipairs
local IsValid = IsValid

function DLib.VCreate(pnlName, pnlParent)
	if not IsValid(pnlParent) then
		DLib.Message(debug.traceback('Attempt to create ' .. pnlName .. ' without valid parent!', 2))
		return
	end

	return vgui.Create(pnlName, pnlParent)
end

function util.copy(var)
	if type(var) == 'table' then return table.Copy(var) end
	if type(var) == 'Angle' then return Angle(var.p, var.y, var.r) end
	if type(var) == 'Vector' then return Vector(var) end
	return var
end

function util.randomVector(mx, my, mz)
	return Vector(math.Rand(-mx, mx), math.Rand(-my, my), math.Rand(-mz, mz))
end

function util.composeEnums(input, ...)
	local num = 0

	if type(input) == 'table' then
		for k, v in ipairs(input) do
			num = num:bor(v)
		end
	else
		num = input
	end

	return num:bor(...)
end

function util.ValidateSteamID(input)
	if not input then return false end
	return input:match('STEAM_0:[0-1]:[0-9]+$') ~= nil
end

function util.SteamLink(steamid)
	if util.ValidateSteamID(steamid) then
		return 'https://steamcommunity.com/profiles/' .. util.SteamIDTo64(steamid) .. '/'
	else
		return 'https://steamcommunity.com/profiles/' .. steamid .. '/'
	end
end

function util.CreateSharedConvar(cvarname, cvarvalue, description)
	if CLIENT then
		return CreateConVar(cvarname, cvarvalue, {FCVAR_REPLICATED}, description)
	else
		return CreateConVar(cvarname, cvarvalue, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, description)
	end
end

-- Replace PrintTable with something better

local rawtype = rawtype
local table = table
local error = error
local pcall = pcall
local debug = debug
local strict = false

local DEFAULT_TEXT_COLOR = Color(247, 255, 27)
local BOOLEAN_COLOR = Color(107, 141, 227)
local NUMBER_COLOR = Color(245, 199, 64)
local ENTITY_COLOR = Color(180, 232, 180)
local FUNCTION_COLOR = Color(117, 207, 226)
local RECURSION_COLOR = Color(195, 222, 69)
local TOO_DEEP_COLOR = Color(196, 158, 91)
local EQUALS_COLOR = Color(169, 117, 222)
local TABLE_TOKEN_COLOR = Color(197, 104, 111)
local COMMENTARY_COLOR = Color(143, 165, 46)

DLib._OldPrintTable = DLib._OldPrintTable or PrintTable

local wellknown, prints

local function getColorForType(typeIn)
	if typeIn == 'boolean' then
		return BOOLEAN_COLOR
	elseif typeIn == 'number' then
		return NUMBER_COLOR
	elseif typeIn == 'function' then
		return FUNCTION_COLOR
	elseif typeIn == 'string' then
		return DEFAULT_TEXT_COLOR
	elseif typeIn == 'Entity' or typeIn == 'Weapon' or typeIn == 'Vehicle' or typeIn == 'Player' then
		return ENTITY_COLOR
	end

	return DEFAULT_TEXT_COLOR
end

local function getValueString(typeIn, valueIn)
	if typeIn == 'string' then
		return '"' .. valueIn:gsub('"', '\\"'):gsub('\t', '\\t'):gsub('\n', '\\n') .. '"'
	elseif typeIn == 'function' then
		local info = debug.getinfo(valueIn)
		return tostring(valueIn), COMMENTARY_COLOR, ' --[[ ' .. info.short_src .. ': ' .. (info.lastlinedefined ~= info.linedefined and (info.linedefined .. '-' .. info.lastlinedefined) or info.lastlinedefined) .. ' ]]'
	end

	return tostring(valueIn)
end

local comparableTypes = {}

local function InternalPrintLoop(tableIn, level, recursionCheck)
	if prints > 100000 then
		error('I dont want to print more. Probably hit a recursion.')
	end

	if strict then
		if wellknown[tableIn] then
			MsgC(RECURSION_COLOR, ' [well known/recursion] ')
			return false
		end
	else
		if wellknown[tableIn] and wellknown[tableIn] > 6 then
			MsgC(RECURSION_COLOR, ' [well known] ')
			return false
		end

		if recursionCheck and recursionCheck[tableIn] then
			MsgC(RECURSION_COLOR, ' [recursion] ')
			return false
		end
	end

	if level > 10 then
		MsgC(TOO_DEEP_COLOR, ' [too deep] ')
		return false
	end

	local keys = {}

	for k in pairs(tableIn) do
		table.insert(keys, k)
	end

	table.sort(keys, function(a, b)
		local ta, tb = type(a), type(b)
		local cmp = false
		local token = ta .. '-' .. tb

		if comparableTypes[token] == nil then
			comparableTypes[token] = pcall(function()
				cmp = a < b
			end)
		elseif comparableTypes[token] then
			cmp = a < b
		end

		return cmp
	end)

	wellknown[tableIn] = (wellknown[tableIn] or 0) + 1

	local hitAnything = false

	for i, key in ipairs(keys) do
		prints = prints + 1

		if not hitAnything then
			MsgC('\n')
			hitAnything = true
		end

		local ktp = type(key)
		MsgC(string.rep(' ', level * 4), TABLE_TOKEN_COLOR, '[')
		MsgC(getColorForType(ktp), getValueString(ktp, key))
		MsgC(TABLE_TOKEN_COLOR, ']', EQUALS_COLOR, ' = ')
		local value = tableIn[key]

		if type(value) == 'table' then
			MsgC(TABLE_TOKEN_COLOR, '{')
			local useSpaces = InternalPrintLoop(value, level + 1, strict and '' or recursionCheck or {})

			if useSpaces then
				MsgC(TABLE_TOKEN_COLOR, string.rep(' ', level * 4), '},\n')
			else
				MsgC(TABLE_TOKEN_COLOR, '},\n')
			end
		else
			local tp = type(value)
			MsgC(getColorForType(tp), getValueString(tp, value))
			MsgC(TABLE_TOKEN_COLOR, ',\n')
		end
	end

	if not hitAnything then
		MsgC(COMMENTARY_COLOR, ' --[[ empty ]] ')
	end

	return hitAnything
end

function _G.PrintTable(tableIn)
	assert(rawtype(tableIn) == 'table', 'Input must be a table!')
	wellknown = {}
	prints = 0
	strict = false
	MsgC(TABLE_TOKEN_COLOR, '{')
	InternalPrintLoop(tableIn, 1)
	MsgC(TABLE_TOKEN_COLOR, '}\n')
end

function _G.PrintTableStrict(tableIn)
	assert(rawtype(tableIn) == 'table', 'Input must be a table!')
	wellknown = {}
	prints = 0
	strict = true
	MsgC(TABLE_TOKEN_COLOR, '{')
	InternalPrintLoop(tableIn, 1)
	MsgC(TABLE_TOKEN_COLOR, '}\n')
end
