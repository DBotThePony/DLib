
-- Copyright (C) 2018-2020 DBotThePony

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
local DLib = DLib
local assert = assert
local type = type

--[[
	@doc
	@fname DLib.I18n.FormatTimeByLang
	@args number time, string lang, boolean ago = false

	@returns
	string: formatted time in selected locale
]]
function I18n.FormatTimeByLang(time, lang, ago)
	assert(type(time) == 'number', 'Invalid time specified')

	if time > 0xFFFFFFFFF then
		return I18n.LocalizeByLang('info.dlib.tformat.long', lang)
	elseif time <= 1 and time >= 0 then
		return I18n.LocalizeByLang('info.dlib.tformat.now', lang)
	--elseif time < 0 and not ago then
	--  return I18n.LocalizeByLang('info.dlib.tformat.past', lang)
	end

	local str = ''
	local suffix = ago and '_ago' or ''

	local centuries, years, months, weeks, days, hours, minutes, seconds = math.tformatVararg(time:abs())

	if seconds ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.second.' .. seconds, lang)
	end

	if minutes ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.minute.' .. minutes, lang) .. ' ' .. str
	end

	if hours ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.hour.' .. hours, lang) .. ' ' .. str
	end

	if days ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.day.' .. days, lang) .. ' ' .. str
	end

	if weeks ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.week.' .. weeks, lang) .. ' ' .. str
	end

	if months ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.month.' .. months, lang) .. ' ' .. str
	end

	if years ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.year.' .. years, lang) .. ' ' .. str
	end

	if centuries ~= 0 then
		str = I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.century.' .. centuries, lang) .. ' ' .. str
	end

	return ago and I18n.LocalizeByLang('info.dlib.tformat.ago' .. (time < 0 and '_inv' or ''), lang, str) or time < 0 and ('-(' .. str .. ')') or str
end

I18n.tformatByLang = I18n.FormatTimeByLang

--[[
	@doc
	@fname DLib.I18n.FormatTimeTableByLang
	@args number time, string lang, boolean ago = false

	@returns
	table: array of formatted time in selected locale
]]
function I18n.FormatTimeTableByLang(time, lang, ago)
	assert(type(time) == 'number', 'Invalid time specified')

	if time > 0xFFFFFFFFF then
		return {I18n.LocalizeByLang('info.dlib.tformat.long', lang)}
	elseif time <= 1 and time >= 0 then
		return {I18n.LocalizeByLang('info.dlib.tformat.now', lang)}
	elseif time < 0 then
		return {I18n.LocalizeByLang('info.dlib.tformat.past', lang)}
	end

	local str = {}
	local suffix = ago and '_ago' or ''

	local centuries, years, months, weeks, days, hours, minutes, seconds = math.tformatVararg(time)

	if seconds ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.second.' .. seconds, lang))
	end

	if minutes ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.minute.' .. minutes, lang))
	end

	if hours ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.hour.' .. hours, lang))
	end

	if days ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.day.' .. days, lang))
	end

	if weeks ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.week.' .. weeks, lang))
	end

	if months ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.month.' .. months, lang))
	end

	if years ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.year.' .. years, lang))
	end

	if centuries ~= 0 then
		table.insert(str, I18n.LocalizeByLang('info.dlib.tformat.countable' .. suffix .. '.century.' .. centuries, lang))
	end

	return str
end

I18n.tformatTableByLang = I18n.FormatTimeTableByLang

--[[
	@doc
	@fname DLib.I18n.FormatTimeTableRaw
	@args number time

	@returns
	table: for use in functions like DLib.LMessage/AddonSpace.LMessage/I18n.AddChat
]]
function I18n.FormatTimeTableRaw(time, ago)
	assert(type(time) == 'number', 'Invalid time specified')

	if time > 0xFFFFFFFFF then
		return {'info.dlib.tformat.long'}
	elseif time <= 1 and time >= 0 then
		return {'info.dlib.tformat.now'}
	--elseif time < 0 then
	--  return {'info.dlib.tformat.past'}
	end

	local suffix = ago and '_ago' or ''
	local str = {}
	local centuries, years, months, weeks, days, hours, minutes, seconds = math.tformatVararg(time:abs())

	if ago then
		table.insert(str, 'info.dlib.tformat.ago' .. (time < 0 and '_inv' or ''))
	end

	if time < 0 then
		table.insert(str, '-(')
	end

	if seconds ~= 0 then
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.second.' .. seconds)
	end

	if minutes ~= 0 then
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.minute.' .. minutes)
	end

	if hours ~= 0 then
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.hour.' .. hours)
	end

	if days ~= 0 then
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.day.' .. days)
	end

	if weeks ~= 0 then
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.week.' .. weeks)
	end

	if months ~= 0 then
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.month.' .. months)
	end

	if years ~= 0 then
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.year.' .. years)
	end

	if centuries ~= 0 then
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.countable' .. suffix .. '.century.' .. centuries)
	end

	if time < 0 then
		table.insert(str, ')')
	end

	return str
end

I18n.tformatRawTable = I18n.FormatTimeTableRaw

--[[
	@doc
	@fname DLib.I18n.FormatTime
	@args number time, boolean ago = false

	@returns
	string: formatted time
]]
function I18n.FormatTime(time, ago)
	return I18n.FormatTimeByLang(time, I18n.CURRENT_LANG, ago)
end

I18n.tformat = I18n.FormatTime

--[[
	@doc
	@fname DLib.I18n.FormatTimeTable
	@args number time, boolean ago = false

	@returns
	table: formatted time
]]
function I18n.FormatTimeTable(time, ago)
	return I18n.FormatTimeTableByLang(time, I18n.CURRENT_LANG, ago)
end

I18n.tformatTable = I18n.FormatTimeTable

--[[
	@doc
	@fname DLib.I18n.tformatFor
	@args Player ply, number time, boolean ago = false

	@returns
	string: formatted time in player's locale
]]
function I18n.FormatTimeForPlayer(ply, time, ago)
	return I18n.FormatTimeByLang(time, assert(type(ply) == 'Player' and ply, 'Invalid player provided').DLib_Lang or I18n.CURRENT_LANG)
end

I18n.tformatFor = I18n.FormatTimeForPlayer

--[[
	@doc
	@fname DLib.I18n.FormatTimeTableForPlayer
	@args Player ply, number time, boolean ago = false

	@returns
	table: formatted time in player's locale
]]
function I18n.FormatTimeTableForPlayer(ply, time, ago)
	return I18n.FormatTimeTableByLang(time, assert(type(ply) == 'Player' and ply, 'Invalid player provided').DLib_Lang or I18n.CURRENT_LANG)
end

I18n.tformatTableFor = I18n.FormatTimeTableForPlayer
