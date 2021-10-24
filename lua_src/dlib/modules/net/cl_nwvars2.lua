
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

Net.Receive('dlib_nw2_pool', function()
	if Net.ReadBool() then
		local read_id = Net.ReadUInt16()
		local name = Net.ReadString()
		Net.NWVarNameRegistry[name] = read_id
		Net.NWVarNameRegistry[read_id] = name
	else
		local read_id = Net.ReadUInt16()

		while read_id ~= 0 do
			local name = Net.ReadString()
			Net.NWVarNameRegistry[name] = read_id
			Net.NWVarNameRegistry[read_id] = name
			read_id = Net.ReadUInt16()
		end
	end
end)

local NWVarsUInt = Net.NWVarsUInt
local NWVarsInt = Net.NWVarsInt
local NWVarsFloat = Net.NWVarsFloat
local NWVarsBool = Net.NWVarsBool
local NWVarsEntity = Net.NWVarsEntity
local NWVarsString = Net.NWVarsString
local NWVarsAngle = Net.NWVarsAngle
local NWVarsVector = Net.NWVarsVector

local NWVarsUIntCallbacks = Net.NWVarsUIntCallbacks
local NWVarsIntCallbacks = Net.NWVarsIntCallbacks
local NWVarsFloatCallbacks = Net.NWVarsFloatCallbacks
local NWVarsBoolCallbacks = Net.NWVarsBoolCallbacks
local NWVarsEntityCallbacks = Net.NWVarsEntityCallbacks
local NWVarsStringCallbacks = Net.NWVarsStringCallbacks
local NWVarsAngleCallbacks = Net.NWVarsAngleCallbacks
local NWVarsVectorCallbacks = Net.NWVarsVectorCallbacks

local NWVarNameRegistry = Net.NWVarNameRegistry
local NWTrackedEnts = Net.NWTrackedEnts

local invert_mask = bit.bnot(0x7000)
local band = bit.band

local function read_entity()
	local id = Net.ReadUInt16()
	NWTrackedEnts[id] = true
	return id
end

local function read_list(_list, _callbacks, read)
	local read_entity_id = Net.ReadUInt16()

	while read_entity_id ~= 0xFFFF do
		local read_entity = Entity(read_entity_id)
		local callback_list = _callbacks[read_entity_id]

		if not read_entity:IsValid() then
			read_entity = nil
			callback_list = nil
		end

		local storage = _list[read_entity_id]

		if not storage then
			storage = {}
			_list[read_entity_id] = storage
		end

		local read_network_id = Net.ReadUInt16()

		while read_network_id ~= 0 do
			if band(read_network_id, 0x7000) ~= 0 then
				local lookup = assert(NWVarNameRegistry[band(read_network_id, invert_mask)], 'Net.NWVarNameRegistry[read_network_id]')
				local oldvalue = storage[lookup]
				storage[lookup] = nil

				if callback_list and callback_list[lookup] then
					callback_list[lookup](read_entity, lookup, oldvalue, nil)
				end
			else
				local lookup = assert(NWVarNameRegistry[read_network_id], 'Net.NWVarNameRegistry[read_network_id]')
				local oldvalue = storage[lookup]
				storage[lookup] = read()

				if callback_list and callback_list[lookup] then
					callback_list[lookup](read_entity, lookup, oldvalue, storage[lookup])
				end
			end

			read_network_id = Net.ReadUInt16()
		end

		read_entity_id = Net.ReadUInt16()
	end
end

local NWVarsArray = Net.NWVarsArray

Net.Receive('dlib_nw2_set', function()
	read_list(NWVarsUInt,   NWVarsUIntCallbacks,   Net.ReadUInt32)
	read_list(NWVarsInt,    NWVarsIntCallbacks,    Net.ReadInt32)
	read_list(NWVarsFloat,  NWVarsFloatCallbacks,  Net.ReadDouble)
	read_list(NWVarsBool,   NWVarsBoolCallbacks,   Net.ReadBool)
	read_list(NWVarsEntity, NWVarsEntityCallbacks, read_entity)
	read_list(NWVarsString, NWVarsStringCallbacks, Net.ReadString)
	read_list(NWVarsAngle,  NWVarsAngleCallbacks,  Net.ReadAngleDouble)
	read_list(NWVarsVector, NWVarsVectorCallbacks, Net.ReadVectorDouble)

	local read_entity_id = Net.ReadUInt16()

	while read_entity_id ~= 0xFFFF do
		local read_network_id = Net.ReadUInt16()
		local lookup = assert(NWVarNameRegistry[read_network_id], 'Net.NWVarNameRegistry[read_network_id]')
		local storage = NWVarsArray[read_entity_id]

		if not storage then
			storage = {}
			NWVarsArray[read_entity_id] = storage
		end

		local array = storage[lookup]

		if not array then
			array = Net._create_array_for(read_entity_id, lookup, Entity(read_entity_id))
			storage[lookup] = array
		end

		local store = array.store
		local read_key = Net.ReadType()

		while read_key ~= nil do
			store[read_key] = Net.ReadType()
			read_key = Net.ReadType()
		end

		read_entity_id = Net.ReadUInt16()
	end
end)

Net.Receive('dlib_nw2_delete', function()
	local index = Net.ReadUInt16()

	NWVarsUInt[index] = nil
	NWVarsInt[index] = nil
	NWVarsFloat[index] = nil
	NWVarsBool[index] = nil
	NWVarsEntity[index] = nil
	NWVarsString[index] = nil
	NWVarsAngle[index] = nil
	NWVarsVector[index] = nil

	NWVarsArray[index] = nil

	DLib.NW.NETWORK_DB[index] = nil

	if NWTrackedEnts[index] then
		for ent, data_list in next, NWVarsEntity do
			for network_name, value in next, data_list do
				if value == index then
					data_list[network_name] = NULL
				end
			end
		end

		NWTrackedEnts[index] = nil
	end
end)
