
-- Copyright (C) 2020 DBotThePony

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

local gradient_r = Material('vgui/gradient-r')
local debugfont = 'Trebuchet24'

local DLib = DLib
local surface = surface
local draw = draw
local render = render
local SysTime = SysTime
local ScrW = ScrW
local ScrH = ScrH
local cam = cam
local collectgarbage = collectgarbage
local string = string
local abs = math.abs
local dlib_performance = CreateConVar('dlib_performance', '0', {}, 'Show debug screen')

local graph_rt_1, graph_rt_2
local graph_rt_1_mat, graph_rt_2_mat
local current_render

local function refresh()
	graph_rt_1 = GetRenderTarget('graph_profile_rt1' .. ScrW() .. '_' .. ScrH(), ScrW(), ScrH())
	graph_rt_2 = GetRenderTarget('graph_profile_rt2' .. ScrW() .. '_' .. ScrH(), ScrW(), ScrH())

	graph_rt_1_mat = CreateMaterial('graph_profile_rt1', 'UnlitGeneric', {
		['$translucent'] = '1',
		['$basetexture'] = '__error__a', -- force pixel correction to assume texture is 32x32
	})

	graph_rt_2_mat = CreateMaterial('graph_profile_rt2', 'UnlitGeneric', {
		['$translucent'] = '1',
		['$basetexture'] = '__error__a', -- force pixel correction to assume texture is 32x32
	})

	graph_rt_1_mat:SetTexture('$basetexture', graph_rt_1)
	graph_rt_2_mat:SetTexture('$basetexture', graph_rt_2)

	current_render = graph_rt_1
end

refresh()
timer.Simple(0, refresh)
hook.Add('ScreenResolutionChanged', 'DLib Refresh Performance Screen', refresh)
hook.Add('InvalidateMaterialCache', 'DLib Refresh Performance Screen', refresh)

local _last_frame, _last_frame_gc = 0, 0
local _last_frame2 = 0
local gc_account, last_gc_account, last_gc_account_time = 0, '000.0 MB/s', 0
local fps_account_frames, last_fps_account, last_fps_account_time, last_fps_account_num = 1, '... FPS average (...)', 0, 1

local account_logic, account_render, last_account_logic, last_account_render = 0, 0, 0, 0

local current_render_position = 0

local step_1_fps = 8000
local target_width = ScrW() * 0.7

local function PreRender()
	if not dlib_performance:GetBool() then return end

	_last_frame2 = SysTime()
	_last_frame_gc = collectgarbage('count')
end

local mark_10_fps = 1 / 10
local mark_30_fps = 1 / 30
local mark_60_fps = 1 / 60
local mark_144_fps = 1 / 144
local mark_240_fps = 1 / 240

local tick = 0

