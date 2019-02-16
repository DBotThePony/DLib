
--
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
local ScrWL = ScrWL
local ScrHL = ScrHL
local ipairs = ipairs

HUDCommons.Position2 = HUDCommons.Position2 or {}
local Pos2 = HUDCommons.Position2

Pos2.ShiftX = 0
Pos2.ShiftX_Ground = 0
Pos2.ShiftX_Weapon = 0
Pos2.ShiftY = 0
Pos2.ShiftY_Ground = 0
Pos2.ShiftY_Weapon = 0
Pos2.LastAngle = Angle(0, 0, 0)

Pos2.XPositions = Pos2.XPositions or {}
Pos2.YPositions = Pos2.YPositions or {}
Pos2.XPositions_CVars = Pos2.XPositions_CVars or {}
Pos2.YPositions_CVars = Pos2.YPositions_CVars or {}
Pos2.XPositions_modified = Pos2.XPositions_modified or {}
Pos2.YPositions_modified = Pos2.YPositions_modified or {}
Pos2.XPositions_original = Pos2.XPositions_original or {}
Pos2.YPositions_original = Pos2.YPositions_original or {}
Pos2.Positions_funcs = Pos2.Positions_funcs or {}

--[[
	@doc
	@fname DLib.HUDCommons.Position2.DefinePosition
	@args string name, number x, number y, function shouldShiftPredicate = nil

	@client

	@desc
	`x` and `y` must be a float in 0 to 1 range inclusive (element position will be based on screen resolution)
	`shouldShiftPredicate` is a function which should return boolean
	if `shouldShiftPredicate` is omitted, predicate check is always successful

	Use `HUDCommonsBase:DefinePosition` instead of this if you are making a HUD on HUDCommonsBase!
	@enddesc

	@returns
	funcion: returns `x, y` of element
	ConVar: x position defined by user (float)
	ConVar: y position defined by user (float)
	function: returns screen side of element (`"LEFT"`, `"RIGHT"` or `"CENTER"`)
]]
function Pos2.DefinePosition(name, x, y, shouldShift)
	if shouldShift ~= nil then
		if type(shouldShift) ~= 'function' then
			local l = shouldShift
			shouldShift = function() return l end
		end
	else
		shouldShift = function() return true end
	end

	if x > 1 or x < 0 then
		error('Invalid position! DefinePosition can only receive 0 <= x <= 1')
	end

	if y > 1 or y < 0 then
		error('Invalid position! DefinePosition can only receive 0 <= y <= 1')
	end

	local cvarX = CreateConVar('dlib_hpos_' .. name .. '_x', tostring(x), {FCVAR_ARCHIVE}, 'X position of corresponding HUD element')
	local cvarY = CreateConVar('dlib_hpos_' .. name .. '_y', tostring(y), {FCVAR_ARCHIVE}, 'X position of corresponding HUD element')

	Pos2.XPositions_original[name] = cvarX:GetFloat():clamp(0, 1)
	Pos2.YPositions_original[name] = cvarY:GetFloat():clamp(0, 1)

	Pos2.XPositions_modified[name] = x * ScrWL()
	Pos2.YPositions_modified[name] = y * ScrHL()

	cvars.AddChangeCallback('dlib_hpos_' .. name .. '_x', function()
		Pos2.XPositions_original[name] = cvarX:GetFloat():clamp(0, 1)
	end, 'DLib.HUDCommons')

	cvars.AddChangeCallback('dlib_hpos_' .. name .. '_y', function()
		Pos2.YPositions_original[name] = cvarY:GetFloat():clamp(0, 1)
	end, 'DLib.HUDCommons')

	Pos2.XPositions_CVars[name] = cvarX
	Pos2.YPositions_CVars[name] = cvarY

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
			return Pos2.XPositions_original[name] * ScrWL(), Pos2.YPositions_original[name] * ScrHL()
		end
	end, cvarX, cvarY, function()
		if Pos2.XPositions_original[name] < 0.33 then
			return 'LEFT'
		elseif Pos2.XPositions_original[name] > 0.66 then
			return 'RIGHT'
		else
			return 'CENTER'
		end
	end
end

