
-- Copyright (C) 2018-2019 DBot

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

--i18n.UNIT_SYSTEM = CreateConVar('dlib_unit_system', 'si', {FCVAR_ARCHIVE}, 'Which measurement unit to use (traditional/imperial or si)')

i18n.METRES_IN_HU_SWITCH = CreateConVar('dlib_unit_system_hu', '1', {FCVAR_ARCHIVE}, 'Use default definition of Hammer Units conversion to SI (player height = 1.37m). When set to 0, non-default conversion would be used instead (player height = 1.7947m), which feel realistic')
i18n.METRES_IN_HU = 0.01905 * (i18n.METRES_IN_HU_SWITCH:GetBool() and 1.31 or 1)

local function useTraditional()
	--return i18n.UNIT_SYSTEM:GetString() == 'imperial' or i18n.UNIT_SYSTEM:GetString() == 'traditional'
	return false
end

--[[
cvars.AddChangeCallback('dlib_unit_system', function(self, old, new)
	if new ~= 'traditional' and new ~= 'imperial' and new ~= 'si' then
		DLib.MessageError('Invalid value for dlib_unit_system specified, reverting to si')
		i18n.UNIT_SYSTEM:Reset()
	end
end, 'DLib')
]]

cvars.AddChangeCallback('dlib_unit_system_hu', function(self, old, new)
	i18n.METRES_IN_HU = 0.01905 * (i18n.METRES_IN_HU_SWITCH:GetBool() and 1.31 or 1)
end, 'DLib')

local prefixL = {
	{math.pow(10, -24), 'yocto'},
	{math.pow(10, -21), 'zepto'},
	{math.pow(10, -18), 'atto'},
	{math.pow(10, -15), 'femto'},
	{math.pow(10, -12), 'pico'},
	{math.pow(10, -9), 'nano'},
	{math.pow(10, -6), 'micro'},
	{math.pow(10, -3), 'milli'},
	-- {math.pow(10, -2), 'centi', true},
	-- {math.pow(10, -1), 'deci', true},
	{math.pow(10, 3), 'kilo'},
	{math.pow(10, 6), 'mega'},
	{math.pow(10, 9), 'giga'},
	{math.pow(10, 12), 'tera'},
	{math.pow(10, 15), 'peta'},
	{math.pow(10, 18), 'exa'},
	{math.pow(10, 21), 'zetta'},
	{math.pow(10, 24), 'yotta'},
}

--[[function i18n.FormatNumImperial(numIn)
	if numIn > 1000 then
		return string.format('%.2fk', numIn / 1000)
	elseif numIn < 1 / 1000 then
		return string.format('%.2fn', numIn * 1000)
	end

	return string.format('%.2f', numIn)
end]]

function i18n.FormatNum(numIn)
	if numIn >= 1 and numIn <= 1000 then
		return string.format('%.2f', numIn)
	end

	local prefix, lastNum = prefixL[1][2], prefixL[1][1]

	for i, row in ipairs(prefixL) do
		if row[1] <= numIn then
			prefix, lastNum = row[2], row[1]
		else
			break
		end
	end

	return string.format('%.2f%s', numIn / lastNum, i18n.localize('info.dlib.si.prefix.' .. prefix .. '.prefix'))
end

