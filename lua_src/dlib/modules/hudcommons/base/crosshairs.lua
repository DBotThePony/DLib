
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
local LocalPlayer = LocalPlayer
local LocalWeapon = LocalWeapon
local IsValid2 = IsValid
local IsValid = FindMetaTable('Entity').IsValid
local table = table
local surface = surface
local math = math
local ScreenSize = ScreenSize
local RealTimeL = RealTimeL
local CurTime = UnPredictedCurTime
local crosshair = ConVar('crosshair')

local startTooHeavy, endTooHeavy, heavyType = 0, 0, false
local startOpenClaws, endOpenClaws, clawsType = 0, 0, false
local startHold, endHold, holdType = 0, 0, false

net.receive('dlib_physgun_tooheavy', function()
	startTooHeavy, endTooHeavy, heavyType = CurTime(), CurTime() + 0.2, net.ReadBool()
end)

net.receive('dlib_physgun_claws', function()
	startOpenClaws, endOpenClaws, clawsType = CurTime(), CurTime() + 0.2, net.ReadBool()
end)

net.receive('dlib_physgun_hold', function()
	startHold, endHold, holdType = CurTime(), CurTime() + 0.2, net.ReadBool()
	startOpenClaws, endOpenClaws, clawsType = 0, 0, false
	startTooHeavy, endTooHeavy, heavyType = 0, 0, false
end)

function meta:RegisterCrosshairHandle(default, tfa, dynamic, dynamic_always, static_scale)
	default, tfa, dynamic, dynamic_always, static_scale = default or '1', tfa or '1', dynamic or '1', dynamic_always or '1', static_scale or '0'

	self.ENABLE_CROSSHAIRS = self:CreateConVar('crosshairs', default, 'Enable custom crosshairs')
	self.ENABLE_CROSSHAIRS_TFA = self:CreateConVar('crosshairs_tfa', tfa, 'Handle (replace) TFA Base crosshairs')
	self.DYNAMIC_CROSSHAIR = self:CreateConVar('crosshairs_dynamic', dynamic, 'Dynamic scaling crosshair based on distance')
	self.DYNAMIC_CROSSHAIR_ALWAYS = self:CreateConVar('crosshairs_dynamic_always', dynamic_always, 'Always show dynamic crosshair, instead of only in third person')

	self.STATIC_CROSSHAIR_SCALE = self:CreateConVar('crosshairs_static_scale', static_scale, 'Static scale crosshair')

	self._nextDisableCrosshair = true
	self.lastDistAccuracyMult = 1
	self.UpcomingAccuracy = 1

	self:AddHookCustom('HUDShouldDraw', 'CrosshairShouldDraw', nil, 6)
	self:AddHookCustom('HUDPaint', 'InternalDrawCrosshair', nil, 6)
	self:AddHook('TFA_DrawCrosshair')
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

function meta:DrawCrosshairGravityGunClawsOpening(x, y, accuracy)
	return self:DrawCrosshairGravityGun(x, y, accuracy)
end

function meta:DrawCrosshairGravityGunClawsClosing(x, y, accuracy)
	return self:DrawCrosshairGravityGun(x, y, accuracy)
end

function meta:DrawCrosshairGravityGunClawsHolding(x, y, accuracy)
	return self:DrawCrosshairGravityGun(x, y, accuracy)
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

		if nextAmmoType then
			wepTypeDef[i] = nextAmmoType:gsub('HL1', ''):lower()
		end

		i = i + 1
	until not nextAmmoType
end

if AreEntitiesAvailable() then
	refreshTypes()
else
	hook.Add('InitPostEntity', 'HUDCommons.GetAmmoTypes', refreshTypes)
end

function meta:HandleDoDrawCrosshair(x, y, weapon)
	self.handledTFA = false

	local status = weapon:DoDrawCrosshair(x, y)

	if self.handledTFA then
		return false
	end

	return status
end

local lastShouldDrawLocalPlayer = false
local lastFOV = 90
local lastOrigin = Vector()
local LocalPlayer = LocalPlayer

function meta:UpdateUpcomingAccuracy(val)
	self.UpcomingAccuracy = val
end

function meta:GetUpcomingAccuracy(val)
	return self.UpcomingAccuracy
end