local function PostRender()
	if not dlib_performance:GetBool() then return end

	local stime = SysTime()

	local delta_full = stime - _last_frame
	local delta_frame = stime - _last_frame2
	local delta_logic = delta_full - delta_frame

	_last_frame = stime
	local gcnum = collectgarbage('count')
	local delta_gc = gcnum - _last_frame_gc
	tick = tick + 1

	if last_gc_account_time < stime then
		local _gc_account = gc_account / 2048
		last_gc_account = string.format('%.3d.%.1d MB/s', _gc_account:floor(), (_gc_account % 1) * 10)
		last_gc_account_time = stime + 2
		gc_account = 0
	end

	last_fps_account = string.format('%.3d FPS (%.3fms / %.3fms logic, %.3fms / %.3fms render)', last_fps_account_num, delta_logic * 1000, last_account_logic, delta_frame * 1000, last_account_render)

	if last_fps_account_time < stime then
		last_account_logic, last_account_render = (account_logic / fps_account_frames) * 1000, (account_render / fps_account_frames) * 1000
		last_fps_account_num = fps_account_frames
		last_fps_account_time = stime + 1
		fps_account_frames = 0
		account_logic, account_render = 0, 0
	end

	gc_account = gc_account + delta_gc:abs()
	account_render = account_render + delta_frame
	account_logic = account_logic + delta_logic
	fps_account_frames = fps_account_frames + 1

	render.PushRenderTarget(current_render)

	cam.Start2D()

	if delta_gc < 0 then
		surface.SetDrawColor(255, 196, 17)
	elseif delta_full <= mark_240_fps then
		surface.SetDrawColor(200, 255, 200)
	elseif delta_full <= mark_144_fps then
		local add = 200 + 55 * delta_full:progression(mark_240_fps, mark_144_fps)
		surface.SetDrawColor(add, 255, add)
	elseif delta_full <= mark_60_fps then
		local add = 255 - 50 * delta_full:progression(mark_144_fps, mark_60_fps)
		surface.SetDrawColor(255, add, add)
	elseif delta_full <= mark_30_fps then
		local add = 255 - 150 * delta_full:progression(mark_60_fps, mark_30_fps)
		surface.SetDrawColor(255, add, add)
	else
		local add = 255 * (1 - delta_full:progression(mark_30_fps, mark_10_fps))
		surface.SetDrawColor(255, add, add)
	end

	local h = delta_full * step_1_fps
	surface.DrawRect(current_render_position, ScrH() - h, 1, h + 1)

	if delta_gc >= 0 then
		local logic_mult = 1 - delta_logic:progression(mark_240_fps, mark_10_fps)
		h = delta_logic * step_1_fps
		surface.SetDrawColor(66 + 200 * (1 - logic_mult), 182 * logic_mult, 225 * logic_mult)
		surface.DrawRect(current_render_position, ScrH() - h, 1, h + 1)
	end

	if tick % 10 == 0 then
		render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_REVERSE_SUBTRACT, BLEND_ZERO, BLEND_ONE, BLENDFUNC_ADD)
		surface.SetDrawColor(25, 25, 25)
		surface.DrawRect(0, 0, ScrW(), ScrH())
		render.OverrideBlend(false)
	end

	cam.End2D()

	render.PopRenderTarget()

	if tick % 10 == 0 then
		render.PushRenderTarget(current_render == graph_rt_1 and graph_rt_2 or graph_rt_1)

		cam.Start2D()
		render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_REVERSE_SUBTRACT, BLEND_ZERO, BLEND_ONE, BLENDFUNC_ADD)
		surface.SetDrawColor(25, 25, 25)
		surface.DrawRect(0, 0, ScrW(), ScrH())
		render.OverrideBlend(false)
		cam.End2D()

		render.PopRenderTarget()
	end

	current_render_position = current_render_position + 1

	if current_render_position >= target_width then
		current_render = current_render == graph_rt_1 and graph_rt_2 or graph_rt_1

		render.PushRenderTarget(current_render)
		render.Clear(0, 0, 0, 0, true, true)
		render.PopRenderTarget()

		current_render_position = 0
	end
end

render.PushRenderTarget(graph_rt_1)
render.Clear(0, 0, 0, 0, true, true)
render.PopRenderTarget()

render.PushRenderTarget(graph_rt_2)
render.Clear(0, 0, 0, 0, true, true)
render.PopRenderTarget()

surface.SetFont(debugfont)
local fps_w, fps_h = surface.GetTextSize('60 FPS')

local unformat_version = tostring(_G.VERSION or '000000')
unformat_version = string.format("Garry's Mod 20%s-%s-%s (%s/%s/%s)",
	unformat_version:sub(1, 2),
	unformat_version:sub(3, 4),
	unformat_version:sub(5, 6),
	jit.arch, _VERSION,
	system.IsWindows() and 'Windows' or system.IsLinux() and 'Linux' or 'OS X'
)

local jit_features = 'JIT features: ' .. table.concat({select(2, jit.status())}, ', ')

local features

local function draw_boxed(text, y)
	local _w, _h = surface.GetTextSize(text)

	surface.DrawRect(0, y, _w + 8, _h + 4)
	surface.SetTextPos(4, y + 2)
	surface.DrawText(text)

	return y + _h + 4
end

local eye_pos = Vector()
local eye_angles = Angle()
local velocity = Angle()

local function PreDrawTranslucentRenderables(a, b)
	if a or b then return end
	if not dlib_performance:GetBool() then return end

	eye_pos = EyePos()
	eye_angles = EyeAngles()
end

local function FinishMove(ply, mv)
	if not dlib_performance:GetBool() then return end
	velocity = mv:GetVelocity()
end

local function ThinkVelocity()
	if not dlib_performance:GetBool() then return end
	velocity = LocalPlayer():GetVelocity()
end

local host_timescale = ConVar('host_timescale')
local sv_cheats = ConVar('sv_cheats')

