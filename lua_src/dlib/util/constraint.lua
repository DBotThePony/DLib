
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

local constraint = DLib.module('constraint')

local mem = {}

local function search(ent)
	if not IsValid(ent) then return end
	if mem[ent] then return end
	local all = constraint.GetTable(ent)

	mem[ent] = true

	for k = 1, #all do
		local ent1, ent2 = all[k].Ent1, all[k].Ent2

		search(ent1)
		search(ent2)
	end

	all = ent:GetChildren()

	for i, data in pairs(all) do
		search(data)
	end
end

function constraint.findAll()
	mem = {}

	search(ent)

	local result = {}

	for k, v in pairs(mem) do
		table.insert(result, k)
	end

	mem = {}

	return result
end

return constraint
