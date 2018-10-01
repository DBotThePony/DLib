
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

DLib.constraint = DLib.constraint or {}
local constraint = DLib.constraint

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
