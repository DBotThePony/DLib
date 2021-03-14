
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
local meta, metaclass = {}, {}

local BitWorker = DLib.BitWorker
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
local bswap = bit.bswap
local string_byte = string.byte
local string_char = string.char
local table_insert = table.insert
local math_floor = math.floor
local math_ceil = math.ceil

local function get_1_bytes_le(optimize, pointer, bytes)
	if optimize then
		return band(rshift(bytes[rshift(pointer, 2) + 1], band(pointer, 0x3) * 8), 0xFF)
	end

	return bytes[pointer + 1]
end

local function get_2_bytes_le(optimize, pointer, bytes)
	if optimize then
		local pick = band(pointer, 0x3)
		pointer = rshift(pointer, 2) + 1

		if pick == 0 then
			local value = bytes[pointer]
			return band(value, 0xFF), band(rshift(value, 8), 0xFF)
		end

		if pick == 1 then
			local value = bytes[pointer]
			return band(rshift(value, 8), 0xFF), band(rshift(value, 16), 0xFF)
		end

		if pick == 2 then
			local value = bytes[pointer]
			return band(rshift(value, 16), 0xFF), band(rshift(value, 24), 0xFF)
		end

		local value_a = bytes[pointer]
		local value_b = bytes[pointer + 1]

		return band(rshift(value_a, 24), 0xFF), band(value_b, 0xFF)
	end

	return bytes[pointer + 1], bytes[pointer + 2]
end

local function get_3_bytes_le(optimize, pointer, bytes)
	if optimize then
		local pick = band(pointer, 0x3)
		pointer = rshift(pointer, 2) + 1

		if pick == 0 then
			local value = bytes[pointer]
			return band(value, 0xFF), band(rshift(value, 8), 0xFF), band(rshift(value, 16), 0xFF)
		end

		if pick == 1 then
			local value = bytes[pointer]
			return band(rshift(value, 8), 0xFF), band(rshift(value, 16), 0xFF), band(rshift(value, 24), 0xFF)
		end

		if pick == 2 then
			local value_a = bytes[pointer]
			local value_b = bytes[pointer + 1]

			return band(rshift(value_a, 16), 0xFF), band(rshift(value_a, 24), 0xFF), band(value_b, 0xFF)
		end

		local value_a = bytes[pointer]
		local value_b = bytes[pointer + 1]

		return band(rshift(value_a, 24), 0xFF), band(value_b, 0xFF), band(rshift(value_b, 8), 0xFF)
	end

	return bytes[pointer + 1], bytes[pointer + 2], bytes[pointer + 3]
end

local function get_4_bytes_le(optimize, pointer, bytes)
	if optimize then
		local pick = band(pointer, 0x3)
		pointer = rshift(pointer, 2) + 1

		if pick == 0 then
			local value = bytes[pointer]
			return band(value, 0xFF), band(rshift(value, 8), 0xFF), band(rshift(value, 16), 0xFF), band(rshift(value, 24), 0xFF)
		end

		local value_a = bytes[pointer]
		local value_b = bytes[pointer + 1]

		if pick == 1 then
			return band(rshift(value_a, 8), 0xFF), band(rshift(value_a, 16), 0xFF), band(rshift(value_a, 24), 0xFF), band(value_b, 0xFF)
		end

		if pick == 2 then
			return band(rshift(value_a, 16), 0xFF), band(rshift(value_a, 24), 0xFF), band(rshift(value_b, 0), 0xFF), band(rshift(value_b, 8), 0xFF)
		end

		return band(rshift(value_a, 24), 0xFF), band(rshift(value_b, 0), 0xFF), band(rshift(value_b, 8), 0xFF), band(rshift(value_b, 16), 0xFF)
	end

	return bytes[pointer + 1], bytes[pointer + 2], bytes[pointer + 3], bytes[pointer + 4]
end

local function set_1_bytes_le(optimize, pointer, bytes, value)
	if optimize then
		local pick = band(pointer, 0x3)
		pointer = rshift(pointer, 2) + 1

		if pick == 0 then
			bytes[pointer] = bor(band(bytes[pointer], 0xFFFFFF00), value)
			return
		end

		if pick == 1 then
			bytes[pointer] = bor(band(bytes[pointer], 0xFFFF00FF), lshift(value, 8))
			return
		end

		if pick == 2 then
			bytes[pointer] = bor(band(bytes[pointer], 0xFF00FFFF), lshift(value, 16))
			return
		end

		bytes[pointer] = bor(band(bytes[pointer], 0x00FFFFFF), lshift(value, 24))
	end

	bytes[pointer + 1] = band(value, 0xFF)
end

