
--
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


local PhysObj = FindMetaTable('PhysObj')
local vectorMeta = FindMetaTable('Vector')
local vehicleMeta = FindMetaTable('Vehicle')
local entMeta = FindMetaTable('Entity')
local panelMeta = FindMetaTable('Panel')
local Color = Color
local math = math
local ipairs = ipairs
local assert = assert
local select = select
local language = language
local list = list
local pairs = pairs
local CLIENT = CLIENT

_G.angle_empty = Angle()
_G.angle_up = Angle(90)
_G.angle_down = Angle(-90)
_G.angle_left = Angle(0, 90)
_G.angle_right = Angle(0, -90)

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
	local fwd = ang:Forward()
	fwd:Mul(self:Length())
	return self:Receive(fwd)
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

vectorMeta._DLib_WithinAABox = vectorMeta._DLib_WithinAABox or vectorMeta.WithinAABox

--[[
	@doc
	@fname Vector:WithinAABox
	@args Vector mins, Vector maxs
	@replaces

	@desc
	modifies function to also accept `LVector`
	forwards call to original function when both arguments are regular vectors
	@enddesc

	@returns
	boolean
]]
function vectorMeta:WithinAABox(mins, maxs)
	local typemi, typema = type(mins), type(maxs)

	if typemi == 'Vector' and typema == 'Vector' then
		return self:_DLib_WithinAABox(mins, maxs)
	end

	if typemi ~= 'Vector' and typemi ~= 'LVector' then
		error('Vector:WithinAABox(' .. typemi .. ', ' .. typema.. ') - invalid call')
	end

	if typema ~= 'Vector' and typema ~= 'LVector' then
		error('Vector:WithinAABox(' .. typemi .. ', ' .. typema .. ') - invalid call')
	end

	local minsx, minsy, minsz, maxsx, maxsy, maxsz = mins.x, mins.y, mins.z, maxs.x, maxs.y, maxs.z

	local normalized = minsx < maxsx and minxy < maxsy and minsz < maxsz

	if not normalized then
		-- as seen on example on https://wiki.facepunch.com/gmod/Vector:WithinAABox
		-- local mins = Vector(1119, 895, 63)
		-- local maxs = Vector(656, -896, -144)
		minsx, minsy, minsz, maxsx, maxsy, maxsz = minsx:min(maxsx), minsy:min(maxsy), minsz:min(maxsz), maxsx:max(minsx), maxsy:max(minsy), maxsz:max(minsz)
	end

	local x, y, z = self.x, self.y, self.z

	return x >= minsx and y >= minsy and z >= minsz and
		x <= maxsx and y <= maxsy and z <= maxsz
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
local buffer = {}

local bezier_lut = {}
local bezier_lut2 = {}
local bake_bezier, bake_bezier2

local function tbezier(t, values, amount)
	assert(type(t) == 'number', 'invalid T variable')
	assert(t >= 0 and t <= 1, '0 <= t <= 1!')
	assert(amount >= 2, 'at least two values must be provided')

	-- linear
	if amount == 2 then
		return values[1] + (values[2] - values[1]) * t
	-- square
	elseif amount == 3 then
		return (1 - t) * (1 - t) * values[1] + 2 * t * (1 - t) * values[2] + t * t * values[3]
	-- cubic
	elseif amount == 4 then
		return (1 - t) * (1 - t) * (1 - t) * values[1] + 3 * t * (1 - t) * (1 - t) * values[2] + 3 * t * t * (1 - t) * values[3] + t * t * t * values[4]
	-- high prime, but not too high
	elseif amount <= 160 then
		return bake_bezier(amount)(t, values)
	end

	-- recursively construct lower prime
	for point = 1, amount do
		local point1 = values[point]
		local point2 = values[point + 1]
		if not point2 then break end
		buffer[point] = point1 + (point2 - point1) * t
	end

	return tbezier(t, buffer, amount - 1)
end

