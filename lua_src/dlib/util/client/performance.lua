
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

local cam_End2D =               cam.End2D
local cam_Start2D =             cam.Start2D
local render_OverrideBlend =    render.OverrideBlend
local render_PopRenderTarget =  render.PopRenderTarget
local render_PushRenderTarget = render.PushRenderTarget
local string_format =           string.format
local surface_DrawRect =        surface.DrawRect
local surface_DrawText =        surface.DrawText
local surface_SetDrawColor =    surface.SetDrawColor
local surface_SetFont =         surface.SetFont
local surface_SetTextColor =    surface.SetTextColor
local surface_SetTextPos =      surface.SetTextPos

local DLib_I18n_FormatAnyBytesLong = DLib.I18n.FormatAnyBytesLong
local math_floor = math.floor
local math_abs = math.abs
local math_progression = math.progression
local surface_GetTextSize = surface.GetTextSize

local Net = DLib.Net
local I18n = DLib.I18n
local ply

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

	render_PushRenderTarget(graph_rt_1)
	render.Clear(0, 0, 0, 0, true, true)
	render_PopRenderTarget()

	render_PushRenderTarget(graph_rt_2)
	render.Clear(0, 0, 0, 0, true, true)
	render_PopRenderTarget()
end

hook.Add('ScreenResolutionChanged', 'DLib Refresh Performance Screen', function()
	graph_rt_1, graph_rt_2 = nil
	graph_rt_1_mat, graph_rt_2_mat = nil
end)

hook.Add('InvalidateMaterialCache', 'DLib Refresh Performance Screen', function()
	graph_rt_1, graph_rt_2 = nil
	graph_rt_1_mat, graph_rt_2_mat = nil
end)

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

local last_max_memory, last_max_memory_text, last_memory = 0, '0'

local function PostRender()
	if not dlib_performance:GetBool() then return end
	if not graph_rt_1 then refresh() end

	local stime = SysTime()

	local delta_full = stime - _last_frame
	local delta_frame = stime - _last_frame2
	local delta_logic = delta_full - delta_frame

	_last_frame = stime
	local gcnum = collectgarbage('count')
	local delta_gc = gcnum - _last_frame_gc
	tick = tick + 1

	if last_max_memory < gcnum then
		last_max_memory_text = DLib_I18n_FormatAnyBytesLong(gcnum * 1024)
		last_max_memory = gcnum
	end

	last_memory = DLib_I18n_FormatAnyBytesLong(gcnum * 1024)

	if last_gc_account_time < stime then
		local _gc_account = gc_account / 2048
		last_gc_account = string_format('%.3d.%.1d MB/s', math_floor(_gc_account), (_gc_account % 1) * 10)
		last_gc_account_time = stime + 2
		gc_account = 0
	end

	last_fps_account = string_format('%.3d FPS (%.3fms / %.3fms logic, %.3fms / %.3fms render)', last_fps_account_num, delta_logic * 1000, last_account_logic, delta_frame * 1000, last_account_render)

	if last_fps_account_time < stime then
		last_account_logic, last_account_render = (account_logic / fps_account_frames) * 1000, (account_render / fps_account_frames) * 1000
		last_fps_account_num = fps_account_frames
		last_fps_account_time = stime + 1
		fps_account_frames = 0
		account_logic, account_render = 0, 0
	end

	gc_account = gc_account + math_abs(delta_gc)
	account_render = account_render + delta_frame
	account_logic = account_logic + delta_logic
	fps_account_frames = fps_account_frames + 1

	render_PushRenderTarget(current_render)

	cam_Start2D()

	if delta_gc < 0 then
		surface_SetDrawColor(255, 196, 17)
	elseif delta_full <= mark_240_fps then
		surface_SetDrawColor(200, 255, 200)
	elseif delta_full <= mark_144_fps then
		local add = 200 + 55 * math_progression(delta_full, mark_240_fps, mark_144_fps)
		surface_SetDrawColor(add, 255, add)
	elseif delta_full <= mark_60_fps then
		local add = 255 - 50 * math_progression(delta_full, mark_144_fps, mark_60_fps)
		surface_SetDrawColor(255, add, add)
	elseif delta_full <= mark_30_fps then
		local add = 255 - 150 * math_progression(delta_full, mark_60_fps, mark_30_fps)
		surface_SetDrawColor(255, add, add)
	else
		local add = 255 * (1 - math_progression(delta_full, mark_30_fps, mark_10_fps))
		surface_SetDrawColor(255, add, add)
	end

	local h = delta_full * step_1_fps
	surface_DrawRect(current_render_position, ScrH() - h, 1, h + 1)

	if delta_gc >= 0 then
		local logic_mult = 1 - delta_logic:progression(mark_240_fps, mark_10_fps)
		h = delta_logic * step_1_fps
		surface_SetDrawColor(66 + 200 * (1 - logic_mult), 182 * logic_mult, 225 * logic_mult)
		surface_DrawRect(current_render_position, ScrH() - h, 1, h + 1)
	end

	if tick % 10 == 0 then
		render_OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_REVERSE_SUBTRACT, BLEND_ZERO, BLEND_ONE, BLENDFUNC_ADD)
		surface_SetDrawColor(25, 25, 25)
		surface_DrawRect(0, 0, ScrW(), ScrH())
		render_OverrideBlend(false)
	end

	cam_End2D()

	render_PopRenderTarget()

	if tick % 10 == 0 then
		render_PushRenderTarget(current_render == graph_rt_1 and graph_rt_2 or graph_rt_1)

		cam_Start2D()
		render_OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_REVERSE_SUBTRACT, BLEND_ZERO, BLEND_ONE, BLENDFUNC_ADD)
		surface_SetDrawColor(25, 25, 25)
		surface_DrawRect(0, 0, ScrW(), ScrH())
		render_OverrideBlend(false)
		cam_End2D()

		render_PopRenderTarget()
	end

	current_render_position = current_render_position + 1

	if current_render_position >= target_width then
		current_render = current_render == graph_rt_1 and graph_rt_2 or graph_rt_1

		render_PushRenderTarget(current_render)
		render.Clear(0, 0, 0, 0, true, true)
		render_PopRenderTarget()

		current_render_position = 0
	end
