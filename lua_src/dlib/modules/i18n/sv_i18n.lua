
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
local game = game
local GetName = FindMetaTable('Entity').GetName
local SetName = FindMetaTable('Entity').SetName

local function tickPlayers()
	if game.SinglePlayer() then
		timer.Remove('DLib.TickPlayerNames')
		hook.Remove('PlayerSpawn', 'DLib.TickPlayerNames')
		hook.Remove('DoPlayerDeath', 'DLib.TickPlayerNames')
		return
	end

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

function i18n.RegisterProxy(...)
	-- do nothing
end

timer.Create('DLib.TickPlayerNames', 0.5, 0, tickPlayers)
hook.Add('PlayerSpawn', 'DLib.TickPlayerNames', timer.Simple:Wrap(0, tickPlayers))
hook.Add('DoPlayerDeath', 'DLib.TickPlayerNames', tickPlayers)