local units = [[hertz    Hz  frequency   1/s     s−1
radian   rad     angle   m/m     1
steradian    sr  solid angle     m2/m2   1
newton   N   force, weight   kg⋅m/s2     kg⋅m⋅s−2
pascal   Pa  pressure, stress    N/m2    kg⋅m−1⋅s−2
joule    J   energy, work, heat  N⋅m, C⋅V, W⋅s   kg⋅m2⋅s−2
watt     W   power, radiant flux     J/s, V⋅A    kg⋅m2⋅s−3
coulomb  C   electric charge or quantity of electricity  s⋅A, F⋅V    s⋅A
volt     V   voltage, electrical potential difference, electromotive force   W/A, J/C    kg⋅m2⋅s−3⋅A−1
farad    F   electrical capacitance  C/V, s/Ω    kg−1⋅m−2⋅s4⋅A2
ohm  Ω   electrical resistance, impedance, reactance     1/S, V/A    kg⋅m2⋅s−3⋅A−2
siemens  S   electrical conductance  1/Ω, A/V    kg−1⋅m−2⋅s3⋅A2
weber    Wb  magnetic flux   J/A, T⋅m2   kg⋅m2⋅s−2⋅A−1
tesla    T   magnetic induction, magnetic flux density   V⋅s/m2, Wb/m2, N/(A⋅m)  kg⋅s−2⋅A−1
henry    H   electrical inductance   V⋅s/A, Ω⋅s, Wb/A    kg⋅m2⋅s−2⋅A−2
degree Celsius   °C  temperature relative to 273.15 K    K   K
lumen    lm  luminous flux   cd⋅sr   cd
lux  lx  illuminance     lm/m2   cd⋅sr/m2
becquerel    Bq  radioactivity (decays per unit time)    1/s     s−1
gray     Gy  absorbed dose (of ionizing radiation)   J/kg    m2⋅s−2
sievert  Sv  equivalent dose (of ionizing radiation)     J/kg    m2⋅s−2
katal    kat     catalytic activity  mol/s   s−1⋅mol]]

for i, row in ipairs(units:split('\n')) do
	local measure, NaM, mtype = row:match('(%S+)%s+(%S+)%s+(.+)')

	if measure and NaM and mtype then
		for i, ttype in ipairs(mtype:split(',')) do
			ttype = ttype:match('(%S+)')

			if ttype then
				i18n['Format' .. ttype:formatname()] = function(numIn)
					return string.format('%s%s', type(numIn) == 'number' and i18n.FormatNum(numIn) or numIn, i18n.localize('info.dlib.si.units.' .. measure .. '.suffix'))
				end
			end
		end
	end
end

--i18n.TEMPERATURE_UNITS = CreateConVar('dlib_unit_system_temperature', 'inherit', {FCVAR_ARCHIVE}, 'inherit/C/K/F')
i18n.TEMPERATURE_UNITS = CreateConVar('dlib_unit_system_temperature', 'C', {FCVAR_ARCHIVE}, 'C/K/F')
i18n.TEMPERATURE_UNITS_TYPE_CELSIUS = 0
i18n.TEMPERATURE_UNITS_TYPE_KELVIN = 1
i18n.TEMPERATURE_UNITS_TYPE_FAHRENHEIT = 2

function i18n.FormatTemperature(tempUnits, providedType)
	providedType = providedType or i18n.TEMPERATURE_UNITS_TYPE_CELSIUS

	if providedType == i18n.TEMPERATURE_UNITS_TYPE_CELSIUS then
		tempUnits = tempUnits + 273.15
	elseif providedType == i18n.TEMPERATURE_UNITS_TYPE_FAHRENHEIT then
		tempUnits = (tempUnits - 32) * 5 / 9 + 273.15
	end

	local units = i18n.TEMPERATURE_UNITS:GetString()

	if units == 'inherit' then
		units = useTraditional() and 'F' or 'K'
	end

	if units == 'K' then
		return string.format('%s°%s', i18n.FormatNum(tempUnits), i18n.localize('info.dlib.si.units.kelvin.suffix'))
	elseif units == 'F' then
		return string.format('%s°%s', i18n.FormatNumImperial(tempUnits * 9 / 5 + 32), i18n.localize('info.dlib.si.units.fahrenheit.suffix'))
	else
		return string.format('%s°%s', i18n.FormatNum(tempUnits - 273.15), i18n.localize('info.dlib.si.units.celsius.suffix'))
	end
end

local sv_gravity = GetConVar('sv_gravity')

function i18n.FreeFallAcceleration()
	return 9.8066 * sv_gravity:GetFloat() / 600
end

local inchesandstuff = {}
table.insert(inchesandstuff, {'p', 0.000352778, 6})
table.insert(inchesandstuff, {'P/', 0.000352778 * 12, 24})
table.insert(inchesandstuff, {'"', 0.000352778 * 12 * 6, 6})
table.insert(inchesandstuff, {'\'', 0.000352778 * 12 * 6 * 12, 12})
table.insert(inchesandstuff, {'yd', 0.000352778 * 12 * 6 * 12 * 3, 800})
table.insert(inchesandstuff, {'mi', 0.000352778 * 12 * 6 * 12 * 3 * 1760})

