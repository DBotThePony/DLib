
-- Copyright (C) 2017-2020 DBotThePony

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
local HUDCommons = DLib.HUDCommons
local meta = HUDCommons.BaseMetaObj
local math = math
local gmod_suit = GetConVar('gmod_suit')
local SPRINT = GetConVar('sv_limited_sprint')
local WATER = GetConVar('sv_limited_oxygen')

timer.Simple(0, function()
	SPRINT = GetConVar('sv_limited_sprint')
	WATER = GetConVar('sv_limited_oxygen')
end)

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

	self:RegisterRegularVariable('inVehicle', 'InVehicle', false)
	self:RegisterRegularVariable('inDrive', 'IsDrivingEntity', false)
	self:RegisterRegularVariable('weaponsInVehicle', 'GetAllowWeaponsInVehicle', false)
	self:RegisterRegularVariable('health', 'Health', 0)
	self:RegisterRegularVariable('maxHealth', 'GetMaxHealth', 100)
	self:RegisterRegularVariable('armor', 'Armor', 0)
	self:RegisterRegularVariable('nick', 'Nick', 'put playername here')
	self:RegisterRegularVariable('maxArmor', 'GetMaxArmor', 100)
	self:RegisterRegularVariable('team', 'Team', 0)
	self:RegisterRegularVariable('wearingSuit', 'IsSuitEquipped', true)
	self:RegisterRegularVariable('entityInUse', 'GetEntityInUse', NULL)

	self:RegisterRegularWeaponVariable('clip1', 'Clip1', 0)
	self:RegisterRegularWeaponVariable('clip2', 'Clip2', 0)
	self:RegisterRegularWeaponVariable('clipMax1', 'GetMaxClip1', 0)
	self:RegisterRegularWeaponVariable('clipMax2', 'GetMaxClip2', 0)

	self:RegisterRegularWeaponVariable('ammoType1', 'GetPrimaryAmmoType', -1)
	self:RegisterRegularWeaponVariable('ammoType2', 'GetSecondaryAmmoType', -1)
	self:RegisterRegularWeaponVariable('weaponName', 'GetPrintName', '')
	self:RegisterRegularWeaponVariable('weaponClass', 'GetClass', '')
	self:RegisterRegularWeaponVariable('customAmmoDisplayCache', 'CustomAmmoDisplay', 'NULLABLE')

	self:RegisterVariable('suitPower', -1)

	self:RegisterVariable('ammo1', 0)
	self:RegisterVariable('ammo1_Select', 0)
	self:RegisterVariable('ammo2', 0)
	self:RegisterVariable('ammo2_Select', 0)

	self:SetTickHook('suitPower', function(self, hudSelf, localPlayer, current)
		if not hudSelf:GetVarWearingSuit() then return -1 end

		if gmod_suit and gmod_suit:GetBool() then
			return localPlayer:GetSuitPower() or -1
		end

		if localPlayer.GetLimitedHEVPower and (SPRINT and SPRINT:GetBool() or WATER and WATER:GetBool()) then
			return localPlayer:GetLimitedHEVPower()
		end

		return -1
	end)

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
	self:RegisterVehicleVariable('vehicleHP', 'Health', 0)
	self:RegisterVehicleVariable('vehicleHP2', 'GetHP', 0)
	self:RegisterVehicleVariable('vehicleHP3', 'GetCurHealth', 0)
	self:RegisterVehicleVariable('vehicleHP4', 'GetCurrentHealth', 0)
	self:RegisterVehicleVariable('vehicleHP5', 'GetVehicleHealth', 0)

	self:RegisterVehicleVariable('vehicleMHP', 'GetMaxHealth', 0)
	self:RegisterVehicleVariable('vehicleMHP2', 'GetMaxHP', 0)
	self:RegisterVehicleVariable('vehicleMHP3', 'GetMaxVehicleHealth', 0)
	self:RegisterVehicleVariable('vehicleMHP4', 'GetVehicleHealthMax', 0)
	self:RegisterVehicleVariable('vehicleMHP5', 'GetVehicleMaxHealth', 0)

	self:RegisterVariable('vehicleAmmoType', -1)
	self:RegisterVariable('vehicleAmmoClip', -1)
	self:RegisterVariable('vehicleAmmoMax', -1)

	local lastClip, lastMax, lastType

	self:SetTickHook('vehicleAmmoType', function(self, hudSelf, localPlayer, current)
		local veh = hudSelf:GetVehicleRecursive()

		if IsValid(veh) then
			lastType, lastMax, lastClip = veh:GetAmmo()
			return lastType
		else
			return -1
		end
	end)

	self:SetTickHook('vehicleAmmoClip', function(self, hudSelf, localPlayer, current)
		return lastClip or -1
	end)

	self:SetTickHook('vehicleAmmoMax', function(self, hudSelf, localPlayer, current)
		return lastMax or -1
	end)
end

--[[
	@doc
	@fname HUDCommonsBase:GetVarVehicleHealth

	@client

	@returns
	number
]]
function meta:GetVarVehicleHealth()
	return math.max(self:GetVarVehicleHP(), self:GetVarVehicleHP2(), self:GetVarVehicleHP3(), self:GetVarVehicleHP4(), self:GetVarVehicleHP5()):floor()
end

--[[
	@doc
	@fname HUDCommonsBase:GetVarVehicleMaxHealth

	@client

	@returns
	number: assume 0 as invalid vehicle
]]
function meta:GetVarVehicleMaxHealth()
	return math.max(self:GetVarVehicleMHP(), self:GetVarVehicleMHP2(), self:GetVarVehicleMHP3(), self:GetVarVehicleMHP4(), self:GetVarVehicleMHP5()):floor()
end

--[[
	@doc
	@fname HUDCommonsBase:GetVehicleHealthFillage

	@client

	@returns
	number: float in range of 0 to 1 inclusive
]]
function meta:GetVehicleHealthFillage()
	if self:GetVarVehicleMaxHealth() <= 0 then return 1 end
	if self:GetVarVehicleMaxHealth() <= self:GetVarVehicleHealth() then return 1 end
	return math.max(0, self:GetVarVehicleHealth() / self:GetVarVehicleMaxHealth())
end
