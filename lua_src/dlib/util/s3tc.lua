
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
				decoded[17 - i] = color0_d
			elseif code == 1 then
				decoded[17 - i] = color1_d
			elseif code == 2 then
				decoded[17 - i] = Color(
					(color0_d.r * 2 + color1_d.r) / 3,
					(color0_d.g * 2 + color1_d.g) / 3,
					(color0_d.b * 2 + color1_d.b) / 3
				)
			else
				decoded[17 - i] = Color(
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
				decoded[17 - i] = color0_d
			elseif code == 1 then
				decoded[17 - i] = color1_d
			elseif code == 2 then
				decoded[17 - i] = Color(
					(color0_d.r + color1_d.r) / 2,
					(color0_d.g + color1_d.g) / 2,
					(color0_d.b + color1_d.b) / 2
				)
			else
				decoded[i] = color_black
			end
		end
	end

	self.cache[block] = decoded

	return decoded
end

DLib.DXT1 = DLib.CreateMoonClassBare('DXT1', DXT1, DXT1Object)

local DXT3 = {}
local DXT3Object = {}

function DXT3Object.CountBytes(w, h)
	return math.ceil(w * h):max(16)
end

function DXT3:ctor(bytes, width, height)
	self.bytes = bytes
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4

	self.cache = {}
end

function DXT3:GetBlock(x, y)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x <= self.width_blocks, '!x <= self.width_blocks')
	assert(y <= self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x
	local block = pixel * 16

	if self.cache[block] then
		return self.cache[block]
	end

	self.bytes:Seek(block)

	local alpha0 = self.bytes:ReadUInt32():bswap()
	local alpha1 = self.bytes:ReadUInt32():bswap()

	local color0 = self.bytes:ReadUInt16():bswap():rshift(16)
	local color1 = self.bytes:ReadUInt16():bswap():rshift(16)

	local color0_d = to_color_5_6_5(color0)
	local color1_d = to_color_5_6_5(color1)

	local describe = self.bytes:ReadUInt32():bswap()

	local decoded = {}

	-- https://www.khronos.org/opengl/wiki/S3_Texture_Compression
	-- state that:
	-- compressed almost as in the DXT1 case; the difference being that color0 is
	-- always assumed to be less than color1 in terms of determining how to use the
	-- codes to extract the color value

	-- which seems to be not the case with source engine

	-- it appears that source engine actually assume that color0 is always *bigger* than color1
	for i = 1, 16 do
		local code = describe:rshift((16 - i) * 2):band(0x3)
		local alpha = (i <= 8 and alpha1 or alpha0):rshift(((16 - i) % 8) * 4):band(0xF) * 0x11

		if code == 0 then
			decoded[17 - i] = color0_d:ModifyAlpha(alpha)
		elseif code == 1 then
			decoded[17 - i] = color1_d:ModifyAlpha(alpha)
		elseif code == 2 then
			decoded[17 - i] = Color(
				(color0_d.r * 2 + color1_d.r) / 3,
				(color0_d.g * 2 + color1_d.g) / 3,
				(color0_d.b * 2 + color1_d.b) / 3,
				alpha
			)
		else
			decoded[17 - i] = Color(
				(color0_d.r + color1_d.r * 2) / 3,
				(color0_d.g + color1_d.g * 2) / 3,
				(color0_d.b + color1_d.b * 2) / 3,
				alpha
			)
		end
	end

	self.cache[block] = decoded

	return decoded
end

DLib.DXT3 = DLib.CreateMoonClassBare('DXT3', DXT3, DXT3Object)

local DXT5 = {}
local DXT5Object = {}

function DXT5Object.CountBytes(w, h)
	return math.ceil(w * h):max(16)
end

function DXT5:ctor(bytes, width, height)
	self.bytes = bytes
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4

	self.cache = {}
end

function DXT5:GetBlock(x, y)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x <= self.width_blocks, '!x <= self.width_blocks')
	assert(y <= self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x
	local block = pixel * 16

	if self.cache[block] then
		return self.cache[block]
	end

	self.bytes:Seek(block)

	local alpha0 = self.bytes:ReadUByte() / 255
	local alpha1 = self.bytes:ReadUByte() / 255

	local readalpha0 = self.bytes:ReadUByte()
	local readalpha1 = self.bytes:ReadUByte()
	local readalpha2 = self.bytes:ReadUByte()

	local readalpha3 = self.bytes:ReadUByte()
	local readalpha4 = self.bytes:ReadUByte()
	local readalpha5 = self.bytes:ReadUByte()

	local alphacode0 = readalpha0:bor(readalpha1:lshift(8), readalpha2:lshift(16))
	local alphacode1 = readalpha3:bor(readalpha4:lshift(8), readalpha5:lshift(16))

	local color0 = self.bytes:ReadUInt16():bswap():rshift(16)
	local color1 = self.bytes:ReadUInt16():bswap():rshift(16)

	local color0_d = to_color_5_6_5(color0)
	local color1_d = to_color_5_6_5(color1)

	local describe = self.bytes:ReadUInt32():bswap()

	local decoded = {}

	for i = 1, 16 do
		local code = describe:rshift((16 - i) * 2):band(0x3)

		if i <= 8 then
			alphacode = alphacode1:rshift((8 - i) * 3):band(0x7)
		else
			alphacode = alphacode0:rshift((16 - i) * 3):band(0x7)
		end

		local alpha

		if alpha0 > alpha1 then
			if alphacode == 0 then
				alpha = alpha0
			elseif alphacode == 1 then
				alpha = alpha1
			elseif alphacode == 2 then
				alpha = (6*alpha0 + 1*alpha1)/7
			elseif alphacode == 3 then
				alpha = (5*alpha0 + 2*alpha1)/7
			elseif alphacode == 4 then
				alpha = (4*alpha0 + 3*alpha1)/7
			elseif alphacode == 5 then
				alpha = (3*alpha0 + 4*alpha1)/7
			elseif alphacode == 6 then
				alpha = (2*alpha0 + 5*alpha1)/7
			else
				alpha = (1*alpha0 + 6*alpha1)/7
			end
		else
			if alphacode == 0 then
				alpha = alpha0
			elseif alphacode == 1 then
				alpha = alpha1
			elseif alphacode == 2 then
				alpha = (4*alpha0 + 1*alpha1)/5
			elseif alphacode == 3 then
				alpha = (3*alpha0 + 2*alpha1)/5
			elseif alphacode == 4 then
				alpha = (2*alpha0 + 3*alpha1)/5
			elseif alphacode == 5 then
				alpha = (1*alpha0 + 4*alpha1)/5
			elseif alphacode == 6 then
				alpha = 0
			else
				alpha = 1
			end
		end

		alpha = math.floor(alpha * 255)

		if code == 0 then
			decoded[17 - i] = color0_d:ModifyAlpha(alpha)
		elseif code == 1 then
			decoded[17 - i] = color1_d:ModifyAlpha(alpha)
		elseif code == 2 then
			decoded[17 - i] = Color(
				(color0_d.r * 2 + color1_d.r) / 3,
				(color0_d.g * 2 + color1_d.g) / 3,
				(color0_d.b * 2 + color1_d.b) / 3,
				alpha
			)
		else
			decoded[17 - i] = Color(
				(color0_d.r + color1_d.r * 2) / 3,
				(color0_d.g + color1_d.g * 2) / 3,
				(color0_d.b + color1_d.b * 2) / 3,
				alpha
			)
		end
	end

	self.cache[block] = decoded

	return decoded
end

DLib.DXT5 = DLib.CreateMoonClassBare('DXT5', DXT5, DXT5Object)
