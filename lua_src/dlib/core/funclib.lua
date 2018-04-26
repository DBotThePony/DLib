
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

local DLib = DLib
DLib.fnlib = {}

local rawequal = rawequal
local error = error
local assert2 = assert
local fnlib = DLib.fnlib
local meta = debug.getmetatable(function() end) or {}

meta.MetaName = 'function'

local function assert(cond, reason)
	if cond then
		error(reason, 3)
	end
end

function meta:__index(key)
	assert(rawequal(self, nil), string.format('attempt to index field %q of nil value', key))

	local val = meta[key]

	if val ~= nil then
		return val
	end

	return fnlib[key]
end

local function genError(reason)
	return function(self, target)
		assert(rawequal(self, nil), string.format('%s (left side of expression is nil)', reason:format(type(self))))
		assert(type(self) == 'function', string.format('%s (left side of expression is a function)', reason:format(type(self))))
		assert(rawequal(target, nil), string.format('%s (right side of expression is nil)', reason:format(type(target))))
		assert(type(target) == 'function', string.format('%s (right side of expression is a function)', reason:format(type(target))))
	end
end

local assert = assert2

meta.__unm = genError('attempt to unary minus %q value')
meta.__add = genError('attempt to add %q value')
meta.__sub = genError('attempt to substract %q value')
meta.__mul = genError('attempt to multiply %q value')
meta.__div = genError('attempt to divide %q value')
meta.__mod = genError('attempt to modulo %q value')
meta.__pow = genError('attempt to involute %q value')
meta.__concat = genError('attempt to concat %q value')
meta.__lt = genError('attempt to compare (<) %q value(s)')
meta.__le = genError('attempt to compare (<=) %q value(s)')

function meta:IsValid()
	return false
end

debug.setmetatable(function() end, meta)

local unpack = unpack
local table = table

-- Falco's FN Lib implementation
-- in a greater™ way

function fnlib:SingleWrap(...)
	local args = {...}

	return function()
		return self(unpack(args))
	end
end

function fnlib:Wrap(...)
	local args = {...}

	return function(...)
		local copy = table.qcopy(args)
		local args2 = table.append(copy, {...})
		return self(unpack(args2))
	end
end

-- ???
fnlib.fp = fnlib.Wrap
fnlib.Partial = fnlib.Wrap

function fnlib:FlipFull(...)
	local args = {...}

	return function(...)
		local copy = table.qcopy(args)
		local args2 = table.append(args2, {...})
		return self(unpack(table.flip(args2)))
	end
end

function fnlib:Flip()
	return function(a, b, ...)
		return self(b, a, ...)
	end
end

function fnlib:Id(...)
	return self, ...
end

-- func:Compose(func2, func3, func4) ->
-- func(func2(func3(func4(...))))

local select = select
local type = type

local function Compose(currentFunc, nextFunc, ...)
	if nextFunc == nil then return currentFunc end

	nextFunc = Compose(nextFunc, ...)

	return function(...)
		return currentFunc(nextFunc(...))
	end
end

function fnlib:Compose(funcList, ...)
	if type(funcList) == 'table' then
		return Compose(unpack(funcList))
	else
		return Compose(funcList, ...)
	end
end

fnlib.fc = fnlib.Compose

function fnlib:ReverseArgs(...)
	return unpack(table.flip({...}))
end

function fnlib:Apply(...)
	return self(...)
end

for k, v in pairs(fnlib) do
	fnlib[k:sub(1, 1):lower() .. k:sub(2)] = v
end
