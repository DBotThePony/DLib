
-- Copyright (C) 2017-2019 DBotThePony

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

local SCREENCOPY, DRAWMAT, RTW, RTH

local function refreshRT()
	RTW, RTH = ScrW(), ScrH()

	SCREENCOPY = GetRenderTarget('dlib-blur-' .. RTW .. '-' .. RTH, RTW, RTH, false)

	DRAWMAT = CreateMaterial('dlib-blur1', 'UnlitGeneric', {
		['$basetexture'] = 'models/debug/debugwhite',
		['$translucent'] = '0',
		['$halflambert'] = '0',
		['$color'] = '1 1 1',
		['$color2'] = '1 1 1',
		['$alpha'] = '1',
		['$nolod'] = '1',
		['$additive'] = '0',
	})

	DRAWMAT:SetFloat('$alpha', '1')
	DRAWMAT:SetTexture('$basetexture', SCREENCOPY)
end

refreshRT()
timer.Simple(0, refreshRT)
hook.Add('ScreenResolutionChanged', 'BAHUD.RefreshRT', refreshRT)
hook.Add('InvalidateMaterialCache', 'BAHUD.RefreshRT', refreshRT)

DLib.blur = DLib.blur or {}
local blur = DLib.blur
local last_refresh

local FrameNumber = FrameNumber
local render = render
local surface = surface
local DLib = DLib

local mat_BlurX = Material("pp/blurx")
local mat_BlurY = Material("pp/blury")
local tex_Bloom1 = render.GetBloomTex1()

-- wtf is with original BlurRenderTarget ?
local function BlurRenderTarget(rt, sizex, sizey, passes)
	mat_BlurX:SetTexture('$basetexture', rt)
	mat_BlurY:SetTexture('$basetexture', tex_Bloom1)
	mat_BlurX:SetFloat('$size', sizex)
	mat_BlurY:SetFloat('$size', sizey)

	for i = 1, passes + 1 do
		render.PushRenderTarget(tex_Bloom1)
		render.SetMaterial(mat_BlurX)
		render.DrawScreenQuad()
		render.PopRenderTarget()

		render.PushRenderTarget(rt)
		render.SetMaterial(mat_BlurY)
		render.DrawScreenQuad()
		render.PopRenderTarget()
	end
end

local BLUR_X = CreateConVar('dlib_blur_x', '2', {FCVAR_ARCHIVE}, 'Blurring strength at X scale. Do not change unless you know what you are doing!')
local BLUR_Y = CreateConVar('dlib_blur_y', '2', {FCVAR_ARCHIVE}, 'Blurring strength at Y scale. Do not change unless you know what you are doing!')
local BLUR_PASSES = CreateConVar('dlib_blur_passes', '1', {FCVAR_ARCHIVE}, 'Blurring passes. Do not change unless you know what you are doing!')
local BLUR_ENABLE = CreateConVar('dlib_blur_enable', '1', {FCVAR_ARCHIVE}, 'Enable blur utility functions. Usually this does not affect performance or do so slightly.')

function blur.RefreshNow(force)
	if not BLUR_ENABLE:GetBool() then return false end
	if last_refresh == FrameNumber() and not force then return false end
	last_refresh = FrameNumber()

	render.CopyRenderTargetToTexture(SCREENCOPY)
	BlurRenderTarget(SCREENCOPY, BLUR_X:GetInt(2):clamp(1, 32), BLUR_Y:GetInt(2):clamp(1, 32), BLUR_PASSES:GetInt(1):clamp(1, 32))

	return true
end

hook.Add('PostDrawHUD', 'DLib.Blur', function()
	blur.RefreshNow()
end, -1)

function blur.Draw(x, y, w, h)
	if not BLUR_ENABLE:GetBool() then return end
	local u, v, eu, ev = x / RTW, y / RTH, (x + w) / RTW, (y + h) / RTH

	surface.SetMaterial(DRAWMAT)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRectUV(x, y, w, h, u, v, eu, ev)
end

function blur.DrawOffset(drawX, drawY, w, h, realX, realY)
	if not BLUR_ENABLE:GetBool() then return end
	local u, v, eu, ev = realX / RTW, realY / RTH, (realX + w) / RTW, (realY + h) / RTH

	surface.SetMaterial(DRAWMAT)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRectUV(drawX, drawY, w, h, u, v, eu, ev)
end

function blur.DrawPanel(w, h, x, y)
	if not BLUR_ENABLE:GetBool() then return end
	local u, v, eu, ev = x / RTW, y / RTH, (x + w) / RTW, (y + h) / RTH

	surface.SetMaterial(DRAWMAT)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRectUV(0, 0, w, h, u, v, eu, ev)
end
