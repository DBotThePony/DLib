
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

local i18n = i18n
local DLib = DLib
local assert = assert
local type = type

function i18n.tformatByLang(time, lang)
	assert(type(time) == 'number', 'Invalid time specified')

	if time > 0xFFFFFFFFF then
		return i18n.localizeByLang('info.dlib.tformat.long', lang)
	elseif time <= 1 and time >= 0 then
		return i18n.localizeByLang('info.dlib.tformat.now', lang)
	elseif time < 0 then
		return i18n.localizeByLang('info.dlib.tformat.past', lang)
	end

	local str = ''

	local tformat = math.tformat(time)
	local centuries = tformat.centuries
	local years = tformat.years
	local months = tformat.months
	local weeks = tformat.weeks
	local days = tformat.days
	local hours = tformat.hours
	local minutes = tformat.minutes
	local seconds = tformat.seconds

	if seconds ~= 0 then
		str = seconds .. ' ' .. i18n.localizeByLang('info.dlib.tformat.seconds', lang)
	end

	if minutes ~= 0 then
		str = minutes .. ' ' .. i18n.localizeByLang('info.dlib.tformat.minutes', lang) .. ' ' .. str
	end

	if hours ~= 0 then
		str = hours .. ' ' .. i18n.localizeByLang('info.dlib.tformat.hours', lang) .. ' ' .. str
	end

	if days ~= 0 then
		str = days .. ' ' .. i18n.localizeByLang('info.dlib.tformat.days', lang) .. ' ' .. str
	end

	if weeks ~= 0 then
		str = weeks .. ' ' .. i18n.localizeByLang('info.dlib.tformat.weeks', lang) .. ' ' .. str
	end

	if months ~= 0 then
		str = months .. ' ' .. i18n.localizeByLang('info.dlib.tformat.months', lang) .. ' ' .. str
	end

	if years ~= 0 then
		str = years .. ' ' .. i18n.localizeByLang('info.dlib.tformat.years', lang) .. ' ' .. str
	end

	if centuries ~= 0 then
		str = years .. ' ' .. i18n.localizeByLang('info.dlib.tformat.centuries', lang) .. ' ' .. str
	end

	return str
end

function i18n.tformatTableByLang(time, lang)
	assert(type(time) == 'number', 'Invalid time specified')

	if time > 0xFFFFFFFFF then
		return {i18n.localizeByLang('info.dlib.tformat.long', lang)}
	elseif time <= 1 and time >= 0 then
		return {i18n.localizeByLang('info.dlib.tformat.now', lang)}
	elseif time < 0 then
		return {i18n.localizeByLang('info.dlib.tformat.past', lang)}
	end

	local str = {}

	local tformat = math.tformat(time)
	local centuries = tformat.centuries
	local years = tformat.years
	local months = tformat.months
	local weeks = tformat.weeks
	local days = tformat.days
	local hours = tformat.hours
	local minutes = tformat.minutes
	local seconds = tformat.seconds

	if centuries ~= 0 then
		table.insert(str, years .. ' ' .. i18n.localizeByLang('info.dlib.tformat.centuries', lang))
	end

	if years ~= 0 then
		table.insert(str, years .. ' ' .. i18n.localizeByLang('info.dlib.tformat.years', lang))
	end

	if months ~= 0 then
		table.insert(str, months .. ' ' .. i18n.localizeByLang('info.dlib.tformat.months', lang))
	end

	if weeks ~= 0 then
		table.insert(str, weeks .. ' ' .. i18n.localizeByLang('info.dlib.tformat.weeks', lang))
	end

	if days ~= 0 then
		table.insert(str, days .. ' ' .. i18n.localizeByLang('info.dlib.tformat.days', lang))
	end

	if hours ~= 0 then
		table.insert(str, hours .. ' ' .. i18n.localizeByLang('info.dlib.tformat.hours', lang))
	end

	if minutes ~= 0 then
		table.insert(str, minutes .. ' ' .. i18n.localizeByLang('info.dlib.tformat.minutes', lang))
	end

	if seconds ~= 0 then
		table.insert(str, seconds .. ' ' .. i18n.localizeByLang('info.dlib.tformat.seconds', lang))
	end

	return str
end

function i18n.tformatRawTable(time)
	assert(type(time) == 'number', 'Invalid time specified')

	if time > 0xFFFFFFFFF then
		return {'info.dlib.tformat.long'}
	elseif time <= 1 and time >= 0 then
		return {'info.dlib.tformat.now'}
	elseif time < 0 then
		return {'info.dlib.tformat.past'}
	end

	local str = {}

	local tformat = math.tformat(time)
	local centuries = tformat.centuries
	local years = tformat.years
	local months = tformat.months
	local weeks = tformat.weeks
	local days = tformat.days
	local hours = tformat.hours
	local minutes = tformat.minutes
	local seconds = tformat.seconds

	if centuries ~= 0 then
		table.insert(str, ' ')
		table.insert(str, centuries)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.centuries')
	end

	if years ~= 0 then
		table.insert(str, ' ')
		table.insert(str, years)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.years')
	end

	if months ~= 0 then
		table.insert(str, ' ')
		table.insert(str, months)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.months')
	end

	if weeks ~= 0 then
		table.insert(str, ' ')
		table.insert(str, weeks)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.weeks')
	end

	if days ~= 0 then
		table.insert(str, ' ')
		table.insert(str, days)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.days')
	end

	if hours ~= 0 then
		table.insert(str, ' ')
		table.insert(str, hours)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.hours')
	end

	if minutes ~= 0 then
		table.insert(str, ' ')
		table.insert(str, minutes)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.minutes')
	end

	if seconds ~= 0 then
		table.insert(str, ' ')
		table.insert(str, seconds)
		table.insert(str, ' ')
		table.insert(str, 'info.dlib.tformat.seconds')
	end

	return str
end

function i18n.tformat(time)
	return i18n.tformatByLang(time, i18n.CURRENT_LANG)
end

function i18n.tformatTable(time)
	return i18n.tformatTableByLang(time, i18n.CURRENT_LANG)
end

function i18n.tformatFor(ply, time)
	return i18n.tformatByLang(time, assert(type(ply) == 'Player' and ply, 'Invalid player provided').DLib_Lang or i18n.CURRENT_LANG)
end

function i18n.tformatTableFor(ply, time)
	return i18n.tformatTableByLang(time, assert(type(ply) == 'Player' and ply, 'Invalid player provided').DLib_Lang or i18n.CURRENT_LANG)
end
