
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
local ipairs = ipairs
local render = render
local table = table
local assert = assert
local type = type
local CRC = util.CRC

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

local DrawCircleCache = {}
function HUDCommons.DrawCircle(x, y, radius, segments)
	x = assert(type(x) == 'number' and x, 'Invalid X'):floor()
	y = assert(type(y) == 'number' and y, 'Invalid Y'):floor()
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius'):floor()
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor()

	if radius <= 1 then return end
	if segments <= 4 then return end -- ???

	local crc = CRC(x .. y .. radius .. segments)

	if not DrawCircleCache[crc] then
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
		DrawCircleCache[crc] = poly
	end

	surface.DrawPoly(DrawCircleCache[crc])

	return DrawCircleCache[crc]
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

local DrawArcHollowCache_1 = {}
local DrawArcHollowCache_2 = {}
function HUDCommons.DrawArcHollow(x, y, radius, segments, inLength, arc, color)
	x = assert(type(x) == 'number' and x, 'Invalid X'):floor()
	y = assert(type(y) == 'number' and y, 'Invalid Y'):floor()
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius'):floor()
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor()
	inLength = assert(type(inLength) == 'number' and inLength, 'Invalid length inside'):floor()
	arc = assert(type(arc) == 'number' and arc, 'Invalid arc degree'):floor()

	if radius <= 1 then return end
	if inLength <= 1 then return end

	local crc = CRC(x .. y .. radius .. segments .. inLength .. arc)

	arc = 360 - arc
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

	if not DrawArcHollowCache_1[crc] then
		local poly = {}

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
		DrawArcHollowCache_1[crc] = poly
	end

	surface.DrawPoly(DrawArcHollowCache_1[crc])

	if arc > 180 then
		deg = arc - 180

		if not DrawArcHollowCache_2[crc] then
			local poly = {}

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
			DrawArcHollowCache_2[crc] = poly
		end

		surface.DrawPoly(DrawArcHollowCache_2[crc])
	end

	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

	draw.NoTexture()
	surface.SetDrawColor(color)
	local poly = HUDCommons.DrawCircle(x, y, radius, segments)

	render.ClearStencil()
	render.SetStencilEnable(false)

	return poly
end

local DrawArcHollow2Cache = {}
function HUDCommons.DrawArcHollow2(x, y, radius, segments, inLength, arc1, arc2, color)
	x = assert(type(x) == 'number' and x, 'Invalid X'):floor()
	y = assert(type(y) == 'number' and y, 'Invalid Y'):floor()
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius'):floor()
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor()
	inLength = assert(type(inLength) == 'number' and inLength, 'Invalid length inside'):floor()
	arc1 = assert(type(arc1) == 'number' and arc1, 'Invalid arc1 degree'):floor()
	arc2 = assert(type(arc2) == 'number' and arc2, 'Invalid arc2 degree'):floor()

	if radius <= 1 then return end
	if inLength <= 1 then return end

	local crc = CRC(x .. y .. radius .. segments .. inLength .. arc1 .. arc2)

	local center = radius / 2
	local inRadius = radius - inLength * 2
	local centerIn = inRadius / 2

	render.SetStencilEnable(true)
	render.ClearStencil()

	render.SetStencilReferenceValue(1)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.SetStencilCompareFunction(STENCIL_ALWAYS)

	surface.SetMaterial(stencilMat)
	surface.SetDrawColor(0, 0, 0, 255)
	HUDCommons.DrawCircle(x + inLength / 2, y + inLength / 2, radius - inLength, segments)

	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

	draw.NoTexture()
	surface.SetDrawColor(color)

	if not DrawArcHollow2Cache[crc] then
		local poly = {}

		table.insert(poly, {
			x = center,
			y = center,
		})

		for i = 0, segments do
			local progress = i / segments
			local ang = progress * -arc2 - arc1

			table.insert(poly, {
				x = center + ang:rad():sin() * center,
				y = center + ang:rad():cos() * center,
			})
		end

		table.insert(poly, {
			x = center,
			y = center,
		})

		HUDCommons.TranslatePolyMatrix(poly, x, y)
		DrawArcHollow2Cache[crc] = poly
	end

	surface.DrawPoly(DrawArcHollow2Cache[crc])

	render.ClearStencil()
	render.SetStencilEnable(false)

	return DrawArcHollow2Cache[crc]
end

function HUDCommons.DrawCircleHollow(x, y, radius, segments, inLength, color)
	x = assert(type(x) == 'number' and x, 'Invalid X'):floor()
	y = assert(type(y) == 'number' and y, 'Invalid Y'):floor()
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius'):floor()
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor()
	inLength = assert(type(inLength) == 'number' and inLength, 'Invalid length inside'):floor()

	if radius <= 1 then return end
	if inLength <= 1 then return end

	local crc = CRC(x .. y .. radius .. segments .. inLength)

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
	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

	draw.NoTexture()
	surface.SetDrawColor(color)
	poly = HUDCommons.DrawCircle(x, y, radius, segments)

	render.ClearStencil()
	render.SetStencilEnable(false)

	return poly
end

local function cleanup()
	DrawCircleCache = {}
	DrawArcHollow2Cache = {}
	DrawArcHollowCache_1 = {}
	DrawArcHollowCache_2 = {}
end

timer.Create('DLib.PolyCacheCleanup', 400, 0, cleanup)
