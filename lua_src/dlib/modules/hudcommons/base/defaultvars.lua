
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

local meta = DLib.FindMetaTable('HUDCommonsBase')

-- do not override
function meta:__InitVaribles()
	self:RegisterRegularVariable('alive', 'IsAlive', true)

	self:SetOnChangeHook('alive', function(self, hudSelf, localPlayer, old, new)
		if new then
			hudSelf:CallOnRespawn()
		else
			hudSelf.glitchEnd = 0
			hudSelf.glitching = false
			hudSelf:CallOnDeath()
		end
	end)

	self:RegisterRegularVariable('health', 'GetHealth', 0)
	self:RegisterRegularVariable('maxHealth', 'GetMaxHealth', 100)
	self:RegisterRegularVariable('armor', 'GetArmor', 0)
	self:RegisterRegularVariable('nick', 'Nick', 'put playername here')
	self:RegisterRegularVariable('maxArmor', 'GetMaxArmor', 100)

	self:RegisterRegularWeaponVariable('clip1', 'Clip1', 0)
	self:RegisterRegularWeaponVariable('clip2', 'Clip2', 0)
	self:RegisterRegularWeaponVariable('clipMax1', 'GetMaxClip1', 0)
	self:RegisterRegularWeaponVariable('clipMax2', 'GetMaxClip2', 0)

	self:RegisterRegularWeaponVariable('ammoType1', 'GetPrimaryAmmoType', -1)
	self:RegisterRegularWeaponVariable('ammoType2', 'GetSecondaryAmmoType', -1)
	self:RegisterRegularWeaponVariable('weaponName', 'GetPrintName', '')

	self:RegisterVariable('ammo1', 0)
	self:RegisterVariable('ammo1_Select', 0)
	self:RegisterVariable('ammo2', 0)
	self:RegisterVariable('ammo2_Select', 0)

	self:SetTickHook('ammo1', function(self, hudSelf, localPlayer, current)
		local atype = hudSelf:GetVarAmmoType1()

		if atype == -1 then
			return -1
		else
			return localPlayer:GetAmmoCount(atype)
		end
	end)

	self:SetTickHook('ammo2', function(self, hudSelf, localPlayer, current)
		local atype = hudSelf:GetVarAmmoType2()

		if atype == -1 then
			return -1
		else
			return localPlayer:GetAmmoCount(atype)
		end
	end)

	self:SetTickHook('ammo1_Select', function(self, hudSelf, localPlayer, current)
		local atype = hudSelf:GetVarAmmoType1_Select()

		if atype == -1 then
			return -1
		else
			return localPlayer:GetAmmoCount(atype)
		end
	end)

	self:SetTickHook('ammo2_Select', function(self, hudSelf, localPlayer, current)
		local atype = hudSelf:GetVarAmmoType2_Select()

		if atype == -1 then
			return -1
		else
			return localPlayer:GetAmmoCount(atype)
		end
	end)
end
