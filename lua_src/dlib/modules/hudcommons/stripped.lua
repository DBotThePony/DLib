
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

--[[
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
