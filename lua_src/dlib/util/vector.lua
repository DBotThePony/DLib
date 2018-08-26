
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

local vector = DLib.module('vector')
local assert = assert
local error = error
local math = math
local ipairs = ipairs
local Vector = Vector
local LVector = LVector
local type = type
local setmetatable = setmetatable

function vector.FindCenter2D(min, max)
	return max - (max - min) * 0.5
end

-- It differs from vector.Centre by checking whenever surface is the surface
function vector.FindPlaneCentre(mins, maxs)
	if mins.y == maxs.y then
		local x1 = mins.x
		local x2 = maxs.x
		local y1 = mins.z
		local y2 = maxs.z

		return Vector((x2 - x1) * 0.5, mins.y, (y2 - y1) * 0.5)
	elseif mins.x == maxs.x then
		local x1 = mins.y
		local x2 = maxs.y
		local y1 = mins.z
		local y2 = maxs.z

		return Vector(mins.x, (x2 - x1) * 0.5, (y2 - y1) * 0.5)
	elseif mins.z == maxs.z then
		local x1 = mins.x
		local x2 = maxs.x
		local y1 = mins.y
		local y2 = maxs.y

		return Vector((x2 - x1) * 0.5, (y2 - y1) * 0.5, mins.z)
	end

	error('One or both of arguments is not a 2D plane!')
end

function vector.LFindPlaneCentre(mins, maxs)
	if mins.y == maxs.y then
		local x1 = mins.x
		local x2 = maxs.x
		local y1 = mins.z
		local y2 = maxs.z

		return LVector((x2 - x1) * 0.5, mins.y, (y2 - y1) * 0.5)
	elseif mins.x == maxs.x then
		local x1 = mins.y
		local x2 = maxs.y
		local y1 = mins.z
		local y2 = maxs.z

		return LVector(mins.x, (x2 - x1) * 0.5, (y2 - y1) * 0.5)
	elseif mins.z == maxs.z then
		local x1 = mins.x
		local x2 = maxs.x
		local y1 = mins.y
		local y2 = maxs.y

		return LVector((x2 - x1) * 0.5, (y2 - y1) * 0.5, mins.z)
	end

	error('One or both of arguments is not a 2D plane!')
end

--[[
	vector.ExtractFaces: Table {
		Face:
			V1
			V2
			V3
			V4
			Normal
		...
	}
]]

function vector.ExtractFaces(mins, maxs)
	return {
		{
			Vector(mins.x, mins.y, mins.z),
			Vector(mins.x, mins.y, maxs.z),
			Vector(mins.x, maxs.y, maxs.z),
			Vector(mins.x, maxs.y, mins.z),
			Vector(-1, 0, 0)
		},
		{
			Vector(mins.x, mins.y, mins.z),
			Vector(maxs.x, mins.y, mins.z),
			Vector(maxs.x, mins.y, maxs.z),
			Vector(mins.x, mins.y, maxs.z),
			Vector(0, -1, 0)
		},
		{
			Vector(mins.x, maxs.y, mins.z),
			Vector(maxs.x, maxs.y, mins.z),
			Vector(maxs.x, maxs.y, maxs.z),
			Vector(mins.x, maxs.y, maxs.z),
			Vector(0, 1, 0)
		},
		{
			Vector(maxs.x, mins.y, mins.z),
			Vector(maxs.x, mins.y, maxs.z),
			Vector(maxs.x, maxs.y, maxs.z),
			Vector(maxs.x, maxs.y, mins.z),
			Vector(1, 0, 0)
		},
		{
			Vector(mins.x, mins.y, maxs.z),
			Vector(maxs.x, mins.y, maxs.z),
			Vector(maxs.x, maxs.y, maxs.z),
			Vector(mins.x, maxs.y, maxs.z),
			Vector(0, 0, 1)
		},
		{
			Vector(mins.x, mins.y, mins.z),
			Vector(maxs.x, mins.y, mins.z),
			Vector(maxs.x, maxs.y, mins.z),
			Vector(mins.x, maxs.y, mins.z),
			Vector(0, 0, -1)
		},
	}
end

function vector.LExtractFaces(mins, maxs)
	return {
		{
			LVector(mins.x, mins.y, mins.z),
			LVector(mins.x, mins.y, maxs.z),
			LVector(mins.x, maxs.y, maxs.z),
			LVector(mins.x, maxs.y, mins.z),
			LVector(-1, 0, 0)
		},
		{
			LVector(mins.x, mins.y, mins.z),
			LVector(maxs.x, mins.y, mins.z),
			LVector(maxs.x, mins.y, maxs.z),
			LVector(mins.x, mins.y, maxs.z),
			LVector(0, -1, 0)
		},
		{
			LVector(mins.x, maxs.y, mins.z),
			LVector(maxs.x, maxs.y, mins.z),
			LVector(maxs.x, maxs.y, maxs.z),
			LVector(mins.x, maxs.y, maxs.z),
			LVector(0, 1, 0)
		},
		{
			LVector(maxs.x, mins.y, mins.z),
			LVector(maxs.x, mins.y, maxs.z),
			LVector(maxs.x, maxs.y, maxs.z),
			LVector(maxs.x, maxs.y, mins.z),
			LVector(1, 0, 0)
		},
		{
			LVector(mins.x, mins.y, maxs.z),
			LVector(maxs.x, mins.y, maxs.z),
			LVector(maxs.x, maxs.y, maxs.z),
			LVector(mins.x, maxs.y, maxs.z),
			LVector(0, 0, 1)
		},
		{
			LVector(mins.x, mins.y, mins.z),
			LVector(maxs.x, mins.y, mins.z),
			LVector(maxs.x, maxs.y, mins.z),
			LVector(mins.x, maxs.y, mins.z),
			LVector(0, 0, -1)
		},
	}
