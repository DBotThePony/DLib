
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

local DLib = DLib
local meta = FindMetaTable('LBytesBuffer') or {}
debug.getregistry().LBytesBuffer = meta
DLib.BytesBufferMeta = meta

local type = type
local math = math
local assert = assert
local table = table
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local string = string

function meta:__index(key)
	if key == 'length' then
		return #self.bytes
	end

	if meta[key] ~= nil then
		return meta[key]
	end

	return rawget(self, key)
end

local byteschecker = {}

byteschecker.__index = byteschecker
byteschecker.__newindex = function(self, key, value)
	if value < 0 or value > 255 then
		error('wtf? new byte is ' .. value)
	end

	rawset(self, key, value)
end

function DLib.BytesBuffer(stringIn)
	local obj = setmetatable({}, meta)
	obj.bytes = setmetatable({}, byteschecker)
	obj.pointer = 0

	if type(stringIn) == 'string' then
		obj:WriteBinary(stringIn)
	end

	obj:Seek(0)

	return obj
end

-- Operations
function meta:Seek(moveTo)
	assert(moveTo >= 0 and moveTo <= self.length, 'Seek - invalid position')
	self.pointer = moveTo
	return self
end

function meta:Move(moveBy)
	return self:Seek(self.pointer + moveBy)
end

meta.Walk = meta.Move

function meta:Reset()
	return self:Seek(0)
end

function meta:Release()
	self.pointer = 0
	self.bytes = setmetatable({}, byteschecker)
	return self
end

function meta:GetBytes()
	return self.bytes
end

-- Primitive read/write
function meta:WriteByte(valueIn)
	assert(type(valueIn) == 'number', 'WriteByte - argument type is ' .. type(valueIn))
	assert(valueIn >= -0x80 and valueIn <= 0x7F, 'WriteByte - size overflow')
	valueIn = math.floor(valueIn) + 0x80
	return self:WriteUByte(math.floor(valueIn) + 0x80)
end

function meta:WriteUByte(valueIn)
	assert(type(valueIn) == 'number', 'WriteUByte - argument type is ' .. type(valueIn))
	assert(valueIn >= 0 and valueIn <= 0xFF, 'WriteUByte - size overflow')
	valueIn = math.floor(valueIn)
	self.pointer = self.pointer + 1
	self.bytes[self.pointer] = valueIn
	return self
end

meta.WriteInt8 = meta.WriteByte
meta.WriteUInt8 = meta.WriteUByte

