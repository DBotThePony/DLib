
--
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

local ENABLE_SHIFTING = CreateConVar('dlib_hud_shift', '1', {FCVAR_ARCHIVE}, 'Enable HUD shifting')
local ENABLE_SHIFTING_WEAPON = CreateConVar('dlib_hud_shift_wp', '1', {FCVAR_ARCHIVE}, 'Enable HUD shifting with weapons')
local ENABLE_SHIFTING_SV = CreateConVar('sv_dlib_hud_shift', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'SV Override: Enable HUD shifting')
local ENABLE_SHIFTING_SV_WEAPON = CreateConVar('sv_dlib_hud_shift_wp', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'SV Override: Enable HUD shifting with weapons')

local SHIFTING_CLAMP_DEF = CreateConVar('dlib_hud_shift_clamp', '1', {FCVAR_ARCHIVE}, 'Clamp of cam move affect for hud')
local SHIFTING_CLAMP_WEP = CreateConVar('dlib_hud_shift_wepclamp', '1', {FCVAR_ARCHIVE}, 'Clamp of weapon move affect for hud')

local SHIFTING_MULT_DEF = CreateConVar('dlib_hud_shift_mult', '1', {FCVAR_ARCHIVE}, 'Multiplier of cam move affect for hud')
local SHIFTING_MULT_WEP = CreateConVar('dlib_hud_shift_wepmult', '1', {FCVAR_ARCHIVE}, 'Multiplier of weapon move affect for hud')

local SHIFTING_AIR = CreateConVar('dlib_hud_shift_midair', '1', {FCVAR_ARCHIVE}, 'Shift hud while in midair')

local WEIGHTED = CreateConVar('dlib_hud_shift_weighted', '1', {FCVAR_ARCHIVE}, 'Shift of element is based on distance from screen center')

local HUDCommons = DLib.HUDCommons
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
local ScreenScale = ScreenScale
local ipairs = ipairs

HUDCommons.Position2 = HUDCommons.Position2 or {}
local Pos2 = HUDCommons.Position2

local ShiftX = 0

function Pos2.ShiftX()
	return ShiftX
end

local ShiftX_Ground = 0
local ShiftX_Weapon = 0
local ShiftY = 0
local ShiftY_Ground = 0
local ShiftY_Weapon = 0
local LastAngle = Angle(0, 0, 0)

Pos2.DefPositions = Pos2.DefPositions or {}
Pos2.XPositions_CVars = Pos2.XPositions_CVars or {}
Pos2.YPositions_CVars = Pos2.YPositions_CVars or {}
Pos2.XPositions_modified = Pos2.XPositions_modified or {}
Pos2.YPositions_modified = Pos2.YPositions_modified or {}
Pos2.XPositions_original = Pos2.XPositions_original or {}
Pos2.YPositions_original = Pos2.YPositions_original or {}

Pos2.XPositions_mul = Pos2.XPositions_mul or {}
Pos2.YPositions_mul = Pos2.YPositions_mul or {}

for _, v in ipairs(Pos2.DefPositions) do
	Pos2.XPositions_mul[v] = 1 - Pos2.XPositions_original[v]:progression(0, 1, 0.5) * 0.8
	Pos2.YPositions_mul[v] = 1 - Pos2.YPositions_original[v]:progression(0, 1, 0.5) * 0.8
end

Pos2.Positions_funcs = Pos2.Positions_funcs or {}

