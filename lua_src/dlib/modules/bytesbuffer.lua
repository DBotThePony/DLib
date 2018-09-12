
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


jit.on()
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

local function wrap(num, maximal)
	if num >= 0 then
		return num
	end

	return maximal * 2 + num
end

local function unwrap(num, maximal)
	if num < maximal then
		return num
	end

	return num - maximal * 2
end

local function assertType(valueIn, desiredType, funcName)
	if type(valueIn) == desiredType then return end
	error(funcName .. ' - input is not a ' .. desiredType .. '! typeof ' .. type(valueIn), 3)
end

local function assertRange(valueIn, min, max, funcName)
	if valueIn >= min and valueIn <= max then return end
	error(funcName .. ' - size overflow (' .. min .. ' -> ' .. max .. ' vs ' .. valueIn .. ')', 3)
end

-- Primitive read/write
-- wrap overflow
function meta:WriteByte_2(valueIn)
	assertType(valueIn, 'number', 'WriteByte')
	assertRange(valueIn, -0x80, 0x7F, 'WriteByte')
	return self:WriteUByte(math.floor(valueIn) + 0x80)
end

-- one's component
function meta:WriteByte(valueIn)
	assertType(valueIn, 'number', 'WriteByte')
	assertRange(valueIn, -0x80, 0x7F, 'WriteByte')
	return self:WriteUByte(wrap(math.floor(valueIn), 0x80))
end

function meta:WriteUByte(valueIn)
	assertType(valueIn, 'number', 'WriteUByte')
	assertRange(valueIn, 0, 0xFF, 'WriteUByte')
	valueIn = math.floor(valueIn)
	self.pointer = self.pointer + 1
	self.bytes[self.pointer] = valueIn
	return self
end

meta.WriteInt8 = meta.WriteByte
meta.WriteUInt8 = meta.WriteUByte

function meta:WriteChar(char)
	assertType(char, 'string', 'WriteChar')
	assert(#char == 1, 'Input is not a single char!')
	self:WriteUByte(string.byte(char))
	return self
end

function meta:WriteInt16_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt16')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16')
	return self:WriteUInt16(math.floor(valueIn) + 0x8000)
end

function meta:WriteInt16(valueIn)
	assertType(valueIn, 'number', 'WriteInt16')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16')
	return self:WriteUInt16(wrap(math.floor(valueIn), 0x8000))
end

function meta:WriteUInt16(valueIn)
	assertType(valueIn, 'number', 'WriteUInt16')
	assertRange(valueIn, 0, 0xFFFF, 'WriteUInt16')
	valueIn = math.floor(valueIn)
	self.bytes[self.pointer + 2] = valueIn % 0x100
	self.bytes[self.pointer + 1] = (valueIn - valueIn % 0x100) / 0x100
	self.pointer = self.pointer + 2
	return self
end

function meta:WriteInt32_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt32')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32')
	return self:WriteUInt32(math.floor(valueIn) + 0x80000000)
end

function meta:WriteInt32(valueIn)
	assertType(valueIn, 'number', 'WriteInt32')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32')
	return self:WriteUInt32(wrap(math.floor(valueIn), 0x80000000))
end

function meta:WriteUInt32(valueIn)
	assertType(valueIn, 'number', 'WriteUInt32')
	assertRange(valueIn, 0, 0xFFFFFFFF, 'WriteUInt32')
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

function meta:WriteInt64_2(valueIn)
	self:WriteUInt64(valueIn + 0x100000000)
	return self
end

function meta:WriteInt64(valueIn)
	self:WriteUInt64(wrap(valueIn, 0x100000000))
	return self
end

function meta:WriteUInt64(valueIn)
	self:WriteUInt32((valueIn - valueIn % 0xFFFFFFFF) / 0xFFFFFFFF)
	valueIn = valueIn % 0xFFFFFFFF
	self:WriteUInt32(valueIn)
	return self
end

function meta:CheckOverflow(name, moveBy)
	if self.pointer + moveBy > self.length then
		error('Read' .. name .. ' - bytes amount overflow (' .. self.pointer .. ' + ' .. moveBy .. ' vs ' .. self.length .. ')', 3)
	end
end

function meta:ReadByte_2()
	return self:ReadUByte() - 0x80
end

function meta:ReadByte()
	return unwrap(self:ReadUByte(), 0x80)
end

function meta:ReadUByte()
	self:CheckOverflow('UByte', 1)
	self.pointer = self.pointer + 1
	return self.bytes[self.pointer]
end

meta.ReadInt8 = meta.ReadByte
meta.ReadUInt8 = meta.ReadUByte

