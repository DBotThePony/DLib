
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
local render = render
local string_byte = string.byte
local render_ReadPixel

if CLIENT then
	render_ReadPixel = render.ReadPixel

	if not DLib._RenderCapturePixelsFn or debug.getinfo(render.CapturePixels).source:find('dlib') then
		DLib._RenderCapturePixels = DLib._RenderCapturePixels or 0
		DLib._RenderCapturePixels_TextureWorks = DLib._RenderCapturePixels_TextureWorks or 0
		DLib._RenderCapturePixelsFn = DLib._RenderCapturePixelsFn or render.CapturePixels

		function render.CapturePixels(...)
			DLib._RenderCapturePixels = DLib._RenderCapturePixels + 1
			return DLib._RenderCapturePixelsFn(...)
		end
	end

	if not render.CapturePixelsBitmap or debug.getinfo(render.CapturePixelsBitmap).source:find('dlib') then
		local buff = {}
		local string_char = string.char
		local unpack = unpack
		local ScrW = ScrW
		local ScrH = ScrH

		function render.CapturePixelsBitmap()
			render.CapturePixels()
			local buildbuff = {}

			local w, h = ScrW(), ScrH()

			local buff_index = 1
			local build_index = 1

			for y = 0, h - 1 do
				for x = 0, w - 1 do
					local r, g, b, a = render_ReadPixel(x, y)
					buff[buff_index] = r
					buff[buff_index + 1] = g
					buff[buff_index + 2] = b
					buff[buff_index + 3] = a or 255
					buff_index = buff_index + 4

					if buff_index >= 7900 then
						buildbuff[build_index] = string_char(unpack(buff, 1, buff_index - 1))
						build_index = build_index + 1
						buff_index = 1
					end
				end
			end

			if build_index > 1 then
				buildbuff[build_index] = string_char(unpack(buff, 1, buff_index - 1))
			end

			return table.concat(buildbuff, '')
		end
	end
end

local AbstractTexture = {}
local AbstractTextureObj = {}

AccessorFunc(AbstractTexture, 'dither', 'Dither')

function AbstractTexture:ctor(bytes, width, height)
	self.bytes = bytes
	self.edge = bytes:Tell()
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4
	self.dither = true

	self.cache = {}
end

function AbstractTexture:GetPointer()
	return self.edge
end

function AbstractTexture:GetBytesBuffer()
	return self.bytes
end

function AbstractTexture:ReadBinary()
	self.bytes:Seek(self.edge)
	return self.bytes:ReadBinary(self.__class.CountBytes(self.width, self.height))
end

function AbstractTexture:WriteBinary(str)
	self.bytes:Seek(self.edge)
	self.bytes:WriteBinary(str)
end

local sample_encode_buff = {}

for i = 1, 16 do
	sample_encode_buff[i] = {0, 0, 0, 255}
end

local function ReadPixel(x, y)
	local r, g, b, a = render_ReadPixel(x, y)
	return r or 0, g or 0, b or 0, a or 255
end

function AbstractTexture:CaptureRenderTarget(rx, ry, w, h, lx, ly)
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
					obj[1], obj[2], obj[3], obj[4] = ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
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
					obj[1], obj[2], obj[3], obj[4] = ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
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
					obj[1], obj[2], obj[3], obj[4] = ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
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
				obj[1], obj[2], obj[3], obj[4] = ReadPixel(rx + X + blockX * 4, ry + Y + blockY * 4)
			end
		end

		self:SetBlock(blockX, blockY, sample_encode_buff, true)
	end
end

local coroutine_yield = coroutine.yield
local coroutine_syswait = coroutine.syswait
local SysTime = SysTime

local function read_bitmap(bitmap, x, y, w, h)
	local pointer = (x + y * w) * 4
	local r, g, b, a = string_byte(bitmap, pointer + 1, pointer + 4)

	if r then
		return r, g, b, a
	end

	return 0, 0, 0, 255
end

function AbstractTexture:CaptureRenderTargetCoroutine(bitmap, bW, bH, rx, ry, w, h, lx, ly, callbackBefore, callbackAfter, thersold, ...)
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
					obj[1], obj[2], obj[3], obj[4] = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				coroutine_yield(...)
				s = SysTime() + thersold

				callbackAfter(done / total)
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
					obj[1], obj[2], obj[3], obj[4] = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				coroutine_yield(...)
				s = SysTime() + thersold

				callbackAfter(done / total)
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
					obj[1], obj[2], obj[3], obj[4] = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				coroutine_yield(...)
				s = SysTime() + thersold

				callbackAfter(done / total)
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
				obj[1], obj[2], obj[3], obj[4] = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
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
			self:GetBlock(blockX, blockY, sample_encode_buff)

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

