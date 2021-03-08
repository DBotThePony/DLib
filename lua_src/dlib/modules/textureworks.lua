
-- Copyright (C) 2017-2021 DBotThePony

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

local color_black = Color(0, 0, 0)
local color_white = Color()
local min, max, ceil, floor, clamp, round = math.min, math.max, math.ceil, math.floor, math.clamp, math.round
local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift
local assert = assert
local Color = Color
local DLib = DLib
local string = string

if CLIENT then
	DLib._RenderCapturePixels = DLib._RenderCapturePixels or 0
	DLib._RenderCapturePixelsFn = DLib._RenderCapturePixelsFn or render.CapturePixels

	function render.CapturePixels(...)
		DLib._RenderCapturePixels = DLib._RenderCapturePixels + 1
		return DLib._RenderCapturePixelsFn(...)
	end
end

local AbstractTexture = {}
local AbstractTextureObj = {}

AccessorFunc(AbstractTexture, 'advanced_dither', 'AdvancedDither')

function AbstractTexture:ctor(bytes, width, height)
	self.bytes = bytes
	self.edge = bytes:Tell()
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4
	self.advanced_dither = true

	self.cache = {}
end

local sample_encode_buff = {}

for i = 1, 16 do
	sample_encode_buff[i] = {0, 0, 0, 255}
end

function AbstractTexture:CaptureRenderTarget(rx, ry, w, h, lx, ly)
	for i = 1, 16 do
		sample_encode_buff[i][4] = 255
	end

	local sBlockX = (lx - lx % 4) / 4
	local sBlockY = (ly - ly % 4) / 4

	local fitx = (lx + w + 1) % 4 == 0
	local fity = (ly + h + 1) % 4 == 0
	local fit = fitx and fity
	local fBlockX = ((lx + w + 1) - (lx + w + 1) % 4) / 4 - 1
	local fBlockY = ((ly + h + 1) - (ly + h + 1) % 4) / 4 - 1

	for blockX = sBlockX, fBlockX do
		for blockY = sBlockY, fBlockY do
			for X = 0, 3 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)
		end
	end

	if fit then return end

	if not fitx then
		local blockX = fBlockX + 1

		for blockY = sBlockY, fBlockY do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, lx + w - blockX * 4 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)
		end
	end

	if not fity then
		local blockY = fBlockY + 1

		for blockX = sBlockX, fBlockX do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, 3 do
				for Y = 0, ly + h - blockY * 4 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)
		end
	end

	if not fitx and not fity then
		local blockX = fBlockX + 1
		local blockY = fBlockY + 1

		self:GetBlock(blockX, blockY, sample_encode_buff)

		for X = 0, lx + w - blockX * 4 do
			for Y = 0, ly + h - blockY * 4 do
				local obj = sample_encode_buff[1 + X + Y * 4]
				obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
			end
		end

		self:SetBlock(blockX, blockY, sample_encode_buff, true)
	end
end

local coroutine_yield = coroutine.yield
local SysTime = SysTime

