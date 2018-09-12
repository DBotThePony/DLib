
-- Copyright (C) 2016-2018 DBot

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


local langObjectMeta = {}

function langObjectMeta:preprocess(...)
	local repack = {}

	for k, v in ipairs{...} do
		if type(v) ~= 'string' then
			table.insert(repack, v)
			goto CONTINUE
		end

		if v:sub(1, 2) == '!#' then
			table.insert(repack, v:sub(3))
			goto CONTINUE
		end

		if v:sub(1, 1) ~= '#' then
			table.insert(repack, v)
			goto CONTINUE
		end

		local raw = v:sub(2)
		local args = string.Explode('||', raw)
		local id = table.remove(args, 1)

		if self:exists(id) then
			table.insert(repack, self:getSafe(id, unpack(args)))
		else
			table.insert(repack, '<INVALID PHRASE - ' .. id .. '>')
		end

		::CONTINUE::
	end

	return repack
end

function langObjectMeta:getByLang(lang, id, ...)
	self.Phrases[lang] = self.Phrases[lang] or {}
	local phrase = self.Phrases[lang][id] or self.Phrases.en[id]
	if not phrase then error('Invalid phrase: ' .. id) end
	return string.format(phrase, ...)
end

function langObjectMeta:getByLangSafe(lang, id, ...)
	self.Phrases[lang] = self.Phrases[lang] or {}
	local phrase = self.Phrases[lang][id] or self.Phrases.en[id]
	if not phrase then return '%' .. id .. '%' end
	local status, result = pcall(string.format, phrase, ...)

	if status then
		return result
	else
		return '%' .. id .. '%'
	end
end

function langObjectMeta:get(id, ...)
	return self:getByLang(lang.CURRENT_LANG or 'en', id, ...)
end

function langObjectMeta:getSafe(id, ...)
	return self:getByLangSafe(lang.CURRENT_LANG or 'en', id, ...)
end

function langObjectMeta:exists(id)
	return ((self.Phrases[lang.CURRENT_LANG or 'en'] or self.Phrases['en'])[id] or self.Phrases['en'][id]) and true or false
end

if SERVER then
	function langObjectMeta:getPlayer(ply, id, ...)
		return self:getByLang(ply.DLib_Lang or 'en', id, ...)
	end
end

function langObjectMeta:missing(lang)
	self.Phrases[lang] = self.Phrases[lang] or {}
	local reply = {}

	for k, v in pairs(self.Phrases.en) do
		if not self.Phrases[lang][k] then
			reply[k] = v
		end
	end

	return reply
end

function langObjectMeta:register(lang, id, phrase)
	self.Phrases[lang] = self.Phrases[lang] or {}
	self.Phrases[lang][id] = phrase
end

function langObjectMeta:registerArray(lang, list)
	for key, value in pairs(list) do
		self:register(lang, key, value)
	end
end

function langObjectMeta:printMissing(lang)
	local reply = self.MissingPhrases(lang)

	for k, v in SortedPairs(reply) do
		print(k .. ' = \'' .. v:Replace('\n', '\\n') .. '\',')
	end
end

function lang.Create()
	local newObject = table.Merge({}, langObjectMeta)
	newObject.Phrases = {}
	newObject.Phrases.en = {}
	return newObject
end

function lang.exportLanguage(tableTarget, classIn)
	function tableTarget.LMessage(...)
		tableTarget.Message(unpack(classIn:preprocess({...})))
	end

	tableTarget.Lmessage = tableTarget.LMessage
	tableTarget.lmessage = tableTarget.LMessage

	if CLIENT then
		function tableTarget.LChat(...)
			tableTarget.Chat(unpack(classIn:preprocess({...})))
		end

		tableTo.LChatMessage = Chat
		tableTo.LChatPrint = Chat
		tableTo.LAddChat = Chat
		tableTo.LchatMessage = Chat
		tableTo.lchatMessage = Chat
	end
end
