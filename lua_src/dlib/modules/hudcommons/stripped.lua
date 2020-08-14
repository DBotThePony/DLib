
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

--[[
	@doc
	@fname DLib.HUDCommons.VerticalStripped
	@args table drawdata

	@client

	@desc
	{
		spacing = 2,
		spacingColor = Color(0, 0, 0, 0),
		color = Color(255, 255, 255),
		bgcolor = Color(100, 100, 100),
		width = 10,
		bars = 10,
        height = 5,
		x = 0,
		y = 0,
		mult = 0.5
	}
	@enddesc
]]
function HUDCommons.VerticalStripped(drawData)
	local spacing = drawData.spacing or 2
	local spacingColor = drawData.spacingColor or Color(0, 0, 0, 0)
	local color = drawData.color or Color(255, 255, 255)
	local bgcolor = drawData.bgcolor or Color(100, 100, 100)
	local width = drawData.width or 10
	local bars = drawData.bars or 10
	local height = drawData.height or 5
	local x = drawData.x or 0
	local y = drawData.y or 0
	local mult = math.Clamp(drawData.mult or 0.5, 0, 1)

	local middleBar = math.floor(bars * mult + 0.5)
    local calcHeight = spacing * (bars - 1) + bars * height
    local middle = calcHeight * mult
    local walkedDist = 0

	for i = 1, bars do
		if i ~= 1 then
			surface.SetDrawColor(spacingColor)
			surface.DrawRect(x, y, width, spacing)
			y = y + spacing
			walkedDist = walkedDist + spacing
		end

        if i < middleBar then
            surface.SetDrawColor(color)
			surface.DrawRect(x, y, width, height)
			y = y + height
			walkedDist = walkedDist + height
        elseif i > middleBar then
            surface.SetDrawColor(bgcolor)
			surface.DrawRect(x, y, width, height)
			y = y + height
        else
            surface.SetDrawColor(bgcolor)
			surface.DrawRect(x, y, width, height)
            local toDraw = math.min(middle - walkedDist, height)
            surface.SetDrawColor(color)
			surface.DrawRect(x, y, width, toDraw)
			y = y + height
        end
	end
end
