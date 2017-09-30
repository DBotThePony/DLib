
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

local player = DLib.module('player', 'player')

player.all = player.GetAll
player.getAll = player.GetAll

function player.inRange(position, range)
	range = range ^ 2

	local output = {}

	for i, ply in ipairs(player.GetAll()) do
		if ply:GetPos():DistToSqr(position) <= range then
			table.insert(output, ply)
		end
	end

	return output
end

return player
