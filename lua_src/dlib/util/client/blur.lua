
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

local SCREENCOPY, DRAWMAT, EFFECTSMAT, RTW, RTH, RTX, RTY, copymatrix

local function refreshRT()
	RTW, RTH = 0, 0
	local w, h = ScrW(), ScrH()

	for i = 1, 13 do
		local pow = math.pow(2, i)

		if RTW == 0 and w < pow then
			RTW = pow
		end

		if RTH == 0 and h < pow then
			RTH = pow
		end

		if RTW ~= 0 and RTH ~= 0 then break end
	end

	SCREENCOPY = GetRenderTarget('dlib-blur-' .. RTW .. '-' .. RTH, RTW, RTH, false)
	RTX = RTW / 2 - w / 2
	RTY = RTH / 2 - h / 2

	DRAWMAT = CreateMaterial('dlib-blur2_', 'UnlitGeneric', {
		-- ['$basetexture'] = 'models/debug/debugwhite',
		['$translucent'] = '0',
		['$color'] = '[1 1 1]',
		['$alpha'] = '1',
		['$nolod'] = '1',
	})

	EFFECTSMAT = CreateMaterial('dlib-screen-space_', 'UnlitGeneric', {
		-- ['$basetexture'] = 'models/debug/debugwhite',
		['$translucent'] = '0',
		['$color'] = '[1 1 1]',
		['$alpha'] = '1',
		['$nolod'] = '1',
	})

	DRAWMAT:SetFloat('$alpha', '1')
	DRAWMAT:SetTexture('$basetexture', SCREENCOPY)
end

refreshRT()
timer.Simple(0, refreshRT)
hook.Add('ScreenResolutionChanged', 'DLib Refresh Blur', refreshRT)
hook.Add('InvalidateMaterialCache', 'DLib Refresh Blur', refreshRT)

DLib.blur = DLib.blur or {}
local blur = DLib.blur

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

local LAST_DRAW = 0
local LAST_REFRESH
DLib.DISTORT_FIX_X = -70
DLib.DISTORT_FIX_Y = 100

--[[
	@doc
	@fname DLib.blur.RefreshNow
	@args boolean force = false
	@client

	@desc
	calls render.CopyRenderTargetToTexture and blurs internal render target
	@enddesc
]]
function blur.RefreshNow(force)
	if not BLUR_ENABLE:GetBool() then return false end
	if not render.SupportsPixelShaders_2_0() then return false end
	if LAST_REFRESH == FrameNumber() and not force then return false end
	if LAST_DRAW < 0 and not force then return false end
	LAST_REFRESH = FrameNumber()
	LAST_DRAW = LAST_DRAW - 1

	render.CopyRenderTargetToTexture(SCREENCOPY)
	BlurRenderTarget(SCREENCOPY, BLUR_X:GetInt(2):clamp(1, 32), BLUR_Y:GetInt(2):clamp(1, 32), BLUR_PASSES:GetInt(1):clamp(1, 32))

	return true
end

hook.Add('PostDrawHUD', 'DLib.Blur', function()
	--blur.RefreshNow()
	if not render.SupportsPixelShaders_2_0() then
		hook.Remove('PostDrawHUD', 'DLib.Blur')
	end
end, -1)

--[[
	@doc
	@fname DLib.blur.Draw
	@args number x, number y, number width, number height
	@client
]]
function blur.Draw(x, y, w, h)
	if not BLUR_ENABLE:GetBool() then return end
	if not render.SupportsPixelShaders_2_0() then return end
	LAST_DRAW = 10
	if LAST_REFRESH ~= FrameNumber() then return end
	local u0, v0, u1, v1 = x / ScrWL(), y / ScrHL(), (x + w) / ScrWL(), (y + h) / ScrHL()
	local du = 0.5 / 32 -- half pixel anticorrection
	local dv = 0.5 / 32 -- half pixel anticorrection
	u0, v0 = (u0 - du) / (1 - 2 * du), (v0 - dv) / (1 - 2 * dv)
	u1, v1 = (u1 - du) / (1 - 2 * du), (v1 - dv) / (1 - 2 * dv)

	surface.SetMaterial(DRAWMAT)
	surface.SetDrawColor(255, 255, 255)
	render.OverrideDepthEnable(true, false)
	surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
	render.OverrideDepthEnable(false)
end

--[[
	@doc
	@fname DLib.blur.DrawOffset
	@args number drawx, number drawy, number width, number height, number realx, number realy
	@client
]]
function blur.DrawOffset(drawX, drawY, w, h, realX, realY)
	if not BLUR_ENABLE:GetBool() then return end
	if not render.SupportsPixelShaders_2_0() then return end
	LAST_DRAW = 10
	if LAST_REFRESH ~= FrameNumber() then return end

	local u0, v0, u1, v1 = realX / ScrWL(), realY / ScrHL(), (realX + w) / ScrWL(), (realY + h) / ScrHL()

	local du = 0.5 / 32 -- half pixel anticorrection
	local dv = 0.5 / 32 -- half pixel anticorrection
	u0, v0 = (u0 - du) / (1 - 2 * du), (v0 - dv) / (1 - 2 * dv)
	u1, v1 = (u1 - du) / (1 - 2 * du), (v1 - dv) / (1 - 2 * dv)

	surface.SetMaterial(DRAWMAT)
	surface.SetDrawColor(255, 255, 255)
	render.OverrideDepthEnable(true, false)
	surface.DrawTexturedRectUV(drawX, drawY, w, h, u0, v0, u1, v1)
	render.OverrideDepthEnable(false)
end

--[[
	@doc
	@fname DLib.blur.DrawPanel
	@args number width, number height, number screenx, number screeny
	@client

	@desc
	handy with use of panels. Example usage: `DLib.blut.DrawPanel(w, h, self:LocalToScreen(0, 0))`
	@enddesc
]]
function blur.DrawPanel(w, h, x, y)
	if not BLUR_ENABLE:GetBool() then return end
	if not render.SupportsPixelShaders_2_0() then return end
	LAST_DRAW = 10
	if LAST_REFRESH ~= FrameNumber() then return end

	local u0, v0, u1, v1 = x / ScrWL(), y / ScrHL(), (x + w) / ScrWL(), (y + h) / ScrHL()

	local du = 0.5 / 32 -- half pixel anticorrection
	local dv = 0.5 / 32 -- half pixel anticorrection
	u0, v0 = (u0 - du) / (1 - 2 * du), (v0 - dv) / (1 - 2 * dv)
	u1, v1 = (u1 - du) / (1 - 2 * du), (v1 - dv) / (1 - 2 * dv)

	surface.SetMaterial(DRAWMAT)
	surface.SetDrawColor(255, 255, 255)
	render.OverrideDepthEnable(true, false)
	surface.DrawTexturedRectUV(0, 0, w, h, u0, v0, u1, v1)
	render.OverrideDepthEnable(false)
end
