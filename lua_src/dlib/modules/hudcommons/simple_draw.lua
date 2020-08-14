
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
local draw = draw

--[[
	@doc
	@fname DLib.HUDCommons.DrawBox
	@args number x, number y, number w, number h, Color color = nil

	@client

	@desc
	!g:surface.SetDrawColor + !g:surface.DrawRect
	@enddesc
]]
function HUDCommons.DrawBox(x, y, w, h, color)
	if color then
		surface.SetDrawColor(color)
	end

	surface.DrawRect(x, y, w, h)
end

--[[
	@doc
	@fname DLib.HUDCommons.SimpleText
	@args string text, string font = nil, number x, number y, Color color = nil

	@client

	@desc
	doesn't support newlines or tabs
	!g:surface.SetTextColor + !g:surface.SetFont + !g:surface.SetTextPos + !g:surface.DrawText
	@enddesc
]]
function HUDCommons.SimpleText(text, font, x, y, col)
	if col then
		surface.SetTextColor(col)
	end

	if font then
		surface.SetFont(font)
	end

	surface.SetTextPos(x, y)
	surface.DrawText(text)

	return surface.GetTextSize(x, y)
end

--[[
	@doc
	@fname DLib.HUDCommons.SimpleTextRight
	@args string text, string font = nil, number x, number y, Color color = nil

	@client

	@desc
	aligns text to right
	doesn't support newlines or tabs
	!g:surface.SetTextColor + !g:surface.SetFont + !g:surface.SetTextPos + !g:surface.DrawText
	@enddesc
]]
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

--[[
	@doc
	@fname DLib.HUDCommons.SimpleTextCentered
	@args string text, string font = nil, number x, number y, Color color = nil

	@client

	@desc
	aligns text to center
	doesn't support newlines or tabs
	!g:surface.SetTextColor + !g:surface.SetFont + !g:surface.SetTextPos + !g:surface.DrawText
	@enddesc
]]
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

--[[
	@doc
	@fname DLib.HUDCommons.SkyrimBar
	@args number x, number y, number w, number h, Color color

	@client

	@desc
	`DLib.HUDCommons.DrawBox(x - w / 2, y, w, h, color)`
	@enddesc
]]
function HUDCommons.SkyrimBar(x, y, w, h, color)
	HUDCommons.DrawBox(x - w / 2, y, w, h, color)
end

--[[
	@doc
	@fname DLib.HUDCommons.WordBox
	@args string text, string font = nil, number x, number y, Color color = nil, Color boxColor = nil, boolean center = false

	@client

	@desc
	!g:draw.WordBox but
	doesn't support newlines (performance)
	allows to be centered
	font and color can be omitted
	draws flat box
	@enddesc
]]
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

--[[
	@doc
	@fname DLib.HUDCommons.VerticalBar
	@args number x, number y, number w, number h, number mult, Color color = nil

	@client
]]
function HUDCommons.VerticalBar(x, y, w, h, mult, color)
	local mult2 = 1 - mult
	y = y + h * mult2

	if color then
		surface.SetDrawColor(color)
	end

	surface.DrawRect(x, y, w, h * mult)
end

local RotatedRectCache = {}

--[[
	@doc
	@fname DLib.HUDCommons.DrawRotatedRect
	@alias surface.DrawRotatedRect
	@args number x, number y, number w, number h, number rotation

	@client

	@desc
	This function is *caching* it's !s:PolygonVertex calculation results
	and thus more performance and GC friendly.
	@enddesc

	@returns
	table: !s:PolygonVertex
]]
function HUDCommons.DrawRotatedRect(x, y, w, h, deg)
	draw.NoTexture()

	local crc = x .. '_' .. y .. '_' .. w .. '_' .. h .. '_' .. deg

	if not RotatedRectCache[crc] then
		local rect = {
			{x = 0, y = 0},
			{x = w, y = 0},
			{x = w, y = h},
			{x = 0, y = h},
		}

		HUDCommons.RotatePolyMatrix(rect, deg)
		HUDCommons.TranslatePolyMatrix(rect, x, y)
		RotatedRectCache[crc] = rect
	end

	surface.DrawPoly(RotatedRectCache[crc])
	return rect
end

surface.DrawRotatedRect = HUDCommons.DrawRotatedRect

--[[
	@doc
	@fname DLib.HUDCommons.DrawCheckboxChecked
	@args number x, number y, number w, number h, Color colorOrRed = nil, number g = nil, number b = nil, number a = nil

	@client
]]
function HUDCommons.DrawCheckboxChecked(x, y, w, h, color, g, b, a)
	if color then
		surface.SetDrawColor(color, g, b, a)
	end

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.2, y + size * 0.7, size * 0.5, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * .4, y + size * .47 + size * 0.6, size, size * 0.15, -45)
end

--[[
	@doc
	@fname DLib.HUDCommons.DrawCheckboxUnchecked
	@args number x, number y, number w, number h, Color colorOrRed = nil, number g = nil, number b = nil, number a = nil

	@client
]]
function HUDCommons.DrawCheckboxUnchecked(x, y, w, h, color, g, b, a)
	if color then
		surface.SetDrawColor(color, g, b, a)
	end

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.25, y + size * 0.15, size * 1.2, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * 0.15, y + size, size * 1.2, size * 0.15, -45)
end
