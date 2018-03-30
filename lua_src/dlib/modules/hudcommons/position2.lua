
--
-- Copyright (C) 2017-2018 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local ENABLE_SHIFTING = CreateConVar('dlib_hud_shift', '1', {FCVAR_ARCHIVE}, 'Enable HUD shifting')
local ENABLE_SHIFTING_WEAPON = CreateConVar('dlib_hud_shift_wp', '1', {FCVAR_ARCHIVE}, 'Enable HUD shifting with weapons')
local ENABLE_SHIFTING_SV = CreateConVar('sv_dlib_hud_shift', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'SV Override: Enable HUD shifting')
local ENABLE_SHIFTING_SV_WEAPON = CreateConVar('sv_dlib_hud_shift_wp', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'SV Override: Enable HUD shifting with weapons')

local SHIFTING_CLAMP_DEF = CreateConVar('dlib_hud_shift_clamp', '1', {FCVAR_ARCHIVE}, 'Clamp of cam move affect for hud')
local SHIFTING_CLAMP_WEP = CreateConVar('dlib_hud_shift_wepclamp', '1', {FCVAR_ARCHIVE}, 'Clamp of weapon move affect for hud')

local SHIFTING_MULT_DEF = CreateConVar('dlib_hud_shift_mult', '1', {FCVAR_ARCHIVE}, 'Multiplier of cam move affect for hud')
local SHIFTING_MULT_WEP = CreateConVar('dlib_hud_shift_wepmult', '1', {FCVAR_ARCHIVE}, 'Multiplier of weapon move affect for hud')

local HUDCommons = HUDCommons
local table = table
local RealTimeL = RealTimeL
local math = math
local LerpCubic = LerpCubic
local LerpCosine = LerpCosine
local LerpAngle = LerpAngle
local LerpSinusine = LerpSinusine
local WorldToLocal = WorldToLocal
local ScreenSize = ScreenSize

HUDCommons.Position2 = HUDCommons.Position2 or {}
local Pos2 = HUDCommons.Position2

Pos2.ShiftX = 0
Pos2.ShiftX_Weapon = 0
Pos2.ShiftY = 0
Pos2.ShiftY_Weapon = 0
Pos2.LastAngle = Angle(0, 0, 0)

Pos2.XPositions = Pos2.XPositions or {}
Pos2.YPositions = Pos2.YPositions or {}
Pos2.XPositions_modified = Pos2.XPositions_modified or {}
Pos2.YPositions_modified = Pos2.YPositions_modified or {}
Pos2.XPositions_original = Pos2.XPositions_original or {}
Pos2.YPositions_original = Pos2.YPositions_original or {}
Pos2.Positions_funcs = Pos2.Positions_funcs or {}

function Pos2.DefinePosition(name, x, y, shouldShift)
	if shouldShift ~= nil then
		if type(shouldShift) ~= 'function' then
			local l = shouldShift
			shouldShift = function() return l end
		end
	else
		shouldShift = function() return true end
	end

	if x > 1 then
		x = x / ScrWL()
	end

	if y > 1 then
		y = y / ScrWL()
	end

	Pos2.XPositions_original[name] = x
	Pos2.YPositions_original[name] = y

	Pos2.XPositions_modified[name] = x
	Pos2.YPositions_modified[name] = y

	if not table.HasValue(Pos2.XPositions, name) then
		table.insert(Pos2.XPositions, name)
	end

	if not table.HasValue(Pos2.YPositions, name) then
		table.insert(Pos2.YPositions, name)
	end

	Pos2.Positions_funcs[name] = shouldShift

	return function()
		if shouldShift() then
			return Pos2.XPositions_modified[name], Pos2.YPositions_modified[name]
		else
			return Pos2.XPositions_original[name], Pos2.YPositions_original[name]
		end
	end
end

Pos2.CreatePosition = Pos2.DefinePosition

function Pos2.GetPos(elem)
	if not Pos2.Positions_funcs[elem] or Pos2.Positions_funcs[elem]() then
		return Pos2.XPositions_modified[elem] or 0, Pos2.YPositions_modified[elem] or 0
	else
		return Pos2.XPositions_original[elem] or 0, Pos2.YPositions_original[elem] or 0
	end
end

Pos2.GetPosition = Pos2.GetPos

local function UpdatePositions()
	local w, h = ScrWL(), ScrHL()

	if ENABLE_SHIFTING:GetBool() and ENABLE_SHIFTING_SV:GetBool() then
		for k, v in ipairs(Pos2.XPositions) do
			Pos2.XPositions_modified[v] = Pos2.XPositions_original[v] * w + Pos2.ShiftX + Pos2.ShiftX_Weapon
		end

		for k, v in ipairs(Pos2.YPositions) do
			Pos2.YPositions_modified[v] = Pos2.YPositions_original[v] * h + Pos2.ShiftY + Pos2.ShiftY_Weapon
		end
	else
		for k, v in ipairs(Pos2.XPositions) do
			Pos2.XPositions_modified[v] = Pos2.XPositions_original[v] * w
		end

		for k, v in ipairs(Pos2.YPositions) do
			Pos2.YPositions_modified[v] = Pos2.YPositions_original[v] * h
		end
	end
end

