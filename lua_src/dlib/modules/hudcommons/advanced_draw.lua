
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


local HUDCommons = DLib.HUDCommons
local surface = surface
local render = render
local cam = cam
local RealTimeL = RealTimeL
local math = math

HUDCommons.BarData = {}
HUDCommons.BarData2 = {}
HUDCommons.BarData3 = {}
HUDCommons.BarData4 = {}
HUDCommons.WordBarData = {}

local function InInterval(val, min, max)
	return val > min and val < max
end

local blurrt, blurMat

timer.Simple(0, function()
	blurrt = GetRenderTarget('dlib_hudcommons_blur', ScrWL(), ScrHL(), false)
	blurMat = CreateMaterial('dlib_hudcommons_blurmat2', 'UnlitGeneric', {
		['$basetexture'] = 'models/debug/debugwhite',
		['$halflambert'] = '1',
		['$translucent'] = '1',
	})

	blurMat:SetTexture('$basetexture', blurrt)
end)

--[[
	@doc
	@fname DLib.HUDCommons.DrawLoading
	@args number x, number y, number radius, Color color, number segments, number inLength

	@client

	@desc
	draws animated arc
	@enddesc
]]
function HUDCommons.DrawLoading(x, y, radius, color, segments, inlength)
	return HUDCommons.DrawArcHollow2(x, y, radius, segments or 60, inlength or (radius / 12.5), ((RealTimeL() * 4) % 180) * 90, math.sin(RealTimeL() * 2) * 180 + 180, color)
end

--[[
	@doc
	@fname DLib.HUDCommons.DrawBlurredRect
	@args number x, number y, number w, number h, number blurx, number blury, number passes

	@client

	@deprecated
]]
function HUDCommons.DrawBlurredRect(x, y, w, h, blurx, blury, passes)
	render.PushRenderTarget(blurrt)
	render.Clear(0, 0, 0, 0)
	cam.Start2D()
	surface.DrawRect(x, y, w, h)
	cam.End2D()
	render.PopRenderTarget()

	render.BlurRenderTarget(blurrt, blurx, blury, passes)
	render.SetMaterial(blurMat)
	render.DrawScreenQuad()
end

--[[
	@doc
	@fname DLib.HUDCommons.SoftBar
	@args number x, number y, number w, number h, Color color, string id

	@client

	@desc
	this function is expected to be called on each frame
	this function draws bar which change it's width over time
	@enddesc
]]
function HUDCommons.SoftBar(x, y, w, h, color, name)
	HUDCommons.BarData[name] = HUDCommons.BarData[name] == HUDCommons.BarData[name] and HUDCommons.BarData[name] or w

	local delta = w - HUDCommons.BarData[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData[name], h, color)
end