function meta:InternalDrawCrosshair(ply)
	if not crosshair:GetBool() then return end
	if not self.ENABLE_CROSSHAIRS:GetBool() then return end
	ply = ply or self:SelectPlayer()

	if not self:GetVarAlive() or not self:WeaponsInVehicle() then return end
	local useEnt = self:GetVarEntityInUse()

	if IsValid(useEnt) then
		if useEnt:GetClass() ~= 'func_tank' then return end

		local tr = ply:GetEyeTrace()
		local x, y = tr.HitPos:ToScreen()
		x, y = x.x, x.y
		x = (x / 1.3):ceil() * 1.3
		y = (y / 1.3):ceil() * 1.3

		self:DrawCrosshairHeavyRifle(x, y, 1)
		return
	end

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

	local accuracy = (90 / (lastFOV or ply:GetFOV())):pow(1.19)

	local typedef = wepTypeDef[ammotype]
	local mapping = mapping[typedef]
	local wclass = self:GetVarWeaponClass()

	if not self.STATIC_CROSSHAIR_SCALE:GetBool() and mapping ~= 'DrawCrosshairRPG' and mapping ~= 'DrawCrosshairNade' and self.DYNAMIC_CROSSHAIR:GetBool() and (self.DYNAMIC_CROSSHAIR_ALWAYS:GetBool() or lastShouldDrawLocalPlayer and ply == LocalPlayer()) then
		local newAcc = (tr.StartPos:Distance(tr.HitPos) / 256):pow(1 / 3) * (90 / (lastFOV or ply:GetFOV())):pow(1.19) * 0.4
		self.lastDistAccuracyMult = Lerp(FrameTime() * 4, self.lastDistAccuracyMult, newAcc)

		if self.lastDistAccuracyMult ~= self.lastDistAccuracyMult then
			self.lastDistAccuracyMult = newAcc
		end

		accuracy = self.lastDistAccuracyMult
	end

	UpcomingAccuracy = accuracy

	if weapon.DoDrawCrosshair and self:HandleDoDrawCrosshair(x, y, weapon) == true then
		return
	end

	local ctime = CurTime()

	if mapping then
		self[mapping](self, x, y, UpcomingAccuracy)
	elseif wclass == 'gmod_tool' then
		self:DrawCrosshairToolgun(x, y, 0)
	elseif wclass == 'weapon_physgun' then
		self:DrawCrosshairPhysicsGun(x, y, 0)
	elseif wclass == 'weapon_physcannon' then
		if holdType then
			self:DrawCrosshairGravityGun(x, y, 1 - ctime:progression(startHold, endHold))
		elseif endHold >= ctime then
			self:DrawCrosshairGravityGun(x, y, ctime:progression(startHold, endHold))
		elseif clawsType then
			self:DrawCrosshairGravityGun(x, y, 2 - ctime:progression(startOpenClaws, endOpenClaws))
		elseif endOpenClaws >= ctime then
			self:DrawCrosshairGravityGun(x, y, 1 + ctime:progression(startOpenClaws, endOpenClaws))
		elseif heavyType then
			self:DrawCrosshairGravityGun(x, y, 2 + ctime:progression(startTooHeavy, endTooHeavy))
		elseif endTooHeavy >= ctime then
			self:DrawCrosshairGravityGun(x, y, 3 - ctime:progression(startTooHeavy, endTooHeavy))
		else
			self:DrawCrosshairGravityGun(x, y, 2)
		end
	elseif wclass == 'weapon_crowbar' then
		self:DrawCrosshairMelee(x, y, 0)
	elseif ammotype == -1 and not self:ShouldDisplayAmmo() then
		self:DrawCrosshairMelee(x, y, UpcomingAccuracy)
	else
		self:DrawCrosshairGeneric(x, y, UpcomingAccuracy)
	end
end

function meta:TFA_DrawCrosshair(weapon, x, y)
	if not self.ENABLE_CROSSHAIRS:GetBool() or not self.ENABLE_CROSSHAIRS_TFA:GetBool() then return end
	local drawstatus = TFA.Enum.ReloadStatus[weapon:GetStatus()] or
		math.min(weapon.DrawCrosshairIS and 1 or (1 - weapon.IronSightsProgress), 1 - weapon.SprintProgress, 1 - weapon.InspectingProgress) <= 0.5

	if drawstatus then return true end

	self.handledTFA = true

	local ttype = weapon:GetType()

	if self.STATIC_CROSSHAIR_SCALE:GetBool() then
		UpcomingAccuracy = 1
	else
		local points, gap = weapon:CalculateConeRecoil()

		if ttype == 'Shotgun' then
			UpcomingAccuracy = UpcomingAccuracy * (points / 0.05) * 1.25
		else
			UpcomingAccuracy = UpcomingAccuracy * (points / 0.02) * 1.45
		end
	end

	return true
end

hook.Add('CalcView', 'HUDCommons.CrosshairWatch', function(ply, origin, angles, fov, znear, zfar)
	lastFOV = fov
	lastOrigin = origin
end, -3)

hook.AddPostModifier('CalcView', 'HUDCommons.CrosshairWatch', function(data)
	if not data then return end
	lastShouldDrawLocalPlayer = data.drawviewer
	lastFOV = data.fov or lastFOV
	lastOrigin = data.origin or lastOrigin
	return data
end)

function meta:CrosshairShouldDraw(element)
	if element == 'CHudCrosshair' and self.ENABLE_CROSSHAIRS:GetBool() then
		return false
	end
end