function AbstractTexture:CaptureRenderTargetCoroutine(rx, ry, w, h, lx, ly, callbackBefore, callbackAfter, thersold, ...)
	for i = 1, 16 do
		sample_encode_buff[i][4] = 255
	end

	local sBlockX = (lx - lx % 4) / 4
	local sBlockY = (ly - ly % 4) / 4

	local fitx = (lx + w + 1) % 4 == 0
	local fity = (ly + h + 1) % 4 == 0
	local fit = fitx and fity
	local fBlockX = ((lx + w + 1) - (lx + w + 1) % 4) / 4 - 1
	local fBlockY = ((ly + h + 1) - (ly + h + 1) % 4) / 4 - 1

	local s = SysTime() + thersold
	local total = (fBlockX - sBlockX) * (fBlockY - sBlockY)

	if not fitx then
		total = total + fBlockY - sBlockY
	end

	if not fity then
		total = total + fBlockX - sBlockX
	end

	if not fity and not fitx then
		total = total + 1
	end

	local done = 0

	for blockX = sBlockX, fBlockX do
		for blockY = sBlockY, fBlockY do
			for X = 0, 3 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				local ref = DLib._RenderCapturePixels

				coroutine_yield(...)
				s = SysTime() + thersold
				callbackAfter(done / total)

				if ref ~= DLib._RenderCapturePixels then
					render.CapturePixels()
				end
			end
		end
	end

	if fit then return end

	if not fitx then
		local blockX = fBlockX + 1

		for blockY = sBlockY, fBlockY do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, lx + w - blockX * 4 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				local ref = DLib._RenderCapturePixels

				coroutine_yield(...)
				s = SysTime() + thersold
				callbackAfter(done / total)

				if ref ~= DLib._RenderCapturePixels then
					render.CapturePixels()
				end
			end
		end
	end

	if not fity then
		local blockY = fBlockY + 1

		for blockX = sBlockX, fBlockX do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, 3 do
				for Y = 0, ly + h - blockY * 4 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				local ref = DLib._RenderCapturePixels

				coroutine_yield(...)
				s = SysTime() + thersold
				callbackAfter(done / total)

				if ref ~= DLib._RenderCapturePixels then
					render.CapturePixels()
				end
			end
		end
	end

	if not fitx and not fity then
		local blockX = fBlockX + 1
		local blockY = fBlockY + 1

		self:GetBlock(blockX, blockY, sample_encode_buff)

		for X = 0, lx + w - blockX * 4 do
			for Y = 0, ly + h - blockY * 4 do
				local obj = sample_encode_buff[1 + X + Y * 4]
				obj[1], obj[2], obj[3] = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
			end
		end

		self:SetBlock(blockX, blockY, sample_encode_buff, true)
	end
end

function AbstractTexture:CaptureRenderTargetAlpha(rx, ry, w, h, lx, ly)
	local sBlockX = (lx - lx % 4) / 4
	local sBlockY = (ly - ly % 4) / 4

	local fitx = (lx + w + 1) % 4 == 0
	local fity = (ly + h + 1) % 4 == 0
	local fit = fitx and fity
	local fBlockX = ((lx + w + 1) - (lx + w + 1) % 4) / 4 - 1
	local fBlockY = ((ly + h + 1) - (ly + h + 1) % 4) / 4 - 1

	for blockX = sBlockX, fBlockX do
		for blockY = sBlockY, fBlockY do
			for X = 0, 3 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)
		end
	end

	if fit then return end

	if not fitx then
		local blockX = fBlockX + 1

		for blockY = sBlockY, fBlockY do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, lx + w - blockX * 4 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)
		end
	end

	if not fity then
		local blockY = fBlockY + 1

		for blockX = sBlockX, fBlockX do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, 3 do
				for Y = 0, ly + h - blockY * 4 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)
		end
	end

	if not fitx and not fity then
		local blockX = fBlockX + 1
		local blockY = fBlockY + 1

		self:GetBlock(blockX, blockY, sample_encode_buff)

		for X = 0, lx + w - blockX * 4 do
			for Y = 0, ly + h - blockY * 4 do
				local obj = sample_encode_buff[1 + X + Y * 4]
				local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				obj[4] = (r + g + b) / 3
			end
		end

		self:SetBlock(blockX, blockY, sample_encode_buff, true, true)
	end
end

