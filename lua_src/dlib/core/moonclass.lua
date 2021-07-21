
-- Copyright (C) 2017-2020 DBotThePony

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

local DLib = DLib
local setmetatable = setmetatable
local istable = istable
local table_Merge = table.Merge
local pairs = pairs
local isstring = isstring
local isfunction = isfunction
local table_Copy = table.Copy
local rawget = rawget

local function empty()

end

--[[
	@doc
	@fname DLib.CreateMoonClassBare
	@args string objectName, table object_definition = {}, table class_definition = {}, table base = nil, table original = nil, boolean originalInheritMode = false

	@desc
	Creates moonscript compatible class, inheriting from (moonscript compatbile) base,
	as well as specifying already defined same class (for Lua autorefresh) `original`
	merged using `originalInheritMode` strategy (false - table.Merge, true - smart copy)
	This does not call `__inherited` on parent class, there is `DLib.CreateMoonClass` with that
	@enddesc

	@returns
	table: meta with constructor metamethod
	table: object definition
	table: parent
	table: parent object definition
]]
function DLib.CreateMoonClassBare(classname, object_definition, class_definition, base, original, originalInheritMode)
	object_definition = object_definition or {}
	class_definition = class_definition or {}
	local classdef

	if istable(original) then
		if originalInheritMode ~= true then
			classdef = original
			table_Merge(original.__base, object_definition)
			object_definition = original.__base
		else
			classdef = {}

			if original.__base then
				for k, v in pairs(original.__base) do
					if object_definition[k] == nil then
						object_definition[k] = v
					end
				end
			end

			for k, v in pairs(original) do
				if not isstring(k) or k ~= '__name' and k ~= '__parent' and k ~= '__base' and k ~= '__class' then
					if istable(v) then
						classdef[k] = table_Copy(v)
					else
						classdef[k] = v
					end
				end
			end

			table_Merge(classdef, class_definition)
		end
	else
		classdef = table_Copy(class_definition)
	end

	classdef.__name = classname
	classdef.__parent = base
	classdef.__base = object_definition

	if base and base.__base then
		setmetatable(classdef.__base, base.__base)
	end

	object_definition.__index = object_definition
	object_definition.__class = classdef

	local init = isfunction(object_definition.new) and object_definition.new or
		isfunction(object_definition.ctor) and object_definition.ctor or
		isfunction(object_definition.constructor) and object_definition.constructor or
		isfunction(object_definition[classname]) and object_definition[classname]

	if init then
		classdef.__init = init
	else
		classdef.__init = empty
	end

	local lookuptable = base or object_definition

	setmetatable(classdef, {
		__index = function(self, key)
			local value = rawget(object_definition, key)
			if value ~= nil then return value end
			return lookuptable[key]
		end,

		__call = function(self, ...)
			local obj = setmetatable({}, object_definition)

			classdef.__init(obj, ...)

			return obj
		end
	})

	return classdef, classdef.__base, base, base and base.__base or nil
end

--[[
	@doc
	@fname DLib.CreateMoonClass
	@args string objectName, table object_definition = {}, table class_definition = {}, table base = nil, table original = nil, boolean originalInheritMode = false

	@desc
	Same as `DLib.CreateMoonClassBare`, except it call `__inherited` metamethod on parent
	@enddesc

	@returns
	table: meta with constructor metamethod
	table: object definition
	table: parent
	table: parent object definition
]]
function DLib.CreateMoonClass(...)
	local classdef, classbase, base, baseDef = DLib.CreateMoonClassBare(...)

	if istable(base) and base.__inherited then
		base:__inherited(classdef)
	end

	return classdef, classbase, base, baseDef
end

local baseclass = {}

function baseclass:ctor()
	self.classes = {}
end

function baseclass:Empty(name)
	if not self.classes[name] then
		self.classes[name] = {}
	end

	table.Empty(self.classes[name])

	return self.classes[name]
end

function baseclass:Has(name)
	return self.classes[name] ~= nil
end

function baseclass:Get(name)
	if not self.classes[name] then
		self.classes[name] = {}
	end

	return self.classes[name]
end

function baseclass:Set(name, tab)
	if not self.classes[name] then
		self.classes[name] = tab
	else
		table_Merge(self.classes[name], tab)
		setmetatable(self.classes[name], getmetatable(tab))
	end
end

DLib.baseclass = DLib.CreateMoonClassBare('baseclass', baseclass, nil, nil, DLib.baseclass)

if not DLib.baseclass.INSTANCE then
	DLib.baseclass.INSTANCE = DLib.baseclass()
end

local error = error

function DLib.ConsturctClass(classIn, ...)
	if classIn == 'HUDCommonsBase' then
		ErrorNoHalt(debug.traceback('DLib.ConsturctClass is deprecated, use DLib.CreateMoonClass/DLib.CreateMoonClassBare instead') .. '\n')
		return DLib.HUDCommons.BaseMeta(...)
	end

	error('DLib.ConsturctClass is deprecated, use DLib.CreateMoonClass/DLib.CreateMoonClassBare instead')
end
