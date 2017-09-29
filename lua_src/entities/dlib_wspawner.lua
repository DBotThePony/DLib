
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

AddCSLuaFile()

local grabBaseclass = baseclass.Get('base_entity')

ENT.Type = 'anim'
ENT.Author = 'DBot'
ENT.Base = 'dlib_espawner'
ENT.PrintName = 'Weapon Spawner Base'
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Model = 'models/items/item_item_crate.mdl'
ENT.SPAWN_HOOK_CALL = 'PlayerSpawnSWEP'
ENT.SPAWNED_HOOK_CALL = 'PlayerSpawnedSWEP'
ENT.IS_SPAWNER = true

function ENT:SpawnFunction(ply, tr, class)
	if not tr.Hit then return end

	local can = hook.Run(self.SPAWN_HOOK_CALL, ply, self.CLASS, self.TABLE)
	if can == false then return end

	local ent = ents.Create(class)
	ent:SetPos(tr.HitPos + tr.HitNormal * 3)
	ent:SetModel(self.DefaultModel)
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:DoSpawn(ply)
	if IsValid(self.LastGun) and not IsValid(self.LastGun:GetOwner()) then return false end

	local ent = ents.Create(self.CLASS)
	ent:SetPos(ply:EyePos())
	ent:Spawn()

	self.LastGun = ent
	self.LastPly = ply

	self:SetNextSpawn(CurTime() + (self.ResetTimer or self.RESET_TIMER:GetFloat()))

	return true
end
