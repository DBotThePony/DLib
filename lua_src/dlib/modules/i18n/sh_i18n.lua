
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
local string = string
local type = type
local error = error
local team = team
local DLib = DLib
local table = table
local IsColor = IsColor
local string_format = string.format
local pcall = pcall
local unpack = unpack
local ipairs = ipairs
local isstring = isstring

I18n._Exists = I18n._Exists or {}
I18n._ExistsNoArgs = I18n._ExistsNoArgs or {}
I18n.hashedFunc = I18n.hashedFunc or {}
I18n.HashedFunc = I18n.hashedFunc
I18n.hashedLang = I18n.hashedLang or {}
I18n.HashedLang = I18n.hashedLang
I18n.hashedLangFunc = I18n.hashedLangFunc or {}
I18n.HashedLangFunc = I18n.hashedLangFunc
I18n.hashedNoArgsLang = I18n.hashedNoArgsLang or {}
I18n.HashedNoArgsLang = I18n.hashedNoArgsLang

local _Exists = I18n._Exists
local _ExistsNoArgs = I18n._ExistsNoArgs
local HashedFunc = I18n.HashedFunc
local HashedLang = I18n.HashedLang
local HashedLangFunc = I18n.HashedLangFunc
local HashedNoArgsLang = I18n.HashedNoArgsLang

local formatters

