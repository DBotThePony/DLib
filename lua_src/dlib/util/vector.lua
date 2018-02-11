
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

return vector
