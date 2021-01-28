
-- Copyright (C) 2018-2019 DBotThePony

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

local I18n = DLib.I18n
local math = math
local string = string
local string_format = string.format
local math_pow = math.pow

I18n.METRES_IN_HU = 0.0254

local prefixL = {
	{math_pow(10, -24), 'yocto'},
	{math_pow(10, -21), 'zepto'},
	{math_pow(10, -18), 'atto'},
	{math_pow(10, -15), 'femto'},
	{math_pow(10, -12), 'pico'},
	{math_pow(10, -9), 'nano'},
	{math_pow(10, -6), 'micro'},
	{math_pow(10, -3), 'milli'},
	-- {math_pow(10, -2), 'centi', true},
	-- {math_pow(10, -1), 'deci', true},
	{math_pow(10, 3), 'kilo'},
	{math_pow(10, 6), 'mega'},
	{math_pow(10, 9), 'giga'},
	{math_pow(10, 12), 'tera'},
	{math_pow(10, 15), 'peta'},
	{math_pow(10, 18), 'exa'},
	{math_pow(10, 21), 'zetta'},
	{math_pow(10, 24), 'yotta'},
}

function I18n.FormatNumImperial(numIn)
	if numIn >= -1000 and numIn <= 1000 then
		return string_format('%.2f', numIn)
	end

	return string_format('%.2fk', numIn / 1000)
end

--[[
	@doc
	@fname DLib.I18n.FormatNum
	@args number numIn

	@returns
	string
]]
function I18n.FormatNum(numIn, minFormat)
	local abs = numIn:abs()

	if abs >= (minFormat or 1) and abs <= 1000 then
		return string_format('%.2f', numIn)
	end

	local prefix, lastNum = prefixL[1][2], prefixL[1][1]

	for i, row in ipairs(prefixL) do
		if row[1] <= abs then
			prefix, lastNum = row[2], row[1]
		else
			break
		end
	end

	return string_format('%.2f%s', numIn / lastNum, I18n.localize('info.dlib.si.prefix.' .. prefix .. '.prefix'))
end

--[[
	@doc
	@fname DLib.I18n.FormatAnyBytes
	@args number numIn

	@desc
	Returns user-friendly human readable format (kb, mb, gb, ...)
	@enddesc

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatAnyBytesLong
	@args number numIn

	@desc
	Returns user-friendly human readable format (kilobytes, megabytes, gigabytes, ...)
	@enddesc

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatBytes
	@args number numIn

	@desc
	Returns human-readable bytes string (1 000 000 B)
	@enddesc

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatBytesLong
	@args number numIn

	@desc
	Returns human-readable bytes string (1 000 000 bytes)
	@enddesc

	@returns
	string
]]

