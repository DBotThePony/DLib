
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
local SERVER = SERVER
local Net = DLib.Net
local isnumber = isnumber
local Entity = Entity
local assert = assert
local isentity = isentity
local entMeta = FindMetaTable('Entity')

local EntIndex = entMeta.EntIndex
local GetTable = entMeta.GetTable

local game_GetWorld = game.GetWorld

Net.NWTrackedEnts = Net.NWTrackedEnts or {}
Net.NWVarNameRegistry = Net.NWVarNameRegistry or {}
Net.__MAGIC_UNSET = Net.__MAGIC_UNSET or {}
local __MAGIC_UNSET = Net.__MAGIC_UNSET

local NWTrackedEnts = Net.NWTrackedEnts

local IsValid = entMeta.IsValid

local array_meta = {}

local function _NotifySet(self, key)
	if not SERVER then return end

	self.dirty[key] = true

	if not self.bdirty then
		self.bdirty = true
		Net.NWVarsArrayDirty[#Net.NWVarsArrayDirty + 1] = self
		Net._var_dirty = true
	end
end

function array_meta:Add(value)
	self:Put(#self.store + 1, value)
end

function array_meta:Put(index, value)
	if self.store[index] ~= value then
		self.store[index] = value
		_NotifySet(self, index)
	end
end

function array_meta:pairs()
	return pairs(self.store)
end

function array_meta:ipairs()
	return ipairs(self.store)
end

function array_meta:Keys()
	return table.GetKeys(self.store)
end

function array_meta:Copy()
	local build = {}

	if copy then
		for k, v in pairs(self.store) do
			build[k] = copy(v)
		end
	else
		for k, v in pairs(self.store) do
			build[k] = v
		end
	end

	return build
end

function array_meta:Get(index, if_none)
	local value = self.store[index]

	if value ~= nil then
		if copy then return copy(value) end
		return value
	end

	if if_none == nil then return defaultIfNone end
	return if_none
end

function array_meta:Remove(index)
	local value = self.store[index]

	if value ~= nil then
		self.store[index] = nil
		_NotifySet(self, index)
		return value
	end
end

function array_meta:RemoveMember(value)
	local index = self:IndexOf(value)

	if index ~= nil then
		self:Remove(index)
		return true
	end

	return false
end

array_meta.RemoveValue = array_meta.RemoveMember

function array_meta:Has(value)
	for k, v in pairs(self.store) do
		if v == value then return true end
	end

	return false
end

function array_meta:IndexOf(value)
	for k, v in pairs(self.store) do
		if v == value then return k end
	end
end

function array_meta:NonEmpty()
	return next(self.store) ~= nil
end

do
	Net.NWVarsArray = Net.NWVarsArray or {}
	Net.NWVarsArrayDirty = Net.NWVarsArrayDirty or {}

	local registry_array = Net.NWVarsArray
	local self_index_array = '_dnw2_a'

	local function create_array_for(index, key, ent)
		return setmetatable({
			ent = ent,
			ient = index,
			key = key,
			store = {},
			dirty = {},
			bdirty = false,
			copy = copy
		}, {
			__index = array_meta
		})
	end

	local function create_array(self, key)
		local index = EntIndex(self)
		local value

		if index > 0 then
			value = registry_array[index]

			if not value then
				registry_array[index] = {}
				value = registry_array[index]
			end
		else
			value = GetTable(self)[self_index_array]

			if not value then
				value = {}
				self[self_index_array] = value
			end
		end

		local make = create_array_for(index, key, self)
		value[key] = make
		return make
	end

	Net._create_array = create_array
	Net._create_array_for = create_array_for

	function entMeta:DLibGetNWTable(name, create_if_empty)
		assert(IsValid(self) or self == game_GetWorld(), 'IsValid(self)', 2)

		if create_if_empty == nil then create_if_empty = true end
		local index = EntIndex(self)

		if index > 0 then
			local value = registry_array[index]

			if not value then
				if not create_if_empty then return end
				return create_array(self, name, copy)
			end

			value = value[name]

			if value == nil then
				if not create_if_empty then return end
				return create_array(self, name, copy)
			end

			return value
		else
			local value = GetTable(self)[self_index_array]

			if not value then
				if not create_if_empty then return end
				return create_array(self, name, copy)
			end

			value = value[name]

			if value == nil then
				if not create_if_empty then return end
				return create_array(self, name, copy)
			end

			return value
		end
	end

	entMeta.DLibGetNWArray = entMeta.DLibGetNWTable
end

local function define(name, defaultIfNone, copy, _assert, _assert_type)
	Net['NWVars' .. name] = Net['NWVars' .. name] or {}
	Net['NWVars' .. name .. 'Callbacks'] = Net['NWVars' .. name .. 'Callbacks'] or {}

	if SERVER then
		Net['NWVars' .. name .. 'Dirty'] = Net['NWVars' .. name .. 'Dirty'] or {}
	end

	local registry = Net['NWVars' .. name]
	local callbacks = Net['NWVars' .. name .. 'Callbacks']
	local dirty = Net['NWVars' .. name .. 'Dirty']
	local self_index = '_dnw2_' .. name
	local self_index_callbacks = '_dnw2_' .. name .. '_cb'

	-- Getters
	if copy then
		-- Getter with output copy
		entMeta['DLibGetNW' .. name] = function(self, name, ifNone)
			assert(IsValid(self) or self == game_GetWorld(), 'IsValid(self)', 2)

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
		-- Getter without output copy
		entMeta['DLibGetNW' .. name] = function(self, name, ifNone)
			assert(IsValid(self) or self == game_GetWorld(), 'IsValid(self)', 2)

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

	local function call_callback(self, index, name, old_value, new_value)
		if index > 0 then
			local callback = callbacks[index]

			if callback then
				callback = callback[name]

				if callback then
					callback(self, name, old_value, new_value)
				end
			end
		else
			local callback = GetTable(self)[self_index_callbacks]

			if callback then
				callback = callback[name]

				if callback then
					callback(self, name, old_value, new_value)
				end
			end
		end
	end

	-- Var proxy getter
	entMeta['DLibGetNWVarProxy' .. name] = function(self, name)
		if not self:IsValid() then error('Tried to use a NULL Entity!', 2) end

		assert(IsValid(self), 'IsValid(self)', 2)
		assert(isstring(name), 'isstring(name)', 2)

		local index = EntIndex(self)

		if index > 0 then
			local callback = callbacks[index]

			if callback then
				return callback[name]
			end
		else
			local get_table = GetTable(self)
			local callback = get_table[self_index_callbacks]

			if callback then
				return callback[name]
			end
		end
	end

	-- Var proxy setter
	entMeta['DLibSetNWVarProxy' .. name] = function(self, name, setfunc)
		assert(IsValid(self), 'IsValid(self)', 2)
		assert(isstring(name), 'isstring(name)', 2)
		assert(setfunc == nil or isfunction(setfunc), 'setfunc == nil or isfunction(setfunc)', 2)

		local index = EntIndex(self)

		if index > 0 then
			local callback = callbacks[index]

			if not callback then
				callback = {}
				callbacks[index] = callback
			end

			callback[name] = setfunc
		else
			local get_table = GetTable(self)
			local callback = get_table[self_index_callbacks]

			if not callback then
				callback = {}
				get_table[self_index_callbacks] = callback
			end

			callback[name] = setfunc
		end
	end

	-- Var setter for entity
	if name == 'Entity' then
		if CLIENT then
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				assert(IsValid(self) or self == game_GetWorld(), 'IsValid(self)', 2)

				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')', 2)
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

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)
				end
			end
		else
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				assert(IsValid(self) or self == game_GetWorld(), 'IsValid(self)', 2)

				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')', 2)
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

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)

					NWTrackedEnts[setvalue] = true

					if oldvalue ~= setvalue then
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
					end
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)
				end
			end
		end
	else
		-- Var setter (regular)
		if CLIENT then
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				assert(IsValid(self) or self == game_GetWorld(), 'IsValid(self)', 2)

				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')', 2)
				end

				local index = EntIndex(self)

				if index > 0 then
					local value = registry[index]

					if not value then
						value = {}
						registry[index] = value
					end

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)
				end
			end
		else
			entMeta['DLibSetNW' .. name] = function(self, name, setvalue)
				assert(IsValid(self) or self == game_GetWorld(), 'IsValid(self)', 2)

				if not _assert(setvalue) then
					error('Bad argument #2 to DLibSetNW' .. name .. ' (' .. _assert_type .. ' expected, got ' .. type(setvalue) .. ')', 2)
				end

				local index = EntIndex(self)

				if index > 0 then
					local value = registry[index]

					if not value then
						value = {}
						registry[index] = value
					end

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)

					if oldvalue ~= setvalue then
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
					end
				else
					local value = GetTable(self)[self_index]

					if not value then
						value = {}
						self[self_index] = value
					end

					local oldvalue = value[name]
					value[name] = setvalue

					call_callback(self, index, name, oldvalue, setvalue)
				end
			end
		end
	end
