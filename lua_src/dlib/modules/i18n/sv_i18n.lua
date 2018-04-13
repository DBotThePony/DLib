
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

function i18n.getPlayer(ply, phrase, ...)
	return i18n.localizeByLang(phrase, ply.DLib_Lang or 'en', ...)
end

i18n.getByPlayer = i18n.getPlayer
i18n.localizePlayer = i18n.getPlayer
i18n.localizebyPlayer = i18n.getPlayer
i18n.byPlayer = i18n.getPlayer

local plyMeta = FindMetaTable('Player')

function plyMeta:LocalizePhrase(phrase, ...)
	return i18n.localizeByLang(phrase, self.DLib_Lang or 'en', ...)
end

plyMeta.DLibPhrase = plyMeta.LocalizePhrase
plyMeta.DLibLocalize = plyMeta.LocalizePhrase
plyMeta.GetDLibPhrase = plyMeta.LocalizePhrase
