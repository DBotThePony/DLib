
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
		return ply:Nick()
	end

	local data = sql.Query('SELECT lastnick, lastname FROM dlib_lastnick WHERE steamid = ' .. SQLStr(steamid))

	if not data then return false end
	return data[1].lastnick, data[1].lastname
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

		sql.Query('UPDATE dlib_lastnick WHERE')
	end

	sql.Query('COMMIT')
end

timer.Create('DLib.UpdateLastNicks', 5, 0, DLib.UpdateLastNicks)
DLib.UpdateLastNicks()