do
	local string_rep = string.rep
	local isnumber = isnumber
	local tonumber = tonumber
	local math_floor = math.floor

	formatters = {
		['##'] = function(self)
			return {'##'}, 0
		end,

		['#E'] = function(self, ent)
			local ltype = type(ent)

			if ltype == 'Player' then
				local nick = ent:Nick()

				if ent.SteamName and ent:SteamName() ~= nick then
					nick = nick .. ' (' .. ent:SteamName() .. ')'
				end

				return {team.GetColor(ent:Team()) or Color(), nick, color_white, string_format('<%s>', ent:SteamID())}
			elseif ltype == 'Entity' then
				return {DLib.ENTITY_COLOR:Copy(), tostring(ent)}
			elseif ltype == 'NPC' then
				return {DLib.NPC_COLOR:Copy(), tostring(ent)}
			elseif ltype == 'Vehicle' then
				return {DLib.VEHICLE_COLOR:Copy(), tostring(ent)}
			elseif ltype == 'NextBot' then
				return {DLib.NEXTBOT_COLOR:Copy(), tostring(ent)}
			elseif ltype == 'Weapon' then
				return {DLib.WEAPON_COLOR:Copy(), tostring(ent)}
			else
				error('Invalid argument to #E: ' .. ltype)
			end
		end,

		-- executor
		['#e'] = function(self, ent)
			local ltype = type(ent)

			if ltype == 'Player' then
				local nick = ent:Nick()

				if ent.SteamName and ent:SteamName() ~= nick then
					nick = nick .. ' (' .. ent:SteamName() .. ')'
				end

				return {team.GetColor(ent:Team()) or Color(), nick, color_white, string_format('<%s>', ent:SteamID())}
			elseif ltype == 'Entity' and not IsValid(ent) then
				return {Color(126, 63, 255), 'Console'}
			else
				error('Invalid argument to #e (executor) - ' .. ltype .. ' (' .. tostring(ent)  .. ')')
			end
		end,

		['#C'] = function(self, color)
			if not IsColor(color) then
				error('#C must be a color! ' .. type(color) .. ' given.')
			end

			return {color}
		end,

		['#%.%d+i'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to custom #i: ' .. type(val))
			end

			return {DLib.NUMBER_COLOR:Copy(), string_format('%' .. self:sub(2, #self - 1) ..'i', val)}
		end,

		['#i'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to #i: ' .. type(val))
			end

			return {DLib.NUMBER_COLOR:Copy(), string_format('%i', val)}
		end,

		['#%.%d+f'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to custom #f: ' .. type(val))
			end

			return {DLib.NUMBER_COLOR:Copy(), string_format('%' .. self:sub(2, #self - 1) ..'f', val)}
		end,

		['#f'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to #f: ' .. type(val))
			end

			return {DLib.NUMBER_COLOR:Copy(), string_format('%f', val)}
		end,

		['#%.%d+[xX]'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to custom #x/#X: ' .. type(val))
			end

			if self[#self] == 'x' then
				return {DLib.NUMBER_COLOR:Copy(), string_format('%' .. self:sub(2, #self - 1) ..'x', val)}
			else
				return {DLib.NUMBER_COLOR:Copy(), string_format('%' .. self:sub(2, #self - 1) ..'X', val)}
			end
		end,

		['#[xX]'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to #x/#X: ' .. type(val))
			end

			if self[2] == 'x' then
				return {DLib.NUMBER_COLOR:Copy(), string_format('%x', val)}
			else
				return {DLib.NUMBER_COLOR:Copy(), string_format('%X', val)}
			end
		end,

		['#[duco]'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to #[duco]: ' .. type(val))
			end

			return {DLib.NUMBER_COLOR:Copy(), string_format('%' .. self[2], val)}
		end,

		['#b'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to #b: ' .. type(val))
			end

			local format = ''

			if val < 0 then
				val = val + 0xFFFFFFFF
			end

			val = math_floor(val)

			while val > 0 do
				local div = val % 2
				val = (val - div) / 2
				format = div .. format
			end

			return {DLib.NUMBER_COLOR:Copy(), format}
		end,

		['#%.%d+b'] = function(self, val)
			if not isnumber(val) then
				error('Invalid argument to custom #b: ' .. type(val))
			end

			local format = ''

			if val < 0 then
				val = val + 0xFFFFFFFF
			end

			val = math_floor(val)

			while val > 0 do
				local div = val % 2
				val = (val - div) / 2
				format = div .. format
			end

			local num = tonumber(self:sub(3, #self - 1))

			if #format < num then
				format = string_rep('0', num - #format) .. format
			end

			return {DLib.NUMBER_COLOR:Copy(), format}
		end,
	}
end

--[[
	@doc
	@fname DLib.I18n.Format
	@args string unformatted, Color colorDef = nil, vararg format

	@desc
	Supports colors from custom format arguments
	This is the same as creating I18n phrase with required arguments put in,
	but slower due to `unformatted` being parsed each time on call, when
	I18n phrase is parsed only once.
	Available arguments are:
	`#.0b`, `#b`, `#d`, `#u`, `#c`, `#o`, `#x`, `#.0x`, `#X`, `#.0X`, `#f`, `#.0f`, `#i`, `#.0i`, `#C` = Color, `#E` = Entity, `#e` = Command executor
	As well as all `%` arguments !g:string.format accept
	@enddesc

	@returns
	table: formatted message
	number: arguments "consumed"
]]
function I18n.Format(unformatted, defColor, ...)
	local formatTable = luatype(defColor) == 'Color'
	defColor = defColor or color_white
	local argsPos = 1
	local searchPos = 1
	local output = {}
	local args = {...}

	if not formatTable then
		table.unshift(args, defColor)
	end

	local hit = true

	while hit and searchPos ~= #unformatted do
		hit = false

		local findBest, findBestCutoff, findBestFunc, findFormatter = 0x1000000, 0x1000000

		for formatter, funcCall in pairs(formatters) do
			local findNext, findCutoff = unformatted:find(formatter, searchPos, false)

			if findNext and findBest > findNext then
				hit = true
				findBest, findBestCutoff, findBestFunc, findFormatter = findNext, findCutoff, funcCall, formatter
			end
		end

		if findBestFunc then
			local slicePre = unformatted:sub(searchPos, findBest - 1)
			local count = I18n.countExpressions(slicePre)

			if count ~= 0 then
				table.insert(output, string_format(slicePre, unpack(args, argsPos, argsPos + count - 1)))
				argsPos = argsPos + count
			else
				table.insert(output, slicePre)
			end

			local ret, grabbed = findBestFunc(unformatted:sub(findBest, findBestCutoff), unpack(args, argsPos, #args))

			if ret then
				table.append(output, ret)

				if not IsColor(ret[#ret]) then
					table.insert(output, defColor)
				end
			end

			argsPos = argsPos + (grabbed or 1)
			searchPos = findBestCutoff + 1

			if searchPos == #unformatted then
				table.insert(output, unformatted[#unformatted])

				if formatTable then
					return output, argsPos - 1
				end

				local build = ''

				for i, arg in ipairs(output) do
					if isstring(arg) then
						build = build .. arg
					end
				end

				return build, argsPos - 1
			end
		end
	end

	if searchPos ~= #unformatted then
		local slice = unformatted:sub(searchPos)
		local count = I18n.countExpressions(slice)

		if count ~= 0 then
			table.insert(output, string_format(slice, unpack(args, argsPos, argsPos + count - 1)))
			argsPos = argsPos + count
		else
			table.insert(output, slice)
		end
	end

	if formatTable then
		return output, argsPos - 1
	end

	local build = ''

	for i, arg in ipairs(output) do
		if isstring(arg) then
			build = build .. arg
		end
	end

	return build, argsPos - 1
end

function I18n._CompileExpression(unformatted)
	local searchPos = 1
	local funclist = {}
	local hit = true

	while hit and searchPos ~= #unformatted do
		hit = false

		local findBest, findBestCutoff, findBestFunc, findFormatter = 0x1000000, 0x1000000

		for formatter, funcCall in pairs(formatters) do
			local findNext, findCutoff = unformatted:find(formatter, searchPos, false)

			if findNext and findBest > findNext then
				hit = true
				findBest, findBestCutoff, findBestFunc, findFormatter = findNext, findCutoff, funcCall, formatter
			end
		end

		if findBestFunc then
			local slicePre = unformatted:sub(searchPos, findBest - 1)
			local count = I18n.countExpressions(slicePre)

			if count ~= 0 then
				table.insert(funclist, function(...)
					return string_format(slicePre, ...), count
				end)
			else
				table.insert(funclist, slicePre)
			end

			table.insert(funclist, function(...)
				local ret, count = findBestFunc(unformatted:sub(findBest, findBestCutoff), ...)
				return ret, count or 1
			end)

			searchPos = findBestCutoff + 1

			if searchPos == #unformatted then
				table.insert(funclist, unformatted[#unformatted])
				break
			end
		end
	end

	if searchPos ~= #unformatted then
		local slice = unformatted:sub(searchPos)
		local count = I18n.countExpressions(slice)

		if count ~= 0 then
			table.insert(funclist, function(...)
				return string_format(slice, ...), count
			end)
		else
			table.insert(funclist, slice)
		end
	end

	local funclist_types = {}

	for i, func in ipairs(funclist) do
		funclist_types[i] = type(func)
	end

	return function(defColor, ...)
		defColor = defColor or color_white
		local output = {}
		local argsPos = 1
		local args = {...}
		local counter = 1

		for i, func in ipairs(funclist) do
			local ftype = funclist_types[i]

			if ftype == 'string' then
				output[counter] = func
				counter = counter + 1
			else
				local fret, fcount = func(unpack(args, argsPos, #args))
				local frettype = type(fret)

				if frettype == 'string' then
					output[counter] = fret
					counter = counter + 1
					argsPos = argsPos + fcount
				elseif frettype == 'table' then
					counter = counter - 1

					for i2 = 1, #fret do
						output[counter + i2] = fret[i2]
					end

					counter = counter + #fret + 1

					if not IsColor(fret[#fret]) then
						output[counter] = defColor
						counter = counter + 1
					end

					argsPos = argsPos + fcount
				end
			end
		end

		return output, argsPos - 1
	end
end

--[[
	@doc
	@fname DLib.I18n.LocalizeByLang
	@args string phrase, any lang, vararg format

	@returns
	string: formatted message
]]
function I18n.LocalizeByLang(phrase, lang, ...)
	if not _Exists[phrase] or I18n.DEBUG_LANG_STRINGS:GetBool() then
		return phrase
	end

	local unformatted

	if not istable(lang) then
		unformatted = HashedLangFunc[lang] and HashedLangFunc[lang][phrase] or HashedLang[lang] and HashedLang[phrase]
	else
		for i, langIn in ipairs(lang) do
			unformatted = HashedLangFunc[langIn] and HashedLangFunc[langIn][phrase] or HashedLang[langIn] and HashedLang[langIn][phrase]
			if unformatted then break end
		end
	end

	if not unformatted then return phrase end

	if isfunction(unformatted) then
		local status, formatted = pcall(unformatted, nil, ...)

		if status then
			local output = ''

			for i, value in ipairs(formatted) do
				if isstring(value) then
					output = output .. value
				end
			end

			return output
		end

		return 'Format error: ' .. phrase .. ' ' .. formatted
	end

	local status, formatted = pcall(string_format, unformatted, ...)

	if status then
		return formatted
	end

	return 'Format error: ' .. phrase .. ' ' .. formatted
end

--[[
	@doc
	@fname DLib.I18n.LocalizeByLangAdvanced
	@args string phrase, string lang, Color colorDef = color_white, vararg format

	@desc
	Supports colors from custom format arguments
	You don't want to use this unless you know that
	some of phrases can contain custom format arguments
	@enddesc

	@returns
	table: formatted message
	number: arguments "consumed"
]]
function I18n.LocalizeByLangAdvanced(phrase, lang, colorDef, ...)
	if not IsColor(colorDef) then
		return I18n._localizeByLangAdvanced(phrase, lang, color_white, ...)
	else
		return I18n._localizeByLangAdvanced(phrase, lang, colorDef, ...)
	end
end

function I18n._localizeByLangAdvanced(phrase, lang, colorDef, ...)
	if not _Exists[phrase] or I18n.DEBUG_LANG_STRINGS:GetBool() then
		return {phrase}, 0
	end

	local unformatted

	if not istable(lang) then
		unformatted = HashedLangFunc[lang] and HashedLangFunc[lang][phrase] or HashedLang[lang] and HashedLang[phrase]
	else
		for i, langIn in ipairs(lang) do
			unformatted = HashedLangFunc[langIn] and HashedLangFunc[langIn][phrase] or HashedLang[langIn] and HashedLang[langIn][phrase]
			if unformatted then break end
		end
	end

	if not unformatted then return {phrase}, 0 end

	if isfunction(unformatted) then
		local status, formatted, cnum = pcall(unformatted, colorDef, ...)

		if status then
			return formatted, cnum
		end

		return {'Format error: ' .. phrase .. ' ' .. formatted}, 0
	end

	local status, formatted, cnum = pcall(string_format, unformatted, ...)

	if status then
		return {formatted}, I18n.CountExpressions(unformatted)
	end

	return {'Format error: ' .. phrase .. ' ' .. formatted}, 0
end

local string_gmatch = string.gmatch

--[[
	@doc
	@fname DLib.I18n.CountExpressions
	@args string str

	@returns
	number
]]
function I18n.CountExpressions(str)
	local i = 0
	local fn = string_gmatch(str, '[%%][^%%]')

	while fn() do
		i = i + 1
	end

	return i
end

--[[
	@doc
	@fname DLib.I18n.RegisterPhrase
	@args string lang, string phrase, string unformatted

	@deprecated
	@internal

	@returns
	boolean: true
]]
function I18n.RegisterPhrase(lang, phrase, unformatted)
	local advanced = false

	for formatter, funcCall in pairs(formatters) do
		if unformatted:find(formatter) then
			advanced = true
			break
		end
	end

	_Exists[phrase] = true

	HashedLang[lang] = HashedLang[lang] or {}
	HashedLang[lang][phrase] = unformatted

	if advanced then
		local fncompile = I18n._CompileExpression(unformatted)

		HashedLangFunc[lang] = HashedLangFunc[lang] or {}
		HashedLangFunc[lang][phrase] = fncompile
	else
		HashedLangFunc[lang] = HashedLangFunc[lang] or {}
		HashedLangFunc[lang][phrase] = nil
	end

	if I18n.CountExpressions(phrase) == 0 then
		_ExistsNoArgs[phrase] = true
		HashedNoArgsLang[lang] = HashedNoArgsLang[lang] or {}
		HashedNoArgsLang[lang][phrase] = unformatted
	else
		_ExistsNoArgs[phrase] = nil
		HashedNoArgsLang[lang] = HashedNoArgsLang[lang] or {}
		HashedNoArgsLang[lang][phrase] = nil
	end

	return true
end

--[[
	@doc
	@fname DLib.I18n.Localize
	@args string phrase, vararg format

	@returns
	string: formatted message
]]
function I18n.Localize(phrase, ...)
	return I18n.LocalizeByLang(phrase, I18n.CURRENT_LANG, ...)
end

--[[
	@doc
	@fname DLib.I18n.LocalizeAdvanced
	@args string phrase, Color colorDef = color_white, vararg format

	@desc
	Supports colors from custom format arguments
	You don't want to use this unless you know that
	some of phrases can contain custom format arguments
	@enddesc

	@returns
	table: formatted message
	number: arguments "consumed"
]]
function I18n.localizeAdvanced(phrase, colorDef, ...)
	if luatype(colorDef) ~= 'Color' then
		return I18n.localizeByLang(phrase, I18n.CURRENT_LANG, nil, ...)
	else
		return I18n.localizeByLang(phrase, I18n.CURRENT_LANG, colorDef, ...)
	end
end

--[[
	@doc
	@fname DLib.I18n.GetRaw
	@args string phrase

	@returns
	string: or nil
]]
function I18n.GetRaw(phrase)
	return I18n.GetRawByLang(phrase, I18n.CURRENT_LANG)
end

function I18n.GetRaw2(phrase)
	return I18n.GetRawByLang2(phrase, I18n.CURRENT_LANG)
end

--[[
	@doc
	@fname DLib.I18n.GetRawByLang
	@args string phrase, string lang

	@returns
	string: or nil
]]
function I18n.GetRawByLang(phrase, lang)
	return HashedLang[lang] and HashedLang[lang][phrase]
end

-- why it is here
function I18n.GetRawByLang2(phrase, lang)
	return HashedLang[lang] and HashedLang[lang][phrase] or HashedLang[phrase] and HashedLang[phrase][lang]
end

--[[
	@doc
	@fname DLib.I18n.Exists
	@alias DLib.I18n.PhrasePresent
	@alias DLib.I18n.PhraseExists
	@args string phrase

	@returns
	boolean
]]
function I18n.Exists(phrase)
	return _Exists[phrase] ~= nil
end

--[[
	@doc
	@fname DLib.I18n.SafePhrase
	@args string phrase

	@returns
	boolean
]]
function I18n.SafePhrase(phrase)
	return _ExistsNoArgs[phrase] ~= nil
end

I18n.PhrasePresent = I18n.Exists
I18n.PhraseExists = I18n.Exists

local table = table

--[[
	@doc
	@fname DLib.I18n.LocalizeTable
	@alias DLib.I18n.RebuildTable
	@args table args, Color colorDef = color_white, boolean backward = false

	@desc
	when `backward` is `true`, table will be constructed from it's end. This means that when a phrase require
	format arguments, it's arguments can be localized too (recursive localization)
	`'info.I18n.phrase_with_two_format_values', 'Player', 'info.I18n.phrase'`
	will localize both `info.I18n.phrase_with_two_format_values` and `info.I18n.phrase`
	in case if `info.I18n.phrase_with_two_format_values` hold two format values (e.g. `'%s was %s'`)
	`false` = `'Player was info.I18n.phrase'`
	`true` = `'Player was looking at phrase'`
	@enddesc

	@returns
	table: a table with localized strings. other types are untouched. does not modify original table
]]
function I18n.LocalizeTable(args, colorDef, backward)
	return I18n.RebuildTableByLang(args, I18n.CURRENT_LANG, colorDef, backward)
end

I18n.RebuildTable = I18n.LocalizeTable

--[[
	@doc
	@fname DLib.I18n.LocalizeTableByLang
	@alias DLib.I18n.RebuildTableByLang
	@args table args, string lang, Color colorDef = color_white, boolean backward = false

	@desc
	when `backward` is `true`, table will be constructed from it's end. This means that when a phrase require
	format arguments, it's arguments can be localized too (recursive localization)
	`'info.I18n.phrase_with_two_format_values', 'Player', 'info.I18n.phrase'`
	will localize both `info.I18n.phrase_with_two_format_values` and `info.I18n.phrase`
	in case if `info.I18n.phrase_with_two_format_values` hold two format values (e.g. `'%s was %s'`)
	`false` = `'Player was info.I18n.phrase'`
	`true` = `'Player was looking at phrase'`
	@enddesc

	@returns
	table: a table with localized strings. other types are untouched. does not modify original table
]]

do
	local isstring = isstring

	function I18n.LocalizeTableByLang(args, lang, colorDef, backward)
		if backward == nil then backward = false end
		local rebuild
		local i = backward and #args or 1

		if backward then
			rebuild = table.qcopy(args)

			while i > 0 do
				local arg = rebuild[i]
				local index = #rebuild - i

				if not isstring(arg) or _Exists[arg] == nil then
					i = i - 1
				else
					local phrase, consumed = I18n.LocalizeByLangAdvanced(arg, lang, colorDef, unpack(rebuild, i + 1, #rebuild))
					table.splice(rebuild, i, consumed + 1, unpack(phrase, 1, #phrase))
					i = i - 1 - consumed
				end
			end
		else
			rebuild = {}

			while i <= #args do
				local arg = args[i]

				if not isstring(arg) or _Exists[arg] == nil then
					table.insert(rebuild, arg)
					i = i + 1
				else
					local phrase, consumed = I18n.LocalizeByLangAdvanced(arg, lang, colorDef, unpack(args, i + 1, #args))
					i = i + 1 + consumed
					table.append(rebuild, phrase)
				end
			end
		end

		return rebuild
	end
end

I18n.RebuildTableByLang = I18n.LocalizeTableByLang

local gmod_language = GetConVar('gmod_language')
local LastLanguage, LastLanguageList, LANG_OVERRIDE

if CLIENT then
	LANG_OVERRIDE = CreateConVar('gmod_language_dlib_cl', 'gmod,en', {FCVAR_ARCHIVE}, 'Specifies lanuages to use, comma separated.')
else
	LANG_OVERRIDE = CreateConVar('gmod_language_dlib_sv', 'gmod,en', {FCVAR_ARCHIVE}, 'Specifies lanuages to use, comma separated.')
end

if LANG_OVERRIDE:GetString() == '' then
	LANG_OVERRIDE:SetString('gmod,en')
end

--[[
	@doc
	@fname DLib.I18n.UpdateLang

	@internal
]]
function I18n.UpdateLang()
	local grablang = LANG_OVERRIDE:GetString():lower():trim():split(',')

	for i = #grablang, 1, -1 do
		grablang[i] = grablang[i]:trim()

		if grablang[i] == '' then
			table.remove(grablang, i)
		elseif grablang[i] == 'gmod' then
			grablang[i] = gmod_language:GetString():lower():trim()
		end
	end

	I18n.CURRENT_LANG = grablang
	local recombine = table.concat(grablang, ',')

	if LastLanguage ~= table.concat(grablang, ',') then
		hook.Run('DLib.LanguageChanged2', LastLanguageList, grablang)
		hook.Run('DLib.LanguageChanged', LastLanguageList, grablang)

		LastLanguageList = grablang
		LastLanguage = recombine
	end

	if CLIENT then
		net.Start('dlib.clientlang')
		net.WriteStringArray(grablang)
		net.SendToServer()
	end
end

if CLIENT then
	cvars.AddChangeCallback('gmod_language', I18n.UpdateLang, 'DLib')
	cvars.AddChangeCallback('gmod_language_dlib_cl', I18n.UpdateLang, 'DLib')
else
	cvars.AddChangeCallback('gmod_language_dlib_sv', I18n.UpdateLang, 'DLib')

	local value = gmod_language:GetString()

	hook.Add('Think', 'dlib_gmod_language_hack', function()
		local value2 = gmod_language:GetString()

		if value2 ~= value then
			I18n.UpdateLang()
			value = value2
		end
	end)
end

timer.Simple(0, I18n.UpdateLang)
I18n.UpdateLang()
