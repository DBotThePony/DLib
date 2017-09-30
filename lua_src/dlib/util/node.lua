
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

return function()
	local export = {}
	local usedSlots = {}

	export.slotUsagePriority = {
		{0, 0},
		{1, 0},
		{-1, 0},
		{0, 1},
		{0, -1},
		{-1, 1},
		{1, 1},
		{1, -1},
		{-1, -1},
	}

	local slotUsagePriority = export.slotUsagePriority

	function export.findNearest(x, y, size)
		usedSlots[size] = usedSlots[size] or {}
		local div = size * 24
		local ctab = usedSlots[size]
		local slotX, slotY = math.floor(x / div), math.floor(y / div)

		if ctab[slotX] == nil then
			ctab[slotX] = {}
			ctab[slotX][slotY] = true
			return x, y
		else
			local findFreeSlotX, findFreeSlotY = 0, 0

			for radius = 1, 10 do
				local success = false

				for i, priorityData in ipairs(slotUsagePriority) do
					local sx, sy = priorityData[1] * radius + slotX, priorityData[2] * radius + slotY

					if not ctab[sx] or not ctab[sx][sy] then
						findFreeSlotX, findFreeSlotY = sx, sy
						success = true
						break
					end
				end

				if success then
					break
				end
			end

			ctab[findFreeSlotX] = ctab[findFreeSlotX] or {}
			ctab[findFreeSlotX][findFreeSlotY] = true

			return findFreeSlotX * div, findFreeSlotY * div
		end
	end

	function export.findNearestAlt(x, y, size, sizeH)
		size = size or 16
		sizeH = sizeH or size
		usedSlots[size] = usedSlots[size] or {}
		local div = size * 24
		local divY = sizeH * 24
		local ctab = usedSlots[size]
		local slotX, slotY = math.floor(x / div), math.floor(y / divY)

		if ctab[slotX] == nil then
			ctab[slotX] = {}
			ctab[slotX][slotY] = true
			return x, y
		else
			local findFreeSlotX, findFreeSlotY = 0, 0

			for radius = 1, 10 do
				local success = false

				for x = radius, -radius, -1 do
					for y = radius, -radius, -1 do
						local sx, sy = x + slotX, y + slotY

						if not ctab[sx] or not ctab[sx][sy] then
							findFreeSlotX, findFreeSlotY = sx, sy
							success = true
							break
						end
					end
				end

				if success then
					break
				end
			end

			ctab[findFreeSlotX] = ctab[findFreeSlotX] or {}
			ctab[findFreeSlotX][findFreeSlotY] = true

			return findFreeSlotX * div, findFreeSlotY * divY
		end
	end

	function export.clear()
		usedSlots = {}
	end

	return export
end
