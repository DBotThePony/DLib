
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
