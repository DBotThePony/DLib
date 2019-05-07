
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
local string = string

i18n.hashed = i18n.hashed or {}
i18n.hashedNoArgs = i18n.hashedNoArgs or {}
i18n.hashedLang = i18n.hashedLang or {}
i18n.hashedNoArgsLang = i18n.hashedNoArgsLang or {}

local formatters = {
	['#P'] = function(ply)
		if type(ply) ~= 'Player' then
			error('Invalid argument to #P: ' .. type(ply))
		end

		local nick = ply:Nick()

		if ply.SteamName and ply:SteamName() ~= nick then
			nick = nick .. ' (' .. ply:SteamName() .. ')'
		end

		return {team.GetColor(ply:Team()) or Color(), nick, color_white, string.format('<%s>', ply:SteamID())}
	end
}

local function doLocalize(unformatted, defColor, ...)
	defColor = defColor or color_white
	local argsPos = 1
	local searchPos = 1
	local output = {}
	local args = {...}
	local hit = true

	while hit and searchPos ~= #unformatted do
		hit = false

		for formatter, funcCall in pairs(formatters) do
			local findNext, findCutoff = unformatted:find(formatter, searchPos, true)

			if findNext then
				hit = true
				local slicePre = unformatted:sub(searchPos, findNext - 1)
				local count = i18n.countExpressions(slicePre)

				if count ~= 0 then
					table.insert(output, string.format(slicePre, unpack(args, argsPos, argsPos + count - 1)))
					argsPos = argsPos + count
				else
					table.insert(output, slicePre)
				end

				local ret, grabbed = funcCall(unpack(args, argsPos, #args))
				grabbed = grabbed or 1

				if ret then
					table.append(output, ret)
					table.insert(output, defColor)
				end

				argsPos = argsPos + grabbed
				searchPos = findCutoff + 1

				if searchPos == #unformatted then
					table.insert(output, unformatted[#unformatted])
					return output, argsPos - 1
				end

				break
			end
		end
	end

	if searchPos ~= #unformatted then
		local slice = unformatted:sub(searchPos)
		local count = i18n.countExpressions(slice)

		if count ~= 0 then
			table.insert(output, string.format(slice, unpack(args, argsPos, argsPos + count - 1)))
			argsPos = argsPos + count
			return output, argsPos - 2 + count
		else
			table.insert(output, slice)
		end
	end

	return output, argsPos - 1
end

--[[
	@doc
	@fname DLib.i18n.localizeByLang
	@args string phrase, string lang, vararg format

	@returns
	string: formatted message
]]
function i18n.localizeByLang(phrase, lang, ...)
	if not i18n.hashed[phrase] or i18n.DEBUG_LANG_STRINGS:GetBool() then
		return phrase
	end

	local unformatted

	if lang == 'en' or not i18n.hashedLang[lang] then
		unformatted = i18n.hashed[phrase] or phrase
	else
		unformatted = i18n.hashedLang[lang][phrase] or i18n.hashed[phrase] or phrase
	end

	local status, formatted = pcall(doLocalize, unformatted, nil, ...)

	if status then
		local output = ''

		for i, value in ipairs(formatted) do
			if type(value) == 'string' then
				output = output .. value
			end
		end

		return output
	else
		return '%%!' .. phrase .. '!%%'
	end
end

--[[
	@doc
	@fname DLib.i18n.localizeByLangAdvanced
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
function i18n.localizeByLangAdvanced(phrase, lang, colorDef, ...)
	if luatype(colorDef) ~= 'Color' then
		return i18n._localizeByLangAdvanced(phrase, lang, color_white, ...)
	else
		return i18n._localizeByLangAdvanced(phrase, lang, colorDef, ...)
	end
end

function i18n._localizeByLangAdvanced(phrase, lang, colorDef, ...)
	if not i18n.hashed[phrase] or i18n.DEBUG_LANG_STRINGS:GetBool() then
		return {phrase}, 0
	end

	local unformatted

	if lang == 'en' or not i18n.hashedLang[lang] then
		unformatted = i18n.hashed[phrase] or phrase
	else
		unformatted = i18n.hashedLang[lang][phrase] or i18n.hashed[phrase] or phrase
	end

	local status, formatted, cnum = pcall(doLocalize, unformatted, colorDef, ...)

	if status then
		return formatted, cnum
	else
		return {'%%!' .. phrase .. '!%%'}, 0
	end
end

--[[
	@doc
	@fname DLib.i18n.countExpressions
	@args string str

	@returns
	number
]]
function i18n.countExpressions(str)
	local i = 0

	for line in str:gmatch('[%%][^%%]') do
		i = i + 1
	end

	return i
end

--[[
	@doc
	@fname DLib.i18n.registerPhrase
	@args string lang, string phrase, string unformatted

	@deprecated
	@internal

	@returns
	boolean: true
]]
function i18n.registerPhrase(lang, phrase, unformatted)
	if lang == 'en' then
		i18n.hashed[phrase] = unformatted
	else
		i18n.hashed[phrase] = i18n.hashed[phrase] or phrase
		i18n.hashedLang[lang] = i18n.hashedLang[lang] or {}
		i18n.hashedLang[lang][phrase] = unformatted
	end

	if i18n.countExpressions(phrase) == 0 then
		if lang == 'en' then
			i18n.hashedNoArgs[phrase] = unformatted
		else
			i18n.hashedNoArgsLang[lang] = i18n.hashedNoArgsLang[lang] or {}
			i18n.hashedNoArgsLang[lang][phrase] = unformatted
		end
	else
		if lang == 'en' then
			i18n.hashedNoArgs[phrase] = nil
		else
			i18n.hashedNoArgsLang[lang] = i18n.hashedNoArgsLang[lang] or {}
			i18n.hashedNoArgsLang[lang][phrase] = nil
		end
	end

	return true
end

--[[
	@doc
	@fname DLib.i18n.localize
	@args string phrase, vararg format

	@returns
	string: formatted message
]]
function i18n.localize(phrase, ...)
	return i18n.localizeByLang(phrase, i18n.CURRENT_LANG, ...)
end

--[[
	@doc
	@fname DLib.i18n.localizeAdvanced
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
function i18n.localizeAdvanced(phrase, colorDef, ...)
	if luatype(colorDef) ~= 'Color' then
		return i18n.localizeByLang(phrase, i18n.CURRENT_LANG, nil, ...)
	else
		return i18n.localizeByLang(phrase, i18n.CURRENT_LANG, colorDef, ...)
	end
end

--[[
	@doc
	@fname DLib.i18n.getRaw
	@args string phrase

	@returns
	string: or nil
]]
function i18n.getRaw(phrase)
	return i18n.getRawByLang(phrase, i18n.CURRENT_LANG)
end

--[[
	@doc
	@fname DLib.i18n.getRaw2
	@args string phrase

	@returns
	string: or nil
]]
function i18n.getRaw2(phrase)
	return i18n.getRawByLang2(phrase, i18n.CURRENT_LANG)
end


--[[
	@doc
	@fname DLib.i18n.getRawByLang
	@args string phrase, string lang

	@returns
	string: or nil
]]
function i18n.getRawByLang(phrase, lang)
	return i18n.hashedLang[lang] and i18n.hashedLang[lang][phrase] or i18n.hashed[phrase]
end

--[[
	@doc
	@fname DLib.i18n.getRawByLang2
	@args string phrase, string lang

	@returns
	string: or nil
]]
function i18n.getRawByLang2(phrase, lang)
	return i18n.hashedLang[lang] and i18n.hashedLang[lang][phrase] or i18n.hashedLang[phrase] and i18n.hashedLang[phrase][lang] or i18n.hashed[phrase]
end

--[[
	@doc
	@fname DLib.i18n.phrasePresent
	@alias DLib.i18n.exists
	@alias DLib.i18n.phraseExists
	@args string phrase

	@returns
	boolean
]]
function i18n.phrasePresent(phrase)
	return i18n.hashed[phrase] ~= nil
end

--[[
	@doc
	@fname DLib.i18n.safePhrase
	@args string phrase

	@returns
	boolean
]]
function i18n.safePhrase(phrase)
	return i18n.hashedNoArgs[phrase] ~= nil
end

i18n.exists = i18n.phrasePresent
i18n.phraseExists = i18n.phrasePresent

local table = table
local type = type

--[[
	@doc
	@fname DLib.i18n.rebuildTable
	@args table args, Color colorDef = color_white

	@returns
	table: a table with localized strings. other types are untouched. does not modify original table
]]
function i18n.rebuildTable(args, colorDef)
	return i18n.rebuildTableByLang(args, i18n.CURRENT_LANG, colorDef)
end

--[[
	@doc
	@fname DLib.i18n.rebuildTableByLang
	@args table args, string lang, Color colorDef = color_white

	@returns
	table: a table with localized strings. other types are untouched. does not modify original table
]]
function i18n.rebuildTableByLang(args, lang, colorDef)
	local rebuild = {}
	local i = 1

	while i <= #args do
		local arg = args[i]

		if type(arg) ~= 'string' or not i18n.exists(arg) then
			table.insert(rebuild, arg)
			i = i + 1
		else
			local phrase, consumed = i18n.localizeByLangAdvanced(arg, lang, colorDef, unpack(args, i + 1, #args))
			i = i + 1 + consumed
			table.append(rebuild, phrase)
		end
	end

	return rebuild
end