do
	local kb = 1024
	local mb = math.pow(1024, 2)
	local gb = math.pow(1024, 3)
	local tb = math.pow(1024, 4)
	local pb = math.pow(1024, 5)

	function I18n.FormatAnyBytes(numIn)
		local abs = numIn:abs()

		if abs <= 1023 then
			return I18n.localize('info.dlib.si.bytes_short.bytes', numIn)
		end

		if abs >= pb then
			return I18n.Localize('info.dlib.si.bytes_short.peta', numIn / (pb))
		elseif abs >= tb then
			return I18n.Localize('info.dlib.si.bytes_short.tera', numIn / (tb))
		elseif abs >= gb then
			return I18n.Localize('info.dlib.si.bytes_short.giga', numIn / (gb))
		elseif abs >= mb then
			return I18n.Localize('info.dlib.si.bytes_short.mega', numIn / (mb))
		end

		return I18n.Localize('info.dlib.si.bytes_short.kilo', numIn / (kb))
	end

	function I18n.FormatAnyBytesLong(numIn)
		local abs = numIn:abs()

		if abs <= 1023 then
			return I18n.localize('info.dlib.si.bytes.bytes', numIn)
		end

		if abs >= pb then
			return I18n.Localize('info.dlib.si.bytes.peta', numIn / (pb))
		elseif abs >= tb then
			return I18n.Localize('info.dlib.si.bytes.tera', numIn / (tb))
		elseif abs >= gb then
			return I18n.Localize('info.dlib.si.bytes.giga', numIn / (gb))
		elseif abs >= mb then
			return I18n.Localize('info.dlib.si.bytes.mega', numIn / (mb))
		end

		return I18n.Localize('info.dlib.si.bytes.kilo', numIn / (kb))
	end

	function I18n.FormatBytes(numIn)
		local str = numIn:abs():tostring()
		local div = #str % 3

		if div ~= 0 then
			str = (div == 1 and '  ' or ' ') .. str
		end

		if numIn < 0 then
			return '-' .. I18n.localize('info.dlib.si.bytes_short.bytes', str:gsub('(...)', '%1 '):match('^%s*(.-)%s*$'))
		end

		return I18n.localize('info.dlib.si.bytes_short.bytes', str:gsub('(...)', '%1 '):match('^%s*(.-)%s*$'))
	end

	function I18n.FormatBytesLong(numIn)
		local str = numIn:abs():tostring()
		local div = #str % 3

		if div ~= 0 then
			str = (div == 1 and '  ' or ' ') .. str
		end

		if numIn < 0 then
			return '-' .. I18n.localize('info.dlib.si.bytes.bytes', str:gsub('(...)', '%1 '):match('^%s*(.-)%s*$'))
		end

		return I18n.localize('info.dlib.si.bytes.bytes', str:gsub('(...)', '%1 '):match('^%s*(.-)%s*$'))
	end

	local divs = {
		{kb, 'kilo', 'Kilobytes'},
		{mb, 'mega', 'Megabytes'},
		{gb, 'giga', 'Gigabytes'},
		{tb, 'tera', 'Terabytes'},
		{pb, 'peta', 'Petabytes'},
	}

	for i, _data in ipairs(divs) do
		local prefix1 = 'info.dlib.si.bytes_short.' .. _data[2]
		local prefix2 = 'info.dlib.si.bytes.' .. _data[2]
		local div = _data[1]

		I18n['Format' .. _data[3]] = function(numIn)
			return I18n.localize(prefix1, numIn / div)
		end

		I18n['Format' .. _data[3] .. 'Long'] = function(numIn)
			return I18n.localize(prefix2, numIn / div)
		end
	end
end

--[[
	@doc
	@fname DLib.I18n.FormatFrequency
	@args number Hz

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatForce
	@args number N

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatPressure
	@args number Pa

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatWork
	@alias DLib.I18n.FormatHeat
	@alias DLib.I18n.FormatEnergy
	@args number J

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatPower
	@args number W

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatVoltage
	@args number V

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatElectricalCapacitance
	@args number F

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatElectricalResistance
	@alias DLib.I18n.FormatImpedance
	@alias DLib.I18n.FormatReactance
	@args number Ω

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatElectricalConductance
	@args number S

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatMagneticFlux
	@args number wb

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatMagneticFluxDensity
	@alias DLib.I18n.FormatMagneticInduction
	@args number T

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatIlluminance
	@args number lx

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatRadioactivity
	@args number Bq

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatAbsorbedDose
	@args number Gy

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatEquivalentDose
	@args number Sv

	@returns
	string
]]

--[[
	@doc
	@fname DLib.I18n.FormatCatalyticActivity
	@args number kat

	@returns
	string
]]
local units = [[hertz    Hz  frequency   1/s     s−1
radian      rad     angle   m/m     1
steradian   sr      solidAngle     m2/m2   1
newton      N       force, weight   kg⋅m/s2     kg⋅m⋅s−2
pascal      Pa      pressure, stress    N/m2    kg⋅m−1⋅s−2
joule       J       energy, work, heat  N⋅m, C⋅V, W⋅s   kg⋅m2⋅s−2
watt        W       power, radiantFlux     J/s, V⋅A    kg⋅m2⋅s−3
coulomb     C       electricCharge, electricityQuantity  s⋅A, F⋅V    s⋅A
volt        V       voltage, electrical potential difference, electromotive force   W/A, J/C    kg⋅m2⋅s−3⋅A−1
farad       F       electricalCapacitance  C/V, s/Ω    kg−1⋅m−2⋅s4⋅A2
ohm         Ω       electricalResistance, impedance, reactance, resistance     1/S, V/A    kg⋅m2⋅s−3⋅A−2
siemens     S       electricalConductance  1/Ω, A/V    kg−1⋅m−2⋅s3⋅A2
weber       Wb      magneticFlux   J/A, T⋅m2   kg⋅m2⋅s−2⋅A−1
tesla       T       magneticInduction, magneticFluxDensity   V⋅s/m2, Wb/m2, N/(A⋅m)  kg⋅s−2⋅A−1
henry       H       electricalInductance   V⋅s/A, Ω⋅s, Wb/A    kg⋅m2⋅s−2⋅A−2
lumen       lm      luminous flux   cd⋅sr   cd
lux         lx      illuminance     lm/m2   cd⋅sr/m2
becquerel   Bq      radioactivity (decays per unit time)    1/s     s−1
gray        Gy      absorbedDose (of ionizing radiation)   J/kg    m2⋅s−2
sievert     Sv      equivalentDose (of ionizing radiation)     J/kg    m2⋅s−2
katal       kat     catalyticActivity  mol/s   s−1⋅mol]]