local function bezier(t, a, b, c, d, ...)
	assert(type(t) == 'number', 'invalid T variable')
	assert(t >= 0 and t <= 1, '0 <= t <= 1!')
	local amount = select('#', ...)
	--assert(amount + 4 <= 200, 'Too many values! Use tbezier instead')

	-- linear
	if c == nil then
		return a + (b - a) * t
	-- square
	elseif d == nil then
		return (1 - t) * (1 - t) * a + 2 * t * (1 - t) * b + t * t * c
	-- cubic
	elseif amount == 0 then
		return (1 - t) * (1 - t) * (1 - t) * a + 3 * t * (1 - t) * (1 - t) * b + 3 * t * t * (1 - t) * c + t * t * t * d
	-- high prime, but not too high
	elseif amount <= 160 then
		return bake_bezier2(amount + 4)(t, a, b, c, d, ...)
	end

	-- fallback to slower method
	return tbezier(t, {a, b, c, d, ...}, amount + 4)
end

do
	local function pow(strin, times)
		if times == 0 then return '1' end

		if times > 4 then
			return 'pow(' .. strin .. ', ' .. times .. ')'
		end

		local values2 = {}

		for i2 = 1, times do
			table.insert(values2, strin)
		end

		return table.concat(values2, ' * ')
	end

	local function factorial(numin)
		if numin == 0 then return 1 end

		local num = 1

		for i = 1, numin do
			num = num * i
		end

		return num
	end

	function bake_bezier(i)
		local getfn = bezier_lut[i]
		if getfn then return getfn end

		local values = {}

		for point = 0, i - 1 do
			local compute = factorial(i - 1) / (factorial(point) * factorial(i - point - 1))
			local str = pow('inv', i - 1 - point)

			if str == '1' then str = '' end

			local powt = pow('t', point)

			if powt ~= '1' then
				if str == '' then
					str = powt
				else
					str = str .. ' * ' .. powt
				end
			end

			if compute ~= 1 then
				str = str .. ' * ' .. compute
			end

			if str == '' then
				str = 'values[' .. (point + 1) .. ']'
			else
				str = str .. ' * values[' .. (point + 1) .. ']'
			end

			table.insert(values, str)
		end

		local lines = {}
		local retstate = {}
		local nextindex = 1

		while #values ~= 0 do
			local line = {}

			for i = 1, 20 do
				local dodel = table.remove(values, 1)
				if not dodel then break end
				table.insert(line, dodel)
			end

			table.insert(lines, 'local value_' .. nextindex .. ' = ' .. table.concat(line, ' + '))
			table.insert(retstate, 'value_' .. nextindex)
			nextindex = nextindex + 1
		end

		bezier_lut[i] = CompileString([[
			local pow = math.pow

			return function(t, values)
				local inv = (1 - t)
				]] .. table.concat(lines, '\n') .. [[
				return ]] .. table.concat(retstate, ' + ') .. [[
			end
		]], 'DLib bezier curve N' .. i)()

		return bezier_lut[i]
	end

	function bake_bezier2(i)
		local getfn = bezier_lut2[i]
		if getfn then return getfn end

		local values = {}
		local args = {}

		for point = 0, i - 1 do
			local compute = factorial(i - 1) / (factorial(point) * factorial(i - point - 1))
			local str = pow('inv', i - 1 - point)

			if str == '1' then str = '' end

			local powt = pow('t', point)

			if powt ~= '1' then
				if str == '' then
					str = powt
				else
					str = str .. ' * ' .. powt
				end
			end

			if compute ~= 1 then
				str = str .. ' * ' .. compute
			end

			if str == '' then
				str = 'arg' .. (point + 1)
			else
				str = str .. ' * arg' .. (point + 1)
			end

			table.insert(args, 'arg' .. (point + 1))
			table.insert(values, str)
		end

		local lines = {}
		local retstate = {}
		local nextindex = 1

		while #values ~= 0 do
			local line = {}

			for i = 1, 20 do
				local dodel = table.remove(values, 1)
				if not dodel then break end
				table.insert(line, dodel)
			end

			table.insert(lines, 'local value_' .. nextindex .. ' = ' .. table.concat(line, ' + '))
			table.insert(retstate, 'value_' .. nextindex)
			nextindex = nextindex + 1
		end

		bezier_lut2[i] = CompileString([[
			local pow = math.pow

			return function(t, ]] .. table.concat(args, ', ') .. [[)
				local inv = (1 - t)
				]] .. table.concat(lines, '\n') .. [[
				return ]] .. table.concat(retstate, ' + ') .. [[
			end
		]], 'DLib bezier curve N' .. i)()

		return bezier_lut2[i]
	end