function AbstractTexture:CaptureRenderTargetAlphaCoroutine(bitmap, bW, bH, rx, ry, w, h, lx, ly, callbackBefore, callbackAfter, thersold, ...)
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
			self:GetBlock(blockX, blockY, sample_encode_buff)

			for X = 0, 3 do
				for Y = 0, 3 do
					local obj = sample_encode_buff[1 + X + Y * 4]
					local r, g, b = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				coroutine_yield(...)
				s = SysTime() + thersold

				callbackAfter(done / total)
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
					local r, g, b = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				coroutine_yield(...)
				s = SysTime() + thersold

				callbackAfter(done / total)
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
					local r, g, b = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
					obj[4] = (r + g + b) / 3
				end
			end

			self:SetBlock(blockX, blockY, sample_encode_buff, true, true)

			done = done + 1

			if SysTime() >= s then
				callbackBefore()

				coroutine_yield(...)
				s = SysTime() + thersold

				callbackAfter(done / total)
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
				local r, g, b = read_bitmap(bitmap, rx + X + blockX * 4, ry + Y + blockY * 4, bW, bH)
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

local RGBA8888 = {
	flip = function(r, g, b, a) return r, g, b, a end,
	flop = function(r, g, b, a) return r, g, b, a end,
	update_alpha = function(value, a) return bor(band(value, 0x00FFFFFF), lshift(a, 24)) end,
}
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
	local flip = self.flip
	local update_alpha = self.update_alpha

	if plain_format then
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
				local a = bytes:ReadUInt32LE()
				local b = bytes:ReadUInt32LE()
				local c = bytes:ReadUInt32LE()
				local d = bytes:ReadUInt32LE()
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				bytes:WriteInt32LE(update_alpha(a, buffer[line * 4 + 1][4]))
				bytes:WriteInt32LE(update_alpha(b, buffer[line * 4 + 2][4]))
				bytes:WriteInt32LE(update_alpha(c, buffer[line * 4 + 3][4]))
				bytes:WriteInt32LE(update_alpha(d, buffer[line * 4 + 4][4]))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				local r, g, b, a = flip(obj[1], obj[2], obj[3], obj[4])
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))

				obj = buffer[line * 4 + 2]
				r, g, b, a = flip(obj[1], obj[2], obj[3], obj[4])
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))

				obj = buffer[line * 4 + 3]
				r, g, b, a = flip(obj[1], obj[2], obj[3], obj[4])
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))

				obj = buffer[line * 4 + 4]
				r, g, b, a = flip(obj[1], obj[2], obj[3], obj[4])
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))
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

				bytes:WriteInt32LE(update_alpha(a, buffer[line * 4 + 1].a))
				bytes:WriteInt32LE(update_alpha(b, buffer[line * 4 + 2].a))
				bytes:WriteInt32LE(update_alpha(c, buffer[line * 4 + 3].a))
				bytes:WriteInt32LE(update_alpha(d, buffer[line * 4 + 4].a))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

				local obj = buffer[line * 4 + 1]
				local r, g, b, a = flip(obj.r, obj.g, obj.b, obj.a)
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))

				obj = buffer[line * 4 + 2]
				r, g, b, a = flip(obj.r, obj.g, obj.b, obj.a)
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))

				obj = buffer[line * 4 + 3]
				r, g, b, a = flip(obj.r, obj.g, obj.b, obj.a)
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))

				obj = buffer[line * 4 + 4]
				r, g, b, a = flip(obj.r, obj.g, obj.b, obj.a)
				bytes:WriteInt32LE(bor(r, lshift(g, 8), lshift(b, 16), lshift(a, 24)))
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
	local flop = self.flop

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)
			local color = bytes:ReadUInt32LE()
			local obj = export[line * 4 + 1]
			obj[1], obj[2], obj[3], obj[4] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24))

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 2]
			obj[1], obj[2], obj[3], obj[4] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24))

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 3]
			obj[1], obj[2], obj[3], obj[4] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24))

			color = bytes:ReadUInt32LE()
			obj = export[line * 4 + 4]
			obj[1], obj[2], obj[3], obj[4] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24))
		end

		return export
	end

	local result = {}
	local index = 1

	for line = 0, 3 do
		bytes:Seek(edge + x * 16 + y * width * 16 + line * width * 4)

		local color = bytes:ReadUInt32LE()
		result[line * 4 + 1] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24)))

		color = bytes:ReadUInt32LE()
		result[line * 4 + 2] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24)))

		color = bytes:ReadUInt32LE()
		result[line * 4 + 3] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24)))

		color = bytes:ReadUInt32LE()
		result[line * 4 + 4] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24)))
	end

	self.cache[pixel] = result

	return result
