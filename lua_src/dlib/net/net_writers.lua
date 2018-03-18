
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

local messageMeta = FindMetaTable('LNetworkMessage')

local DLib = DLib
local util = util
local gnet = net
local type = type
local debug = debug
local ErrorNoHalt2 = ErrorNoHalt
local table = table
local ipairs = ipairs
local pairs = pairs
local math = math
local string = string
local IsValid = IsValid
local TypeID = TypeID
local assert = assert
local tostring = tostring

local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

local function ErrorNoHalt(message)
	if not DLib.DEBUG_MODE:GetBool() then return end

	if not DLib.STRICT_MODE:GetBool() then
		return ErrorNoHalt2(traceback(message) .. '\n')
	else
		return error(message)
	end
end

function messageMeta:WriteBit(bitIn)
	if type(bitIn) == 'boolean' then
		bitIn = bitIn and 1 or 0
	end

	if bitIn == nil then
		ErrorNoHalt('WriteBit - got nil as argument!')
		bitIn = 0
	end

	if type(bitIn) ~= 'number' then
		error('WriteBit - Must be a number! ' .. type(bitIn))
	end

	local input = math.floor(bitIn) == 1 and 1 or 0
	self:WriteBitRaw(input)
	return self
end

messageMeta.WriteBool = messageMeta.WriteBit

function messageMeta:WriteIntInternal(input, bitCount, direction)
	input = tonumber(input)
	bitCount = tonumber(bitCount)
	assert(type(input) == 'number', 'Input is not a number! ' .. type(input))
	assert(type(bitCount) == 'number', 'Bit amount is not a number! ' .. type(bitCount))

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	assert(bitCount < 127 and bitCount > 2, 'Bit amount overflow')

	local output = DLib.bitworker2.IntegerToBinary2(input, bitCount)

	if not direction then
		self:WriteBitsRawBackward(output)
	else
		self:WriteBitsRaw(output)
	end

	return self
end

function messageMeta:WriteIntInternalTwos(input, bitCount, direction)
	input = tonumber(input)
	bitCount = tonumber(bitCount)
	assert(type(input) == 'number', 'Input is not a number! ' .. type(input))
	assert(type(bitCount) == 'number', 'Bit amount is not a number! ' .. type(bitCount))

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	assert(bitCount <= 127 and bitCount >= 2, 'Bit amount overflow')

	local output = DLib.bitworker2.IntegerToBinary(input, bitCount)

	if not direction then
		local sign = table.remove(output, 1)
		self:WriteBitsRawBackward(output, bitCount - 1)
		self:WriteBitRaw(sign)
	else
		self:WriteBitRaw(table.remove(output, 1))
		self:WriteBitsRaw(output, bitCount - 1)
	end

	return self
end

function messageMeta:WriteInt(input, bitCount)
	return self:WriteIntInternal(input, bitCount, false)
end

function messageMeta:WriteIntBackward(input, bitCount)
	return self:WriteIntInternal(input, bitCount, false)
end

function messageMeta:WriteIntForward(input, bitCount)
	return self:WriteIntInternal(input, bitCount, true)
end

function messageMeta:WriteIntTwosBackward(input, bitCount)
	return self:WriteIntInternalTwos(input, bitCount, false)
end

function messageMeta:WriteIntTwosForward(input, bitCount)
	return self:WriteIntInternalTwos(input, bitCount, true)
end

function messageMeta:WriteIntTwos(input, bitCount)
	return self:WriteIntInternalTwos(input, bitCount, false)
end

function messageMeta:WriteIntBackwardTwos(input, bitCount)
	return self:WriteIntInternalTwos(input, bitCount, false)
end

function messageMeta:WriteIntForwardTwos(input, bitCount)
	return self:WriteIntInternalTwos(input, bitCount, true)
end

function messageMeta:WriteUIntInternal(input, bitCount, direction)
	input = tonumber(input)
	bitCount = tonumber(bitCount)
	assert(type(input) == 'number', 'Input is not a number! ' .. type(input))
	assert(type(bitCount) == 'number', 'Bit amount is not a number! ' .. type(bitCount))

	if bitCount == 1 then
		ErrorNoHalt('WriteUInt(bit, 1)?!?! - Use WriteBit instead!')
		self:WriteBit(input)
		return self
	end

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	assert(bitCount <= 127 and bitCount >= 2, 'Bit amount overflow')

	if input < 0 then
		ErrorNoHalt('WriteUInt - input integer is lesser than 0! To keep backward compability, it gets bit shift to flip')
		input = math.pow(2, bitCount) + input
	end

	local output = DLib.bitworker2.UIntegerToBinary(input, bitCount)
	self:WriteBitsRawDirection(output, bitCount, direction)

	return self
