
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
local hook = hook
local unpack = unpack

I18n.DEBUG_LANG_STRINGS = CreateConVar('gmod_language_dlib_dbg_cl', '0', {FCVAR_ARCHIVE}, 'Debug language strings (do not localize them)')

local DefaultPanelCreated

do
	local function languageWatchdog(self)
		self:_SetTextDLib(I18n.localize(self._DLibLocalizeText, unpack(self._DLibLocalizeArgsText)))
	end

	local function SetText(self, text, ...)
		if not text or not isstring(text) then
			hook.Remove('DLib.I18n.LangUpdate5', self)
			return self:_SetTextDLib(text, ...)
		end

		local text2 = text

		if text2[1] == '#' then
			text2 = text2:sub(2)
		end

		if not I18n.exists(text2) then
			hook.Remove('DLib.I18n.LangUpdate5', self)
			return self:_SetTextDLib(text, ...)
		end

		hook.Add('DLib.I18n.LangUpdate5', self, languageWatchdog)
		self._DLibLocalizeText = text2
		self._DLibLocalizeArgsText = {...}
		return self:_SetTextDLib(I18n.localize(text2, ...))
	end

	function DefaultPanelCreated(self)
		if not self.SetText then return end

		self._SetTextDLib = self._SetTextDLib or self.SetText
		self.SetText = SetText
	end
end

local LabelPanelCreated

do
	local function languageWatchdog(self)
		self:_SetLabelDLib(I18n.localize(self._DLibLocalizeLabel, unpack(self._DLibLocalizeArgsLabel)))
	end

	local function SetLabel(self, text, ...)
		if not isstring(text) or not I18n.exists(text) then
			hook.Remove('DLib.I18n.LangUpdate4', self)
			return self:_SetLabelDLib(text, ...)
		end

		hook.Add('DLib.I18n.LangUpdate4', self, languageWatchdog)
		self._DLibLocalizeLabel = text
		self._DLibLocalizeArgsLabel = {...}
		return self:_SetLabelDLib(I18n.localize(text, ...))
	end

	function LabelPanelCreated(self)
		if not self.SetLabel then return end

		self._SetLabelDLib = self._SetLabelDLib or self.SetLabel
		self.SetLabel = SetLabel
	end
end

local TooltipPanelCreated

do
	local function languageWatchdog(self)
		self:_SetTooltipDLib(I18n.localize(self._DLibLocalizeTooltip, unpack(self._DLibLocalizeArgsTooltip)))
	end

	local function SetTooltip(self, text, ...)
		if not isstring(text) or not I18n.exists(text) then
			hook.Remove('DLib.I18n.LangUpdate3', self)
			return self:_SetTooltipDLib(text, ...)
		end

		hook.Add('DLib.I18n.LangUpdate3', self, languageWatchdog)
		self._DLibLocalizeTooltip = text
		self._DLibLocalizeArgsTooltip = {...}
		return self:_SetTooltipDLib(I18n.localize(text, ...))
	end

	function TooltipPanelCreated(self)
		if not self.SetTooltip then return end

		self._SetTooltipDLib = self._SetTooltipDLib or self.SetTooltip
		self.SetTooltip = SetTooltip
	end
end

local TitlePanelCreated

do
	local function languageWatchdog(self)
		self:_SetTitleDLib(I18n.localize(self._DLibLocalizeTitle, unpack(self._DLibLocalizeArgsTitle)))
	end

	local function SetTitle(self, text, ...)
		if not isstring(text) or not I18n.exists(text) then
			hook.Remove('DLib.I18n.LangUpdate2', self)
			return self:_SetTitleDLib(text, ...)
		end

		hook.Add('DLib.I18n.LangUpdate2', self, languageWatchdog)
		self._DLibLocalizeTitle = text
		self._DLibLocalizeArgsTitle = {...}
		return self:_SetTitleDLib(I18n.localize(text, ...))
	end

	function TitlePanelCreated(self)
		if not self.SetTitle then return end

		self._SetTitleDLib = self._SetTitleDLib or self.SetTitle
		self.SetTitle = SetTitle
	end
end

local NamedPanelCreated

