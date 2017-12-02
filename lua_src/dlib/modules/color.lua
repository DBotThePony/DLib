
-- Copyright (C) 2017 DBot

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

local colorMeta = FindMetaTable('Color') or {}

colorMeta.__index = function(self, key)
	if key == 1 then
		return self.r
	elseif key == 2 then
		return self.g
	elseif key == 3 then
		return self.b
	elseif key == 4 then
		return self.a
	else
		local val = rawget(self, key)

		if val ~= nil then
			return val
		end

		return colorMeta[key]
	end
end

debug.getregistry().Color = colorMeta

function _G.Color(r, g, b, a)
	r = math.Clamp(tonumber(r) or 255, 0, 255)
	g = math.Clamp(tonumber(g) or 255, 0, 255)
	b = math.Clamp(tonumber(b) or 255, 0, 255)
	a = math.Clamp(tonumber(a) or 255, 0, 255)

	local newObj = {
		r = r,
		g = g,
		b = b,
		a = a,
	}

	return setmetatable(newObj, colorMeta)
end

function _G.ColorAlpha(target, newAlpha)
	return target:Copy():SetAlpha(newAlpha)
end

function _G.IsColor(object)
	if type(object) ~= 'table' then
		return false
	end

	return type(object.r) == 'number' and type(object.g) == 'number' and type(object.b) == 'number' and type(object.a) == 'number'
end

_G.iscolor = IsColor

local IsColor = IsColor
local Color = Color

function colorMeta:__tostring()
	return string.format('Color[%i %i %i %i]', self.r, self.g, self.b, self.a)
end

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
	return Vector(self.r / 255, self.g / 255, self.a / 255)
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

_G.color_black = Color() - 255
_G.color_white = Color()
_G.color_transparent = Color():SetAlpha(0)