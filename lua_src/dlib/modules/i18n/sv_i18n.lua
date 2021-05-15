
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

net.pool('dlib.clientlang')

local I18n = DLib.I18n

I18n.DEBUG_LANG_STRINGS = CreateConVar('gmod_language_dlib_dbg', '0', {FCVAR_ARCHIVE}, 'Debug language strings (do not localize them)')

--[[
	@doc
	@fname DLib.I18n.GetForPlayer
	@alias DLib.I18n.GetPlayer
	@alias DLib.I18n.GetByPlayer
	@alias DLib.I18n.LocalizePlayer
	@alias DLib.I18n.LocalizebyPlayer
	@alias DLib.I18n.ByPlayer
	@alias Player:LocalizePhrase
	@alias Player:DLibPhrase
	@alias Player:DLibLocalize
	@alias Player:GetDLibPhrase

	@args Player ply, string phrase, vararg formatArguments
	@server

	@returns
	string: formatted message
]]
function I18n.GetForPlayer(ply, phrase, ...)
	return I18n.LocalizeByLang(phrase, ply.DLib_Lang or 'en', ...)
end

I18n.GetPlayer = I18n.GetForPlayer
I18n.GetByPlayer = I18n.GetForPlayer
I18n.LocalizePlayer = I18n.GetForPlayer
I18n.LocalizebyPlayer = I18n.GetForPlayer
I18n.ByPlayer = I18n.GetForPlayer

--[[
	@doc
	@fname DLib.I18n.GetForPlayerAdvanced
	@alias DLib.I18n.GetPlayerAdvanced
	@alias DLib.I18n.GetByPlayerAdvanced
	@alias DLib.I18n.LocalizePlayerAdvanced
	@alias DLib.I18n.LocalizebyPlayerAdvanced
	@alias DLib.I18n.ByPlayerAdvanced
	@alias Player:LocalizePhraseAdvanced
	@alias Player:DLibPhraseAdvanced
	@alias Player:DLibLocalizeAdvanced
	@alias Player:GetDLibPhraseAdvanced

	@args Player ply, string phrase, Color colorDef = color_white, vararg formatArguments
	@server

	@desc
	Supports colors from custom format arguments
	You don't want to use this unless you know that
	some of phrases can contain custom format arguments
	@enddesc

	@returns
	table: formatted message
	number: arguments "consumed"
]]
function I18n.GetForPlayerAdvanced(ply, phrase, ...)
	return I18n.LocalizeByLangAdvanced(phrase, ply.DLib_Lang or 'en', ...)
end

I18n.GetPlayerAdvanced = I18n.GetForPlayerAdvanced
I18n.GetByPlayerAdvanced = I18n.GetForPlayerAdvanced
I18n.LocalizePlayerAdvanced = I18n.GetForPlayerAdvanced
I18n.LocalizebyPlayerAdvanced = I18n.GetForPlayerAdvanced
I18n.ByPlayerAdvanced = I18n.GetForPlayerAdvanced

local plyMeta = FindMetaTable('Player')

--[[
	@doc
	@fname Player:LocalizePhrase
	@alias Player:DLibPhrase
	@alias Player:DLibLocalize
	@alias Player:GetDLibPhrase

	@args string phrase, vararg formatArguments
	@server

	@returns
	string: formatted message
]]
function plyMeta:LocalizePhrase(phrase, ...)
	return I18n.LocalizeByLang(phrase, self.DLib_Lang or 'en', ...)
end

plyMeta.DLibPhrase = plyMeta.LocalizePhrase
plyMeta.DLibLocalize = plyMeta.LocalizePhrase
plyMeta.GetDLibPhrase = plyMeta.LocalizePhrase

--[[
	@doc
	@fname Player:LocalizePhraseAdvanced
	@alias Player:DLibPhraseAdvanced
	@alias Player:DLibLocalizeAdvanced
	@alias Player:GetDLibPhraseAdvanced

	@args string phrase, Color colorDef = color_white, vararg formatArguments
	@server

	@desc
	Supports colors from custom format arguments
	You don't want to use this unless you know that
	some of phrases can contain custom format arguments
	@enddesc

	@returns
	table: formatted message
	number: arguments "consumed"
]]
function plyMeta:LocalizePhraseAdvanced(phrase, ...)
	return I18n.LocalizeByLangAdvanced(phrase, self.DLib_Lang or 'en', ...)
end

plyMeta.DLibPhraseAdvanced = plyMeta.LocalizePhraseAdvanced
plyMeta.DLibLocalizeAdvanced = plyMeta.LocalizePhraseAdvanced
plyMeta.GetDLibPhraseAdvanced = plyMeta.LocalizePhraseAdvanced

local ipairs = ipairs
local player = player
local game = game
local GetName = FindMetaTable('Entity').GetName
local SetName = FindMetaTable('Entity').SetName
local IsValid = FindMetaTable('Entity').IsValid
local GetHumans = player.GetHumans
local yield = coroutine.yield

local tickPlayers, tickPlayersYieldable

if game.SinglePlayer() then
	function tickPlayers()
		for i, ply in ipairs(GetHumans()) do
			local name = GetName(ply)

			if name == '' then
				SetName(ply, '_bad_playername_' .. ply:UserID())
			end
		end
	end

	function tickPlayersYieldable()
		for i, ply in ipairs(GetHumans()) do
			if IsValid(ply) then
				local name = GetName(ply)

				if name == '' then
					SetName(ply, '_bad_playername_' .. ply:UserID())
				end

				yield()
			end
		end
	end
else
	function tickPlayers()
		for i, ply in ipairs(GetHumans()) do
			local name = GetName(ply)

			if name == '' then
				SetName(ply, '_bad_playername_' .. ply:UserID())
			end

			local nick = ply:Nick()

			if I18n.exists(nick) then
				ply:Kick('[DLib.I18n] Bad player name. Contact server\'s staff if you changed name to this using serverside nickname system by a mistake.')
			end
		end
	end

	function tickPlayersYieldable()
		for i, ply in ipairs(GetHumans()) do
			if IsValid(ply) then
				local name = GetName(ply)

				if name == '' then
					SetName(ply, '_bad_playername_' .. ply:UserID())
				end

				local nick = ply:Nick()

				if I18n.exists(nick) then
					ply:Kick('[DLib.I18n] Bad player name. Contact server\'s staff if you changed name to this using serverside nickname system by a mistake.')
				end

				yield()
			end
		end
	end
end

function I18n.RegisterProxy(...)
	-- do nothing, since there is no `language` library present serverside
end

--[[
	@doc
	@hook DLib.PlayerLanguageChanges
	@args Player ply, string oldOrNil, string new
]]

net.receive('dlib.clientlang', function(len, ply)
	local old = ply.DLib_Lang
	ply.DLib_Lang = net.ReadStringArray()
	hook.Run('DLib.PlayerLanguageChanges', ply, old, ply.DLib_Lang)
end)

hook.AddTask('Think', 'DLib Update Friend List', tickPlayersYieldable)
hook.Add('PlayerSpawn', 'DLib.TickPlayerNames', timer.Simple:Wrap(0, tickPlayers))
