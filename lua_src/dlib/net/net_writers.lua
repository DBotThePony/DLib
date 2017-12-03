
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
		error('Must be a number')
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
	if type(input) ~= 'number' then error('Input is not a number!') end
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

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

	for i = 2, #output do
		self:WriteBitRaw(output[i])
	end

	return self
end

function messageMeta:WriteUInt(input, bitCount)
	if self.isReading then error('Message is read-only') end

	input = tonumber(input)
	bitCount = tonumber(bitCount)
	if type(input) ~= 'number' then error('Input is not a number!') end
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

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

	for i = 1, #output do
		self:WriteBitRaw(output[i])
	end

	return self
end

function messageMeta:WriteNumber(input, bitsInteger, bitsFloat)
	if self.isReading then error('Message is read-only') end

	input = tonumber(input)
	bitsFloat = tonumber(bitsFloat)
	bitsInteger = tonumber(bitsInteger)
	if type(input) ~= 'number' then error('Input is not a number!') end
	if type(bitsInteger) ~= 'number' then error('Integer part Bit amount is not a number!') end
	if type(bitsFloat) ~= 'number' then error('Float part Bit amount is not a number!') end

	bitsInteger = math.floor(bitsInteger)
	bitsFloat = math.floor(bitsFloat)
	if bitsInteger > 127 or bitsInteger < 2 then error('Integer part Bit amount overflow') end
	if bitsFloat > 87 or bitsFloat < 2 then error('Float part Bit amount overflow') end

	local totalBits = bitsInteger + bitsFloat
	local output = DLib.bitworker.FloatToBinary(input, bitsFloat)

	self:WriteBitRaw(output[1])

	for i = 1, totalBits - #output do
		self:WriteBitRaw(0)
	end

	-- print(input, totalBits, totalBits - #output, #output)

	for i = 2, #output do
		self:WriteBitRaw(output[i])
	end

	return self
end

function messageMeta:WriteFloat(floatIn)
	return self:WriteNumber(floatIn, 24, 8)
end

function messageMeta:WriteVector(vecIn)
	if type(vecIn) ~= 'Vector' then
		error('WriteVector - input is not a vector!')
	end

	self:WriteNumber(vecIn.x, 24, 4)
	self:WriteNumber(vecIn.y, 24, 4)
	self:WriteNumber(vecIn.z, 24, 4)

	return self
end

function messageMeta:WriteAngle(angleIn)
	if type(angleIn) ~= 'Angle' then
		error('WriteAngle - input is not an angle!')
	end

	self:WriteNumber(angleIn.p, 24, 4)
	self:WriteNumber(angleIn.y, 24, 4)
	self:WriteNumber(angleIn.r, 24, 4)

	return self
end

function messageMeta:WriteData(binaryData, bytesToSend)
	if type(binaryData) ~= 'string' then
		error('WriteData - input is not a string!')
	end

	if type(bytesToSend) ~= 'number' then
		error('WriteData - length is not a number!')
	end

	bytesToSend = math.floor(bytesToSend)

	if bytesToSend < 0 then
		error('WriteData - length overflow')
	end

	bytesToSend = math.min(#binaryData, bytesToSend)
	local chars = {binaryData:byte(1, bytesToSend)}

	for i, char in ipairs(chars) do
		self:WriteBitsRaw(DLib.bitworker.UIntegerToBinary(char), 8)
	end

	return self
end

function messageMeta:WriteDouble(value)
	return self:WriteNumber(value, 32, 32)
end

function messageMeta:WriteString(stringIn)
	if type(stringIn) ~= 'string' then
		error('WriteString - input is not a string!')
	end

	for i, char in ipairs({stringIn:byte(1, #stringIn)}) do
		self:WriteBitsRaw(DLib.bitworker.UIntegerToBinary(char), 8)
	end

	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)

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
		error('WriteNormal - input is not a vector!')
	end

	local vector = vectorIn:GetNormalized()

	self:WriteNumber(vector.x, 3, 8)
	self:WriteNumber(vector.y, 3, 8)
	self:WriteNumber(vector.z, 3, 8)

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
		error('WriteMatrix - input is not a VMatrix!')
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