for i, row in ipairs(units:split('\n')) do
	local measure, NaM, mtype = row:match('(%S+)%s+(%S+)%s+(.+)')

	if measure and NaM and mtype then
		for i, ttype in ipairs(mtype:split(',')) do
			ttype = ttype:match('(%S+)')

			if ttype then
				I18n['Format' .. ttype:formatname()] = function(numIn)
					return string_format('%s%s',
						isnumber(numIn) and I18n.FormatNum(numIn) or numIn, I18n.Localize('info.dlib.si.units.' .. measure .. '.suffix'))
				end
			end
		end
	end
end

I18n.FormatWeight = I18n.FormatForce

I18n.TEMPERATURE_UNITS = CreateConVar('dlib_unit_system_temperature', 'C', {FCVAR_ARCHIVE}, 'C/K/F')
I18n.TEMPERATURE_UNITS_TYPE_CELSIUS = 0
I18n.TEMPERATURE_UNITS_TYPE_KELVIN = 1
I18n.TEMPERATURE_UNITS_TYPE_FAHRENHEIT = 2

--[[
	@doc
	@fname DLib.I18n.FormatTemperature
	@args number numIn, number providedType

	@desc
	`providedType` define in whcih temp units `numIn` is
	Valid values are:
	`DLib.I18n.TEMPERATURE_UNITS_TYPE_CELSIUS` (default)
	`DLib.I18n.TEMPERATURE_UNITS_TYPE_KELVIN`
	`DLib.I18n.TEMPERATURE_UNITS_TYPE_FAHRENHEIT`
	@enddesc

	@returns
	string
]]
function I18n.FormatTemperature(tempUnits, providedType)
	providedType = providedType or I18n.TEMPERATURE_UNITS_TYPE_CELSIUS

	if providedType == I18n.TEMPERATURE_UNITS_TYPE_CELSIUS then
		tempUnits = tempUnits + 273.15
	elseif providedType == I18n.TEMPERATURE_UNITS_TYPE_FAHRENHEIT then
		tempUnits = (tempUnits - 32) * 5 / 9 + 273.15
	end

	local units = I18n.TEMPERATURE_UNITS:GetString()

	if units == 'K' then
		return string_format('%s°%s', I18n.FormatNum(tempUnits, 0.01), I18n.localize('info.dlib.si.units.kelvin.suffix'))
	elseif units == 'F' then
		return string_format('%s°%s', I18n.FormatNumImperial((tempUnits - 273.15) * 9 / 5 + 32), I18n.localize('info.dlib.si.units.fahrenheit.suffix'))
	else
		return string_format('%s°%s', I18n.FormatNum(tempUnits - 273.15, 0.01), I18n.localize('info.dlib.si.units.celsius.suffix'))
	end
end

local sv_gravity = GetConVar('sv_gravity')

--[[
	@doc
	@fname DLib.I18n.FreeFallAcceleration

	@returns
	number: for use with `FormatForce` or anything like that
]]
function I18n.FreeFallAcceleration()
	return 9.8066 * sv_gravity:GetFloat() / 600
end

--[[
	@doc
	@fname DLib.I18n.FormatDistance
	@args number metresIn

	@returns
	string
]]
function I18n.FormatDistance(numIn)
	return string_format('%s%s', I18n.FormatNum(numIn), I18n.Localize('info.dlib.si.units.metre.suffix'))
end

function I18n.FormatSpeed(numIn)
	return string_format('%s%s/%s', I18n.FormatNum(numIn), I18n.Localize('info.dlib.si.units.metre.suffix'), I18n.Localize('info.dlib.si.units.second.suffix'))
end

function I18n.FormatSpeedMundane(numIn)
	return string_format('%d%s', numIn * 3.6, I18n.Localize('info.dlib.si.units.kmh.suffix'))
end