function AbstractTexture:CaptureRenderTargetAlphaCoroutine(rx, ry, w, h, lx, ly, callbackBefore, callbackAfter, thersold, ...)
	local sBlockX = (lx - lx % 4) / 4
	local sBlockY = (ly - ly % 4) / 4

	local fitx = (lx + w + 1) % 4 == 0
	local fity = (ly + h + 1) % 4 == 0
	local fit = fitx and fity
	local fBlockX = ((lx + w + 1) - (lx + w + 1) % 4) / 4 - 1
	local fBlockY = ((ly + h + 1) - (ly + h + 1) % 4) / 4 - 1

	local s = SysTime() + thersold
	local total = (fBlockX - sBlockX) * (fBlockY - sBlockY)

	if not fitx then
		total = total + fBlockY - sBlockY
	end

	if not fity then
		total = total + fBlockX - sBlockX
	end

	if not fity and not fitx then
		total = total + 1
	end

	local done = 0

	for blockX = sBlockX, fBlockX do
		for blockY = sBlockY, fBlockY do
			for X = 0, 3 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				local ref = DLib._RenderCapturePixels

				coroutine_yield(...)
				s = SysTime() + thersold
				callbackAfter(done / total)

				if ref ~= DLib._RenderCapturePixels then
					render.CapturePixels()
				end
			end
		end
	end

	if fit then return end

	if not fitx then
		local blockX = fBlockX + 1

		for blockY = sBlockY, fBlockY do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, lx + w - blockX * 4 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				local ref = DLib._RenderCapturePixels

				coroutine_yield(...)
				s = SysTime() + thersold
				callbackAfter(done / total)

				if ref ~= DLib._RenderCapturePixels then
					render.CapturePixels()
				end
			end
		end
	end

	if not fity then
		local blockY = fBlockY + 1

		for blockX = sBlockX, fBlockX do
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, 3 do
				for Y = 0, ly + h - blockY * 4 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				local ref = DLib._RenderCapturePixels

				coroutine_yield(...)
				s = SysTime() + thersold
				callbackAfter(done / total)

				if ref ~= DLib._RenderCapturePixels then
					render.CapturePixels()
				end
			end
		end
	end

	if not fitx and not fity then
		local blockX = fBlockX + 1
		local blockY = fBlockY + 1

		self:GetBlock(blockX, blockY, sample_encode_buff)

		for X = 0, lx + w - blockX * 4 do
			for Y = 0, ly + h - blockY * 4 do
				local obj = sample_encode_buff[1 + X + Y * 4]
				local r, g, b = render.ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
				obj[4] = (r + g + b) / 3
			end
		end

		self:SetBlock(blockX, blockY, sample_encode_buff, true, true)
	end
end

function AbstractTexture:GetPixel(x, y)
	local divX, divY = x % 4, y % 4
	local blockX, blockY = (x - divX) / 4, (y - divY) / 4

	return self:GetBlock(blockX, blockY)[divX + divY * 4 + 1]
end

DLib.AbstractTexture, DLib.AbstractTextureBase = DLib.CreateMoonClassBare('AbstractTexture', AbstractTexture, AbstractTextureObj)

--[[
	-- Template:

	local RGBA8888 = {}
	local RGBA8888Object = {}

	function RGBA8888Object.CountBytes(w, h)
		return w * h * 4
	end

	function RGBA8888:SetBlock(x, y, buffer, plain_format, only_update_alpha)
		assert(x >= 0, '!x >= 0')
		assert(y >= 0, '!y >= 0')
		assert(x < self.width_blocks, '!x <= self.width_blocks')
		assert(y < self.height_blocks, '!y <= self.height_blocks')
	end

	function RGBA8888:GetBlock(x, y, export)
		assert(x >= 0, '!x >= 0')
		assert(y >= 0, '!y >= 0')
		assert(x < self.width_blocks, '!x <= self.width_blocks')
		assert(y < self.height_blocks, '!y <= self.height_blocks')

		local pixel = y * self.width_blocks + x

		if not export and self.cache[pixel] then
			return self.cache[pixel]
		end

		local bytes = self.bytes

	end

	DLib.RGBA8888 = DLib.CreateMoonClassBare('RGBA8888', RGBA8888, RGBA8888Object, DLib.AbstractTexture)
]]

local RGBA8888 = {}
local RGBA8888Object = {}

function RGBA8888Object.CountBytes(w, h)
	return w * h * 4
end

function RGBA8888Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b, a = floor(fill.r), floor(fill.g), floor(fill.b), floor(fill.a)

	local filler = string.char(r, g, b, a)

	if not bytes then
		return DLib.RGBA8888(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.RGBA8888(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function RGBA8888:SetBlock(x, y, buffer, plain_format, only_update_alpha)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if plain_format then
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(a, 0x00FFFFFF), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(b, 0x00FFFFFF), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(c, 0x00FFFFFF), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(d, 0x00FFFFFF), lshift(obj[4], 24)))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16), lshift(obj[4], 24)))
			end
		end
	else
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(a, 0x00FFFFFF), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(b, 0x00FFFFFF), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(c, 0x00FFFFFF), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(d, 0x00FFFFFF), lshift(obj.a, 24)))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16), lshift(obj.a, 24)))
			end
		end
	end
end

