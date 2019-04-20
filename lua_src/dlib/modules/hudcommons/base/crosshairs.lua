
-- Copyright (C) 2017-2019 DBot

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

local meta = DLib.FindMetaTable('HUDCommonsBase')
local DLib = DLib
local LocalPlayer = LocalPlayer
local LocalWeapon = LocalWeapon
local IsValid2 = IsValid
local IsValid = FindMetaTable('Entity').IsValid
local table = table
local surface = surface
local math = math
local ScreenSize = ScreenSize
local RealTimeL = RealTimeL

function meta:RegisterCrosshairHandle()
	self.ENABLE_CROSSHAIRS = self:CreateConVar('crosshairs', '1', 'Enable custom crosshairs')

	self:AddHookCustom('HUDShouldDraw', 'CrosshairShouldDraw')
	self:AddPaintHook('InternalDrawCrosshair')
end

function meta:DrawCrosshairGeneric(x, y, accuracy)
	-- generic code
end

function meta:DrawCrosshairMelee(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:DrawCrosshairPistol(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:DrawCrosshairRevolver(x, y, accuracy)
	return self:DrawCrosshairPistol(x, y, accuracy)
end

function meta:DrawCrosshairSubmachine(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:DrawCrosshairRifle(x, y, accuracy)
	return self:DrawCrosshairSubmachine(x, y, accuracy)
end

function meta:DrawCrosshairHeavyRifle(x, y, accuracy)
	return self:DrawCrosshairRifle(x, y, accuracy)
end

function meta:DrawCrosshairBigCalibreRifle(x, y, accuracy)
	return self:DrawCrosshairHeavyRifle(x, y, accuracy)
end

function meta:DrawCrosshairShotgun(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:DrawCrosshairElectronEnergy(x, y, accuracy)
	return self:DrawCrosshairShotgun(x, y, accuracy)
end

function meta:DrawCrosshairAlien(x, y, accuracy)
	return self:DrawCrosshairShotgun(x, y, accuracy)
end

function meta:DrawCrosshairEnergy(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:DrawCrosshairDarkEnergy(x, y, accuracy)
	return self:DrawCrosshairAlien(x, y, accuracy)
end

function meta:DrawCrosshairSniper(x, y, accuracy)
	return self:DrawCrosshairRifle(x, y, accuracy)
end

function meta:DrawCrosshairNade(x, y, accuracy)
	return self:DrawCrosshairShotgun(x, y, accuracy)
end

function meta:DrawCrosshairDeployable(x, y, accuracy)
	return self:DrawCrosshairNade(x, y, accuracy)
end

function meta:DrawCrosshairRPG(x, y, accuracy)
	return self:DrawCrosshairShotgun(x, y, accuracy)
end

function meta:DrawCrosshairToolgun(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:DrawCrosshairGravityGun(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:DrawCrosshairPhysicsGun(x, y, accuracy)
	return self:DrawCrosshairGeneric(x, y, accuracy)
end

function meta:GetRealAmmoType()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return self:GetVarAmmoType2()
	end

	return self:GetVarAmmoType1()
end

local wepTypeDef = {}

local mapping = {
	['ar2'] = 'DrawCrosshairRifle',
	['ar2altfire'] = 'DrawCrosshairDarkEnergy',
	['pistol'] = 'DrawCrosshairPistol',
	['smg1'] = 'DrawCrosshairSubmachine',
	['357'] = 'DrawCrosshairRevolver',
	['xbowbolt'] = 'DrawCrosshairSniper',
	['buckshot'] = 'DrawCrosshairShotgun',
	['rpg_round'] = 'DrawCrosshairRPG',
	['smg1_grenade'] = 'DrawCrosshairNade',
	['grenade'] = 'DrawCrosshairNade',
	['slam'] = 'DrawCrosshairDeployable',
	['alyxgun'] = 'DrawCrosshairSubmachine',
	['sniperround'] = 'DrawCrosshairSniper',
	['sniperpenetratedround'] = 'DrawCrosshairSniper',
	['thumper'] = 'DrawCrosshairDarkEnergy',
	['gravity'] = 'DrawCrosshairDarkEnergy',
	['battery'] = 'DrawCrosshairEnergy',
	['gaussenergy'] = 'DrawCrosshairEnergy',
	['combinecannon'] = 'DrawCrosshairHeavyRifle',
	['airboatgun'] = 'DrawCrosshairHeavyRifle',
	['striderminigun'] = 'DrawCrosshairHeavyRifle',
	['helicoptergun'] = 'DrawCrosshairHeavyRifle',
	['9mmround'] = 'DrawCrosshairSubmachine',
	['357round'] = 'DrawCrosshairRevolver',
	['mp5_grenade'] = 'DrawCrosshairNade',
	['rpg_rocket'] = 'DrawCrosshairRPG',
	['uranium'] = 'DrawCrosshairElectronEnergy',
	['hornet'] = 'DrawCrosshairAlien',
	['snark'] = 'DrawCrosshairNade',
	['tripmine'] = 'DrawCrosshairDeployable',
	['satchel'] = 'DrawCrosshairDeployable',
	['12mmround'] = 'DrawCrosshairGeneric',
	['striderminigundirect'] = 'DrawCrosshairHeavyRifle',
	['combineheavycannon'] = 'DrawCrosshairBigCalibreRifle',
}

local function refreshTypes()
	local i = 1
	local nextAmmoType

	repeat
		nextAmmoType = game.GetAmmoName(i)
		i = i + 1

		if nextAmmoType then
			wepTypeDef[i] = nextAmmoType:gsub('HL1', ''):lower()
		end
	until not nextAmmoType
end

if AreEntitiesAvailable() then
	refreshTypes()
else
	hook.Add('InitPostEntity', 'HUDCommons.GetAmmoTypes', refreshTypes)
end

function meta:InternalDrawCrosshair(ply)
	if not self.ENABLE_CROSSHAIRS:GetBool() then return end
	local weapon = self:GetWeapon()
	if not IsValid(weapon) then return end
	local ammotype = self:GetRealAmmoType()

	if weapon.DrawCrosshair == false or weapon.HUDShouldDraw and weapon:HUDShouldDraw('CHudCrosshair') == false then
		return
	end

	local tr = ply:GetEyeTrace()
	local x, y = tr.HitPos:ToScreen()
	x, y = x.x, x.y
	x = (x / 1.3):ceil() * 1.3
	y = (y / 1.3):ceil() * 1.3

	if weapon.DoDrawCrosshair and weapon:DoDrawCrosshair(x, y) == true then
		return
	end

	local typedef = wepTypeDef[ammotype]
	local mapping = mapping[typedef]
	local wclass = self:GetVarWeaponClass()

	if mapping then
		self[mapping](self, x, y, 1)
	elseif wclass == 'gmod_tool' then
		self:DrawCrosshairToolgun(x, y, 1)
	elseif wclass == 'weapon_physgun' then
		self:DrawCrosshairPhysicsGun(x, y, 1)
	elseif wclass == 'weapon_physcannon' then
		self:DrawCrosshairGravityGun(x, y, 1)
	elseif ammotype == -1 and not self:ShouldDisplayAmmo() then
		self:DrawCrosshairMelee(x, y, 1)
	else
		self:DrawCrosshairGeneric(x, y, 1)
	end
end

function meta:CrosshairShouldDraw(element)
	if element == 'CHudCrosshair' and self.ENABLE_CROSSHAIRS:GetBool() then
		return false
	end
end
