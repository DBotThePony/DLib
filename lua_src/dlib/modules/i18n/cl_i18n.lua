
-- Copyright (C) 2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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
			hook.Remove('DLib.LanguageChanged2', self)
			return self:_SetTextDLib(text, ...)
		end

		hook.Add('DLib.LanguageChanged2', self, languageWatchdog)
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
			hook.Remove('DLib.LanguageChanged2', self)
			return self:_SetLabelDLib(text, ...)
		end

		hook.Add('DLib.LanguageChanged2', self, languageWatchdog)
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
			hook.Remove('DLib.LanguageChanged2', self)
			return self:_SetTooltipDLib(text, ...)
		end

		hook.Add('DLib.LanguageChanged2', self, languageWatchdog)
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
			hook.Remove('DLib.LanguageChanged2', self)
			return self:_SetTitleDLib(text, ...)
		end

		hook.Add('DLib.LanguageChanged2', self, languageWatchdog)
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
			hook.Remove('DLib.LanguageChanged2', self)
			return self:_SetNameDLib(text, ...)
		end

		hook.Add('DLib.LanguageChanged2', self, languageWatchdog)
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

local function vguiPanelCreated(self)
	if self:GetClassName():lower():find('textentry') or self:GetClassName():lower():find('input') or self:GetClassName():lower():find('editor') then return end

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

hook.Add('VGUIPanelCreated', 'DLib.I18n', vguiPanelCreated)
chat.AddTextLocalized = i18n.AddChat