end

function RGBA8888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes

	bytes:Seek(self.edge)

	local flop = self.flop

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt32LE()
			result[index] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16), rshift(color, 24)))
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
local ARGB8888 = {
	flip = function(r, g, b, a) return a, r, g, b end,
	flop = function(a, r, g, b) return r, g, b, a end,
	update_alpha = function(value, a) return bor(band(value, 0xFFFFFF00), a) end,
}
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

DLib.ARGB8888 = DLib.CreateMoonClassBare('ARGB8888', ARGB8888, ARGB8888Object, DLib.RGBA8888)

local BGRA8888 = {
	flip = function(r, g, b, a) return b, g, r, a end,
	flop = function(b, g, r, a) return r, g, b, a end,
}
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

DLib.BGRA8888 = DLib.CreateMoonClassBare('BGRA8888', BGRA8888, BGRA8888Object, DLib.RGBA8888)

local ABGR8888 = {
	flip = function(r, g, b, a) return a, b, g, r end,
	flop = function(a, b, g, r) return r, g, b, a end,
	update_alpha = function(value, a) return bor(band(value, 0xFFFFFF00), a) end,
}
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

DLib.ABGR8888 = DLib.CreateMoonClassBare('ABGR8888', ABGR8888, ABGR8888Object, DLib.RGBA8888)

local RGB888 = {
	flip = function(r, g, b) return r, g, b end,
	flop = function(r, g, b) return r, g, b end,
}
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
	local flip = self.flip

	if plain_format then
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local obj = buffer[line * 4 + 1]
			local r, g, b = flip(obj[1], obj[2], obj[3])
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))

			obj = buffer[line * 4 + 2]
			r, g, b = flip(obj[1], obj[2], obj[3])
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))

			obj = buffer[line * 4 + 3]
			r, g, b = flip(obj[1], obj[2], obj[3])
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))

			obj = buffer[line * 4 + 4]
			r, g, b = flip(obj[1], obj[2], obj[3])
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))
		end
	else
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

			local obj = buffer[line * 4 + 1]
			local r, g, b = flip(obj.r, obj.g, obj.b)
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))

			obj = buffer[line * 4 + 2]
			r, g, b = flip(obj.r, obj.g, obj.b)
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))

			obj = buffer[line * 4 + 3]
			r, g, b = flip(obj.r, obj.g, obj.b)
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))

			obj = buffer[line * 4 + 4]
			r, g, b = flip(obj.r, obj.g, obj.b)
			bytes:WriteUInt24LE(bor(r, lshift(g, 8), lshift(b, 16)))
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
	local flop = self.flop

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)
			local color = bytes:ReadUInt24LE()
			local obj = export[line * 4 + 1]
			obj[1], obj[2], obj[3] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 2]
			obj[1], obj[2], obj[3] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 3]
			obj[1], obj[2], obj[3] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))

			color = bytes:ReadUInt24LE()
			obj = export[line * 4 + 4]
			obj[1], obj[2], obj[3] = flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16))
		end

		return export
	end

	local result = {}
	local index = 1

	for line = 0, 3 do
		bytes:Seek(edge + x * 12 + y * width * 12 + line * width * 3)

		local color = bytes:ReadUInt24LE()
		result[line * 4 + 1] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16)))

		color = bytes:ReadUInt24LE()
		result[line * 4 + 2] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16)))

		color = bytes:ReadUInt24LE()
		result[line * 4 + 3] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16)))

		color = bytes:ReadUInt24LE()
		result[line * 4 + 4] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16)))
	end

	self.cache[pixel] = result

	return result
end

function RGB888:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes
	local flop = self.flop

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt24LE()
			result[index] = Color(flop(band(color, 0xFF), rshift(band(color, 0xFF00), 8), rshift(band(color, 0xFF0000), 16)))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.RGB888 = DLib.CreateMoonClassBare('RGB888', RGB888, RGB888Object, DLib.AbstractTexture)

local BGR888 = {
	flip = function(r, g, b) return b, g, r end,
	flop = function(b, g, r) return r, g, b end,
}
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

DLib.BGR888 = DLib.CreateMoonClassBare('BGR888', BGR888, BGR888Object, DLib.RGB888)

local function encode_color_5_6_5(r, g, b, a)
	r = round(clamp(r, 0, 255) * 0.12156862745098)
	g = round(clamp(g, 0, 255) * 0.24705882352941)
	b = round(clamp(b, 0, 255) * 0.12156862745098)

	return band(bor(lshift(b, 11), lshift(g, 5), r), 0xFFFF)
