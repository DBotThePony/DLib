
-- Copyright (C) 2017-2020 DBotThePony

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

local bitworker = DLib.bitworker

local type = type
local math = math
local assert = assert
local table = table
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local string = string
local bit = bit
local lshift = bit.lshift
local rshift = bit.rshift
local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local string_byte = string.byte
local string_char = string.char
local table_insert = table.insert
local math_floor = math.floor

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
DLib.BytesBuffer = setmetatable({proto = meta, meta = meta}, {__call = function(self, stringIn)
	local obj = setmetatable({}, meta)

	obj.pointer = 0

	if isstring(stringIn) then
		local bytes = {}

		for i = 1, #stringIn do
			bytes[i] = string_byte(stringIn, i)
		end

		obj.bytes = bytes
		obj.length = #bytes
	else
		obj.bytes = {}
		obj.length = 0
	end

	return obj
end})

--[[
	@doc
	@fname BytesBuffer:Seek
	@args number position

	@returns
	BytesBuffer: self
]]
-- Operations
function meta:Seek(moveTo)
	if moveTo < 0 or moveTo > self.length then
		error('Seek - invalid position (' .. moveTo .. '; ' .. self.length .. ')', 2)
	end

	self.pointer = moveTo
	return self
end

--[[
	@doc
	@fname BytesBuffer:Tell
	@alias BytesBuffer:Ask

	@returns
	number: pointer position
]]
function meta:Tell()
	return self.pointer
end

meta.Ask = meta.Tell

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
	assertType(valueIn, 'number', 'WriteUByte')
	assertRange(valueIn, 0, 0xFF, 'WriteUByte')

	valueIn = math_floor(valueIn)

	self.bytes[self.pointer + 1] = valueIn
	self.pointer = self.pointer + 1
	self.length = #self.bytes

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
	return self:WriteUByte(math_floor(valueIn) + 0x80)
end

-- one's component
function meta:WriteByte(valueIn)
	assertType(valueIn, 'number', 'WriteByte')
	assertRange(valueIn, -0x80, 0x7F, 'WriteByte')
	return self:WriteUByte(wrap(math_floor(valueIn), 0x80))
end

meta.WriteInt8 = meta.WriteByte
meta.WriteUInt8 = meta.WriteUByte

function meta:WriteChar(char)
	assertType(char, 'string', 'WriteChar')
	assert(#char == 1, 'Input is not a single char!')
	self:WriteUByte(string_byte(char))
	return self
end

--[[
	@doc
	@fname BytesBuffer:WriteShort_2
	@alias BytesBuffer:WriteInt16_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteShort
	@alias BytesBuffer:WriteInt16
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUShort
	@alias BytesBuffer:WriteUInt16
	@args number value

	@returns
	BytesBuffer: self
]]
function meta:WriteInt16_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt16')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16')
	return self:WriteUInt16(math_floor(valueIn) + 0x8000)
end

function meta:WriteInt16(valueIn)
	assertType(valueIn, 'number', 'WriteInt16')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16')
	return self:WriteUInt16(wrap(math_floor(valueIn), 0x8000))
end

function meta:WriteUInt16(valueIn)
	assertType(valueIn, 'number', 'WriteUInt16')
	assertRange(valueIn, 0, 0xFFFF, 'WriteUInt16')

	local bytes, pointer = self.bytes, self.pointer + 1

	bytes[pointer] = band(rshift(valueIn, 8), 0xFF)
	bytes[pointer + 1] = band(valueIn, 0xFF)
	self.pointer = pointer + 1
	self.length = #bytes

	return self
end

meta.WriteShort = meta.WriteInt16
meta.WriteShort_2 = meta.WriteInt16_2
meta.WriteUShort = meta.WriteUInt16

--[[
	@doc
	@fname BytesBuffer:WriteInt_2
	@alias BytesBuffer:WriteInt32_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt
	@alias BytesBuffer:WriteInt32
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUInt
	@alias BytesBuffer:WriteUInt32
	@args number value

	@returns
	BytesBuffer: self
]]
function meta:WriteInt32_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt32')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32')
	return self:WriteUInt32(math_floor(valueIn) + 0x80000000)
