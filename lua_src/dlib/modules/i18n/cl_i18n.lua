
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

	self._SetTextDLib = self._SetTextDLib or self.SetText
	self.SetText = SetText
end

hook.Add('VGUIPanelCreated', 'DLib.I18n', vguiPanelCreated)
