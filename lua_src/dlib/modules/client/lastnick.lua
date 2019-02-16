
-- Copyright (C) 2017-2019 DBot

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


local LocalPlayer = LocalPlayer
local sql = sql
local DLib = DLib

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
	if not nick then return 'Unknown Pone #' .. util.CRC(steamid):sub(1, 4) end

	if nick == name then
		return nick
	else
		return nick .. '(' .. name .. ')'
	end
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

	if sql.Query('SELECT steamid FROM dlib_lastnick WHERE steamid = ' .. steamid) then
		return sql.Query('UPDATE dlib_lastnick SET lastnick = ' .. nick .. ', lastname = ' .. lastname .. ' WHERE steamid = ' .. steamid)
	else
		return sql.Query('INSERT INTO dlib_lastnick (steamid, lastnick, lastname) VALUES (' .. steamid .. ', ' .. nick .. ', ' .. lastname .. ')')
	end
end

--[[
	@doc
	@fname DLib.UpdateLastNicks

	@internal
]]
function DLib.UpdateLastNicks()
	sql.Query('BEGIN')

	for i, ply in ipairs(player.GetHumans()) do
		local steamid, lastname = SQLStr(ply:SteamID()), SQLStr(ply:Nick())
		local nick = lastname

		if ply.SteamName then
			lastname = SQLStr(ply:SteamName())
		end

		if not ply.__dlib_nickinsert then
			sql.Query('INSERT INTO dlib_lastnick (steamid, lastnick, lastname) VALUES (' .. steamid .. ', ' .. nick .. ', ' .. lastname .. ')')
			ply.__dlib_nickinsert = true
		end

		sql.Query('UPDATE dlib_lastnick SET lastnick = ' .. nick .. ', lastname = ' .. lastname .. ' WHERE steamid = ' .. steamid)
	end

	sql.Query('COMMIT')
end

timer.Create('DLib.UpdateLastNicks', 5, 0, DLib.UpdateLastNicks)
DLib.UpdateLastNicks()
