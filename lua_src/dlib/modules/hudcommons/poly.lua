
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
local ipairs = ipairs
local render = render
local table = table
local assert = assert
local type = type
local STENCIL_NEVER = STENCIL_NEVER
local STENCIL_KEEP = STENCIL_KEEP
local STENCIL_REPLACE = STENCIL_REPLACE
local STENCIL_ALWAYS = STENCIL_ALWAYS
local STENCIL_NOTEQUAL = STENCIL_NOTEQUAL

--[[
	@doc
	@fname DLib.HUDCommons.DrawTriangle
	@args number x, number y, number w, number h, number rotate = 0

	@client

	@returns
	table: !s:PolygonVertex
]]
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

--[[
	@doc
	@fname DLib.HUDCommons.DrawCircle
	@args number x, number y, number radius, number segments = radius / 8

	@client

	@desc
	Draws a circle positioned in center of `x` and `y`
	This function is *caching* it's !s:PolygonVertex calculation results
	and thus more performance and GC friendly.
	@enddesc

	@returns
	table: !s:PolygonVertex
]]
local DrawCircleCache = {}
function HUDCommons.DrawCircle(x, y, radius, segments)
	x = assert(type(x) == 'number' and x, 'Invalid X')
	y = assert(type(y) == 'number' and y, 'Invalid Y')
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius')
	segments = segments or radius / 8
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor():max(8)

	if radius <= 1 then return end
	if segments <= 4 then return end -- ???

	local crc = x .. y .. radius .. segments

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

--[[
	@doc
	@fname DLib.HUDCommons.DrawPolyFrame
	@args table PolygonVertex, boolean drawname, boolean drawXY, boolean drawUV

	@client

	@desc
	useful for debugging shapes of !s:PolygonVertex when it doesn't draw or something
	@enddesc
]]
function HUDCommons.DrawPolyFrame(polydata, drawnum, drawXY, drawUV)
	local w, h = ScrWL(), ScrHL()
	local padding = ScreenSize(2)
	local x, y

	surface.SetFont('Default')
	surface.SetTextColor(255, 255, 255)

	HUDCommons.DrawCircle(polydata[1].x - 4, polydata[1].y - 4, 8, 16)

	for i, vertex in ipairs(polydata) do
		local X, Y = vertex.x, vertex.y
		x = x or X
		y = y or Y
		surface.DrawLine(x, y, X, Y)
		x = X
		y = Y

		if drawXY or drawUV or drawnum then
			HUDCommons.DrawCircle(x - 4, y - 4, 8, 16)
			local text = drawXY and drawUV and drawnum and
				string.format('%i:%f,%f %.2f,%.2f', i, x, y, vertex.u or 0, vertex.v or 0) or
				drawXY and drawnum and string.format('%i:%f,%f', i, x, y) or
				drawUV and drawnum and string.format('%i:%.2f,%.2f', i, vertex.u or 0, vertex.v or 0) or
				drawXY and string.format('%f,%f', x, y) or
				string.format('%.2f,%.2f', vertex.u or 0, vertex.v or 0)

			local tw, th = surface.GetTextSize(text)

			surface.SetTextPos(math.clamp(x - tw, padding, w - padding), math.clamp(y - th, padding, h - padding))
			surface.DrawText(text)
		end
	end

	HUDCommons.DrawCircle(x - 6, y - 6, 12, 16)
end

-- function HUDCommons.DrawArcHollow(x, y, radius, segments, inLength, arc)
--  local poly = {}
--  local center = radius / 2
--  local inRadius = radius - inLength
--  local centerIn = inRadius / 2

--  -- outer
--  for i = 1, segments do
--    if i ~= segments then
--      local progress = i / segments
--      local ang = progress * -arc

--      table.insert(poly, {
--        x = center + ang:rad():sin() * center,
--        y = center + ang:rad():cos() * center,
--      })
--    end
--  end

--  -- inner
--  for i = 1, segments do
--    if i ~= segments then
--      local progress = 1 - i / segments
--      local ang = progress * -arc

--      table.insert(poly, {
--        x = center + ang:rad():sin() * centerIn,
--        y = center + ang:rad():cos() * centerIn,
--      })
--    end
--  end

--  table.insert(poly, {
--    x = center + (0):sin() * center,
--    y = center + (0):cos() * center,
--  })

--  draw.NoTexture()
--  HUDCommons.TranslatePolyMatrix(poly, x, y)
--  surface.SetDrawColor(255, 255, 255)
--  surface.DrawPoly(poly)
--  surface.SetDrawColor(80, 80, 80)
--  HUDCommons.DrawPolyFrame(poly)

--  return poly
-- end

