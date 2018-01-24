
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local Lerp = Lerp
local LerpCubic = LerpCubic
local Cubic = Cubic
local bit = bit
local assert = assert
local type = type
local perlin = DLib.CreateLuaObject('Perlin2D', true)
local random = util.SharedRandom

function perlin:__construct(seed)
	seed = seed or 0
	self.seed = seed
	self.knownPoints = {}
	self.bytes = {}

	for i = 0, 1023 do
		self.bytes[i] = math.floor(random('perlin2d_pregen', 0, 1024, self.seed * 1.25 + i ^ 1.25))
	end
end

local function Dot2D(a, b)
	return a[1] * b[1] + a[2] * b[2]
end

function perlin:GetVectorAt(x, y)
	assert(type(x) == 'number', 'X must be a number!')
	assert(type(y) == 'number', 'Y must be a number!')

	--local rnd = bit.band(math.abs(math.floor(bit.band(x * 5 + 16 - 4 * y + y ^ 2 * 154 - x ^ 24 + (self.seed ^ 2) * 552, 1024 + self.seed))), 3)
	local rnd = math.floor(bit.band(bit.bxor(x * 346234, y * 123652) + 63687782, 1023))
	rnd = self.bytes[rnd]
	rnd = rnd % 4

	--local point = math.floor(random('perlin2d', 1, 1023, self.seed * 2 + x * 1.35 - y * 1.5 + math.sin(x + y) - math.cos(x - y)))
	--local point = math.floor(math.random() * 1022 + 1)
	--local rnd =  self.bytes[point]

	if rnd == 0 then
		return {1, 0}
	elseif rnd == 1 then
		return {-1, 0}
	elseif rnd == 2 then
		return {0, 1}
	elseif rnd == 3 then
		return {0, -1}
	end
end

function perlin:Generate(fx, fy)
	local x = math.floor(fx)
	local y = math.floor(fy)

	local quadX = fx - x
	local quadY = fy - y

	local topL = self:GetVectorAt(x, y)
	local topR = self:GetVectorAt(x + 1, y)
	local bottomL = self:GetVectorAt(x, y + 1)
	local bottomR = self:GetVectorAt(x + 1, y + 1)

	local dTopL = {quadX, quadY}
	local dTopR = {quadX - 1, quadY}
	local dBottomL = {quadX, quadY - 1}
	local dBottomR = {quadX - 1, quadY - 1}

	local dotTopL = Dot2D(dTopL, topL)
	local dotTopR = Dot2D(dTopR, topR)
	local dotBottomL = Dot2D(dBottomL, bottomL)
	local dotBottomR = Dot2D(dBottomR, bottomR)

	local tx = Cubic(quadX)
	local ty = Cubic(quadY)

	local ix = Lerp(tx, dotTopL, dotTopR)
	local iy = Lerp(tx, dotBottomL, dotBottomR)
	return Lerp(ty, ix, iy)
end
