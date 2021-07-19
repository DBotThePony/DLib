
-- Copyright (C) 2021 DBotThePony

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
local Net = DLib.Net
local isnumber = isnumber
local Entity = Entity
local assert = assert
local isentity = isentity
local entMeta = FindMetaTable('Entity')

local EntIndex = entMeta.EntIndex
local GetTable = entMeta.GetTable

Net.NWTrackedEnts = Net.NWTrackedEnts or {}
Net.NWVarNameRegistry = Net.NWVarNameRegistry or {}
Net.__MAGIC_UNSET = Net.__MAGIC_UNSET or {}
local __MAGIC_UNSET = Net.__MAGIC_UNSET

local NWTrackedEnts = Net.NWTrackedEnts

local function define(name, defaultIfNone, copy, _assert, _assert_type)
	Net['NWVars' .. name] = Net['NWVars' .. name] or {}

	if SERVER then
		Net['NWVars' .. name .. 'Dirty'] = Net['NWVars' .. name .. 'Dirty'] or {}
	end

	local registry = Net['NWVars' .. name]
	local dirty = Net['NWVars' .. name .. 'Dirty']
	local self_index = '_dnw2_' .. name

	if copy then
		entMeta['DLibGetNW' .. name] = function(self, name, ifNone)
			if ifNone == nil then ifNone = defaultIfNone end
			local index = EntIndex(self)

			if index > 0 then
				local value = registry[index]

				if not value then
					return copy(ifNone)
				end

				value = value[name]

				if value ~= nil then
					return copy(value)
				end

				return copy(ifNone)
			else
				local value = GetTable(self)[self_index]

				if not value then
					self[self_index] = {}
					return copy(ifNone)
				end

				value = value[name]

				if value ~= nil then
					return copy(value)
				end

				return copy(ifNone)
			end
		end
	else
		entMeta['DLibGetNW' .. name] = function(self, name, ifNone)
			if ifNone == nil then ifNone = defaultIfNone end
			local index = EntIndex(self)

			if index > 0 then
				local value = registry[index]

				if not value then
					return ifNone
				end

				value = value[name]

				if value ~= nil then
					return value
				end

				return ifNone
			else
				local value = GetTable(self)[self_index]

				if not value then
					self[self_index] = {}
					return ifNone
				end

				value = value[name]

				if value ~= nil then
					return value
				end

				return ifNone
			end
		end
	end

	if name == 'Entity' then
		if CLIENT then
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')')
				end

				local index = EntIndex(self)

				if isentity(setvalue) then
					setvalue = EntIndex(setvalue)
				end

				if index > 0 then
					local value = registry[index]
					NWTrackedEnts[setvalue] = true

					if not value then
						value = {}
						registry[index] = value
					end

					value[name] = setvalue
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					value[name] = setvalue
				end
			end
		else
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')')
				end

				local index = EntIndex(self)

				if isentity(setvalue) then
					setvalue = EntIndex(setvalue)
				end

				if index > 0 then
					local value = registry[index]

					if not value then
						value = {}
						registry[index] = value
					end

					if value[name] == setvalue then return end

					value[name] = setvalue
					NWTrackedEnts[setvalue] = true

					local _dirty = dirty[index]

					if setvalue == nil then
						if _dirty then
							_dirty[Net.GetVarName(name)] = __MAGIC_UNSET
						else
							dirty[index] = {[Net.GetVarName(name)] = __MAGIC_UNSET}
						end
					else
						if _dirty then
							_dirty[Net.GetVarName(name)] = setvalue
						else
							dirty[index] = {[Net.GetVarName(name)] = setvalue}
						end
					end

					Net._var_dirty = true
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					value[name] = setvalue
				end
			end
		end
	else
		if CLIENT then
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')')
				end

				local index = EntIndex(self)

				if index > 0 then
					local value = registry[index]

					if not value then
						value = {}
						registry[index] = value
					end

					value[name] = setvalue
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					value[name] = setvalue
				end
			end
		else
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')')
				end

				local index = EntIndex(self)

				if index > 0 then
					local value = registry[index]

					if not value then
						value = {}
						registry[index] = value
					end

					value[name] = setvalue

					local _dirty = dirty[index]

					if setvalue == nil then
						if _dirty then
							_dirty[Net.GetVarName(name)] = __MAGIC_UNSET
						else
							dirty[index] = {[Net.GetVarName(name)] = __MAGIC_UNSET}
						end
					else
						if _dirty then
							_dirty[Net.GetVarName(name)] = setvalue
						else
							dirty[index] = {[Net.GetVarName(name)] = setvalue}
						end
					end

					Net._var_dirty = true
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					value[name] = setvalue
				end
			end
		end
	end
end

define('UInt', 0, function(value) return assert(value and value >= 0 and value, 'value is lesser than zero') end, isnumber, 'number')
define('Int', 0, nil, isnumber, 'number')
define('Float', 0, nil, isnumber, 'number')
define('Bool', false, nil, isbool, 'boolean')
define('String', '', nil, isstring, 'string')
define('Entity', NULL, function(value) return isnumber(value) and Entity(value) or value end, isentity, 'Entity')
define('Angle', Angle(), Angle, isangle, 'Angle')
define('Vector', Vector(), Vector, isvector, 'Vector')
