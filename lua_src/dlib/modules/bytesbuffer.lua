
-- Copyright (C) 2017-2019 DBot

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

meta.__index = meta

--[[
	@doc
	@fname DLib.BytesBuffer
	@args string binary = ''

	@desc
	entry point of BytesBuffer creation
	you can pass a string to it to construct bytes array from it
	**BUFFER ONLY WORK WITH BIG ENDIAN BYTES**
	@descdesc

	@returns
	BytesBuffer: newly created object
]]
function DLib.BytesBuffer(stringIn)
	local obj = setmetatable({}, meta)
	obj.bytes = {}
	obj.pointer = 0
	obj.length = 0

	if type(stringIn) == 'string' then
		obj:WriteBinary(stringIn)
	end

	obj:Seek(0)

	return obj
end

--[[
	@doc
	@fname BytesBuffer:Seek
	@args number position

	@returns
	BytesBuffer: self
]]
-- Operations
function meta:Seek(moveTo)
	assert(moveTo >= 0 and moveTo <= self.length, 'Seek - invalid position')
	self.pointer = moveTo
	return self
end

--[[
	@doc
	@fname BytesBuffer:Move
	@alias BytesBuffer:Walk
	@args number delta

	@returns
	BytesBuffer: self
]]
function meta:Move(moveBy)
	return self:Seek(self.pointer + moveBy)
end

meta.Walk = meta.Move