function RGBA8888:GetBlock(x, y, export)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x

	if not export and self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
			local color = bytes:ReadUInt32LE()
			local obj = export[line * 4 + 1]
			obj[1], obj[2], obj[3], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 2]
			obj[1], obj[2], obj[3], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 3]
			obj[1], obj[2], obj[3], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 4]
			obj[1], obj[2], obj[3], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)
		end
	else
		local result = {}
		local index = 1

		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

			local color = bytes:ReadUInt32LE()
			result[line * 4 + 1] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 2] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 3] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 4] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24))
		end

		self.cache[pixel] = result

		return result
	end
end

function RGBA8888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt32LE()
			result[index] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.RGBA8888 = DLib.CreateMoonClassBare('RGBA8888', RGBA8888, RGBA8888Object, DLib.AbstractTexture)

-- VTFEdit read this format wrong (it read it as GBAR8888 in little-endian byte order
-- or, RABG8888 in big-endian order)
local ARGB8888 = {}
local ARGB8888Object = {}

function ARGB8888Object.CountBytes(w, h)
	return w * h * 4
end

function ARGB8888Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b, a = floor(fill.r), floor(fill.g), floor(fill.b), floor(fill.a)

	local filler = string.char(a, r, g, b)

	if not bytes then
		return DLib.ARGB8888(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.ARGB8888(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function ARGB8888:SetBlock(x, y, buffer, plain_format, only_update_alpha)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if plain_format then
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(lshift(obj[1], 8), lshift(obj[2], 16), lshift(obj[3], 24), obj[4]))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(lshift(obj[1], 8), lshift(obj[2], 16), lshift(obj[3], 24), obj[4]))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(lshift(obj[1], 8), lshift(obj[2], 16), lshift(obj[3], 24), obj[4]))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(lshift(obj[1], 8), lshift(obj[2], 16), lshift(obj[3], 24), obj[4]))
			end
		end
	else
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(lshift(obj.r, 8), lshift(obj.g, 16), lshift(obj.b, 24), band(obj.a, 0xFF)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(lshift(obj.r, 8), lshift(obj.g, 16), lshift(obj.b, 24), band(obj.a, 0xFF)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(lshift(obj.r, 8), lshift(obj.g, 16), lshift(obj.b, 24), band(obj.a, 0xFF)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(lshift(obj.r, 8), lshift(obj.g, 16), lshift(obj.b, 24), band(obj.a, 0xFF)))
			end
		end
	end
end

function ARGB8888:GetBlock(x, y, export)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x

	if not export and self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
			local color = bytes:ReadUInt32LE()
			local obj = export[line * 4 + 1]
			obj[4], obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 2]
			obj[4], obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 3]
			obj[4], obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 4]
			obj[4], obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)
		end
	else
		local result = {}
		local index = 1

		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

			local color = bytes:ReadUInt32LE()
			result[line * 4 + 1] = Color(rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24), band(color, 0xFF))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 2] = Color(rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24), band(color, 0xFF))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 3] = Color(rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24), band(color, 0xFF))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 4] = Color(rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24), band(color, 0xFF))
		end

		self.cache[pixel] = result

		return result
	end
end

function ARGB8888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt32LE()
			result[index] = Color(rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24), band(color, 0xFF))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.ARGB8888 = DLib.CreateMoonClassBare('ARGB8888', ARGB8888, ARGB8888Object, DLib.AbstractTexture)

local BGRA8888 = {}
local BGRA8888Object = {}

function BGRA8888Object.CountBytes(w, h)
	return w * h * 4
end

function BGRA8888Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b, a = floor(fill.r), floor(fill.g), floor(fill.b), floor(fill.a)

	local filler = string.char(b, g, r, a)

	if not bytes then
		return DLib.BGRA8888(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.BGRA8888(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function BGRA8888:SetBlock(x, y, buffer, plain_format, only_update_alpha)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if plain_format then
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(a, 0x00FFFFFF), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(b, 0x00FFFFFF), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(c, 0x00FFFFFF), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(d, 0x00FFFFFF), lshift(obj[4], 24)))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16), lshift(obj[4], 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16), lshift(obj[4], 24)))
			end
		end
	else
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(a, 0x00FFFFFF), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(b, 0x00FFFFFF), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(c, 0x00FFFFFF), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(d, 0x00FFFFFF), lshift(obj.a, 24)))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16), lshift(obj.a, 24)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16), lshift(obj.a, 24)))
			end
		end
	end