end

local function read_entity_for_var(value)
	return isnumber(value) and Entity(value) or value
end

define('UInt', 0, function(value) return assert(value and value >= 0 and value, 'value is lesser than zero') end, isnumber, 'number')
define('Int', 0, nil, isnumber, 'number')
define('Float', 0, nil, isnumber, 'number')
define('Bool', false, nil, isbool, 'boolean')
define('String', '', nil, isstring, 'string')
define('Entity', NULL, read_entity_for_var, isentity, 'Entity')
define('Angle', Angle(), Angle, isangle, 'Angle')
define('Vector', Vector(), Vector, isvector, 'Vector')

local function assemble_var_table(self, var_table, read_table, read_function)
	if not read_table then return end

	if read_function then
		for key, value in next, read_table do
			var_table[key] = read_function(value)
		end
	else
		for key, value in next, read_table do
			var_table[key] = value
		end
	end
end

function entMeta:DLibGetNWVarTable()
	local assemble = {
		uint = {},
		int = {},
		float = {},
		bool = {},
		string = {},
		entity = {},
		angle = {},
		vector = {},
	}

	local index = self:EntIndex()

	assemble_var_table(self, assemble.uint, Net.NWVarsUInt[index])
	assemble_var_table(self, assemble.int, Net.NWVarsInt[index])
	assemble_var_table(self, assemble.float, Net.NWVarsFloat[index])
	assemble_var_table(self, assemble.bool, Net.NWVarsBool[index])
	assemble_var_table(self, assemble.string, Net.NWVarsString[index])
	assemble_var_table(self, assemble.entity, Net.NWVarsEntity[index], read_entity_for_var)
	assemble_var_table(self, assemble.angle, Net.NWVarsAngle[index], Angle)
	assemble_var_table(self, assemble.vector, Net.NWVarsVector[index], Vector)

	return assemble
end
