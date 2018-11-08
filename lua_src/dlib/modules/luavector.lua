
-- Copyright (C) 2018 DBot

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


local meta = FindMetaTable('LVector') or {}
debug.getregistry().LVector = meta

local table = table
local rawget = rawget
local rawset = rawset
local error = error
local string = string
local Vector = Vector
local type = luatype
local setmetatable = setmetatable
local Angle = Angle
local Color = Color
local Lerp = Lerp

meta.MetaName = 'LVector'

function meta:__index(key)
	if key == 1 then
		return self.x
	elseif key == 2 then
		return self.y
	elseif key == 3 then
		return self.z
	end

	local func = meta[key]

	if func then
		return func
	end

	return rawget(self, key)
end

function meta:__newindex(key, value)
	if key == 1 then
		key = 'x'
	elseif key == 2 then
		key = 'y'
	elseif key == 3 then
		key = 'z'
	end

	rawset(self, key, value)
end

local function LVector(x, y, z)
	if type(x) == 'Vector' or type(x) == 'LVector' then
		y = x.y
		z = x.z
		x = x.x
	end

	if type(x) ~= 'nil' and type(x) ~= 'number' then
		error('Invalid X variable. typeof ' .. type(x))
	end

	if type(y) ~= 'nil' and type(y) ~= 'number' then
		error('Invalid Y variable. typeof ' .. type(y))
	end

	if type(z) ~= 'nil' and type(z) ~= 'number' then
		error('Invalid Z variable. typeof ' .. type(z))
	end

	local object = {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}

	return setmetatable(object, meta)
end

_G.LVector = LVector
_G.LuaVector = LVector

function meta:ToNative()
	return Vector(self.x, self.y, self.z)
end

function meta:ToLua()
	return LVector(self)
end

function meta:Copy()
	return LVector(self)
end

function meta:ToVector()
	return LVector(self)
end

function meta:__tostring()
	return string.format('LuaVector [%.6f %.6f %.6f]', self.x, self.y, self.z)
end

function meta:__call()
	return LVector(self)
end

-- Vector maths

local math = math

function meta:Length()
	return math.sqrt(self.x:pow(2) + self.y:pow(2) + self.z:pow(2))
end

function meta:LengthSqr()
	return self.x:pow(2) + self.y:pow(2) + self.z:pow(2)
end

function meta:Length2D()
	return math.sqrt(self.x:pow(2) + self.y:pow(2))
end

function meta:Length2DSqr()
	return self.x:pow(2) + self.y:pow(2)
end

function meta:Normalize()
	local len = self:Length()
	self.x, self.y, self.z = self.x / len, self.y / len, self.z / len
	return self
end

function meta:GetNormalized()
	local len = self:Length()
	return LVector(self.x / len, self.y / len, self.z / len)
end

function meta:IsNormalized()
	return self.x <= 1 and self.y <= 1 and self.z <= 1 and self.x >= -1 and self.y >= -1 and self.z >= -1
end

local UP = LVector(0, 0, 1)
local FORWARD = LVector(1, 0, 0)
local LEFT = LVector(0, 1, 0)

function meta:Dot(another)
	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:Dot(' .. type(another) .. ') - invalid call')
	end

	local scalar =
		self.x * another.x +
		self.y * another.y +
		self.z * another.z

	local len = self:Length() * another:Length()

	if len == 0 then return 0 end

	return scalar / len
end

function meta:IsZero()
	return self.x == 0 and self.y == 0 and self.z == 0
end

function meta:Lerp(lerpValue, lerpTo)
	if type(lerpTo) ~= 'Vector' and type(lerpTo) ~= 'LVector' then
		error('LVector:Lerp(' .. type(lerpValue) .. ', ' .. type(lerpTo) .. ') - invalid call')
	end

	local x = Lerp(lerpValue, self.x, lerpTo.x)
	local y = Lerp(lerpValue, self.y, lerpTo.x)
	local z = Lerp(lerpValue, self.z, lerpTo.z)

	return LVector(x, y, z)
