
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

local i18n = i18n
local hook = hook
local unpack = unpack

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

	local function vguiPanelCreated(self)
		if not self.SetText then return end
		if self:GetClassName():lower():find('textentry') then return end

		self._SetTextDLib = self._SetTextDLib or self.SetText
		self.SetText = SetText
	end

	hook.Add('VGUIPanelCreated', 'DLib.I18n', vguiPanelCreated)
end

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

	local function vguiPanelCreated(self)
		if not self.SetLabel then return end
		if self:GetClassName():lower():find('textentry') then return end

		self._SetLabelDLib = self._SetLabelDLib or self.SetLabel
		self.SetLabel = SetLabel
	end

	hook.Add('VGUIPanelCreated', 'DLib.I18n_Label', vguiPanelCreated)
end

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

	local function vguiPanelCreated(self)
		if not self.SetTitle then return end

		self._SetTitleDLib = self._SetTitleDLib or self.SetTitle
		self.SetTitle = SetTitle
	end

	hook.Add('VGUIPanelCreated', 'DLib.I18n_Title', vguiPanelCreated)
end