local function set_2_bytes_le(optimize, pointer, bytes, value)
	if optimize then
		local pick = band(pointer, 0x3)
		pointer = rshift(pointer, 2) + 1

		if pick == 0 then
			bytes[pointer] = bor(band(bytes[pointer], 0xFFFF0000), value)
			return
		end

		if pick == 1 then
			bytes[pointer] = bor(band(bytes[pointer], 0xFF0000FF), lshift(value, 8))
			return
		end

		if pick == 2 then
			bytes[pointer] = bor(band(bytes[pointer], 0x0000FFFF), lshift(value, 16))
			return
		end

		bytes[pointer] = bor(band(bytes[pointer], 0x00FFFFFF), lshift(value, 24))
		bytes[pointer + 1] = bor(band(bytes[pointer + 1], 0xFFFFFF00), rshift(value, 8))
	end

	bytes[pointer + 1] = band(value, 0xFF)
	bytes[pointer + 2] = rshift(band(value, 0xFF00), 8)
end

local function set_3_bytes_le(optimize, pointer, bytes, value)
	if optimize then
		local pick = band(pointer, 0x3)
		pointer = rshift(pointer, 2) + 1

		if pick == 0 then
			bytes[pointer] = bor(band(bytes[pointer], 0xFF000000), value)
			return
		end

		if pick == 1 then
			bytes[pointer] = bor(band(bytes[pointer], 0x000000FF), lshift(value, 8))
			return
		end

		if pick == 2 then
			bytes[pointer] = bor(band(bytes[pointer], 0x0000FFFF), lshift(value, 16))
			bytes[pointer + 1] = bor(band(bytes[pointer + 1], 0xFFFFFF00), rshift(value, 16))

			return
		end

		bytes[pointer] = bor(band(bytes[pointer], 0x00FFFFFF), lshift(value, 24))
		bytes[pointer + 1] = bor(band(bytes[pointer + 1], 0xFFFF0000), rshift(value, 8))
	end

	bytes[pointer + 1] = band(value, 0xFF)
	bytes[pointer + 2] = rshift(band(value, 0xFF00), 8)
	bytes[pointer + 3] = rshift(band(value, 0xFF0000), 16)
end

local function set_4_bytes_le(optimize, pointer, bytes, value)
	if optimize then
		local pick = band(pointer, 0x3)
		pointer = rshift(pointer, 2) + 1

		if pick == 0 then
			bytes[pointer] = value
			return
		end

		if pick == 1 then
			bytes[pointer] = bor(band(bytes[pointer], 0x000000FF), lshift(value, 8))
			bytes[pointer + 1] = bor(band(bytes[pointer + 1], 0xFFFFFF00), rshift(value, 24))
			return
		end

		if pick == 2 then
			bytes[pointer] = bor(band(bytes[pointer], 0x0000FFFF), lshift(value, 16))
			bytes[pointer + 1] = bor(band(bytes[pointer + 1], 0xFFFF0000), rshift(value, 16))
			return
		end

		bytes[pointer] = bor(band(bytes[pointer], 0x00FFFFFF), lshift(value, 24))
		bytes[pointer + 1] = bor(band(bytes[pointer + 1], 0xFF000000), rshift(value, 8))
	end

	bytes[pointer + 1] = band(value, 0xFF)
	bytes[pointer + 2] = rshift(band(value, 0xFF00), 8)
	bytes[pointer + 3] = rshift(band(value, 0xFF0000), 16)
	bytes[pointer + 4] = rshift(band(value, 0xFF000000), 24)
end