function meta:WriteChar(char)
	assert(type(char) == 'string' and #char == 1, 'Input is not a char!')
	self:WriteUByte(string.byte(char))
	return self
end

function meta:WriteInt16(valueIn)
	assert(type(valueIn) == 'number', 'WriteInt16 - argument type is ' .. type(valueIn))
	assert(valueIn >= -0x8000 and valueIn <= 0x7FFF, 'WriteInt16 - size overflow')
	return self:WriteUInt16(math.floor(valueIn) + 0x8000)
end

function meta:WriteUInt16(valueIn)
	assert(type(valueIn) == 'number', 'WriteUInt16 - argument type is ' .. type(valueIn))
	assert(valueIn >= 0 and valueIn <= 0xFFFF, 'WriteUInt16 - size overflow')
	valueIn = math.floor(valueIn)
	self.bytes[self.pointer + 2] = valueIn % 0x100
	self.bytes[self.pointer + 1] = (valueIn - valueIn % 0x100) / 0x100
	self.pointer = self.pointer + 2
	return self
end

function meta:WriteInt32(valueIn)
	assert(type(valueIn) == 'number', 'WriteInt32 - argument type is ' .. type(valueIn))
	assert(valueIn >= -0x80000000 and valueIn <= 0x7FFFFFFF, 'WriteByte - size overflow')
	return self:WriteUInt32(math.floor(valueIn) + 0x80000000)
end

function meta:WriteUInt32(valueIn)
	assert(type(valueIn) == 'number', 'WriteUInt32 - argument type is ' .. type(valueIn))
	assert(valueIn >= -0 and valueIn <= 0xFFFFFFFF, 'WriteUInt32 - size overflow')
	valueIn = math.floor(valueIn)
	self.bytes[self.pointer + 4] = valueIn % 0x100
	valueIn = (valueIn - valueIn % 0x100) / 0x100
	self.bytes[self.pointer + 3] = valueIn % 0x100
	valueIn = (valueIn - valueIn % 0x100) / 0x100
	self.bytes[self.pointer + 2] = valueIn % 0x100
	valueIn = (valueIn - valueIn % 0x100) / 0x100
	self.bytes[self.pointer + 1] = valueIn % 0x100
	valueIn = (valueIn - valueIn % 0x100) / 0x100
	self.pointer = self.pointer + 4
	return self
end

function meta:WriteInt64(valueIn)
	self:WriteUInt64(valueIn + 0x100000000)
	return self
end

function meta:WriteUInt64(valueIn)
	self:WriteUInt32((valueIn - valueIn % 0xFFFFFFFF) / 0xFFFFFFFF)
	valueIn = valueIn % 0xFFFFFFFF
	self:WriteUInt32(valueIn)
	return self
end

function meta:CheckOverflow(name, moveBy)
	assert(self.pointer + moveBy <= self.length, 'Read' .. name .. ' - bytes amount overflow (' .. self.pointer .. ' + ' .. moveBy .. ' vs ' .. self.length .. ')')
end

function meta:ReadByte()
	return self:ReadUByte() - 0x80
end

function meta:ReadUByte()
	self:CheckOverflow('UByte', 1)
	self.pointer = self.pointer + 1
	return self.bytes[self.pointer]
end

meta.ReadInt8 = meta.ReadByte
meta.ReadUInt8 = meta.ReadUByte

function meta:ReadInt16()
	return self:ReadUInt16() - 0x8000
end

function meta:ReadUInt16()
	self:CheckOverflow('UInt16', 2)
	self.pointer = self.pointer + 2
	return self.bytes[self.pointer] + self.bytes[self.pointer - 1] * 256
end

function meta:ReadInt32()
	return self:ReadUInt32() - 0x80000000
end

function meta:ReadUInt32()
	self:CheckOverflow('UInt32', 4)
	self.pointer = self.pointer + 4
	return self.bytes[self.pointer] +
		self.bytes[self.pointer - 1] * 256 +
		self.bytes[self.pointer - 2] * 256 * 256 +
		self.bytes[self.pointer - 3] * 256 * 256 * 256
end

function meta:ReadInt64()
	return self:ReadUint64() - 0x100000000
end

function meta:ReadUInt64()
	self:CheckOverflow('UInt64', 8)
	self.pointer = self.pointer + 8
	return self.bytes[self.pointer] +
		self.bytes[self.pointer - 1] * 256 +
		self.bytes[self.pointer - 2] * 256 * 256 +
		self.bytes[self.pointer - 3] * 256 * 256 * 256 +
		self.bytes[self.pointer - 4] * 256 * 256 * 256 * 256 +
		self.bytes[self.pointer - 5] * 256 * 256 * 256 * 256 * 256 +
		self.bytes[self.pointer - 6] * 256 * 256 * 256 * 256 * 256 * 256 +
		self.bytes[self.pointer - 7] * 256 * 256 * 256 * 256 * 256 * 256 * 256
end

-- Float
function meta:WriteFloat(valueIn)
	local bits = DLib.bitworker.FloatToBinaryIEEE(valueIn, 8, 23)
	local bitsInNumber = DLib.bitworker.BinaryToUInteger(bits)
	return self:WriteUInt32(bitsInNumber)
end

function meta:ReadFloat()
	local bitsInNumber = self:ReadUInt32()
	local bits = DLib.bitworker.IntegerToBinaryFixed(bitsInNumber, 32)
	return DLib.bitworker.BinaryToFloatIEEE(bits, 8, 23)
end

function meta:WriteDouble(valueIn)
	local bits = DLib.bitworker.FloatToBinaryIEEE(valueIn, 11, 52)
	local bitsInNumber = DLib.bitworker.BinaryToUInteger(bits)
	self:WriteUInt64(bitsInNumber)
	return self
end

function meta:ReadDouble()
	local bitsInNumber = self:ReadUInt64()
	local bits = DLib.bitworker.IntegerToBinaryFixed(bitsInNumber, 64)
	return DLib.bitworker.BinaryToFloatIEEE(bits, 11, 52)
end

-- String
function meta:WriteString(stringIn)
	for i, byte in ipairs(DLib.string.bbyte(stringIn, 1, #stringIn)) do
		if byte == 0 then
			error('Binary data in a string?!')
		end

		self.pointer = self.pointer + 1
		self.bytes[self.pointer] = byte
	end

	self.pointer = self.pointer + 1
	self.bytes[self.pointer] = 0

	return self
end

function meta:ReadString()
	self:CheckOverflow('ReadString', 1)
	self.pointer = self.pointer + 1
	local readNext = self.bytes[self.pointer]
	local output = {}

	while readNext ~= 0 and readNext ~= nil do
		table.insert(output, readNext)
		self.pointer = self.pointer + 1
		readNext = self.bytes[self.pointer]

		if readNext == nil then
			error('No NULL terminator was found, buffer overflow!')
		end
	end

	return DLib.string.bcharTable(output)
end

-- Binary Data

function meta:WriteBinary(binaryString)
	for i, byte in ipairs(DLib.string.bbyte(binaryString, 1, #binaryString)) do
		self.pointer = self.pointer + 1
		self.bytes[self.pointer] = byte
	end

	return self
end

function meta:ReadBinary(readAmount)
	assert(readAmount > 0, 'Read amount must be positive and not equal zero')
	self:CheckOverflow('Binary', readAmount)

	local output = {}

	for i = 1, readAmount do
		self.pointer = self.pointer + 1
		table.insert(output, self.bytes[self.pointer])
	end

	return DLib.string.bcharTable(output)
end

function meta:WriteFloat(floatNum)
	local bytes = DLib.bitworker2.BitsToBytes(DLib.bitworker2.FloatToBinaryIEEE(floatNum, 8, 23))

	for i, byte in ipairs(bytes) do
		self:WriteUByte(byte)
	end

	return self
end

function meta:WriteDouble(floatNum)
	local bytes = DLib.bitworker2.BitsToBytes(DLib.bitworker2.FloatToBinaryIEEE(floatNum, 11, 52))

	for i, byte in ipairs(bytes) do
		self:WriteUByte(byte)
	end

	return self
end

function meta:ReadFloat(floatNum)
	local bytes = self:ReadUInt32()
	return DLib.bitworker2.BinaryToFloatIEEE(DLib.bitworker2.UIntegerToBinary(bytes, 32), 8, 23)
end

function meta:ReadFloat(floatNum)
	local bytes = self:ReadUInt64()
	return DLib.bitworker2.BinaryToFloatIEEE(DLib.bitworker2.UIntegerToBinary(bytes, 64), 11, 52)
end

meta.WriteData = meta.WriteBinary
meta.ReadData = meta.ReadBinary

function meta:ReadChar()
	return string.char(self:ReadUByte())
end

function meta:ToString()
	return DLib.string.bcharTable(self.bytes)
end
