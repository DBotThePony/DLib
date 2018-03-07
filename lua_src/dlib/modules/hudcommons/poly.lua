
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local HUDCommons = HUDCommons
local surface = surface
local draw = draw

function HUDCommons.DrawTriangle(x, y, w, h, rotate)
	local poly = {
		{x = w / 2, y = 0},
		{x = w, y = h},
		{x = 0, y = h},
	}

	if rotate then
		HUDCommons.RotatePolyMatrix(poly, rotate)
	end

	HUDCommons.TranslatePolyMatrix(poly, x, y)

	surface.DrawPoly(poly)
	return poly
end

function HUDCommons.DrawCircle(x, y, radius, segments)
	local poly = {}
	local center = radius / 2

	for i = 1, segments do
		local progress = i / segments
		local ang = progress * -360

		table.insert(poly, {
			x = center + ang:rad():sin() * center,
			y = center + ang:rad():cos() * center,
		})
	end

	draw.NoTexture()
	HUDCommons.TranslatePolyMatrix(poly, x, y)
	surface.DrawPoly(poly)

	return poly
end