--[[
	@doc
	@fname DLib.HUDCommons.Position2.GetSide
	@args string name

	@client

	@returns
	string: `"LEFT"`, `"RIGHT"` or `"CENTER"`
]]
function Pos2.GetSide(name)
	if Pos2.XPositions_original[name] < 0.33 then
		return 'LEFT'
	elseif Pos2.XPositions_original[name] > 0.66 then
		return 'RIGHT'
	else
		return 'CENTER'
	end
end

--[[
	@doc
	@fname DLib.HUDCommons.Position2.GetSideStrict
	@args string name

	@client

	@returns
	string: `"LEFT"` or `"RIGHT"`
]]
function Pos2.GetSideStrict(name)
	if Pos2.XPositions_original[name] < 0.5 then
		return 'LEFT'
	else
		return 'RIGHT'
	end
end

Pos2.CreatePosition = Pos2.DefinePosition

--[[
	@doc
	@fname DLib.HUDCommons.Position2.GetPos
	@args string name

	@client

	@returns
	number: x
	number: y
]]
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
			Pos2.XPositions_modified[v] = Pos2.XPositions_original[v] * w + Pos2.ShiftX + Pos2.ShiftX_Weapon + Pos2.ShiftX_Ground
		end

		for k, v in ipairs(Pos2.YPositions) do
			Pos2.YPositions_modified[v] = Pos2.YPositions_original[v] * h + Pos2.ShiftY + Pos2.ShiftY_Weapon + Pos2.ShiftY_Ground
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

local LastOnGround = false
local LastOnGroundIdle = 0
local MOVETYPE_WALK = MOVETYPE_WALK

local function UpdateShift(delta)
	if not ENABLE_SHIFTING:GetBool() then return end
	if not ENABLE_SHIFTING_SV:GetBool() then return end

	local ply = HUDCommons.SelectPlayer()
	local ang = ply:EyeAngles()
	local ground = ply:IsOnGround()
	local mvtype = ply:GetMoveType()

	if mvtype ~= MOVETYPE_WALK then
		ground = true
	end

	if ply:WaterLevel() ~= 0 then
		ground = true
	end

	local M1, M2 = ScreenSize(20) * SHIFTING_CLAMP_DEF:GetFloat():clamp(0, 10), ScreenSize(30) * SHIFTING_CLAMP_DEF:GetFloat():clamp(0, 10)

	if LastOnGround ~= ground then
		LastOnGround = ground

		if ground then
			Pos2.ShiftX_Ground = 0
			Pos2.ShiftY_Ground = -M1 * 4
		else
			LastOnGroundIdle = RealTimeL() + 0.7
		end
	end

	if not ground and LastOnGroundIdle < RealTimeL() then
		local anim = (RealTimeL() % math.pi) * (1 + RealTimeL():progression(LastOnGroundIdle, LastOnGroundIdle + 4)) * 5
		Pos2.ShiftX_Ground = anim:sin() * (RealTimeL() - LastOnGroundIdle + 1):min(8) * ScreenSize(8)
		Pos2.ShiftY_Ground = Pos2.ShiftY_Ground + M1 * delta * 5
	end

	local changePitch = math.AngleDifference(ang.p, Pos2.LastAngle.p)
	local changeYaw = math.AngleDifference(ang.y, Pos2.LastAngle.y)

	Pos2.LastAngle = LerpAngle(delta * 22, Pos2.LastAngle, ang)
	Pos2.ShiftX = math.clamp(Pos2.ShiftX + changeYaw * 1.8, -M2, M2)
	Pos2.ShiftX_Ground = math.clamp(Pos2.ShiftX_Ground, -M2 * 2, M2 * 2)
	Pos2.ShiftY = math.clamp(Pos2.ShiftY - changePitch * 1.8, -M1, M1)
	Pos2.ShiftY_Ground = math.clamp(Pos2.ShiftY_Ground, -M1 * 1.5, M1 * 3)

	local oldX, oldY = Pos2.ShiftX, Pos2.ShiftY

	Pos2.ShiftX = Pos2.ShiftX - Pos2.ShiftX * delta * 11 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)
	Pos2.ShiftY = Pos2.ShiftY - Pos2.ShiftY * delta * 11 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)
	Pos2.ShiftY_Ground = Pos2.ShiftY_Ground - Pos2.ShiftY_Ground * delta * 4 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)

	if oldX > 0 and Pos2.ShiftX < 0 or oldX < 0 and Pos2.ShiftX > 0 then
		Pos2.ShiftX = 0
	end

	if oldY > 0 and Pos2.ShiftY < 0 or oldY < 0 and Pos2.ShiftY > 0 then
		Pos2.ShiftY = 0
	end