do
	local function languageWatchdog(self)
		self:_SetNameDLib(I18n.localize(self._DLibLocalizeName, unpack(self._DLibLocalizeArgsName)))
	end

	local function SetName(self, text, ...)
		if not isstring(text) or not I18n.exists(text) then
			hook.Remove('DLib.I18n.LangUpdate1', self)
			return self:_SetNameDLib(text, ...)
		end

		hook.Add('DLib.I18n.LangUpdate1', self, languageWatchdog)
		self._DLibLocalizeName = text
		self._DLibLocalizeArgsName = {...}
		return self:_SetNameDLib(I18n.localize(text, ...))
	end

	function NamedPanelCreated(self)
		if not self.SetName then return end

		self._SetNameDLib = self._SetNameDLib or self.SetName
		self.SetName = SetName
	end
end

-- lmao this way to workaround
hook.Add('DLib.LanguageChanged2', 'DLib.i18nPanelsBridge', function(...)
	hook.Run('DLib.I18n.LangUpdate1', ...)
	hook.Run('DLib.I18n.LangUpdate2', ...)
	hook.Run('DLib.I18n.LangUpdate3', ...)
	hook.Run('DLib.I18n.LangUpdate4', ...)
	hook.Run('DLib.I18n.LangUpdate5', ...)
end)

cvars.AddChangeCallback('gmod_language_dlib_dbg_cl', function()
	hook.Run('DLib.I18n.LangUpdate1')
	hook.Run('DLib.I18n.LangUpdate2')
	hook.Run('DLib.I18n.LangUpdate3')
	hook.Run('DLib.I18n.LangUpdate4')
	hook.Run('DLib.I18n.LangUpdate5')
end, 'DLib')

local function vguiPanelCreated(self)
	local classname = self:GetClassName():lower()
	if classname:find('textentry') or classname:lower():find('input') or classname:lower():find('editor') then return end

	DefaultPanelCreated(self)
	LabelPanelCreated(self)
	TooltipPanelCreated(self)
	TitlePanelCreated(self)
	NamedPanelCreated(self)
end


--[[
	@doc
	@fname DLib.I18n.AddChat
	@args vararg arguments

	@client
]]
function I18n.AddChat(...)
	local rebuild = I18n.RebuildTable({...})
	return chat.AddText(unpack(rebuild))
end

I18n.WatchLegacyPhrases = I18n.WatchLegacyPhrases or {}

--[[
	@doc
	@fname DLib.I18n.RegisterProxy
	@args string legacyName, string newName

	@client
	@deprecated

	@desc
	allows you to do language.Add(legacyName, localized newName) easily
	@enddesc
]]
function I18n.RegisterProxy(legacyName, newName)
	newName = newName or legacyName

	I18n.WatchLegacyPhrases[legacyName] = newName
	language.Add(legacyName, I18n.localize(newName))
end

hook.Add('DLib.LanguageChanged', 'DLib.I18n.WatchLegacyPhrases', function(...)
	for legacyName, newName in pairs(I18n.WatchLegacyPhrases) do
		language.Add(legacyName, I18n.localize(newName))
	end
end)

hook.Add('VGUIPanelCreated', 'DLib.I18n', vguiPanelCreated)
chat.AddTextLocalized = I18n.AddChat

local LANG_OVERRIDE = ConVar('gmod_language_dlib_cl')
local funcCallback

