
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
	local str = ''

	local weeks = (time - time % 604800) / 604800
	time = time - weeks * 604800

	local days = (time - time % 86400) / 86400
	time = time - days * 86400

	local hours = (time - time % 3600) / 3600
	time = time - hours * 3600

	local minutes = (time - time % 60) / 60
	time = time - minutes * 60

	local seconds = math.floor(time)

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

	return str
end

function i18n.tformat(time)
	return i18n.tformatByLang(time, i18n.CURRENT_LANG)
end
