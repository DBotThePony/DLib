
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

local string = string
local setmetatable = setmetatable
local math = math
local type = type
local tonumber = tonumber
local Vector = Vector
local ColorToHSV = ColorToHSV
local Lerp = Lerp
local util = util
local assert = assert
local srnd = util.SharedRandom

local colorMeta = FindMetaTable('Color') or {}
colorMeta.__index = colorMeta
debug.getregistry().Color = colorMeta

function _G.Color(r, g, b, a)
	r = math.Clamp(math.floor(tonumber(r) or 255), 0, 255)
	g = math.Clamp(math.floor(tonumber(g) or 255), 0, 255)
	b = math.Clamp(math.floor(tonumber(b) or 255), 0, 255)
	a = math.Clamp(math.floor(tonumber(a) or 255), 0, 255)

	local newObj = {
		r = r,
		g = g,
		b = b,
		a = a,
	}

	return setmetatable(newObj, colorMeta)
end

function _G.ColorFromSeed(seedIn)
	return Color(srnd(seedIn, 0, 255, 0), srnd(seedIn, 0, 255, 1), srnd(seedIn, 0, 255, 2))
end

local Color = Color

function _G.ColorAlpha(target, newAlpha)
	if target.Copy then
		return target:Copy():SetAlpha(newAlpha)
	else
		return Color(target.r, target.g, target.b, newAlpha)
	end
end

function _G.IsColor(object)
	if type(object) ~= 'table' then
		return false
	end

	return getmetatable(object) == colorMeta or
		type(object.r) == 'number' and
		type(object.g) == 'number' and
		type(object.b) == 'number' and
		type(object.a) == 'number'
end

_G.iscolor = IsColor

local IsColor = IsColor

function colorMeta:__tostring()
	return string.format('Color[%i %i %i %i]', self.r, self.g, self.b, self.a)
end

function colorMeta:ToHex()
	return string.format('0x%02x%02x%02x', self.r, self.g, self.b)
end

function colorMeta:ToNumberLittle()
	return self.r + self.g * 256 + self.b * 256 * 256
end

function colorMeta:ToNumber()
	return self.b + self.g * 256 + self.r * 256 * 256
end

colorMeta.ToNumberBig = colorMeta.ToNumber
colorMeta.ToNumberBigEndian = colorMeta.ToNumber
colorMeta.ToNumberLittlEndian = colorMeta.ToNumberLittle

function _G.ColorFromNumberLittle(numIn)
	assert(type(numIn) == 'number', 'Must be a number!')
	local red = numIn % 256
	numIn = (numIn - numIn % 256) / 256
	local green = numIn % 256
	numIn = (numIn - numIn % 256) / 256
	local blue = numIn % 256
	numIn = (numIn - numIn % 256) / 256

	return Color(red, green, blue)
end

function _G.ColorFromNumber(numIn)
	assert(type(numIn) == 'number', 'Must be a number!')
	local red = numIn % 256
	numIn = (numIn - numIn % 256) / 256
	local green = numIn % 256
	numIn = (numIn - numIn % 256) / 256
	local blue = numIn % 256
	numIn = (numIn - numIn % 256) / 256

	return Color(blue, green, red)
end

local ColorFromNumber = ColorFromNumber

function _G.ColorFromHex(hex)
	return ColorFromNumber(tonumber(hex, 16))
end

_G.ColorFromNumberLittleEndian = _G.ColorFromNumberLittle
_G.ColorFromNumberBig = _G.ColorFromNumber
_G.ColorFromNumberBigEndian = _G.ColorFromNumber

function colorMeta:__eq(target)
	if not IsColor(target) then
		return false
	end

	return target.r == self.r and target.g == self.g and target.b == self.b and target.a == self.a
end