--[[
	@doc
	@fname DLib.HUDCommons.SoftBarMult
	@args number x, number y, number w, number h, number mult, Color color, Color bgcolor, string id

	@client

	@desc
	width is multiplied by `mult` (float)
	and it also draws extra bar with `bgcolor` color
	@enddesc
]]
function HUDCommons.SoftBarMult(x, y, w, h, mult, color, bgcolor, name)
    HUDCommons.DrawBox(x, y, w, h, bgcolor)
    w = w * mult:clamp(0, 1)
	HUDCommons.BarData2[name] = HUDCommons.BarData2[name] == HUDCommons.BarData2[name] and HUDCommons.BarData2[name] or w

	local delta = w - HUDCommons.BarData2[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData2[name] = HUDCommons.BarData2[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData2[name] = HUDCommons.BarData2[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData2[name], h, color)
end

--[[
	@doc
	@fname DLib.HUDCommons.SoftBarBackground
	@args number x, number y, number w, number h, Color color, Color bgcolor, string id

	@client
]]
function HUDCommons.SoftBarBackground(x, y, w, h, color, bgcolor, name)
	HUDCommons.BarData3[name] = HUDCommons.BarData3[name] == HUDCommons.BarData3[name] and HUDCommons.BarData3[name] or w

	local delta = w - HUDCommons.BarData3[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData3[name] = HUDCommons.BarData3[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData3[name] = HUDCommons.BarData3[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData3[name], h, bgcolor)
    HUDCommons.DrawBox(x, y, w, h, color)
end

--[[
	@doc
	@fname DLib.HUDCommons.SoftBarBackgroundMult
	@args number x, number y, number w, number h, number mult, Color color, Color bgcolor1, Color bgcolor2, string id

	@client

	@desc
	mimics behavior of HP bars in some popular games
	first pass - `w, h` bar with `bgcolor1` is drawn
	second pass - lerped over time `bgcolor2` bar with `w * mult, h` is drawn
	third pass - `color` bar with `w * mult, h` is drawn
	@enddesc
]]
function HUDCommons.SoftBarBackgroundMult(x, y, w, h, mult, color, bgcolor1, bgcolor2, name)
    HUDCommons.DrawBox(x, y, w, h, bgcolor1)
    w = w * mult:clamp(0, 1)
	HUDCommons.BarData4[name] = HUDCommons.BarData4[name] == HUDCommons.BarData4[name] or w

	local delta = w - HUDCommons.BarData4[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData4[name] = HUDCommons.BarData4[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData4[name] = HUDCommons.BarData4[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData4[name], h, bgcolor2)
    HUDCommons.DrawBox(x, y, w, h, color)
end

--[[
	@doc
	@fname DLib.HUDCommons.SoftCenteredBar
	@args number x, number y, number w, number h, Color color, string id, number speed = 0.1

	@client

	@desc
	mimics behavior of skyrim bar
	@enddesc
]]
function HUDCommons.SoftCenteredBar(x, y, w, h, color, name, speed)
	speed = speed or .1
	HUDCommons.BarData[name] = HUDCommons.BarData[name] == HUDCommons.BarData[name] and HUDCommons.BarData[name] or w

	local delta = w - HUDCommons.BarData[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta * speed * HUDCommons.Multipler
	else
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta
	end

	HUDCommons.DrawBox(x - HUDCommons.BarData[name] / 2, y, HUDCommons.BarData[name], h, color)
end

HUDCommons.SoftSkyrimBar = HUDCommons.SoftCenteredBar

--[[
	@doc
	@fname DLib.HUDCommons.BarWithText
	@args number x, number y, number w, number h, number mult, Color bg, Color barbg, Color bar, string text

	@client
]]
function HUDCommons.BarWithText(x, y, w, h, mult, bg, barbg, bar, text)
    surface.SetDrawColor(bg)
    surface.DrawRect(x - 4, y - 4, w + 8, h + 8)

    surface.SetDrawColor(barbg)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(bar)
    surface.DrawRect(x, y, w * mult:clamp(0, 1), h)

    surface.SetDrawColor(bg)
    local W, H = surface.GetTextSize(text)
    surface.DrawRect(x - 4, y - 12 - H, W + 8, H + 8)
    surface.SetTextPos(x, y - H - 8)
    surface.DrawText(text)
end

--[[
	@doc
	@fname DLib.HUDCommons.CenteredBarWithText
	@args number x, number y, number w, number h, number mult, Color bg, Color barbg, Color bar, string text

	@client
]]
function HUDCommons.CenteredBarWithText(x, y, w, h, mult, bg, barbg, bar, text)
    surface.SetDrawColor(bg)
    surface.DrawRect(x - 4, y - 4, w + 8, h + 8)

    surface.SetDrawColor(barbg)
    surface.DrawRect(x, y, w, h)

    local targetwidth = w * mult:clamp(0, 1)
    surface.SetDrawColor(bar)
    surface.DrawRect(x + w / 2 - targetwidth / 2, y, targetwidth, h)

    surface.SetDrawColor(bg)
    local W, H = surface.GetTextSize(text)
    surface.DrawRect(x - 4, y - 12 - H, W + 8, H + 8)
    surface.SetTextPos(x, y - H - 8)
    surface.DrawText(text)
end

HUDCommons.SkyrimBarWithText = HUDCommons.CenteredBarWithText

--[[
	@doc
	@fname DLib.HUDCommons.SoftBarWithText
	@args number x, number y, number w, number h, number mult, Color bg, Color barbg, Color bar, string text, string barid, number speed = 0.1

	@client
]]
function HUDCommons.SoftBarWithText(x, y, w, h, mult, bg, barbg, bar, text, barid, speed)
    speed = speed or .1
    local targetwidth = w * mult:clamp(0, 1)
	HUDCommons.WordBarData[barid] = HUDCommons.WordBarData[barid] or targetwidth

	local delta = targetwidth - HUDCommons.WordBarData[barid]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.WordBarData[barid] = HUDCommons.WordBarData[barid] + delta * speed * HUDCommons.Multipler
	else
		HUDCommons.WordBarData[barid] = HUDCommons.WordBarData[barid] + delta
	end

    surface.SetDrawColor(bg)
    surface.DrawRect(x - 4, y - 4, w + 8, h + 8)

    surface.SetDrawColor(barbg)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(bar)
    surface.DrawRect(x, y, HUDCommons.WordBarData[barid], h)

    surface.SetDrawColor(bg)
    local W, H = surface.GetTextSize(text)
    surface.DrawRect(x - 4, y - 12 - H, W + 8, H + 8)
    surface.SetTextPos(x, y - H - 8)
    surface.DrawText(text)
end

--[[
	@doc
	@fname DLib.HUDCommons.SoftSkyrimBarWithText
	@args number x, number y, number w, number h, number mult, Color bg, Color barbg, Color bar, string text, string barid, number speed = 0.1

	@client
]]
function HUDCommons.SoftSkyrimBarWithText(x, y, w, h, mult, bg, barbg, bar, text, barid, speed)
    speed = speed or .1
    local targetwidth = w * mult:clamp(0, 1)
	HUDCommons.WordBarData[barid] = HUDCommons.WordBarData[barid] or targetwidth

	local delta = targetwidth - HUDCommons.WordBarData[barid]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.WordBarData[barid] = HUDCommons.WordBarData[barid] + delta * speed * HUDCommons.Multipler
	else
		HUDCommons.WordBarData[barid] = HUDCommons.WordBarData[barid] + delta
	end

    surface.SetDrawColor(bg)
    surface.DrawRect(x - 4, y - 4, w + 8, h + 8)

    surface.SetDrawColor(barbg)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(bar)
    surface.DrawRect(x + w / 2 - HUDCommons.WordBarData[barid] / 2, y, HUDCommons.WordBarData[barid], h)

    surface.SetDrawColor(bg)
    local W, H = surface.GetTextSize(text)
    surface.DrawRect(x - 4, y - 12 - H, W + 8, H + 8)
    surface.SetTextPos(x, y - H - 8)
    surface.DrawText(text)
end

--[[
	@doc
	@fname DLib.HUDCommons.BarWithTextCentered
	@args number x, number y, number w, number h, number mult, Color bg, Color barbg, Color bar, string text

	@client
]]
function HUDCommons.BarWithTextCentered(x, y, w, h, mult, bg, barbg, bar, text)
    surface.SetDrawColor(bg)
    surface.DrawRect(x - w / 2 - 4, y - 4, w + 8, h + 8)

    surface.SetDrawColor(barbg)
    surface.DrawRect(x - w / 2, y, w, h)

    surface.SetDrawColor(bar)
    surface.DrawRect(x - w / 2, y, w * mult, h)

    surface.SetDrawColor(bg)
    local W, H = surface.GetTextSize(text)
    surface.DrawRect(x - w / 2 - 4, y - 12 - H, W + 8, H + 8)
    surface.SetTextPos(x - w / 2, y - H - 8)
    surface.DrawText(text)
end

--[[
	@doc
	@fname DLib.HUDCommons.AdvancedWordBox
	@args string text, string font, number x, number y, Color color, boolean center

	@client

	@desc
	Same as `HUDCommons.WordBox`, but supports new lines
	Similar to !g:draw.DrawText , but works faster
	because it doesn't calculate tabs
	`font` and `color` arguments can be omitted (if you specified them earlier)
	@enddesc
]]
function HUDCommons.AdvancedWordBox(text, font, x, y, col, colBox, center)
	if font then
		surface.SetFont(font)
	end

	if col then
		surface.SetTextColor(col)
	end

    local W, H = surface.GetTextSize('W')
	local w, h = surface.GetTextSize(text)

    if center then
	    HUDCommons.DrawBox(x - 4 - w / 2, y - 2, w + 8, h + 4, colBox)
    else
	    HUDCommons.DrawBox(x - 4, y - 2, w + 8, h + 4, colBox)
    end

    for ntext in string.gmatch(text, '[^\n]*') do
        if ntext ~= '' then
            local w2, h2 = surface.GetTextSize(ntext)

            if center then
                surface.SetTextPos(x - w2 / 2, y)
            else
                surface.SetTextPos(x, y)
            end

            surface.DrawText(ntext)
        else
            y = y + H
        end
    end

    return w, h
end