end

meta.CosinusBetween = meta.Dot
meta.DegreeBetween = meta.Dot

-- Various vanilla things

function meta:Add(another)
	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:Add(' .. type(another) .. ') - invalid call')
	end

	self.x = self.x + another.x
	self.y = self.y + another.y
	self.z = self.z + another.z

	return self
end

function meta:Sub(another)
	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:Sub(' .. type(another) .. ') - invalid call')
	end

	self.x = self.x - another.x
	self.y = self.y - another.y
	self.z = self.z - another.z

	return self
end

function meta:Set(another)
	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:Set(' .. type(another) .. ') - invalid call')
	end

	self.x = another.x
	self.y = another.y
	self.z = another.z

	return self
end

function meta:Zero()
	self.x = 0
	self.y = 0
	self.z = 0

	return self
end

function meta:WithinAABox(mins, maxs)
	if type(mins) ~= 'Vector' and type(mins) ~= 'LVector' then
		error('LVector:WithinAABox(' .. type(mins) .. ', ' .. type(maxs) .. ') - invalid call')
	end

	if type(maxs) ~= 'Vector' and type(maxs) ~= 'LVector' then
		error('LVector:WithinAABox(' .. type(mins) .. ', ' .. type(maxs) .. ') - invalid call')
	end

	return self.x >= mins.x
		and self.y >= mins.y
		and self.z >= mins.z
		and self.x <= maxs.x
		and self.y <= maxs.y
		and self.z <= maxs.z
end

function meta:Distance(another)
	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:Distance(' .. type(another) .. ') - invalid call')
	end

	return math.sqrt((self.x - another.x):pow(2) + (self.y - another.y):pow(2) + (self.z - another.z):pow(2))
end

function meta:DistToSqr(another)
	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:DistToSqr(' .. type(another) .. ') - invalid call')
	end

	return (self.x - another.x):pow(2) + (self.y - another.y):pow(2) + (self.z - another.z):pow(2)
end

function meta:Mul(number)
	if type(number) ~= 'number' then
		error('LVector:Mul(' .. type(number) .. ') - invalid call')
	end

	self.x = self.x * number
	self.y = self.y * number
	self.z = self.z * number

	return self
end

function meta:Div(number)
	if type(number) ~= 'number' then
		error('LVector:Div(' .. type(number) .. ') - invalid call')
	end

	self.x = self.x / number
	self.y = self.y / number
	self.z = self.z / number

	return self
end

function meta:ToColor()
	return Color(self.x / 255, self.y / 255, self.z / 255)
end

function meta:Angle()
	local normal = self:GetNormalized()

	local x, y = normal.x, normal.y
	local add = 45

	if x > 0 and y < 0 then
		add = -45
	end

	local dotPitch = normal:Dot(UP)
	local dotYaw = LVector(x, y):Dot(LVector(1, 1)):acos():deg() + add

	if x > 0 and y < 0 then
		dotYaw = -dotYaw
	end

	return Angle(-dotPitch:asin():deg(), dotYaw, 0)
end

-- Extended

function meta:Invert()
	return LVector(-self.x, -self.y, -self.z)
end

function meta:IsValid()
	return
		self.x == self.x
		and self.y == self.y
		and self.z == self.z
		and self.x ~= self.x.huge
		and self.y ~= self.y.huge
		and self.z ~= self.z.huge
		and self.x ~= -self.x.huge
		and self.y ~= -self.y.huge
		and self.z ~= -self.z.huge
end

-- Lua metamethods

function meta:__unm()
	return self:Invert()
end

function meta:__eq(another)
	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__eq(' .. type(another) .. ') - invalid call')
	end

	return self.x == another.x and self.y == another.y and self.z == another.z
end

