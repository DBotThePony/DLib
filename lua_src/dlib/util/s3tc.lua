
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

local DXT1 = {}
local DXT1Object = {}

function DXT1Object.CountBytes(w, h)
	return math.ceil(w * h / 2):max(8)
end

function DXT1:ctor(bytes, width, height)
	self.bytes = bytes
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4

	self.cache = {}
end

local function to_color_5_6_5(value)
	local b = math.floor(value:band(31) * 8.2258064516129)
	local g = math.floor(value:rshift(5):band(63) * 4.047619047619)
	local r = math.floor(value:rshift(11):band(31) * 8.2258064516129)

	return Color(r, g, b)
end

local color_black = Color(0, 0, 0)

function DXT1:GetBlock(x, y)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x
	local block = pixel * 8

	if self.cache[block] then
		return self.cache[block]
	end

	self.bytes:Seek(block)

	-- they are little endians
	local color0 = self.bytes:ReadUInt16():bswap():rshift(16)
	local color1 = self.bytes:ReadUInt16():bswap():rshift(16)

	local color0_d = to_color_5_6_5(color0)
	local color1_d = to_color_5_6_5(color1)

	local describe = self.bytes:ReadUInt32():bswap()

	local decoded = {}

	if color0 > color1 then
		for i = 1, 16 do
			local code = describe:rshift((16 - i) * 2):band(0x3)

			if code == 0 then
				decoded[i] = color0_d
			elseif code == 1 then
				decoded[i] = color1_d
			elseif code == 2 then
				decoded[i] = Color(
					(color0_d.r * 2 + color1_d.r) / 3,
					(color0_d.g * 2 + color1_d.g) / 3,
					(color0_d.b * 2 + color1_d.b) / 3
				)
			else
				decoded[i] = Color(
					(color0_d.r + color1_d.r * 2) / 3,
					(color0_d.g + color1_d.g * 2) / 3,
					(color0_d.b + color1_d.b * 2) / 3
				)
			end
		end
	else
		for i = 1, 16 do
			local code = describe:rshift((16 - i) * 2):band(0x3)

			if code == 0 then
				decoded[i] = color0_d
			elseif code == 1 then
				decoded[i] = color1_d
			elseif code == 2 then
				decoded[i] = Color(
					(color0_d.r + color1_d.r) / 2,
					(color0_d.g + color1_d.g) / 2,
					(color0_d.b + color1_d.b) / 2
				)
			else
				decoded[i] = color_black
			end
		end
	end

	self.cache[block] = {color0, color1, describe, decoded}
	return self.cache[block]
end

function DXT1:GetPixel(x, y)
	local block = self:GetBlock(math.floor(x / 4), math.floor(y / 4))
	local color0, color1, describe, decoded = block[1], block[2], block[3], block[4]

	if color0 > color1 then

	end
end

DLib.DXT1 = DLib.CreateMoonClassBare('DXT1', DXT1, DXT1Object)

local DXT5 = {}

function DXT5:ctor(bytes, width, height)
	self.bytes = bytes
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4
end

function DXT5:GetBlock(x, y)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x <= self.width_blocks, '!x <= self.width_blocks')
	assert(y <= self.height_blocks, '!y <= self.height_blocks')
end

DLib.DXT5 = DLib.CreateMoonClassBare('DXT5', DXT5)