end

local function decode_color_5_6_5(value)
	local r = round(band(value, 31) * 8.2258064516129)
	local g = round(band(rshift(value, 5), 63) * 4.047619047619)
	local b = round(band(rshift(value, 11), 31) * 8.2258064516129)

	return r, g, b, 255
end

local function encode_color_5_6_5_le(r, g, b, a)
	r = round(clamp(r, 0, 255) * 0.12156862745098)
	g = round(clamp(g, 0, 255) * 0.24705882352941)
	b = round(clamp(b, 0, 255) * 0.12156862745098)

	return band(bor(lshift(r, 11), lshift(g, 5), b), 0xFFFF)
end

local function encode_color_4444_le(r, g, b, a)
	r = round(clamp(r, 0, 255) * 0.058823529411765)
	g = round(clamp(g, 0, 255) * 0.058823529411765)
	b = round(clamp(b, 0, 255) * 0.058823529411765)
	a = round(clamp(a, 0, 255) * 0.058823529411765)

	return band(bor(lshift(a, 12), lshift(r, 8), lshift(g, 4), b), 0xFFFF)
end

local function encode_color_5551_le(r, g, b, a)
	r = round(clamp(r, 0, 255) * 0.12156862745098)
	g = round(clamp(g, 0, 255) * 0.12156862745098)
	b = round(clamp(b, 0, 255) * 0.12156862745098)
	a = a > 127.5 and 1 or 0

	return band(bor(lshift(a, 15), lshift(r, 10), lshift(g, 5), b), 0xFFFF)
end

local function decode_color_5_6_5_le(value)
	local b = round(band(value, 31) * 8.2258064516129)
	local g = round(band(rshift(value, 5), 63) * 4.047619047619)
	local r = round(band(rshift(value, 11), 31) * 8.2258064516129)

	return r, g, b, 255
end

local function decode_color_4444_le(value)
	local b = round(band(value, 15) * 17)
	local g = round(band(rshift(value, 4), 15) * 17)
	local r = round(band(rshift(value, 8), 15) * 17)
	local a = round(band(rshift(value, 12), 15) * 17)

	return r, g, b, a
end

local function decode_color_5551_le(value)
	local b = round(band(value, 31) * 8.2258064516129)
	local g = round(band(rshift(value, 5), 31) * 8.2258064516129)
	local r = round(band(rshift(value, 10), 31) * 8.2258064516129)
	local a = rshift(value, 15) == 1 and 255 or 0

	return r, g, b, a
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

