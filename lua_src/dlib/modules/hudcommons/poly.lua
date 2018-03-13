
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
local ipairs = ipairs
local render = render
local table = table

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

	HUDCommons.TranslatePolyMatrix(poly, x, y)
	surface.DrawPoly(poly)

	return poly
end

function HUDCommons.DrawPolyFrame(polydata)
	local x, y

	HUDCommons.DrawCircle(polydata[1].x - 4, polydata[1].y - 4, 8, 16)

	for i, vertex in ipairs(polydata) do
		local X, Y = vertex.x, vertex.y
		x = x or X
		y = y or Y
		surface.DrawLine(x, y, X, Y)
		x = X
		y = Y
	end

	HUDCommons.DrawCircle(x - 6, y - 6, 12, 16)
end

-- function HUDCommons.DrawArcHollow(x, y, radius, segments, inLength, arc)
-- 	local poly = {}
-- 	local center = radius / 2
-- 	local inRadius = radius - inLength
-- 	local centerIn = inRadius / 2

-- 	-- outer
-- 	for i = 1, segments do
-- 		if i ~= segments then
-- 			local progress = i / segments
-- 			local ang = progress * -arc

-- 			table.insert(poly, {
-- 				x = center + ang:rad():sin() * center,
-- 				y = center + ang:rad():cos() * center,
-- 			})
-- 		end
-- 	end

-- 	-- inner
-- 	for i = 1, segments do
-- 		if i ~= segments then
-- 			local progress = 1 - i / segments
-- 			local ang = progress * -arc

-- 			table.insert(poly, {
-- 				x = center + ang:rad():sin() * centerIn,
-- 				y = center + ang:rad():cos() * centerIn,
-- 			})
-- 		end
-- 	end

-- 	table.insert(poly, {
-- 		x = center + (0):sin() * center,
-- 		y = center + (0):cos() * center,
-- 	})

-- 	draw.NoTexture()
-- 	HUDCommons.TranslatePolyMatrix(poly, x, y)
-- 	surface.SetDrawColor(255, 255, 255)
-- 	surface.DrawPoly(poly)
-- 	surface.SetDrawColor(80, 80, 80)
-- 	HUDCommons.DrawPolyFrame(poly)

-- 	return poly
-- end

local STENCIL_KEEP = STENCIL_KEEP
local STENCIL_REPLACE = STENCIL_REPLACE
local STENCIL_ALWAYS = STENCIL_ALWAYS
local STENCIL_NOTEQUAL = STENCIL_NOTEQUAL

local stencilMat = CreateMaterial('dlib_arc_white', 'UnlitGeneric', {
	['$basetexture'] = 'models/debug/debugwhite',
	['$alpha'] = '0',
	['$translucent'] = '1',
})

function HUDCommons.DrawArcHollow(x, y, radius, segments, inLength, arc, color)
	arc = 360 - arc
	local poly = {}
	local center = radius / 2
	local inRadius = radius - inLength * 2
	local centerIn = inRadius / 2

	render.SetStencilEnable(true)

	render.SetStencilReferenceValue(1)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.ClearStencil()

	render.SetStencilCompareFunction(STENCIL_ALWAYS)

	surface.SetMaterial(stencilMat)
	surface.SetDrawColor(0, 0, 0, 255)
	HUDCommons.DrawCircle(x + inLength / 2, y + inLength / 2, radius - inLength, segments)

	local deg = arc

	if arc > 180 then
		deg = 180
	end

	table.insert(poly, {
		x = center,
		y = center,
	})

	for i = 0, 20 do
		local progress = i / 20
		local ang = progress * -deg

		table.insert(poly, {
			x = center + ang:rad():sin() * center * 1.1,
			y = center + ang:rad():cos() * center * 1.1,
		})
	end

	table.insert(poly, {
		x = center,
		y = center,
	})

	HUDCommons.TranslatePolyMatrix(poly, x, y)
	surface.DrawPoly(poly)

	if arc > 180 then
		deg = arc - 180
		poly = {}

		table.insert(poly, {
			x = center,
			y = center,
		})

		for i = 0, 20 do
			local progress = i / 20
			local ang = progress * -deg - 180

			table.insert(poly, {
				x = center + ang:rad():sin() * center * 1.1,
				y = center + ang:rad():cos() * center * 1.1,
			})
		end

		table.insert(poly, {
			x = center,
			y = center,
		})

		HUDCommons.TranslatePolyMatrix(poly, x, y)
		surface.DrawPoly(poly)
	end

	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

	draw.NoTexture()
	surface.SetDrawColor(color)
	poly = HUDCommons.DrawCircle(x, y, radius, segments)

	render.ClearStencil()
	render.SetStencilEnable(false)

	return poly
end

function HUDCommons.DrawArcHollow2(x, y, radius, segments, inLength, arc1, arc2, color)
	local poly = {}
	local center = radius / 2
	local inRadius = radius - inLength * 2
	local centerIn = inRadius / 2

	render.SetStencilEnable(true)

	render.SetStencilReferenceValue(1)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.ClearStencil()

	render.SetStencilCompareFunction(STENCIL_ALWAYS)

	surface.SetMaterial(stencilMat)
	surface.SetDrawColor(0, 0, 0, 255)
	HUDCommons.DrawCircle(x + inLength / 2, y + inLength / 2, radius - inLength, segments)

	table.insert(poly, {
		x = center,
		y = center,
	})

	for i = 0, 20 do
		local progress = i / 20
		local ang = progress * -arc2 - arc1

		table.insert(poly, {
			x = center + ang:rad():sin() * center * 1.1,
			y = center + ang:rad():cos() * center * 1.1,
		})
	end

	table.insert(poly, {
		x = center,
		y = center,
	})

	HUDCommons.TranslatePolyMatrix(poly, x, y)
	surface.DrawPoly(poly)

	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

	draw.NoTexture()
	surface.SetDrawColor(color)
	poly = HUDCommons.DrawCircle(x, y, radius, segments)

	render.ClearStencil()
	render.SetStencilEnable(false)

	return poly
end

function HUDCommons.DrawCircleHollow(x, y, radius, segments, inLength, color)
	local poly = {}
	local center = radius / 2
	local inRadius = radius - inLength * 2
	local centerIn = inRadius / 2

	render.SetStencilEnable(true)

	render.SetStencilReferenceValue(1)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.ClearStencil()

	render.SetStencilCompareFunction(STENCIL_ALWAYS)

	surface.SetMaterial(stencilMat)
	surface.SetDrawColor(0, 0, 0, 255)
	HUDCommons.DrawCircle(x + inLength / 2, y + inLength / 2, radius - inLength, segments)

	HUDCommons.TranslatePolyMatrix(poly, x, y)
	surface.DrawPoly(poly)
	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

	draw.NoTexture()
	surface.SetDrawColor(color)
	poly = HUDCommons.DrawCircle(x, y, radius, segments)

	render.ClearStencil()
	render.SetStencilEnable(false)

	return poly
end
