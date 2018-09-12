
-- Copyright (C) 2017-2018 DBot

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

function HUDCommons.SimpleTextCentered(text, font, x, y, col)
	if col then
		surface.SetTextColor(col)
	end

	if font then
		surface.SetFont(font)
	end

	local w, h = surface.GetTextSize(text)
	surface.SetTextPos(x - w / 2, y)
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

	HUDCommons.DrawBox(x - w * 0.2, y - h * 0.1, w * 1.4, h * 1.2, colBox)
	surface.SetTextPos(x, y)
	surface.DrawText(text)

    return w * 1.4, h * 1.2
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