end

function BGRA8888:GetBlock(x, y, export)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x

	if not export and self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
			local color = bytes:ReadUInt32LE()
			local obj = export[line * 4 + 1]
			obj[3], obj[2], obj[1], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 2]
			obj[3], obj[2], obj[1], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 3]
			obj[3], obj[2], obj[1], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 4]
			obj[3], obj[2], obj[1], obj[4] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)
		end
	else
		local result = {}
		local index = 1

		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

			local color = bytes:ReadUInt32LE()
			result[line * 4 + 1] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF), rshift(band(color, 0xFF000000), 24))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 2] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF), rshift(band(color, 0xFF000000), 24))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 3] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF), rshift(band(color, 0xFF000000), 24))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 4] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF), rshift(band(color, 0xFF000000), 24))
		end

		self.cache[pixel] = result

		return result
	end
end

function BGRA8888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt32LE()
			result[index] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF), rshift(band(color, 0xFF000000), 24))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.BGRA8888 = DLib.CreateMoonClassBare('BGRA8888', BGRA8888, BGRA8888Object, DLib.AbstractTexture)

local ABGR8888 = {}
local ABGR8888Object = {}

function ABGR8888Object.CountBytes(w, h)
	return w * h * 4
end

function ABGR8888Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b, a = floor(fill.r), floor(fill.g), floor(fill.b), floor(fill.a)

	local filler = string.char(a, b, g, r)

	if not bytes then
		return DLib.ABGR8888(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.ABGR8888(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function ABGR8888:SetBlock(x, y, buffer, plain_format, only_update_alpha)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if plain_format then
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(a, 0xFFFFFF00), obj[4]))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(lshift(obj[3], 8), lshift(obj[2], 16), lshift(obj[1], 24), obj[4]))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(lshift(obj[3], 8), lshift(obj[2], 16), lshift(obj[1], 24), obj[4]))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(lshift(obj[3], 8), lshift(obj[2], 16), lshift(obj[1], 24), obj[4]))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(lshift(obj[3], 8), lshift(obj[2], 16), lshift(obj[1], 24), obj[4]))
			end
		end
	else
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(band(b, 0xFFFFFF00), obj.a, 24))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				bytes:WriteInt32LE(bor(lshift(obj.b, 8), lshift(obj.g, 16), lshift(obj.r, 24), band(obj.a, 0xFF)))

				obj = buffer[line * 4 + 2]
				bytes:WriteInt32LE(bor(lshift(obj.b, 8), lshift(obj.g, 16), lshift(obj.r, 24), band(obj.a, 0xFF)))

				obj = buffer[line * 4 + 3]
				bytes:WriteInt32LE(bor(lshift(obj.b, 8), lshift(obj.g, 16), lshift(obj.r, 24), band(obj.a, 0xFF)))

				obj = buffer[line * 4 + 4]
				bytes:WriteInt32LE(bor(lshift(obj.b, 8), lshift(obj.g, 16), lshift(obj.r, 24), band(obj.a, 0xFF)))
			end
		end
	end
end

function ABGR8888:GetBlock(x, y, export)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x

	if not export and self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
			local color = bytes:ReadUInt32LE()
			local obj = export[line * 4 + 1]
			obj[4], obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 2]
			obj[4], obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 3]
			obj[4], obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 4]
			obj[4], obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)
		end
	else
		local result = {}
		local index = 1

		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

			local color = bytes:ReadUInt32LE()
			result[line * 4 + 1] = Color(rshift(band(color, 0xFF000000), 24), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 2] = Color(rshift(band(color, 0xFF000000), 24), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 3] = Color(rshift(band(color, 0xFF000000), 24), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))

			color = bytes:ReadUInt32LE()
			result[line * 4 + 4] = Color(rshift(band(color, 0xFF000000), 24), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))
		end

		self.cache[pixel] = result

		return result
	end
end

