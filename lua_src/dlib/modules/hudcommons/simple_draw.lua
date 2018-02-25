
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
local draw = draw

function HUDCommons.DrawBox(x, y, w, h, color)
	if color then
		surface.SetDrawColor(color)
	end

	surface.DrawRect(x, y, w, h)
end

function HUDCommons.SimpleText(text, font, x, y, col)
	if col then
		surface.SetTextColor(col)
	end

	if font then
		surface.SetFont(font)
	end

	surface.SetTextPos(x, y)
	surface.DrawText(text)
end

function HUDCommons.SimpleTextRight(text, font, x, y, col)
	if col then
		surface.SetTextColor(col)
	end

	if font then
		surface.SetFont(font)
	end

	local w, h = surface.GetTextSize(text)
	surface.SetTextPos(x - w, y)
	surface.DrawText(text)
	return w, h
end

function HUDCommons.SkyrimBar(x, y, w, h, color)
	HUDCommons.DrawBox(x - w / 2, y, w, h, color)
end

function HUDCommons.WordBox(text, font, x, y, col, colBox, center)
	if font then
		surface.SetFont(font)
	end

	if col then
		surface.SetTextColor(col)
	end

	local w, h = surface.GetTextSize(text)

	if center then
		x = x - w / 2
	end

	HUDCommons.DrawBox(x - 4, y - 2, w + 8, h + 4, colBox)
	surface.SetTextPos(x, y)
	surface.DrawText(text)

    return w, h
end

function HUDCommons.VerticalBar(x, y, w, h, mult, color)
	local mult2 = 1 - mult
	y = y + h * mult2
	if color then
		surface.SetDrawColor(color)
	end

	surface.DrawRect(x, y, w, h * mult)
end

function HUDCommons.DrawRotatedRect(x, y, w, h, deg)
	draw.NoTexture()

	local rect = {
		{x = 0, y = 0},
		{x = w, y = 0},
		{x = w, y = h},
		{x = 0, y = h},
	}

	HUDCommons.RotatePolyMatrix(rect, deg)
	HUDCommons.TranslatePolyMatrix(rect, x, y)
	surface.DrawPoly(rect)
	return rect
end

surface.DrawRotatedRect = HUDCommons.DrawRotatedRect

function HUDCommons.DrawCheckboxChecked(x, y, w, h, color, g, b, a)
	if color then
		surface.SetDrawColor(color, g, b, a)
	end

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.2, y + size * 0.7, size * 0.5, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * .4, y + size * .47 + size * 0.6, size, size * 0.15, -45)
end

function HUDCommons.DrawCheckboxUnchecked(x, y, w, h, color, g, b, a)
	if color then
		surface.SetDrawColor(color, g, b, a)
	end

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.25, y + size * 0.15, size * 1.2, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * 0.15, y + size, size * 1.2, size * 0.15, -45)
end

function HUDCommons.DrawTriangle(x, y, w, h, rotate)
	local poly = {
		{x = x + w / 2, y = y},
		{x = x + w, y = y + h},
		{x = x, y = y + h},
	}

	if rotate then
		HUDCommons.RotatePolyMatrix(poly, rotate)
	end

	surface.DrawPoly(poly)
	return poly
end