end

for i, n in ipairs({8, 16, 32, 64, 96}) do
	messageMeta['WriteInt' .. n] = function(self, value)
		return self:WriteInt(value, n)
	end

	messageMeta['WriteIntTwos' .. n] = function(self, value)
		return self:WriteIntTwos(value, n)
	end

	messageMeta['WriteUInt' .. n] = function(self, value)
		return self:WriteUInt(value, n)
	end
end

function messageMeta:WriteUInt(input, bitCount)
	return self:WriteUIntInternal(input, bitCount, false)
end

function messageMeta:WriteUIntBackward(input, bitCount)
	return self:WriteUIntInternal(input, bitCount, false)
end

function messageMeta:WriteUIntForward(input, bitCount)
	return self:WriteUIntInternal(input, bitCount, true)
end

function messageMeta:WriteNumber(input, bitsExponent, bitsMantissa, direction)
	input = tonumber(input)
	bitsMantissa = tonumber(bitsMantissa)
	bitsExponent = tonumber(bitsExponent)

	assert(type(input) == 'number', 'Input is not a number! ' .. type(input))
	assert(type(bitsExponent) == 'number', 'Exponent bits is not a number! ' .. type(bitsExponent))
	assert(type(bitsMantissa) == 'number', 'Mantissa bits is not a number! ' .. type(bitsMantissa))

	bitsExponent = math.floor(bitsExponent)
	bitsMantissa = math.floor(bitsMantissa)

	assert(bitsExponent <= 24 and bitsExponent >= 4, 'Exponent bits amount overflow')
	assert(bitsMantissa <= 127 and bitsMantissa >= 4, 'Mantissa bits amount overflow')

	self:WriteBitsRawDirection(DLib.bitworker2.FloatToBinaryIEEE(input, bitsExponent, bitsMantissa), nil, direction)

	return self
end

function messageMeta:WriteFloat(floatIn)
	return self:WriteNumber(floatIn, 8, 23, false)
end

function messageMeta:WriteFloatBackward(floatIn)
	return self:WriteNumber(floatIn, 8, 23, false)
end

function messageMeta:WriteFloatForward(floatIn)
	return self:WriteNumber(floatIn, 8, 23, true)
end

function messageMeta:WriteVector(vecIn)
	assert(type(vecIn) == 'Vector', 'WriteVector - input is not a vector! ' .. type(vecIn))

	self:WriteNumber(vecIn.x, 8, 16)
	self:WriteNumber(vecIn.y, 8, 16)
	self:WriteNumber(vecIn.z, 8, 16)

	return self
end

function messageMeta:WriteAngle(angleIn)
	assert(type(angleIn) == 'Angle', 'WriteAngle - input is not an angle! ' .. type(angleIn))

	self:WriteNumber(angleIn.p, 8, 16)
	self:WriteNumber(angleIn.y, 8, 16)
	self:WriteNumber(angleIn.r, 8, 16)

	return self
end

