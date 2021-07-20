
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
local Entity = Entity
local Net = DLib.Net

Net.Pool('dlib_nw2_pool')
Net.Pool('dlib_nw2_set')
Net.Pool('dlib_nw2_delete')

Net.NWVarNameRegistryNext = Net.NWVarNameRegistryNext or 1
local NWVarNameRegistry = Net.NWVarNameRegistry

function Net.ReplicateNWVarNameList(ply)
	Net.Start('dlib_nw2_pool')
	Net.WriteBool(false)

	for name, id in next, NWVarNameRegistry do
		Net.WriteUInt16(id)
		Net.WriteString(name)
	end

	Net.WriteUInt16(0)

	Net.Send(ply)
end

function Net.GetVarName(name)
	local index = NWVarNameRegistry[name]

	if not index then
		NWVarNameRegistry[name] = Net.NWVarNameRegistryNext
		Net.NWVarNameRegistryNext = Net.NWVarNameRegistryNext + 1

		Net.Start('dlib_nw2_pool')
		Net.WriteBool(true)
		Net.WriteUInt16(NWVarNameRegistry[name])
		Net.WriteString(name)
		Net.Broadcast()

		return NWVarNameRegistry[name]
	end

	return index
end

local NWVarsIntDirty = Net.NWVarsIntDirty
local NWVarsFloatDirty = Net.NWVarsFloatDirty
local NWVarsBoolDirty = Net.NWVarsBoolDirty
local NWVarsEntityDirty = Net.NWVarsEntityDirty
local NWVarsStringDirty = Net.NWVarsStringDirty
local NWVarsAngleDirty = Net.NWVarsAngleDirty
local NWVarsVectorDirty = Net.NWVarsVectorDirty

local NWVarsInt = Net.NWVarsInt
local NWVarsFloat = Net.NWVarsFloat
local NWVarsBool = Net.NWVarsBool
local NWVarsEntity = Net.NWVarsEntity
local NWVarsString = Net.NWVarsString
local NWVarsAngle = Net.NWVarsAngle
local NWVarsVector = Net.NWVarsVector

local entMeta = FindMetaTable('Entity')

local EntIndex = entMeta.EntIndex
local IsValid = entMeta.IsValid
local next = next
local bor = bit.bor
local rawequal = rawequal
local player_GetCount = player.GetCount
local __MAGIC_UNSET = Net.__MAGIC_UNSET
local NWTrackedEnts = Net.NWTrackedEnts

local function write_list(_list, write)
	for ent, dirty_list in next, _list do
		Net.WriteUInt16(ent)

		for network_id, write_value in next, dirty_list do
			if rawequal(__MAGIC_UNSET, write_value) then
				Net.WriteUInt16(bor(network_id, 0x7000))
			else
				Net.WriteUInt16(network_id)
				write(write_value)
			end
		end

		Net.WriteUInt16(0)

		_list[ent] = nil
	end
end

local function write_list_replicate(_list, write)
	for ent, dirty_list in next, _list do
		Net.WriteUInt16(ent)

		for network_name, write_value in next, dirty_list do
			Net.WriteUInt16(Net.GetVarName(network_name))
			write(write_value)
		end

		Net.WriteUInt16(0)
	end
end

local function write_entity(index)
	if isnumber(index) then
		if index < 1 or index > 65000 or not IsValid(Entity(index)) then
			Net.WriteUInt16(0)
		else
			Net.WriteUInt16(index)
		end
	elseif isentity(index) and IsValid(index) then
		index = index:EntIndex()

		if index < 1 or index > 65000 or not IsValid(Entity(index)) then
			Net.WriteUInt16(0)
		else
			Net.WriteUInt16(index)
		end
	else
		Net.WriteUInt16(0)
	end
end

local function Think()
	if not Net._var_dirty then return end
	Net._var_dirty = false

	Net.Start('dlib_nw2_set')

	write_list(NWVarsIntDirty, Net.WriteInt32)
	Net.WriteUInt16(0xFFFF)

	write_list(NWVarsFloatDirty, Net.WriteDouble)
	Net.WriteUInt16(0xFFFF)

	write_list(NWVarsBoolDirty, Net.WriteBool)
	Net.WriteUInt16(0xFFFF)

	write_list(NWVarsEntityDirty, write_entity)
	Net.WriteUInt16(0xFFFF)

	write_list(NWVarsStringDirty, Net.WriteString)
	Net.WriteUInt16(0xFFFF)

	write_list(NWVarsAngleDirty, Net.WriteAngleDouble)
	Net.WriteUInt16(0xFFFF)

	write_list(NWVarsVectorDirty, Net.WriteVectorDouble)
	Net.WriteUInt16(0xFFFF)

	Net.Broadcast()
end

function Net.ReplicateVars(ply)
	Net.Start('dlib_nw2_set')

	write_list_replicate(NWVarsInt, Net.WriteInt32)
	Net.WriteUInt16(0xFFFF)

	write_list_replicate(NWVarsFloat, Net.WriteDouble)
	Net.WriteUInt16(0xFFFF)

	write_list_replicate(NWVarsBool, Net.WriteBool)
	Net.WriteUInt16(0xFFFF)

	write_list_replicate(NWVarsEntity, write_entity)
	Net.WriteUInt16(0xFFFF)

	write_list_replicate(NWVarsString, Net.WriteString)
	Net.WriteUInt16(0xFFFF)

	write_list_replicate(NWVarsAngle, Net.WriteAngleDouble)
	Net.WriteUInt16(0xFFFF)

	write_list_replicate(NWVarsVector, Net.WriteVectorDouble)
	Net.WriteUInt16(0xFFFF)

	Net.Send(ply)
end

local function EntityRemoved(self)
	if player_GetCount() == 0 then return end
	local index = EntIndex(self)

	if index < 1 then return end

	NWVarsIntDirty[index] = nil
	NWVarsFloatDirty[index] = nil
	NWVarsBoolDirty[index] = nil
	NWVarsEntityDirty[index] = nil
	NWVarsStringDirty[index] = nil
	NWVarsAngleDirty[index] = nil
	NWVarsVectorDirty[index] = nil

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

	Net.Start('dlib_nw2_delete')
	Net.WriteUInt16(index)
	Net.Broadcast()
end

local function PlayerAuthed(ply)
	Net.ReplicateNWVarNameList(ply)
	Net.ReplicateVars(ply)
end

hook.Add('Think', 'DLib.Net.ThinkNWVars', Think, -2)
hook.Add('EntityRemoved', 'DLib.Net Remove Tracked Entity', EntityRemoved, -10)
hook.Add('PlayerAuthed', 'DLib.Net Send NWVar Name Databank', PlayerAuthed)

for i, ply in ipairs(player.GetHumans()) do
	PlayerAuthed(ply)
end
