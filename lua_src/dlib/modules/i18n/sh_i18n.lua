
-- Copyright (C) 2016-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local lang = DLib.lang
local i18n = i18n
local string = string

i18n.namespace = i18n.namespace or {}
i18n.hashed = i18n.hashed or {}
i18n.hashedNoArgs = i18n.hashedNoArgs or {}
i18n.hashedLang = i18n.hashedLang or {}
i18n.hashedNoArgsLang = i18n.hashedNoArgsLang or {}

function i18n.localizeByLang(phrase, lang, ...)
	if not i18n.hashed[phrase] then
		return '%%' .. phrase .. '%%'
	end

	local unformatted

	if lang == 'en' or not i18n.hashedLang[lang] then
		unformatted = i18n.hashed[phrase] or phrase
	else
		unformatted = i18n.hashedLang[lang][phrase] or i18n.hashed[phrase] or phrase
	end

	local status, formatted = pcall(string.format, phrase, ...)

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
	return i18n.hashedLang[lang] and i18n.hashedLang[lang][phrase]
end

function i18n.getRawByLang2(phrase, lang)
	return i18n.hashedLang[lang] and i18n.hashedLang[lang][phrase] or i18n.hashedLang[phrase] and i18n.hashedLang[phrase][lang]
end

function i18n.phrasePresent(phrase)
	return i18n.hashed[phrase] ~= nil
end

function i18n.safePhrase(phrase)
	return i18n.hashedNoArgs[phrase] ~= nil
end

i18n.exists = i18n.phrasePresent