for i, row in ipairs(inchesandstuff) do
	if row[3] then
		row[3] = row[2] * row[3]
	end
end

function i18n.FormatDistance(numIn)
	if useTraditional() then
		local suffix, lastNum = inchesandstuff[1][1], inchesandstuff[1][2]

		for i, row in ipairs(inchesandstuff) do
			if row[2] <= numIn then
				suffix, lastNum = row[1], row[2]

				if row[3] and row[3] >= numIn then break end
			else
				break
			end
		end

		return string.format('%.2f%s', numIn / lastNum, suffix)
	end

	return string.format('%s%s', i18n.FormatNum(numIn), i18n.localize('info.dlib.si.units.metre.suffix'))
end

function i18n.FormatHU(numIn)
	return i18n.FormatDistance(numIn * i18n.METRES_IN_HU)
end

i18n.FormatHammerUnits = i18n.FormatHU

do
	local prefixL = table.Copy(prefixL)
	local inchesandstuff = {}

	do
		local ft = 0.09290341
		table.insert(inchesandstuff, {'ft', ft})
		table.insert(inchesandstuff, {'ch', 404.6873})
		table.insert(inchesandstuff, {'mi', 4046.873 * 640})
		table.insert(inchesandstuff, {'twp', 4046.873 * 640 * 36})
	end

	for i, row in ipairs(prefixL) do
		row[1] = row[1]:pow(2)
	end

	function i18n.FormatArea(numIn)
		--[[if numIn < 0 then
			error('are you high')
		end]]

		if useTraditional() then
			local suffix, lastNum = inchesandstuff[1][1], inchesandstuff[1][2]

			for i, row in ipairs(inchesandstuff) do
				if row[2] <= numIn then
					suffix, lastNum = row[1], row[2]

					if row[3] and row[3] >= numIn then break end
				else
					break
				end
			end

			if suffix == 'ch' and numIn / lastNum > 200 then
				suffix = 'mi'
				lastNum = inchesandstuff[3][2]
			end

			return string.format('%.2f%s^2', numIn / lastNum, suffix)
		end

		if numIn >= 1 and numIn <= 1000 then
			return string.format('%.2fm^2', numIn)
		end

		local index = 1

		for i, row in ipairs(prefixL) do
			if row[1] <= numIn then
				index = i
			else
				break
			end
		end

		local lastNum, prefix = prefixL[index][1], prefixL[index][2]

		if numIn / lastNum > 10000 and index < #prefixL then
			index = index + 1
			lastNum, prefix = prefixL[index][1], prefixL[index][2]
		end

		return string.format('%.2f%s%s^2', numIn / lastNum, i18n.localize('info.dlib.si.prefix.' .. prefix .. '.prefix'), i18n.localize('info.dlib.si.units.metre.suffix'))
	end

	function i18n.FormatAreaHU(numIn)
		return i18n.FormatArea(numIn * i18n.METRES_IN_HU)
	end

	i18n.FormatAreaHammerUnits = i18n.FormatAreaHU
end

