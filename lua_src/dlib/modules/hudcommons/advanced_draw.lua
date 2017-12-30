
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

local HUDCommons = HUDCommons
local surface = surface

HUDCommons.BarData = HUDCommons.BarData or {}
HUDCommons.BarData2 = HUDCommons.BarData2 or {}
HUDCommons.BarData3 = HUDCommons.BarData3 or {}
HUDCommons.BarData4 = HUDCommons.BarData4 or {}
HUDCommons.WordBarData = HUDCommons.WordBarData or {}

local function InInterval(val, min, max)
	return val > min and val < max
end

function HUDCommons.SoftBar(x, y, w, h, color, name)
	HUDCommons.BarData[name] = HUDCommons.BarData[name] or w

	local delta = w - HUDCommons.BarData[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData[name], h, color)
end

function HUDCommons.SoftBarMult(x, y, w, h, mult, color, bgcolor, name)
    HUDCommons.DrawBox(x, y, w, h, bgcolor)
    w = w * math.Clamp(mult, 0, 1)
	HUDCommons.BarData2[name] = HUDCommons.BarData2[name] or w

	local delta = w - HUDCommons.BarData2[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData2[name] = HUDCommons.BarData2[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData2[name] = HUDCommons.BarData2[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData2[name], h, color)
end

function HUDCommons.SoftBarBackground(x, y, w, h, color, bgcolor, name)
	HUDCommons.BarData3[name] = HUDCommons.BarData3[name] or w

	local delta = w - HUDCommons.BarData3[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData3[name] = HUDCommons.BarData3[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData3[name] = HUDCommons.BarData3[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData3[name], h, bgcolor)
    HUDCommons.DrawBox(x, y, w, h, color)
end

function HUDCommons.SoftBarBackgroundMult(x, y, w, h, mult, color, bgcolor1, bgcolor2, name)
    HUDCommons.DrawBox(x, y, w, h, bgcolor)
    w = w * math.Clamp(mult, 0, 1)
	HUDCommons.BarData4[name] = HUDCommons.BarData4[name] or w

	local delta = w - HUDCommons.BarData4[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData4[name] = HUDCommons.BarData4[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData4[name] = HUDCommons.BarData4[name] + delta
	end

	HUDCommons.DrawBox(x, y, HUDCommons.BarData4[name], h, bgcolor)
    HUDCommons.DrawBox(x, y, w, h, color)
end

function HUDCommons.SoftSkyrimBar(x, y, w, h, color, name, speed)
	speed = speed or .1
	HUDCommons.BarData[name] = HUDCommons.BarData[name] or w

	local delta = w - HUDCommons.BarData[name]

	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta * speed * HUDCommons.Multipler
	else
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta
	end

	HUDCommons.DrawBox(x - HUDCommons.BarData[name] / 2, y, HUDCommons.BarData[name], h, color)
end

function HUDCommons.BarWithText(x, y, w, h, mult, bg, barbg, bar, text)
    surface.SetDrawColor(bg)
    surface.DrawRect(x - 4, y - 4, w + 8, h + 8)

    surface.SetDrawColor(barbg)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(bar)
    surface.DrawRect(x, y, w * math.Clamp(mult, 0, 1), h)

    surface.SetDrawColor(bg)
    local W, H = surface.GetTextSize(text)
    surface.DrawRect(x - 4, y - 12 - H, W + 8, H + 8)
    surface.SetTextPos(x, y - H - 8)
    surface.DrawText(text)
end

function HUDCommons.SkyrimBarWithText(x, y, w, h, mult, bg, barbg, bar, text)
    surface.SetDrawColor(bg)
    surface.DrawRect(x - 4, y - 4, w + 8, h + 8)

    surface.SetDrawColor(barbg)
    surface.DrawRect(x, y, w, h)

    local targetwidth = w * math.Clamp(mult, 0, 1)
    surface.SetDrawColor(bar)
    surface.DrawRect(x + w / 2 - targetwidth / 2, y, targetwidth, h)

    surface.SetDrawColor(bg)
    local W, H = surface.GetTextSize(text)
    surface.DrawRect(x - 4, y - 12 - H, W + 8, H + 8)
    surface.SetTextPos(x, y - H - 8)
    surface.DrawText(text)
end

function HUDCommons.SoftBarWithText(x, y, w, h, mult, bg, barbg, bar, text, barid, speed)
    speed = speed or .1
    local targetwidth = w * math.Clamp(mult, 0, 1)
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

function HUDCommons.SoftSkyrimBarWithText(x, y, w, h, mult, bg, barbg, bar, text, barid, speed)
    speed = speed or .1
    local targetwidth = w * math.Clamp(mult, 0, 1)
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

-- Same as HUDCommons.WordBox, but supports new lines
-- Similar to draw.DrawText(), but works faster
-- because it doesn't calculate tabs
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