function colorMeta:__add(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return Color(self.r + target, self.g + target, self.b + target)
	elseif type(target) == 'Vector' then
		return self + target:ToColor()
	else
		if not IsColor(target) then
			error('Color + ' .. type(target) .. ' => Not a function!')
		end

		return Color(self.r + target.r, self.g + target.g, self.b + target.b, self.a)
	end
end

function colorMeta:__sub(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return Color(self.r - target, self.g - target, self.b - target)
	elseif type(target) == 'Vector' then
		return self - target:ToColor()
	else
		if not IsColor(target) then
			error('Color - ' .. type(target) .. ' => Not a function!')
		end

		return Color(self.r - target.r, self.g - target.g, self.b - target.b, self.a)
	end
end

function colorMeta:__mul(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return Color(self.r * target, self.g * target, self.b * target)
	elseif type(target) == 'Vector' then
		return self * target:ToColor()
	else
		if not IsColor(target) then
			error('Color * ' .. type(target) .. ' => Not a function!')
		end

		return Color(self.r * target.r, self.g * target.g, self.b * target.b, self.a)
	end
end

function colorMeta:__div(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return Color(self.r / target, self.g / target, self.b / target)
	elseif type(target) == 'Vector' then
		return self / target:ToColor()
	else
		if not IsColor(target) then
			error('Color / ' .. type(target) .. ' => Not a function!')
		end

		return Color(self.r / target.r, self.g / target.g, self.b / target.b, self.a)
	end
end

function colorMeta:__mod(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return Color(self.r % target, self.g % target, self.b % target)
	elseif type(target) == 'Vector' then
		return self % target:ToColor()
	else
		if not IsColor(target) then
			error('Color % ' .. type(target) .. ' => Not a function!')
		end

		return Color(self.r % target.r, self.g % target.g, self.b % target.b, self.a)
	end
end

function colorMeta:__pow(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return Color(self.r ^ target, self.g ^ target, self.b ^ target)
	elseif type(target) == 'Vector' then
		return self ^ target:ToColor()
	else
		if not IsColor(target) then
			error('Color ^ ' .. type(target) .. ' => Not a function!')
		end

		return Color(self.r ^ target.r, self.g ^ target.g, self.b ^ target.b, self.a)
	end
end

function colorMeta:__concat(target)
	if IsColor(self) then
		return string.format('%i %i %i %i', self.r, self.g, self.b, self.a) .. target
	else
		return self .. string.format('%i %i %i %i', target.r, target.g, target.b, target.a)
	end
end

function colorMeta:__lt(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return self:Length() < target
	elseif type(target) == 'Vector' then
		return self < target:ToColor()
	else
		if not IsColor(target) then
			error('Color < ' .. type(target) .. ' => Not a function!')
		end

		return self:Length() < target:Length()
	end
end

function colorMeta:__le(target)
	if type(self) ~= 'table' and type(target) == 'table' then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		return self:Length() <= target
	elseif type(target) == 'Vector' then
		return self <= target:ToColor()
	else
		if not IsColor(target) then
			error('Color <= ' .. type(target) .. ' => Not a function!')
		end

		return self:Length() <= target:Length()
	end
end

function colorMeta:__unm()
	return self:Invert()
end

function colorMeta:Copy()
	return Color(self.r, self.g, self.b, self.a)
end

function colorMeta:Length()
	return self.r + self.g + self.b
end

function colorMeta:Invert()
	return Color(255 - self.r, 255 - self.g, 255 - self.b, self.a)
end

function colorMeta:ToHSV()
	return ColorToHSV(self)
end

function colorMeta:ToVector()
	return Vector(self.r / 255, self.g / 255, self.b / 255)
end

function colorMeta:Lerp(lerpValue, lerpTo)
	if not IsColor(lerpTo) then
		error('Color:Lerp - second argument is not a color!')
	end

	local r = Lerp(lerpValue, self.r, lerpTo.r)
	local g = Lerp(lerpValue, self.g, lerpTo.g)
	local b = Lerp(lerpValue, self.b, lerpTo.b)

	return Color(r, g, b, self.a)
end

do
	local methods = {
		r = 'Red',
		g = 'Green',
		b = 'Blue',
		a = 'Alpha'
	}

	for key, method in pairs(methods) do
		colorMeta['Set' .. method] = function(self, newValue)
			self[key] = math.Clamp(tonumber(newValue) or 255, 0, 255)
			return self
		end

		colorMeta['Get' .. method] = function(self)
			return self[key]
		end
	end
end

local colorBundle = {
	color_black = Color() - 255,
	color_white = Color(),
	color_red = Color(255, 0, 0),
	color_green = Color(0, 255, 0),
	color_blue = Color(0, 0, 255),
	color_cyan = Color(0, 255, 255),
	color_magenta = Color(255, 0, 255),
	color_yellow = Color(255, 255, 0),
	color_dlib = Color(0, 0, 0, 255),
	color_transparent = Color():SetAlpha(0),
}

for k, v in pairs(colorBundle) do
	_G[k] = v
end
