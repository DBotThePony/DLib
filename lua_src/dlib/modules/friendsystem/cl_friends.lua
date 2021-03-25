
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

local Friend = DLib.Friend
local DLib = DLib
local sql = sql
local string = string
local net = net

sql.EQuery([[
	CREATE TABLE IF NOT EXISTS dlib_friends (
		steamid VARCHAR(31) NOT NULL,
		friendid VARCHAR(63) NOT NULL,
		status BOOLEAN NOT NULL,
		PRIMARY KEY (steamid, friendid)
	)
]])

local plyMeta = FindMetaTable('Player')
local IsValid = FindMetaTable('Entity').IsValid

Friend.CurrentStatus = {}
Friend.CurrentCount = 0

--[[
	@doc
	@fname DLib.Friend.FillGaps
	@args string statusID

	@client

	@desc
	fills missing entries in Friend table with specified friend string ID
	@enddesc

	@returns
	table: of steamids which was affected
]]
function Friend.FillGaps(statusID)
	if not Friend.typesCache[statusID] then return false end

	local defToInsert = Friend.typesCache[statusID].def and '1' or '0'
	local steamids = sql.EQuery("SELECT steamid FROM dlib_friends WHERE " .. SQLStr(statusID) .. " NOT IN (SELECT friendid FROM dlib_friends WHERE steamid = steamid) GROUP BY steamid")

	if steamids then
		sql.EQuery('BEGIN')
		local sidQ = SQLStr(statusID)

		for i, row in ipairs(steamids) do
			sql.EQuery('INSERT INTO dlib_friends (steamid, friendid, status) VALUES (' .. SQLStr(row.steamid) .. ', ' .. sidQ .. ', ' .. defToInsert .. ')')
		end

		sql.EQuery('COMMIT')
	end

	return steamids
end

--[[
	@doc
	@fname Player:IsDLibFriend
	@args Player target

	@returns
	boolean
]]
function plyMeta:IsDLibFriend(target)
	if not IsValid(target) then return false end

	if self == LocalPlayer() then
		local tab = Friend.CurrentStatus
		if not tab[target] then return false end
		return tab[target].isFriend
	else
		local tab = self.DLib_Friends_currentStatus
		if not tab then return false end
		if not tab[target] then return false end
		return tab[target].isFriend
	end
end

--[[
	@doc
	@fname Player:IsDLibFriendType
	@args Player target, string statusID

	@returns
	boolean
]]
function plyMeta:IsDLibFriendType(target, tp)
	if not IsValid(target) then return false end
	if not tp then return false end

	if self == LocalPlayer() then
		local tab = Friend.CurrentStatus
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

function Friend.LoadPlayer(steamid, returnIfNothing, withCreation)
	local ply = player.GetBySteamID(steamid)

	if ply and Friend.CurrentStatus[ply] and Friend.CurrentStatus[ply].isFriend then
		return Friend.CurrentStatus[ply]
	end

	local data = sql.EQuery('SELECT friendid, status FROM dlib_friends WHERE steamid = ' .. SQLStr(steamid))

	if not data then
		if returnIfNothing then
			if not withCreation then
				return {
					isFriend = false,
					status = {}
				}
			else
				local build = {}

				for id, data in pairs(Friend.typesCache) do
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

--[[
	@doc
	@fname DLib.Friend.ModifyFriend
	@args string steamid, table savedata

	@desc
	not gonna explain what this does and how to use this
	just gonna say this function exists and if you hit a big boulder and want to use this function - you can do
	just make sure you know what you are doing
	@enddesc

	@internal
	@client
]]
function Friend.ModifyFriend(steamid, savedata)
	local ply = player.GetBySteamID(steamid)

	if ply then
		Friend.CurrentStatus[ply] = savedata
		hook.Run('DLib_FriendModified', ply, savedata)
		Friend.SendToServer()
	end

	Friend.SaveDataFor(steamid, savedata)
end

local steamidsCache = {}

