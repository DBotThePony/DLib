
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
local Entity = Entity
local IsValid = IsValid
local Matrix = Matrix

local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

local function ErrorNoHalt(message)
	return ErrorNoHalt2(traceback(message) .. '\n')
end

function messageMeta:ReadBit()
	if self.pointer == self.length then
		self:ReportOutOfRange('ReadBit', 1)
		return 0
	end

	self.pointer = self.pointer + 1
	return self.bits[self.pointer]
end

function messageMeta:ReadBool()
	return self:ReadBit() == 1
end

function messageMeta:ReadIntInternal(bitCount, direction)
	bitCount = tonumber(bitCount)
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

	if self.pointer + bitCount > self.length or bitCount < 2 then
		self:ReportOutOfRange('ReadInt', bitCount)
		return 0
	end

	bitCount = math.floor(bitCount)
	local buffer = self:ReadBufferDirection(bitCount, direction)

	return math.floor(DLib.bitworker.BinaryToIntegerFixed(buffer))
end

function messageMeta:ReadUIntInternal(bitCount, direction)
	bitCount = tonumber(bitCount)
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

	if self.pointer + bitCount > self.length or bitCount < 1 then
		self:ReportOutOfRange('ReadUInt', bitCount)
		return 0
	end

	bitCount = math.floor(bitCount)
	local buffer = self:ReadBufferDirection(bitCount, direction)

	return math.floor(DLib.bitworker.BinaryToUInteger(buffer))
end

function messageMeta:ReadInt(bitCount)
	return self:ReadIntInternal(bitCount, false)
end

function messageMeta:ReadUInt(bitCount)
	return self:ReadUIntInternal(bitCount, false)
end

function messageMeta:ReadIntBackward(bitCount)
	return self:ReadIntInternal(bitCount, false)
end

function messageMeta:ReadUIntBackward(bitCount)
	return self:ReadUIntInternal(bitCount, false)
end

function messageMeta:ReadIntForward(bitCount)
	return self:ReadIntInternal(bitCount, true)
end

function messageMeta:ReadUIntForward(bitCount)
	return self:ReadUIntInternal(bitCount, true)
end

function messageMeta:ReadNumber(bitsExponent, bitsMantissa, driection)
	bitsMantissa = tonumber(bitsMantissa)
	bitsExponent = tonumber(bitsExponent)

	if type(bitsExponent) ~= 'number' then error('Exponent bit amount is not a number!') end
	if type(bitsMantissa) ~= 'number' then error('Mantissa bit amount is not a number!') end

	if bitsExponent > 24 or bitsExponent < 4 then error('Exponent bit amount overflow') end
	if bitsMantissa > 127 or bitsMantissa < 4 then error('Mantissa bit amount overflow') end

	local totalBits = bitsExponent + bitsMantissa + 1

	if self.pointer + totalBits > self.length then
		self:ReportOutOfRange('ReadNumber', totalBits)
		return 0
	end

	local buffer = self:ReadBufferDirection(totalBits, direction)
	local readFloat = DLib.bitworker.BinaryToFloatIEEE(buffer, bitsExponent, bitsMantissa)

	--local ceil = math.pow(10, math.max(1, math.floor(bitsMantissa / 3)))
	--readFloat = math.floor(readFloat * ceil + 0.5) / ceil

	return readFloat
end

function messageMeta:ReadFloat()
	return self:ReadNumber(8, 23)
end

local Angle, Vector = Angle, Vector

function messageMeta:ReadVector()
	return Vector(self:ReadNumber(8, 16), self:ReadNumber(8, 16), self:ReadNumber(8, 16))
end

function messageMeta:ReadAngle()
	return Angle(self:ReadNumber(8, 16), self:ReadNumber(8, 16), self:ReadNumber(8, 16))
end

function messageMeta:ReadDataInternal(bytesRead, direction)
	if type(bytesRead) ~= 'number' then
		error('ReadData - length is not a number!')
	end

	bytesRead = math.floor(bytesRead)

	if bytesRead < 0 then
		-- error('ReadData - length overflow')
		return ''
	end

	local bitsRead = bytesRead * 8

	if self.pointer + bitsRead > self.length then
		ErrorNoHalt('ReadData - out of bounds, clamping read range...')
		bitsRead = self.length - self.pointer
		bytesRead = math.floor(bitsRead / 8)
	end

	local bits = {}

	for byte = 1, bytesRead do
		table.insert(bits, DLib.bitworker.BinaryToUInteger(self:ReadBufferDirection(8, direction)))
	end

	if #bits <= 500 then
		return string.char(unpack(bits))
	else
		local output = ''
		local amount = #bits

		for i = 1, amount, 500 do
			output = output .. string.char(unpack(bits, i, math.min(i + 499, amount)))
		end

		return output
	end