end

function meta:WriteInt32(valueIn)
	assertType(valueIn, 'number', 'WriteInt32')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32')
	return self:WriteUInt32(wrap(math_floor(valueIn), 0x80000000))
end

function meta:WriteUInt32(valueIn)
	assertType(valueIn, 'number', 'WriteUInt32')
	assertRange(valueIn, 0, 0xFFFFFFFF, 'WriteUInt32')

	local bytes, pointer = self.bytes, self.pointer + 1

	bytes[pointer] = band(rshift(valueIn, 24), 0xFF)
	bytes[pointer + 1] = band(rshift(valueIn, 16), 0xFF)
	bytes[pointer + 2] = band(rshift(valueIn, 8), 0xFF)
	bytes[pointer + 3] = band(valueIn, 0xFF)

	self.pointer = pointer + 3
	self.length = #bytes

	return self
end

meta.WriteInt = meta.WriteInt32
meta.WriteInt_2 = meta.WriteInt32_2
meta.WriteUInt = meta.WriteUInt32

--[[
	@doc
	@fname BytesBuffer:WriteLong_2
	@alias BytesBuffer:WriteInt64_2
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
	@fname BytesBuffer:WriteLong
	@alias BytesBuffer:WriteInt64
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
	@fname BytesBuffer:WriteULong
	@alias BytesBuffer:WriteUInt64
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

meta.WriteLong = meta.WriteInt64
meta.WriteLong_2 = meta.WriteInt64_2
meta.WriteULong = meta.WriteUInt64

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
	local value = self.bytes[self.pointer + 1]
	self.pointer = self.pointer + 1

	return value
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

	local bytes, pointer = self.bytes, self.pointer + 1

	local value =
		lshift(bytes[pointer], 8) +
		bytes[pointer + 1]

	self.pointer = pointer + 1

	return value
end

meta.ReadShort = meta.ReadInt16
meta.ReadShort_2 = meta.ReadInt16_2
meta.ReadUShort = meta.ReadUInt16

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

	local bytes, pointer = self.bytes, self.pointer + 1

	local value =
		lshift(bytes[pointer], 24) +
		lshift(bytes[pointer + 1], 16) +
		lshift(bytes[pointer + 2], 8) +
		bytes[pointer + 3]

	self.pointer = pointer + 3

	return value
end

meta.ReadInt = meta.ReadInt32
meta.ReadInt_2 = meta.ReadInt32_2
meta.ReadUInt = meta.ReadUInt32

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

	local bytes, pointer = self.bytes, self.pointer + 1

	local value =
		bytes[pointer] * 0x100000000000000 +
		bytes[pointer + 1] * 0x1000000000000 +
		bytes[pointer + 2] * 0x10000000000 +
		bytes[pointer + 3] * 0x100000000 +
		lshift(bytes[pointer + 4], 24) +
		lshift(bytes[pointer + 5], 16) +
		lshift(bytes[pointer + 6], 8) +
		bytes[pointer + 7]

	self.pointer = pointer + 7

	return value
end

meta.ReadLong = meta.ReadInt32
meta.ReadLong_2 = meta.ReadInt32_2
meta.ReadULong = meta.ReadUInt32

--[[
	@doc
	@fname BytesBuffer:WriteFloatSlow
	@args number float

	@desc
	due to precision errors, this is a slightly inaccurate operation
	*This function internally utilize tables, so it can hog memory*
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:WriteFloatSlow(valueIn)
	assertType(valueIn, 'number', 'WriteFloat')
	local bits = bitworker.FloatToBinaryIEEE(valueIn, 8, 23)
	local bitsInNumber = bitworker.BinaryToUInteger(bits)
	return self:WriteUInt32(bitsInNumber)
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
function meta:WriteFloat(valueIn)
	assertType(valueIn, 'number', 'WriteFloat')
	return self:WriteInt32(bitworker.FastFloatToBinaryIEEE(valueIn))
end

--[[
	@doc
	@fname BytesBuffer:ReadFloatSlow

	@desc
	due to precision errors, this is a slightly inaccurate operation
	*This function internally utilize tables, so it can hog memory*
	@enddesc

	@returns
	number
]]
function meta:ReadFloatSlow()
	local bitsInNumber = self:ReadUInt32()
	local bits = bitworker.UIntegerToBinary(bitsInNumber, 32)
	return bitworker.BinaryToFloatIEEE(bits, 8, 23)
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
	return bitworker.FastBinaryToFloatIEEE(self:ReadUInt32())
end

--[[
	@doc
	@fname BytesBuffer:WriteDoubleSlow
	@args number double

	@desc
	due to precision errors, this is a inaccurate operation
	*This function internally utilize tables, so it can hog memory*
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:WriteDoubleSlow(valueIn)
	assertType(valueIn, 'number', 'WriteDouble')
	local bits = bitworker.FloatToBinaryIEEE(valueIn, 11, 52)
	local bytes = bitworker.BitsToBytes(bits)

	local bytes, pointer = self.bytes, self.pointer + 1

	bytes[pointer] = bytes[1]
	bytes[pointer + 1] = bytes[2]
	bytes[pointer + 2] = bytes[3]
	bytes[pointer + 3] = bytes[4]
	bytes[pointer + 4] = bytes[5]
	bytes[pointer + 5] = bytes[6]
	bytes[pointer + 6] = bytes[7]
	bytes[pointer + 7] = bytes[8]

	self.pointer = pointer + 7
	self.length = #bytes

	return self
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

	local int1, int2 = bitworker.FastDoubleToBinaryIEEE(valueIn)
	local bytes, pointer = self.bytes, self.pointer + 1

	int1 = wrap(int1, 0x80000000)
	int2 = wrap(int2, 0x80000000)

	bytes[pointer] = band(rshift(int1, 24), 0xFF)
	bytes[pointer + 1] = band(rshift(int1, 16), 0xFF)
	bytes[pointer + 2] = band(rshift(int1, 8), 0xFF)
	bytes[pointer + 3] = band(int1, 0xFF)

	bytes[pointer + 4] = band(rshift(int2, 24), 0xFF)
	bytes[pointer + 5] = band(rshift(int2, 16), 0xFF)
	bytes[pointer + 6] = band(rshift(int2, 8), 0xFF)
	bytes[pointer + 7] = band(int2, 0xFF)

	self.pointer = pointer + 7
	self.length = #bytes

	return self
end

--[[
	@doc
	@fname BytesBuffer:ReadDoubleSlow

	@desc
	due to precision errors, this is a slightly inaccurate operation
	*This function internally utilize tables, so it can hog memory*
	@enddesc

	@returns
	number
]]
function meta:ReadDoubleSlow()
	local bytes1 = self:ReadUInt32()
	local bytes2 = self:ReadUInt32()
	local bits = {}
	table.append(bits, bitworker.UIntegerToBinary(bytes1, 32))
	table.append(bits, bitworker.UIntegerToBinary(bytes2, 32))
	return bitworker.BinaryToFloatIEEE(bits, 11, 52)
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
	return bitworker.FastBinaryToDoubleIEEE(self:ReadUInt32(), self:ReadUInt32())
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

	if #stringIn == 0 then
		self:WriteUByte(0)
		return self
	end

	local bytes = self.bytes
	local pointer = self.pointer + 1

	-- LuaJIT optimize such loop so it is pretty fast
	for i = 1, #stringIn do
		local byte = string_byte(stringIn, i)

		if byte == 0 then
			error('NUL terminator in string at ' .. i)
		else
			bytes[pointer] = byte
			pointer = pointer + 1
		end
	end

	self.length = #bytes
	self.pointer = pointer - 1

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
	self:CheckOverflow('String', 1)
	local bytes = self.bytes

	for i = self.pointer + 1, self.length do
		if bytes[i] == 0 then
			local string = self:StringSlice(self.pointer + 1, i - 1)
			self.pointer = i
			return string
		end
	end

	error('No NUL terminator was found while reached EOF')
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

	local bytes = self.bytes
	local pointer = self.pointer + 1

	-- LuaJIT optimize such loop so it is pretty fast
	for i = 1, #binaryString do
		bytes[pointer] = string_byte(binaryString, i)
		pointer = pointer + 1
	end

	self.length = #bytes
	self.pointer = pointer - 1

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

	local slice = self:StringSlice(self.pointer + 1, self.pointer + readAmount)
	self.pointer = self.pointer + readAmount

	return slice
end

meta.WriteData = meta.WriteBinary
meta.ReadData = meta.ReadBinary

function meta:ReadChar()
	return string_char(self:ReadUByte())
end

--[[
	@doc
	@fname BytesBuffer:ToString

	@returns
	string
]]
function meta:ToString()
	return self:StringSlice(1, self.length)
end

--[[
	@doc
	@fname BytesBuffer:StringSlice
	@internal

	@returns
	string
]]
function meta:StringSlice(slice_start, slice_end)
	local strings = {}
	slice_start = slice_start - 1

	while slice_start < slice_end do
		local nexti = math.min(7996, slice_end - slice_start)

		table_insert(strings, string_char(unpack(self.bytes, slice_start + 1, slice_start + nexti)))
		slice_start = slice_start + nexti
	end

	return table.concat(strings, '')
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

	for i, byte in ipairs(self.bytes) do
		fileStream:WriteByte(byte)
	end

	return fileStream
end

--[[
	@doc
	@fname DLib.BytesBuffer.CompileStructure
	@args string structureDef, table customTypes

	@desc
	Reads a structure from current pointer position
	this is somewhat fancy way of reading typical headers and stuff
	The string is in next format:
	```
	type identifier with any symbols
	type on_next_line
	uint32 thing
	```
	Supported types:
	`int8`
	`int16`
	`int32`
	`int64`
	`bigint`
	`float`
	`double`
	`uint8`
	`uint16`
	`uint32`
	`uint64`
	`ubigint`
	`string` - NUL terminated string
	@enddesc

	@returns
	function: a function to pass `BytesBuffer` to get readed structure
]]
function DLib.BytesBuffer.CompileStructure(structureDef, callbacks)
	local output = {}

	for i, line in ipairs(structureDef:split('\n')) do
		line = line:trim()
		--assert(line ~= '', 'Invalid line definition at ' .. i)

		if line ~= '' then
			local findSpace = assert(line:find('%s'), 'Can\'t find variable name at line ' .. i)
			local rtype2 = line:sub(1, findSpace):trim()
			local rtype = rtype2:lower()
			local rname = line:sub(findSpace + 1):trim()
			local findCommentary = rname:find('%s//')

			if findCommentary then
				rname = rname:sub(1, findCommentary):trim()
			end

			if rtype == 'int8' or rtype == 'byte' then
				table_insert(output, {rname, meta.ReadByte})
			elseif rtype == 'int16' or rtype == 'short' then
				table_insert(output, {rname, meta.ReadInt16})
			elseif rtype == 'int32' or rtype == 'long' or rtype == 'int' then
				table_insert(output, {rname, meta.ReadInt32})
			elseif rtype == 'int64' or rtype == 'longlong' or rtype == 'bigint' then
				table_insert(output, {rname, meta.ReadInt64})
			elseif rtype == 'uint8' or rtype == 'ubyte' then
				table_insert(output, {rname, meta.ReadUByte})
			elseif rtype == 'uint16' or rtype == 'ushort' then
				table_insert(output, {rname, meta.ReadUInt16})
			elseif rtype == 'uint32' or rtype == 'ulong' or rtype == 'uint' then
				table_insert(output, {rname, meta.ReadUInt32})
			elseif rtype == 'uint64' or rtype == 'ulong64' or rtype == 'biguint' or rtype == 'ubigint' then
				table_insert(output, {rname, meta.ReadUInt64})
			elseif rtype == 'float' then
				table_insert(output, {rname, meta.ReadFloat})
			elseif rtype == 'double' then
				table_insert(output, {rname, meta.ReadDouble})
			elseif rtype == 'variable' or rtype == 'string' then
				table_insert(output, {rname, meta.ReadString})
			elseif callbacks and callbacks[rtype2] then
				table_insert(output, {rname, callbacks[rtype2]})
			else
				DLib.MessageError(debug.traceback('Undefined type: ' .. rtype))
			end
		end
	end

	return function(self)
		local read = {}

		for i, data in ipairs(output) do
			read[data[1]] = data[2](self, read)
		end

		return read
	end
end

--[[
	@doc
	@fname BytesBuffer:ReadStructure
	@args string structureDef, table customTypes

	@desc
	`DLib.BytesBuffer.CompileStructure(structureDef, customTypes)(self)`
	@enddesc

	@returns
	table: the read structure
]]
function meta:ReadStructure(structureDef, callbacks)
	return DLib.BytesBuffer.CompileStructure(structureDef, callbacks)(self)
end

local meta_view = {}
local meta_bytes = {}

function meta_view:StringSlice(slice_start, slice_end)
	local strings = {}
	local self_slice_start, self_slice_end = self.slice_start, self.slice_end
	local aqs = self_slice_start + (slice_start - 1):max(0)
	local aqe = aqs + (slice_end - slice_start + 1)
	local distance = aqe - aqs
	local started = false

	for i, buffer in ipairs(self.buffers) do
		if buffer.length >= aqs then
			table_insert(strings, buffer:StringSlice((aqs + 1):max(1), aqe:min(buffer.length)))
		end

		aqs = aqs - buffer.length
		aqe = aqe - buffer.length

		if aqe <= 0 then break end
	end

	return table.concat(strings, '')
end

function meta_view:CalculateTotalLength()
	local length = 0

	for _, buffer in ipairs(self.buffers) do
		length = length + buffer.length
	end

	return length
end

function meta_view:__index(key)
	local value = rawget(self, key)

	if value ~= nil then return value end

	--[[if key == 'length' then
		return meta_view.CalculateLength(self)
	end]]

	return meta_view[key] or meta[key]
end

function meta_bytes:__index(key)
	if not isnumber(key) then return end
	local self2 = rawget(self, 'self')
	key = key + self2.slice_start

	if key < 0 then return end
	if key > self2.slice_end then return end

	for _, buffer in ipairs(self2.buffers) do
		local key2 = key - buffer.length

		if key2 <= 0 then
			return buffer.bytes[key]
		else
			key = key2
		end
	end
end

function meta_bytes:__newindex(key, value)
	if not isnumber(key) then return end
	local self2 = rawget(self, 'self')
	key = key + self2.slice_start

	if key < 0 then return end
	if key > self2.slice_end then return end

	for _, buffer in ipairs(self2.buffers) do
		local key2 = key - buffer.length

		if key2 <= 0 then
			buffer.bytes[key] = value
			return
		else
			key = key2
		end
	end
end

--[[
	@doc
	@fname DLib.BytesBufferView
	@args number slice_start, number slice_end, vararg buffers

	@desc
	Allows you to create lightweight slices of one or more buffers at specified positions
	Keep in mind that this is generally slower to work with big slices since there is a cost at translating
	byte index to corresponding buffers
	This object expose every property and method regular `BytesBuffer` has
	@descdesc

	@returns
	BytesBufferView: newly created object
]]
DLib.BytesBufferView = setmetatable({proto = meta_view, meta = meta_view}, {__call = function(self, slice_start, slice_end, ...)
	if select('#', ...) == 0 then
		error('You should provide at least one buffer for view!')
	end

	assert(isnumber(slice_start) and slice_start >= 0, 'Invalid slice start')
	assert(isnumber(slice_end) and slice_end >= slice_start, 'Invalid slice end')

	local obj = setmetatable({}, meta_view)
	obj.pointer = 0
	obj.length = slice_end - slice_start
	obj.slice_start = slice_start
	obj.slice_end = slice_end
	obj.buffers = {...}
	obj.bytes = setmetatable({self = obj}, meta_bytes)

	return obj
end})
