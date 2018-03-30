
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

local entMeta = FindMetaTable('Entity')
local plyMeta = FindMetaTable('Player')
local npcMeta = FindMetaTable('NPC')

function entMeta:IsClientsideEntity()
	return false
end

function plyMeta:GetActiveWeaponClass()
	local weapon = self:GetActiveWeapon()
	if not weapon:IsValid() then return nil end
	return weapon:GetClass()
end

npcMeta.GetActiveWeaponClass = plyMeta.GetActiveWeaponClass

if CLIENT then
	local CSEnt = FindMetaTable('CSEnt')
	local Ent = FindMetaTable('Entity')
	Ent.RemoveDLib = Ent.RemoveDLib or Ent.Remove

	function CSEnt:IsClientsideEntity()
		return true
	end

	function Ent:IsClientsideEntity()
		return false
	end

	function Ent:Remove()
		print(debug.traceback('[DLib] Maybe removal of non clientside entity', 1))
		return self:RemoveDLib()
	end
else
	function entMeta:BuddhaEnable()
		self:SetSaveValue('m_takedamage', DAMAGE_MODE_BUDDHA)
	end

	function entMeta:BuddhaDisable()
		self:SetSaveValue('m_takedamage', DAMAGE_MODE_ENABLED)
	end

	function entMeta:IsBuddhaEnabled()
		return self:GetSaveTable().m_takedamage == DAMAGE_MODE_BUDDHA
	end
end

function plyMeta:GetHealth()
	return self:Health()
end

function plyMeta:GetArmor()
	return self:Armor()
end

function plyMeta:IsAlive()
	return self:Alive()
end

function plyMeta:GetIsAlive()
	return self:Alive()
end

-- placeholder for now
function plyMeta:GetMaxArmor()
	return 100
end