end

local lastWeaponPosX, lastWeaponPosY, lastWeaponPosZ = 0, 0, 0
local lastChangeX, lastChangeY, lastChangeZ = 0, 0, 0
local lastWeapon = NULL
local WorldToLocal = WorldToLocal
local IsValid = FindMetaTable('Entity').IsValid
local Lerp = Lerp
local LerpQuintic = LerpQuintic
local RealFrameTime = RealFrameTime

Pos2.Weapon_PosX_Change = 0
Pos2.Weapon_PosY_Change = 0
Pos2.Weapon_PosZ_Change = 0

Pos2.Weapon_PosX_ChangeLerp = 0
Pos2.Weapon_PosY_ChangeLerp = 0
Pos2.Weapon_PosZ_ChangeLerp = 0

local function grabShiftOfEntity(plyPos, plyAng, view)
	local xs, ys, zs = 0, 0, 0
	local viewt = view:GetTable()

	if not viewt.__dlib_position2 then
		viewt.__dlib_position2 = {
			multX = 0.25,
			multY = 0.25,
			multZ = 0.25,
			bonesX = {},
			bonesY = {},
			bonesZ = {},

			weighedXLast = 0,
			weighedX = 0.25,
			weighedY = 0.25,
			weighedYLast = 0,
			weighedZ = 0.25,
			weighedZLast = 0,
		}
	end

	local private = viewt.__dlib_position2
	local rft = RealFrameTime()

	local bones = view:GetBoneCount()

	for bone = 0, bones - 1 do
		local bpos, bang = view:GetBonePosition(bone)
		bang = bang + view:GetManipulateBoneAngles(bone)
		bpos = bpos + view:GetManipulateBonePosition(bone)
		local npos, nang = WorldToLocal(bpos, bang, plyPos, plyAng)
		private.bonesX[bone + 1] = private.bonesX[bone + 1] or npos.x
		private.bonesY[bone + 1] = private.bonesY[bone + 1] or npos.y
		private.bonesZ[bone + 1] = private.bonesZ[bone + 1] or npos.z

		local diffX, diffY, diffZ = (npos.x - private.bonesX[bone + 1]):abs(), (npos.y - private.bonesY[bone + 1]):abs(), (npos.z - private.bonesZ[bone + 1]):abs()

		private.multX = math.max(Lerp(rft, private.multX, diffX), 0.1)
		private.multY = math.max(Lerp(rft, private.multY, diffY), 0.1)
		private.multZ = math.max(Lerp(rft, private.multZ, diffZ), 0.1)

		xs = xs + npos.x / private.multX
		ys = ys + npos.y / private.multY
		zs = zs + npos.z / private.multZ

		private.bonesX[bone + 1] = npos.x
		private.bonesY[bone + 1] = npos.y
		private.bonesZ[bone + 1] = npos.z
	end

	private.weighedXLast = private.weighedXLast or xs
	private.weighedYLast = private.weighedYLast or ys
	private.weighedZLast = private.weighedZLast or zs

	local diffX, diffY, diffZ = (xs - private.weighedXLast):abs(), (ys - private.weighedYLast):abs(), (zs - private.weighedZLast):abs()

	private.weighedX = math.max(Lerp(rft, private.weighedX, diffX), 0.1)
	private.weighedY = math.max(Lerp(rft, private.weighedY, diffY), 0.1)
	private.weighedZ = math.max(Lerp(rft, private.weighedZ, diffZ), 0.1)

	xs = xs / private.weighedX
	ys = ys / private.weighedY
	zs = zs / private.weighedZ

	private.weighedXLast = xs
	private.weighedYLast = ys
	private.weighedZLast = zs
	return bones, xs, ys, zs
end

