
--
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


local PhysObj = FindMetaTable('PhysObj')
local vectorMeta = FindMetaTable('Vector')
local vehicleMeta = FindMetaTable('Vehicle')
local entMeta = FindMetaTable('Entity')
local Color = Color
local math = math
local ipairs = ipairs
local assert = assert
local select = select
local language = language
local list = list
local pairs = pairs
local CLIENT = CLIENT

function PhysObj:SetAngleVelocity(newAngle)
	return self:AddAngleVelocity(newAngle - self:GetAngleVelocity())
end

PhysObj.DLibSetMass = PhysObj.DLibSetMass or PhysObj.SetMass
PhysObj.DLibEnableCollisions = PhysObj.DLibEnableCollisions or PhysObj.EnableCollisions
PhysObj.DLibEnableDrag = PhysObj.DLibEnableDrag or PhysObj.EnableDrag
PhysObj.DLibEnableMotion = PhysObj.DLibEnableMotion or PhysObj.EnableMotion
PhysObj.DLibEnableGravity = PhysObj.DLibEnableGravity or PhysObj.EnableGravity

function PhysObj:SetMass(newMass)
	if newMass <= 0 then
		print(debug.traceback('Mass can not be lower or equal to 0!', 2))
		return
	end

	return self:DLibSetMass(newMass)
end

local worldspawn, worldspawnPhys

-- shut up dumb addons
function PhysObj:EnableCollisions(newStatus)
	worldspawn = worldspawn or Entity(0)
	worldspawnPhys = worldspawnPhys or worldspawn:GetPhysicsObject()

	if worldspawnPhys == self then
		print(debug.traceback('Attempt to call :EnableCollisions() on World PhysObj!', 2))
		return
	end

	return self:DLibEnableCollisions(newStatus)
end

--[[
	@doc
	@fname Vector:Copy

	@desc
	Same as doing `Vector(self)`
	@enddesc

	@returns
	Vector
]]
function vectorMeta:Copy()
	return Vector(self)
end

--[[
	@doc
	@fname Vector:__call

	@returns
	Vector: copy
]]
function vectorMeta:__call()
	return Vector(self)
end

--[[
	@doc
	@fname Vector:ToNative

	@returns
	Vector: self
]]
function vectorMeta:ToNative()
	return self
end

--[[
	@doc
	@fname Vector:IsNormalized

	@returns
	boolean
]]
function vectorMeta:IsNormalized()
	return self.x <= 1 and self.y <= 1 and self.z <= 1 and self.x >= -1 and self.y >= -1 and self.z >= -1
end

--[[
	@doc
	@fname Vector:Receive
	@args Vector from

	@returns
	Vector: self
]]
function vectorMeta:Receive(target)
	local x, y, z = target.x, target.y, target.z
	self.x, self.y, self.z = x, y, z
	return self
end

--[[
	@doc
	@fname Vector:RotateAroundAxis
	@args Vector axis, number rotation

	@returns
	Vector: self
]]
function vectorMeta:RotateAroundAxis(axis, rotation)
	local ang = self:Angle()
	ang:RotateAroundAxis(axis, rotation)
	return self:Receive(ang:Forward() * self:Length())
end

--[[
	@doc
	@fname Vector:ToColor

	@returns
	Color
]]
function vectorMeta:ToColor()
	return Color(self.x * 255, self.y * 255, self.z * 255)
end

local type = luatype

--[[
	@doc
	@fname Vector:WithinAABox
	@args Vector mins, Vector maxs

	@desc
	can also accept `LVector`
	@enddesc

	@returns
	boolean
]]
function vectorMeta:WithinAABox(mins, maxs)
	if type(mins) ~= 'Vector' and type(mins) ~= 'LVector' then
		error('Vector:WithinAABox(' .. type(mins) .. ', ' .. type(maxs) .. ') - invalid call')
	end

	if type(maxs) ~= 'Vector' and type(maxs) ~= 'LVector' then
		error('Vector:WithinAABox(' .. type(mins) .. ', ' .. type(maxs) .. ') - invalid call')
	end

	return self.x >= mins.x
		and self.y >= mins.y
		and self.z >= mins.z
		and self.x <= maxs.x
		and self.y <= maxs.y
		and self.z <= maxs.z