--[[
	@doc
	@fname DLib.Friend.UpdateFriendType
	@args string steamid, string statusID, boolean newstatus

	@desc
	sets friend status of `steamid` in `statusID` relationhip to `newstatus`
	@enddesc

	@client

	@returns
	table: new savedata (you don't have to save it manually)
]]
function Friend.UpdateFriendType(steamid, ftype, fnew)
	steamidsCache[steamid] = steamidsCache[steamid] or Friend.LoadPlayer(steamid, true, true)
	steamidsCache[steamid].status[ftype] = fnew

	local isFriend = false

	for i, status in pairs(steamidsCache[steamid].status) do
		if status then
			isFriend = true
			break
		end
	end

	steamidsCache[steamid].isFriend = isFriend

	hook.Run('DLib_FriendStatusUpdated', steamid, ftype, fnew, player.GetBySteamID(steamid))

	return steamidsCache[steamid]
end

--[[
	@doc
	@fname DLib.Friend.Flush
	@args string steamid, string statusID, boolean newstatus

	@desc
	save everything
	@enddesc

	@client
]]
function Friend.Flush()
	for steamid, data in pairs(steamidsCache) do
		Friend.SaveDataFor(steamid, data)
	end

	steamidsCache = {}
end

--[[
	@doc
	@fname DLib.Friend.SaveDataFor
	@args string steamid, table savedata

	@client
	@internal
]]
function Friend.SaveDataFor(steamid, savedata)
	if not savedata.isFriend then
		Friend.RemoveFriend(steamid)
		return
	end

	sql.EQuery('BEGIN')
	steamid = SQLStr(steamid)

	sql.EQuery('DELETE FROM dlib_friends WHERE steamid = ' .. steamid)

	for statusID, status in pairs(savedata.status) do
		sql.EQuery('INSERT INTO dlib_friends (steamid, friendid, status) VALUES (' .. steamid .. ', ' .. SQLStr(statusID) .. ', ' .. (status and '1' or '0') .. ')')
	end

	sql.EQuery('COMMIT')

	hook.Run('DLib_FriendSaved', steamid, savedata)
end

--[[
	@doc
	@fname DLib.Friend.RemoveFriend
	@args string steamid

	@client

	@desc
	removes a friend completely
	@enddesc

	@returns
	boolean: was operation successful or not
]]
function Friend.RemoveFriend(steamid)
	sql.EQuery('DELETE FROM dlib_friends WHERE steamid = ' .. SQLStr(steamid))

	local ply = player.GetBySteamID(steamid)

	if ply then
		local build = {}

		for id, data in pairs(Friend.typesCache) do
			build[id] = false
		end

		Friend.CurrentStatus[ply] = {
			isFriend = false,
			status = build
		}

		Friend.SendToServer()

		hook.Run('DLib_FriendRemoved', steamid, ply)

		return true
	end

	hook.Run('DLib_FriendRemoved', steamid)

	return false
end

--[[
	@doc
	@fname DLib.Friend.CreateFriend
	@args string steamid, boolean doSave = false

	@client

	@desc
	creates a new friend

	THIS DOES NOT CHECK WHENEVER FRIEND ALREADY EXISTS
	CHECK BY YOURSELVE
	@enddesc

	@returns
	table: new savedata
]]
function Friend.CreateFriend(steamid, doSave)
	local ply = player.GetBySteamID(steamid)
	local build = {}

	for id, data in pairs(Friend.typesCache) do
		build[id] = data.def
	end

	local data = {
		isFriend = true,
		status = build
	}

	if doSave then
		Friend.SaveDataFor(steamid, data)

		if ply then
			Friend.CurrentStatus[ply] = data
		end

		hook.Run('DLib_FriendCreated', steamid)
	end

	return data
end

--[[
	@doc
	@fname DLib.Friend.GetIDsString

	@client

	@returns
	table: sql strings of statusIDs
]]
function Friend.GetIDsString()
	local keys = table.GetKeys(Friend.typesCache)

	for i, val in ipairs(keys) do
		keys[i] = SQLStr(val)
	end

	return table.concat(keys, ',')
end

--[[
	@doc
	@fname DLib.Friend.Reload

	@client
]]
function Friend.Reload()
	Friend.CurrentStatus = {}
	Friend.CurrentCount = player.GetCount()
	local lply = LocalPlayer()

	local targets = {}
	local targetsH = {}
	local targetsH2 = {}

	-- sql.EQuery('BEGIN')

	for k, ply in ipairs(player.GetHumans()) do
		if lply ~= ply then
			local steamid = ply:SteamID()
			local sq = SQLStr(steamid)
			table.insert(targets, sq)

			Friend.CurrentStatus[ply] = {
				isFriend = false,
				status = {}
			}

			local d = Friend.CurrentStatus[ply].status
			targetsH[steamid] = d
			targetsH2[steamid] = Friend.CurrentStatus[ply]

			for id, data in pairs(Friend.typesCache) do
				d[id] = false
			end
		end
	end

	-- sql.EQuery('COMMIT')

	local data = sql.EQuery('SELECT * FROM `dlib_friends` WHERE `steamid` IN (' .. table.concat(targets, ',') .. ')')

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

	Friend.SendToServer()

	hook.Run('DLib_FriendsReloaded')

	return Friend.CurrentStatus
end

--[[
	@doc
	@fname DLib.Friend.SendToServer

	@client
]]
function Friend.SendToServer()
	net.Start('DLib.friendsystem')

	net.WriteUInt(table.Count(Friend.CurrentStatus), 8)

	for ply, status in pairs(Friend.CurrentStatus) do
		net.WritePlayer(ply)
		Friend.Serealize(status)
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
		local rply, status = Friend.Read()

		if IsValid(rply) then
			target[rply] = status
		end
	end
end)

local GetCount = player.GetCount

hook.AddTask('Think', 'DLib Update Friend List', function()
	if Friend.CurrentCount ~= GetCount() then
		Friend.Reload()
	end
end)

timer.Remove('DLib.updateFriendList')
