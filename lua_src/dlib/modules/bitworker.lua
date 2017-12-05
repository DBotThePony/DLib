
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
local type = type
local ipairs = ipairs

local function isValidNumber(numIn)
	return type(numIn) == 'number' and numberIn == numberIn and numberIn ~= math.huge and numberIn ~= -math.huge
end

function bitworker.IntegerToBinary(numberIn)
	if not isValidNumber(numberIn) then
		return {0, 0}
	end

	local bits = {}
	local sign = numberIn >= 0 and 0 or 1
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

function bitworker.BinaryToUInteger(inputTable)
	local amount = #inputTable
	local output = 0

	for i = 1, amount do
		if inputTable[i] > 0 then
			output = output + math.pow(2, amount - i)
		end
	end

	return output
end

function bitworker.BinaryToInteger(inputTable)
	local direction = inputTable[1]
	local amount = #inputTable
	local output = 0

	for i = 2, amount do
		if inputTable[i] > 0 then
			output = output + math.pow(2, amount - i)
		end
	end

	if direction == 0 then
		return output
	else
		return -output
	end
end

function bitworker.UIntegerToBinary(numberIn)
	if not isValidNumber(numberIn) then
		return {0}
	end

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

function bitworker.IntegerToBinaryFixed(numberIn, bitsOut)
	local maximal = math.pow(2, bitsOut) - 1

	if numberIn < 0 then
		numberIn = numberIn + maximal
	end

	numberIn = math.min(maximal, numberIn)
	local output = bitworker.UIntegerToBinary(numberIn)
	local bits = {}

	for i = 1, bitsOut - #output do
		table.insert(bits, 0)
	end

	for i = 1, math.min(#output, bitsOut) do
		table.insert(bits, output[i])
	end

	return bits
end

function bitworker.BinaryToIntegerFixed(bitsIn)
	local bitsOut = #bitsIn
	local maximalDiv = math.pow(2, bitsOut - 1) - 1
	local value = bitworker.BinaryToUInteger(bitsIn)

	if value > maximalDiv then
		value = value - math.pow(2, bitsOut) + 1
	end

	return value
end

function bitworker.FloatToBinary(numberIn, precision)
	if not isValidNumber(numberIn) then
		local bits = {0, 0}

		for i = 1, precision do
			table.insert(bits, 0)
		end

		return bits
	end

	precision = precision or 6
	local float = math.abs(numberIn) % 1
	local bits
	local dir = numberIn < 0

	if dir then
		bits = bitworker.IntegerToBinary(numberIn + float)
	else
		bits = bitworker.IntegerToBinary(numberIn - float)
	end

	local lastMult = float

	for i = 1, precision do
		local mult = lastMult * 2

		if mult >= 1 then
			table.insert(bits, 1)
			mult = mult - 1
		else
			table.insert(bits, 0)
		end

		lastMult = mult
	end

	return bits
end

function bitworker.NumberToMantiss(numberIn, bitsAllowed)
	if not isValidNumber(numberIn) then
		local bits = {}

		for i = 1, bitsAllowed do
			table.insert(bits, 0)
		end

		return bits
	end

	local bits = {}
	local exp = 0
	numberIn = math.abs(numberIn)
	local lastMult = numberIn % 1
	numberIn = numberIn - lastMult

	while numberIn >= 1 and bitsAllowed > #bits do
		local div = numberIn / 2
		local num = div % 1

		if num ~= 0 then
			table.insert(bits, 1)
		else
			table.insert(bits, 0)
		end

		numberIn = numberIn - div - num
		exp = exp + 1
	end

	bits = table.flip(bits)

	while bitsAllowed > #bits do
		lastMult = lastMult * 2

		if lastMult >= 1 then
			table.insert(bits, 1)
			lastMult = lastMult - 1
		else
			table.insert(bits, 0)
		end
	end

	return bits, exp
end

function bitworker.MantissToNumber(bitsIn, shiftNum)
	shiftNum = shiftNum or 0
	local num = 0

	for i = 1, #bitsIn do
		if bitsIn[i] ~= 0 then
			num = num + math.pow(2, -i + shiftNum)
		end
	end

	return num
end

function bitworker.BinaryToFloat(inputTable, precision)
	local amount = #inputTable
	precision = precision or 6

	local integerPart = {}
	for i = 1, amount - precision do
		table.insert(integerPart, inputTable[i])
	end

	local integer = bitworker.BinaryToInteger(integerPart)
	local float = 0

	for i = amount - precision + 1, amount do
		if inputTable[i] > 0 then
			float = float + math.pow(2, amount - precision - i)
		end
	end

	if integer < 0 then
		return integer - float
	else
		return integer + float
	end
end

-- final range is bitsExponent + bitsMantissa + 2
-- where 2 is two bits which one forwards number sign and one forward exponent sign
function bitworker.FloatToBinaryIEEE(numberIn, bitsExponent, bitsMantissa)
	if not isValidNumber(numberIn) then
		local bits = {}

		for i = 0, bitsExponent + bitsMantissa do
			table.insert(bits, 0)
		end

		return bits
	end

	local bits = {numberIn >= 0 and 0 or 1}
	local mantissa, exp = bitworker.NumberToMantiss(numberIn, bitsMantissa)
	local expBits = bitworker.IntegerToBinary(exp)

	table.insert(bits, table.remove(expBits, 1))

	for i = 1, bitsExponent - #expBits do
		table.insert(bits, 0)
	end

	for i = 1, math.min(bitsExponent, #expBits) do
		table.insert(bits, expBits[i])
	end

	table.append(bits, mantissa)

	return bits
end

function bitworker.BinaryToFloatIEEE(bitsIn, bitsExponent, bitsMantissa)
	local forward = bitsIn[1]
	local exponent = table.gcopyRange(bitsIn, 2, 2 + bitsExponent)
	local exp = bitworker.BinaryToInteger(exponent)
	local mantissa = table.gcopyRange(bitsIn, 2 + bitsExponent + 1)

	local value = bitworker.MantissToNumber(mantissa, exp)

	if forward == 0 then
		return value
	else
		return -value
	end
end

return bitworker