end

render_PushRenderTarget(graph_rt_1)
render.Clear(0, 0, 0, 0, true, true)
render_PopRenderTarget()

render_PushRenderTarget(graph_rt_2)
render.Clear(0, 0, 0, 0, true, true)
render_PopRenderTarget()

surface_SetFont(debugfont)
local fps_w, fps_h = surface_GetTextSize('60 FPS')

local unformat_version = tostring(_G.VERSION or '000000')
unformat_version = string_format("Garry's Mod 20%s-%s-%s (%s/%s/%s/DLib)",
	unformat_version:sub(1, 2),
	unformat_version:sub(3, 4),
	unformat_version:sub(5, 6),
	jit.arch, _VERSION,
	system.IsWindows() and 'Windows' or system.IsLinux() and 'Linux' or 'OS X'
)

local jit_features = 'JIT features: ' .. table.concat({select(2, jit.status())}, ', ')

local features

local function draw_boxed(text, y)
	local _w, _h = surface_GetTextSize(text)

	surface_DrawRect(0, y, _w + 8, _h + 4)
	surface_SetTextPos(4, y + 2)
	surface_DrawText(text)

	return y + _h + 4
end

local scr_w

local function draw_boxed_right(text, y)
	local _w, _h = surface_GetTextSize(text)

	surface_DrawRect(scr_w - _w - 8, y, _w + 8, _h + 4)
	surface_SetTextPos(scr_w - _w - 4, y + 2)
	surface_DrawText(text)

	return y + _h + 4
end

local eye_pos = Vector()
local eye_angles = Angle()
local velocity = Angle()

local EyePos = EyePos
local EyeAngles = EyeAngles
local LocalPlayer = LocalPlayer

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
local cl_showfps = ConVar('cl_showfps')
local cl_showpos = ConVar('cl_showpos')

local render_SetMaterial = render.SetMaterial
local render_DrawScreenQuad = render.DrawScreenQuad
local render_SetScissorRect = render.SetScissorRect
local render_SetScissorRect = render.SetScissorRect

local mat_dxlevel = ConVar('mat_dxlevel')
local mat_picmip = ConVar('mat_picmip')
local mat_specular = ConVar('mat_specular')
local cl_drawhud = ConVar('cl_drawhud')
local crosshair = ConVar('crosshair')
local mat_hdr_level = ConVar('mat_hdr_level')

