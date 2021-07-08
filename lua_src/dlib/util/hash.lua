
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

local jit_status = jit.status
local jit_off = jit.off
local jit_on = jit.on

local bor = bit.bor
local tobit = bit.tobit
local band = bit.band
local bxor = bit.bxor
local rshift = bit.rshift
local bnot = bit.bnot
local lshift = bit.lshift
local string = string
local string_byte = string.byte
local string_sub = string.sub
local math_floor = math.floor

local assert = assert
local isnumber = isnumber

local function overflow(a)
	if a < 0 then
		return a + 4294967296
	end

	return a % 4294967296
end

local meta = {}

--[[
	@doc
	@fname DLib.Util.MD5
	@args number A = 0x67452301, number B = 0xEFCDAB89, number C = 0x98BADCFE, number D = 0x10325476

	@desc
	Returns MD5 object, which has `:Update(data)` and `:Digest()` methods
	Arguments to this function allow to re-define standard initialization vector
	Don't touch them if you want MD5 hash to match hashes created by other programs
	MD5 is not secure and should not be utilized for such
	This is not actually a function (but still can be called), but a Moonscript compatible class table
	@enddesc

	@returns
	table: class representing MD5 hash
]]

function meta:ctor(a, b, c, d)
	if a == nil then a = 0x67452301 end
	if b == nil then b = 0xEFCDAB89 end
	if c == nil then c = 0x98BADCFE end
	if d == nil then d = 0x10325476 end

	assert(isnumber(a), 'A is not a number')
	assert(isnumber(b), 'B is not a number')
	assert(isnumber(c), 'C is not a number')
	assert(isnumber(d), 'D is not a number')

	self.A = a
	self.B = b
	self.C = c
	self.D = d

	self.digested = false

	self.current_block = ''
	self.blocks = 0
	self.length = 0
end

local ROTL = bit.rol
local ROTR = bit.ror