local function UpdateWeaponShift(delta)
	if not ENABLE_SHIFTING:GetBool() then return end
	if not ENABLE_SHIFTING_WEAPON:GetBool() then return end
	if not ENABLE_SHIFTING_SV:GetBool() then return end
	if not ENABLE_SHIFTING_SV_WEAPON:GetBool() then return end

	Pos2.ShiftX_Weapon = Lerp(delta * 7, Pos2.ShiftX_Weapon, 0)
	Pos2.ShiftY_Weapon = Lerp(delta * 7, Pos2.ShiftY_Weapon, 0)

	Pos2.Weapon_PosX_ChangeLerp = Lerp(delta, Pos2.Weapon_PosX_ChangeLerp, 0)
	Pos2.Weapon_PosY_ChangeLerp = Lerp(delta, Pos2.Weapon_PosY_ChangeLerp, 0)
	Pos2.Weapon_PosZ_ChangeLerp = Lerp(delta, Pos2.Weapon_PosZ_ChangeLerp, 0)

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
			local bones, xs2, ys2, zs2 = grabShiftOfEntity(plyPos, plyAng, view)
			amount = amount + bones
			xs = xs + xs2
			ys = ys + ys2
			zs = zs + zs2
		end
	end

	if ply.GetHands then
		local hands = ply:GetHands()

		if IsValid(hands) then
			local bones, xs2, ys2, zs2 = grabShiftOfEntity(plyPos, plyAng, hands)
			amount = amount + bones
			xs = xs + xs2
			ys = ys + ys2
			zs = zs + zs2
		end
	end

	if amount <= 2 then return end
	local div = ScreenSize(1) * SHIFTING_MULT_WEP:GetFloat():clamp(0, 10)

	amount = amount / 12
	xs, ys, zs = xs / amount, ys / amount, zs / amount
	local changeX = (xs - lastWeaponPosX) * div
	local changeY = (ys - lastWeaponPosY) * div
	local changeZ = (zs - lastWeaponPosZ) * div
	local nancheck = changeX ~= changeX or changeY ~= changeY or changeZ ~= changeZ

	Pos2.Weapon_PosX_Change = changeX
	Pos2.Weapon_PosY_Change = changeY
	Pos2.Weapon_PosZ_Change = changeZ

	if not nancheck then
		lastChangeX = Lerp(delta * 11, lastChangeX, changeX)
		lastChangeY = Lerp(delta * 11, lastChangeY, changeY)
		lastChangeZ = Lerp(delta * 11, lastChangeZ, changeZ)
		lastWeaponPosX = Lerp(delta * 44, lastWeaponPosX, xs)
		lastWeaponPosY = Lerp(delta * 44, lastWeaponPosY, ys)
		lastWeaponPosZ = Lerp(delta * 44, lastWeaponPosZ, zs)

		Pos2.Weapon_PosX_ChangeLerp = Lerp(delta * 22, Pos2.Weapon_PosX_ChangeLerp, changeX)
		Pos2.Weapon_PosY_ChangeLerp = Lerp(delta * 22, Pos2.Weapon_PosY_ChangeLerp, changeY)
		Pos2.Weapon_PosZ_ChangeLerp = Lerp(delta * 22, Pos2.Weapon_PosZ_ChangeLerp, changeZ)

		if math.abs(changeX) > 100 or math.abs(changeY) > 100 or math.abs(changeY) > 100 then return end

		--lastWeaponPosX = xs
		--lastWeaponPosY = ys
		--lastWeaponPosZ = zs

		local M = ScreenSize(20) * SHIFTING_CLAMP_WEP:GetFloat():clamp(0, 10)
		Pos2.ShiftX_Weapon = math.Clamp(Pos2.ShiftX_Weapon + ((lastChangeX / delta) - (lastChangeY / delta)) * 0.3, -M, M)
		Pos2.ShiftY_Weapon = math.Clamp(Pos2.ShiftY_Weapon + ((lastChangeZ / delta)) * 0.3, -M, M)
	else
		if DLib.DEBUG_MODE:GetBool() then
			DLib.Message('Invalid position of weapon viewmodel')
		end

		Pos2.Weapon_PosX_Change = 0
		Pos2.Weapon_PosY_Change = 0
		Pos2.Weapon_PosZ_Change = 0

		lastWeaponPosX, lastWeaponPosY, lastWeaponPosZ = 0, 0, 0
		lastChangeX, lastChangeY, lastChangeZ = 0, 0, 0

		Pos2.ShiftX_Weapon = 0
		Pos2.ShiftY_Weapon = 0

		Pos2.Weapon_PosX_ChangeLerp = 0
		Pos2.Weapon_PosY_ChangeLerp = 0
		Pos2.Weapon_PosZ_ChangeLerp = 0
	end
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