local DefPositions = Pos2.DefPositions
local XPositions_CVars = Pos2.XPositions_CVars
local YPositions_CVars = Pos2.YPositions_CVars
local XPositions_modified = Pos2.XPositions_modified
local YPositions_modified = Pos2.YPositions_modified
local XPositions_original = Pos2.XPositions_original
local YPositions_original = Pos2.YPositions_original
local XPositions_mul = Pos2.XPositions_mul
local YPositions_mul = Pos2.YPositions_mul
local Positions_funcs = Pos2.Positions_funcs

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

	XPositions_original[name] = cvarX:GetFloat():clamp(0, 1)
	YPositions_original[name] = cvarY:GetFloat():clamp(0, 1)

	XPositions_mul[name] = 1 - XPositions_original[name]:progression(0, 1, 0.5) * 0.8
	YPositions_mul[name] = 1 - YPositions_original[name]:progression(0, 1, 0.5) * 0.8

	XPositions_modified[name] = x * ScrWL()
	YPositions_modified[name] = y * ScrHL()

	cvars.AddChangeCallback('dlib_hpos_' .. name .. '_x', function()
		local old = XPositions_original[name]
		XPositions_original[name] = cvarX:GetFloat():clamp(0, 1)
		XPositions_mul[name] = 1 - XPositions_original[name]:progression(0, 1, 0.5) * 0.8
		hook.Run('HUDCommons_PositionSettingUpdatesX', name, old, XPositions_original[name])
		hook.Run('HUDCommons_PositionSettingUpdates', name, XPositions_original[name], YPositions_original[name])
	end, 'DLib.HUDCommons')

	cvars.AddChangeCallback('dlib_hpos_' .. name .. '_y', function()
		local old = YPositions_original[name]
		YPositions_original[name] = cvarY:GetFloat():clamp(0, 1)
		YPositions_mul[name] = 1 - YPositions_original[name]:progression(0, 1, 0.5) * 0.8
		hook.Run('HUDCommons_PositionSettingUpdatesY', name, old, YPositions_original[name])
		hook.Run('HUDCommons_PositionSettingUpdates', name, XPositions_original[name], YPositions_original[name])
	end, 'DLib.HUDCommons')

	XPositions_CVars[name] = cvarX
	YPositions_CVars[name] = cvarY

	if not table.qhasValue(DefPositions, name) then
		table.insert(DefPositions, name)
	end

	Positions_funcs[name] = shouldShift

	return function()
		if shouldShift() then
			return XPositions_modified[name], YPositions_modified[name]
		else
			return XPositions_original[name] * ScrWL(), YPositions_original[name] * ScrHL()
		end
	end, cvarX, cvarY, function()
		if XPositions_original[name] < 0.33 then
			return 'LEFT'
		elseif XPositions_original[name] > 0.66 then
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
	if XPositions_original[name] < 0.33 then
		return 'LEFT'
	elseif XPositions_original[name] > 0.66 then
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
	if XPositions_original[name] < 0.5 then
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
	if not Positions_funcs[elem] or Positions_funcs[elem]() then
		return XPositions_modified[elem] or 0, YPositions_modified[elem] or 0
	else
		return XPositions_original[elem] or 0, YPositions_original[elem] or 0
	end
end

Pos2.GetPosition = Pos2.GetPos

local function UpdatePositions()
	local w, h = ScrWL(), ScrHL()

	if ENABLE_SHIFTING:GetBool() and ENABLE_SHIFTING_SV:GetBool() then
		if WEIGHTED:GetBool() then
			for i = 1, #DefPositions do
				local v = DefPositions[i]
				XPositions_modified[v] = XPositions_original[v] * w + (ShiftX + ShiftX_Weapon + ShiftX_Ground) * XPositions_mul[v]
				YPositions_modified[v] = YPositions_original[v] * h + (ShiftY + ShiftY_Weapon + ShiftY_Ground) * YPositions_mul[v]
			end
		else
			for i = 1, #DefPositions do
				local v = DefPositions[i]
				XPositions_modified[v] = XPositions_original[v] * w + ShiftX + ShiftX_Weapon + ShiftX_Ground
				YPositions_modified[v] = YPositions_original[v] * h + ShiftY + ShiftY_Weapon + ShiftY_Ground
			end
		end
	else
		for i = 1, #DefPositions do
			local v = DefPositions[i]
			XPositions_modified[v] = XPositions_original[v] * w
			YPositions_modified[v] = YPositions_original[v] * h
		end
	end
end

local LastOnGround = false
local LastOnGroundIdle = 0
local MOVETYPE_WALK = MOVETYPE_WALK

local math_clamp = math.clamp
local math_sin = math.sin
local math_min = math.min
local math_max = math.max
local math_progression = math.progression