function ABGR8888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt32LE()
			result[index] = Color(rshift(band(color, 0xFF000000), 24), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.ABGR8888 = DLib.CreateMoonClassBare('ABGR8888', ABGR8888, ABGR8888Object, DLib.AbstractTexture)

local RGB888 = {}
local RGB888Object = {}

function RGB888Object.CountBytes(w, h)
	return w * h * 3
end

function RGB888Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b = floor(fill.r), floor(fill.g), floor(fill.b)

	local filler = string.char(r, g, b)

	if not bytes then
		return DLib.RGB888(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.RGB888(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function RGB888:SetBlock(x, y, buffer, plain_format)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if plain_format then
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local obj = buffer[line * 4 + 1]
			bytes:WriteUInt24LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16)))

			obj = buffer[line * 4 + 2]
			bytes:WriteUInt24LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16)))

			obj = buffer[line * 4 + 3]
			bytes:WriteUInt24LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16)))

			obj = buffer[line * 4 + 4]
			bytes:WriteUInt24LE(bor(obj[1], lshift(obj[2], 8), lshift(obj[3], 16)))
		end
	else
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local obj = buffer[line * 4 + 1]
			bytes:WriteUInt24LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16)))

			obj = buffer[line * 4 + 2]
			bytes:WriteUInt24LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16)))

			obj = buffer[line * 4 + 3]
			bytes:WriteUInt24LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16)))

			obj = buffer[line * 4 + 4]
			bytes:WriteUInt24LE(bor(obj.r, lshift(obj.g, 8), lshift(obj.b, 16)))
		end
	end
end

function RGB888:GetBlock(x, y, export)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x

	if not export and self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)
			local color = bytes:ReadUInt24LE()
			local obj = export[line * 4 + 1]
			obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16)

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 2]
			obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 3]
			obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 4]
			obj[1], obj[2], obj[3] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)
		end
	else
		local result = {}
		local index = 1

		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local color = bytes:ReadUInt24LE()
			result[line * 4 + 1] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))

			color = bytes:ReadUInt24LE()
			result[line * 4 + 2] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))

			color = bytes:ReadUInt24LE()
			result[line * 4 + 3] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))

			color = bytes:ReadUInt24LE()
			result[line * 4 + 4] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))
		end

		self.cache[pixel] = result

		return result
	end
end

function RGB888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt24LE()
			result[index] = Color(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.RGB888 = DLib.CreateMoonClassBare('RGB888', RGB888, RGB888Object, DLib.AbstractTexture)

local BGR888 = {}
local BGR888Object = {}

function BGR888Object.CountBytes(w, h)
	return w * h * 3
end

function BGR888Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b = floor(fill.r), floor(fill.g), floor(fill.b)

	local filler = string.char(b, g, r)

	if not bytes then
		return DLib.BGR888(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.BGR888(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function BGR888:SetBlock(x, y, buffer, plain_format)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if plain_format then
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local obj = buffer[line * 4 + 1]
			bytes:WriteUInt24LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16)))

			obj = buffer[line * 4 + 2]
			bytes:WriteUInt24LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16)))

			obj = buffer[line * 4 + 3]
			bytes:WriteUInt24LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16)))

			obj = buffer[line * 4 + 4]
			bytes:WriteUInt24LE(bor(obj[3], lshift(obj[2], 8), lshift(obj[1], 16)))
		end
	else
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local obj = buffer[line * 4 + 1]
			bytes:WriteUInt24LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16)))

			obj = buffer[line * 4 + 2]
			bytes:WriteUInt24LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16)))

			obj = buffer[line * 4 + 3]
			bytes:WriteUInt24LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16)))

			obj = buffer[line * 4 + 4]
			bytes:WriteUInt24LE(bor(obj.b, lshift(obj.g, 8), lshift(obj.r, 16)))
		end
	end
end

function BGR888:GetBlock(x, y, export)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x

	if not export and self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)
			local color = bytes:ReadUInt24LE()
			local obj = export[line * 4 + 1]
			obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16)

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 2]
			obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 3]
			obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 4]
			obj[3], obj[2], obj[1] = band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF000000), 24)
		end
	else
		local result = {}
		local index = 1

		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local color = bytes:ReadUInt24LE()
			result[line * 4 + 1] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))

			color = bytes:ReadUInt24LE()
			result[line * 4 + 2] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))

			color = bytes:ReadUInt24LE()
			result[line * 4 + 3] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))

			color = bytes:ReadUInt24LE()
			result[line * 4 + 4] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))
		end

		self.cache[pixel] = result

		return result
	end
end

