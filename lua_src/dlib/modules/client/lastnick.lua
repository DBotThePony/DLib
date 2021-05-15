
-- Copyright (C) 2017-2020 DBotThePony

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

local ipairs = ipairs
local LocalPlayer = LocalPlayer
local sql = sql
local DLib = DLib
local player = player

sql.Query([[
	CREATE TABLE IF NOT EXISTS dlib_lastnick (
		steamid VARCHAR(31) NOT NULL,
		lastnick VARCHAR(255) NOT NULL,
		lastname VARCHAR(255) NOT NULL,
		PRIMARY KEY (steamid)
	)
]])

--[[
	@doc
	@fname DLib.LastNick
	@args string steamid

	@client

	@returns
	any: string or boolean (if not exists)
]]
function DLib.LastNick(steamid)
	local ply = player.GetBySteamID(steamid)

	if ply then
		return ply:Nick(), ply.SteamName and ply:SteamName() or ply:Nick()
	end

	local data = sql.Query('SELECT lastnick, lastname FROM dlib_lastnick WHERE steamid = ' .. SQLStr(steamid))

	if not data then return false end
	return data[1].lastnick, data[1].lastname
end

--[[
	@doc
	@fname DLib.LastNickFormatted
	@args string steamid

	@client

	@returns
	string
]]
function DLib.LastNickFormatted(steamid)
	local nick, name = DLib.LastNick(steamid)

	if not nick then return 'Anonymous #' .. DLib.Util.QuickSHA1(steamid):sub(1, 8) end

	if nick == name then
		return nick
	end

	return nick .. ' (' .. name .. ')'
end

--[[
	@doc
	@fname DLib.UpdateLastNick
	@args string steamid, string nick, string lastname

	@desc
	lastname is SteamName, nick is nickname in general
	they are the same if current gamemode does not separate those conceptions
	(DarkRP do separate for example)
	@enddesc

	@internal

	@returns
	string
]]
function DLib.UpdateLastNick(steamid, nick, lastname)
	lastname = lastname or nick
	steamid = SQLStr(steamid)
	nick = SQLStr(nick)
	lastname = SQLStr(lastname)

	return sql.Query('REPLACE INTO "dlib_lastnick" ("steamid", "lastnick", "lastname") VALUES (' .. steamid .. ', ' .. nick .. ', ' .. lastname .. ')') ~= false
end

local yield = coroutine.yield
local IsValid = FindMetaTable('Entity').IsValid
local GetHumans = player.GetHumans

function DLib.UpdateLastNicks()
	local players = GetHumans()

	for i = 1, #players do
		local ply = players[i]

		if IsValid(ply) then
			local lastname = ply:Nick()
			local lastnick = lastname

			if ply.SteamName then
				lastname = ply:SteamName()
			end

			if ply._dlib_lastname ~= lastname or ply._dlib_lastnick ~= lastnick then
				ply._dlib_lastname = lastname
				ply._dlib_lastnick = lastnick

				local steamid = SQLStr(ply:SteamID())
				lastname, lastnick = SQLStr(lastname), SQLStr(lastnick)

				sql.Query('REPLACE INTO "dlib_lastnick" ("steamid", "lastnick", "lastname") VALUES (' .. steamid .. ', ' .. lastnick .. ', ' .. lastname .. ')')
			end

			yield()
		end
	end
end

timer.Remove('DLib.UpdateLastNicks')
hook.AddTask('Think', 'DLib Update Last Nicknames', DLib.UpdateLastNicks)