local function UpdateShift(delta)
	if not ENABLE_SHIFTING:GetBool() or not ENABLE_SHIFTING_SV:GetBool() then return end

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

	local M1, M2 = ScreenScale(math_clamp(SHIFTING_CLAMP_DEF:GetFloat(), 0, 10)), ScreenSize(math_clamp(SHIFTING_CLAMP_DEF:GetFloat(), 0, 10))
	local rtime = RealTimeL()

	if LastOnGround ~= ground then
		LastOnGround = ground

		if ground then
			ShiftX_Ground = 0
			ShiftY_Ground = -M1 * 4
		else
			LastOnGroundIdle = rtime + 0.7
		end
	end

	if not ground and LastOnGroundIdle < rtime and SHIFTING_AIR:GetBool() then
		local anim = (rtime % math.pi) * (1 + math_progression(rtime, LastOnGroundIdle, LastOnGroundIdle + 4)) * 5
		ShiftX_Ground = math_sin(anim) * math_min(rtime - LastOnGroundIdle + 1, 8) * ScreenSize(8)
		ShiftY_Ground = ShiftY_Ground + M1 * delta * 5
	end

	local changePitch = math.AngleDifference(ang.p, LastAngle.p)
	local changeYaw = math.AngleDifference(ang.y, LastAngle.y)

	LastAngle = LerpAngle(delta * 22, LastAngle, ang)
	ShiftX = math_clamp(ShiftX + changeYaw * 1.8, -M2, M2)
	ShiftX_Ground = math_clamp(ShiftX_Ground, -M2 * 2, M2 * 2)
	ShiftY = math_clamp(ShiftY - changePitch * 1.8, -M1, M1)
	ShiftY_Ground = math_clamp(ShiftY_Ground, -M1 * 1.5, M1 * 3)

	local oldX, oldY = ShiftX, ShiftY

	ShiftX = ShiftX - ShiftX * delta * 11 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)
	ShiftY = ShiftY - ShiftY * delta * 11 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)
	ShiftY_Ground = ShiftY_Ground - ShiftY_Ground * delta * 4 * SHIFTING_MULT_DEF:GetFloat():clamp(0, 10)

	if oldX > 0 and ShiftX < 0 or oldX < 0 and ShiftX > 0 then
		ShiftX = 0
	end

	if oldY > 0 and ShiftY < 0 or oldY < 0 and ShiftY > 0 then
		ShiftY = 0
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

local Weapon_PosX_Change = 0
local Weapon_PosY_Change = 0
local Weapon_PosZ_Change = 0

local Weapon_PosX_ChangeLerp = 0
local Weapon_PosY_ChangeLerp = 0
local Weapon_PosZ_ChangeLerp = 0

local math_abs = math.abs

