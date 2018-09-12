
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


local lang = DLib.lang
local i18n = i18n
local string = string

i18n.hashed = i18n.hashed or {}
i18n.hashedNoArgs = i18n.hashedNoArgs or {}
i18n.hashedLang = i18n.hashedLang or {}
i18n.hashedNoArgsLang = i18n.hashedNoArgsLang or {}

function i18n.localizeByLang(phrase, lang, ...)
	if not i18n.hashed[phrase] then
		return phrase
	end

	local unformatted

	if lang == 'en' or not i18n.hashedLang[lang] then
		unformatted = i18n.hashed[phrase] or phrase
	else
		unformatted = i18n.hashedLang[lang][phrase] or i18n.hashed[phrase] or phrase
	end

	local status, formatted = pcall(string.format, unformatted, ...)

	if status then
		return formatted
	else
		return '%%!' .. phrase .. '!%%'
	end
end

function i18n.countExpressions(str)
	local i = 0

	for line in str:gmatch('[%%][^%%]') do
		i = i + 1
	end

	return i
end

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

function i18n.localize(phrase, ...)
	return i18n.localizeByLang(phrase, lang.CURRENT_LANG, ...)
end

function i18n.getRaw(phrase)
	return i18n.getRawByLang(phrase, lang.CURRENT_LANG)
end

function i18n.getRaw2(phrase)
	return i18n.getRawByLang2(phrase, lang.CURRENT_LANG)
end

function i18n.getRawByLang(phrase, lang)
	return i18n.hashedLang[lang] and i18n.hashedLang[lang][phrase] or i18n.hashed[phrase]
end

function i18n.getRawByLang2(phrase, lang)
	return i18n.hashedLang[lang] and i18n.hashedLang[lang][phrase] or i18n.hashedLang[phrase] and i18n.hashedLang[phrase][lang] or i18n.hashed[phrase]
end

function i18n.phrasePresent(phrase)
	return i18n.hashed[phrase] ~= nil
end

function i18n.safePhrase(phrase)
	return i18n.hashedNoArgs[phrase] ~= nil
end

i18n.exists = i18n.phrasePresent
i18n.phraseExists = i18n.phrasePresent

local table = table
local type = type

function i18n.rebuildTable(args)
	return i18n.rebuildTableByLang(args, lang.CURRENT_LANG)
end

function i18n.rebuildTableByLang(args, lang)
	local rebuild = {}
	local i = 1

	while i <= #args do
		local arg = args[i]

		if type(arg) ~= 'string' or not i18n.exists(arg) then
			table.insert(rebuild, arg)
			i = i + 1
		else
			local phrase = i18n.getRawByLang(arg, lang)
			local count = i18n.countExpressions(phrase)

			if count == 0 then
				table.insert(rebuild, phrase)
				i = i + 1
			else
				local arguments = {}
				local original = i
				local success = true

				for n = 1, count do
					if type(args[i + n]) ~= 'string' and type(args[i + n]) ~= 'number' then
						success = false
						i = original
						break
					end

					table.insert(arguments, args[i + n])
				end

				if success then
					table.insert(rebuild, i18n.localizeByLang(arg, lang, unpack(arguments)))
					i = i + 1 + count
				else
					table.insert(rebuild, arg)
					i = i + 1
				end
			end
		end
	end

	return rebuild
end
