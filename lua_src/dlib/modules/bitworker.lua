
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


local table = table
local DLib = DLib
local math = math
local bitworker = DLib.module('bitworker')
local type = type
local ipairs = ipairs

local function isValidNumber(numIn)
	return type(numIn) == 'number' and numIn == numIn and numIn ~= math.huge and numIn ~= -math.huge
end

local function table_insert(tabIn, val)
	tabIn[#tabIn + 1] = val
end

local function fixedBits(tabIn, amount)
	local bits = {}

	for i = 1, amount - #tabIn do
		table_insert(bits, 0)
	end

	for i = 1, math.min(#tabIn, amount) do
		table_insert(bits, tabIn[i])
	end

	return bits
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
			table_insert(bits, 1)
		else
			table_insert(bits, 0)
		end

		numberIn = numberIn - div - num
	until numberIn < 1

	table_insert(bits, sign)

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
			table_insert(bits, 1)
		else
			table_insert(bits, 0)
		end

		numberIn = numberIn - div - num
	until numberIn < 1

	return table.flip(bits)
end

function bitworker.IntegerToBinaryFixed(numberIn, bitsOut)
	local maximal = math.pow(2, bitsOut)

	if numberIn < 0 then
		numberIn = numberIn + maximal
	end

	numberIn = math.min(maximal, numberIn)
	local output = bitworker.UIntegerToBinary(numberIn)
	local bits = {}

	for i = 1, bitsOut - #output do
		table_insert(bits, 0)
	end

	for i = 1, math.min(#output, bitsOut) do
		table_insert(bits, output[i])
	end

	return bits
end

function bitworker.BinaryToIntegerFixed(bitsIn)
	local bitsOut = #bitsIn
	local maximalDiv = math.pow(2, bitsOut - 1) - 1
	local value = bitworker.BinaryToUInteger(bitsIn)

	if value > maximalDiv then
		value = value - math.pow(2, bitsOut)
	end

	return value
end

function bitworker.FloatToBinary(numberIn, precision)
	if not isValidNumber(numberIn) then
		local bits = {0, 0}

		for i = 1, precision do
			table_insert(bits, 0)
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
			table_insert(bits, 1)
			mult = mult - 1
		else
			table_insert(bits, 0)
		end

		lastMult = mult
	end

	return bits
end

function bitworker.NumberToMantiss(numberIn, bitsAllowed)
	if not isValidNumber(numberIn) then
		local bits = {}

		for i = 1, bitsAllowed do
			table_insert(bits, 0)
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
			table_insert(bits, 1)
		else
			table_insert(bits, 0)
		end

		numberIn = numberIn - div - num
		exp = exp + 1
	end

	bits = table.flip(bits)

	while bitsAllowed > #bits do
		lastMult = lastMult * 2

		if lastMult >= 1 then
			table_insert(bits, 1)
			lastMult = lastMult - 1
		else
			table_insert(bits, 0)
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
		table_insert(integerPart, inputTable[i])
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
			table_insert(bits, 0)
		end

		return bits
	end

	local bits = {numberIn >= 0 and 0 or 1}
	local mantissa, exp = bitworker.NumberToMantiss(numberIn, bitsMantissa)
	local expBits = fixedBits(bitworker.UIntegerToBinary(exp + 127), bitsExponent)

	table.append(bits, expBits)
	table.append(bits, mantissa)

	return bits
end

function bitworker.BinaryToFloatIEEE(bitsIn, bitsExponent, bitsMantissa)
	local forward = bitsIn[1]
	local exponent = table.gcopyRange(bitsIn, 2, 2 + bitsExponent - 1)
	local exp = bitworker.BinaryToUInteger(exponent)
	local mantissa = table.gcopyRange(bitsIn, 2 + bitsExponent)

	local value = bitworker.MantissToNumber(mantissa, exp - 127)

	if forward == 0 then
		return value
	else
		return -value
	end
end

return bitworker
