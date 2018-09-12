
-- Copyright (C) 2017-2018 DBot

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
		local class = self:GetClass()
		return class == 'class C_PhysPropClientside' or class == 'class C_ClientRagdoll' or class == 'class CLuaEffect'
	end

	function Ent:Remove()
		local class = self:GetClass()

		if class ~= 'class C_PhysPropClientside' and class ~= 'class C_ClientRagdoll' and class ~= 'class CLuaEffect' then
			print(debug.traceback('[DLib] Maybe removal of non clientside entity (' .. (class or 'NOT_A_CLASS') .. ')', 1))
		end

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
