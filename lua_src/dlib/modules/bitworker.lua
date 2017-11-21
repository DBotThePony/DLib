
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

local table = table
local DLib = DLib
local math = math
local bitworker = DLib.module('bitworker')

function bitworker.IntegerToBinary(numberIn)
	local bits = {}
	local sign = numberIn > 0 and 0 or 1
	numberIn = math.abs(numberIn)

	repeat
		local div = numberIn / 2
		local num = div % 1

		if num ~= 0 then
			table.insert(bits, 1)
		else
			table.insert(bits, 0)
		end

		numberIn = numberIn - div - num
	until numberIn < 1

	table.insert(bits, sign)

	return table.flip(bits)
end

function bitworker.UIntegerToBinary(numberIn)
	local bits = {}
	numberIn = math.abs(numberIn)

	repeat
		local div = numberIn / 2
		local num = div % 1

		if num ~= 0 then
			table.insert(bits, 1)
		else
			table.insert(bits, 0)
		end

		numberIn = numberIn - div - num
	until numberIn < 1

	return table.flip(bits)
end

function bitworker.FloatToBinary(numberIn, precision)
	precision = precision or 6
	local bits = bitworker.IntegerToBinary(numberIn)
	local float = numberIn % 1
	local lastMult = float

	for i = 1, precision do
		local mult = lastMult * 2

		if mult > 1 then
			table.insert(bits, 1)
			mult = mult - 1
		else
			table.insert(bits, 0)
		end

		lastMult = mult
	end

	return bits
end

return bitworker