function BGR888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt24LE()
			result[index] = Color(rshift(band(color, 0xFF0000), 16), rshift(band(color, 0xFF00), 8), band(color, 0xFF))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.BGR888 = DLib.CreateMoonClassBare('BGR888', BGR888, BGR888Object, DLib.AbstractTexture)

local function encode_color_5_6_5(r, g, b)
	local r = round(clamp(r, 0, 255) * 0.12156862745098)
	local g = round(clamp(g, 0, 255) * 0.24705882352941)
	local b = round(clamp(b, 0, 255) * 0.12156862745098)

	return band(bor(lshift(b, 11), lshift(g, 5), r), 0xFFFF)
end

local function decode_color_5_6_5(value)
	local r = round(band(value, 31) * 8.2258064516129)
	local g = round(band(rshift(value, 5), 63) * 4.047619047619)
	local b = round(band(rshift(value, 11), 31) * 8.2258064516129)

	return r, g, b
end

local function encode_color_5_6_5_le(r, g, b)
	local r = round(clamp(r, 0, 255) * 0.12156862745098)
	local g = round(clamp(g, 0, 255) * 0.24705882352941)
	local b = round(clamp(b, 0, 255) * 0.12156862745098)

	return band(bor(lshift(r, 11), lshift(g, 5), b), 0xFFFF)
end

local function decode_color_5_6_5_le(value)
	local b = round(band(value, 31) * 8.2258064516129)
	local g = round(band(rshift(value, 5), 63) * 4.047619047619)
	local r = round(band(rshift(value, 11), 31) * 8.2258064516129)

	return r, g, b
end

local error_buffer = {}

for i = 1, 16 do
	error_buffer[i] = {0, 0, 0, 0}
end

local function reset_error_buffer()
	for i = 1, 16 do
		local obj = error_buffer[i]
		obj[1] = 0
		obj[2] = 0
		obj[3] = 0
		obj[4] = 0
	end
end

local report_error, receive_error

do
	local dither_precompute = {}
	local _compute = {
		{1, 0, 7 / 48},
		{2, 0, 5 / 48},

		{-2, 1, 3 / 48},
		{-1, 1, 5 / 48},
		{0, 1, 7 / 48},
		{1, 1, 5 / 48},
		{2, 1, 3 / 48},

		{-2, 2, 1 / 48},
		{-1, 2, 3 / 48},
		{0, 2, 5 / 48},
		{1, 2, 3 / 48},
		{2, 2, 1 / 48},
	}

	for X = 0, 3 do
		for Y = 0, 3 do
			local compute = {}
			dither_precompute[1 + X + Y * 4] = compute

			for _, data in ipairs(_compute) do
				local x, y, dither = data[1] + X, data[2] + Y, data[3]

				if x < 4 and x > -1 and y < 4 and y > -1 then
					table.insert(compute, {1 + x + y * 4, dither})
				end
			end
		end
	end

	function report_error(index, r, g, b)
		local _r = round(r * 0.12156862745098)
		local _g = round(g * 0.24705882352941)
		local _b = round(b * 0.12156862745098)

		local r_error, g_error, b_error = r - _r * 8.2258064516129, g - _g * 4.047619047619, b - _b * 8.2258064516129
		local dither = dither_precompute[index]

		for i2 = 1, #dither do
			local _error2 = error_buffer[dither[i2][1]]
			local mult = dither[i2][2]
			_error2[1] = _error2[1] + r_error * mult
			_error2[2] = _error2[2] + g_error * mult
			_error2[3] = _error2[3] + b_error * mult
		end
	end

	function receive_error(index)
		local obj = error_buffer[index]
		return obj[1], obj[2], obj[3], obj[4]
	end
end

-- source engine does not support RGB565 for some vague reasons
-- since BGR565 is supported
local RGB565 = {
	encode_color_5_6_5 = encode_color_5_6_5,
	decode_color_5_6_5 = decode_color_5_6_5,
}
local RGB565Object = {}

function RGB565Object.CountBytes(w, h)
	return w * h * 2
end

