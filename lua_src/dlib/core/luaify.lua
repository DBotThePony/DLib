
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- https://github.com/PAC3-Server/notagain/blob/master/lua/notagain/optimizations/preinit/luaify.lua

local rawequal = rawequal
local getmetatable = getmetatable
local setmetatable = debug.setmetatable
local rawget = rawget

local function type(var)
	if rawequal(var, nil) == true then
		return 'nil'
	end

	if rawequal(var, true) == true then
		return 'boolean'
	end

	if rawequal(var, false) == true then
		return 'boolean'
	end

	local meta = getmetatable(var)

	if rawequal(meta, nil) == true then
		return 'table'
	end

	local metaname = rawget(meta, 'MetaName')

	if rawequal(metaname, nil) == true then
		local metaname2 = rawget(meta, '__type')

		if rawequal(metaname2, nil) == true then
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
		'Entity',
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
end)