local report_error, receive_error, report_error_4444, report_error_5551

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

	-- no dither for alpha since it is just one bit
	function report_error_5551(index, r, g, b, a)
		local _r = round(r * 0.12156862745098)
		local _g = round(g * 0.12156862745098)
		local _b = round(b * 0.12156862745098)

		local r_error, g_error, b_error = r - _r * 8.2258064516129, g - _g * 8.2258064516129, b - _b * 8.2258064516129
		local dither = dither_precompute[index]

		for i2 = 1, #dither do
			local _error2 = error_buffer[dither[i2][1]]
			local mult = dither[i2][2]
			_error2[1] = _error2[1] + r_error * mult
			_error2[2] = _error2[2] + g_error * mult
			_error2[3] = _error2[3] + b_error * mult
		end
	end

	function report_error_4444(index, r, g, b, a)
		local _r = round(r * 0.058823529411765)
		local _g = round(g * 0.058823529411765)
		local _b = round(b * 0.058823529411765)
		local _a = round(a * 0.058823529411765)

		local r_error, g_error, b_error, a_error = r - _r * 17, g - _g * 17, b - _b * 17, a - _a * 17
		local dither = dither_precompute[index]

		for i2 = 1, #dither do
			local _error2 = error_buffer[dither[i2][1]]
			local mult = dither[i2][2]
			_error2[1] = _error2[1] + r_error * mult
			_error2[2] = _error2[2] + g_error * mult
			_error2[3] = _error2[3] + b_error * mult
			_error2[4] = _error2[4] + a_error * mult
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
	report_error = report_error,
	care_about_alpha = false
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
	local r, g, b, a

	if self.care_about_alpha then
		if plain_format then
			r, g, b, a = floor(buffer[1][1]), floor(buffer[1][2]), floor(buffer[1][3]), floor(buffer[1][4])

			for i = 2, 16 do
				local pixel = buffer[i]

				if floor(pixel[1]) ~= r or floor(pixel[2]) ~= g or floor(pixel[3]) ~= b or floor(pixel[4]) ~= a then
					solid = false
					break
				end
			end
		else
			r, g, b, a = floor(buffer[1].r), floor(buffer[1].g), floor(buffer[1].b), floor(buffer[1].a)

			for i = 2, 16 do
				local pixel = buffer[i]

				if floor(pixel.r) ~= r or floor(pixel.g) ~= g or floor(pixel.b) ~= b or floor(pixel.a) ~= a then
					solid = false
					break
				end
			end
		end
	else
		a = 255

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
	end

	if solid then
		local wColor0 = encode_color_5_6_5(r, g, b, a)
		wColor0 = bor(wColor0, lshift(wColor0, 16))

		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)
			bytes:WriteInt32LE(wColor0)
			bytes:WriteInt32LE(wColor0)
		end

		return
	end

	reset_error_buffer()
	local report_error = self.report_error

	if plain_format then
		if self.dither then
			for i = 1, 16 do
				local obj = buffer[i]
				report_error(i, obj[1], obj[2], obj[3], obj[4])
			end
		end

		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

			local obj = buffer[line * 4 + 1]
			local _r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b, obj[4] + _a))

			obj = buffer[line * 4 + 2]
			r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b, obj[4] + _a))

			obj = buffer[line * 4 + 3]
			r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b, obj[4] + _a))

			obj = buffer[line * 4 + 4]
			r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj[1] + _r, obj[2] + _g, obj[3] + _b, obj[4] + _a))
		end
	else
		if self.dither then
			for i = 1, 16 do
				local obj = buffer[i]
				report_error(i, obj.r, obj.g, obj.b, obj.a)
			end
		end

		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

			local obj = buffer[line * 4 + 1]
			local _r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b, obj.a + _a))

			obj = buffer[line * 4 + 2]
			_r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b, obj.a + _a))

			obj = buffer[line * 4 + 3]
			_r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b, obj.a + _a))

			obj = buffer[line * 4 + 4]
			_r, _g, _b, _a = receive_error(line * 4 + 1)
			bytes:WriteUInt16LE(encode_color_5_6_5(obj.r + _r, obj.g + _g, obj.b + _b, obj.a + _a))
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
			obj[1], obj[2], obj[3], obj[4] = decode_color_5_6_5(color)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 2]
			obj[1], obj[2], obj[3], obj[4] = decode_color_5_6_5(color)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 3]
			obj[1], obj[2], obj[3], obj[4] = decode_color_5_6_5(color)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 4]
			obj[1], obj[2], obj[3], obj[4] = decode_color_5_6_5(color)
		end

		return export
	end

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

local BGRA4444 = {
	encode_color_5_6_5 = encode_color_4444_le,
	decode_color_5_6_5 = decode_color_4444_le,
	report_error = report_error_4444,
	care_about_alpha = true
}
local BGRA4444Object = {}

function BGRA4444Object.CountBytes(w, h)
	return w * h * 2
end