function RGB565Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b = floor(fill.r), floor(fill.g), floor(fill.b)
	local color = encode_color_5_6_5(r, g, b)

	local filler = string.char(band(color, 0xFF), rshift(color, 8))

	if not bytes then
		return DLib.RGB565(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.RGB565(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function RGB565:SetBlock(x, y, buffer, plain_format)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width
	local encode_color_5_6_5 = self.encode_color_5_6_5

	local solid = true
	local r, g, b

	if plain_format then
		r, g, b = floor(buffer[1][1]), floor(buffer[1][2]), floor(buffer[1][3])

		for i = 2, 16 do
			local pixel = buffer[i]

			if floor(pixel[1]) ~= r or floor(pixel[2]) ~= g or floor(pixel[3]) ~= b then
				solid = false
				break
			end
		end
	else
		r, g, b = floor(buffer[1].r), floor(buffer[1].g), floor(buffer[1].b)

		for i = 2, 16 do
			local pixel = buffer[i]

			if floor(pixel.r) ~= r or floor(pixel.g) ~= g or floor(pixel.b) ~= b then
				solid = false
				break
			end
		end
	end

	if solid then
		local wColor0 = encode_color_5_6_5(r, g, b)
		wColor0 = bor(wColor0, lshift(wColor0, 16))

		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)
			bytes:WriteInt32LE(wColor0)
			bytes:WriteInt32LE(wColor0)
		end

		return
	end

	reset_error_buffer()

	if plain_format then
		for i = 1, 16 do
			local obj = buffer[i]
			report_error(i, obj[1], obj[2], obj[3])
		end

		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

			local obj = buffer[line * 4 + 1]
			local _r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b))

			obj = buffer[line * 4 + 2]
			_r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b))

			obj = buffer[line * 4 + 3]
			_r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b))

			obj = buffer[line * 4 + 4]
			_r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b))
		end
	else
		for i = 1, 16 do
			local obj = buffer[i]
			report_error(i, obj.r, obj.g, obj.b)
		end

		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

			local obj = buffer[line * 4 + 1]
			local _r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b))

			obj = buffer[line * 4 + 2]
			_r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b))

			obj = buffer[line * 4 + 3]
			_r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b))

			obj = buffer[line * 4 + 4]
			_r, _g, _b = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b))
		end
	end
end

function RGB565:GetBlock(x, y, export)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x

	if not export and self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width

	local decode_color_5_6_5 = self.decode_color_5_6_5

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)
			local color = bytes:ReadUInt16LE()
			local obj = export[line * 4 + 1]
			obj[1], obj[2], obj[3] = decode_color_5_6_5(color)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 2]
			obj[1], obj[2], obj[3] = decode_color_5_6_5(color)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 3]
			obj[1], obj[2], obj[3] = decode_color_5_6_5(color)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 4]
			obj[1], obj[2], obj[3] = decode_color_5_6_5(color)
		end
	else
		local result = {}
		local index = 1

		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

			local color = bytes:ReadUInt16LE()
			result[line * 4 + 1] = Color(decode_color_5_6_5(color))

			color = bytes:ReadUInt16LE()
			result[line * 4 + 2] = Color(decode_color_5_6_5(color))

			color = bytes:ReadUInt16LE()
			result[line * 4 + 3] = Color(decode_color_5_6_5(color))

			color = bytes:ReadUInt16LE()
			result[line * 4 + 4] = Color(decode_color_5_6_5(color))
		end

		self.cache[pixel] = result

		return result
	end
end

function RGB565:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	local decode_color_5_6_5 = self.decode_color_5_6_5

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt16LE()
			result[index] = Color(decode_color_5_6_5(color))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.RGB565 = DLib.CreateMoonClassBare('RGB565', RGB565, RGB565Object, DLib.AbstractTexture)

local BGR565 = {
	encode_color_5_6_5 = encode_color_5_6_5_le,
	decode_color_5_6_5 = decode_color_5_6_5_le,
}
local BGR565Object = {}

function BGR565Object.CountBytes(w, h)
	return w * h * 2
end

function BGR565Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local r, g, b = floor(fill.r), floor(fill.g), floor(fill.b)
	local color = encode_color_5_6_5_le(r, g, b)

	local filler = string.char(band(color, 0xFF), rshift(color, 8))

	if not bytes then
		return DLib.BGR565(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.BGR565(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

DLib.BGR565 = DLib.CreateMoonClassBare('BGR565', BGR565, BGR565Object, DLib.RGB565)
