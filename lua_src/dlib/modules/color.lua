
-- Copyright (C) 2017-2018 DBot

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

local function Color(r, g, b, a)
	if type(r) == 'table' then
		g = r.g
		b = r.b
		a = r.a
		r = r.r
	elseif type(r) == 'number' and r > 255 and not g and not b and not a then
		return ColorBE(r)
	end

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

_G.Color = Color
local IsColor

function _G.ColorAlpha(target, newAlpha)
	if not IsColor(target) then
		error('Input is not a color! typeof ' .. type(target))
	end

	if target.Copy then
		return target:Copy():SetAlpha(newAlpha)
	else
		return Color(target.r, target.g, target.b, newAlpha)
	end
end

function IsColor(object)
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
_G.IsColor = IsColor

function colorMeta:__tostring()
	return string.format('Color[%i %i %i %i]', self.r, self.g, self.b, self.a)
end

function colorMeta:ToHex()
	return string.format('0x%02x%02x%02x', self.r, self.g, self.b)
end

function colorMeta:ToNumberLittle(writeAlpha)
	if writeAlpha then
		return self.r:band(255) + self.g:band(255):lshift(8) + self.b:band(255):lshift(16) + self.a:band(255):lshift(24)
	else
		return self.r:band(255) + self.g:band(255):lshift(8) + self.b:band(255):lshift(16)
	end
end

function colorMeta:ToNumber(writeAlpha)
	if writeAlpha then
		return self.r:band(255):lshift(24) + self.g:band(255):lshift(16) + self.b:band(255):lshift(8) + self.a:band(255)
	else
		return self.r:band(255):lshift(16) + self.g:band(255):lshift(8) + self.b:band(255)
	end
end

colorMeta.ToNumberBig = colorMeta.ToNumber
colorMeta.ToNumberBigEndian = colorMeta.ToNumber
colorMeta.ToNumberBE = colorMeta.ToNumber
colorMeta.ToNumberLittlEndian = colorMeta.ToNumberLittle
colorMeta.ToNumberLE = colorMeta.ToNumberLittle

function _G.ColorFromNumberLittle(numIn, hasAlpha)
	assert(type(numIn) == 'number', 'Must be a number!')
	if hasAlpha then
		local a, b, g, r =
			numIn:rshift(24):band(255),
			numIn:rshift(16):band(255),
			numIn:rshift(8):band(255),
			numIn:band(255)

		return Color(r, g, b, a)
	end

	local b, g, r =
		numIn:rshift(16):band(255),
		numIn:rshift(8):band(255),
		numIn:band(255)

	return Color(r, g, b)
end

function _G.ColorFromNumber(numIn, hasAlpha)
	assert(type(numIn) == 'number', 'Must be a number!')
	if hasAlpha then
		local r, g, b, a =
			numIn:rshift(24):band(255),
			numIn:rshift(16):band(255),
			numIn:rshift(8):band(255),
			numIn:band(255)

		return Color(r, g, b, a)
	end

	local r, g, b =
		numIn:rshift(16):band(255),
		numIn:rshift(8):band(255),
		numIn:band(255)

	return Color(r, g, b)
end

local ColorFromNumber = ColorFromNumber

function _G.ColorFromHex(hex, hasAlpha)
	return ColorFromNumber(tonumber(hex, 16), hasAlpha)
end

_G.ColorHex = _G.ColorFromHex
_G.ColorHEX = _G.ColorFromHex
_G.ColorFromHEX = _G.ColorFromHex
_G.Color16 = _G.ColorFromHex
_G.ColorFrom16 = _G.ColorFromHex
_G.ColorFromNumberLittleEndian = _G.ColorFromNumberLittle
_G.ColorFromNumberLE = _G.ColorFromNumberLittle
_G.ColorLE = _G.ColorFromNumberLittle
_G.ColorFromNumberBig = _G.ColorFromNumber
_G.ColorFromNumberBigEndian = _G.ColorFromNumber
_G.ColorFromNumberBE = _G.ColorFromNumber
_G.ColorBE = _G.ColorFromNumber

_G.HSVToColorC = HSVToColorC or HSVToColor

function _G.HSVToColor(hue, saturation, value)
	assert(type(hue) == 'number' and hue >= 0 and hue <= 360, 'Invalid hue value. It must be a number and be in 0-360 range')
	assert(type(saturation) == 'number' and saturation >= 0 and saturation <= 1, 'Invalid saturation value. It must be a number and be in 0-1 (float) range')
	assert(type(value) == 'number' and value >= 0 and value <= 1, 'Invalid color value (brightness). It must be a number and be in 0-1 (float) range')

	local huei = (hue / 60):floor() % 6
	local valueMin = (1 - saturation) * value
	local delta = (value - valueMin) * (hue % 60) / 60
	local valueInc = valueMin + delta
	local valueDec = value - delta

	if huei == 0 then
		return Color(value * 255, valueInc * 255, valueMin * 255)
	elseif huei == 1 then
		return Color(valueDec * 255, value * 255, valueMin * 255)
	elseif huei == 2 then
		return Color(valueMin * 255, value * 255, valueInc * 255)
	elseif huei == 3 then
		return Color(valueMin * 255, valueDec * 255, value * 255)
	elseif huei == 4 then
		return Color(valueInc * 255, valueMin * 255, value * 255)
	end

	return Color(value * 255, valueMin * 255, valueDec * 255)
end

function colorMeta:__eq(target)
	if not IsColor(target) then
		return false
	end

	return target.r == self.r and target.g == self.g and target.b == self.b and target.a == self.a
end

function colorMeta:__add(target)
	if not IsColor(self) and IsColor(target) then
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
	if not IsColor(self) and IsColor(target) then
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
	if not IsColor(self) and IsColor(target) then
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
	if not IsColor(self) and IsColor(target) then
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
	if not IsColor(self) and IsColor(target) then
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
	if not IsColor(self) and IsColor(target) then
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
	if not IsColor(self) and IsColor(target) then
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
	if not IsColor(self) and IsColor(target) then
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

		colorMeta['Modify' .. method] = function(self, newValue)
			local new = Color(self)
			new[key] = newValue
			return new
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
