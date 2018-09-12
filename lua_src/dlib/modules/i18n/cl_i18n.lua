
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
local hook = hook
local unpack = unpack

local DefaultPanelCreated

do
	local function languageWatchdog(self)
		self:_SetTextDLib(i18n.localize(self._DLibLocalize, unpack(self._DLibLocalizeArgs)))
	end

	local function SetText(self, text, ...)
		if not i18n.exists(text) then
			hook.Remove('DLib.i18n.LangUpdate5', self)
			return self:_SetTextDLib(text, ...)
		end

		hook.Add('DLib.i18n.LangUpdate5', self, languageWatchdog)
		self._DLibLocalize = text
		self._DLibLocalizeArgs = {...}
		return self:_SetTextDLib(i18n.localize(text, ...))
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
		self:_SetLabelDLib(i18n.localize(self._DLibLocalize, unpack(self._DLibLocalizeArgs)))
	end

	local function SetLabel(self, text, ...)
		if not i18n.exists(text) then
			hook.Remove('DLib.i18n.LangUpdate4', self)
			return self:_SetLabelDLib(text, ...)
		end

		hook.Add('DLib.i18n.LangUpdate4', self, languageWatchdog)
		self._DLibLocalize = text
		self._DLibLocalizeArgs = {...}
		return self:_SetLabelDLib(i18n.localize(text, ...))
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
		self:_SetTooltipDLib(i18n.localize(self._DLibLocalize, unpack(self._DLibLocalizeArgs)))
	end

	local function SetTooltip(self, text, ...)
		if not i18n.exists(text) then
			hook.Remove('DLib.i18n.LangUpdate3', self)
			return self:_SetTooltipDLib(text, ...)
		end

		hook.Add('DLib.i18n.LangUpdate3', self, languageWatchdog)
		self._DLibLocalize = text
		self._DLibLocalizeArgs = {...}
		return self:_SetTooltipDLib(i18n.localize(text, ...))
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
		self:_SetTitleDLib(i18n.localize(self._DLibLocalize, unpack(self._DLibLocalizeArgs)))
	end

	local function SetTitle(self, text, ...)
		if not i18n.exists(text) then
			hook.Remove('DLib.i18n.LangUpdate2', self)
			return self:_SetTitleDLib(text, ...)
		end

		hook.Add('DLib.i18n.LangUpdate2', self, languageWatchdog)
		self._DLibLocalize = text
		self._DLibLocalizeArgs = {...}
		return self:_SetTitleDLib(i18n.localize(text, ...))
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
		self:_SetNameDLib(i18n.localize(self._DLibLocalize, unpack(self._DLibLocalizeArgs)))
	end

	local function SetName(self, text, ...)
		if not i18n.exists(text) then
			hook.Remove('DLib.i18n.LangUpdate1', self)
			return self:_SetNameDLib(text, ...)
		end

		hook.Add('DLib.i18n.LangUpdate1', self, languageWatchdog)
		self._DLibLocalize = text
		self._DLibLocalizeArgs = {...}
		return self:_SetNameDLib(i18n.localize(text, ...))
	end

	function NamedPanelCreated(self)
		if not self.SetName then return end

		self._SetNameDLib = self._SetNameDLib or self.SetName
		self.SetName = SetName
	end
end

-- lmao this way to workaround
hook.Add('DLib.LanguageChanged2', 'DLib.i18nPanelsBridge', function(...)
	hook.Run('DLib.i18n.LangUpdate1', ...)
	hook.Run('DLib.i18n.LangUpdate2', ...)
	hook.Run('DLib.i18n.LangUpdate3', ...)
	hook.Run('DLib.i18n.LangUpdate4', ...)
	hook.Run('DLib.i18n.LangUpdate5', ...)
end)

local function vguiPanelCreated(self)
	local classname = self:GetClassName():lower()
	if classname:find('textentry') or classname:lower():find('input') or classname:lower():find('editor') then return end

	DefaultPanelCreated(self)
	LabelPanelCreated(self)
	TooltipPanelCreated(self)
	TitlePanelCreated(self)
	NamedPanelCreated(self)
end

function i18n.AddChat(...)
	local rebuild = i18n.rebuildTable({...})
	return chat.AddText(unpack(rebuild))
end

i18n.WatchLegacyPhrases = i18n.WatchLegacyPhrases or {}

function i18n.RegisterProxy(legacyName, newName)
	newName = newName or legacyName

	i18n.WatchLegacyPhrases[legacyName] = newName
	language.Add(legacyName, i18n.localize(newName))
end

hook.Add('DLib.LanguageChanged', 'DLib.i18n.WatchLegacyPhrases', function(...)
	for legacyName, newName in pairs(i18n.WatchLegacyPhrases) do
		language.Add(legacyName, i18n.localize(newName))
	end
end)

hook.Add('VGUIPanelCreated', 'DLib.I18n', vguiPanelCreated)
chat.AddTextLocalized = i18n.AddChat