do
	local prefixL = table.Copy(prefixL)
	local inchesandstuff = {}

	do
		--[[local inch = 16.387064 / 1000
		table.insert(inchesandstuff, {'in', inch})
		table.insert(inchesandstuff, {'ft', inch * 1728})
		table.insert(inchesandstuff, {'yd', inch * 1728 * 27})]]

		--[[local tsp = 4.92892159375 / 1000
		table.insert(inchesandstuff, {'tsp', tsp})
		table.insert(inchesandstuff, {'Tbsp', tsp * 3})
		table.insert(inchesandstuff, {'fl oz', tsp * 3 * 2})
		table.insert(inchesandstuff, {'cp', tsp * 3 * 2 * 8})]]

	end

	for i, row in ipairs(prefixL) do
		row[1] = row[1]:pow(3)
	end

	i18n.VOLUME_UNITS = CreateConVar('dlib_unit_system_volume', 'L', {FCVAR_ARCHIVE}, 'L/m')

	function i18n.FormatVolume(litres)
		--[[if numIn < 0 then
			error('are you high')
		end]]

		if useTraditional() then
			local suffix, lastNum = inchesandstuff[1][1], inchesandstuff[1][2]

			for i, row in ipairs(inchesandstuff) do
				if row[2] <= numIn then
					suffix, lastNum = row[1], row[2]

					if row[3] and row[3] >= numIn then break end
				else
					break
				end
			end

			if suffix == 'ch' and numIn / lastNum > 200 then
				suffix = 'mi'
				lastNum = inchesandstuff[3][2]
			end

			return string.format('%.2f%s', numIn / lastNum, suffix)
		end

		if i18n.VOLUME_UNITS:GetString() == 'm' then
			local numIn = litres / 1000

			if numIn >= 0.0001 and numIn <= 1000000 then
				return string.format('%.4fm^3', numIn)
			end

			local index = 1

			for i, row in ipairs(prefixL) do
				if row[1] <= numIn then
					index = i
				else
					break
				end
			end

			local lastNum, prefix = prefixL[index][1], prefixL[index][2]

			if numIn / lastNum > 10000 and index < #prefixL then
				index = index + 1
				lastNum, prefix = prefixL[index][1], prefixL[index][2]
			end

			return string.format('%.4f%s%s^3', numIn / lastNum, i18n.localize('info.dlib.si.prefix.' .. prefix .. '.prefix'), i18n.localize('info.dlib.si.units.metre.suffix'))
		end

		return string.format('%s%s', i18n.FormatNum(litres), i18n.localize('info.dlib.si.units.litre.suffix'))
	end

	function i18n.FormatVolumeHU(numIn)
		return i18n.FormatVolume(numIn * i18n.METRES_IN_HU / 1000)
	end

	i18n.FormatVolumeHammerUnits = i18n.FormatVolumeHU

	cvars.AddChangeCallback('dlib_unit_system_volume', function(self, old, new)
		if new ~= 'L' and new ~= 'm' then
			DLib.MessageError('Invalid value for dlib_unit_system_volume specified, reverting to L')
			i18n.VOLUME_UNITS:Reset()
		end
	end, 'DLib')
end

local inchesandstuff = {}
table.insert(inchesandstuff, {'gr', 64.798 / 1000, 20})
table.insert(inchesandstuff, {'dr', 1.771, 16})
table.insert(inchesandstuff, {'oz', 1.771 * 16, 16})
table.insert(inchesandstuff, {'lb', 1.771 * 16 * 16, 400})
table.insert(inchesandstuff, {'cwt', 1.771 * 16 * 16 * 100, 200})
table.insert(inchesandstuff, {'ton', 1.771 * 16 * 16 * 100 * 20})

for i, row in ipairs(inchesandstuff) do
	if row[3] then
		row[3] = row[2] * row[3]
	end
end

function i18n.FormatWeight(numIn)
	if useTraditional() then
		local suffix, lastNum = inchesandstuff[1][1], inchesandstuff[1][2]

		for i, row in ipairs(inchesandstuff) do
			if row[2] <= numIn then
				suffix, lastNum = row[1], row[2]

				if row[3] and row[3] >= numIn then break end
			else
				break
			end
		end

		return string.format('%.2f%s', numIn / lastNum, suffix)
	end

	return string.format('%s%s', i18n.FormatNum(numIn), i18n.localize('info.dlib.si.units.gram.suffix'))
end

function i18n.GetNormalPressure()
	return 101325
end

cvars.AddChangeCallback('dlib_unit_system_temperature', function(self, old, new)
	--if new ~= 'inherit' and new ~= 'C' and new ~= 'K' and new ~= 'F' then
	if new ~= 'C' and new ~= 'K' and new ~= 'F' then
		DLib.MessageError('Invalid value for dlib_unit_system_temperature specified, reverting to C')
		i18n.TEMPERATURE_UNITS:Reset()
	end
end, 'DLib')
