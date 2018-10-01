
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

DLib.bitworker = DLib.bitworker or {}
local table = table
local DLib = DLib
local math = math
local bitworker = DLib.bitworker
local type = type
local ipairs = ipairs

local function isValidNumber(numIn)
	return type(numIn) == 'number' and numIn == numIn and numIn ~= math.huge and numIn ~= -math.huge
end

local function table_insert(tabIn, val)
	tabIn[#tabIn + 1] = val
end

function bitworker.IntegerToBinary(numberIn, bitsNum)
	if not isValidNumber(numberIn) then
		local vr = {}

		for i = 1, bitsNum do
			vr[i] = 0
		end

		return vr
	end

	local bits = {}
	local sign = numberIn >= 0 and 0 or 1
	if sign == 1 then
		numberIn = -numberIn
	end

	bits[1] = sign

	for i = 2, bitsNum do
		bits[i] = 0
	end

	for i = 2, bitsNum do
		if numberIn == 0 then break end
		local div = numberIn % 2
		numberIn = (numberIn - div) / 2
		bits[bitsNum - i + 2] = div
	end

	return bits
end

function bitworker.IntegerToBinary2(numberIn, bitsNum)
	local max = math.pow(2, bitsNum)

	if numberIn < 0 then
		numberIn = max + numberIn
	elseif numberIn > max then
		numberIn = numberIn - max
	end

	local bits = {}

	for i = 1, bitsNum do
		bits[i] = 0
	end

	for i = 1, bitsNum do
		if numberIn == 0 then break end
		local div = numberIn % 2
		numberIn = (numberIn - div) / 2
		bits[bitsNum - i + 1] = div
	end

	return bits
end

function bitworker.BinaryToUInteger(inputTable)
	local amount = #inputTable
	local output = 0

	for i = 1, amount do
		if inputTable[i] == 1 then
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
		if inputTable[i] == 1 then
			output = output + math.pow(2, amount - i)
		end
	end

	if direction == 0 then
		return output
	else
		return -output
	end
end

function bitworker.BinaryToInteger2(bits)
	local bitsNum = #bits
	local max = math.pow(2, bitsNum - 1) - 1
	local output = 0

	for i = 1, bitsNum do
		if bits[i] == 1 then
			output = output + math.pow(2, bitsNum - i)
		end
	end

	if output > max then
		output = output - math.pow(2, bitsNum)
	end

	return output
end

function bitworker.UIntegerToBinary(numberIn, bitsNum)
	if not isValidNumber(numberIn) then
		local vr = {}

		for i = 1, bitsNum do
			vr[i] = 0
		end

		return vr
	end

	if numberIn < 0 then
		numberIn = math.pow(2, bitsNum) + numberIn
	end

	local bits = {}

	for i = 1, bitsNum do
		bits[i] = 0
	end

	for i = 1, bitsNum do
		if numberIn == 0 then break end
		local div = numberIn % 2
		numberIn = (numberIn - div) / 2
		bits[bitsNum - i + 1] = div
	end

	return bits
end

function bitworker.NumberToMantiss(numberIn, bitsAllowed)
	if not isValidNumber(numberIn) then
		local bits = {}

		for i = 1, bitsAllowed do
			bits[i] = 0
		end

		return bits
	end

	local exp = 0
	numberIn = math.abs(numberIn)
	local lastMult = numberIn % 1

	if numberIn >= 2 then
		-- try to normalize number to be less than 2
		-- shift to right
		while numberIn >= 2 do
			numberIn = numberIn / 2
			exp = exp + 1
		end
	end

	-- if our number is less than one, shift to left
	if exp == 0 and numberIn < 1 then
		while numberIn < 1 do
			numberIn = numberIn * 2
			exp = exp - 1
		end
	end

	-- if number is not a zero, it is known amoung all computers that
	-- first bit of mantissa is always 1
	-- so let's assume so
	numberIn = numberIn - 1

	local bits = {}
	for i = 1, bitsAllowed do
		numberIn = numberIn * 2

		if numberIn >= 1 then
			table_insert(bits, 1)
			numberIn = numberIn - 1
		else
			table_insert(bits, 0)
		end
	end

	return bits, exp
end

function bitworker.MantissToNumber(bitsIn, exp)
	exp = exp or 0
	local num = 0

	for i = 1, #bitsIn do
		if bitsIn[i] == 1 then
			num = num + math.pow(2, -i)
		end
	end

	return math.pow(2, exp) * (1 + num)
end

-- final range is bitsExponent + bitsMantissa + 2
-- where 2 is two bits which one forwards number sign and one forward exponent sign
function bitworker.FloatToBinaryIEEE(numberIn, bitsExponent, bitsMantissa)
	if not isValidNumber(numberIn) or numberIn == 0 then
		local bits = {}

		for i = 0, bitsExponent + bitsMantissa do
			table_insert(bits, 0)
		end

		return bits
	end

	local bits = {numberIn >= 0 and 0 or 1}
	local mantissa, exp = bitworker.NumberToMantiss(numberIn, bitsMantissa)
	local expBits = bitworker.UIntegerToBinary(exp + 127, bitsExponent)

	table.append(bits, expBits)
	table.append(bits, mantissa)

	return bits
end

function bitworker.BinaryToFloatIEEE(bitsIn, bitsExponent, bitsMantissa)
	local valid = false

	for i = 1, #bitsIn do
		if bitsIn[i] ~= 0 then
			valid = true
			break
		end
	end

	if not valid then return 0 end

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

function bitworker.BitsToBytes(bitsIn)
	assert(#bitsIn % 8 == 0, 'Not full bytes')
	local output = {}

	for i = 1, #bitsIn / 8 do
		output[i] =
			bitsIn[(i - 1) * 8 + 8] +
			bitsIn[(i - 1) * 8 + 7] * 2 +
			bitsIn[(i - 1) * 8 + 6] * 4 +
			bitsIn[(i - 1) * 8 + 5] * 8 +
			bitsIn[(i - 1) * 8 + 4] * 16 +
			bitsIn[(i - 1) * 8 + 3] * 32 +
			bitsIn[(i - 1) * 8 + 2] * 64 +
			bitsIn[(i - 1) * 8 + 1] * 128
	end

	return output
end