local function UpdateShift(delta)
	if not ENABLE_SHIFTING:GetBool() then return end
	if not ENABLE_SHIFTING_SV:GetBool() then return end

	local ply = HUDCommons.SelectPlayer()
	local ang = ply:EyeAngles()

	local changePitch = math.AngleDifference(ang.p, Pos2.LastAngle.p)
	local changeYaw = math.AngleDifference(ang.y, Pos2.LastAngle.y)

	Pos2.LastAngle = LerpAngle(delta * 22, Pos2.LastAngle, ang)
	local M1, M2 = ScreenSize(20) * SHIFTING_CLAMP_DEF:GetFloat():clamp(0, 10), ScreenSize(30) * SHIFTING_CLAMP_DEF:GetFloat():clamp(0, 10)

	Pos2.ShiftX = math.Clamp(Pos2.ShiftX + changeYaw * 1.8, -M2, M2)
	Pos2.ShiftY = math.Clamp(Pos2.ShiftY - changePitch * 1.8, -M1, M1)

	local oldX, oldY = Pos2.ShiftX, Pos2.ShiftY

	Pos2.ShiftX = Pos2.ShiftX - Pos2.ShiftX * delta * 11 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)
	Pos2.ShiftY = Pos2.ShiftY - Pos2.ShiftY * delta * 11 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)

	if oldX > 0 and Pos2.ShiftX < 0 or oldX < 0 and Pos2.ShiftX > 0 then
		Pos2.ShiftX = 0
	end

	if oldY > 0 and Pos2.ShiftY < 0 or oldY < 0 and Pos2.ShiftY > 0 then
		Pos2.ShiftY = 0
	end
end

local lastWeaponPosX = 0
local lastWeaponPosY = 0
local lastWeaponPosZ = 0
local lastWeapon = NULL
local WorldToLocal = WorldToLocal
local IsValid = FindMetaTable('Entity').IsValid

local function UpdateWeaponShift(delta)
	if not ENABLE_SHIFTING:GetBool() then return end
	if not ENABLE_SHIFTING_WEAPON:GetBool() then return end
	if not ENABLE_SHIFTING_SV:GetBool() then return end
	if not ENABLE_SHIFTING_SV_WEAPON:GetBool() then return end

	Pos2.ShiftX_Weapon = LerpCosine(delta * 7, Pos2.ShiftX_Weapon, 0)
	Pos2.ShiftY_Weapon = LerpSinusine(delta * 7, Pos2.ShiftY_Weapon, 0)

	local ply = HUDCommons.SelectPlayer()
	if ply:InVehicle() then return end
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end
	local plyPos = ply:EyePos()
	local plyAng = ply:EyeAngles()
	local xs, ys, zs = 0, 0, 0
	local amount = 0

	if ply.GetViewModel then
		local view = ply:GetViewModel()

		if IsValid(view) then
			local bones = view:GetBoneCount()
			amount = amount + bones

			for bone = 0, bones - 1 do
				local bpos, bang = view:GetBonePosition(bone)
				bang = bang + view:GetManipulateBoneAngles(bone)
				bpos = bpos + view:GetManipulateBonePosition(bone)
				local npos, nang = WorldToLocal(bpos, bang, plyPos, plyAng)
				xs = xs + npos.x
				ys = ys + npos.y
				zs = zs + npos.z
			end
		end
	end

	if ply.GetHands then
		local hands = ply:GetHands()

		if IsValid(hands) then
			local bones = hands:GetBoneCount()
			amount = amount + bones

			for bone = 0, bones - 1 do
				local bpos, bang = hands:GetBonePosition(bone)
				bang = bang + hands:GetManipulateBoneAngles(bone)
				bpos = bpos + hands:GetManipulateBonePosition(bone)
				local npos, nang = WorldToLocal(bpos, bang, plyPos, plyAng)
				xs = xs + npos.x
				ys = ys + npos.y
				zs = zs + npos.z
			end
		end
	end

	if amount <= 2 then return end
	local div = ScreenSize(1) * SHIFTING_MULT_WEP:GetFloat():clamp(0, 10)

	xs, ys, zs = xs / amount, ys / amount, zs / amount
	local changeX = (xs - lastWeaponPosX) * div
	local changeY = (ys - lastWeaponPosY) * div
	local changeZ = (zs - lastWeaponPosZ) * div

	lastWeaponPosX = LerpCubic(delta * 44, lastWeaponPosX, xs)
	lastWeaponPosY = LerpCubic(delta * 44, lastWeaponPosY, ys)
	lastWeaponPosZ = LerpCubic(delta * 44, lastWeaponPosZ, zs)

	if math.abs(changeX) > 100 or math.abs(changeY) > 100 or math.abs(changeY) > 100 then return end

	--lastWeaponPosX = xs
	--lastWeaponPosY = ys
	--lastWeaponPosZ = zs

	local M = ScreenSize(20) * SHIFTING_CLAMP_WEP:GetFloat():clamp(0, 10)
	Pos2.ShiftX_Weapon = math.Clamp(Pos2.ShiftX_Weapon + ((changeX / delta) - (changeY / delta)) * 0.3, -M, M)
	Pos2.ShiftY_Weapon = math.Clamp(Pos2.ShiftY_Weapon + ((changeZ / delta)) * 0.3, -M, M)
end

local lastThink = RealTimeL()

local function Think()
	local time = RealTimeL()
	local delta = time - lastThink
	lastThink = time
	if delta == 0 then return end
	UpdateShift(delta)
	UpdateWeaponShift(delta)
	UpdatePositions()
end

hook.Add('Think', 'HUDCommons.Pos2.PositionShift', Think)
