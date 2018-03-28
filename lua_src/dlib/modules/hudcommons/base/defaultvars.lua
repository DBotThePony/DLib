
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
local math = math

-- do not override
function meta:__InitVaribles()
	self:RegisterRegularVariable('alive', 'IsAlive', true)

	self:SetOnChangeHook('alive', function(self, hudSelf, localPlayer, old, new)
		hudSelf.glitchEnd = 0
		hudSelf.glitching = false

		if new then
			hudSelf:CallOnRespawn()
		else
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

	self:RegisterVehicleVariable('vehicleName', 'GetPrintNameDLib', '')
	self:RegisterVehicleVariable('vehicleHP', 'GetHealth', 0)
	self:RegisterVehicleVariable('vehicleHP2', 'GetHP', 0)
	self:RegisterVehicleVariable('vehicleHP3', 'GetCurHealth', 0)
	self:RegisterVehicleVariable('vehicleHP4', 'GetCurrentHealth', 0)
	self:RegisterVehicleVariable('vehicleHP5', 'GetVehicleHealth', 0)

	self:RegisterVehicleVariable('vehicleMHP', 'GetMaxHealth', 0)
	self:RegisterVehicleVariable('vehicleMHP2', 'GetMaxHP', 0)
	self:RegisterVehicleVariable('vehicleMHP3', 'GetMaxVehicleHealth', 0)
	self:RegisterVehicleVariable('vehicleMHP4', 'GetVehicleHealthMax', 0)
	self:RegisterVehicleVariable('vehicleMHP5', 'GetVehicleMaxHealth', 0)
end

function meta:GetVarVehicleHealth()
	return math.max(self:GetVarVehicleHP(), self:GetVarVehicleHP2(), self:GetVarVehicleHP3(), self:GetVarVehicleHP4(), self:GetVarVehicleHP5()):floor()
end

function meta:GetVarVehicleMaxHealth()
	return math.max(self:GetVarVehicleMHP(), self:GetVarVehicleMHP2(), self:GetVarVehicleMHP3(), self:GetVarVehicleMHP4(), self:GetVarVehicleMHP5()):floor()
end

function meta:GetVehicleHealthFillage()
	if self:GetVarVehicleMaxHealth() <= 0 then return 1 end
	if self:GetVarVehicleMaxHealth() <= self:GetVarVehicleHealth() then return 1 end
	return math.max(0, self:GetVarVehicleHealth() / self:GetVarVehicleMaxHealth())
end
