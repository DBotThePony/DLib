
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

sql.Query([[
	CREATE TABLE IF NOT EXISTS dlib_friends (
		steamid VARCHAR(31) NOT NULL,
		friendid VARCHAR(255) NOT NULL,
		status BOOLEAN NOT NULL,
		PRIMARY KEY (steamid, friendid)
	)
]])

local plyMeta = FindMetaTable('Player')
local IsValid = FindMetaTable('Entity').IsValid

friends.currentStatus = {}
friends.currentCount = 0

function friends.FillGaps(statusID)
	if not friends.typesCache[statusID] then return false end

	local defToInsert = friends.typesCache[statusID].def and '1' or '0'
	local steamids = sql.Query("SELECT steamid FROM dlib_friends WHERE " .. SQLStr(statusID) .. " NOT IN (SELECT friendid FROM dlib_friends WHERE steamid = steamid) GROUP BY steamid")

	if steamids then
		sql.Query('BEGIN')

		for i, row in ipairs(steamids) do
			sql.Query('INSERT INTO dlib_friends (steamid, friendid, status) VALUES (' .. SQLStr(row.steamid) .. ', ' .. statusID .. ', ' .. defToInsert .. ')')
		end

		sql.Query('COMMIT')
	end

	return steamids
end

function plyMeta:IsDLibFriend(target)
	if not IsValid(target) then return false end

	if self == LocalPlayer() then
		local tab = friends.currentStatus
		if not tab[target] then return false end
		return tab[target].isFriend
	else
		local tab = self.DLib_Friends_currentStatus
		if not tab then return false end
		if not tab[target] then return false end
		return tab[target].isFriend
	end
end

function plyMeta:IsDLibFriendType(target, tp)
	if not IsValid(target) then return false end
	if not tp then return false end

	if self == LocalPlayer() then
		local tab = friends.currentStatus
		if not tab[target] then return false end
		return tab[target].status[tp] or false
	else
		local tab = self.DLib_Friends_currentStatus
		if not tab then return false end
		if not tab[target] then return false end
		return tab[target].status[tp] or false
	end
end

function friends.Reload()
	friends.currentStatus = {}
	friends.currentCount = 0

	local targets = {}
	local targetsH = {}
	local targetsH2 = {}

	for k, ply in ipairs(player.GetAll()) do
		local steamid = ply:SteamID()
		table.insert(targets, SQLStr(steamid))

		friends.currentCount = friends.currentCount + 1

		friends.currentStatus[ply] = {
			isFriend = false,
			status = {}
		}

		local d = friends.currentStatus[ply].status
		targetsH[steamid] = d
		targetsH2[steamid] = friends.currentStatus[ply]

		for id, data in pairs(friends.typesCache) do
			d[id] = false
		end
	end

	local keys = table.GetKeys(friends.typesCache)

	for i, val in ipairs(keys) do
		keys[i] = SQLStr(val)
	end

	local data = sql.Query('SELECT * FROM dlib_friends WHERE steamid IN (' .. table.concat(targets, ',') .. ') AND friendid IN (' .. table.concat(keys, ',') .. ')')

	if data then
		for i, row in ipairs(data) do
			local steamid = row.steamid
			local id = row.friendid
			local status = row.status
			local into = targetsH[steamid]

			targetsH2[steamid].isFriend = true

			if into and into[id] ~= nil then
				into[id] = status
			end
		end
	end

	friends.SendToServer()

	return friends.currentStatus
end

function friends.SendToServer()
	net.Start('DLib.friendsystem')

	net.WriteUInt(table.Count(friends.currentStatus), 8)

	for ply, status in pairs(friends.currentStatus) do
		net.WritePlayer(ply)
		friends.Serealize(status)
	end

	net.SendToServer()
end

net.receive('DLib.friendsystem', function(len)
	local ply = net.ReadPlayer()
	if not IsValid(ply) then return end

	local amount = net.ReadUInt(8)
	ply.DLib_Friends_currentStatus = {}
	local target = ply.DLib_Friends_currentStatus

	for i = 1, amount do
		local rply, status = friends.Read()

		if IsValid(rply) then
			target[rply] = status
		end
	end
end)

timer.Create('DLib.updateFriendList', 1, 0, function()
	if not IsValid(LocalPlayer()) then return end

	if friends.currentCount ~= player.GetCount() then
		friends.Reload()
	end
end)