local function PostDrawHUD()
	if not dlib_performance:GetBool() then return end

	if not features then
		local ply = LocalPlayer()

		features = {
			string.format('Singleplayer: %s', game.SinglePlayer() and 'Yes' or 'No'),
			string.format('Map: %s', game.GetMap()),
			string.format('LocalPlayer(): E%d / U%d <%s/%s>', ply:EntIndex(), ply:UserID(), ply:SteamID(), ply:SteamID64()),
		}
	end

	cam.Start2D()

	local current_mat = current_render == graph_rt_1 and graph_rt_1_mat or graph_rt_2_mat
	local other_mat = current_render == graph_rt_1 and graph_rt_2_mat or graph_rt_1_mat

	render.SetMaterial(current_mat)
	render.DrawScreenQuad()

	local sH = ScrH()

	render.SetScissorRect(current_render_position, 0, target_width, sH, true)
	render.SetMaterial(other_mat)
	render.DrawScreenQuad()
	render.SetScissorRect(0, 0, 0, 0, false)

	local pos = sH - mark_60_fps * step_1_fps - 1
	surface.SetDrawColor(0, 255, 0)
	surface.DrawRect(0, pos, target_width, 2)

	surface.SetFont(debugfont)

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(6, pos - 34, fps_w + 8, fps_h + 8)

	surface.SetTextColor(0, 255, 0)
	surface.SetTextPos(10, pos - 30)
	surface.DrawText('60 FPS')

	pos = sH - mark_30_fps * step_1_fps - 1

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(6, pos - 34, fps_w + 8, fps_h + 8)

	surface.SetDrawColor(0, 255, 0)
	surface.DrawRect(0, pos, target_width, 2)

	surface.SetTextColor(0, 255, 0)
	surface.SetTextPos(10, pos - 30)
	surface.DrawText('30 FPS')

	local _w, _h = surface.GetTextSize(last_gc_account)

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(target_width + 4, pos, _w + 8, _h + 8)

	surface.SetTextPos(target_width + 8, pos + 4)
	local mult = 1 - 0.2 * Cubic(SysTime():progression(last_gc_account_time - 1, last_gc_account_time - 0.5))
	surface.SetTextColor(255 * mult, 196 * mult, 17 * mult)
	surface.DrawText(last_gc_account)

	surface.SetTextColor(200, 200, 200)
	surface.SetDrawColor(100, 100, 100, 230)

	local y = 0

	y = draw_boxed(unformat_version, y)
	y = draw_boxed(last_fps_account, y)
	y = draw_boxed(string.format('Reported viewport: %dx%d', ScrW(), ScrH()), y)

	y = y + 30
	y = draw_boxed(string.format('JIT status: %s', jit.status() and 'Enabled' or 'Disabled'), y)
	y = draw_boxed(jit_features, y)

	y = y + 30
	y = draw_boxed(features[1], y)
	y = draw_boxed(features[2], y)
	y = draw_boxed(features[3], y)

	y = y + 30
	y = draw_boxed(string.format('CurTime(): %.4f RealTime(): %.4f SysTime(): %.4f', CurTime(), RealTime(), SysTime()), y)
	y = draw_boxed(string.format('EyePos(%.3f %.3f %.3f)', eye_pos:Unpack()), y)
	y = draw_boxed(string.format('EyeAngles(%.3f %.3f %.3f)', eye_angles:Unpack()), y)
	y = draw_boxed(string.format('Velocity(%.3f %.3f %.3f)', velocity:Unpack()), y)
	y = draw_boxed(string.format('game.GetTimeScale(): %.2f; host_timescale: %.2f / %.2f', game.GetTimeScale(), host_timescale:GetFloat(), sv_cheats:GetBool() and host_timescale:GetFloat() or 1), y)

	cam.End2D()
end

hook.Add('PreRender', 'DLib Performance', PreRender)
hook.Add('PostRender', 'DLib Performance', PostRender)
hook.Add('PostDrawHUD', 'DLib Performance', PostDrawHUD, 100)
hook.Add('PreDrawTranslucentRenderables', 'DLib Performance', PreDrawTranslucentRenderables, -100)
hook.Add('FinishMove', 'DLib Performance', FinishMove)

if game.SinglePlayer() then
	hook.Add('Think', 'DLib Performance', ThinkVelocity)
end