local language_codes = {
	['ab'] = {'Abkhazian', 'аҧсуа бызшәа, аҧсшәа'},
	['aa'] = {'Afar', 'Afaraf'},
	['af'] = {'Afrikaans', 'Afrikaans'},
	['ak'] = {'Akan', 'Akan'},
	['sq'] = {'Albanian', 'Shqip'},
	['am'] = {'Amharic', 'አማርኛ'},
	['ar'] = {'Arabic', 'العربية'},
	['an'] = {'Aragonese', 'aragonés'},
	['hy'] = {'Armenian', 'Հայերեն'},
	['as'] = {'Assamese', 'অসমীয়া'},
	['av'] = {'Avaric', 'авар мацӀ, магӀарул мацӀ'},
	['ae'] = {'Avestan', 'avesta'},
	['ay'] = {'Aymara', 'aymar aru'},
	['az'] = {'Azerbaijani', 'azərbaycan dili'},
	['bm'] = {'Bambara', 'bamanankan'},
	['ba'] = {'Bashkir', 'башҡорт теле'},
	['eu'] = {'Basque', 'euskara, euskera'},
	['be'] = {'Belarusian', 'беларуская мова'},
	['bn'] = {'Bengali', 'বাংলা'},
	['bh'] = {'Bihari', 'भोजपुरी'},
	['bi'] = {'Bislama', 'Bislama'},
	['bs'] = {'Bosnian', 'bosanski jezik'},
	['br'] = {'Breton', 'brezhoneg'},
	['bg'] = {'Bulgarian', 'български език'},
	['my'] = {'Burmese', 'ဗမာစာ'},
	['ca'] = {'Catalan', 'català, valencià'},
	['ch'] = {'Chamorro', 'Chamoru'},
	['ce'] = {'Chechen', 'нохчийн мотт'},
	['ny'] = {'Chichewa', 'chiCheŵa, chinyanja'},
	['zh'] = {'Chinese', '中文 (Zhōngwén), 汉语, 漢語'},
	['cv'] = {'Chuvash', 'чӑваш чӗлхи'},
	['kw'] = {'Cornish', 'Kernewek'},
	['co'] = {'Corsican', 'corsu, lingua corsa'},
	['cr'] = {'Cree', 'ᓀᐦᐃᔭᐍᐏᐣ'},
	['hr'] = {'Croatian', 'hrvatski jezik'},
	['cs'] = {'Czech', 'čeština, český jazyk'},
	['da'] = {'Danish', 'dansk'},
	['dv'] = {'Divehi', 'ދިވެހި'},
	['nl'] = {'Dutch', 'Nederlands, Vlaams'},
	['dz'] = {'Dzongkha', 'རྫོང་ཁ'},
	['en'] = {'English', 'English'},
	['eo'] = {'Esperanto', 'Esperanto'},
	['et'] = {'Estonian', 'eesti, eesti keel'},
	['ee'] = {'Ewe', 'Eʋegbe'},
	['fo'] = {'Faroese', 'føroyskt'},
	['fj'] = {'Fijian', 'vosa Vakaviti'},
	['fi'] = {'Finnish', 'suomi, suomen kieli'},
	['fr'] = {'French', 'français, langue française'},
	['ff'] = {'Fulah', 'Fulfulde, Pulaar, Pular'},
	['gl'] = {'Galician', 'Galego'},
	['ka'] = {'Georgian', 'ქართული'},
	['de'] = {'German', 'Deutsch'},
	['el'] = {'Greek', 'ελληνικά'},
	['gn'] = {'Guarani', "Avañe'ẽ"},
	['gu'] = {'Gujarati', 'ગુજરાતી'},
	['ht'] = {'Haitian', 'Kreyòl ayisyen'},
	['ha'] = {'Hausa', 'هَوُسَ (Hausa)'},
	['he'] = {'Hebrew', 'עברית'},
	['hz'] = {'Herero', 'Otjiherero'},
	['hi'] = {'Hindi', 'हिन्दी, हिंदी'},
	['ho'] = {'Hiri Motu', 'Hiri Motu'},
	['hu'] = {'Hungarian', 'magyar'},
	['ia'] = {'Interlingua', 'Interlingua'},
	['id'] = {'Indonesian', 'Bahasa Indonesia'},
	['ie'] = {'Interlingue', 'Interlingue'},
	['ga'] = {'Irish', 'Gaeilge'},
	['ig'] = {'Igbo', 'Asụsụ Igbo'},
	['ik'] = {'Inupiaq', 'Iñupiaq, Iñupiatun'},
	['io'] = {'Ido', 'Ido'},
	['is'] = {'Icelandic', 'Íslenska'},
	['it'] = {'Italian', 'Italiano'},
	['iu'] = {'Inuktitut', 'ᐃᓄᒃᑎᑐᑦ'},
	['ja'] = {'Japanese', '日本語 (にほんご)'},
	['jv'] = {'Javanese', 'ꦧꦱꦗꦮ, Basa Jawa'},
	['kl'] = {'Kalaallisut', 'kalaallisut, kalaallit oqaasii'},
	['kn'] = {'Kannada', 'ಕನ್ನಡ'},
	['kr'] = {'Kanuri', 'Kanuri'},
	['ks'] = {'Kashmiri', 'कश्मीरी, كشميري'},
	['kk'] = {'Kazakh', 'қазақ тілі'},
	['km'] = {'Central Khmer', 'ខ្មែរ, ខេមរភាសា, ភាសាខ្មែរ'},
	['ki'] = {'Kikuyu', 'Gĩkũyũ'},
	['rw'] = {'Kinyarwanda', 'Ikinyarwanda'},
	['ky'] = {'Kirghiz', 'Кыргызча, Кыргыз тили'},
	['kv'] = {'Komi', 'коми кыв'},
	['kg'] = {'Kongo', 'Kikongo'},
	['ko'] = {'Korean', 'ko-Hang|한국어}} <!-- ideograph is used in Korea-->'},
	['ku'] = {'Kurdish', 'ku-Latn|Kurdî}}, {{rtl-lang|ku-Arab|کوردی}}'},
	['kj'] = {'Kuanyama', 'Kuanyama'},
	['la'] = {'Latin', 'latine, lingua latina'},
	['lb'] = {'Luxembourgish', 'Lëtzebuergesch'},
	['lg'] = {'Ganda', 'Luganda'},
	['li'] = {'Limburgan', 'Limburgs'},
	['ln'] = {'Lingala', 'Lingála'},
	['lo'] = {'Lao', 'ພາສາລາວ'},
	['lt'] = {'Lithuanian', 'lietuvių kalba'},
	['lu'] = {'Luba-Katanga', 'Kiluba'},
	['lv'] = {'Latvian', 'latviešu valoda'},
	['gv'] = {'Manx', 'Gaelg, Gailck'},
	['mk'] = {'Macedonian', 'македонски јазик'},
	['mg'] = {'Malagasy', 'fiteny malagasy'},
	['ms'] = {'Malay', 'Bahasa Melayu, بهاس ملايو'},
	['ml'] = {'Malayalam', 'മലയാളം'},
	['mt'] = {'Maltese', 'Malti'},
	['mi'] = {'Maori', 'te reo Māori'},
	['mr'] = {'Marathi', 'मराठी'},
	['mh'] = {'Marshallese', 'Kajin M̧ajeļ'},
	['mn'] = {'Mongolian', 'Монгол хэл'},
	['na'] = {'Nauru', 'Dorerin Naoero'},
	['nv'] = {'Navajo', 'Diné bizaad'},
	['nd'] = {'North Ndebele', 'isiNdebele'},
	['ne'] = {'Nepali', 'नेपाली'},
	['ng'] = {'Ndonga', 'Owambo'},
	['nb'] = {'Norwegian Bokmål', 'Norsk Bokmål'},
	['nn'] = {'Norwegian Nynorsk', 'Norsk Nynorsk'},
	['no'] = {'Norwegian', 'Norsk'},
	['ii'] = {'Sichuan Yi', 'ꆈꌠ꒿ Nuosuhxop'},
	['nr'] = {'South Ndebele', 'isiNdebele'},
	['oc'] = {'Occitan', "occitan, lenga d'òc"},
	['oj'] = {'Ojibwa', 'ᐊᓂᔑᓈᐯᒧᐎᓐ'},
	['cu'] = {'Church&nbsp;Slavic', 'ѩзыкъ словѣньскъ'},
	['om'] = {'Oromo', 'Afaan Oromoo'},
	['or'] = {'Oriya', 'ଓଡ଼ିଆ'},
	['os'] = {'Ossetian', 'ирон æвзаг'},
	['pa'] = {'Punjabi', 'ਪੰਜਾਬੀ, پنجابی'},
	['pi'] = {'Pali', 'पालि, पाळि'},
	['fa'] = {'Persian', 'فارسی'},
	['pl'] = {'Polish', 'język polski, polszczyzna'},
	['ps'] = {'Pashto', 'پښتو'},
	['pt'] = {'Portuguese', 'Português'},
	['qu'] = {'Quechua', 'Runa Simi, Kichwa'},
	['rm'] = {'Romansh', 'Rumantsch Grischun'},
	['rn'] = {'Rundi', 'Ikirundi'},
	['ro'] = {'Romanian', 'Română'},
	['ru'] = {'Russian', 'русский'},
	['sa'] = {'Sanskrit', 'संस्कृतम्'},
	['sc'] = {'Sardinian', 'sardu'},
	['sd'] = {'Sindhi', 'सिन्धी, سنڌي، سندھی'},
	['se'] = {'Northern Sami', 'Davvisámegiella'},
	['sm'] = {'Samoan', "gagana fa'a Samoa"},
	['sg'] = {'Sango', 'yângâ tî sängö'},
	['sr'] = {'Serbian', 'српски језик'},
	['gd'] = {'Gaelic', 'Gàidhlig'},
	['sn'] = {'Shona', 'chiShona'},
	['si'] = {'Sinhala', 'සිංහල'},
	['sk'] = {'Slovak', 'Slovenčina, Slovenský Jazyk'},
	['sl'] = {'Slovenian', 'Slovenski Jezik, Slovenščina'},
	['so'] = {'Somali', 'Soomaaliga, af Soomaali'},
	['st'] = {'Southern Sotho', 'Sesotho'},
	['es'] = {'Spanish', 'Español'},
	['su'] = {'Sundanese', 'Basa Sunda'},
	['sw'] = {'Swahili', 'Kiswahili'},
	['ss'] = {'Swati', 'SiSwati'},
	['sv'] = {'Swedish', 'Svenska'},
	['ta'] = {'Tamil', 'தமிழ்'},
	['te'] = {'Telugu', 'తెలుగు'},
	['tg'] = {'Tajik', 'тоҷикӣ, toçikī, تاجیکی'},
	['th'] = {'Thai', 'ไทย'},
	['ti'] = {'Tigrinya', 'ትግርኛ'},
	['bo'] = {'Tibetan', 'བོད་ཡིག'},
	['tk'] = {'Turkmen', 'Türkmen, Түркмен'},
	['tl'] = {'Tagalog', 'Wikang Tagalog'},
	['tn'] = {'Tswana', 'Setswana'},
	['to'] = {'Tonga', 'Faka Tonga'},
	['tr'] = {'Turkish', 'Türkçe'},
	['ts'] = {'Tsonga', 'Xitsonga'},
	['tt'] = {'Tatar', 'татар теле, tatar tele'},
	['tw'] = {'Twi', 'Twi'},
	['ty'] = {'Tahitian', 'Reo Tahiti'},
	['ug'] = {'Uighur', 'ئۇيغۇرچە, Uyghurche'},
	['uk'] = {'Ukrainian', 'Українська'},
	['ur'] = {'Urdu', 'اردو'},
	['uz'] = {'Uzbek', 'Oʻzbek, Ўзбек, أۇزبېك'},
	['ve'] = {'Venda', 'Tshivenḓa'},
	['vi'] = {'Vietnamese', 'Tiếng Việt'},
	['vo'] = {'Volapük', 'Volapük'},
	['wa'] = {'Walloon', 'Walon'},
	['cy'] = {'Welsh', 'Cymraeg'},
	['wo'] = {'Wolof', 'Wollof'},
	['fy'] = {'Western Frisian', 'Frysk'},
	['xh'] = {'Xhosa', 'isiXhosa'},
	['yi'] = {'Yiddish', 'ייִדיש'},
	['yo'] = {'Yoruba', 'Yorùbá'},
	['za'] = {'Zhuang', 'Saɯ cueŋƅ, Saw cuengh'},
	['zu'] = {'Zulu', 'isiZulu'},

	['gmod'] = {"Garry's mod language", '-'},
	['en-pt'] = {"Piratespeak", "Lingo of yer crew"},
}

