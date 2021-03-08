
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