function BGRA4444Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local color = encode_color_4444_le(floor(fill.r), floor(fill.g), floor(fill.b), floor(fill.a))

	local filler = string.char(band(color, 0xFF), rshift(color, 8))

	if not bytes then
		return DLib.BGRA4444(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.BGRA4444(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

DLib.BGRA4444 = DLib.CreateMoonClassBare('BGRA4444', BGRA4444, BGRA4444Object, DLib.RGB565)

local BGRA5551 = {
	encode_color_5_6_5 = encode_color_5551_le,
	decode_color_5_6_5 = decode_color_5551_le,
	report_error = report_error_5551,
	care_about_alpha = true
}
local BGRA5551Object = {}

function BGRA5551Object.CountBytes(w, h)
	return w * h * 2
end

function BGRA5551Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local color = encode_color_4444_le(floor(fill.r), floor(fill.g), floor(fill.b), floor(fill.a))

	local filler = string.char(band(color, 0xFF), rshift(color, 8))

	if not bytes then
		return DLib.BGRA5551(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.BGRA5551(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

DLib.BGRA5551 = DLib.CreateMoonClassBare('BGRA5551', BGRA5551, BGRA5551Object, DLib.RGB565)

local function to_luma_rec601(r, g, b) return round(r * 0.299 + g * 0.587 + b * 0.114) end
local function to_luma_rec709(r, g, b) return round(r * 0.2126 + g * 0.7152 + b * 0.0722) end
local function to_luma_rec240(r, g, b) return round(r * 0.212 + g * 0.701 + b * 0.0087) end

local I8 = {
	luma_func = to_luma_rec709,
	current_luma = 1,
	lumas = {
		to_luma_rec709,
		to_luma_rec601,
		to_luma_rec240
	}
}
local I8Object = {}

function I8:SwitchLumaType(num)
	self.luma_func = assert(self.lumas[num], 'invalid luma function: ' .. num)
	self.current_luma = num
end

function I8:GetLumaType()
	return self.current_luma
end

function I8:GetLumaFunction()
	return self.luma_func
end

function I8:SetLumaFunction(func)
	assert(isfunction(func))
	self.luma_func = func
end

function I8Object.CountBytes(w, h)
	return w * h
end

local function twos(_)
	if _ < 0 then return 0x100000000 + _ end
	return _
end

function I8Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local filler = string.char(to_luma_rec601(floor(fill.r), floor(fill.g), floor(fill.b)))

	if not bytes then
		return DLib.I8(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.I8(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function I8:SetBlock(x, y, buffer, plain_format)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width
	local luma_func = self.luma_func

	if plain_format then
		for line = 0, 3 do
			bytes:Seek(edge + x * 4 + y * width * 4 + line * width)

			local obj_1 = buffer[line * 4 + 1]
			local obj_2 = buffer[line * 4 + 2]
			local obj_3 = buffer[line * 4 + 3]
			local obj_4 = buffer[line * 4 + 4]

			bytes:WriteUInt32LE(twos(bor(
					   luma_func(obj_1[1], obj_1[2], obj_1[3]),
				lshift(luma_func(obj_2[1], obj_2[2], obj_2[3]), 8),
				lshift(luma_func(obj_3[1], obj_3[2], obj_3[3]), 16),
				lshift(luma_func(obj_4[1], obj_4[2], obj_4[3]), 24)
			)))
		end
	else
		for line = 0, 3 do
			bytes:Seek(edge + x * 4 + y * width * 4 + line * width)

			local obj_1 = buffer[line * 4 + 1]
			local obj_2 = buffer[line * 4 + 2]
			local obj_3 = buffer[line * 4 + 3]
			local obj_4 = buffer[line * 4 + 4]

			bytes:WriteUInt32LE(twos(bor(
					   luma_func(obj_1.r, obj_1.g, obj_1.b),
				lshift(luma_func(obj_2.r, obj_2.g, obj_2.b), 8),
				lshift(luma_func(obj_3.r, obj_3.g, obj_3.b), 16),
				lshift(luma_func(obj_4.r, obj_4.g, obj_4.b), 24)
			)))
		end
	end
end

function I8:GetBlock(x, y, export)
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
			bytes:Seek(edge + x * 4 + y * width * 4 + line * width)
			local color = bytes:ReadUInt32LE()
			local obj = export[line * 4 + 1]
			local _color = band(color, 0xFF)
			obj[1], obj[2], obj[3] = _color, _color, _color

			_color = rshift(band(color, 0xFF00), 8)
			obj = export[line * 4 + 2]
			obj[1], obj[2], obj[3] = _color, _color, _color

			_color = rshift(band(color, 0xFF0000), 16)
			obj = export[line * 4 + 3]
			obj[1], obj[2], obj[3] = _color, _color, _color

			_color = rshift(color, 24)
			obj = export[line * 4 + 4]
			obj[1], obj[2], obj[3] = _color, _color, _color
		end

		return export
	end

	local result = {}
	local index = 1

	for line = 0, 3 do
		bytes:Seek(edge + x * 4 + y * width * 4 + line * width)

		local color = bytes:ReadUInt32LE()
		local _color = band(color, 0xFF)
		result[line * 4 + 1] = Color(_color, _color, _color)

		_color = rshift(band(color, 0xFF00), 8)
		result[line * 4 + 2] = Color(_color, _color, _color)

		_color = rshift(band(color, 0xFF0000), 16)
		result[line * 4 + 3] = Color(_color, _color, _color)

		_color = rshift(color, 24)
		result[line * 4 + 4] = Color(_color, _color, _color)
	end

	self.cache[pixel] = result

	return result
end

function I8:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes
	local flop = self.flop

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local read = bytes:ReadUByte()
			result[index] = Color(read, read, read)
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.I8 = DLib.CreateMoonClassBare('I8', I8, I8Object, DLib.AbstractTexture)

local IA88 = {
	luma_func = to_luma_rec709,
	current_luma = 1,
	lumas = {
		to_luma_rec709,
		to_luma_rec601,
		to_luma_rec240
	}
}
local IA88Object = {}

function IA88:SwitchLumaType(num)
	self.luma_func = assert(self.lumas[num], 'invalid luma function: ' .. num)
	self.current_luma = num
end

function IA88:GetLumaType()
	return self.current_luma
end

function IA88:GetLumaFunction()
	return self.luma_func
end

function IA88:SetLumaFunction(func)
	assert(isfunction(func))
	self.luma_func = func
end

function IA88Object.CountBytes(w, h)
	return w * h * 2
end

function IA88Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local filler = string.char(to_luma_rec601(floor(fill.r), floor(fill.g), floor(fill.b)), floor(fill.a))

	if not bytes then
		return DLib.I8(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.I8(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function IA88:SetBlock(x, y, buffer, plain_format, only_update_alpha)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width
	local luma_func = self.luma_func

	if plain_format then
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

				local a = bytes:ReadUInt16LE()
				local b = bytes:ReadUInt16LE()
				local c = bytes:ReadUInt16LE()
				local d = bytes:ReadUInt16LE()

				bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

				local obj = buffer[line * 4 + 1]
				bytes:WriteUInt16LE(bor(band(a, 0xFF), lshift(obj[4], 8)))

				obj = buffer[line * 4 + 2]
				bytes:WriteUInt16LE(bor(band(b, 0xFF), lshift(obj[4], 8)))

				obj = buffer[line * 4 + 3]
				bytes:WriteUInt16LE(bor(band(c, 0xFF), lshift(obj[4], 8)))

				obj = buffer[line * 4 + 4]
				bytes:WriteUInt16LE(bor(band(d, 0xFF), lshift(obj[4], 8)))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

				local obj = buffer[line * 4 + 1]
				bytes:WriteUInt16LE(bor(luma_func(obj[1], obj[2], obj[3]), lshift(obj[4], 8)))

				obj = buffer[line * 4 + 2]
				bytes:WriteUInt16LE(bor(luma_func(obj[1], obj[2], obj[3]), lshift(obj[4], 8)))

				obj = buffer[line * 4 + 3]
				bytes:WriteUInt16LE(bor(luma_func(obj[1], obj[2], obj[3]), lshift(obj[4], 8)))

				obj = buffer[line * 4 + 4]
				bytes:WriteUInt16LE(bor(luma_func(obj[1], obj[2], obj[3]), lshift(obj[4], 8)))
			end
		end
	else
		if only_update_alpha then
			for line = 0, 3 do
				bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

				local a = bytes:ReadUInt16LE()
				local b = bytes:ReadUInt16LE()
				local c = bytes:ReadUInt16LE()
				local d = bytes:ReadUInt16LE()

				bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

				local obj = buffer[line * 4 + 1]
				bytes:WriteUInt16LE(bor(band(a, 0xFF), lshift(obj.a, 8)))

				obj = buffer[line * 4 + 2]
				bytes:WriteUInt16LE(bor(band(a, 0xFF), lshift(obj.a, 8)))

				obj = buffer[line * 4 + 3]
				bytes:WriteUInt16LE(bor(band(a, 0xFF), lshift(obj.a, 8)))

				obj = buffer[line * 4 + 4]
				bytes:WriteUInt16LE(bor(band(a, 0xFF), lshift(obj.a, 8)))
			end
		else
			for line = 0, 3 do
				bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

				local obj = buffer[line * 4 + 1]
				bytes:WriteUInt16LE(bor(luma_func(obj.r, obj.g, obj.b), lshift(obj.a, 8)))

				obj = buffer[line * 4 + 2]
				bytes:WriteUInt16LE(bor(luma_func(obj.r, obj.g, obj.b), lshift(obj.a, 8)))

				obj = buffer[line * 4 + 3]
				bytes:WriteUInt16LE(bor(luma_func(obj.r, obj.g, obj.b), lshift(obj.a, 8)))

				obj = buffer[line * 4 + 4]
				bytes:WriteUInt16LE(bor(luma_func(obj.r, obj.g, obj.b), lshift(obj.a, 8)))
			end
		end
	end
end

function IA88:GetBlock(x, y, export)
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
	local flop = self.flop

	if export then
		for line = 0, 3 do
			bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)
			local color = bytes:ReadUInt16LE()
			local obj = export[line * 4 + 1]
			local _color = band(color, 0xFF)
			obj[1], obj[2], obj[3] = _color, _color, _color, rshift(color, 8)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 2]
			_color = band(color, 0xFF)
			obj[1], obj[2], obj[3] = _color, _color, _color, rshift(color, 8)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 3]
			_color = band(color, 0xFF)
			obj[1], obj[2], obj[3] = _color, _color, _color, rshift(color, 8)

			color = bytes:ReadUInt16LE()
			obj = export[line * 4 + 4]
			_color = band(color, 0xFF)
			obj[1], obj[2], obj[3] = _color, _color, _color, rshift(color, 8)
		end

		return export
	end

	local result = {}
	local index = 1

	for line = 0, 3 do
		bytes:Seek(edge + x * 8 + y * width * 8 + line * width * 2)

		local color = bytes:ReadUInt16LE()
		local _color = band(color, 0xFF)
		result[line * 4 + 1] = Color(_color, _color, _color, rshift(color, 8))

		color = bytes:ReadUInt16LE()
		_color = band(color, 0xFF)
		result[line * 4 + 2] = Color(_color, _color, _color, rshift(color, 8))

		color = bytes:ReadUInt16LE()
		_color = band(color, 0xFF)
		result[line * 4 + 3] = Color(_color, _color, _color, rshift(color, 8))

		color = bytes:ReadUInt16LE()
		_color = band(color, 0xFF)
		result[line * 4 + 4] = Color(_color, _color, _color, rshift(color, 8))
	end

	self.cache[pixel] = result

	return result
end

function IA88:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes
	local flop = self.flop

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local color = bytes:ReadUInt16LE()
			_color = band(color, 0xFF)
			result[index] = Color(_color, _color, _color, rshift(color, 8))
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.IA88 = DLib.CreateMoonClassBare('IA88', IA88, IA88Object, DLib.AbstractTexture)

local A8 = {}
local A8Object = {}

function A8Object.CountBytes(w, h)
	return w * h
end

function A8Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	--assert(width % 4 == 0, 'width % 4 ~= 0')
	--assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white
	local filler = string.char(floor(fill.a))

	if not bytes then
		return DLib.A8(DLib.BytesBuffer(string.rep(filler, width * height)), width, height)
	end

	local pointer = bytes:Tell()
	bytes:WriteBinary(string.rep(filler, width * height))
	local pointer2 = bytes:Tell()
	bytes:Seek(pointer)
	local texture = DLib.A8(bytes, width, height)
	bytes:Seek(pointer2)

	return texture
end

function A8:SetBlock(x, y, buffer, plain_format)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local bytes = self.bytes
	local edge = self.edge
	local width = self.width
	local luma_func = self.luma_func

	if plain_format then
		for line = 0, 3 do
			bytes:Seek(edge + x * 4 + y * width * 4 + line * width)

			local obj_1 = buffer[line * 4 + 1]
			local obj_2 = buffer[line * 4 + 2]
			local obj_3 = buffer[line * 4 + 3]
			local obj_4 = buffer[line * 4 + 4]

			bytes:WriteUInt32LE(twos(bor(
					   obj_1[4],
				lshift(obj_2[4], 8),
				lshift(obj_3[4], 16),
				lshift(obj_4[4], 24)
			)))
		end
	else
		for line = 0, 3 do
			bytes:Seek(edge + x * 4 + y * width * 4 + line * width)

			local obj_1 = buffer[line * 4 + 1]
			local obj_2 = buffer[line * 4 + 2]
			local obj_3 = buffer[line * 4 + 3]
			local obj_4 = buffer[line * 4 + 4]

			bytes:WriteUInt32LE(twos(bor(
					   obj_1.a,
				lshift(obj_2.a, 8),
				lshift(obj_3.a, 16),
				lshift(obj_4.a, 24)
			)))
		end
	end
end

function A8:GetBlock(x, y, export)
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
			bytes:Seek(edge + x * 4 + y * width * 4 + line * width)
			local color = bytes:ReadUInt32LE()
			export[line * 4 + 1][4] = band(color, 0xFF)
			export[line * 4 + 2][4] = rshift(band(color, 0xFF00), 8)
			export[line * 4 + 3][4] = rshift(band(color, 0xFF0000), 16)
			export[line * 4 + 4][4] = rshift(color, 24)
		end

		return export
	end

	local result = {}
	local index = 1

	for line = 0, 3 do
		bytes:Seek(edge + x * 4 + y * width * 4 + line * width)

		local color = bytes:ReadUInt32LE()
		local _color = band(color, 0xFF)
		result[line * 4 + 1] = Color(255, 255, 255, band(color, 0xFF))
		result[line * 4 + 2] = Color(255, 255, 255, rshift(band(color, 0xFF00), 8))
		result[line * 4 + 3] = Color(255, 255, 255, rshift(band(color, 0xFF0000), 16))
		result[line * 4 + 4] = Color(255, 255, 255, rshift(color, 24))
	end

	self.cache[pixel] = result

	return result
end

function A8:ReadEntireImage(nocache)
	if self._cache then return self._cache end

	local result = {}
	local index = 1
	local bytes = self.bytes
	local flop = self.flop

	bytes:Seek(self.edge)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			result[index] = Color(255, 255, 255, bytes:ReadUByte())
			index = index + 1
		end
	end

	if not nocache then
		self._cache = result
	end

	return result
end

DLib.A8 = DLib.CreateMoonClassBare('A8', A8, A8Object, DLib.AbstractTexture)
