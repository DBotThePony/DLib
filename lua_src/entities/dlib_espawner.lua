
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

local PICKUP_RANGE = CreateConVar('dlib_spawner_range', '128', {FCVAR_ARCHIVE, FCVAR_NOTIFY}, 'Entity spawner spawn trigger range in Hu')
local RESET_TIMER = CreateConVar('dlib_spawner_timer', '10', {FCVAR_ARCHIVE, FCVAR_NOTIFY}, 'Entity spawner reset timer in seconds')

ENT.Type = 'anim'
ENT.Author = 'DBot'
ENT.PrintName = 'Enitity Spawner Base'
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.DefaultModel = 'models/items/item_item_crate.mdl'
ENT.SPAWN_HOOK_CALL = 'PlayerSpawnSENT'
ENT.SPAWNED_HOOK_CALL = 'PlayerSpawnedSENT'
ENT.IS_SPAWNER = true

ENT.PICKUP_RANGE = PICKUP_RANGE
ENT.RESET_TIMER = RESET_TIMER

function ENT:SetupDataTables()
	self:NetworkVar('Float', 0, 'NextSpawn')
	self:SetNextSpawn(0)
end

function ENT:SpawnFunction(ply, tr, class)
	if not tr.Hit then return end

	local can = hook.Run(self.SPAWN_HOOK_CALL, ply, self.CLASS)
	if can == false then return end

	if not self.TABLE.eSpawnerInfo then
		local newEnt = ents.Create(self.CLASS)
		newEnt:SetPos(tr.HitPos)
		newEnt:Spawn()
		newEnt:Activate()

		local mdl = newEnt:GetModel()
		local skin = newEnt:GetSkin()
		local color = newEnt:GetColor()
		local material = newEnt:GetMaterial()
		local bg = newEnt:GetBodyGroups()

		self.TABLE.eSpawnerInfo = {}
		self.TABLE.eSpawnerInfo.mdl = util.IsValidModel(mdl) and mdl or self.DefaultModel
		self.TABLE.eSpawnerInfo.skin = skin
		self.TABLE.eSpawnerInfo.color = color
		self.TABLE.eSpawnerInfo.material = material
		self.TABLE.eSpawnerInfo.bg = bg
		self.TABLE.eSpawnerInfo.bginfo = {}

		if bg then
			for k, v in pairs(bg) do
				self.TABLE.eSpawnerInfo.bginfo[v.id] = newEnt:GetBodygroup(v.id)
			end
		end

		newEnt:Remove()
	end

	local ent = ents.Create(class)
	ent:SetPos(tr.HitPos + tr.HitNormal)

	local mdl, skin, color, material = self.TABLE.eSpawnerInfo.mdl, self.TABLE.eSpawnerInfo.skin, self.TABLE.eSpawnerInfo.color, self.TABLE.eSpawnerInfo.material

	if mdl then
		ent.Model = mdl
		ent:SetModel(mdl)
	else
		ent:SetModel(self.DefaultModel)
	end

	if skin then
		ent:SetSkin(skin)
	end

	for k, v in pairs(self.TABLE.eSpawnerInfo.bginfo) do
		ent:SetBodygroup(k, v)
	end

	ent:Spawn()
	ent:Activate()

	return ent
end

local MINS, MAXS = Vector(-10, -10, 0), Vector(10, 10, 10)

function ENT:GetIsSpawned()
	return self:GetNextSpawn() < CurTime()
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:DrawShadow(false)

	self.CurrentClip = 0

	if CLIENT then
		self:ClientsideEntity()
		self.CurrAngle = Angle()
		return
	end
end

function ENT:ClientsideEntity()
	if IsValid(self.CModel) then self.CModel:Remove() end

	local ent = ClientsideModel(self:GetModel())
	self.CModel = ent
	ent:SetPos(self:GetPos())
	ent:Spawn()
	ent:Activate()
	ent:SetNoDraw(true)

	if IsValid(self.CModel2) then self.CModel2:Remove() end

	local ent1 = ent
	local ent = ClientsideModel(self:GetModel())
	local ent2 = ent
	self.CModel2 = ent
	ent:SetPos(self:GetPos())
	ent:Spawn()
	ent:Activate()
	ent:SetNoDraw(true)

	local bg = self:GetBodyGroups()

	ent1:SetSkin(self:GetSkin() or 0)
	ent1:SetColor(self:GetColor())
	ent1:SetMaterial(self:GetMaterial() or '')

	ent2:SetSkin(self:GetSkin() or 0)
	ent2:SetColor(self:GetColor())
	ent2:SetMaterial(self:GetMaterial() or '')

	if bg then
		for k, v in pairs(bg) do
			ent1:SetBodygroup(v.id, self:GetBodygroup(v.id))
		end

		for k, v in pairs(bg) do
			ent2:SetBodygroup(v.id, self:GetBodygroup(v.id))
		end
	end