--[[
	@doc
	@fname DLib.HUDCommons.DrawArcHollow
	@args number x, number y, number radius, number segments = radius / 8, number inLength, number arcAngle, Color color

	@client

	@desc
	Draws hollow circle with line width of `inLength` and angle of `arcAngle`

	Will not work if called inside other stencil operations

	This function is *caching* it's !s:PolygonVertex calculation results
	and thus more performance and GC friendly.
	@enddesc

	@returns
	table: !s:PolygonVertex
]]
local DrawArcHollowCache_1 = {}
local DrawArcHollowCache_2 = {}
function HUDCommons.DrawArcHollow(x, y, radius, segments, inLength, arc, color)
	x = assert(type(x) == 'number' and x, 'Invalid X')
	y = assert(type(y) == 'number' and y, 'Invalid Y')
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius')
	segments = segments or radius / 8
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor():max(8)
	inLength = assert(type(inLength) == 'number' and inLength, 'Invalid length inside')
	arc = assert(type(arc) == 'number' and arc, 'Invalid arc degree'):floor()

	if radius <= 1 then return end
	if inLength <= 1 then return end

	local crc = x .. y .. radius .. segments .. inLength .. arc

	arc = 360 - arc
	local center = radius / 2
	local inRadius = radius - inLength * 2
	local centerIn = inRadius / 2

	render.SetStencilEnable(true)

	render.SetStencilReferenceValue(1)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_REPLACE)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.ClearStencil()

	render.SetStencilCompareFunction(STENCIL_NEVER)

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
	render.SetStencilFailOperation(STENCIL_KEEP)

	draw.NoTexture()
	surface.SetDrawColor(color)
	local poly = HUDCommons.DrawCircle(x, y, radius, segments)

	render.ClearStencil()
	render.SetStencilEnable(false)

	return poly
end

--[[
	@doc
	@fname DLib.HUDCommons.DrawArcHollow2
	@args number x, number y, number radius, number segments = radius / 8, number inLength, number arcAngleStart, number arcAngleEnd, Color color

	@client

	@desc
	Same as `DLib.HUDCommons.DrawArcHollow` but allows to specify start and end angles of arc

	This function is *caching* it's !s:PolygonVertex calculation results
	and thus more performance and GC friendly.
	@enddesc

	@returns
	table: !s:PolygonVertex
]]
local DrawArcHollow2Cache = {}
function HUDCommons.DrawArcHollow2(x, y, radius, segments, inLength, arc1, arc2, color)
	x = assert(type(x) == 'number' and x, 'Invalid X')
	y = assert(type(y) == 'number' and y, 'Invalid Y')
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius')
	segments = segments or radius / 8
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor():max(8)
	inLength = assert(type(inLength) == 'number' and inLength, 'Invalid length inside')
	arc1 = assert(type(arc1) == 'number' and arc1, 'Invalid arc1 degree'):floor()
	arc2 = assert(type(arc2) == 'number' and arc2, 'Invalid arc2 degree'):floor()

	if radius <= 1 then return end
	if inLength <= 1 then return end

	local crc = x .. y .. radius .. segments .. inLength .. arc1 .. arc2

	local center = radius / 2
	local inRadius = radius - inLength * 2
	local centerIn = inRadius / 2

	render.SetStencilEnable(true)
	render.ClearStencil()

	render.SetStencilReferenceValue(1)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_REPLACE)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.SetStencilCompareFunction(STENCIL_NEVER)

	surface.SetDrawColor(0, 0, 0, 255)
	HUDCommons.DrawCircle(x + inLength / 2, y + inLength / 2, radius - inLength, segments)

	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
	render.SetStencilFailOperation(STENCIL_KEEP)

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

--[[
	@doc
	@fname DLib.HUDCommons.DrawCircleHollow
	@args number x, number y, number radius, number segments = radius / 8, number inLength, Color color

	@client

	@desc
	Draws a hollow circle with line width of `inLength`
	Circle is positioned in center of `x` and `y`

	This function is *caching* it's !s:PolygonVertex calculation results
	and thus more performance and GC friendly.
	@enddesc

	@returns
	table: !s:PolygonVertex
	table: !s:PolygonVertex
]]
function HUDCommons.DrawCircleHollow(x, y, radius, segments, inLength, color)
	x = assert(type(x) == 'number' and x, 'Invalid X')
	y = assert(type(y) == 'number' and y, 'Invalid Y')
	radius = assert(type(radius) == 'number' and radius, 'Invalid Radius')
	segments = segments or radius / 8
	segments = assert(type(segments) == 'number' and segments, 'Invalid amount of segments'):floor():max(8)
	inLength = assert(type(inLength) == 'number' and inLength, 'Invalid length inside')

	if radius <= 1 then return end
	if inLength <= 1 then return end

	local crc = x .. y .. radius .. segments .. inLength

	render.SetStencilEnable(true)

	render.SetStencilReferenceValue(1)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_REPLACE)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.ClearStencil()

	render.SetStencilCompareFunction(STENCIL_NEVER)

	surface.SetDrawColor(0, 0, 0, 255)
	local poly2 = HUDCommons.DrawCircle(x + inLength / 2, y + inLength / 2, radius - inLength, segments)
	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
	render.SetStencilFailOperation(STENCIL_KEEP)

	draw.NoTexture()
	surface.SetDrawColor(color)
	local poly = HUDCommons.DrawCircle(x, y, radius, segments)

	render.ClearStencil()
	render.SetStencilEnable(false)

	return poly, poly2
end

local function cleanup()
	DrawCircleCache = {}
	DrawArcHollow2Cache = {}
	DrawArcHollowCache_1 = {}
	DrawArcHollowCache_2 = {}
end

timer.Create('DLib.PolyCacheCleanup', 400, 0, cleanup)