local function grabShiftOfEntity(plyPos, plyAng, view)
	local xs, ys, zs = 0, 0, 0
	local viewt = view:GetTable()
	local private = viewt.__dlib_position2

	if not private then
		private = {
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

		viewt.__dlib_position2 = private
	end

	local bonesX, bonesY, bonesZ = private.bonesX, private.bonesY, private.bonesZ
	local multX, multY, multZ = private.multX, private.multY, private.multZ

	local rft = RealFrameTime()

	local bones = view:GetBoneCount()

	for bone = 0, bones - 1 do
		-- this is damn slow
		local bpos, bang = view:GetBonePosition(bone)

		bang:Add(view:GetManipulateBoneAngles(bone))
		bpos:Add(view:GetManipulateBonePosition(bone))

		local npos = WorldToLocal(bpos, bang, plyPos, plyAng)
		local vX, vY, vZ = npos.x, npos.y, npos.z

		bonesX[bone + 1] = bonesX[bone + 1] or vX
		bonesY[bone + 1] = bonesY[bone + 1] or vY
		bonesZ[bone + 1] = bonesZ[bone + 1] or vZ

		local diffX, diffY, diffZ = math_abs(vX - bonesX[bone + 1]), math_abs(vY - bonesY[bone + 1]), math_abs(vZ - bonesZ[bone + 1])

		multX = math_max(Lerp(rft, multX, diffX), 0.1)
		multY = math_max(Lerp(rft, multY, diffY), 0.1)
		multZ = math_max(Lerp(rft, multZ, diffZ), 0.1)

		xs = xs + vX / multX
		ys = ys + vY / multY
		zs = zs + vZ / multZ

		bonesX[bone + 1] = vX
		bonesY[bone + 1] = vY
		bonesZ[bone + 1] = vZ
	end

	private.multX, private.multY, private.multZ = multX, multY, multZ

	private.weighedXLast = private.weighedXLast or xs
	private.weighedYLast = private.weighedYLast or ys
	private.weighedZLast = private.weighedZLast or zs

	local diffX, diffY, diffZ = math_abs(xs - private.weighedXLast), math_abs(ys - private.weighedYLast), math_abs(zs - private.weighedZLast)

	private.weighedX = math_max(Lerp(rft, private.weighedX, diffX), 0.1)
	private.weighedY = math_max(Lerp(rft, private.weighedY, diffY), 0.1)
	private.weighedZ = math_max(Lerp(rft, private.weighedZ, diffZ), 0.1)

	xs = xs / private.weighedX
	ys = ys / private.weighedY
	zs = zs / private.weighedZ

	private.weighedXLast = xs
	private.weighedYLast = ys
	private.weighedZLast = zs

	return bones, xs, ys, zs
end

local function UpdateWeaponShift(delta)
	if not ENABLE_SHIFTING:GetBool() or not ENABLE_SHIFTING_WEAPON:GetBool() then return end
	if not ENABLE_SHIFTING_SV:GetBool() or not ENABLE_SHIFTING_SV_WEAPON:GetBool() then return end

	ShiftX_Weapon = Lerp(delta * 7, ShiftX_Weapon, 0)
	ShiftY_Weapon = Lerp(delta * 7, ShiftY_Weapon, 0)

	Weapon_PosX_ChangeLerp = Lerp(delta, Weapon_PosX_ChangeLerp, 0)
	Weapon_PosY_ChangeLerp = Lerp(delta, Weapon_PosY_ChangeLerp, 0)
	Weapon_PosZ_ChangeLerp = Lerp(delta, Weapon_PosZ_ChangeLerp, 0)

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
	local div = ScreenSize(math_clamp(SHIFTING_MULT_WEP:GetFloat(), 0, 10))

	amount = amount / 12
	xs, ys, zs = xs / amount, ys / amount, zs / amount
	local changeX = (xs - lastWeaponPosX) * div
	local changeY = (ys - lastWeaponPosY) * div
	local changeZ = (zs - lastWeaponPosZ) * div
	local nancheck = changeX ~= changeX or changeY ~= changeY or changeZ ~= changeZ

	if not nancheck then
		Weapon_PosX_Change = changeX
		Weapon_PosY_Change = changeY
		Weapon_PosZ_Change = changeZ

		lastChangeX = Lerp(delta * 11, lastChangeX, changeX)
		lastChangeY = Lerp(delta * 11, lastChangeY, changeY)
		lastChangeZ = Lerp(delta * 11, lastChangeZ, changeZ)
		lastWeaponPosX = Lerp(delta * 44, lastWeaponPosX, xs)
		lastWeaponPosY = Lerp(delta * 44, lastWeaponPosY, ys)
		lastWeaponPosZ = Lerp(delta * 44, lastWeaponPosZ, zs)

		Weapon_PosX_ChangeLerp = Lerp(delta * 22, Weapon_PosX_ChangeLerp, changeX)
		Weapon_PosY_ChangeLerp = Lerp(delta * 22, Weapon_PosY_ChangeLerp, changeY)
		Weapon_PosZ_ChangeLerp = Lerp(delta * 22, Weapon_PosZ_ChangeLerp, changeZ)

		if math_abs(changeX) > 100 or math_abs(changeY) > 100 or math_abs(changeY) > 100 then return end

		--lastWeaponPosX = xs
		--lastWeaponPosY = ys
		--lastWeaponPosZ = zs

		local M = ScreenSize(math_abs(SHIFTING_CLAMP_WEP:GetFloat(), 0, 10))
		ShiftX_Weapon = math.Clamp(ShiftX_Weapon + ((lastChangeX / delta) - (lastChangeY / delta)) * 0.3, -M, M)
		ShiftY_Weapon = math.Clamp(ShiftY_Weapon + ((lastChangeZ / delta)) * 0.3, -M, M)
	else
		DLib.Message('Invalid position of weapon viewmodel: ', changeX, ' ', changeY, ' ', changeZ, ' of ', ply:GetViewModel(), ' ', ply:GetHands())

		Weapon_PosX_Change = 0
		Weapon_PosY_Change = 0
		Weapon_PosZ_Change = 0

		lastWeaponPosX, lastWeaponPosY, lastWeaponPosZ = 0, 0, 0
		lastChangeX, lastChangeY, lastChangeZ = 0, 0, 0

		ShiftX_Weapon = 0
		ShiftY_Weapon = 0

		Weapon_PosX_ChangeLerp = 0
		Weapon_PosY_ChangeLerp = 0
		Weapon_PosZ_ChangeLerp = 0
	end
end

local lastThink = RealTimeL()

local function Think()
	local time = RealTimeL()
	local delta = time - lastThink
	lastThink = time
	if delta == 0 then return end
	if #DefPositions == 0 then return end

	UpdateShift(delta)
	UpdateWeaponShift(delta)
	UpdatePositions()
end

hook.Add('Think', 'HUDCommons.Pos2.PositionShift', Think)