end

--[[
	@doc
	@fname sql.EQuery
	@args string query

	@desc
	Same as gmod's sql.Query except it prints errors in console when one occures
	@enddesc

	@returns
	any: returned value from database
]]
function sql.EQuery(...)
	local data = sql.Query(...)

	if data == false then
		DLib.Message('SQL: ', ...)
		DLib.Message(sql.LastError())
	end

	return data
end

--[[
	@doc
	@fname math.progression
	@args number self, number min, number max, number middle = nil

	@returns
	number: position of self between min and max in 0-1 range, or 0-1-0 is middle is not nil
]]
function math.progression(self, min, max, middle)
	if self < min then return 0 end

	if middle then
		if self < min or self >= max then return 0 end

		if self < middle then
			return math.min((self - min) / (middle - min), 1)
		elseif self > middle then
			return 1 - math.min((self - middle) / (max - middle), 1)
		elseif self == middle then
			return 1
		end
	end

	return math.min((self - min) / (max - min), 1)
end

--[[
	@doc
	@fname math.equal
	@args vararg numbers

	@returns
	boolean
]]
function math.equal(...)
	local amount = select('#', ...)
	assert(amount > 1, 'At least two numbers are required!')
	local lastValue

	for i = 1, amount do
		local value = select(i, ...)
		lastValue = lastValue or value
		if value ~= lastValue then return false end
	end

	return true
end

--[[
	@doc
	@fname math.average
	@args vararg numbers

	@returns
	number: the average
]]
function math.average(...)
	local amount = select('#', ...)
	assert(amount > 1, 'At least two numbers are required!')
	local total = 0

	for i = 1, amount do
		total = total + select(i, ...)
	end

	return total / amount
end

local type = type
local table = table
local unpack = unpack

--[[
	@doc
	@fname math.bezier
	@args number t, vararg numbers

	@returns
	number
]]
function math.bezier(t, ...)
	return math.tbezier(t, {...})
end

--[[
	@doc
	@fname math.tbezier
	@args number t, table numbers

	@returns
	number
]]
-- accepts table
function math.tbezier(t, values)
	assert(type(t) == 'number', 'invalid T variable')
	assert(t >= 0 and t <= 1, '0 <= t <= 1!')
	assert(#values >= 2, 'at least two values must be provided')
	local amount = #values
	local a, b = values[1], values[2]

	-- linear
	if amount == 2 then
		return a + (b - a) * t
	-- square
	elseif amount == 3 then
		return (1 - t):pow(2) * a + 2 * t * (1 - t) * b + t:pow(2) * values[3]
	-- cube
	elseif amount == 4 then
		return (1 - t):pow(3) * a + 3 * t * (1 - t):pow(2) * b + 3 * t:pow(2) * (1 - t) * values[3] + t:pow(3) * values[4]
	end

	-- instead of implementing matrix, using bare loops
	local points = {}

	for point = 1, amount do
		local point1 = values[point]
		local point2 = values[point + 1]
		if not point2 then break end
		local newpoint = point1 + (point2 - point1) * t
		table.insert(points, newpoint)
	end

	return math.tbezier(t, points)
end

--[[
	@doc
	@fname math.tformat
	@args number time

	@returns
	table: formatted table
]]
function math.tformat(time)
	assert(type(time) == 'number', 'Invalid time provided.')

	if time > 0xFFFFFFFFFF then
		error('Value is too big! Maximum is ' .. 0xFFFFFFFFFF)
	elseif time <= 1 then
		return {centuries = 0, years = 0, weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0, months = 0}
	end

	local output = {}

	output.centuries = (time - time % 0xBBF81E00) / 0xBBF81E00
	time = time - output.centuries * 0xBBF81E00

	output.years = (time - time % 0x01E13380) / 0x01E13380
	time = time - output.years * 0x01E13380

	output.months = ((time - time % 0x00278D00) / 0x00278D00):min(11)
	time = time - output.months * 0x00278D00

	output.weeks = (time - time % 604800) / 604800
	time = time - output.weeks * 604800

	output.days = (time - time % 86400) / 86400
	time = time - output.days * 86400

	output.hours = (time - time % 3600) / 3600
	time = time - output.hours * 3600

	output.minutes = (time - time % 60) / 60
	time = time - output.minutes * 60

	output.seconds = math.floor(time)

	return output
end


--[[
	@doc
	@fname math.untformat
	@args table time

	@desc
	reverse of table format of number
	@enddesc

	@returns
	number
]]
function math.untformat(time)
	assert(type(time) == 'table', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.centuries) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.years) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.months) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.weeks) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.days) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.hours) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.minutes) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(time.seconds) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')

	return time.centuries * 0xBBF81E00
		+ time.years * 0x01E13380
		+ time.months * 0x00278D00
		+ time.weeks * 604800
		+ time.days * 86400
		+ time.hours * 3600
		+ time.minutes * 60
		+ time.seconds