end

function messageMeta:ReadData(bytesRead)
	return self:ReadDataInternal(bytesRead, false)
end

function messageMeta:ReadDataBackward(bytesRead)
	return self:ReadDataInternal(bytesRead, false)
end

function messageMeta:ReadDataForward(bytesRead)
	return self:ReadDataInternal(bytesRead, true)
end

function messageMeta:ReadDoubleBackward()
	return self:ReadNumber(11, 52, false)
end

function messageMeta:ReadDouble()
	return self:ReadNumber(11, 52, false)
end

function messageMeta:ReadDoubleForward()
	return self:ReadNumber(11, 52, true)
end

function messageMeta:ReadStringInternal(direction)
	if self.length < self.pointer + 8 then
		ErrorNoHalt('net.ReadString - unable to read - buffer is exhausted!')
		return ''
	end

	local nextChar = DLib.bitworker.BinaryToUInteger(self:ReadBufferBackward(8))
	local readString = {}

	while nextChar ~= 0 do
		if self.length < self.pointer + 8 then
			ErrorNoHalt('net.ReadString - string has no NULL terminator! Buffer overflow!')
			return ''
		end

		table.insert(readString, nextChar)
		nextChar = DLib.bitworker.BinaryToUInteger(self:ReadBufferDirection(8, direction))
	end

	--print('-----')
	--PrintTable(readString)

	if #readString ~= 0 then
		return string.char(unpack(readString))
	else
		return ''
	end
end

function messageMeta:ReadString()
	return self:ReadStringInternal(false)
end

function messageMeta:ReadStringBackward()
	return self:ReadStringInternal(false)
end

function messageMeta:ReadStringForward()
	return self:ReadStringInternal(true)
end

function messageMeta:ReadEntity()
	local ent = Entity(self:ReadUInt(16))

	if IsValid(ent) then
		return ent
	else
		return Entity(0)
	end
end

function messageMeta:ReadNormal()
	return Vector(self:ReadNumber(3, 16), self:ReadNumber(3, 16), self:ReadNumber(3, 16))
end

messageMeta.ReadFunctions = {
	[TYPE_NIL] = function(self) return nil end,
	[TYPE_STRING] = function(self) return self:ReadString() end,
	[TYPE_NUMBER] = function(self) return self:ReadDouble() end,
	[TYPE_TABLE] = function(self) return self:ReadTable() end,
	[TYPE_BOOL] = function(self) return self:ReadBool() end,
	[TYPE_ENTITY] = function(self) return self:ReadEntity() end,
	[TYPE_VECTOR] = function(self) return self:ReadVector() end,
	[TYPE_ANGLE] = function(self) return self:ReadAngle() end,
	[TYPE_MATRIX] = function(self) return self:ReadMatrix() end,
	[TYPE_COLOR] = function(self) return self:ReadColor() end,
}

function messageMeta:ReadType(typeid)
	typeid = typeid or self:ReadUInt(8)

	local readFunc = self.ReadFunctions[typeid]

	if readFunc then
		return readFunc(self)
	end

	error('ReadType - corrupted or invalid typeid - ' .. typeid)
end

function messageMeta:ReadTable()
	local output = {}
	local readKey, readValue

	repeat
		readKey = self:ReadType()
		if readKey == nil then break end
		readValue = self:ReadType()
		if readValue == nil then break end
		output[readKey] = readValue
	until readKey == nil or readValue == nil or self.pointer >= self.length

	return output
end

function messageMeta:ReadMatrix()
	local tableOutput = {}

	for row = 1, 4 do
		tableOutput[row] = {}

		for field = 1, 4 do
			tableOutput[row][field] = self:ReadDouble()
		end
	end

	return Matrix(tableOutput)
end

function messageMeta:ReadHeader()
	return self:ReadUInt(16)
end
