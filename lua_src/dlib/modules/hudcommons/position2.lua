
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
local ENABLE_SHIFTING_SV = CreateConVar('sv_dlib_hud_shift', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'SV Override: Enable HUD shifting')
local HUDCommons = HUDCommons
local table = table
local math = math

HUDCommons.Position2 = HUDCommons.Position2 or {}
local Pos2 = HUDCommons.Position2

Pos2.ShiftX = 0
Pos2.ShiftY = 0
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

	if x < 1 then
		x = ScrW() * x
	end

	if y < 1 then
		y = ScrH() * y
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
	if ENABLE_SHIFTING:GetBool() and ENABLE_SHIFTING_SV:GetBool() then
		for k, v in pairs(Pos2.XPositions) do
			Pos2.XPositions_modified[v] = Pos2.XPositions_original[v] + Pos2.ShiftX
		end

		for k, v in pairs(Pos2.YPositions) do
			Pos2.YPositions_modified[v] = Pos2.YPositions_original[v] + Pos2.ShiftY
		end
	else
		for k, v in pairs(Pos2.XPositions) do
			Pos2.XPositions_modified[v] = Pos2.XPositions_original[v]
		end

		for k, v in pairs(Pos2.YPositions) do
			Pos2.YPositions_modified[v] = Pos2.YPositions_original[v]
		end
	end
end

local function UpdateShift()
	if not ENABLE_SHIFTING:GetBool() then return end
	if not ENABLE_SHIFTING_SV:GetBool() then return end

	local ply = HUDCommons.SelectPlayer()
	local ang = ply:EyeAngles()

	local changePitch = math.AngleDifference(ang.p, Pos2.LastAngle.p)
	local changeYaw = math.AngleDifference(ang.y, Pos2.LastAngle.y)

	Pos2.LastAngle = LerpAngle(FrameTime() * 33, Pos2.LastAngle, ang)

	Pos2.ShiftX = math.Clamp(Pos2.ShiftX + changeYaw * 1.8, -30, 30)
	Pos2.ShiftY = math.Clamp(Pos2.ShiftY - changePitch * 1.8, -20, 20)

	local oldX, oldY = Pos2.ShiftX, Pos2.ShiftY

	Pos2.ShiftX = Pos2.ShiftX - Pos2.ShiftX * FrameTime() * 22
	Pos2.ShiftY = Pos2.ShiftY - Pos2.ShiftY * FrameTime() * 22

	if oldX > 0 and Pos2.ShiftX < 0 or oldX < 0 and Pos2.ShiftX > 0 then
		Pos2.ShiftX = 0
	end

	if oldY > 0 and Pos2.ShiftY < 0 or oldY < 0 and Pos2.ShiftY > 0 then
		Pos2.ShiftY = 0
	end
end

local function Think()
	UpdateShift()
	UpdatePositions()
end

hook.Add('Think', 'HUDCommons.Pos2.PositionShift', Think)