end

DLib.bezier_lut = bezier_lut
DLib.bezier_lut2 = bezier_lut2

--[[
	@doc
	@fname math.bezier
	@args number t, vararg numbers

	@returns
	number
]]
math.bezier = bezier

--[[
	@doc
	@fname math.tbezier
	@args number t, table numbers

	@returns
	number
]]
-- accepts table
function math.tbezier(t, values)
	return tbezier(t, values, #values)
end

--[[
	@doc
	@fname math.tformat
	@args number time

	@returns
	table: formatted table
]]
function math.tformat(time)
	local centuries, years, months, weeks, days, hours, minutes, seconds = math.tformatVararg(time)
	return {
		centuries = centuries, years = years, months = months, weeks = weeks, days = days, hours = hours, minutes = minutes, seconds = seconds
	}
end

--[[
	@doc
	@fname math.tformatVararg
	@args number time

	@returns
	number: centuries
	number: years
	number: months
	number: weeks
	number: days
	number: hours
	number: minutes
	number: seconds
]]
function math.tformatVararg(time)
	assert(type(time) == 'number', 'Invalid time provided.')

	if time > 0xFFFFFFFFFF then
		error('Value is too big! Maximum is ' .. 0xFFFFFFFFFF)
	elseif time <= 1 then
		return 0, 0, 0, 0, 0, 0, 0, 0
	end

	local centuries = (time - time % 0xBBF81E00) / 0xBBF81E00
	time = time - centuries * 0xBBF81E00

	local years = (time - time % 0x01E13380) / 0x01E13380
	time = time - years * 0x01E13380

	local months = ((time - time % 0x00278D00) / 0x00278D00):min(11)
	time = time - months * 0x00278D00

	local weeks = (time - time % 604800) / 604800
	time = time - weeks * 604800

	local days = (time - time % 86400) / 86400
	time = time - days * 86400

	local hours = (time - time % 3600) / 3600
	time = time - hours * 3600

	local minutes = (time - time % 60) / 60
	time = time - minutes * 60

	local seconds = time:floor()

	return centuries, years, months, weeks, days, hours, minutes, seconds
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

	return math.untformatVararg(time.centuries, time.years, time.months, time.weeks, time.days, time.hours, time.minutes, time.seconds)
end

--[[
	@doc
	@fname math.untformatVararg
	@args number centuries, number years, number months, number weeks, number days, number hours, number minutes, number seconds

	@desc
	reverse of time numbers format of number
	@enddesc

	@returns
	number
]]
function math.untformatVararg(centuries, years, months, weeks, days, hours, minutes, seconds)
	assert(type(centuries) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(years) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(months) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(weeks) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(days) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(hours) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(minutes) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')
	assert(type(seconds) == 'number', 'Invalid time provided. You must provide table in math.tformat output format.')

	return centuries * 0xBBF81E00
		+ years * 0x01E13380
		+ months * 0x00278D00
		+ weeks * 604800
		+ days * 86400
		+ hours * 3600
		+ minutes * 60
		+ seconds
end

do
	local daysIn = {
		31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
	}

	local _timeCached = {}
	local _timeCachedHigh = {}

	for month = 1, 12 do
		local stamp1 = 0
		local stamp2 = 0

		for _month = 1, month - 1 do
			if _month == 2 then
				stamp1 = stamp1 + 29 * 86400
				stamp2 = stamp2 + 28 * 86400
			else
				stamp1 = stamp1 + daysIn[_month] * 86400
				stamp2 = stamp2 + daysIn[_month] * 86400
			end
		end

		_timeCachedHigh[month] = stamp1
		_timeCached[month] = stamp2
	end

	local yearLength = 31536000
	local longYearLength = 31622400
	local isnumber = isnumber

	function math.dateToTimestamp(year, month, day, hour, minute, second)
		assert(isnumber(year), 'year is not a number or missing')
		assert(isnumber(month), 'month is not a number or missing')
		assert(isnumber(day), 'day is not a number or missing')
		assert(isnumber(hour), 'hour is not a number or missing')
		assert(isnumber(minute), 'minute is not a number or missing')
		assert(isnumber(second), 'second is not a number or missing')

		assert(year >= 1970, 'year < 1970 is not supported yet')
		assert(month >= 1 and month < 13, 'invalid month')
		assert(day >= 1 and day <= 31, 'invalid day')
		assert(hour >= 0 and hour <= 24, 'invalid hour')
		assert(minute >= 0 and minute <= 60, 'invalid minute')
		assert(second >= 0 and second <= 60, 'invalid second')

		local yearS, peaks, skips, shift = year - 1970, 0, 0, 0

		if year > 2000 then
			-- ???
			peaks = ((year - 1600) / 400):floor()
			yearS = yearS - peaks
			shift = -86400 * peaks

			skips = (((year - 1900) / 100):floor() - peaks):max(0)
			yearS = yearS - skips

			local peak2 = (((year - 1968) / 4):floor() - skips):max(0)
			yearS = yearS - peak2
			peaks = peaks + peak2
		elseif year < 2000 then
			peaks = ((year - 1968) / 4):floor()
			yearS = yearS - peaks
		else
			peaks = 7
			yearS = yearS - 7
		end

		return peaks * longYearLength + skips * yearLength + yearS * yearLength +
			((year % 400 == 0 or year % 100 ~= 0 and year % 4 == 0) and _timeCachedHigh[month] or _timeCached[month]) +
			(day - 1) * 86400 + hour * 3600 + minute * 60 + second + shift
	end
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
	local dlib_screenscale_mul = CreateConVar('dlib_screenscale_mul', '1', {FCVAR_ARCHIVE}, 'GUI Scale multiplier')
	DLib.dlib_screenscale_mul = dlib_screenscale_mul
	local dlib_screenscale_mul_get = dlib_screenscale_mul:GetFloat(1):max(0)
	local ScrWL = ScrWL
	local ScrHL = ScrHL
	local screenfunc

	if use_type:GetBool() then
		function screenfunc(modify)
			return ScrHL() / 480 * modify * dlib_screenscale_mul_get
		end
	else
		function screenfunc(modify)
			return ScrWL() / 640 * modify * dlib_screenscale_mul_get
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
	cvars.AddChangeCallback('dlib_screenscale_mul', function()
		dlib_screenscale_mul_get = dlib_screenscale_mul:GetFloat(1):max(0)
		DLib.TriggerScreenSizeUpdate(ScrWL(), ScrHL(), ScrWL(), ScrHL())
	end, 'DLib')

	--[[
		@doc
		@fname Panel:IsVisibleRecursive

		@desc
		whenever is panel visible to user
		@enddesc

		@returns
		boolean
	]]
	function panelMeta:IsVisibleRecursive()
		repeat
			if not self:IsVisible() then return false end
			self = self:GetParent()
		until not IsValid(self)

		return true
	end
end

local SysTime = SysTime
local coroutine = coroutine
local coroutine_yield = coroutine.yield
local coroutine_running = coroutine.running

--[[
	@doc
	@fname coroutine.syswait
	@args number seconds, vararg yield

	@desc
	like !g:coroutine.wait but use `SysTime()`
	@enddesc
]]
function coroutine.syswait(seconds, ...)
	if not isnumber(seconds) then
		error('coroutine.syswait: bad argument #1 (expected number, got ' .. type(seconds) .. ')')
	end

	local thread = assert(coroutine_running(), 'Not inside coroutine!')

	if seconds < 0 then return end
	local target = SysTime() + seconds

	while target > SysTime() do
		coroutine_yield(...)
	end
end