--[[
	@doc
	@fname DLib.I18n.FormatHU
	@alias DLib.I18n.FormatHammerUnits
	@args number hammerUnitsIn

	@returns
	string
]]
function I18n.FormatHU(numIn)
	return I18n.FormatDistance(numIn * I18n.METRES_IN_HU)
end

I18n.FormatHammerUnits = I18n.FormatHU

do
	local prefixL = table.Copy(prefixL)

	for i, row in ipairs(prefixL) do
		row[1] = row[1] * row[1]
	end

--[[
	@doc
	@fname DLib.I18n.FormatArea
	@args number squareMetresIn

	@returns
	string
]]
	function I18n.FormatArea(numIn)
		assert(numIn >= 0, 'Area can not be negative')

		if numIn >= 1 and numIn <= 1000 then
			return string_format('%.2fm^2', numIn)
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

		return string_format('%.2f%s%s^2',
			numIn / lastNum,
			I18n.Localize('info.dlib.si.prefix.' .. prefix .. '.prefix'),
			I18n.Localize('info.dlib.si.units.metre.suffix'))
	end

--[[
	@doc
	@fname DLib.I18n.FormatAreaHU
	@alias DLib.I18n.FormatAreaHammerUnits
	@args number squareHammerUnitsIn

	@returns
	string
]]
	function I18n.FormatAreaHU(numIn)
		return I18n.FormatArea(numIn * I18n.METRES_IN_HU)
	end

	I18n.FormatAreaHammerUnits = I18n.FormatAreaHU
end

do
	local prefixL = table.Copy(prefixL)

	for i, row in ipairs(prefixL) do
		row[1] = row[1] * row[1] * row[1]
	end

	I18n.VOLUME_UNITS = CreateConVar('dlib_unit_system_volume', '0', {FCVAR_ARCHIVE}, 'L/m')

	if I18n.VOLUME_UNITS:GetString() == 'L' then
		I18n.VOLUME_UNITS:SetString('0')
	elseif I18n.VOLUME_UNITS:GetString() == 'm' then
		I18n.VOLUME_UNITS:SetString('1')
	end

--[[
	@doc
	@fname DLib.I18n.FormatVolume
	@args number litres

	@returns
	string
]]
	function I18n.FormatVolume(litres)
		assert(litres >= 0, 'Volume can not be negative')

		if I18n.VOLUME_UNITS:GetBool() then
			local numIn = litres / 1000

			if numIn >= 0.0001 and numIn <= 1000000 then
				return string_format('%.4fm^3', numIn)
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

			return string_format('%.4f%s%s^3', numIn / lastNum, I18n.localize('info.dlib.si.prefix.' .. prefix .. '.prefix'), I18n.localize('info.dlib.si.units.metre.suffix'))
		end

		return string_format('%s%s', I18n.FormatNum(litres), I18n.localize('info.dlib.si.units.litre.suffix'))
	end

--[[
	@doc
	@fname DLib.I18n.FormatVolumeHU
	@alias DLib.I18n.FormatVolumeHammerUnits
	@args number cubicHammerUnitsIn

	@returns
	string
]]
	function I18n.FormatVolumeHU(numIn)
		return I18n.FormatVolume(numIn * I18n.METRES_IN_HU * 0.2587786259)
	end

	I18n.FormatVolumeHammerUnits = I18n.FormatVolumeHU

	cvars.AddChangeCallback('dlib_unit_system_volume', function(self, old, new)
		if new ~= '0' and new ~= '1' then
			DLib.MessageError('Invalid value for dlib_unit_system_volume specified, reverting to L (0)')
			I18n.VOLUME_UNITS:Reset()
		end
	end, 'DLib')
end

--[[
	@doc
	@fname DLib.I18n.FormatMass
	@args number kilograms

	@returns
	string
]]
function I18n.FormatMass(numIn)
	return string_format('%s%s', I18n.FormatNum(numIn * 1000), I18n.localize('info.dlib.si.units.gram.suffix'))
end

--[[
	@doc
	@fname DLib.I18n.GetNormalPressure

	@returns
	number: Pa
]]
function I18n.GetNormalPressure()
	return 101325
end

cvars.AddChangeCallback('dlib_unit_system_temperature', function(self, old, new)
	if new ~= 'C' and new ~= 'K' and new ~= 'F' then
		DLib.MessageError('Invalid value for dlib_unit_system_temperature specified, reverting to C')
		I18n.TEMPERATURE_UNITS:Reset()
	end
end, 'DLib')