--[[
	@doc
	@fname DLib.BytesBuffer
	@args string binary = ''

	@desc
	entry point of BytesBuffer creation
	you can pass a string to it to construct bytes array from it
	**BUFFER BY DEFAULT WORK WITH BIG ENDIAN BYTES**
	To work with Little Endian bytes, use appropriate functions
	@enddesc

	@returns
	BytesBuffer: newly created object
]]
function meta:ctor(stringIn)
	self.pointer = 0

	if isstring(stringIn) then
		local bytes = {}

		local length = #stringIn

		for i = 1, math_floor(length / 4) do
			local a, b, c, d = string_byte(stringIn, (i - 1) * 4 + 1, (i - 1) * 4 + 4)
			bytes[i] = a + lshift(b, 8) + lshift(c, 16) + lshift(d, 24)
		end

		self.bytes = bytes
		self.length = length

		local _length = band(length, 3)

		if _length == 1 then
			bytes[#bytes + 1] = string_byte(stringIn, length)
		elseif _length == 2 then
			local a, b = string_byte(stringIn, length - 1, length)
			bytes[#bytes + 1] = a + lshift(b, 8)
		elseif _length == 3 then
			local a, b, c = string_byte(stringIn, length - 2, length)
			bytes[#bytes + 1] = a + lshift(b, 8) + lshift(c, 16)
		end
	else
		self.bytes = {}
		self.length = 0
	end

	self.o = true
end

--[[
	@doc
	@fname BytesBuffer:Unoptimize

	@internal
	@desc
	Called internally by BytesBufferView
	Forces buffer to represent itself as ubyte array instead of uint32
	@enddesc
]]
function meta:Unoptimize()
	if not self.o then return end

	local bytes = self.bytes
	self.bytes = {}
	local _bytes = self.bytes
	local index = 1

	self.o = false

	for i = 1, #bytes do
		local uint = bytes[i]
		_bytes[index] = band(uint, 0xFF)
		_bytes[index + 1] = rshift(band(uint, 0xFF00), 8)
		_bytes[index + 2] = rshift(band(uint, 0xFF0000), 16)
		_bytes[index + 3] = rshift(band(uint, 0xFF000000), 24)
		index = index + 4
	end
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

	@desc
	Whatever is stored there is not guaranteed to be like that across DLib versions
	The array is optimized exclusively for inner class usage
	@enddesc

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
	@fname BytesBuffer:IsEOF
	@alias BytesBuffer:EndOfStream

	@returns
	boolean
]]
function meta:EndOfStream()
	return self.pointer >= self.length
end

function meta:IsEOF()
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

	local pointer = self.pointer
	local bytes = self.bytes
	local length = self.length

	if pointer == length then
		self.length = length + 1
		local index = rshift(pointer, 2) + 1

		if bytes[index] == nil then
			bytes[index] = 0
		end
	end

	set_1_bytes_le(self.o, pointer, bytes, valueIn)
	self.pointer = pointer + 1

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
	@fname BytesBuffer:WriteShortLE_2
	@alias BytesBuffer:WriteInt16LE_2
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
	@fname BytesBuffer:WriteShortLE
	@alias BytesBuffer:WriteInt16LE
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

--[[
	@doc
	@fname BytesBuffer:WriteUShortLE
	@alias BytesBuffer:WriteUInt16LE
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

function meta:WriteInt16LE_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt16LE')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16LE')
	return self:WriteUInt16LE(math_floor(valueIn) + 0x8000)
end

function meta:WriteInt16LE(valueIn)
	assertType(valueIn, 'number', 'WriteInt16LE')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16LE')
	return self:WriteUInt16LE(wrap(math_floor(valueIn), 0x8000))
end

function meta:WriteUInt16(valueIn)
	assertType(valueIn, 'number', 'WriteUInt16')
	assertRange(valueIn, 0, 0xFFFF, 'WriteUInt16')

	local pointer = self.pointer
	local bytes = self.bytes
	local length = self.length

	if pointer + 1 >= length then
		self.length = pointer + 2

		if self.o then
			local index = rshift(pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_2_bytes_le(self.o, pointer, bytes, rshift(bswap(valueIn), 16))
	self.pointer = pointer + 2

	return self
end

function meta:WriteUInt16LE(valueIn)
	assertType(valueIn, 'number', 'WriteUInt16LE')
	assertRange(valueIn, 0, 0xFFFF, 'WriteUInt16LE')

	local pointer = self.pointer
	local bytes = self.bytes
	local length = self.length

	if pointer + 1 >= length then
		self.length = pointer + 2

		if self.o then
			local index = rshift(pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_2_bytes_le(self.o, pointer, bytes, valueIn)
	self.pointer = pointer + 2

	return self
end

meta.WriteShort = meta.WriteInt16
meta.WriteShortLE = meta.WriteInt16LE
meta.WriteShort_2 = meta.WriteInt16_2
meta.WriteShortLE_2 = meta.WriteInt16LE_2
meta.WriteUShort = meta.WriteUInt16
meta.WriteUShortLE = meta.WriteUInt16LE

--[[
	@doc
	@fname BytesBuffer:WriteInt24_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt24LE_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt24
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt24LE
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUInt24
	@args number value

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUInt24LE
	@args number value

	@returns
	BytesBuffer: self
]]
function meta:WriteInt24_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt24')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24')
	return self:WriteUInt24(math_floor(valueIn) + 0x8000)
end

function meta:WriteInt24(valueIn)
	assertType(valueIn, 'number', 'WriteInt24')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24')
	return self:WriteUInt24(wrap(math_floor(valueIn), 0x800000))
end

function meta:WriteInt24LE_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt24LE')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24LE')
	return self:WriteUInt24LE(math_floor(valueIn) + 0x800000)
end

function meta:WriteInt24LE(valueIn)
	assertType(valueIn, 'number', 'WriteInt24LE')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24LE')
	return self:WriteUInt24LE(wrap(math_floor(valueIn), 0x800000))
end

function meta:WriteUInt24(valueIn)
	assertType(valueIn, 'number', 'WriteUInt24')
	assertRange(valueIn, 0, 0xFFFFFF, 'WriteUInt24')

	local pointer = self.pointer
	local bytes = self.bytes
	local length = self.length

	if pointer + 2 >= length then
		self.length = pointer + 3

		if self.o then
			local index = rshift(pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 2, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_3_bytes_le(self.o, pointer, bytes, rshift(bswap(valueIn), 8))
	self.pointer = pointer + 3

	return self
end

function meta:WriteUInt24LE(valueIn)
	assertType(valueIn, 'number', 'WriteUInt24LE')
	assertRange(valueIn, 0, 0xFFFFFF, 'WriteUInt24LE')

	local pointer = self.pointer
	local bytes = self.bytes
	local length = self.length

	if pointer + 2 >= length then
		self.length = pointer + 3

		if self.o then
			local index = rshift(pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 2, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_3_bytes_le(self.o, pointer, bytes, valueIn)
	self.pointer = pointer + 3

	return self
end

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

--[[
	@doc
	@fname BytesBuffer:WriteIntLE_2
	@alias BytesBuffer:WriteInt32LE_2
	@args number value

	@desc
	with value shift
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteIntLE
	@alias BytesBuffer:WriteInt32LE
	@args number value

	@desc
	with negative number overflow
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteUIntLE
	@alias BytesBuffer:WriteUInt32LE
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

	local pointer = self.pointer
	local bytes = self.bytes
	local length = self.length

	if pointer + 3 >= length then
		self.length = pointer + 4

		if self.o then
			local index = rshift(pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 2, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 3, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_4_bytes_le(self.o, pointer, bytes, bswap(valueIn))
	self.pointer = pointer + 4

	return self
end

function meta:WriteInt32LE_2(valueIn)
	assertType(valueIn, 'number', 'WriteInt32LE')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32LE')
	return self:WriteUInt32LE(math_floor(valueIn) + 0x80000000)
end

function meta:WriteInt32LE(valueIn)
	assertType(valueIn, 'number', 'WriteInt32LE')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32LE')
	return self:WriteUInt32LE(wrap(math_floor(valueIn), 0x80000000))
end

function meta:WriteUInt32LE(valueIn)
	assertType(valueIn, 'number', 'WriteUInt32')
	assertRange(valueIn, 0, 0xFFFFFFFF, 'WriteUInt32')

	local pointer = self.pointer
	local bytes = self.bytes
	local length = self.length

	if pointer + 3 >= length then
		self.length = pointer + 4

		if self.o then
			local index = rshift(pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 2, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(pointer + 3, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_4_bytes_le(self.o, pointer, bytes, valueIn)
	self.pointer = pointer + 4

	return self
end

meta.WriteInt = meta.WriteInt32
meta.WriteInt_2 = meta.WriteInt32_2
meta.WriteUInt = meta.WriteUInt32

meta.WriteIntLE = meta.WriteInt32LE
meta.WriteIntLE_2 = meta.WriteInt32LE_2
meta.WriteUIntLE = meta.WriteUInt32LE

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

--[[
	@doc
	@fname BytesBuffer:WriteLongLE_2
	@alias BytesBuffer:WriteInt64LE_2
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
	@fname BytesBuffer:WriteLongLE
	@alias BytesBuffer:WriteInt64LE
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
	@fname BytesBuffer:WriteULongLE
	@alias BytesBuffer:WriteUInt64LE
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

function meta:WriteInt64LE_2(valueIn)
	self:WriteUInt64LE(valueIn + 0x100000000)
	return self
end

function meta:WriteInt64(valueIn)
	self:WriteUInt64LE(wrap(valueIn, 0x100000000))
	return self
end

function meta:WriteUInt64LE(valueIn)
	local div = valueIn % 0xFFFFFFFF
	self:WriteUInt32(div)
	self:WriteUInt32((valueIn - div) / 0xFFFFFFFF)
	return self
end

meta.WriteLong = meta.WriteInt64
meta.WriteLong_2 = meta.WriteInt64_2
meta.WriteULong = meta.WriteUInt64

meta.WriteLongLE = meta.WriteInt64LE
meta.WriteLongLE_2 = meta.WriteInt64LE_2
meta.WriteULongLE = meta.WriteUInt64LE

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
	local pointer = self.pointer
	self.pointer = pointer + 1
	return get_1_bytes_le(self.o, pointer, self.bytes)
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

--[[
	@doc
	@fname BytesBuffer:ReadInt16LE_2

	@desc
	with value shift
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt16LE

	@desc
	with negative number overflow
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt16LE

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
	local pointer = self.pointer
	self.pointer = pointer + 2
	local a, b = get_2_bytes_le(self.o, pointer, self.bytes)
	return bor(lshift(a, 8), b)
end

function meta:ReadInt16LE_2()
	return self:ReadUInt16LE() - 0x8000
end

function meta:ReadInt16LE()
	return unwrap(self:ReadUInt16LE(), 0x8000)
end

function meta:ReadUInt16LE()
	self:CheckOverflow('UInt16LE', 2)
	local pointer = self.pointer
	self.pointer = pointer + 2
	local a, b = get_2_bytes_le(self.o, pointer, self.bytes)
	return bor(lshift(b, 8), a)
end

meta.ReadShort = meta.ReadInt16
meta.ReadShort_2 = meta.ReadInt16_2
meta.ReadUShort = meta.ReadUInt16

meta.ReadShortLE = meta.ReadInt16LE
meta.ReadShortLE_2 = meta.ReadInt16LE_2
meta.ReadUShortLE = meta.ReadUInt16LE

--[[
	@doc
	@fname BytesBuffer:ReadInt24_2

	@desc
	with value shift
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt24

	@desc
	with negative number overflow
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt24

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt24LE_2

	@desc
	with value shift
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt24LE

	@desc
	with negative number overflow
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt24LE

	@returns
	number
]]
function meta:ReadInt24_2()
	return self:ReadUInt24() - 0x800000
end

function meta:ReadInt24()
	return unwrap(self:ReadUInt24(), 0x800000)
end

function meta:ReadUInt24()
	self:CheckOverflow('UInt24', 3)
	local pointer = self.pointer
	self.pointer = pointer + 3
	local a, b, c = get_3_bytes_le(self.o, pointer, self.bytes)
	return bor(lshift(a, 8), b, lshift(c, 16))
end

function meta:ReadInt24LE_2()
	return self:ReadUInt24LE() - 0x800000
end

function meta:ReadInt24LE()
	return unwrap(self:ReadUInt24LE(), 0x800000)
end

function meta:ReadUInt24LE()
	self:CheckOverflow('UInt24LE', 3)
	local pointer = self.pointer
	self.pointer = pointer + 3
	local a, b, c = get_3_bytes_le(self.o, pointer, self.bytes)
	return bor(lshift(c, 16), lshift(b, 8), a)
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

--[[
	@doc
	@fname BytesBuffer:ReadInt32LE_2

	@desc
	with value shift
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt32LE

	@desc
	with negative number overflow
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt32LE

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
	local pointer = self.pointer
	self.pointer = pointer + 4
	local a, b, c, d = get_4_bytes_le(self.o, pointer, self.bytes)
	return bor(lshift(a, 24), lshift(b, 16), lshift(c, 8), d)
end

function meta:ReadInt32LE_2()
	return self:ReadUInt32LE() - 0x80000000
end

function meta:ReadInt32LE()
	return unwrap(self:ReadUInt32LE(), 0x80000000)
end

function meta:ReadUInt32LE()
	self:CheckOverflow('UInt32LE', 4)
	local pointer = self.pointer
	self.pointer = pointer + 4
	local a, b, c, d = get_4_bytes_le(self.o, pointer, self.bytes)
	return bor(lshift(d, 24), lshift(c, 16), lshift(b, 8), a)
end

meta.ReadInt = meta.ReadInt32
meta.ReadInt_2 = meta.ReadInt32_2
meta.ReadUInt = meta.ReadUInt32

meta.ReadIntLE = meta.ReadInt32LE
meta.ReadIntLE_2 = meta.ReadInt32LE_2
meta.ReadUIntLE = meta.ReadUInt32LE

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

--[[
	@doc
	@fname BytesBuffer:ReadInt64LE_2

	@desc
	with value shift
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt64LE

	@desc
	with negative number overflow
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadUInt64LE

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

	local pointer = self.pointer
	self.pointer = pointer + 8

	local a, b, c, d = get_4_bytes_le(self.o, pointer, self.bytes)
	local e, f, g, k = get_4_bytes_le(self.o, pointer + 4, self.bytes)

	return
		a * 0x100000000000000 +
		b * 0x1000000000000 +
		c * 0x10000000000 +
		d * 0x100000000 +
		bor(lshift(e, 24), lshift(f, 16), lshift(g, 8), k)
end

function meta:ReadInt64LE_2()
	return self:ReadUInt64LE() - 0x100000000
end

function meta:ReadInt64()
	return unwrap(self:ReadUInt64LE(), 0x100000000)
end

function meta:ReadUInt64LE()
	self:CheckOverflow('UInt64LE', 8)

	local k, g, f, e = get_4_bytes_le(self.o, pointer, self.bytes)
	local d, c, b, a = get_4_bytes_le(self.o, pointer + 4, self.bytes)

	return
		a * 0x100000000000000 +
		b * 0x1000000000000 +
		c * 0x10000000000 +
		d * 0x100000000 +
		bor(lshift(e, 24), lshift(f, 16), lshift(g, 8), k)
end

meta.ReadLong = meta.ReadInt32
meta.ReadLong_2 = meta.ReadInt32_2
meta.ReadULong = meta.ReadUInt32

meta.ReadLongLE = meta.ReadInt32LE
meta.ReadLongLE_2 = meta.ReadInt32LE_2
meta.ReadULongLE = meta.ReadUInt32LE

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
	local bits = BitWorker.FloatToBinaryIEEE(valueIn, 8, 23)
	local bitsInNumber = BitWorker.BinaryToUInteger(bits)
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

--[[
	@doc
	@fname BytesBuffer:WriteFloatLE
	@args number float

	@desc
	due to precision errors, this is a slightly inaccurate operation
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:WriteFloat(valueIn)
	assertType(valueIn, 'number', 'WriteFloat')
	return self:WriteInt32(BitWorker.FastFloatToBinaryIEEE(valueIn))
end

function meta:WriteFloatLE(valueIn)
	assertType(valueIn, 'number', 'WriteFloatLE')
	return self:WriteInt32LE(BitWorker.FastFloatToBinaryIEEE(valueIn))
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
	local bits = BitWorker.UIntegerToBinary(bitsInNumber, 32)
	return BitWorker.BinaryToFloatIEEE(bits, 8, 23)
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

--[[
	@doc
	@fname BytesBuffer:ReadFloatLE

	@desc
	due to precision errors, this is a slightly inaccurate operation
	@enddesc

	@returns
	number
]]
function meta:ReadFloat()
	return BitWorker.FastBinaryToFloatIEEE(self:ReadUInt32())
end

function meta:ReadFloatLE()
	return BitWorker.FastBinaryToFloatIEEE(self:ReadUInt32LE())
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
	local bits = BitWorker.FloatToBinaryIEEE(valueIn, 11, 52)
	local bytes = BitWorker.BitsToBytes(bits)

	self:WriteUInt32(wrap(bor(lshift(bytes[1], 24), lshift(bytes[2], 16), lshift(bytes[3], 8), bytes[4]), 0x80000000))
	self:WriteUInt32(wrap(bor(lshift(bytes[5], 24), lshift(bytes[6], 16), lshift(bytes[7], 8), bytes[8]), 0x80000000))

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

--[[
	@doc
	@fname BytesBuffer:WriteDoubleLE
	@args number double

	@desc
	due to precision errors, this is a inaccurate operation
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:WriteDouble(valueIn)
	assertType(valueIn, 'number', 'WriteDouble')

	local int1, int2 = BitWorker.FastDoubleToBinaryIEEE(valueIn)

	self:WriteUInt32(wrap(int1, 0x80000000))
	self:WriteUInt32(wrap(int2, 0x80000000))

	return self
end

function meta:WriteDoubleLE(valueIn)
	assertType(valueIn, 'number', 'WriteDouble')

	local int1, int2 = BitWorker.FastDoubleToBinaryIEEE(valueIn)

	self:WriteUInt32LE(wrap(int2, 0x80000000))
	self:WriteUInt32LE(wrap(int1, 0x80000000))

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
	local bits = BitWorker.UIntegerToBinary(bytes1, 32)
	table.append(bits, BitWorker.UIntegerToBinary(bytes2, 32))
	return BitWorker.BinaryToFloatIEEE(bits, 11, 52)
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
	return BitWorker.FastBinaryToDoubleIEEE(self:ReadUInt32(), self:ReadUInt32())
end

--[[
	@doc
	@fname BytesBuffer:ReadDoubleLE

	@desc
	due to precision errors, this is a slightly inaccurate operation
	@enddesc

	@returns
	number
]]
function meta:ReadDoubleLE()
	local a, b = self:ReadUInt32LE(), self:ReadUInt32LE()
	return BitWorker.FastBinaryToDoubleIEEE(b, a)
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
	local pointer = self.pointer

	for pointer = rshift(self.pointer, 2), rshift(self.pointer + #stringIn, 2) + 1 do
		if bytes[pointer] == nil then
			bytes[pointer] = 0
		end
	end

	local length = #stringIn
	local optimized = self.o

	for i = 1, math_floor(length / 4) do
		local a, b, c, d = string_byte(stringIn, (i - 1) * 4 + 1, (i - 1) * 4 + 4)

		if a == 0 then error('NUL in input string at ' .. ((i - 1) * 4 + 1)) end
		if b == 0 then error('NUL in input string at ' .. ((i - 1) * 4 + 2)) end
		if c == 0 then error('NUL in input string at ' .. ((i - 1) * 4 + 3)) end
		if d == 0 then error('NUL in input string at ' .. ((i - 1) * 4 + 4)) end

		set_4_bytes_le(optimized, pointer, bytes, a + lshift(b, 8) + lshift(c, 16) + lshift(d, 24))
		pointer = pointer + 4
	end

	local _length = band(length, 3)

	if _length == 1 then
		set_1_bytes_le(optimized, pointer, bytes, string_byte(stringIn, length))
	elseif _length == 2 then
		local a, b = string_byte(stringIn, length - 1, length)
		set_2_bytes_le(optimized, pointer, bytes, a + lshift(b, 8))
	elseif _length == 3 then
		local a, b, c = string_byte(stringIn, length - 2, length)
		set_2_bytes_le(optimized, pointer, bytes, a + lshift(b, 8))
		set_1_bytes_le(optimized, pointer + 2, bytes, c)
	end

	pointer = pointer + _length

	self.pointer = pointer
	self.length = self.length:max(pointer)
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
	local optimized = self.o

	for i = self.pointer, self.length do
		if get_1_bytes_le(optimized, i, bytes) == 0 then
			local string = self:StringSlice(self.pointer + 1, i)
			self.pointer = i + 1
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
function meta:WriteBinary(stringIn)
	assertType(stringIn, 'string', 'WriteBinary')

	if #stringIn == 0 then
		return self
	end

	local bytes = self.bytes
	local pointer = self.pointer

	for pointer = rshift(self.pointer, 2), rshift(self.pointer + #stringIn, 2) + 1 do
		if bytes[pointer] == nil then
			bytes[pointer] = 0
		end
	end

	local length = #stringIn
	local optimized = self.o

	for i = 1, math_floor(length / 4) do
		local a, b, c, d = string_byte(stringIn, (i - 1) * 4 + 1, (i - 1) * 4 + 4)
		set_4_bytes_le(optimized, pointer, bytes, a + lshift(b, 8) + lshift(c, 16) + lshift(d, 24))
		pointer = pointer + 4
	end

	local _length = band(length, 3)

	if _length == 1 then
		set_1_bytes_le(optimized, pointer, bytes, string_byte(stringIn, length))
	elseif _length == 2 then
		local a, b = string_byte(stringIn, length - 1, length)
		set_2_bytes_le(optimized, pointer, bytes, a + lshift(b, 8))
	elseif _length == 3 then
		local a, b, c = string_byte(stringIn, length - 2, length)
		set_2_bytes_le(optimized, pointer, bytes, a + lshift(b, 8))
		set_1_bytes_le(optimized, pointer + 2, bytes, c)
	end

	pointer = pointer + _length

	self.pointer = pointer
	self.length = self.length:max(pointer)

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
	local bytes = self.bytes
	local _length = slice_end - slice_start + 1

	if _length == 1 then
		return string_char(get_1_bytes_le(self.o, slice_start - 1, bytes))
	elseif _length == 2 then
		return string_char(get_2_bytes_le(self.o, slice_start - 1, bytes))
	elseif _length == 3 then
		local a, b = get_2_bytes_le(self.o, slice_start - 1, bytes)
		return string_char(a, b, get_1_bytes_le(self.o, slice_start + 1, bytes))
	elseif _length == 4 then
		return string_char(get_4_bytes_le(self.o, slice_start - 1, bytes))
	end

	local strings = {}

	local whole_length = math_floor(_length / 4)
	local index = 1
	local optimized = self.o

	for i = 1, whole_length do
		strings[index] = string_char(get_4_bytes_le(optimized, slice_start + i * 4 - 5, bytes))
		index = index + 1
	end

	_length = band(_length, 0x3)

	if _length == 1 then
		strings[index] = string_char(get_1_bytes_le(optimized, slice_end - 1, bytes))
	elseif _length == 2 then
		strings[index] = string_char(get_2_bytes_le(optimized, slice_end - 2, bytes))
	elseif _length == 3 then
		local a, b = get_2_bytes_le(optimized, slice_end - 3, bytes)
		strings[index] = string_char(a, b, get_1_bytes_le(optimized, slice_end - 1, bytes))
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
	if self.length == 0 then return fileStream end
	local bytes = self.bytes

	for i = 1, math_floor(self.length / 4) do
		fileStream:WriteLong(bytes[i])
	end

	local _length = band(self.length, 0x3)
	local last = bytes[#bytes]

	if _length == 1 then
		fileStream:WriteByte(last)
	elseif _length == 2 then
		fileStream:WriteByte(band(last, 0xFF))
		fileStream:WriteByte(rshift(band(last, 0xFF00), 8))
	elseif _length == 3 then
		fileStream:WriteByte(band(last, 0xFF))
		fileStream:WriteByte(rshift(band(last, 0xFF00), 8))
		fileStream:WriteByte(rshift(band(last, 0xFF00), 16))
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

do
	local function readArray(num, fn)
		if isnumber(num) then
			return function(self, struct)
				local array = {}

				for i = 1, num do
					array[i] = fn(self, struct)
				end

				return array
			end
		else
			return function(self, struct)
				local array = {}

				for i = 1, struct[num] do
					array[i] = fn(self, struct)
				end

				return array
			end
		end
	end

	local function readChar(self, struct)
		return string.char(self:ReadUByte())
	end

	local function readCharLE(self, struct)
		return string.char(self:ReadUByte():bswap():rshift(24))
	end

	function metaclass.CompileStructure(structureDef, callbacks)
		local output = {}

		for i, line in ipairs(structureDef:split('\n')) do
			line = line:trim()
			--assert(line ~= '', 'Invalid line definition at ' .. i)

			if line ~= '' and not line:startsWith('//') then
				line = line
					:gsub('unsigned%s+int', 'uint32')
					:gsub('unsigned%s+short', 'uint16')
					:gsub('unsigned%s+char', 'uint8')

				local findLE, findLE_ = line:lower():find('^le%s+')
				local findLE2, findLE2_ = line:lower():find('^little endian%s+')

				local isLE = false

				if findLE then
					isLE = true
					line = line:sub(findLE_ + 1)
				end

				if findLE2 then
					isLE = true
					line = line:sub(findLE2_ + 1)
				end

				local findSpace = assert(line:find('%s'), 'Can\'t find variable name at line ' .. i)
				local rtype2 = line:sub(1, findSpace):trim()
				local rtype = rtype2:lower()
				local rname = line:sub(findSpace + 1):trim()
				local findCommentary = rname:find('%s//')

				if findCommentary then
					rname = rname:sub(1, findCommentary):trim()
				end

				if rname[#rname] == ';' then
					rname = rname:sub(1, #rname - 1)
				end

				local findIndex = string.match(rname, '%[.-%]$')

				if findIndex then
					rname = rname:sub(1, #rname - #findIndex)
				end

				local limit = 0x0

				if rtype == 'int8' or rtype == 'byte' then
					table_insert(output, {rname, meta.ReadByte})
					limit = 24
				elseif rtype == 'char' then
					local addfn = readChar
					limit = 24

					if isLE then
						isLE = false
						addfn = readCharLE
					end

					table_insert(output, {rname, addfn})
				elseif rtype == 'int16' or rtype == 'short' then
					table_insert(output, {rname, meta.ReadInt16})
					limit = 16
				elseif rtype == 'int32' or rtype == 'long' or rtype == 'int' then
					table_insert(output, {rname, meta.ReadInt32})
					limit = 0
				elseif rtype == 'int64' or rtype == 'longlong' or rtype == 'bigint' then
					table_insert(output, {rname, meta.ReadInt64})
					limit = 0 -- unsupported by bit library
				elseif rtype == 'uint8' or rtype == 'ubyte' then
					table_insert(output, {rname, meta.ReadUByte})
					limit = 24
				elseif rtype == 'uint16' or rtype == 'ushort' then
					table_insert(output, {rname, meta.ReadUInt16})
					limit = 16
				elseif rtype == 'uint32' or rtype == 'ulong' or rtype == 'uint' then
					table_insert(output, {rname, meta.ReadUInt32})
					limit = 0
				elseif rtype == 'uint64' or rtype == 'ulong64' or rtype == 'biguint' or rtype == 'ubigint' then
					table_insert(output, {rname, meta.ReadUInt64})
					limit = 0 -- unsupported by bit library
				elseif rtype == 'float' then
					if isLE then
						isLE = false
						table_insert(output, {rname, meta.ReadFloatLE})
					else
						table_insert(output, {rname, meta.ReadFloat})
					end
				elseif rtype == 'double' then
					if isLE then
						isLE = false
						table_insert(output, {rname, meta.ReadDoubleLE})
					else
						table_insert(output, {rname, meta.ReadDouble})
					end
				elseif rtype == 'variable' or rtype == 'string' then
					table_insert(output, {rname, meta.ReadString})
				elseif callbacks and callbacks[rtype2] then
					table_insert(output, {rname, callbacks[rtype2]})
				else
					DLib.MessageError(debug.traceback('Undefined type: ' .. rtype))
				end

				if isLE then
					local fn = output[#output][2]

					output[#output][2] = function(self, struct)
						return fn(self, struct):bswap():rshift(limit)
					end
				end

				if findIndex then
					local index = findIndex:sub(2, #findIndex - 1)
					output[#output][2] = readArray(tonumber(index) or index, output[#output][2])
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

if DLib.BytesBuffer and not DLib.BytesBuffer.__base then DLib.BytesBuffer = nil end

function metaclass.Allocate(length)
	return DLib.BytesBuffer(string.rep('\x00', length))
end

local real_buff_meta
DLib.BytesBuffer, real_buff_meta = DLib.CreateMoonClassBare('LBytesBuffer', meta, metaclass, nil, DLib.BytesBuffer, true)
debug.getregistry().LBytesBuffer = DLib.BytesBuffer
DLib.BytesBufferBase = real_buff_meta

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
	return meta_view[key] or real_buff_meta[key]
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

	@deprecated

	@desc
	Allows you to create "lightweight" (buffers passed to this constructor are memory un-optimized)
	(lightweight because BytesBufferView does not copy contents of a buffer) slices of one or more buffers at specified positions
	Keep in mind that this is generally slower to work with big slices since there is a cost at translating
	byte index to corresponding buffers
	This object expose every property and method regular `BytesBuffer` has

	Deprecated: You should not use this at all because it is crudely incompatible with internal BytesBuffer representation
	If you REALLY need to use multiple you could try to use it, but this will un-optimize memory consumption of buffers in question.
	For slicing a single buffer, you can use `BytesBuffer:PushSlice()` and `BytesBuffer:PopSlice()`
	@enddesc

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

	for i, buffer in ipairs(obj.buffers) do
		buffer:Unoptimize()
	end

	return obj
end})