local force_langs = {
	gmod = true,
	['en-pt'] = true
}

function I18n.PopulateMenu(self)
	if not IsValid(self) then return end

	self:SetSkin('DLib_Black')

	self:Help('gui.dlib.menu.i18n.tooltip')

	local langlist = vgui.Create('DListView', self)
	langlist:SetSortable(false)

	langlist:AddColumn('gui.dlib.menu.i18n.lang_column')
	langlist:AddColumn('gui.dlib.menu.i18n.name_english')
	langlist:AddColumn('gui.dlib.menu.i18n.name_self')
	langlist:Dock(TOP)
	langlist:DockMargin(5, 5, 5, 0)

	langlist:SetTall(600)

	local known_languages, combobox, moveup, movedown, delete
	local ignore = false

	function funcCallback()
		if ignore then return end
		known_languages = LANG_OVERRIDE:GetString():lower():trim():split(',')

		for i = #known_languages, 1, -1 do
			known_languages[i] = known_languages[i]:trim()

			if known_languages[i] == '' then
				table.remove(known_languages, i)
			end
		end

		langlist:Clear()

		for i, lang in ipairs(known_languages) do
			local linedata = language_codes[lang]

			if linedata then
				langlist:AddLine(lang, linedata[1], linedata[2])
			else
				langlist:AddLine(lang, '-', '-')
			end
		end

		if combobox then
			combobox:Clear()

			for name, data in pairs(language_codes) do
				if not table.qhasValue(known_languages, name) and (force_langs[name] or I18n.HashedLang[name] and table.Count(I18n.HashedLang[name]) > 0 or I18n.HashedFunc[name] and table.Count(I18n.HashedFunc[name]) > 0) then
					combobox:AddChoice(string.format('%s (%s)', data[1], data[2]), name)
				end
			end
		end

		if moveup then
			moveup:SetEnabled(false)
		end

		if movedown then
			movedown:SetEnabled(false)
		end

		if delete then
			delete:SetEnabled(false)
		end
	end

	local controls = vgui.Create('EditablePanel', self)
	controls:Dock(TOP)
	controls:DockMargin(5, 5, 5, 5)

	moveup = vgui.Create('DButton', controls)
	movedown = vgui.Create('DButton', controls)
	delete = vgui.Create('DButton', controls)

	moveup:SetEnabled(false)
	movedown:SetEnabled(false)
	delete:SetEnabled(false)

	function langlist.OnRowSelected(_, index, rowPanel)
		if #known_languages <= 1 then
			moveup:SetEnabled(false)
			movedown:SetEnabled(false)
		else
			local realIndex = index
			local langText = rowPanel:GetColumnText(1)

			for i, lang in ipairs(known_languages) do
				if lang == langText then
					realIndex = i
					break
				end
			end

			moveup:SetEnabled(realIndex > 1)
			movedown:SetEnabled(realIndex < #known_languages)
		end

		delete:SetEnabled(true)
	end

	function delete.DoClick()
		local _, line = langlist:GetSelectedLine()
		if not IsValid(line) then return end

		for i, lang in ipairs(known_languages) do
			if lang == line:GetColumnText(1) then
				table.remove(known_languages, i)
				break
			end
		end

		LANG_OVERRIDE:SetString(table.concat(known_languages, ','))
	end

	function moveup.DoClick()
		local _, line = langlist:GetSelectedLine()

		if not IsValid(line) then return end
		local lineText = line:GetColumnText(1)

		for i2, panel2 in ipairs(langlist.Sorted) do
			if panel2 == line then
				local a, b = langlist.Sorted[i2 - 1], line
				langlist.Sorted[i2 - 1] = b
				langlist.Sorted[i2] = a

				langlist:SetDirty(true)
				langlist:InvalidateLayout()

				break
			end
		end

		table.Empty(known_languages)

		for i2, panel2 in ipairs(langlist.Sorted) do
			table.insert(known_languages, panel2:GetColumnText(1))
		end

		ignore = true
		LANG_OVERRIDE:SetString(table.concat(known_languages, ','))
		ignore = false

		langlist.OnRowSelected(_, -1, line)
	end

	function movedown.DoClick()
		local _, line = langlist:GetSelectedLine()

		if not IsValid(line) then return end
		local lineText = line:GetColumnText(1)

		for i2, panel2 in ipairs(langlist.Sorted) do
			if panel2 == line then
				local a, b = langlist.Sorted[i2 + 1], line
				langlist.Sorted[i2 + 1] = b
				langlist.Sorted[i2] = a

				langlist:SetDirty(true)
				langlist:InvalidateLayout()

				break
			end
		end

		table.Empty(known_languages)

		for i2, panel2 in ipairs(langlist.Sorted) do
			table.insert(known_languages, panel2:GetColumnText(1))
		end

		ignore = true
		LANG_OVERRIDE:SetString(table.concat(known_languages, ','))
		ignore = false

		langlist.OnRowSelected(_, -1, line)
	end

	moveup:Dock(LEFT)
	moveup:SetZPos(1)

	movedown:Dock(LEFT)
	movedown:SetZPos(2)

	delete:Dock(FILL)
	delete:SetZPos(3)

	moveup:SetImage('icon16/arrow_up.png')
	movedown:SetImage('icon16/arrow_down.png')
	moveup:SetText('gui.dlib.menu.i18n.move_up')
	movedown:SetText('gui.dlib.menu.i18n.move_down')
	delete:SetText('gui.misc.delete')

	moveup:DockMargin(0, 0, 2, 0)
	movedown:DockMargin(2, 0, 2, 0)
	delete:DockMargin(2, 0, 0, 0)

	controls:SetTall(30)

	local controls_add1 = vgui.Create('EditablePanel', self)
	controls_add1:Dock(TOP)
	controls_add1:DockMargin(5, 0, 5, 5)

	local controls_add2 = vgui.Create('EditablePanel', self)
	controls_add2:Dock(TOP)
	controls_add2:DockMargin(5, 0, 5, 5)

	combobox = vgui.Create('DComboBox', controls_add1)
	local add_combobox = vgui.Create('DButton', controls_add1)

	add_combobox:Dock(RIGHT)
	add_combobox:DockMargin(2, 0, 0, 0)
	combobox:Dock(FILL)

	add_combobox:SetText('gui.misc.add')

	local textfield = vgui.Create('DTextEntry', controls_add2)
	local add_textfield = vgui.Create('DButton', controls_add2)

	add_textfield:Dock(RIGHT)
	add_textfield:DockMargin(2, 0, 0, 0)

	textfield:Dock(FILL)
	textfield:SetPlaceholderText(I18n.Localize('gui.dlib.menu.i18n.iso_name'))
	textfield:SetUpdateOnType(true)

	add_textfield:SetText('gui.misc.add')

	add_combobox:SetEnabled(false)
	add_textfield:SetEnabled(false)

	function combobox.OnSelect(_, index, value, data)
		add_combobox:SetEnabled(true)
	end

	function add_combobox.DoClick()
		if LANG_OVERRIDE:GetString():trim() == '' then
			LANG_OVERRIDE:SetString(select(2, combobox:GetSelected()))
		else
			LANG_OVERRIDE:SetString(LANG_OVERRIDE:GetString() .. ',' .. select(2, combobox:GetSelected()))
		end
	end

	function textfield.OnValueChange(_, value)
		add_textfield:SetEnabled(value and value:trim() ~= '')
	end

	function textfield.OnEnter(_, value)
		if add_textfield:IsEnabled() then
			timer.Simple(0, add_textfield.DoClick)
		end
	end

	function add_textfield.DoClick()
		local getlang = textfield:GetValue():trim():lower()

		if LANG_OVERRIDE:GetString():trim() == '' then
			LANG_OVERRIDE:SetString(textfield:GetValue())
		elseif not table.qhasValue(known_languages, getlang) then
			LANG_OVERRIDE:SetString(LANG_OVERRIDE:GetString() .. ',' .. getlang)
		end

		textfield:SetValue('')
	end

	local function resize()
		add_combobox:SizeToContents()
		add_textfield:SizeToContents()

		add_combobox:SetWide(add_combobox:GetWide() + 30)
		add_textfield:SetWide(add_textfield:GetWide() + 30)

		moveup:SizeToContents()
		movedown:SizeToContents()

		local wide = math.max(moveup:GetWide(), movedown:GetWide()) + 20
		moveup:SetWide(wide)
		movedown:SetWide(wide)
	end

	hook.Add('DLib.LanguageChanged', self, resize)

	self:CheckBox('gui.dlib.menu.i18n.volume_convar', 'dlib_unit_system_volume')
	local temperature_box = self:ComboBox('gui.dlib.menu.i18n.temperature_convar', 'dlib_unit_system_temperature')

	temperature_box:AddChoice('info.dlib.si.units.kelvin.name', 'K', I18n.TEMPERATURE_UNITS:GetString() == 'K')
	temperature_box:AddChoice('info.dlib.si.units.celsius.name', 'C', I18n.TEMPERATURE_UNITS:GetString() == 'C')
	temperature_box:AddChoice('info.dlib.si.units.fahrenheit.name', 'F', I18n.TEMPERATURE_UNITS:GetString() == 'F')

	temperature_box:GetParent():SetTall(temperature_box:GetParent():GetTall() + 10)

	self:CheckBox('gui.dlib.menu.i18n.debug_convar', 'gmod_language_dlib_dbg_cl')

	resize()
	funcCallback()
end

hook.Add('PopulateToolMenu', 'DLib.I18n.Settings', function()
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'DLib.I18n.Settings', 'gui.dlib.menu.i18n.settings', '', '', I18n.PopulateMenu)
end)

cvars.AddChangeCallback('gmod_language_dlib_cl', function()
	if funcCallback then funcCallback() end
end, 'DLib Menu')
