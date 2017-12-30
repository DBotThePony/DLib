
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

local LangSetup, gmod_language, LastLanguage

function lang.update()
	LangSetup = true
	gmod_language = gmod_language or GetConVar('gmod_language')
	if not gmod_language then return end
	lang.CURRENT_LANG = gmod_language:GetString():lower()
	if LastLanguage ~= lang.CURRENT_LANG then hook.Call('DLib.LanguageChanged') end
	LastLanguage = lang.CURRENT_LANG

	net.Start('DLib.UpdateLang')
	net.WriteString(lang.CURRENT_LANG)
	net.SendToServer()
end

cvars.AddChangeCallback('gmod_language', lang.update, 'DLib')
lang.update()
timer.Simple(0, lang.update)