--[[
	@doc
	@fname BytesBuffer:Reset

	@desc
	alias of BytesBuffer:Seek(0)
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:Reset()
	return self:Seek(0)
end

--[[
	@doc
	@fname BytesBuffer:Release

	@desc
	sets pointer to 0 and removes internal bytes array
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:Release()
	self.pointer = 0
	self.bytes = {}
	return self
end

--[[
	@doc
	@fname BytesBuffer:GetBytes

	@internal

	@returns
	table: of integers (for optimization purpose). editing this array will affect the object! be careful
]]
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


--[[
	@doc
	@fname BytesBuffer:EndOfStream

	@returns
	boolean
]]
function meta:EndOfStream()
	return self.pointer >= self.length
end

--[[
	@doc
	@fname BytesBuffer:WriteUByte
	@args number value

	@returns
	BytesBuffer: self
]]
function meta:WriteUByte(valueIn)
	if valueIn == 0 then
		local internal = math.floor(self.pointer / 4) + 1
		self.bytes[internal] = (self.bytes[internal] or 0)
			:band((0xFF):lshift((self.pointer % 4) * 8):bnot())

		self.pointer = self.pointer + 1

		if self.length < self.pointer then
			self.length = self.pointer
		end

		return self
	end

	assertType(valueIn, 'number', 'WriteUByte')
	assertRange(valueIn, 0, 0xFF, 'WriteUByte')

	valueIn = math.floor(valueIn)
	local internal = math.floor(self.pointer / 4) + 1

	self.bytes[internal] = (self.bytes[internal] or 0)
		:band((0xFF):lshift((self.pointer % 4) * 8):bnot())
		:bor(valueIn:lshift((self.pointer % 4) * 8))

	self.pointer = self.pointer + 1

	if self.length < self.pointer then
		self.length = self.pointer
	end

	return self
end

--[[
	@doc
	@fname BytesBuffer:WriteByte_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteByte
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteCHar
	@args string char

	@returns
	BytesBuffer: self
]]
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

meta.WriteInt8 = meta.WriteByte
meta.WriteUInt8 = meta.WriteUByte

function meta:WriteChar(char)
	assertType(char, 'string', 'WriteChar')
	assert(#char == 1, 'Input is not a single char!')
	self:WriteUByte(string.byte(char))
	return self
end

--[[
	@doc
	@fname BytesBuffer:WriteInt16_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt16
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUInt16
	@args number value

	@returns
	BytesBuffer: self
]]
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
	self:WriteUByte((valueIn - valueIn % 0x100) / 0x100)
	self:WriteUByte(valueIn % 0x100)
	return self
end

--[[
	@doc
	@fname BytesBuffer:WriteInt32_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt32
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUInt32
	@args number value

	@returns
	BytesBuffer: self
]]
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

	local four = valueIn % 0x100
	valueIn = (valueIn - valueIn % 0x100) / 0x100
	local three = valueIn % 0x100
	valueIn = (valueIn - valueIn % 0x100) / 0x100
	local two = valueIn % 0x100
	valueIn = (valueIn - valueIn % 0x100) / 0x100
	local one = valueIn % 0x100

	self:WriteUByte(one)
	self:WriteUByte(two)
	self:WriteUByte(three)
	self:WriteUByte(four)

	return self
end

--[[
	@doc
	@fname BytesBuffer:WriteInt64_2
	@args number value

	@desc
	with value shift
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt64
	@args number value

	@desc
	with negative number overflow
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUInt64
	@args number value

	@desc
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	BytesBuffer: self
]]
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

--[[
	@doc
	@fname BytesBuffer:ReadByte_2

	@desc
	with value shift
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadByte

	@desc
	with negative number overflow
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadChar

	@returns
	string
]]
function meta:ReadByte_2()
	return self:ReadUByte() - 0x80
end

function meta:ReadByte()
	return unwrap(self:ReadUByte(), 0x80)
end

function meta:ReadUByte()
	self:CheckOverflow('UByte', 1)
	local internal = math.floor(self.pointer / 4) + 1
	local pointer = self.pointer
	self.pointer = self.pointer + 1

	return (self.bytes[internal] or 0)
		:band((0xFF):lshift((pointer % 4) * 8)):rshift((pointer % 4) * 8)
end

meta.ReadInt8 = meta.ReadByte
meta.ReadUInt8 = meta.ReadUByte

--[[
	@doc
	@fname BytesBuffer:ReadInt16_2

	@desc
	with value shift
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt16

	@desc
	with negative number overflow
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt16

	@returns
	number
]]
function meta:ReadInt16_2()
	return self:ReadUInt16() - 0x8000
end

function meta:ReadInt16()
	return unwrap(self:ReadUInt16(), 0x8000)
end

function meta:ReadUInt16()
	self:CheckOverflow('UInt16', 2)
	return self:ReadUByte() * 256 + self:ReadUByte()
end

--[[
	@doc
	@fname BytesBuffer:ReadInt32_2

	@desc
	with value shift
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt32

	@desc
	with negative number overflow
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt32

	@returns
	number
]]
function meta:ReadInt32_2()
	return self:ReadUInt32() - 0x80000000
end

function meta:ReadInt32()
	return unwrap(self:ReadUInt32(), 0x80000000)
end

function meta:ReadUInt32()
	self:CheckOverflow('UInt32', 4)
	return
		self:ReadUByte() * 0x1000000 +
		self:ReadUByte() * 0x10000 +
		self:ReadUByte() * 0x100 +
		self:ReadUByte()
end

--[[
	@doc
	@fname BytesBuffer:ReadInt64_2

	@desc
	with value shift
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt64

	@desc
	with negative number overflow
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt64

	@desc
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	number
]]
function meta:ReadInt64_2()
	return self:ReadUInt64() - 0x100000000
end

function meta:ReadInt64()
	return unwrap(self:ReadUInt64(), 0x100000000)
end

function meta:ReadUInt64()
	self:CheckOverflow('UInt64', 8)
	self.pointer = self.pointer + 8
	return
		self:ReadUByte() * 0x100000000000000 +
		self:ReadUByte() * 0x1000000000000 +
		self:ReadUByte() * 0x10000000000 +
		self:ReadUByte() * 0x100000000 +
		self:ReadUByte() * 0x1000000 +
		self:ReadUByte() * 0x10000 +
		self:ReadUByte() * 0x100 +
		self:ReadUByte()
end

--[[
	@doc
	@fname BytesBuffer:WriteFloat
	@args number float

	@desc
	due to precision errors, this is a slightly inaccurate operation
	@enddesc

	@returns
	BytesBuffer: self
]]
-- Float
function meta:WriteFloat(valueIn)
	assertType(valueIn, 'number', 'WriteFloat')
	local bits = DLib.bitworker.FloatToBinaryIEEE(valueIn, 8, 23)
	local bitsInNumber = DLib.bitworker.BinaryToUInteger(bits)
	return self:WriteUInt32(bitsInNumber)
end

--[[
	@doc
	@fname BytesBuffer:ReadFloat

	@desc
	due to precision errors, this is a slightly inaccurate operation
	@enddesc

	@returns
	number
]]
function meta:ReadFloat()
	local bitsInNumber = self:ReadUInt32()
	local bits = DLib.bitworker.UIntegerToBinary(bitsInNumber, 32)
	return DLib.bitworker.BinaryToFloatIEEE(bits, 8, 23)
end

--[[
	@doc
	@fname BytesBuffer:WriteDouble
	@args number double

	@desc
	due to precision errors, this is a inaccurate operation
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:WriteDouble(valueIn)
	assertType(valueIn, 'number', 'WriteDouble')
	local bits = DLib.bitworker.FloatToBinaryIEEE(valueIn, 11, 52)
	local bitsInNumber = DLib.bitworker.BinaryToUInteger(bits)
	self:WriteUInt64(bitsInNumber)
	return self
end

--[[
	@doc
	@fname BytesBuffer:ReadDouble

	@desc
	due to precision errors, this is a slightly inaccurate operation
	@enddesc

	@returns
	number
]]
function meta:ReadDouble()
	local bitsInNumber = self:ReadUInt64()
	local bits = DLib.bitworker.UIntegerToBinary(bitsInNumber, 64)
	return DLib.bitworker.BinaryToFloatIEEE(bits, 11, 52)
end


--[[
	@doc
	@fname BytesBuffer:WriteString
	@args string data

	@desc
	writes NUL terminated string to buffer
	errors if NUL is present in string
	@enddesc

	@returns
	BytesBuffer: self
]]
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

	self:WriteUByte(bytes[i])

	if i < len then
		goto loop
	end

	self:WriteUByte(0)

	return self
end

--[[
	@doc
	@fname BytesBuffer:ReadString
	@args string data

	@desc
	reads buffer until it hits NUL symbol
	errors if buffer depleted before NUL is found
	@enddesc

	@returns
	string
]]
function meta:ReadString()
	self:CheckOverflow('ReadString', 1)
	local readNext = self:ReadUByte()
	local output = {}

	if readNext == 0 then return '' end

	::loop::

	table.insert(output, readNext)

	if self:EndOfStream() then
		error('No NUL terminator was found, buffer overflow!')
	end

	readNext = self:ReadUByte()

	if readNext ~= 0 and readNext ~= nil then
		goto loop
	end

	return DLib.string.bcharTable(output)
end

-- Binary Data

--[[
	@doc
	@fname BytesBuffer:WriteBinary
	@alias BytesBuffer:WriteData
	@args string binary

	@returns
	BytesBuffer: self
]]
function meta:WriteBinary(binaryString)
	assertType(binaryString, 'string', 'WriteBinary')
	if #binaryString == 0 then return self end

	for i = 1, #binaryString do
		self:WriteUByte(binaryString:byte(i, i))
	end

	return self
end

--[[
	@doc
	@fname BytesBuffer:ReadBinary
	@alias BytesBuffer:ReadData
	@args number bytesToRead

	@returns
	string
]]
function meta:ReadBinary(readAmount)
	assert(readAmount >= 0, 'Read amount must be positive')
	if readAmount == 0 then return '' end
	self:CheckOverflow('Binary', readAmount)

	local output = {}

	local i = 0

	::loop::

	i = i + 1
	table.insert(output, self:ReadUByte())

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

--[[
	@doc
	@fname BytesBuffer:ToString

	@deprecated

	@returns
	string
]]
function meta:ToString()
	local pointer = self.pointer
	self:Seek(0)
	local str = self:ReadBinary(self.length)
	self:Seek(pointer)
	return str
end

--[[
	@doc
	@fname BytesBuffer:ToFileStream
	@args File stream

	@returns
	File
]]
function meta:ToFileStream(fileStream)
	local bytes = #self.bytes
	if bytes == 0 then return fileStream end

	for i = 1, #self.bytes do
		if i ~= self.bytes[i] then
			fileStream:WriteULong(self.bytes[i])
		else
			local len = self.length % 4

			if len == 0 then
				fileStream:WriteULong(self.bytes[i])
			elseif len == 1 then
				fileStream:WriteByte(self.bytes[i])
			elseif len == 2 then
				fileStream:WriteByte(self.bytes[i]:rshift(8):band(0xFF))
				fileStream:WriteByte(self.bytes[i]:band(0xFF))
			else
				fileStream:WriteByte(self.bytes[i]:rshift(16):band(0xFF))
				fileStream:WriteByte(self.bytes[i]:rshift(8):band(0xFF))
				fileStream:WriteByte(self.bytes[i]:band(0xFF))
			end
		end
	end

	return fileStream
end
