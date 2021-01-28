
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

local bor = bit.bor
local band = bit.band
local bxor = bit.bxor
local rshift = bit.rshift
local bnot = bit.bnot
local lshift = bit.lshift
local string = string
local string_byte = string.byte
local string_sub = string.sub
local math_floor = math.floor

local function overflow(a)
	if a < 0 then
		return a + 4294967296
	end

	return a % 4294967296
end

local meta = {}

function meta:ctor(stringIn)
	self.A = 0x67452301
	self.B = 0xEFCDAB89
	self.C = 0x98BADCFE
	self.D = 0x10325476

	self.digested = false

	self.current_block = ''
	self.blocks = 0
	self.length = 0
end

do
	local function F(x, y, z)
		return (bor(band(x, y), band(z, bnot(x))))
	end

	local function G(x, y, z)
		return (bor(band(x, z), band(y, bnot(z))))
	end

	local function H(x, y, z)
		return (bxor(x, y, z))
	end

	local function I(x, y, z)
		return (bxor(y, bor(x, bnot(z))))
	end

	local function rotate(x, n)
		return (bor(lshift(x, n), rshift(x, 32 - n)))
	end

	local function FF(a, b, c, d, x, s, ac)
		a = ((a) + overflow(F(b, c, d)) + (x) + ac) % 4294967296
		return (overflow(rotate(a, s)) + (b)) % 4294967296
	end

	local function GG(a, b, c, d, x, s, ac)
		a = ((a) + overflow(G(b, c, d)) + (x) + ac) % 4294967296
		return (overflow(rotate(a, s)) + (b)) % 4294967296
	end

	local function HH(a, b, c, d, x, s, ac)
		a = ((a) + overflow(H(b, c, d)) + (x) + ac) % 4294967296
		return (overflow(rotate(a, s)) + (b)) % 4294967296
	end

	local function II(a, b, c, d, x, s, ac)
		a = ((a) + overflow(I(b, c, d)) + (x) + ac) % 4294967296
		return (overflow(rotate(a, s)) + (b)) % 4294967296
	end

	local x = {}
	local S11 = 7
	local S12 = 12
	local S13 = 17
	local S14 = 22
	local S21 = 5
	local S22 = 9
	local S23 = 14
	local S24 = 20
	local S31 = 4
	local S32 = 11
	local S33 = 16
	local S34 = 23
	local S41 = 6
	local S42 = 10
	local S43 = 15
	local S44 = 21

	function meta:_Inner(cc)
		-- 512 bit block
		for i = 1, math_floor(#cc / 64) do
			self.blocks = self.blocks + 1

			-- separated as ubytes (8 bit)
			local bytes = {string_byte(cc, (i - 1) * 64 + 1, i * 64)}

			-- copy as 4 byte uint blocks
			for i = 0, 15 do
				x[i] = overflow(bor(
					bytes[i * 4 + 1],
					lshift(bytes[i * 4 + 2], 8),
					lshift(bytes[i * 4 + 3], 16),
					lshift(bytes[i * 4 + 4], 24)
				))
			end

			local a, b, c, d = self.A, self.B, self.C, self.D

			-- /* Round 1 */
			a = FF (a, b, c, d, x[ 0], S11, 0xd76aa478); -- /* 1 */
			--print('f', a, b, c, d, x[ 0], S11, 0xd76aa478)
			d = FF (d, a, b, c, x[ 1], S12, 0xe8c7b756); -- /* 2 */
			--print('f2', d, a, b, c, x[ 1], S12, 0xe8c7b756)
			c = FF (c, d, a, b, x[ 2], S13, 0x242070db); -- /* 3 */
			b = FF (b, c, d, a, x[ 3], S14, 0xc1bdceee); -- /* 4 */
			a = FF (a, b, c, d, x[ 4], S11, 0xf57c0faf); -- /* 5 */
			d = FF (d, a, b, c, x[ 5], S12, 0x4787c62a); -- /* 6 */
			c = FF (c, d, a, b, x[ 6], S13, 0xa8304613); -- /* 7 */
			b = FF (b, c, d, a, x[ 7], S14, 0xfd469501); -- /* 8 */
			a = FF (a, b, c, d, x[ 8], S11, 0x698098d8); -- /* 9 */
			d = FF (d, a, b, c, x[ 9], S12, 0x8b44f7af); -- /* 10 */
			c = FF (c, d, a, b, x[10], S13, 0xffff5bb1); -- /* 11 */
			b = FF (b, c, d, a, x[11], S14, 0x895cd7be); -- /* 12 */
			a = FF (a, b, c, d, x[12], S11, 0x6b901122); -- /* 13 */
			--print('pre', a, b, c, d)
			d = FF (d, a, b, c, x[13], S12, 0xfd987193); -- /* 14 */
			c = FF (c, d, a, b, x[14], S13, 0xa679438e); -- /* 15 */
			b = FF (b, c, d, a, x[15], S14, 0x49b40821); -- /* 16 */
			--print(1, a, b, c, d)

			-- /* Round 2 */
			a = GG (a, b, c, d, x[ 1], S21, 0xf61e2562); -- /* 17 */
			d = GG (d, a, b, c, x[ 6], S22, 0xc040b340); -- /* 18 */
			c = GG (c, d, a, b, x[11], S23, 0x265e5a51); -- /* 19 */
			b = GG (b, c, d, a, x[ 0], S24, 0xe9b6c7aa); -- /* 20 */
			a = GG (a, b, c, d, x[ 5], S21, 0xd62f105d); -- /* 21 */
			d = GG (d, a, b, c, x[10], S22,  0x2441453); -- /* 22 */
			c = GG (c, d, a, b, x[15], S23, 0xd8a1e681); -- /* 23 */
			b = GG (b, c, d, a, x[ 4], S24, 0xe7d3fbc8); -- /* 24 */
			a = GG (a, b, c, d, x[ 9], S21, 0x21e1cde6); -- /* 25 */
			d = GG (d, a, b, c, x[14], S22, 0xc33707d6); -- /* 26 */
			c = GG (c, d, a, b, x[ 3], S23, 0xf4d50d87); -- /* 27 */
			b = GG (b, c, d, a, x[ 8], S24, 0x455a14ed); -- /* 28 */
			a = GG (a, b, c, d, x[13], S21, 0xa9e3e905); -- /* 29 */
			d = GG (d, a, b, c, x[ 2], S22, 0xfcefa3f8); -- /* 30 */
			c = GG (c, d, a, b, x[ 7], S23, 0x676f02d9); -- /* 31 */
			b = GG (b, c, d, a, x[12], S24, 0x8d2a4c8a); -- /* 32 */
			--print(2, a, b, c, d)

			-- /* Round 3 */
			a = HH (a, b, c, d, x[ 5], S31, 0xfffa3942); -- /* 33 */
			d = HH (d, a, b, c, x[ 8], S32, 0x8771f681); -- /* 34 */
			c = HH (c, d, a, b, x[11], S33, 0x6d9d6122); -- /* 35 */
			b = HH (b, c, d, a, x[14], S34, 0xfde5380c); -- /* 36 */
			a = HH (a, b, c, d, x[ 1], S31, 0xa4beea44); -- /* 37 */
			d = HH (d, a, b, c, x[ 4], S32, 0x4bdecfa9); -- /* 38 */
			c = HH (c, d, a, b, x[ 7], S33, 0xf6bb4b60); -- /* 39 */
			b = HH (b, c, d, a, x[10], S34, 0xbebfbc70); -- /* 40 */
			a = HH (a, b, c, d, x[13], S31, 0x289b7ec6); -- /* 41 */
			d = HH (d, a, b, c, x[ 0], S32, 0xeaa127fa); -- /* 42 */
			c = HH (c, d, a, b, x[ 3], S33, 0xd4ef3085); -- /* 43 */
			b = HH (b, c, d, a, x[ 6], S34,  0x4881d05); -- /* 44 */
			a = HH (a, b, c, d, x[ 9], S31, 0xd9d4d039); -- /* 45 */
			d = HH (d, a, b, c, x[12], S32, 0xe6db99e5); -- /* 46 */
			c = HH (c, d, a, b, x[15], S33, 0x1fa27cf8); -- /* 47 */
			b = HH (b, c, d, a, x[ 2], S34, 0xc4ac5665); -- /* 48 */
			-- print(3, a, b, c, d)

			-- /* Round 4 */
			a = II (a, b, c, d, x[ 0], S41, 0xf4292244); -- /* 49 */
			d = II (d, a, b, c, x[ 7], S42, 0x432aff97); -- /* 50 */
			c = II (c, d, a, b, x[14], S43, 0xab9423a7); -- /* 51 */
			b = II (b, c, d, a, x[ 5], S44, 0xfc93a039); -- /* 52 */
			a = II (a, b, c, d, x[12], S41, 0x655b59c3); -- /* 53 */
			d = II (d, a, b, c, x[ 3], S42, 0x8f0ccc92); -- /* 54 */
			c = II (c, d, a, b, x[10], S43, 0xffeff47d); -- /* 55 */
			b = II (b, c, d, a, x[ 1], S44, 0x85845dd1); -- /* 56 */
			a = II (a, b, c, d, x[ 8], S41, 0x6fa87e4f); -- /* 57 */
			d = II (d, a, b, c, x[15], S42, 0xfe2ce6e0); -- /* 58 */
			c = II (c, d, a, b, x[ 6], S43, 0xa3014314); -- /* 59 */
			b = II (b, c, d, a, x[13], S44, 0x4e0811a1); -- /* 60 */
			a = II (a, b, c, d, x[ 4], S41, 0xf7537e82); -- /* 61 */
			d = II (d, a, b, c, x[11], S42, 0xbd3af235); -- /* 62 */
			c = II (c, d, a, b, x[ 2], S43, 0x2ad7d2bb); -- /* 63 */
			b = II (b, c, d, a, x[ 9], S44, 0xeb86d391); -- /* 64 */
			-- print(4, a, b, c, d)

			self.A = (self.A + overflow(a)) % 4294967296
			self.B = (self.B + overflow(b)) % 4294967296
			self.C = (self.C + overflow(c)) % 4294967296
			self.D = (self.D + overflow(d)) % 4294967296

			-- print('A', self.A, self.B, self.C, self.D)
		end
	end
end

function meta:Update(data)
	if self.digested then error('Message is already digested!') end

	if data == '' then return self end
	local cc = self.current_block .. data
	self.length = self.length + #data

	if #cc < 64 then
		self.current_block = cc
		return self
	end

	self.current_block = string_sub(cc, #cc - #cc % 64 + 1, #cc)
	self:_Inner(cc)

	return self
end

function meta:_Digest()
	self.digested = true

	local mod = self.length % 64

	if mod < 56 then
		-- append 128, then 0
		self.current_block = self.current_block .. '\x80' .. string.rep('\x00', 55 - mod)
	elseif mod > 56 then
		-- too long
		self.current_block = self.current_block ..
			'\x80' ..
			string.rep('\x00', 119 - mod)
	end

	local realLength = self.length * 8
	local modLen = realLength % 4294967296
	local div = (realLength - modLen) / 4294967296

	self:_Inner(self.current_block .. string.char(
		band(modLen, 0xFF),
		band(rshift(modLen, 8), 0xFF),
		band(rshift(modLen, 16), 0xFF),
		band(rshift(modLen, 24), 0xFF),

		band(div, 0xFF),
		band(rshift(div, 8), 0xFF),
		band(rshift(div, 16), 0xFF),
		band(rshift(div, 24), 0xFF)
	))

	self.digest_hex = string.format('%08x%08x%08x%08x', overflow(bit.bswap(self.A)), overflow(bit.bswap(self.B)), overflow(bit.bswap(self.C)), overflow(bit.bswap(self.D)))
end

function meta:Digest()
	if not self.digest_hex then
		self:_Digest()
	end

	return self.digest_hex
end

DLib.Util.MD5 = DLib.CreateMoonClassBare('MD5', meta, {})

local jit_status = jit.status
local jit_off = jit.off
local jit_on = jit.on

function DLib.Util.QuickMD5(str)
	local j = jit_status()

	jit_off()
	local hash =  DLib.Util.MD5():Update(str):Digest()
	if j then jit_on() end

	return hash
end
