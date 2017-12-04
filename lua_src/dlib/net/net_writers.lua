
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

local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

local function ErrorNoHalt(message)
	return ErrorNoHalt2(traceback(message) .. '\n')
end

function messageMeta:WriteBit(bitIn)
	if self.isReading then error('Message is read-only') end

	if type(bitIn) == 'boolean' then
		bitIn = bitIn and 1 or 0
	end

	if type(bitIn) ~= 'number' then
		error('WriteBit - Must be a number! ' .. type(bitIn))
	end

	local input = math.floor(bitIn) == 1 and 1 or 0
	self:WriteBitRaw(input)
	return self
end

messageMeta.WriteBool = messageMeta.WriteBit

function messageMeta:WriteInt(input, bitCount)
	if self.isReading then error('Message is read-only') end

	input = tonumber(input)
	bitCount = tonumber(bitCount)
	if type(input) ~= 'number' then error('Input is not a number! ' .. type(input)) end
	if type(bitCount) ~= 'number' then error('Bit amount is not a number! ' .. type(bitCount)) end

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	if bitCount > 127 or bitCount < 2 then error('Bit amount overflow') end

	local output = DLib.bitworker.IntegerToBinary(input)

	if #output > bitCount then
		ErrorNoHalt('WriteInt - input integer is larger than integer that can be represented with ' .. bitCount .. ' bits!')
	end

	self:WriteBitRaw(output[1])

	for i = 1, bitCount - #output do
		self:WriteBitRaw(0)
	end

	for i = 2, math.min(#output, bitCount) do
		self:WriteBitRaw(output[i])
	end

	return self
end

function messageMeta:WriteUInt(input, bitCount)
	if self.isReading then error('Message is read-only') end

	input = tonumber(input)
	bitCount = tonumber(bitCount)
	if type(input) ~= 'number' then error('Input is not a number! ' .. type(input)) end
	if type(bitCount) ~= 'number' then error('Bit amount is not a number! ' .. type(bitCount)) end

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	if bitCount > 127 or bitCount < 1 then error('Bit amount overflow') end

	if input < 0 then
		ErrorNoHalt('WriteUInt - input integer is lesser than 0! To keep backward compability, it gets bit shift to flip')
		input = math.pow(2, bitCount) + input
	end

	local output = DLib.bitworker.UIntegerToBinary(input)

	if #output > bitCount then
		ErrorNoHalt('WriteUInt - input integer is larger than integer that can be represented with ' .. bitCount .. ' bits!')
	end

	for i = 1, bitCount - #output do
		self:WriteBitRaw(0)
	end

	for i = 1, math.min(#output, bitCount) do
		self:WriteBitRaw(output[i])
	end

	return self
end

function messageMeta:WriteNumber(input, bitsExponent, bitsMantissa)
	if self.isReading then error('Message is read-only') end

	input = tonumber(input)
	bitsMantissa = tonumber(bitsMantissa)
	bitsExponent = tonumber(bitsExponent)

	if type(input) ~= 'number' then error('Input is not a number! ' .. type(input)) end
	if type(bitsExponent) ~= 'number' then error('Exponent bits amount is not a number! ' .. type(bitsExponent)) end
	if type(bitsMantissa) ~= 'number' then error('Mantissa bits amount is not a number! ' .. type(bitsMantissa)) end

	bitsExponent = math.floor(bitsExponent)
	bitsMantissa = math.floor(bitsMantissa)
	if bitsExponent > 24 or bitsExponent < 4 then error('Exponent bits amount overflow') end
	if bitsMantissa > 127 or bitsMantissa < 4 then error('Mantissa bits amount overflow') end

	self:WriteBitsRaw(DLib.bitworker.FloatToBinaryIEEE(input, bitsExponent - 1, bitsMantissa))

	return self
end

function messageMeta:WriteFloat(floatIn)
	return self:WriteNumber(floatIn, 8, 23)
end

function messageMeta:WriteVector(vecIn)
	if type(vecIn) ~= 'Vector' then
		error('WriteVector - input is not a vector! ' .. type(vecIn))
	end

	self:WriteNumber(vecIn.x, 8, 16)
	self:WriteNumber(vecIn.y, 8, 16)
	self:WriteNumber(vecIn.z, 8, 16)

	return self
end

function messageMeta:WriteAngle(angleIn)
	if type(angleIn) ~= 'Angle' then
		error('WriteAngle - input is not an angle! ' .. type(angleIn))
	end

	self:WriteNumber(angleIn.p, 8, 16)
	self:WriteNumber(angleIn.y, 8, 16)
	self:WriteNumber(angleIn.r, 8, 16)

	return self
end

function messageMeta:WriteData(binaryData, bytesToSend)
	if type(binaryData) ~= 'string' then
		error('WriteData - input is not a string! ' .. type(binaryData))
	end

	if type(bytesToSend) ~= 'number' then
		error('WriteData - length is not a number! ' .. type(bytesToSend))
	end

	bytesToSend = math.floor(bytesToSend)

	if bytesToSend == 0 then
		-- error('WriteData - length overflow')
		return
	end

	if bytesToSend < 0 then
		error('WriteData - length overflow')
	end

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
		self:WriteBitsRaw(DLib.bitworker.UIntegerToBinary(char), 8)
	end

	return self
end

function messageMeta:WriteDouble(value)
	return self:WriteNumber(value, 11, 52)
end

local endString = {
	0, 0, 0, 0, 0, 0, 0, 0
}

function messageMeta:WriteString(stringIn)
	if type(stringIn) ~= 'string' then
		error('WriteString - input is not a string! ' .. type(stringIn))
	end

	if #stringIn == 0 then
		self:WriteBitsRaw(endString)
		return self
	end

	for i, char in ipairs({stringIn:byte(1, #stringIn)}) do
		self:WriteBitsRaw(DLib.bitworker.UIntegerToBinary(char), 8)
	end

	self:WriteBitsRaw(endString)

	return self
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
	if type(vecIn) ~= 'Vector' then
		error('WriteNormal - input is not a vector! ' .. type(vecIn))
	end

	local vector = vectorIn:GetNormalized()

	self:WriteNumber(vector.x, 3, 16)
	self:WriteNumber(vector.y, 3, 16)
	self:WriteNumber(vector.z, 3, 16)

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
	if type(matrixIn) ~= 'VMatrix' then
		error('WriteMatrix - input is not a VMatrix! ' .. type(matrixIn))
	end

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
