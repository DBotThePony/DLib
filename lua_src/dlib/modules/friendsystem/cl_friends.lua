
-- Copyright (C) 2017-2018 DBot

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


local sql = DLib.sql

sql.Query([[
	CREATE TABLE IF NOT EXISTS dlib_friends (
		steamid VARCHAR(31) NOT NULL,
		friendid VARCHAR(63) NOT NULL,
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
		local sidQ = SQLStr(statusID)

		for i, row in ipairs(steamids) do
			sql.Query('INSERT INTO dlib_friends (steamid, friendid, status) VALUES (' .. SQLStr(row.steamid) .. ', ' .. sidQ .. ', ' .. defToInsert .. ')')
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

plyMeta.IsDLibFriendIn = plyMeta.IsDLibFriendType

function friends.LoadPlayer(steamid, returnIfNothing, withCreation)
	local ply = player.GetBySteamID(steamid)

	if ply and friends.currentStatus[ply] and friends.currentStatus[ply].isFriend then
		return friends.currentStatus[ply]
	end

	local data = sql.Query('SELECT friendid, status FROM dlib_friends WHERE steamid = ' .. SQLStr(steamid))

	if not data then
		if returnIfNothing then
			if not withCreation then
				return {
					isFriend = false,
					status = {}
				}
			else
				local build = {}

				for id, data in pairs(friends.typesCache) do
					build[id] = data.def
				end

				return {
					isFriend = true,
					status = build
				}
			end
		end

		return
	end

	local build = {}

	for i, row in ipairs(data) do
		build[row.friendid] = tobool(row.status)
	end

	return {
		isFriend = true,
		status = build
	}
end

function friends.ModifyFriend(steamid, savedata)
	local ply = player.GetBySteamID(steamid)

	if ply then
		friends.currentStatus[ply] = savedata
		hook.Run('DLib_FriendModified', ply, savedata)
	end

	friends.SaveDataFor(steamid, savedata)
end

local steamidsCache = {}

function friends.UpdateFriendType(steamid, ftype, fnew)
	steamidsCache[steamid] = steamidsCache[steamid] or friends.LoadPlayer(steamid, true, true)
	steamidsCache[steamid].status[ftype] = fnew

	local isFriend = false

	for i, status in pairs(steamidsCache[steamid].status) do
		if status then
			isFriend = true
			break
		end
	end

	steamidsCache[steamid].isFriend = isFriend

	return steamidsCache[steamid]
end

function friends.Flush()
	for steamid, data in pairs(steamidsCache) do
		friends.SaveDataFor(steamid, data)
	end

	steamidsCache = {}
end

function friends.SaveDataFor(steamid, savedata)
	if not savedata.isFriend then
		friends.RemoveFriend(steamid)
		return
	end

	sql.Query('BEGIN')
	steamid = SQLStr(steamid)

	sql.Query('DELETE FROM dlib_friends WHERE steamid = ' .. steamid)

	for statusID, status in pairs(savedata.status) do
		sql.Query('INSERT INTO dlib_friends (steamid, friendid, status) VALUES (' .. steamid .. ', ' .. SQLStr(statusID) .. ', ' .. (status and '1' or '0') .. ')')
	end

	sql.Query('COMMIT')

	hook.Run('DLib_FriendSaved', steamid, savedata)
end

function friends.RemoveFriend(steamid)
	sql.Query('DELETE FROM dlib_friends WHERE steamid = ' .. SQLStr(steamid))

	local ply = player.GetBySteamID(steamid)

	if ply then
		local build = {}

		for id, data in pairs(friends.typesCache) do
			build[id] = false
		end

		friends.currentStatus[ply] = {
			isFriend = false,
			status = build
		}

		friends.SendToServer()

		hook.Run('DLib_FriendRemoved', steamid, ply)

		return true
	end

	hook.Run('DLib_FriendRemoved', steamid)

	return false
end

function friends.CreateFriend(steamid, doSave)
	local ply = player.GetBySteamID(steamid)
	local build = {}

	for id, data in pairs(friends.typesCache) do
		build[id] = data.def
	end

	local data = {
		isFriend = true,
		status = build
	}

	if doSave then
		friends.SaveDataFor(steamid, data)

		if ply then
			friends.currentStatus[ply] = data
		end

		hook.Run('DLib_FriendCreated', steamid)
	end

	return data
end

function friends.GetIDsString()
	local keys = table.GetKeys(friends.typesCache)

	for i, val in ipairs(keys) do
		keys[i] = SQLStr(val)
	end

	return table.concat(keys, ',')
end

function friends.Reload()
	friends.currentStatus = {}
	friends.currentCount = player.GetCount()
	local lply = LocalPlayer()

	local targets = {}
	local targetsH = {}
	local targetsH2 = {}

	sql.Query('BEGIN')

	for k, ply in ipairs(player.GetHumans()) do
		if lply ~= ply then
			local steamid = ply:SteamID()
			local sq = SQLStr(steamid)
			table.insert(targets, sq)

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
	end

	sql.Query('COMMIT')

	local data = sql.Query('SELECT * FROM dlib_friends WHERE steamid IN (' .. table.concat(targets, ',') .. ')')

	if data then
		for i, row in ipairs(data) do
			local steamid = row.steamid
			local id = row.friendid
			local status = row.status
			local into = targetsH[steamid]

			targetsH2[steamid].isFriend = true

			if into then
				into[id] = tobool(status)
			end
		end
	end

	friends.SendToServer()

	hook.Run('DLib_FriendsReloaded')

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
