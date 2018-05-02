
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

local HUDCommons = HUDCommons
local RealTimeL = RealTimeL
local hook = hook
local ipairs = ipairs
local ScrWL = ScrWL
local ScrHL = ScrHL

HUDCommons.A3D = HUDCommons.A3D or {}
local A3D = HUDCommons.A3D

local ENABLE_A3D = CreateConVar('dlib_a3d', '1', {FCVAR_ARCHIVE}, 'Enable A3D Features. Fancy shit, but it affect performance very heavily.')

A3D.XPositions = A3D.XPositions or {}
A3D.YPositions = A3D.YPositions or {}
A3D.XPositions_modified = A3D.XPositions_modified or {}
A3D.YPositions_modified = A3D.YPositions_modified or {}
A3D.XPositions_original = A3D.XPositions_original or {}
A3D.YPositions_original = A3D.YPositions_original or {}

local UpdatePositions

function A3D.DefinePosition(name, x, y)
	if x > 1 or x < 0 then
		error('Invalid position! DefinePosition can only receive 0 <= x <= 1')
	end

	if y > 1 or y < 0 then
		error('Invalid position! DefinePosition can only receive 0 <= y <= 1')
	end

	local DEFINED_AS_POS = HUDCommons.Position2.DefinePosition(name, x, y)

	A3D.XPositions_original[name] = x
	A3D.YPositions_original[name] = y

	A3D.XPositions_modified[name] = x
	A3D.YPositions_modified[name] = y

	if not table.HasValue(A3D.XPositions, name) then
		table.insert(A3D.XPositions, name)
	end

	if not table.HasValue(A3D.YPositions, name) then
		table.insert(A3D.YPositions, name)
	end

	UpdatePositions()

	return function()
		if ENABLE_A3D:GetBool() then
			return A3D.XPositions_modified[name], A3D.YPositions_modified[name]
		else
			return DEFINED_AS_POS()
		end
	end
end

function UpdatePositions()
	local w, h = ScrWL(), ScrHL()

	for k, v in ipairs(A3D.XPositions) do
		A3D.XPositions_modified[v] = A3D.XPositions_original[v] * w
	end

	for k, v in ipairs(A3D.YPositions) do
		A3D.YPositions_modified[v] = A3D.YPositions_original[v] * h
	end
end

local RENDER_TARGET_LEFT, RENDER_TARGET_RIGHT, RENDER_TARGET_CENTER, RENDER_TARGET
local render = render
local cam = cam
local Vector = Vector
local Angle = Angle
local MATERIAL_SIDE_LEFT, MATERIAL_SIDE_RIGHT, MATERIAL_SIDE_CENTER, MATERIAL_REDRAW

local CENTER_POSITION = Vector(640, 0, 0)

local function ScreenResolutionChanged()
	if not MATERIAL_SIDE_LEFT then
		MATERIAL_SIDE_LEFT = CreateMaterial('dlib_hudcommons_a3d_rtl_mat', 'UnlitGeneric', {
			['$basetexture'] = 'models/debug/debugwhite',
			['$translucent'] = '1',
			['$halflambert'] = '1',
			['$color'] = '[1 1 1]',
			['$color2'] = '[1 1 1]',
			['$alpha'] = '1',
			['$additive'] = '0',
		})

		MATERIAL_SIDE_RIGHT = CreateMaterial('dlib_hudcommons_a3d_rtr_mat', 'UnlitGeneric', {
			['$basetexture'] = 'models/debug/debugwhite',
			['$translucent'] = '1',
			['$halflambert'] = '1',
			['$color'] = '[1 1 1]',
			['$color2'] = '[1 1 1]',
			['$alpha'] = '1',
			['$additive'] = '0',
		})

		MATERIAL_SIDE_CENTER = CreateMaterial('dlib_hudcommons_a3d_rtc_mat', 'UnlitGeneric', {
			['$basetexture'] = 'models/debug/debugwhite',
			['$translucent'] = '1',
			['$halflambert'] = '1',
			['$color'] = '[1 1 1]',
			['$color2'] = '[1 1 1]',
			['$alpha'] = '1',
			['$additive'] = '0',
		})

		MATERIAL_REDRAW = CreateMaterial('dlib_hudcommons_a3d_rt_mat', 'UnlitGeneric', {
			['$basetexture'] = 'models/debug/debugwhite',
			['$translucent'] = '1',
			['$halflambert'] = '1',
			['$color'] = '[1 1 1]',
			['$color2'] = '[1 1 1]',
			['$alpha'] = '1',
			['$additive'] = '0',
		})
	end

	RENDER_TARGET_LEFT = GetRenderTarget('dlib_hudcommons_a3d_rtl_' .. ScrWL() .. '_' .. ScrHL(), ScrWL(), ScrHL(), false)
	RENDER_TARGET_RIGHT = GetRenderTarget('dlib_hudcommons_a3d_rtr_' .. ScrWL() .. '_' .. ScrHL(), ScrWL(), ScrHL(), false)
	RENDER_TARGET_CENTER = GetRenderTarget('dlib_hudcommons_a3d_rtc_' .. ScrWL() .. '_' .. ScrHL(), ScrWL(), ScrHL(), false)
	RENDER_TARGET = GetRenderTarget('dlib_hudcommons_a3d_rt_' .. ScrWL() .. '_' .. ScrHL(), ScrWL(), ScrHL(), false)

	MATERIAL_SIDE_LEFT:SetTexture('$basetexture', RENDER_TARGET_LEFT)
	MATERIAL_SIDE_RIGHT:SetTexture('$basetexture', RENDER_TARGET_RIGHT)
	MATERIAL_SIDE_CENTER:SetTexture('$basetexture', RENDER_TARGET_CENTER)
	MATERIAL_REDRAW:SetTexture('$basetexture', RENDER_TARGET)

	UpdatePositions()

	CENTER_POSITION = Vector(ScrWL() / 2.775)
