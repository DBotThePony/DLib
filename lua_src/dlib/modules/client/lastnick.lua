
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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

function DLib.LastNick(steamid)
	local ply = player.GetBySteamID(steamid)

	if ply then
		return ply:Nick(), ply.SteamName and ply:SteamName() or ply:Nick()
	end

	local data = sql.Query('SELECT lastnick, lastname FROM dlib_lastnick WHERE steamid = ' .. SQLStr(steamid))

	if not data then return false end
	return data[1].lastnick, data[1].lastname
end

function DLib.LastNickFormatted(steamid)
	local nick, name = DLib.LastNick(steamid)
	if not nick then return 'Unknown Pone #' .. util.CRC(steamid):sub(1, 4) end

	if nick == name then
		return nick
	else
		return nick .. '(' .. name .. ')'
	end
end

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