end

function ENT:DoSpawn(ply)
	if ply.EntSpawnerCooldown and ply.EntSpawnerCooldown > CurTime() then return false end

	local try = hook.Run(self.SPAWN_HOOK_CALL, ply, self.CLASS)
	if try == false then return false end

	if not ply:CheckLimit('sents') then
		ply.EntSpawnerCooldown = CurTime() + 10
		return false
	end

	local sfunc = self.TABLE.SpawnFunction
	local ent
	local hpos = self:GetPos() + Vector(0, 0, 40)

	if sfunc then
		local fakeTrace = {
			Hit = true,
			HitPos = hpos,
			StartPos = hpos,
			EndPos = hpos,
			HitWorld = true,
			HitSky = false,
			PhysicsBone = 0,
			HitNoDraw = false,
			HitNonWorld = false,
			HitTexture = '',
			HitGroup = HITGROUP_GENERIC,
			MatType = MAT_GRASS, -- heh
			HitNormal = Vector(0, 0, 1),
			Entity = game.GetWorld()
		}

		ent = sfunc(self.TABLE, ply, fakeTrace, self.CLASS)
		if not ent then return end
	else
		ent = ents.Create(self.CLASS)
	end

	ent:SetPos(hpos)
	ent:Spawn()

	ent:PhysWake()

	hook.Run(self.SPAWNED_HOOK_CALL, ply, ent)

	ent:Activate()

	DoPropSpawnedEffect(ent)

	self.LastEntity = ent
	self.LastPly = ply

	self:SetNextRespawn(CurTime() + (self.ResetTimer or RESET_TIMER:GetFloat()))

	undo.Create('SENT')
	undo.AddEntity(ent)
	undo.SetPlayer(ply)

	if ent.PrintName then
		undo.SetCustomUndoText('Undone ' .. ent.PrintName)
	end

	undo.Finish()

	return true
end

function ENT:Think()
	if CLIENT then return end

	if self:GetIsSpawned() then
		local lpos = self:GetPos()
		local dist = PICKUP_RANGE:GetInt()

		for k, v in ipairs(player.GetAll()) do
			if v:GetPos():Distance(lpos) < dist and self:DoSpawn(v) then
				break
			end
		end
	end
end

local debugwtite = Material('models/debug/debugwhite')
local glow = Color(0, 255, 255)

function ENT:Draw()
	if not IsValid(self.CModel) then self:ClientsideEntity() end
	if not IsValid(self.CModel2) then self:ClientsideEntity() end

	local mdl = self:GetModel()
	self.CModel:SetModel(mdl)
	self.CModel2:SetModel(mdl)

	local ang = self.CurrAngle
	local pos = self:GetPos()

	ang.y = ang.y + FrameTime() * 33
	pos.z = pos.z + math.sin(CurTime() * 2) * 10 + 20

	ang:Normalize()

	self.CModel:SetAngles(ang)
	self.CModel2:SetAngles(ang)
	self.CModel:SetPos(pos)
	self.CModel2:SetPos(pos)

	if self:GetIsSpawned() then
		self.CModel:DrawModel()
		-- God how i hate this part
		-- GMod functions have documented the best
		self.CurrentClip = self.CurrentClip + FrameTime() * 22

		if self.CurrentClip > 150 then
			self.CurrentClip = -150
		end

		local Vec = ang:Forward()

		local First = pos + Vec * self.CurrentClip
		local Second = pos + Vec * self.CurrentClip + Vec * 5
		local dot1 = Vec:Dot(First)
		local dot2 = (-Vec):Dot(Second)

		render.SuppressEngineLighting(true)
		render.ModelMaterialOverride(debugwtite)
		render.SetColorModulation(0, 1, 1)
		render.ResetModelLighting(1, 1, 1)

		local old = render.EnableClipping(true)
		render.PushCustomClipPlane(Vec, dot1)
		render.PushCustomClipPlane(-Vec, dot2)

		self.CModel2:DrawModel()

		render.PopCustomClipPlane()
		render.PopCustomClipPlane()
		render.EnableClipping(old)

		render.SetColorModulation(1, 1, 1)
		render.ModelMaterialOverride()
		render.SuppressEngineLighting(false)
	end

	self.CurrAngle = ang
end

function ENT:OnRemove()
	if CLIENT and IsValid(self.CModel) then
		self.CModel:Remove()
	end

	if CLIENT and IsValid(self.CModel2) then
		self.CModel2:Remove()
	end
end