end

--[[
	vector.ExtractFacesAndCentre: Table {
		Face:
			V1
			V2
			V3
			V4
			Normal
			Centre
		...
	}
]]


function vector.ExtractFacesAndCentre(mins, maxs)
	local find = vector.ExtractFaces(mins, maxs)

	for i, data in ipairs(find) do
		data[6] = vector.Centre(data[1], data[3])
	end

	return find
end

function vector.FindQuadSize(V1, V2, V3, V4)
	if math.equal(V1.x, V2.x, V3.x, V4.x) then
		local minX = math.min(V1.y, V2.y, V3.y, V4.y)
		local maxX = math.max(V1.y, V2.y, V3.y, V4.y)
		local minY = math.min(V1.z, V2.z, V3.z, V4.z)
		local maxY = math.max(V1.z, V2.z, V3.z, V4.z)

		return maxX - minX, maxY - minY
	elseif math.equal(V1.y, V2.y, V3.y, V4.y) then
		local minX = math.min(V1.x, V2.x, V3.x, V4.x)
		local maxX = math.max(V1.x, V2.x, V3.x, V4.x)
		local minY = math.min(V1.z, V2.z, V3.z, V4.z)
		local maxY = math.max(V1.z, V2.z, V3.z, V4.z)

		return maxX - minX, maxY - minY
	elseif math.equal(V1.z, V2.z, V3.z, V4.z) then
		local minX = math.min(V1.x, V2.x, V3.x, V4.x)
		local maxX = math.max(V1.x, V2.x, V3.x, V4.x)
		local minY = math.min(V1.y, V2.y, V3.y, V4.y)
		local maxY = math.max(V1.y, V2.y, V3.y, V4.y)

		return maxX - minX, maxY - minY
	end

	error('No proper flat surface detected!')
end

function vector.Centre(mins, maxs)
	local deltax = maxs.x - mins.x
	local deltay = maxs.y - mins.y
	local deltaz = maxs.z - mins.z
	return Vector(mins.x + deltax * 0.5, mins.y + deltay * 0.5, mins.z + deltaz * 0.5)
end

function vector.LCentre(mins, maxs)
	local deltax = maxs.x - mins.x
	local deltay = maxs.y - mins.y
	local deltaz = maxs.z - mins.z
	return LVector(mins.x + deltax * 0.5, mins.y + deltay * 0.5, mins.z + deltaz * 0.5)
end

--[[
	Give two vectors (e.g. mins and maxs) and origin position
	origin position is Vector(0, 0, 0) if mins and maxs are WORLDSPACE vectors
	if mins and maxs are local vectors, origin is probably position of entity
	which these vectors are belong to
	This function will return a table with
		{A, B, C, D} values that represent
		Ax + By + Cz + D = 0
]]

function vector.CalculateSurfaceFromTwoPoints(mins, maxs, zero)
	zero = zero or LVector(0, 0, 0)

	local x0, y0, z0 = zero.x, zero.y, zero.z
	local x1, y1, z1 = mins.x, mins.y, mins.z
	local x2, y2, z2 = maxs.x, maxs.y, maxs.z

	local a1 = -x0
	local a2 = -y0
	local a3 = -z0

	local b1 = x1
	local b2 = y1
	local b3 = z1

	local c1 = x2
	local c2 = y2
	local c3 = z2

	local m1 = b2 * c3
	local m2 = b1 * c2
	local m3 = b3 * c1
	local m4 = b2 * c1
	local m5 = b3 * c2
	local m6 = b1 * c3

	local X, Y, Z, D = 0, 0, 0, 0

	-- m1
	X = X + m1
	D = D + a1 * m1

	-- m2
	Z = Z + m2
	D = D + a3 * m2

	-- m3
	Y = Y + m3
	D = D + a2 * m3

	-- m4
	Z = Z - m4
	D = D - a3 * m4

	-- m5
	X = X - m5
	D = D - a1 * m5

	-- m6
	Y = Y - m6
	D = D - a2 * m6

	return {X, Y, Z, D}
end

function vector.DistanceFromPointToSurface(point, surfaceTable)
	local A, B, C, D = surfaceTable[1], surfaceTable[2], surfaceTable[3], surfaceTable[4]
	local Mx, My, Mz = point.x, point.y, point.z
	local toDivide = math.abs(A * Mx + B * My + C * Mz + D)
	local square = math.sqrt(math.pow(A, 2) + math.pow(B, 2) + math.pow(C, 2))
	return toDivide / square
end

function vector.DistanceFromPointToPlane(point, mins, maxs)
	return vector.DistanceFromPointToSurface(point, vector.CalculateSurfaceFromTwoPoints(mins, maxs))
end

function vector.IsPositionInsideBox(pos, mins, maxs)
	return pos.x >= mins.x and pos.x <= maxs.x and
		pos.y >= mins.y and pos.y <= maxs.y and
		pos.z >= mins.z and pos.z <= maxs.z
end

return vector
