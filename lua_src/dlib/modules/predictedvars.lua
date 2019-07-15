
-- Copyright (C) 2017-2019 DBotThePony

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

-- Those are based on source engine entities

-- Willox (C)
-- it's less of a limitation and more of proper usage
-- a real source mod is going to add dtvars to the player class, they are a compile-time thing so addons can't really do that
-- although tf2 does have certain controller entities that parent to players and have dtvars, so i guess it's not too different to that
-- i didn't think the jetpack would be so many lines of code... not a great example

DLib.pred = DLib.pred or {}
local pred = DLib.pred
local plyMeta = FindMetaTable('Player')

pred.Vars = pred.Vars or {}
pred._known = pred._known or {}
pred._Vars = pred._Vars or {}
pred.MaxEnt = pred.MaxEnt or 0

pred.SlotCounters = pred.SlotCounters or {
	String = 0,
	Bool = 0,
	Float = 0,
	Int = 0,
	Vector = 0,
	Angle = 0,
	Entity = 0,
}

function pred.Define(identify, mtype, default)
	if pred.Vars[identify] then
		assert(pred.Vars[identify].type == mtype, 'Can not change type of variable at runtime')
		pred.Vars[identify].default = default

		return
	end

	if not pred.SlotCounters[mtype] then
		error('Invalid variable type provided: ' .. mtype)
	end

	local slot = pred.SlotCounters[mtype]
	pred.SlotCounters[mtype] = slot + 1

	pred.Vars[identify] = {
		identify = identify,
		type = mtype,
		slot = slot,
		default = default
	}

	local _, entId, realSlot = pred.GetEntityAndSlot(identify)
	pred.Vars[identify].realSlot = realSlot
	pred._Vars[entId] = pred._Vars[entId] or {}
	pred._Vars[entId][identify] = pred.Vars[identify]
	pred.RebuildEntityDefinition(entId)
	pred.MaxEnt = pred.MaxEnt:max(entId)

	pred.Vars[identify].entId = entId

	plyMeta['Get' .. identify] = function(self)
		local ent = self.__dlib_pred_ent and self.__dlib_pred_ent[entId + 1]
		if not IsValid(ent) then return default end
		return ent['Get' .. identify](ent)
	end

	plyMeta['Set' .. identify] = function(self, newValue)
		local ent = self.__dlib_pred_ent and self.__dlib_pred_ent[entId + 1]
		if not IsValid(ent) then return end
		return ent['Set' .. identify](ent, newValue)
	end

	plyMeta['Reset' .. identify] = function(self)
		return self['Set' .. identify](self, default)
	end
end

function pred.RebuildEntityDefinition(entId)
	local ENT = {}
	ENT.Type = 'anim'
	ENT.Spawnable = false
	ENT.AdminSpawnable = false
	ENT.Author = 'DBotThePony'
	ENT.PrintName = 'DLib Predicted player variables bundle'

	function ENT:Initialize()
		self:SetSolid(SOLID_NONE)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetNoDraw(true)
		self.initial_setup = false
	end

	function ENT:Draw()

	end

	function ENT:SetupDataTables()
		if not pred._Vars[entId] then return end

		for k, v in pairs(pred._Vars[entId]) do
			self:NetworkVar(v.type, v.realSlot, k)
			self['Set' .. k](self, v.default)
		end
	end

	function ENT:DumpVariables()
		local output = {}
		if not pred._Vars[entId] then return output end

		for k, v in pairs(pred._Vars[entId]) do
			if self['Get' .. k] then
				output[k] = self['Get' .. k](self)
			end
		end

		return output
	end

	function ENT:LoadVariables(input)
		for k, v in pairs(input) do
			if self['Set' .. k] then
				self['Set' .. k](self, v)
			end
		end
	end

	function ENT:Think()
		if not IsValid(self:GetParent()) then
			if CLIENT then return end

			if not IsValid(self.__dlib_parent) then
				SafeRemoveEntity(self)
				return
			else
				self:SetParent(self.__dlib_parent)
				self:SetPos(self.__dlib_parent:GetPos())
			end
		end

		if not self.initial_setup then
			self.initial_setup = true
			self:SetTransmitWithParent(true)

			if CLIENT then
				self:SetPredictable(true)
			end
		end

		local ply = self:GetParent():GetTable()

		if not ply.__dlib_pred_ent then
			ply.__dlib_pred_ent = {}
		end

		if SERVER and IsValid(ply.__dlib_pred_ent[entId + 1]) and ply.__dlib_pred_ent[entId + 1] ~= self then
			SafeRemoveEntity(ply.__dlib_pred_ent[entId + 1])
		end

		ply.__dlib_pred_ent[entId + 1] = self
	end

	scripted_ents.Register(ENT, 'dlib_predictednw' .. entId)

	if CLIENT then return end

	for i, ent in ipairs(ents.FindByClass('dlib_predictednw' .. entId)) do
		local dump = ent:DumpVariables()
		local ply = ent:GetParent()
		SafeRemoveEntity(ent)

		ent = ents.Create('dlib_predictednw' .. entId)
		ent:SetParent(ply)
		ent:SetPos(ply:GetPos())
		ent:LoadVariables(dump)
		ent:Spawn()
		ent.__dlib_parent = ply
		ent:Activate()
		ent:Think()
	end

	for i, ply in ipairs(player.GetAll()) do
		if not ply.__dlib_pred_ent then
			for entId = 0, pred.MaxEnt do
				local ent = ents.Create('dlib_predictednw' .. entId)
				ent:SetParent(ply)
				ent:SetPos(ply:GetPos())
				ent:Spawn()
				ent.__dlib_parent = ply
				ent:Activate()
				ent:Think()
			end
		else
			for entId = 0, pred.MaxEnt do
				if not ply.__dlib_pred_ent[entId + 1] then
					local ent = ents.Create('dlib_predictednw' .. entId)
					ent:SetParent(ply)
					ent:SetPos(ply:GetPos())
					ent:Spawn()
					ent.__dlib_parent = ply
					ent:Activate()
					ent:Think()
				end
			end
		end
	end
end

for entId = 0, pred.MaxEnt do
	pred.RebuildEntityDefinition(entId)
end

function pred.GetEntityAndSlot(identify)
	local data = assert(pred.Vars[identify], 'Unknown variable name provided')

	if data.type == 'String' then
		return data.slot, (data.slot - data.slot % 4) / 4, data.slot % 4
	end

	return data.slot, (data.slot - data.slot % 32) / 32, data.slot % 32
end

if CLIENT then return end

hook.Add('PlayerAuthed', 'DLib.pred', function(ply)
	for entId = 0, pred.MaxEnt do
		local ent = ents.Create('dlib_predictednw' .. entId)
		ent:SetParent(ply)
		ent:SetPos(ply:GetPos())
		ent:Spawn()
		ent.__dlib_parent = ply
		ent:Activate()
		ent:Think()
	end
end, -3)
