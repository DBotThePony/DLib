
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


-- https://github.com/PAC3-Server/notagain/blob/master/lua/notagain/optimizations/preinit/luaify.lua

local rawequal = rawequal
local getmetatable = getmetatable
local setmetatable = debug.setmetatable
local rawget = rawget
_G.rawtype = _G.rawtype or type

local rawtype = rawtype

local function type(var)
	if rawequal(var, nil) then
		return 'nil'
	end

	if rawequal(var, true) or rawequal(var, false) then
		return 'boolean'
	end

	local meta = getmetatable(var)

	if rawequal(meta, true) or rawequal(meta, false) then
		return 'table'
	end

	if rawequal(meta, nil) then
		return 'table'
	end

	local metaname = meta.MetaName

	if metaname == nil then
		local metaname2 = meta.__type

		if metaname2 == nil then
			return 'table'
		end

		return metaname2
	end

	return metaname
end

local ctime = coroutine.create(getmetatable)

if ctime ~= false then
	local cmeta = getmetatable(ctime) or {}
	cmeta.MetaName = 'thread'
	setmetatable(ctime, cmeta)
end

local bmeta = getmetatable(true) or {}
bmeta.MetaName = 'boolean'
setmetatable(true, cmeta)

local fmeta = debug.getmetatable(function() end) or {}
fmeta.MetaName = 'function'
setmetatable(function() end, fmeta)

local strmeta = getmetatable('') or {}
strmeta.MetaName = 'string'

function strmeta:IsValid()
	return false
end

function string:IsValid()
	return false
end

setmetatable('', strmeta)

ProtectedCall(function()
	assert(type(1) == 'number', type(1))
	assert(type('') == 'string', type(''))
	assert(type(NULL) == 'Entity', type(NULL))
	assert(type({}) == 'table', type({}))
	-- assert(type(coroutine.create(getmetatable)) == 'thread', type(coroutine.create(getmetatable)))

	_G.type = type

	local overridetypes = {
		'string',
		'number',
		'Angle',
		'Vector',
		'Panel',
		'Matrix',
		'function',
		'table',
	}

	function _G.isbool(var)
		return type(var) == 'boolean'
	end

	function _G.isboolean(var)
		return type(var) == 'boolean'
	end

	for i, rawname in ipairs(overridetypes) do
		local function ischeck(var)
			return type(var) == rawname
		end

		_G['Is' .. rawname:sub(1, 1) .. rawname:sub(2)] = ischeck
		_G['is' .. rawname:lower()] = ischeck
		_G['is' .. rawname:sub(1, 1) .. rawname:sub(2)] = ischeck
	end

	function _G.IsEntity(var)
		local tp = type(var)

		return tp == 'Entity' or
			tp == 'NextBot' or
			tp == 'NPC' or
			tp == 'Vehicle' or
			tp == 'Player' or
			tp == 'Weapon'
	end

	_G.isEntity = IsEntity
	_G.isentity = IsEntity
end)
