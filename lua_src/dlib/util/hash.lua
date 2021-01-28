
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
	local function rotate(x, n)
		return (bor(lshift(x, n), rshift(x, 32 - n)))
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
			a = (overflow(rotate(((a) + overflow((bor(band(b, c), band(d, bnot(b))))) + (x[ 0]) + 0xd76aa478), S11)) + (b)) % 4294967296 -- /* 1 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, b), band(c, bnot(a))))) + (x[ 1]) + 0xe8c7b756), S12)) + (a)) % 4294967296 -- /* 2 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, a), band(b, bnot(d))))) + (x[ 2]) + 0x242070db), S13)) + (d)) % 4294967296 -- /* 3 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, d), band(a, bnot(c))))) + (x[ 3]) + 0xc1bdceee), S14)) + (c)) % 4294967296 -- /* 4 */
			a = (overflow(rotate(((a) + overflow((bor(band(b, c), band(d, bnot(b))))) + (x[ 4]) + 0xf57c0faf), S11)) + (b)) % 4294967296 -- /* 5 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, b), band(c, bnot(a))))) + (x[ 5]) + 0x4787c62a), S12)) + (a)) % 4294967296 -- /* 6 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, a), band(b, bnot(d))))) + (x[ 6]) + 0xa8304613), S13)) + (d)) % 4294967296 -- /* 7 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, d), band(a, bnot(c))))) + (x[ 7]) + 0xfd469501), S14)) + (c)) % 4294967296 -- /* 8 */
			a = (overflow(rotate(((a) + overflow((bor(band(b, c), band(d, bnot(b))))) + (x[ 8]) + 0x698098d8), S11)) + (b)) % 4294967296 -- /* 9 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, b), band(c, bnot(a))))) + (x[ 9]) + 0x8b44f7af), S12)) + (a)) % 4294967296 -- /* 10 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, a), band(b, bnot(d))))) + (x[10]) + 0xffff5bb1), S13)) + (d)) % 4294967296 -- /* 11 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, d), band(a, bnot(c))))) + (x[11]) + 0x895cd7be), S14)) + (c)) % 4294967296 -- /* 12 */
			a = (overflow(rotate(((a) + overflow((bor(band(b, c), band(d, bnot(b))))) + (x[12]) + 0x6b901122), S11)) + (b)) % 4294967296 -- /* 13 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, b), band(c, bnot(a))))) + (x[13]) + 0xfd987193), S12)) + (a)) % 4294967296 -- /* 14 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, a), band(b, bnot(d))))) + (x[14]) + 0xa679438e), S13)) + (d)) % 4294967296 -- /* 15 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, d), band(a, bnot(c))))) + (x[15]) + 0x49b40821), S14)) + (c)) % 4294967296 -- /* 16 */

			-- /* Round 2 */
			a = (overflow(rotate(((a) + overflow((bor(band(b, d), band(c, bnot(d))))) + (x[ 1]) + 0xf61e2562), S21)) + (b)) % 4294967296 -- /* 17 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, c), band(b, bnot(c))))) + (x[ 6]) + 0xc040b340), S22)) + (a)) % 4294967296 -- /* 18 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, b), band(a, bnot(b))))) + (x[11]) + 0x265e5a51), S23)) + (d)) % 4294967296 -- /* 19 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, a), band(d, bnot(a))))) + (x[ 0]) + 0xe9b6c7aa), S24)) + (c)) % 4294967296 -- /* 20 */
			a = (overflow(rotate(((a) + overflow((bor(band(b, d), band(c, bnot(d))))) + (x[ 5]) + 0xd62f105d), S21)) + (b)) % 4294967296 -- /* 21 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, c), band(b, bnot(c))))) + (x[10]) +  0x2441453), S22)) + (a)) % 4294967296 -- /* 22 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, b), band(a, bnot(b))))) + (x[15]) + 0xd8a1e681), S23)) + (d)) % 4294967296 -- /* 23 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, a), band(d, bnot(a))))) + (x[ 4]) + 0xe7d3fbc8), S24)) + (c)) % 4294967296 -- /* 24 */
			a = (overflow(rotate(((a) + overflow((bor(band(b, d), band(c, bnot(d))))) + (x[ 9]) + 0x21e1cde6), S21)) + (b)) % 4294967296 -- /* 25 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, c), band(b, bnot(c))))) + (x[14]) + 0xc33707d6), S22)) + (a)) % 4294967296 -- /* 26 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, b), band(a, bnot(b))))) + (x[ 3]) + 0xf4d50d87), S23)) + (d)) % 4294967296 -- /* 27 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, a), band(d, bnot(a))))) + (x[ 8]) + 0x455a14ed), S24)) + (c)) % 4294967296 -- /* 28 */
			a = (overflow(rotate(((a) + overflow((bor(band(b, d), band(c, bnot(d))))) + (x[13]) + 0xa9e3e905), S21)) + (b)) % 4294967296 -- /* 29 */
			d = (overflow(rotate(((d) + overflow((bor(band(a, c), band(b, bnot(c))))) + (x[ 2]) + 0xfcefa3f8), S22)) + (a)) % 4294967296 -- /* 30 */
			c = (overflow(rotate(((c) + overflow((bor(band(d, b), band(a, bnot(b))))) + (x[ 7]) + 0x676f02d9), S23)) + (d)) % 4294967296 -- /* 31 */
			b = (overflow(rotate(((b) + overflow((bor(band(c, a), band(d, bnot(a))))) + (x[12]) + 0x8d2a4c8a), S24)) + (c)) % 4294967296 -- /* 32 */

			-- /* Round 3 */
			a = (overflow(rotate(((a) + overflow(bxor(b, c, d)) + (x[ 5]) + 0xfffa3942), S31)) + (b)) % 4294967296 -- /* 33 */
			d = (overflow(rotate(((d) + overflow(bxor(a, b, c)) + (x[ 8]) + 0x8771f681), S32)) + (a)) % 4294967296 -- /* 34 */
			c = (overflow(rotate(((c) + overflow(bxor(d, a, b)) + (x[11]) + 0x6d9d6122), S33)) + (d)) % 4294967296 -- /* 35 */
			b = (overflow(rotate(((b) + overflow(bxor(c, d, a)) + (x[14]) + 0xfde5380c), S34)) + (c)) % 4294967296 -- /* 36 */
			a = (overflow(rotate(((a) + overflow(bxor(b, c, d)) + (x[ 1]) + 0xa4beea44), S31)) + (b)) % 4294967296 -- /* 37 */
			d = (overflow(rotate(((d) + overflow(bxor(a, b, c)) + (x[ 4]) + 0x4bdecfa9), S32)) + (a)) % 4294967296 -- /* 38 */
			c = (overflow(rotate(((c) + overflow(bxor(d, a, b)) + (x[ 7]) + 0xf6bb4b60), S33)) + (d)) % 4294967296 -- /* 39 */
			b = (overflow(rotate(((b) + overflow(bxor(c, d, a)) + (x[10]) + 0xbebfbc70), S34)) + (c)) % 4294967296 -- /* 40 */
			a = (overflow(rotate(((a) + overflow(bxor(b, c, d)) + (x[13]) + 0x289b7ec6), S31)) + (b)) % 4294967296 -- /* 41 */
			d = (overflow(rotate(((d) + overflow(bxor(a, b, c)) + (x[ 0]) + 0xeaa127fa), S32)) + (a)) % 4294967296 -- /* 42 */
			c = (overflow(rotate(((c) + overflow(bxor(d, a, b)) + (x[ 3]) + 0xd4ef3085), S33)) + (d)) % 4294967296 -- /* 43 */
			b = (overflow(rotate(((b) + overflow(bxor(c, d, a)) + (x[ 6]) +  0x4881d05), S34)) + (c)) % 4294967296 -- /* 44 */
			a = (overflow(rotate(((a) + overflow(bxor(b, c, d)) + (x[ 9]) + 0xd9d4d039), S31)) + (b)) % 4294967296 -- /* 45 */
			d = (overflow(rotate(((d) + overflow(bxor(a, b, c)) + (x[12]) + 0xe6db99e5), S32)) + (a)) % 4294967296 -- /* 46 */
			c = (overflow(rotate(((c) + overflow(bxor(d, a, b)) + (x[15]) + 0x1fa27cf8), S33)) + (d)) % 4294967296 -- /* 47 */
			b = (overflow(rotate(((b) + overflow(bxor(c, d, a)) + (x[ 2]) + 0xc4ac5665), S34)) + (c)) % 4294967296 -- /* 48 */

			-- /* Round 4 */
			a = (overflow(rotate(((a) + overflow((bxor(c, bor(b, bnot(d))))) + (x[ 0]) + 0xf4292244), S41)) + (b)) % 4294967296 -- /* 49 */
			d = (overflow(rotate(((d) + overflow((bxor(b, bor(a, bnot(c))))) + (x[ 7]) + 0x432aff97), S42)) + (a)) % 4294967296 -- /* 50 */
			c = (overflow(rotate(((c) + overflow((bxor(a, bor(d, bnot(b))))) + (x[14]) + 0xab9423a7), S43)) + (d)) % 4294967296 -- /* 51 */
			b = (overflow(rotate(((b) + overflow((bxor(d, bor(c, bnot(a))))) + (x[ 5]) + 0xfc93a039), S44)) + (c)) % 4294967296 -- /* 52 */
			a = (overflow(rotate(((a) + overflow((bxor(c, bor(b, bnot(d))))) + (x[12]) + 0x655b59c3), S41)) + (b)) % 4294967296 -- /* 53 */
			d = (overflow(rotate(((d) + overflow((bxor(b, bor(a, bnot(c))))) + (x[ 3]) + 0x8f0ccc92), S42)) + (a)) % 4294967296 -- /* 54 */
			c = (overflow(rotate(((c) + overflow((bxor(a, bor(d, bnot(b))))) + (x[10]) + 0xffeff47d), S43)) + (d)) % 4294967296 -- /* 55 */
			b = (overflow(rotate(((b) + overflow((bxor(d, bor(c, bnot(a))))) + (x[ 1]) + 0x85845dd1), S44)) + (c)) % 4294967296 -- /* 56 */
			a = (overflow(rotate(((a) + overflow((bxor(c, bor(b, bnot(d))))) + (x[ 8]) + 0x6fa87e4f), S41)) + (b)) % 4294967296 -- /* 57 */
			d = (overflow(rotate(((d) + overflow((bxor(b, bor(a, bnot(c))))) + (x[15]) + 0xfe2ce6e0), S42)) + (a)) % 4294967296 -- /* 58 */
			c = (overflow(rotate(((c) + overflow((bxor(a, bor(d, bnot(b))))) + (x[ 6]) + 0xa3014314), S43)) + (d)) % 4294967296 -- /* 59 */
			b = (overflow(rotate(((b) + overflow((bxor(d, bor(c, bnot(a))))) + (x[13]) + 0x4e0811a1), S44)) + (c)) % 4294967296 -- /* 60 */
			a = (overflow(rotate(((a) + overflow((bxor(c, bor(b, bnot(d))))) + (x[ 4]) + 0xf7537e82), S41)) + (b)) % 4294967296 -- /* 61 */
			d = (overflow(rotate(((d) + overflow((bxor(b, bor(a, bnot(c))))) + (x[11]) + 0xbd3af235), S42)) + (a)) % 4294967296 -- /* 62 */
			c = (overflow(rotate(((c) + overflow((bxor(a, bor(d, bnot(b))))) + (x[ 2]) + 0x2ad7d2bb), S43)) + (d)) % 4294967296 -- /* 63 */
			b = (overflow(rotate(((b) + overflow((bxor(d, bor(c, bnot(a))))) + (x[ 9]) + 0xeb86d391), S44)) + (c)) % 4294967296 -- /* 64 */

			self.A = (self.A + overflow(a)) % 4294967296
			self.B = (self.B + overflow(b)) % 4294967296
			self.C = (self.C + overflow(c)) % 4294967296
			self.D = (self.D + overflow(d)) % 4294967296
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