local function PostDrawHUD()
	if not dlib_performance:GetBool() then return end
	if not graph_rt_1 then refresh() end

	if not features then
		ply = LocalPlayer()

		features = {
			string_format('Singleplayer: %s', game.SinglePlayer() and 'Yes' or 'No'),
			string_format('Map: %s', game.GetMap()),
			string_format('LocalPlayer(): E%d / U%d <%s/%s>', ply:EntIndex(), ply:UserID(), ply:SteamID(), ply:SteamID64()),
		}
	end

	cam_Start2D()

	local current_mat = current_render == graph_rt_1 and graph_rt_1_mat or graph_rt_2_mat
	local other_mat = current_render == graph_rt_1 and graph_rt_2_mat or graph_rt_1_mat

	local sH = ScrH()
	local pos = sH - mark_30_fps * step_1_fps
	surface_SetDrawColor(0, 0, 0, 150)
	surface_DrawRect(0, pos, target_width, mark_30_fps * step_1_fps)

	render_SetMaterial(current_mat)
	render_DrawScreenQuad()

	scr_w = ScrW()

	render_SetScissorRect(current_render_position, 0, target_width, sH, true)
	render_SetMaterial(other_mat)
	render_DrawScreenQuad()
	render_SetScissorRect(0, 0, 0, 0, false)

	pos = sH - mark_60_fps * step_1_fps - 1
	surface_SetDrawColor(0, 255, 0)
	surface_DrawRect(0, pos, target_width, 2)

	surface_SetFont(debugfont)

	surface_SetDrawColor(0, 0, 0, 255)
	surface_DrawRect(6, pos - 34, fps_w + 8, fps_h + 8)

	surface_SetTextColor(0, 255, 0)
	surface_SetTextPos(10, pos - 30)
	surface_DrawText('60 FPS')

	pos = sH - mark_30_fps * step_1_fps - 1

	surface_SetDrawColor(0, 0, 0, 255)
	surface_DrawRect(6, pos - 34, fps_w + 8, fps_h + 8)

	surface_SetDrawColor(0, 255, 0)
	surface_DrawRect(0, pos, target_width, 2)

	surface_SetTextColor(0, 255, 0)
	surface_SetTextPos(10, pos - 30)
	surface_DrawText('30 FPS')

	local _w, _h = surface_GetTextSize(last_gc_account)

	surface_SetDrawColor(0, 0, 0, 255)
	surface_DrawRect(target_width + 4, pos, _w + 8, _h + 8)

	surface_SetTextPos(target_width + 8, pos + 4)
	local mult = 1 - 0.2 * Cubic(SysTime():progression(last_gc_account_time - 1, last_gc_account_time - 0.5))
	surface_SetTextColor(255 * mult, 196 * mult, 17 * mult)
	surface_DrawText(last_gc_account)

	surface_SetTextColor(200, 200, 200)
	surface_SetDrawColor(100, 100, 100, 230)

	local y = 0

	y = draw_boxed(unformat_version, y)
	y = draw_boxed(last_fps_account, y)
	y = draw_boxed(string_format('Reported viewport: %dx%d', ScrW(), ScrH()), y)
	y = draw_boxed(string_format('Gamemode: %s', engine.ActiveGamemode()), y)

	y = y + 30
	y = draw_boxed(string_format('CurTime(%.4f) RealTime(%.4f) SysTime(%.4f)', CurTime(), RealTime(), SysTime()), y)
	y = draw_boxed(string_format('EyePos(%.3f %.3f %.3f)', eye_pos:Unpack()), y)
	y = draw_boxed(string_format('EyeAngles(%.3f %.3f %.3f)', eye_angles:Unpack()), y)
	y = draw_boxed(string_format('Velocity(%.3f %.3f %.3f)', velocity:Unpack()), y)
	y = draw_boxed(string_format('game.GetTimeScale(%.2f); host_timescale: %.2f / %.2f', game.GetTimeScale(), host_timescale:GetFloat(), sv_cheats:GetBool() and host_timescale:GetFloat() or 1), y)

	local interval = math.floor(0.5 + 1 / engine.TickInterval())

	if interval < 66 and interval > 44 then
		surface_SetTextColor(255, 249, 205)
	elseif interval <= 44 and interval > 33 then
		surface_SetTextColor(255, 240, 140)
	elseif interval <= 33 and interval > 22 then
		surface_SetTextColor(255, 229, 55)
	elseif interval <= 22 and interval > 16 then
		surface_SetTextColor(255, 124, 124)
	elseif interval <= 16 then
		surface_SetTextColor(255, 0, 0)
	elseif interval > 66 and interval <= 88 then
		surface_SetTextColor(210, 255, 173)
	elseif interval > 88 and interval <= 128 then
		surface_SetTextColor(160, 255, 83)
	elseif interval > 128 and interval <= 160 then
		surface_SetTextColor(255, 240, 140)
	elseif interval > 160 and interval <= 200 then
		surface_SetTextColor(255, 229, 55)
	elseif interval > 200 and interval <= 240 then
		surface_SetTextColor(255, 124, 124)
	elseif interval > 240 then
		surface_SetTextColor(255, 0, 0)
	end

	y = draw_boxed(string_format('Tickrate: %.2f; Ticks: %.6d', interval, engine.TickCount()), y)

	surface_SetTextColor(200, 200, 200)

	y = y + 10
	y = draw_boxed('DLib.Net', y)
	y = draw_boxed(string_format('Network bytes out %s/in %s', I18n.FormatKilobytes(Net.total_traffic_out), I18n.FormatKilobytes(Net.total_traffic_in)), y)
	y = draw_boxed(string_format('Payload bytes out %s/in %s', I18n.FormatKilobytes(Net.server_position), I18n.FormatKilobytes(Net.network_position)), y)
	y = draw_boxed(string_format('Next datagram out %d/in %d', Net.next_datagram_id, Net.next_expected_datagram), y)
	y = draw_boxed(string_format('Queued out Chunks %d/Datagrams %d; queued in Chunks %d/Datagrams %d', Net.server_chunks_num, Net.server_datagrams_num, Net.queued_chunks_num, Net.queued_datagrams_num), y)
	y = draw_boxed(string_format('Input buffer %s', I18n.FormatKilobytes(Net.accumulated_size)), y)

	if Net.use_unreliable then
		surface_SetTextColor(200, 255, 200)
		y = draw_boxed('Using unreliable channel', y)
		surface_SetTextColor(200, 200, 200)
	else
		surface_SetTextColor(255, 200, 200)
		y = draw_boxed('Using reliable channel; suffered network losses earlier', y)
		surface_SetTextColor(200, 200, 200)
	end

	if ply:DLibGetNWBool('dlib_net_unreliable', true) then
		surface_SetTextColor(200, 255, 200)
		y = draw_boxed('Server is using unreliable channel', y)
		surface_SetTextColor(200, 200, 200)
	else
		surface_SetTextColor(255, 200, 200)
		y = draw_boxed('Server is using reliable channel; suffered network losses earlier', y)
		surface_SetTextColor(200, 200, 200)
	end

	y = 0

	if cl_showfps:GetBool() then
		y = 16
	end

	if cl_showpos:GetBool() then
		y = y + 48
	end

	y = draw_boxed_right(string_format('LuaVM Mem: %s / %s', last_memory, last_max_memory_text), y) + 10
	y = draw_boxed_right(string_format('DirectX level: %d', mat_dxlevel:GetInt()), y)
	y = draw_boxed_right(string_format('P: %d S: %d DH: %d C: %d', mat_picmip:GetInt(), mat_specular:GetInt(), cl_drawhud:GetInt(), crosshair:GetInt()), y)
	y = draw_boxed_right(string_format('Pixel shaders 1.4: %s 2.0: %s; Vertex shaders 2.0: %s', render.SupportsPixelShaders_1_4() and 'true' or 'false', render.SupportsPixelShaders_2_0() and 'true' or 'false', render.SupportsVertexShaders_2_0() and 'true' or 'false'), y)
	local mat_hdr_level = mat_hdr_level:GetInt()
	y = draw_boxed_right(string_format('HDR Supported: %s; Level: %s', render.SupportsHDR() and 'true' or 'false', mat_hdr_level <= 0 and 'disabled' or mat_hdr_level == 1 and 'partial' or 'full'), y) + 30

	y = draw_boxed_right(string_format('JIT status: %s', jit.status() and 'Enabled' or 'Disabled'), y)
	y = draw_boxed_right(jit_features, y) + 30

	y = draw_boxed_right(features[1], y)
	y = draw_boxed_right(features[2], y)
	y = draw_boxed_right(features[3], y)

	cam_End2D()
end

hook.Add('PreRender', 'DLib Performance', PreRender)
hook.Add('PostRender', 'DLib Performance', PostRender)
hook.Add('PostDrawHUD', 'DLib Performance', PostDrawHUD, 100)
hook.Add('PreDrawTranslucentRenderables', 'DLib Performance', PreDrawTranslucentRenderables, -100)
hook.Add('FinishMove', 'DLib Performance', FinishMove)

if game.SinglePlayer() then
	hook.Add('Think', 'DLib Performance', ThinkVelocity)
end