end

local CLIENT = CLIENT
local hook = hook
local net = net

if SERVER then
	net.pool('dlib.limithitfix')
end

local plyMeta = FindMetaTable('Player')

--[[
	@doc
	@fname Player:LimitHit

	@desc
	This function no longer produce limit hit message when called clientside
	this function is internal and is used by gmod itself
	but the override allows you to put !g:Player:CheckLimit in shared code of toolguns
	@enddesc
]]
function plyMeta:LimitHit(limit)
	-- we call CheckLimit() on client just for prediction
	-- so when we actually hit limit - it can produce two messages because client will also try to
	-- display this message by calling hook LimitHit. So, let's call that only once.

	-- if you want to call this function clientside despite this text and warning
	-- you can run hooks on LimitHit manually by doing so:
	-- hook.Run('LimitHit', 'mylimit')
	-- you shouldn't really call this function directly clientside
	if CLIENT then return end

	net.Start('dlib.limithitfix')
	net.WriteString(limit)
	net.Send(self)
end

if CLIENT then
	net.receive('dlib.limithitfix', function()
		hook.Run('LimitHit', net.ReadString())
	end)
end

if CLIENT then
	local surface = surface
	surface._DLibPlaySound = surface._DLibPlaySound or surface.PlaySound

	function surface.PlaySound(path, ...)
		assert(type(path) == 'string', 'surface.PlaySound - string expected, got ' .. type(path))
		local can = hook.Run('SurfaceEmitSound', path, ...)
		if can == false then return end
		return surface._DLibPlaySound(path, ...)
	end

	-- cache and speedup lookups a bit
	local use_type = CreateConVar('dlib_screenscale', '1', {FCVAR_ARCHIVE}, 'Use screen height as screen scale parameter instead of screen width')
	local ScrWL = ScrWL
	local ScrHL = ScrHL

	function _G.ScreenScale(modify)
		return ScrWL() / 640 * modify
	end

	local screenfunc

	if use_type:GetBool() then
		function screenfunc(modify)
			return ScrHL() / 480 * modify
		end
	else
		function screenfunc(modify)
			return ScrWL() / 640 * modify
		end
	end

	--[[
		@doc
		@fname ScreenSize
		@args number modify

		@desc
		same as ScreenScale but use screen height (by default)
		behvaior can be changed by user
		@enddesc

		@returns
		number
	]]
	function _G.ScreenSize(modify)
		return screenfunc(modify)
	end

	local function dlib_screenscale_chages()
		if use_type:GetBool() then
			function screenfunc(modify)
				return ScrHL() / 480 * modify
			end
		else
			function screenfunc(modify)
				return ScrWL() / 640 * modify
			end
		end

		DLib.TriggerScreenSizeUpdate(ScrWL(), ScrHL(), ScrWL(), ScrHL())
	end

	cvars.AddChangeCallback('dlib_screenscale', dlib_screenscale_chages, 'DLib')
end
