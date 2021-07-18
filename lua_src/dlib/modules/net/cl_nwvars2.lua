
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

local NWVarsInt = Net.NWVarsInt
local NWVarsFloat = Net.NWVarsFloat
local NWVarsBool = Net.NWVarsBool
local NWVarsEntity = Net.NWVarsEntity
local NWVarsString = Net.NWVarsString
local NWVarsAngle = Net.NWVarsAngle
local NWVarsVector = Net.NWVarsVector

local NWVarNameRegistry = Net.NWVarNameRegistry
local NWTrackedEnts = Net.NWTrackedEnts

local invert_mask = bit.bnot(0x7000)
local band = bit.band

local function read_entity()
	local id = Net.ReadUInt16()
	NWTrackedEnts[id] = true
	return id
end

local function read_list(_list, read)
	local read_entity_id = Net.ReadUInt16()

	while read_entity_id ~= 0xFFFF do
		local storage = _list[read_entity_id]

		if not storage then
			storage = {}
			_list[read_entity_id] = storage
		end

		local read_network_id = Net.ReadUInt16()

		while read_network_id ~= 0 do
			if band(read_network_id, 0x7000) ~= 0 then
				storage[assert(NWVarNameRegistry[band(read_network_id, invert_mask)], 'Net.NWVarNameRegistry[read_network_id]')] = nil
			else
				storage[assert(NWVarNameRegistry[read_network_id], 'Net.NWVarNameRegistry[read_network_id]')] = read()
			end

			read_network_id = Net.ReadUInt16()
		end

		read_entity_id = Net.ReadUInt16()
	end
end

Net.Receive('dlib_nw2_set', function()
	read_list(NWVarsInt, Net.ReadInt32)
	read_list(NWVarsFloat, Net.ReadDouble)
	read_list(NWVarsBool, Net.ReadBool)
	read_list(NWVarsEntity, read_entity)
	read_list(NWVarsString, Net.ReadString)
	read_list(NWVarsAngle, Net.ReadAngleDouble)
	read_list(NWVarsVector, Net.ReadVectorDouble)
end)

Net.Receive('dlib_nw2_delete', function()
	local index = Net.ReadUInt16()

	NWVarsInt[index] = nil
	NWVarsFloat[index] = nil
	NWVarsBool[index] = nil
	NWVarsEntity[index] = nil
	NWVarsString[index] = nil
	NWVarsAngle[index] = nil
	NWVarsVector[index] = nil

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