end

timer.Simple(0, ScreenResolutionChanged)

local POSITION = Vector()
local ANGLE = Angle(0, 0, 0)
-- 90 is high
local FOV = 70
local color_white = Color()

local CENTER_NORMAL = Vector(-1, 0, 0)

local function HUDPaint()
	if not ENABLE_A3D:GetBool() then
		hook.Run('HUDCommons_3DRenderLeft', w, h, false)
		hook.Run('HUDCommons_3DRenderCenter', w, h, false)
		hook.Run('HUDCommons_3DRenderRight', w, h, false)
		return
	end

	local left, right, center = hook.HasHooks('HUDCommons_3DRenderLeft'), hook.HasHooks('HUDCommons_3DRenderRight'), hook.HasHooks('HUDCommons_3DRenderCenter')
	if not left and not right and not center then return end
	local w, h = ScrWL(), ScrHL()

	if left then
		-- render left side
		render.PushRenderTarget(RENDER_TARGET_LEFT)
		render.Clear(0, 0, 0, 0, false, false)
		cam.Start2D()

		hook.Run('HUDCommons_3DRenderLeft', w, h, RENDER_TARGET_LEFT)

		cam.End2D()
		render.PopRenderTarget()
	end

	if center then
		-- render center
		render.PushRenderTarget(RENDER_TARGET_CENTER)
		render.Clear(0, 0, 0, 0, false, false)
		cam.Start2D()

		hook.Run('HUDCommons_3DRenderCenter', w, h, RENDER_TARGET_CENTER)

		cam.End2D()
		render.PopRenderTarget()
	end

	if right then
		-- render right side
		render.PushRenderTarget(RENDER_TARGET_RIGHT)
		render.Clear(0, 0, 0, 0, false, false)
		cam.Start2D()

		hook.Run('HUDCommons_3DRenderRight', w, h, RENDER_TARGET_RIGHT)

		cam.End2D()
		render.PopRenderTarget()
	end

	local weaponShift = Vector(HUDCommons.Position2.Weapon_PosX_ChangeLerp * 80, HUDCommons.Position2.Weapon_PosY_ChangeLerp * 20, HUDCommons.Position2.Weapon_PosZ_ChangeLerp * 20)

	-- workaround some good source engine bugs
	--render.PushRenderTarget(RENDER_TARGET)
	--render.Clear(0, 0, 0, 0, true, true)
	-- draw sides on screen
	cam.Start3D(POSITION, ANGLE, FOV)

	render.SetMaterial(MATERIAL_SIDE_CENTER)
	render.DrawQuadEasy(CENTER_POSITION + weaponShift, CENTER_NORMAL, w * 0.5, h * 0.5, color_white, 180)

	cam.End3D()

	--render.PopRenderTarget()

	--render.SetMaterial(MATERIAL_REDRAW)
	--render.DrawScreenQuad()

	--surface.SetMaterial(MATERIAL_REDRAW)
	--surface.DrawTexturedRect(0, 0, w, h)
end

hook.Add('HUDPaint', 'HUDCommons.A3D', HUDPaint)
hook.Add('ScreenResolutionChanged', 'HUDCommons.A3D', ScreenResolutionChanged)