do
	local W = {}

	local S = {
		7, 12, 17, 22,
		7, 12, 17, 22,
		7, 12, 17, 22,
		7, 12, 17, 22,

		5, 9,  14, 20,
		5, 9,  14, 20,
		5, 9,  14, 20,
		5, 9,  14, 20,

		4, 11, 16, 23,
		4, 11, 16, 23,
		4, 11, 16, 23,
		4, 11, 16, 23,

		6, 10, 15, 21,
		6, 10, 15, 21,
		6, 10, 15, 21,
		6, 10, 15, 21,
	}

	local T = {}

	for i = 1, 64 do
		T[i] = math.floor(math.sin(i):abs() * 4294967296)
	end

	local function F(x, y, z)
		return bor(band(x, y), band(z, bnot(x)))
	end

	local function G(x, y, z)
		return bor(band(x, z), band(y, bnot(z)))
	end

	local H = bxor

	local function I(x, y, z)
		return bxor(y, bor(x, bnot(z)))
	end

	function meta:_Inner(cc)
		local A, B, C, D = self.A, self.B, self.C, self.D
		local num = math_floor(#cc / 64)
		self.blocks = self.blocks + num

		-- 512 bit block
		for i = 1, num do
			local init = (i - 1) * 64 - 4

			local a, b, c, d = A, B, C, D

			for t = 1, 16 do
				-- BIG-ENDIAN blocks!
				local a, b, c, d = string_byte(cc, init + t * 4 + 1, init + t * 4 + 4)

				W[t] = bor(
					a,
					lshift(b, 8),
					lshift(c, 16),
					lshift(d, 24)
				)
			end

			-- /* Round 1 */
			for i = 1, 16 do
				--a = b + ROTL(a + F(b, c, d) + W[i] + T[i], S[i])
				a = b + ROTL(a + bor(band(b, c), band(d, bnot(b))) + W[i] + T[i], S[i])
				a, b, c, d = d, a, b, c
			end

			local index = 1

			-- /* Round 2 */
			for i = 17, 32 do
				--a = b + ROTL(a + G(b, c, d) + W[index + 1] + T[i], S[i])
				a = b + ROTL(a + bor(band(b, d), band(c, bnot(d))) + W[index + 1] + T[i], S[i])
				index = band(index + 5, 0xF)
				a, b, c, d = d, a, b, c
			end

			index = 5

			-- /* Round 3 */
			for i = 33, 48 do
				a = b + ROTL(a + H(b, c, d) + W[index + 1] + T[i], S[i])
				index = band(index + 3, 0xF)
				a, b, c, d = d, a, b, c
			end

			index = 0

			-- /* Round 4 */
			for i = 49, 64 do
				a = b + ROTL(a + I(b, c, d) + W[index + 1] + T[i], S[i])
				index = band(index + 7, 0xF)
				a, b, c, d = d, a, b, c
			end

			A = tobit(A + a)
			B = tobit(B + b)
			C = tobit(C + c)
			D = tobit(D + d)
		end

		self.A, self.B, self.C, self.D = A, B, C, D
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
	else
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

function meta:DigestBinary()
	if not self.digest_hex then
		self:_Digest()
	end

	return overflow(bit.bswap(self.A)), overflow(bit.bswap(self.B)), overflow(bit.bswap(self.C)), overflow(bit.bswap(self.D))
end

DLib.Util.MD5 = DLib.CreateMoonClassBare('MD5', meta, {})

--[[
	@doc
	@fname DLib.Util.QuickMD5
	@args string data

	@desc
	Equals to `return DLib.Util.MD5():Update(str):Digest()`
	@enddesc

	@returns
	string: hex representation of hash string
]]

function DLib.Util.QuickMD5(str)
	return DLib.Util.MD5():Update(str):Digest()
end

function DLib.Util.QuickMD5Binary(str)
	return DLib.Util.MD5():Update(str):DigestBinary()
end

local metasha1 = {}

--[[
	@doc
	@fname DLib.Util.SHA1
	@args number H0 = 0x67452301, number H1 = 0xEFCDAB89, number H2 = 0x98BADCFE, number H3 = 0x10325476, number H4 = 0xC3D2E1F0

	@desc
	Returns SHA1 object, which has `:Update(data)` and `:Digest()` methods
	Arguments to this function allow to re-define standard initialization vector
	Don't touch them if you want SHA1 hash to match hashes created by other programs
	SHA1 is not secure and should not be utilized for such
	This is not actually a function (but still can be called), but a Moonscript compatible class table
	@enddesc

	@returns
	table: class representing SHA1 hash
]]

function metasha1:ctor(a, b, c, d, e)
	if a == nil then a = 0x67452301 end
	if b == nil then b = 0xEFCDAB89 end
	if c == nil then c = 0x98BADCFE end
	if d == nil then d = 0x10325476 end
	if e == nil then e = 0xC3D2E1F0 end

	assert(isnumber(a), 'H0 is not a number')
	assert(isnumber(b), 'H1 is not a number')
	assert(isnumber(c), 'H2 is not a number')
	assert(isnumber(d), 'H3 is not a number')
	assert(isnumber(e), 'H4 is not a number')

	self.H0 = a
	self.H1 = b
	self.H2 = c
	self.H3 = d
	self.H4 = e

	self.digested = false

	self.current_block = ''
	self.blocks = 0
	self.length = 0
end

do
	local W = {}
	local bytes = {}

	function metasha1:_Inner(cc)
		local num = math_floor(#cc / 64)
		self.blocks = self.blocks + num

		-- 512 bit block
		for i = 1, num do
			local init = (i - 1) * 64 - 4

			for t = 1, 16 do
				-- LITTLE-ENDIAN blocks!
				local a, b, c, d = string_byte(cc, init + t * 4 + 1, init + t * 4 + 4)

				W[t] = bor(
					d,
					lshift(c, 8),
					lshift(b, 16),
					lshift(a, 24)
				)
			end

			-- process extra
			for t = 17, 80 do
				W[t] = ROTL(bxor(W[t - 3], W[t - 8], W[t - 14], W[t - 16]), 1)
			end

			local A, B, C, D, E = self.H0, self.H1, self.H2, self.H3, self.H4

			for t = 1, 20 do
				E, D, C, B, A = D, C, ROTL(B, 30), A, ROTL(A, 5) + bor(band(B, C), band(bnot(B), D)) + E + W[t] + 0x5A827999
			end

			for t = 21, 40 do
				E, D, C, B, A = D, C, ROTL(B, 30), A, ROTL(A, 5) + bxor(B, C, D) + E + W[t] + 0x6ED9EBA1
			end

			for t = 41, 60 do
				E, D, C, B, A = D, C, ROTL(B, 30), A, ROTL(A, 5) + bor(band(B, C), band(B, D), band(C, D)) + E + W[t] + 0x8F1BBCDC
			end

			for t = 61, 80 do
				E, D, C, B, A = D, C, ROTL(B, 30), A, ROTL(A, 5) + bxor(B, C, D) + E + W[t] + 0xCA62C1D6
			end

			self.H0 = tobit(self.H0 + A)
			self.H1 = tobit(self.H1 + B)
			self.H2 = tobit(self.H2 + C)
			self.H3 = tobit(self.H3 + D)
			self.H4 = tobit(self.H4 + E)
		end
	end
end

metasha1.Update = meta.Update
metasha1.Digest = meta.Digest

function metasha1:_Digest()
	self.digested = true

	local mod = self.length % 64

	if mod < 56 then
		-- append 128, then 0
		self.current_block = self.current_block .. '\x80' .. string.rep('\x00', 55 - mod)
	else
		-- too long
		self.current_block = self.current_block ..
			'\x80' ..
			string.rep('\x00', 119 - mod)
	end

	local realLength = self.length * 8
	local modLen = realLength % 4294967296
	local div = (realLength - modLen) / 4294967296

	self:_Inner(self.current_block .. string.char(
		band(rshift(div, 24), 0xFF),
		band(rshift(div, 16), 0xFF),
		band(rshift(div, 8), 0xFF),
		band(rshift(div, 0), 0xFF),

		band(rshift(modLen, 24), 0xFF),
		band(rshift(modLen, 16), 0xFF),
		band(rshift(modLen, 8), 0xFF),
		band(rshift(modLen, 0), 0xFF)
	))

	self.digest_hex = string.format('%08x%08x%08x%08x%08x',
		overflow(self.H0),
		overflow(self.H1),
		overflow(self.H2),
		overflow(self.H3),
		overflow(self.H4))
end

function metasha1:DigestBinary()
	if not self.digest_hex then
		self:_Digest()
	end

	return  overflow(self.H0),
			overflow(self.H1),
			overflow(self.H2),
			overflow(self.H3),
			overflow(self.H4)
end

DLib.Util.SHA1 = DLib.CreateMoonClassBare('SHA1', metasha1, {})

--[[
	@doc
	@fname DLib.Util.QuickSHA1
	@args string data

	@desc
	Equals to `return DLib.Util.SHA1():Update(str):Digest()`
	@enddesc

	@returns
	string: hex representation of hash string
]]

function DLib.Util.QuickSHA1(str)
	return DLib.Util.SHA1():Update(str):Digest()
end

function DLib.Util.QuickSHA1Binary(str)
	return DLib.Util.SHA1():Update(str):DigestBinary()
end

local metasha224 = {}
local metasha256 = {}

--[[
	@doc
	@fname DLib.Util.SHA224
	@args number H0 = 0xC1059ED8, number H1 = 0x367CD507, number H2 = 0x3070DD17, number H3 = 0xF70E5939, number H4 = 0xFFC00B31, number H5 = 0x68581511, number H6 = 0x64F98FA7, number H7 = 0xBEFA4FA4

	@desc
	Returns SHA224 object, which has `:Update(data)` and `:Digest()` methods
	Arguments to this function allow to re-define standard initialization vector
	Don't touch them if you want SHA224 hash to match hashes created by other programs
	SHA224 is not very secure and should be avoided when security is a priority
	This is not actually a function (but still can be called), but a Moonscript compatible class table
	@enddesc

	@returns
	table: class representing SHA224 hash
]]

function metasha224:ctor(a, b, c, d, e, f, g, h)
	if a == nil then a = 0xC1059ED8 end
	if b == nil then b = 0x367CD507 end
	if c == nil then c = 0x3070DD17 end
	if d == nil then d = 0xF70E5939 end
	if e == nil then e = 0xFFC00B31 end
	if f == nil then f = 0x68581511 end
	if g == nil then g = 0x64F98FA7 end
	if h == nil then h = 0xBEFA4FA4 end

	assert(isnumber(a), 'H0 is not a number')
	assert(isnumber(b), 'H1 is not a number')
	assert(isnumber(c), 'H2 is not a number')
	assert(isnumber(d), 'H3 is not a number')
	assert(isnumber(e), 'H4 is not a number')
	assert(isnumber(f), 'H5 is not a number')
	assert(isnumber(g), 'H6 is not a number')
	assert(isnumber(h), 'H7 is not a number')

	self.H0 = a
	self.H1 = b
	self.H2 = c
	self.H3 = d
	self.H4 = e
	self.H5 = f
	self.H6 = g
	self.H7 = h

	self.digested = false

	self.current_block = ''
	self.blocks = 0
	self.length = 0
end

--[[
	@doc
	@fname DLib.Util.SHA256
	@args number H0 = 0x6A09E667, number H1 = 0xBB67AE85, number H2 = 0x3C6EF372, number H3 = 0xA54FF53A, number H4 = 0x510E527F, number H5 = 0x9B05688C, number H6 = 0x1F83D9AB, number H7 = 0x5BE0CD19

	@desc
	Returns SHA256 object, which has `:Update(data)` and `:Digest()` methods
	Arguments to this function allow to re-define standard initialization vector
	Don't touch them if you want SHA256 hash to match hashes created by other programs
	SHA256 is not very secure and should be avoided when security is a priority
	This is not actually a function (but still can be called), but a Moonscript compatible class table
	@enddesc

	@returns
	table: class representing SHA256 hash
]]

function metasha256:ctor(a, b, c, d, e, f, g, h)
	if a == nil then a = 0x6A09E667 end
	if b == nil then b = 0xBB67AE85 end
	if c == nil then c = 0x3C6EF372 end
	if d == nil then d = 0xA54FF53A end
	if e == nil then e = 0x510E527F end
	if f == nil then f = 0x9B05688C end
	if g == nil then g = 0x1F83D9AB end
	if h == nil then h = 0x5BE0CD19 end

	assert(isnumber(a), 'H0 is not a number')
	assert(isnumber(b), 'H1 is not a number')
	assert(isnumber(c), 'H2 is not a number')
	assert(isnumber(d), 'H3 is not a number')
	assert(isnumber(e), 'H4 is not a number')
	assert(isnumber(f), 'H5 is not a number')
	assert(isnumber(g), 'H6 is not a number')
	assert(isnumber(h), 'H7 is not a number')

	self.H0 = a
	self.H1 = b
	self.H2 = c
	self.H3 = d
	self.H4 = e
	self.H5 = f
	self.H6 = g
	self.H7 = h

	self.digested = false

	self.current_block = ''
	self.blocks = 0
	self.length = 0
end

do
	local function CH(x, y, z)
		return bxor(band(x, y), band(bnot(x), z))
	end

	local function MAJ(x, y, z)
		return bxor(band(x, y), band(x, z), band(y, z))
	end

	local function BSIG0(x)
		return bxor(ROTR(x, 2), ROTR(x, 13), ROTR(x, 22))
	end

	local function BSIG1(x)
		return bxor(ROTR(x, 6), ROTR(x, 11), ROTR(x, 25))
	end

	local function SSIG0(x)
		return bxor(ROTR(x, 7), ROTR(x, 18), rshift(x, 3))
	end

	local function SSIG1(x)
		return bxor(ROTR(x, 17), ROTR(x, 19), rshift(x, 10))
	end

	local W = {}
	local bytes = {}

	local K = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
		0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
		0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
		0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
		0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
		0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
		0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
		0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
		0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
	}

	local function _Inner(self, cc)
		-- 512 bit block
		for i = 1, math_floor(#cc / 64) do
			self.blocks = self.blocks + 1

			local init = (i - 1) * 64 - 4

			for t = 1, 16 do
				-- LITTLE-ENDIAN blocks!
				local a, b, c, d = string_byte(cc, init + t * 4 + 1, init + t * 4 + 4)

				W[t] = bor(
					d,
					lshift(c, 8),
					lshift(b, 16),
					lshift(a, 24)
				)
			end

			-- prepare
			for t = 17, 64 do
				W[t] = SSIG1(W[t - 2]) + W[t - 7] + SSIG0(W[t - 15]) + W[t - 16]
			end

			-- working variables
			local a, b, c, d, e, f, g, h =
				self.H0,
				self.H1,
				self.H2,
				self.H3,
				self.H4,
				self.H5,
				self.H6,
				self.H7

			for t = 1, 64 do
				local T1 =
					h +
					BSIG1(e) +
					CH(e, f, g) +
					K[t] +
					W[t]

				h, g, f, e, d, c, b, a = g, f, e, d + T1, c, b, a, T1 + BSIG0(a) + MAJ(a, b, c)
			end

			-- compute intermediate hash value
			self.H0 = tobit(a + self.H0)
			self.H1 = tobit(b + self.H1)
			self.H2 = tobit(c + self.H2)
			self.H3 = tobit(d + self.H3)
			self.H4 = tobit(e + self.H4)
			self.H5 = tobit(f + self.H5)
			self.H6 = tobit(g + self.H6)
			self.H7 = tobit(h + self.H7)
		end
	end

	metasha224._Inner = _Inner
	metasha256._Inner = _Inner
end

do
	local function _Digest(self)
		self.digested = true

		local mod = self.length % 64

		if mod < 56 then
			-- append 128, then 0
			self.current_block = self.current_block .. '\x80' .. string.rep('\x00', 55 - mod)
		else
			-- too long
			self.current_block = self.current_block ..
				'\x80' ..
				string.rep('\x00', 119 - mod)
		end

		local realLength = self.length * 8
		local modLen = realLength % 4294967296
		local div = (realLength - modLen) / 4294967296

		self:_Inner(self.current_block .. string.char(
			band(rshift(div, 24), 0xFF),
			band(rshift(div, 16), 0xFF),
			band(rshift(div, 8), 0xFF),
			band(rshift(div, 0), 0xFF),

			band(rshift(modLen, 24), 0xFF),
			band(rshift(modLen, 16), 0xFF),
			band(rshift(modLen, 8), 0xFF),
			band(rshift(modLen, 0), 0xFF)
		))
	end

	function metasha224:_Digest()
		_Digest(self)

		self.digest_hex = string.format('%08x%08x%08x%08x%08x%08x%08x',
			overflow(self.H0),
			overflow(self.H1),
			overflow(self.H2),
			overflow(self.H3),
			overflow(self.H4),
			overflow(self.H5),
			overflow(self.H6)
		)
	end

	function metasha224:DigestBinary()
		if not self.digest_hex then
			self:_Digest()
		end

		return  overflow(self.H0),
				overflow(self.H1),
				overflow(self.H2),
				overflow(self.H3),
				overflow(self.H4),
				overflow(self.H5),
				overflow(self.H6)
	end

	function metasha256:_Digest()
		_Digest(self)

		local N = self.blocks + 1

		self.digest_hex = string.format('%08x%08x%08x%08x%08x%08x%08x%08x',
			overflow(self.H0),
			overflow(self.H1),
			overflow(self.H2),
			overflow(self.H3),
			overflow(self.H4),
			overflow(self.H5),
			overflow(self.H6),
			overflow(self.H7)
		)
	end

	function metasha256:DigestBinary()
		if not self.digest_hex then
			self:_Digest()
		end

		return  overflow(self.H0),
				overflow(self.H1),
				overflow(self.H2),
				overflow(self.H3),
				overflow(self.H4),
				overflow(self.H5),
				overflow(self.H6),
				overflow(self.H7)
	end
end

metasha256.Update = meta.Update
metasha256.Digest = meta.Digest

metasha224.Update = meta.Update
metasha224.Digest = meta.Digest

DLib.Util.SHA256 = DLib.CreateMoonClassBare('SHA256', metasha256, {})
DLib.Util.SHA224 = DLib.CreateMoonClassBare('SHA224', metasha224, {})

--[[
	@doc
	@fname DLib.Util.QuickSHA256
	@args string data

	@desc
	Equals to `return DLib.Util.SHA256():Update(str):Digest()`
	@enddesc

	@returns
	string: hex representation of hash string
]]

function DLib.Util.QuickSHA256(str)
	return DLib.Util.SHA256():Update(str):Digest()
end

function DLib.Util.QuickSHA256Binary(str)
	return DLib.Util.SHA256():Update(str):DigestBinary()
end

--[[
	@doc
	@fname DLib.Util.QuickSHA224
	@args string data

	@desc
	Equals to `return DLib.Util.SHA224():Update(str):Digest()`
	@enddesc

	@returns
	string: hex representation of hash string
]]

function DLib.Util.QuickSHA224(str)
	return DLib.Util.SHA224():Update(str):Digest()
end

function DLib.Util.QuickSHA224Binary(str)
	return DLib.Util.SHA224():Update(str):DigestBinary()
end

local plyMeta = FindMetaTable('Player')

function plyMeta:DLibUniqueID()
	if self._dlib_hash then return self._dlib_hash end

	if self:IsBot() then
		self._dlib_hash = DLib.Util.QuickSHA1('Bot ' .. self:UserID())
		return self._dlib_hash
	end

	self._dlib_hash = DLib.Util.QuickSHA1(self:SteamID64() or '0')
	return self._dlib_hash
end

function player.GetByDLibUniqueID(id)
	local players = player.GetAll()

	for i = 1, #players do
		if players[i]:DLibUniqueID() == id then return players[i] end
	end

	return false
end