function messageMeta:WriteDataInternal(binaryData, bytesToSend, direction)
	assert(type(binaryData) == 'string', 'WriteData - input is not a string! ' .. type(binaryData))
	assert(type(bytesToSend) == 'number', 'WriteData - length is not a number! ' .. type(bytesToSend))

	bytesToSend = math.floor(bytesToSend)

	if bytesToSend == 0 then
		return self
	end

	assert(bytesToSend >= 0, 'WriteData - length overflow')

	bytesToSend = math.min(#binaryData, bytesToSend)

	local chars = {}

	if bytesToSend > 1000 then
		for i = 1, bytesToSend, 1000 do
			table.append(chars, {binaryData:byte(i, math.min(i + 999, bytesToSend))})
		end
	else
		chars = {binaryData:byte(1, bytesToSend)}
	end

	for i, char in ipairs(chars) do
		self:WriteBitsRawDirection(DLib.bitworker2.UIntegerToBinary(char, 8), nil, direction)
	end

	return self
end

function messageMeta:WriteData(binaryData, bytesToSend)
	return self:WriteDataInternal(binaryData, bytesToSend, false)
end

function messageMeta:WriteDataBackward(binaryData, bytesToSend)
	return self:WriteDataInternal(binaryData, bytesToSend, false)
end

function messageMeta:WriteDataForward(binaryData, bytesToSend)
	return self:WriteDataInternal(binaryData, bytesToSend, true)
end

function messageMeta:WriteDouble(value)
	return self:WriteNumber(value, 11, 52, false)
end

function messageMeta:WriteDoubleBackward(value)
	return self:WriteNumber(value, 11, 52, false)
end

function messageMeta:WriteDoubleForward(value)
	return self:WriteNumber(value, 11, 52, true)
end

local endString = {
	0, 0, 0, 0, 0, 0, 0, 0
}

function messageMeta:WriteStringInternal(stringIn, direction)
	if type(stringIn) == 'number' then
		ErrorNoHalt('WriteString - input is not a string! casting number into string')
		stringIn = tostring(stringIn)
	end

	assert(type(stringIn) == 'string', 'WriteString - input is not a string! ' .. type(stringIn))

	if #stringIn == 0 then
		self:WriteBitsRaw(endString)
		return self
	end

	local writtenZero = false
	local len = #stringIn

	for byte = 1, len, 500 do
		for i, char in ipairs({stringIn:byte(byte, math.min(byte + 499, len))}) do
			if char == 0 and not writtenZero then
				writtenZero = true
				ErrorNoHalt('Writting binary data using net.WriteString?!')
			end

			self:WriteBitsRawDirection(DLib.bitworker2.UIntegerToBinary(char, 8), 8, direction)
		end
	end

	self:WriteBitsRaw(endString)

	return self
end

function messageMeta:WriteString(stringIn)
	return self:WriteStringInternal(stringIn, false)
end

function messageMeta:WriteStringBackward(stringIn)
	return self:WriteStringInternal(stringIn, false)
end

function messageMeta:WriteStringForward(stringIn)
	return self:WriteStringInternal(stringIn, true)
end

function messageMeta:WriteEntity(ent)
	if IsValid(ent) then
		self:WriteUInt(math.max(ent:EntIndex()), 16)
	else
		self:WriteUInt(0, 16)
	end

	return self
end

function messageMeta:WriteNormal(vectorIn)
	assert(type(vectorIn) == 'Vector', 'WriteNormal - input is not a vector! ' .. type(vectorIn))

	local vector = vectorIn:GetNormalized()

	self:WriteNumber(vector.x, 4, 16)
	self:WriteNumber(vector.y, 4, 16)
	self:WriteNumber(vector.z, 4, 16)

	return self
end

messageMeta.WriteFunctions = {
	[TYPE_NIL] = function(self, valueIn) end,
	[TYPE_STRING] = function(self, valueIn) self:WriteString(valueIn) end,
	[TYPE_NUMBER] = function(self, valueIn) self:WriteDouble(valueIn) end,
	[TYPE_TABLE] = function(self, valueIn) self:WriteTable(valueIn) end,
	[TYPE_BOOL] = function(self, valueIn) self:WriteBool(valueIn) end,
	[TYPE_ENTITY] = function(self, valueIn) self:WriteEntity(valueIn) end,
	[TYPE_VECTOR] = function(self, valueIn) self:WriteVector(valueIn) end,
	[TYPE_ANGLE] = function(self, valueIn) self:WriteAngle(valueIn) end,
	[TYPE_MATRIX] = function(self, valueIn) self:WriteMatrix(valueIn) end,
	[TYPE_COLOR] = function(self, valueIn) self:WriteColor(valueIn) end,
}

function messageMeta:WriteType(valueIn)
	local typeid = IsColor(valueIn) and TYPE_COLOR or TypeID(valueIn)
	local writeFunc = self.WriteFunctions[typeid]

	if writeFunc then
		self:WriteUInt(typeid, 8)
		writeFunc(self, valueIn)
		return self
	end

	error('WriteType - type is not networkable - ' .. type(valueIn) .. ' (type ID is ' .. typeid .. ')')
end

function messageMeta:WriteTable(tableIn)
	if type(tableIn) ~= 'table' then
		return 'Invalid table input!'
	end

	for key, value in pairs(tableIn) do
		if key ~= '__index' and key ~= '__newindex' then
			self:WriteType(key)
			self:WriteType(value)
		end
	end

	self:WriteType(nil)

	return self
end

function messageMeta:WriteMatrix(matrixIn)
	assert(type(matrixIn) == 'VMatrix', 'WriteMatrix - input is not a VMatrix! ' .. type(matrixIn))

	local toTable = matrixIn:ToTable()

	for row = 1, 4 do
		for field = 1, 4 do
			self:WriteDouble(toTable[row][field])
		end
	end

	return self
end

function messageMeta:WriteHeader(intIn)
	return self:WriteUInt(intIn, 16)
end