function meta:ReadInt16_2()
	return self:ReadUInt16() - 0x8000
end

function meta:ReadInt16()
	return unwrap(self:ReadUInt16(), 0x8000)
end

function meta:ReadUInt16()
	self:CheckOverflow('UInt16', 2)
	self.pointer = self.pointer + 2
	return self.bytes[self.pointer] + self.bytes[self.pointer - 1] * 256
end

function meta:ReadInt32_2()
	return self:ReadUInt32() - 0x80000000
end

function meta:ReadInt32()
	return unwrap(self:ReadUInt32(), 0x80000000)
end

function meta:ReadUInt32()
	self:CheckOverflow('UInt32', 4)
	self.pointer = self.pointer + 4
	return self.bytes[self.pointer] +
		self.bytes[self.pointer - 1] * 256 +
		self.bytes[self.pointer - 2] * 256 * 256 +
		self.bytes[self.pointer - 3] * 256 * 256 * 256
end

function meta:ReadInt64_2()
	return self:ReadUInt64() - 0x100000000
end

function meta:ReadInt64()
	return unwrap(self:ReadUInt64(), 0x100000000)
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
	assertType(valueIn, 'number', 'WriteFloat')
	local bits = DLib.bitworker2.FloatToBinaryIEEE(valueIn, 8, 23)
	local bitsInNumber = DLib.bitworker2.BinaryToUInteger(bits)
	return self:WriteUInt32(bitsInNumber)
end

function meta:ReadFloat()
	local bitsInNumber = self:ReadUInt32()
	local bits = DLib.bitworker2.UIntegerToBinary(bitsInNumber, 32)
	return DLib.bitworker2.BinaryToFloatIEEE(bits, 8, 23)
end

function meta:WriteDouble(valueIn)
	assertType(valueIn, 'number', 'WriteDouble')
	local bits = DLib.bitworker2.FloatToBinaryIEEE(valueIn, 11, 52)
	local bitsInNumber = DLib.bitworker2.BinaryToUInteger(bits)
	self:WriteUInt64(bitsInNumber)
	return self
end

function meta:ReadDouble()
	local bitsInNumber = self:ReadUInt64()
	local bits = DLib.bitworker2.UIntegerToBinary(bitsInNumber, 64)
	return DLib.bitworker2.BinaryToFloatIEEE(bits, 11, 52)
end

-- String
function meta:WriteString(stringIn)
	assertType(stringIn, 'string', 'WriteString')
	if #stringIn == 0 then return self end
	local bytes = DLib.string.bbyte(stringIn, 1, #stringIn)
	local i = 0
	local len = #bytes

	::loop::
	i = i + 1

	if bytes[i] == 0 then
		error('Binary data in a string?!')
	end

	self.pointer = self.pointer + 1
	self.bytes[self.pointer] = bytes[i]

	if i < len then
		goto loop
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

	::loop::

	table.insert(output, readNext)
	self.pointer = self.pointer + 1
	readNext = self.bytes[self.pointer]

	if readNext == nil then
		error('No NULL terminator was found, buffer overflow!')
	end

	if readNext ~= 0 and readNext ~= nil then
		goto loop
	end

	return DLib.string.bcharTable(output)
end

-- Binary Data

function meta:WriteBinary(binaryString)
	assertType(binaryString, 'string', 'WriteBinary')
	if #binaryString == 0 then return false end
	local bytes = DLib.string.bbyte(binaryString, 1, #binaryString)
	local len = #bytes
	local i = 0

	::loop::

	i = i + 1
	self.pointer = self.pointer + 1
	self.bytes[self.pointer] = bytes[i]

	if i < len then
		goto loop
	end

	return self
end

function meta:ReadBinary(readAmount)
	assert(readAmount >= 0, 'Read amount must be positive')
	if readAmount == 0 then return '' end
	self:CheckOverflow('Binary', readAmount)

	local output = {}

	local i = 0

	::loop::

	i = i + 1
	self.pointer = self.pointer + 1
	table.insert(output, self.bytes[self.pointer])

	if i < readAmount then
		goto loop
	end

	return DLib.string.bcharTable(output)
end

meta.WriteData = meta.WriteBinary
meta.ReadData = meta.ReadBinary

function meta:ReadChar()
	return string.char(self:ReadUByte())
end

function meta:ToString()
	return DLib.string.bcharTable(self.bytes)
end

function meta:ToFileStream(fileStream)
	local bytes = #self.bytes
	if bytes == 0 then return fileStream end
	local i = 0

	::loop::
	i = i + 1

	fileStream:WriteByte(self.bytes[i])

	if i < bytes then
		goto loop
	end

	return fileStream
end