function meta:__add(another)
	--[[if type(self) == 'number' then
		return LVector(another.x + self, another.y + self, another.z + self)
	end

	if type(another) == 'number' then
		return LVector(another + self.x, another + self.y, another + self.z)
	end]]

	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__add(' .. type(another) .. ') - invalid call')
	end

	if type(self) ~= 'Vector' and type(self) ~= 'LVector' then
		error('LVector:__add(' .. type(self) .. ') - invalid call')
	end

	return LVector(another.x + self.x, another.y + self.y, another.z + self.z)
end

function meta:__sub(another)
	--[[if type(self) == 'number' then
		return LVector(another.x - self, another.y - self, another.z - self)
	end

	if type(another) == 'number' then
		return LVector(self.x - another, self.y - another, self.z - another)
	end]]

	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__sub(' .. type(another) .. ') - invalid call')
	end

	if type(self) ~= 'Vector' and type(self) ~= 'LVector' then
		error('LVector:__sub(' .. type(self) .. ') - invalid call')
	end

	return LVector(self.x - another.x, self.y - another.x, self.z - another.x)
end

function meta:__mul(another)
	if type(self) == 'number' then
		return LVector(another.x * self, another.y * self, another.z * self)
	end

	if type(another) == 'number' then
		return LVector(self.x * another, self.y * another, self.z * another)
	end

	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__mul(' .. type(another) .. ') - invalid call')
	end

	if type(self) ~= 'Vector' and type(self) ~= 'LVector' then
		error('LVector:__mul(' .. type(self) .. ') - invalid call')
	end

	return LVector(self.x * another.x, self.y * another.x, self.z * another.x)
end

function meta:__div(another)
	if type(self) == 'number' then
		return LVector(another.x / self, another.y / self, another.z / self)
	end

	if type(another) == 'number' then
		return LVector(self.x / another, self.y / another, self.z / another)
	end

	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__div(' .. type(another) .. ') - invalid call')
	end

	if type(self) ~= 'Vector' and type(self) ~= 'LVector' then
		error('LVector:__div(' .. type(self) .. ') - invalid call')
	end

	return LVector(self.x / another.x, self.y / another.x, self.z / another.x)
end

function meta:__mod(another)
	if type(self) == 'number' then
		return LVector(another.x % self, another.y % self, another.z % self)
	end

	if type(another) == 'number' then
		return LVector(self.x % another, self.y % another, self.z % another)
	end

	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__mod(' .. type(another) .. ') - invalid call')
	end

	if type(self) ~= 'Vector' and type(self) ~= 'LVector' then
		error('LVector:__mod(' .. type(self) .. ') - invalid call')
	end

	return LVector(self.x % another.x, self.y % another.x, self.z % another.x)
end

function meta:__lt(another)
	if type(self) == 'number' then
		return another:Length() < self
	end

	if type(another) == 'number' then
		return self:Length() < another
	end

	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__lt(' .. type(another) .. ') - invalid call')
	end

	if type(self) ~= 'Vector' and type(self) ~= 'LVector' then
		error('LVector:__lt(' .. type(self) .. ') - invalid call')
	end

	return self:Length() < another:Length()
end

function meta:__le(another)
	if type(self) == 'number' then
		return another:Length() <= self
	end

	if type(another) == 'number' then
		return self:Length() <= another
	end

	if type(another) ~= 'Vector' and type(another) ~= 'LVector' then
		error('LVector:__le(' .. type(another) .. ') - invalid call')
	end

	if type(self) ~= 'Vector' and type(self) ~= 'LVector' then
		error('LVector:__le(' .. type(self) .. ') - invalid call')
	end

	return self:Length() <= another:Length()
end

function meta:__concat(another)
	if type(self) == 'LVector' then
		return string.format('Vector [%.2f %.2f %.2f]', self.x, self.y, self.z) .. another
	else
		return self .. string.format('Vector [%.2f %.2f %.2f]', another.x, another.y, another.z)
	end
end
