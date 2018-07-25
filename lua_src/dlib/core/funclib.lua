
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
local fnlib = DLib.fnlib
local meta = debug.getmetatable(function() end) or {}

meta.MetaName = 'function'

function meta:__index(key)
	if rawequal(self, nil) then
		local i = 1
		local lasts, lastsAll = {}, {}

		while true do
			local name, value = debug.getlocal(2, i)
			if name == nil then break end
			i = i + 1

			if value == nil then
				table.insert(lastsAll, name)

				if name ~= '(*temporary)' then
					table.insert(lasts, name)
				end
			end
		end

		if #lasts == 0 and #lastsAll ~= 0 then
			error(string.format('attempt to index field %q of a nil value (bytecode local variable)', key), 2)
		elseif #lasts == 0 and #lastsAll == 0 then
			error(string.format('attempt to index field %q of a nil value (unable to detect)', key), 2)
		elseif #lasts == 1 then
			error(string.format('attempt to index field %q of a nil value (probably %s?)', key, lasts[1]), 2)
		elseif #lasts <= 4 then
			error(string.format('attempt to index field %q of a nil value (%i possibilities: %s)', key, #lasts, table.concat(lasts, ', ')), 2)
		else
			local things = {}

			for i = #lasts - 4, #lasts do
				table.insert(things, lasts[i])
			end

			if #lastsAll ~= #lasts then
				error(string.format('attempt to index field %q of a nil value (%i possibilities + bytecode local variables, probably %s)', key, #lasts, table.concat(things, ', ')), 2)
			else
				error(string.format('attempt to index field %q of a nil value (%i possibilities, probably %s)', key, #lasts, table.concat(things, ', ')), 2)
			end
		end
	end

	local val = meta[key]

	if val ~= nil then
		return val
	end

	return fnlib[key]
end

local function genError(reason)
	return function(self, target)
		if type(self) == type(target) then
			local format = string.format('%s (both sides are %s values)', reason:format(type(self)), type(self))
			error(format, 2)
		elseif type(self) == 'function' or type(self) == 'nil' then
			local format = string.format('%s (left side of expression is a %s, right side is a %s)', reason:format(type(self)), type(self), type(target))
			error(format, 2)
		end

		local format = string.format('%s (left side of expression is a %s, right side is a %s)', reason:format(type(nil)), type(self), type(target))
		error(format, 2)
	end
end

meta.__unm = genError('attempt to unary minus a %s value')
meta.__add = genError('attempt to add a %s value')
meta.__sub = genError('attempt to substract a %s value')
meta.__mul = genError('attempt to multiply a %s value')
meta.__div = genError('attempt to divide a %s value')
meta.__mod = genError('attempt to modulo a %s value')
meta.__pow = genError('attempt to involute a %s value')
meta.__concat = genError('attempt to concat a %s value')
meta.__lt = genError('attempt to compare (<) a %s value(s)')
meta.__le = genError('attempt to compare (<=) a %s value(s)')

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
		return Compose(self, unpack(funcList))
	else
		return Compose(self, funcList, ...)
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
