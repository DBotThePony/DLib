
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
		return
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
		return
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
		return
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
		return
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
			bytes[i] = bor(a, lshift(b, 8), lshift(c, 16), lshift(d, 24))
		end

		self.bytes = bytes
		self.length = length

		local _length = band(length, 3)

		if _length == 1 then
			bytes[#bytes + 1] = string_byte(stringIn, length)
		elseif _length == 2 then
			local a, b = string_byte(stringIn, length - 1, length)
			bytes[#bytes + 1] = bor(a, lshift(b, 8))
		elseif _length == 3 then
			local a, b, c = string_byte(stringIn, length - 2, length)
			bytes[#bytes + 1] = bor(a, lshift(b, 8), lshift(c, 16))
		end
	else
		self.bytes = {}
		self.length = 0
	end

	self.slices = {}

	self.o = true
end

function metaclass.Allocate(length)
	local buff = DLib.BytesBuffer()
	local bytes = buff.bytes

	for i = 1, math.ceil(length / 4) do
		bytes[i] = 0
	end

	buff.length = length

	return buff
end

local rol = bit.rol

function metaclass.AllocatePattern(pattern, repeats)
	local buff = DLib.BytesBuffer()
	local bytes = buff.bytes

	if #pattern == 1 then
		-- ровно байт
		local a = string_byte(pattern, 1)
		local full = bor(a, lshift(a, 8), lshift(a, 16), lshift(a, 24))

		for i = 1, math_floor(repeats / 4) do
			bytes[i] = full
		end

		local _length = band(repeats, 3)

		if _length == 1 then
			bytes[#bytes + 1] = a
		elseif _length == 2 then
			bytes[#bytes + 1] = bor(a, lshift(a, 8))
		elseif _length == 3 then
			bytes[#bytes + 1] = bor(a, lshift(a, 8), lshift(a, 16))
		end

		buff.length = repeats
	elseif #pattern == 2 then
		-- ровно 2 байта
		local a, b = string_byte(pattern, 1, 2)
		local full = bor(a, lshift(b, 8), lshift(a, 16), lshift(b, 24))

		for i = 1, math_floor(repeats / 2) do
			bytes[i] = full
		end

		if band(repeats, 1) == 1 then
			bytes[#bytes + 1] = bor(a, lshift(b, 8))
		end

		buff.length = repeats * 2
		-- 3 байта не имеют логики, так как требуют зацикливание и встречаются довольно редко
		-- поэтому они обрабатываются как обычно
	elseif #pattern == 4 then
		-- ровно 4 байта
		local a, b, c, d = string_byte(pattern, 1, 4)
		local full = bor(a, lshift(b, 8), lshift(c, 16), lshift(d, 24))

		for i = 1, repeats do
			bytes[i] = full
		end

		buff.length = repeats * 4
	elseif #pattern % 4 == 0 then
		-- выровнено по границе в 4 байта
		local pbyte = DLib.BytesBuffer(pattern)
		local bytesPattern = pbyte.bytes
		local len = #bytesPattern

		for rep = 1, repeats do
			for i = 1, len do
				bytes[(rep - 1) * len + i] = bytesPattern[i]
			end
		end

		buff.length = repeats * len * 4
	else
		-- никакой специальной логики
		meta.ctor(buff, string.rep(pattern, repeats))
	end

	return buff
end

--[[
	@doc
	@fname BytesBuffer:PushSlice
	@args number slice_start, number slice_end = nil

	@desc
	Pushes new slice of this buffer, relative to any other slices present
	`slice_end` is not required and in most cases should be left undefined
	`slice_end` is ***relative***
	since write operations ignore limits
	unless you want upcoming code to rely on `Buffer:Length()`
	@enddesc
]]
function meta:PushSlice(slice_start, slice_end)
	assert(isnumber(slice_start), 'slice start must be a number', 2)
	assert(slice_start >= 0, 'slice start must be positive', 2)

	if isnumber(slice_end) then
		assert(slice_end > 0, 'slice end must be above zero')
	elseif slice_end ~= nil then
		error('slice end is not a number', 2)
	end

	table.insert(self.slices, {self.slice_start, self.slice_end, self.pointer})
	local _slice_start = self.slice_start or 0

	self.pointer = 0
	self.slice_start = _slice_start + slice_start

	if slice_end then
		self.slice_end = _slice_start + slice_start + slice_end
		self.slice_end_real = slice_end
	else
		self.slice_end_real = self.length - (_slice_start + slice_start)
	end
end

--[[
	@doc
	@fname BytesBuffer:Slice
	@args number slice_start, number slice_end = nil

	@desc
	`DLib.BytesBufferView` replacement. Creates shallow clone which reflect original, with slice defined,
	Won't work if buffer is optimized and gets unoptimized later.
	Basically `self:ShallowClone()` with `clone:PushSlice(slice_start, slice_end)`.
	@enddesc

	@returns
	table: slice pseudo-object
]]
function meta:Slice(slice_start, slice_end)
	local obj = self:ShallowClone()
	obj:PushSlice(slice_start, slice_end)
	return obj
end

--[[
	@doc
	@fname BytesBuffer:ShallowClone

	@desc
	Allows to define buffer-wide properties (such as current slice) without affecting original buffer
	Any write/read operations will be directed to original
	Won't work if buffer is optimized and gets unoptimized later.
	@enddesc

	@returns
	table: slice pseudo-object
]]
function meta:ShallowClone()
	return setmetatable({
		pointer = self.pointer,
		bytes = self.bytes,
		slices = table.Copy(self.slices),
		slice_start = self.slice_start,
		slice_end = self.slice_end,
	}, {
		__index = self,
		__newindex = function(_self, key, value)
			if key == 'length' then
				self[key] = value
				return
			end

			rawset(_self, key, value)
		end
	})
end

--[[
	@doc
	@fname BytesBuffer:PopSlice
]]
function meta:PopSlice()
	local pop = assert(table.remove(self.slices), 'nothing to pop', 2)

	self.slice_start = pop[1]
	self.slice_end = pop[2]
	self.pointer = pop[3]
	self.slice_end_real = nil

	if self.slice_end then
		self.slice_end_real = self.slice_end - self.slice_start
	elseif self.slice_start then
		self.slice_end_real = self.length - self.slice_start
	end
end

--[[
	@doc
	@fname BytesBuffer:CurrentSliceEnd

	@internal

	@returns
	number
]]
function meta:CurrentSliceEnd()
	local get = self.slice_end
	if get == nil then return self.length end
	return get
end

--[[
	@doc
	@fname BytesBuffer:Length

	@returns
	number: length affected by slices
]]
function meta:Length()
	local get = self.slice_end_real
	if get == nil then return self.length end
	return get
end

--[[
	@doc
	@fname BytesBuffer:RealLength

	@returns
	number: unaffected length by slices
]]
function meta:RealLength()
	return self.length
end

--[[
	@doc
	@fname BytesBuffer:CurrentSliceStart

	@internal

	@returns
	number
]]
function meta:CurrentSliceStart()
	local get = self.slice_start
	if get == nil then return 0 end
	return get
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
function meta:Seek(moveTo)
	if moveTo < 0 then
		error(string.format('BytesBuffer:Seek(%d): argument must be non-negative', moveTo), 2)
	elseif moveTo > self:Length() then
		error(string.format('BytesBuffer:Seek(%d): overflow (max %d, delta %d)', moveTo, self:Length(), moveTo - self:Length()), 2)
	end

	self.pointer = moveTo
	return self
end

function meta:CheckOverflow(name, moveBy)
	if self.pointer + moveBy > self:Length() then
		error(string.format('BytesBuffer:Read%s(): overflow (read %d->%d; %d)',
			name,
			self.pointer,
			self.pointer + moveBy,
			self:Length()), 3)
	end
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

local function assertNumber(valueIn, funcName)
	if isnumber(valueIn) then return end
	error(funcName .. ' - input is not a number! typeof ' .. type(valueIn), 3)
end

local function assertString(valueIn, funcName)
	if isstring(valueIn) then return end
	error(funcName .. ' - input is not a string! typeof ' .. type(valueIn), 3)
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
function meta:IsEOF()
	return self.pointer >= self:Length()
end

meta.EndOfStream = meta.IsEOF

--[[
	@doc
	@fname BytesBuffer:WriteUByte
	@args number value

	@returns
	BytesBuffer: self
]]
function meta:WriteUByte(valueIn)
	assertNumber(valueIn, 'WriteUByte')
	assertRange(valueIn, 0, 0xFF, 'WriteUByte')

	valueIn = math_floor(valueIn)

	local pointer = self.pointer
	local _pointer = pointer + self:CurrentSliceStart()
	local bytes = self.bytes
	local length = self.length

	if _pointer == length then
		self.length = length + 1
		local index = rshift(_pointer, 2) + 1

		if bytes[index] == nil then
			bytes[index] = 0
		end
	end

	set_1_bytes_le(self.o, _pointer, bytes, valueIn)
	self.pointer = pointer + 1

	return self
end

--[[
	@doc
	@fname BytesBuffer:WriteByte_2
	@args number value

	@desc
	one's exponent
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteByte
	@args number value

	@desc
	two's exponent
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
	assertNumber(valueIn, 'WriteByte')
	assertRange(valueIn, -0x80, 0x7F, 'WriteByte')
	return self:WriteUByte(math_floor(valueIn) + 0x80)
end

-- one's component
function meta:WriteByte(valueIn)
	assertNumber(valueIn, 'WriteByte')
	assertRange(valueIn, -0x80, 0x7F, 'WriteByte')
	return self:WriteUByte(wrap(math_floor(valueIn), 0x80))
end

meta.WriteInt8 = meta.WriteByte
meta.WriteUInt8 = meta.WriteUByte

function meta:WriteChar(char)
	assertString(char, 'WriteChar')
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
	one's exponent
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
	one's exponent
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
	two's exponent
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
	two's exponent
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
	assertNumber(valueIn, 'WriteInt16')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16')
	return self:WriteUInt16(math_floor(valueIn) + 0x8000)
end

function meta:WriteInt16(valueIn)
	assertNumber(valueIn, 'WriteInt16')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16')
	return self:WriteUInt16(wrap(math_floor(valueIn), 0x8000))
end

function meta:WriteInt16LE_2(valueIn)
	assertNumber(valueIn, 'WriteInt16LE')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16LE')
	return self:WriteUInt16LE(math_floor(valueIn) + 0x8000)
end

function meta:WriteInt16LE(valueIn)
	assertNumber(valueIn, 'WriteInt16LE')
	assertRange(valueIn, -0x8000, 0x7FFF, 'WriteInt16LE')
	return self:WriteUInt16LE(wrap(math_floor(valueIn), 0x8000))
end

function meta:WriteUInt16(valueIn)
	assertNumber(valueIn, 'WriteUInt16')
	assertRange(valueIn, 0, 0xFFFF, 'WriteUInt16')

	local pointer = self.pointer
	local _pointer = pointer + self:CurrentSliceStart()
	local bytes = self.bytes
	local length = self.length

	if _pointer + 1 >= length then
		self.length = _pointer + 2

		if self.o then
			local index = rshift(_pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_2_bytes_le(self.o, _pointer, bytes, rshift(bswap(valueIn), 16))
	self.pointer = pointer + 2

	return self
end

function meta:WriteUInt16LE(valueIn)
	assertNumber(valueIn, 'WriteUInt16LE')
	assertRange(valueIn, 0, 0xFFFF, 'WriteUInt16LE')

	local pointer = self.pointer
	local _pointer = pointer + self:CurrentSliceStart()
	local bytes = self.bytes
	local length = self.length

	if _pointer + 1 >= length then
		self.length = _pointer + 2

		if self.o then
			local index = rshift(_pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_2_bytes_le(self.o, _pointer, bytes, valueIn)
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
	one's exponent
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt24LE_2
	@args number value

	@desc
	one's exponent
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt24
	@args number value

	@desc
	two's exponent
	@enddesc

	@returns
	BytesBuffer: self
]]

--[[
	@doc
	@fname BytesBuffer:WriteInt24LE
	@args number value

	@desc
	two's exponent
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
	assertNumber(valueIn, 'WriteInt24')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24')
	return self:WriteUInt24(math_floor(valueIn) + 0x8000)
end

function meta:WriteInt24(valueIn)
	assertNumber(valueIn, 'WriteInt24')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24')
	return self:WriteUInt24(wrap(math_floor(valueIn), 0x800000))
end

function meta:WriteInt24LE_2(valueIn)
	assertNumber(valueIn, 'WriteInt24LE')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24LE')
	return self:WriteUInt24LE(math_floor(valueIn) + 0x800000)
end

function meta:WriteInt24LE(valueIn)
	assertNumber(valueIn, 'WriteInt24LE')
	assertRange(valueIn, -0x800000, 0x7FFFFF, 'WriteInt24LE')
	return self:WriteUInt24LE(wrap(math_floor(valueIn), 0x800000))
end

function meta:WriteUInt24(valueIn)
	assertNumber(valueIn, 'WriteUInt24')
	assertRange(valueIn, 0, 0xFFFFFF, 'WriteUInt24')

	local pointer = self.pointer
	local _pointer = pointer + self:CurrentSliceStart()
	local bytes = self.bytes
	local length = self.length

	if _pointer + 2 >= length then
		self.length = _pointer + 3

		if self.o then
			local index = rshift(_pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 2, 2) + 1

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
	assertNumber(valueIn, 'WriteUInt24LE')
	assertRange(valueIn, 0, 0xFFFFFF, 'WriteUInt24LE')

	local pointer = self.pointer
	local _pointer = pointer + self:CurrentSliceStart()
	local bytes = self.bytes
	local length = self.length

	if _pointer + 2 >= length then
		self.length = _pointer + 3

		if self.o then
			local index = rshift(_pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 2, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_3_bytes_le(self.o, _pointer, bytes, valueIn)
	self.pointer = pointer + 3

	return self
end

--[[
	@doc
	@fname BytesBuffer:WriteInt_2
	@alias BytesBuffer:WriteInt32_2
	@args number value

	@desc
	one's exponent
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
	two's exponent
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
	one's exponent
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
	two's exponent
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
	assertNumber(valueIn, 'WriteInt32')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32')
	return self:WriteUInt32(math_floor(valueIn) + 0x80000000)
end

function meta:WriteInt32(valueIn)
	assertNumber(valueIn, 'WriteInt32')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32')
	return self:WriteUInt32(wrap(math_floor(valueIn), 0x80000000))
end

function meta:WriteUInt32(valueIn)
	assertNumber(valueIn, 'WriteUInt32')
	assertRange(valueIn, 0, 0xFFFFFFFF, 'WriteUInt32')

	local pointer = self.pointer
	local _pointer = pointer + self:CurrentSliceStart()
	local bytes = self.bytes
	local length = self.length

	if _pointer + 3 >= length then
		self.length = _pointer + 4

		if self.o then
			local index = rshift(_pointer, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 1, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 2, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end

			index = rshift(_pointer + 3, 2) + 1

			if bytes[index] == nil then
				bytes[index] = 0
			end
		end
	end

	set_4_bytes_le(self.o, _pointer, bytes, bswap(valueIn))
	self.pointer = pointer + 4

	return self
end

function meta:WriteInt32LE_2(valueIn)
	assertNumber(valueIn, 'WriteInt32LE')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32LE')
	return self:WriteUInt32LE(math_floor(valueIn) + 0x80000000)
end

function meta:WriteInt32LE(valueIn)
	assertNumber(valueIn, 'WriteInt32LE')
	assertRange(valueIn, -0x80000000, 0x7FFFFFFF, 'WriteInt32LE')
	return self:WriteUInt32LE(wrap(math_floor(valueIn), 0x80000000))
end

function meta:WriteUInt32LE(valueIn)
	assertNumber(valueIn, 'WriteUInt32')
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
	one's exponent
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
	two's exponent
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
	one's exponent
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
	two's exponent
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

--[[
	@doc
	@fname BytesBuffer:ReadByte_2

	@desc
	one's exponent
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadByte

	@desc
	two's exponent
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
	return get_1_bytes_le(self.o, pointer + self:CurrentSliceStart(), self.bytes)
end

meta.ReadInt8 = meta.ReadByte
meta.ReadUInt8 = meta.ReadUByte

--[[
	@doc
	@fname BytesBuffer:ReadInt16_2

	@desc
	one's exponent
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt16

	@desc
	two's exponent
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
	one's exponent
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt16LE

	@desc
	two's exponent
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
	local a, b = get_2_bytes_le(self.o, pointer + self:CurrentSliceStart(), self.bytes)
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
	local a, b = get_2_bytes_le(self.o, pointer + self:CurrentSliceStart(), self.bytes)
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
	one's exponent
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt24

	@desc
	two's exponent
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
	one's exponent
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt24LE

	@desc
	two's exponent
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
	local a, b, c = get_3_bytes_le(self.o, pointer + self:CurrentSliceStart(), self.bytes)
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
	local a, b, c = get_3_bytes_le(self.o, pointer + self:CurrentSliceStart(), self.bytes)
	return bor(lshift(c, 16), lshift(b, 8), a)
end

--[[
	@doc
	@fname BytesBuffer:ReadInt32_2

	@desc
	one's exponent
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt32

	@desc
	two's exponent
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
	one's exponent
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt32LE

	@desc
	two's exponent
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
	local a, b, c, d = get_4_bytes_le(self.o, pointer + self:CurrentSliceStart(), self.bytes)
	local value = bor(lshift(a, 24), lshift(b, 16), lshift(c, 8), d)

	if value < 0 then
		return value + 0x100000000
	end

	return value
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
	local a, b, c, d = get_4_bytes_le(self.o, pointer + self:CurrentSliceStart(), self.bytes)
	local value = bor(lshift(d, 24), lshift(c, 16), lshift(b, 8), a)

	if value < 0 then
		return value + 0x100000000
	end

	return value
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
	one's exponent
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt64

	@desc
	two's exponent
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
	one's exponent
	due to precision errors, this not actually accurate operation
	@enddesc

	@returns
	number
]]

--[[
	@doc
	@fname BytesBuffer:ReadInt64LE

	@desc
	two's exponent
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
	local _poiner = pointer + self:CurrentSliceStart()
	self.pointer = pointer + 8

	local a, b, c, d = get_4_bytes_le(self.o, _poiner, self.bytes)
	local e, f, g, k = get_4_bytes_le(self.o, _poiner + 4, self.bytes)

	local value = bor(lshift(e, 24), lshift(f, 16), lshift(g, 8), k)

	if value < 0 then
		return value + 0x100000000
	end

	return
		a * 0x100000000000000 +
		b * 0x1000000000000 +
		c * 0x10000000000 +
		d * 0x100000000 +
		value
end

function meta:ReadInt64LE_2()
	return self:ReadUInt64LE() - 0x100000000
end

function meta:ReadInt64()
	return unwrap(self:ReadUInt64LE(), 0x100000000)
end

function meta:ReadUInt64LE()
	self:CheckOverflow('UInt64LE', 8)

	local pointer = self.pointer
	local _poiner = pointer + self:CurrentSliceStart()
	self.pointer = pointer + 8

	local k, g, f, e = get_4_bytes_le(self.o, _poiner, self.bytes)
	local d, c, b, a = get_4_bytes_le(self.o, _poiner + 4, self.bytes)

	local value = bor(lshift(e, 24), lshift(f, 16), lshift(g, 8), k)

	if value < 0 then
		return value + 0x100000000
	end

	return
		a * 0x100000000000000 +
		b * 0x1000000000000 +
		c * 0x10000000000 +
		d * 0x100000000 +
		value
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
	assertNumber(valueIn, 'WriteFloat')
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
	assertNumber(valueIn, 'WriteFloat')
	return self:WriteInt32(BitWorker.FastFloatToBinaryIEEE(valueIn))
end

function meta:WriteFloatLE(valueIn)
	assertNumber(valueIn, 'WriteFloatLE')
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
	assertNumber(valueIn, 'WriteDouble')
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
	assertNumber(valueIn, 'WriteDouble')

	local int1, int2 = BitWorker.FastDoubleToBinaryIEEE(valueIn)

	self:WriteUInt32(wrap(int1, 0x80000000))
	self:WriteUInt32(wrap(int2, 0x80000000))

	return self
end

function meta:WriteDoubleLE(valueIn)
	assertNumber(valueIn, 'WriteDouble')

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
	assertString(stringIn, 'WriteString')

	if #stringIn == 0 then
		self:WriteUByte(0)
		return self
	end

	local _pointer = self.pointer + self:CurrentSliceStart()
	local bytes = self.bytes

	for pointer = rshift(self.pointer + self:CurrentSliceStart(), 2), rshift(self.pointer + #stringIn + self:CurrentSliceStart(), 2) + 1 do
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

		set_4_bytes_le(optimized, _pointer, bytes, bor(a,  lshift(b, 8), lshift(c, 16), lshift(d, 24)))
		_pointer = _pointer + 4
	end

	local _length = band(length, 3)

	if _length == 1 then
		set_1_bytes_le(optimized, _pointer, bytes, string_byte(stringIn, length))
	elseif _length == 2 then
		local a, b = string_byte(stringIn, length - 1, length)
		set_2_bytes_le(optimized, _pointer, bytes, bor(a, lshift(b, 8)))
	elseif _length == 3 then
		local a, b, c = string_byte(stringIn, length - 2, length)
		set_2_bytes_le(optimized, _pointer, bytes, bor(a, lshift(b, 8)))
		set_1_bytes_le(optimized, _pointer + 2, bytes, c)
	end

	_pointer = _pointer + _length

	self.pointer = _pointer - self:CurrentSliceStart()
	self.length = self.length:max(_pointer)
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

	for i = self.pointer + self:CurrentSliceStart(), self:CurrentSliceEnd() do
		if get_1_bytes_le(optimized, i, bytes) == 0 then
			local string = self:StringSlice(self.pointer + 1 + self:CurrentSliceStart(), i)
			self.pointer = i + 1 - self:CurrentSliceStart()
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
	assertString(stringIn, 'WriteBinary')

	if #stringIn == 0 then
		return self
	end

	local _pointer = self.pointer + self:CurrentSliceStart()
	local bytes = self.bytes

	for pointer = rshift(self.pointer + self:CurrentSliceStart(), 2), rshift(self.pointer + #stringIn + self:CurrentSliceStart(), 2) + 1 do
		if bytes[pointer] == nil then
			bytes[pointer] = 0
		end
	end

	local length = #stringIn
	local optimized = self.o

	for i = 1, math_floor(length / 4) do
		local a, b, c, d = string_byte(stringIn, (i - 1) * 4 + 1, (i - 1) * 4 + 4)
		set_4_bytes_le(optimized, _pointer, bytes, bor(a,  lshift(b, 8), lshift(c, 16), lshift(d, 24)))
		_pointer = _pointer + 4
	end

	local _length = band(length, 3)

	if _length == 1 then
		set_1_bytes_le(optimized, _pointer, bytes, string_byte(stringIn, length))
	elseif _length == 2 then
		local a, b = string_byte(stringIn, length - 1, length)
		set_2_bytes_le(optimized, _pointer, bytes, bor(a, lshift(b, 8)))
	elseif _length == 3 then
		local a, b, c = string_byte(stringIn, length - 2, length)
		set_2_bytes_le(optimized, _pointer, bytes, bor(a, lshift(b, 8)))
		set_1_bytes_le(optimized, _pointer + 2, bytes, c)
	end

	_pointer = _pointer + _length

	self.pointer = _pointer - self:CurrentSliceStart()
	self.length = self.length:max(_pointer)

	return self
end

local function circular(stringIn)
	local bytes = {string_byte(stringIn, 1, #stringIn)}
	local index = 1
	local maxIndex = #stringIn

	local function get()
		local byte = bytes[index]
		index = index + 1

		if index > maxIndex then
			index = 1
		end

		return byte
	end

	local optimized

	if band(maxIndex, 3) == 0 then
		function optimized()
			local byteA = bytes[index]
			local byteB = bytes[index + 1]
			local byteC = bytes[index + 2]
			local byteD = bytes[index + 3]

			index = index + 4

			if index > maxIndex then
				index = 1
			end

			return byteA, byteB, byteC, byteD
		end
	else
		function optimized()
			return get(), get(), get(), get()
		end
	end

	return function(length)
		if length == 4 then
			return get(), get(), get(), get()
		elseif length == 3 then
			return get(), get(), get()
		elseif length == 2 then
			return get(), get()
		else
			return get()
		end
	end, optimized
end

--[[
	@doc
	@fname BytesBuffer:WriteBinaryRep
	@alias BytesBuffer:WriteDataRep
	@args string binary

	@desc
	Writes binary string, repeated `repeats` times.
	Slightly slower than pairting WriteBinary + string.rep,
	but wildly more memory efficient
	@enddesc

	@returns
	BytesBuffer: self
]]
function meta:WriteBinaryRep(stringIn, repeats)
	assertString(stringIn, 'WriteBinaryRep')
	assertNumber(repeats, 'WriteBinaryRep')

	if #stringIn == 0 then
		return self
	end

	if #stringIn > 7960 then
		for i = 1, repeats do
			self:WriteBinary(stringIn)
		end

		return self
	end

	local circular, circular4 = circular(stringIn)
	local realLength = #stringIn * repeats

	local _pointer = self.pointer + self:CurrentSliceStart()
	local bytes = self.bytes

	for pointer = rshift(self.pointer + self:CurrentSliceStart(), 2), rshift(self.pointer + realLength + self:CurrentSliceStart(), 2) + 1 do
		if bytes[pointer] == nil then
			bytes[pointer] = 0
		end
	end

	local optimized = self.o

	for i = 1, math_floor(realLength / 4) do
		local a, b, c, d = circular4()
		set_4_bytes_le(optimized, _pointer, bytes, bor(a,  lshift(b, 8), lshift(c, 16), lshift(d, 24)))
		_pointer = _pointer + 4
	end

	local _length = band(realLength, 3)

	if _length == 1 then
		set_1_bytes_le(optimized, _pointer, bytes, circular(1))
	elseif _length == 2 then
		local a, b = circular(2)
		set_2_bytes_le(optimized, _pointer, bytes, bor(a, lshift(b, 8)))
	elseif _length == 3 then
		local a, b, c = circular(3)
		set_2_bytes_le(optimized, _pointer, bytes, bor(a, lshift(b, 8)))
		set_1_bytes_le(optimized, _pointer + 2, bytes, c)
	end

	_pointer = _pointer + _length

	self.pointer = _pointer - self:CurrentSliceStart()
	self.length = self.length:max(_pointer)

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

	local slice = self:StringSlice(self.pointer + 1 + self:CurrentSliceStart(), self.pointer + readAmount + self:CurrentSliceStart())
	self.pointer = self.pointer + readAmount

	return slice
end

meta.WriteData = meta.WriteBinary
meta.WriteDataRep = meta.WriteBinaryRep
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
	return self:StringSlice(self:CurrentSliceStart() + 1, self:CurrentSliceEnd())
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

	-- writing bytes manually is extremely slow holy shit
	fileStream:Write(self:StringSlice(self:CurrentSliceStart() + 1, self:CurrentSliceEnd()))

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

	local function readVec3(self, struct)
		return Vector(self:ReadFloat(), self:ReadFloat(), self:ReadFloat())
	end

	local function readVec3LE(self, struct)
		return Vector(self:ReadFloatLE(), self:ReadFloatLE(), self:ReadFloatLE())
	end

	function metaclass.CompileStructure(structureDef, callbacks)
		local output = {}
		local comment = false

		for i, line in ipairs(structureDef:split('\n')) do
			line = line:trim()

			if comment then
				if not line:startsWith('*/') then
					goto CONTINUE
				end

				comment = false
				goto CONTINUE
			elseif line:startsWith('/*') then
				comment = true
				goto CONTINUE
			end

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

				if rtype == 'int8' or rtype == 'byte' then
					table_insert(output, {rname, meta.ReadByte})
				elseif rtype == 'char' then
					table_insert(output, {rname, readChar})
				elseif rtype == 'int16' or rtype == 'short' then
					table_insert(output, {rname, isLE and meta.ReadInt16LE or meta.ReadInt16})
				elseif rtype == 'int32' or rtype == 'long' or rtype == 'int' then
					table_insert(output, {rname, isLE and meta.ReadInt32LE or meta.ReadInt32})
				elseif rtype == 'int64' or rtype == 'longlong' or rtype == 'bigint' then
					table_insert(output, {rname, isLE and meta.ReadInt64LE or meta.ReadInt64})

				elseif rtype == 'uint8' or rtype == 'ubyte' then
					table_insert(output, {rname, meta.ReadUByte})
				elseif rtype == 'uint16' or rtype == 'ushort' then
					table_insert(output, {rname, isLE and meta.ReadUInt16LE or meta.ReadUInt16})
				elseif rtype == 'uint32' or rtype == 'ulong' or rtype == 'uint' then
					table_insert(output, {rname, isLE and meta.ReadUInt32LE or meta.ReadUInt32})
				elseif rtype == 'uint64' or rtype == 'ulong64' or rtype == 'biguint' or rtype == 'ubigint' then

					table_insert(output, {rname, isLE and meta.ReadUInt64LE or meta.ReadUInt64})
				elseif rtype == 'float' then
					table_insert(output, {rname, isLE and meta.ReadFloatLE or meta.ReadFloat})
				elseif rtype == 'double' then
					table_insert(output, {rname, isLE and meta.ReadDoubleLE or meta.ReadDouble})

				elseif rtype == 'vec3' then
					table_insert(output, {rname, isLE and readVec3LE or readVec3})

				elseif rtype == 'variable' or rtype == 'string' then
					table_insert(output, {rname, meta.ReadString})
				elseif callbacks and callbacks[rtype2] then
					table_insert(output, {rname, callbacks[rtype2]})
				else
					DLib.MessageError(debug.traceback('Undefined type: ' .. rtype))
				end

				if findIndex then
					local index = findIndex:sub(2, #findIndex - 1)
					output[#output][2] = readArray(tonumber(index) or index, output[#output][2])
				end
			end

			::CONTINUE::
		end

		return function(self)
			local read = {}

			for i, data in ipairs(output) do
				read[data[1]] = data[2](self, read)
			end

			return read
		end
	end

	metaclass.CompileStruct = metaclass.CompileStructure
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

local real_buff_meta
DLib.BytesBuffer, real_buff_meta = DLib.CreateMoonClassBare('LBytesBuffer', meta, metaclass, nil, DLib.BytesBuffer, true)
debug.getregistry().LBytesBuffer = DLib.BytesBuffer
DLib.BytesBufferBase = real_buff_meta

local meta_view = {}
local meta_bytes = {}

function meta_view:StringSlice(slice_start, slice_end)
	local strings = {}
	local self_slice_start, self_slice_end = self._slice_start, self._slice_end
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

	key = key + self2._slice_start

	if key < 0 then return end
	if key > self2._slice_end then return end

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
	key = key + self2._slice_start

	if key < 0 then return end
	if key > self2._slice_end then return end

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
	obj._slice_start = slice_start
	obj._slice_end = slice_end
	obj.buffers = {...}
	obj.bytes = setmetatable({self = obj}, meta_bytes)

	for i, buffer in ipairs(obj.buffers) do
		buffer:Unoptimize()
	end

	return obj
end})

local meta_immutable = {}
local object_immutable = {}

do
	local import = {
		'PushSlice',
		'Slice',
		'ShallowClone',
		'PopSlice',
		'CurrentSliceEnd',
		'Length',
		'RealLength',
		'CurrentSliceStart',
		'Seek',
		'CheckOverflow',
		'Tell',
		'Ask',
		'Move',
		'Walk',
		'Reset',
		'GetBytes',
		'IsEOF',

		'ReadByte_2',
		'ReadByte',

		'ReadInt16_2',
		'ReadInt16',
		'ReadInt16LE_2',
		'ReadInt16LE',

		'ReadInt24_2',
		'ReadInt24',
		'ReadInt24LE_2',
		'ReadInt24LE',

		'ReadInt32_2',
		'ReadInt32',
		'ReadInt32LE_2',
		'ReadInt32LE',

		'ReadInt64_2',
		'ReadInt64',
		'ReadInt64LE_2',
		'ReadInt64',

		'ReadFloatSlow',
		'ReadFloat',
		'ReadFloatLE',
		'ReadDoubleSlow',
		'ReadDouble',
		'ReadDoubleLE',

		'ToFileStream',
	}

	for i, fnname in ipairs(import) do
		meta_immutable[fnname] = meta[fnname]
	end
end

local function get_1_bytes_le(pointer, bytes)
	return string_byte(bytes, pointer + 1)
end

local function get_2_bytes_le(pointer, bytes)
	return string_byte(bytes, pointer + 1, pointer + 2)
end

local function get_3_bytes_le(pointer, bytes)
	return string_byte(bytes, pointer + 1, pointer + 3)
end

local function get_4_bytes_le(pointer, bytes)
	return string_byte(bytes, pointer + 1, pointer + 4)
end

local function get_8_bytes_le(pointer, bytes)
	return string_byte(bytes, pointer + 1, pointer + 8)
end

function meta_immutable:ReadUByte()
	self:CheckOverflow('UByte', 1)
	local pointer = self.pointer
	self.pointer = pointer + 1
	return get_1_bytes_le(pointer + self:CurrentSliceStart(), self.bytes)
end

function meta_immutable:ReadUInt16()
	self:CheckOverflow('UInt16', 2)
	local pointer = self.pointer
	self.pointer = pointer + 2
	local a, b = get_2_bytes_le(pointer + self:CurrentSliceStart(), self.bytes)
	return bor(lshift(a, 8), b)
end

function meta_immutable:ReadUInt16LE()
	self:CheckOverflow('UInt16LE', 2)
	local pointer = self.pointer
	self.pointer = pointer + 2
	local a, b = get_2_bytes_le(pointer + self:CurrentSliceStart(), self.bytes)
	return bor(lshift(b, 8), a)
end

function meta_immutable:ReadUInt24()
	self:CheckOverflow('UInt24', 3)
	local pointer = self.pointer
	self.pointer = pointer + 3
	local a, b, c = get_3_bytes_le(pointer + self:CurrentSliceStart(), self.bytes)
	return bor(lshift(a, 8), b, lshift(c, 16))
end

function meta_immutable:ReadUInt24LE()
	self:CheckOverflow('UInt24LE', 3)
	local pointer = self.pointer
	self.pointer = pointer + 3
	local a, b, c = get_3_bytes_le(pointer + self:CurrentSliceStart(), self.bytes)
	return bor(lshift(c, 16), lshift(b, 8), a)
end

function meta_immutable:ReadUInt32()
	self:CheckOverflow('UInt32', 4)
	local pointer = self.pointer
	self.pointer = pointer + 4
	local a, b, c, d = get_4_bytes_le(pointer + self:CurrentSliceStart(), self.bytes)
	local value = bor(lshift(a, 24), lshift(b, 16), lshift(c, 8), d)

	if value < 0 then
		return value + 0x100000000
	end

	return value
end

function meta_immutable:ReadUInt32LE()
	self:CheckOverflow('UInt32LE', 4)
	local pointer = self.pointer
	self.pointer = pointer + 4
	local a, b, c, d = get_4_bytes_le(pointer + self:CurrentSliceStart(), self.bytes)
	local value = bor(lshift(d, 24), lshift(c, 16), lshift(b, 8), a)

	if value < 0 then
		return value + 0x100000000
	end

	return value
end

function meta_immutable:ReadUInt64()
	self:CheckOverflow('UInt64', 8)

	local pointer = self.pointer
	local _poiner = pointer + self:CurrentSliceStart()
	self.pointer = pointer + 8

	local a, b, c, d, e, f, g, k = get_8_bytes_le(_poiner, self.bytes)

	local value = bor(lshift(e, 24), lshift(f, 16), lshift(g, 8), k)

	if value < 0 then
		return value + 0x100000000
	end

	return
		a * 0x100000000000000 +
		b * 0x1000000000000 +
		c * 0x10000000000 +
		d * 0x100000000 +
		value
end

function meta_immutable:ReadUInt64LE()
	self:CheckOverflow('UInt64LE', 8)

	local pointer = self.pointer
	local _poiner = pointer + self:CurrentSliceStart()
	self.pointer = pointer + 8

	local k, g, f, e, d, c, b, a = get_8_bytes_le(_poiner, self.bytes)

	local value = bor(lshift(e, 24), lshift(f, 16), lshift(g, 8), k)

	if value < 0 then
		return value + 0x100000000
	end

	return
		a * 0x100000000000000 +
		b * 0x1000000000000 +
		c * 0x10000000000 +
		d * 0x100000000 +
		value
end

function meta_immutable:ReadString()
	self:CheckOverflow('String', 1)

	local bytes = self.bytes

	for i = self.pointer + self:CurrentSliceStart() + 1, self:CurrentSliceEnd() do
		if string_byte(bytes, i) == 0 then
			local string = string.sub(bytes, self.pointer + 1 + self:CurrentSliceStart(), i - 1)
			self.pointer = i + 1 - self:CurrentSliceStart()
			return string
		end
	end

	error('No NUL terminator was found while reached EOF')
end

function meta_immutable:ReadBinary(readAmount)
	assert(readAmount >= 0, 'Read amount must be positive')
	if readAmount == 0 then return '' end
	self:CheckOverflow('Binary', readAmount)

	local slice = string.sub(self.bytes, self.pointer + 1 + self:CurrentSliceStart(), self.pointer + readAmount + self:CurrentSliceStart())
	self.pointer = self.pointer + readAmount

	return slice
end

function meta_immutable:ToString()
	return string.sub(self.bytes, self:CurrentSliceStart() + 1, self:CurrentSliceEnd())
end

function meta_immutable:StringSlice(slice_start, slice_end)
	return string.sub(self.bytes, slice_start, slice_end)
end

meta_immutable.ReadInt8 = meta_immutable.ReadByte
meta_immutable.ReadUInt8 = meta_immutable.ReadUByte

meta_immutable.ReadShort = meta_immutable.ReadInt16
meta_immutable.ReadShort_2 = meta_immutable.ReadInt16_2
meta_immutable.ReadUShort = meta_immutable.ReadUInt16

meta_immutable.ReadShortLE = meta_immutable.ReadInt16LE
meta_immutable.ReadShortLE_2 = meta_immutable.ReadInt16LE_2
meta_immutable.ReadUShortLE = meta_immutable.ReadUInt16LE

meta_immutable.ReadInt = meta_immutable.ReadInt32
meta_immutable.ReadInt_2 = meta_immutable.ReadInt32_2
meta_immutable.ReadUInt = meta_immutable.ReadUInt32

meta_immutable.ReadIntLE = meta_immutable.ReadInt32LE
meta_immutable.ReadIntLE_2 = meta_immutable.ReadInt32LE_2
meta_immutable.ReadUIntLE = meta_immutable.ReadUInt32LE

meta_immutable.ReadLong = meta_immutable.ReadInt32
meta_immutable.ReadLong_2 = meta_immutable.ReadInt32_2
meta_immutable.ReadULong = meta_immutable.ReadUInt32

meta_immutable.ReadLongLE = meta_immutable.ReadInt32LE
meta_immutable.ReadLongLE_2 = meta_immutable.ReadInt32LE_2
meta_immutable.ReadULongLE = meta_immutable.ReadUInt32LE

meta_immutable.ReadData = meta_immutable.ReadBinary

--[[
	@doc
	@fname DLib.ImmutableBytesBuffer
	@args string binary

	@desc
	Allows to slice string for bytes. Interface is same as `BytesBuffer`,
	except there are no write functions.
	@enddesc

	@returns
	table: newly created object
]]
function meta_immutable:ctor(strIn)
	self.bytes = assert(isstring(strIn) and strIn, 'bad argument #1 to DLib.ImmutableBytesBuffer (string expected, got ' .. type(strIn) .. ')')
	self.length = #strIn
	self.pointer = 0
end

DLib.ImmutableBytesBuffer, DLib.ImmutableBytesBufferBase = DLib.CreateMoonClassBare('LImmutableBytesBuffer', meta_immutable, object_immutable, nil, DLib.ImmutableBytesBuffer, true)
debug.getregistry().LImmutableBytesBuffer = DLib.ImmutableBytesBuffer
