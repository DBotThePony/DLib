
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

local ipairs = ipairs
local player = player
local GetName = FindMetaTable('Entity').GetName
local SetName = FindMetaTable('Entity').SetName

local function tickPlayers()
	for i, ply in ipairs(player.GetAll()) do
		local name = GetName(ply)

		if #name < 4 then
			DLib.Message(ply, ' network name was treated as exploit, changing...')
			SetName(ply, '_bad_playername_' .. ply:UserID())
		end

		local nick = ply:Nick()

		if nick == 'unnamed' or i18n.exists(nick) then
			ply:Kick('[DLib/I18N] Invalid nickname')
		end
	end
end

timer.Create('DLib.TickPlayerNames', 0.5, 0, tickPlayers)
hook.Add('PlayerSpawn', 'DLib.TickPlayerNames', tickPlayers)
hook.Add('DoPlayerDeath', 'DLib.TickPlayerNames', tickPlayers)

local reasons = {
	'ok, we now all know that you are a N',
	'get outta here, N',
	'NO U',
	'Mean words?',
	'Mean words!',
	'HYPERBRUH',
	'HYPERBRUH DETECTED',
	'What person? HYPERBRUH',
	'HYPERBRUH you HYPERBRUH lasers',
	'get outta here, trash',
	'r00d words [DETECTED] :Cazador:',
	'Every day you HYPERBRUH in chat',
	'i think kick is not enough',
}

local function PlayerSay(self, text)
	if text:lower():find('n ?i ?[gb] ?[gb] ?[ae] ?r?') then
		self:Kick('[DLib/I18N] ' .. table.frandom(reasons))
		return ''
	end
end

hook.Add('PlayerSay', 'DLib.I18nMean', PlayerSay)
