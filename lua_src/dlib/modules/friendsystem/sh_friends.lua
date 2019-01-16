
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

local DLib = DLib
local util = util
local friends = friends
local net = net
local error = error

friends.typesCache = friends.typesCache or {}
friends.typesCacheUID = friends.typesCacheUID or {}
friends.typesCacheCRC = friends.typesCacheCRC or {}

--[[
	@doc
	@fname DLib.friends.Register
	@args string statusID, string statusName, boolean defaultValue = true

	@desc
	statusID is internal ID you would use
	statusName is friendly name that player would use
	(it can be a DLib i18n string)
	defaultValue is status of this friend relationship for newly created friends
	or for steam friends
	@enddesc
]]
function friends.Register(statusID, statusName, defaultValue)
	assert(type(statusID) == 'string', 'Invalid status id were provided. typeof ' .. type(statusID))

	statusName = statusName or statusID
	local localized = DLib.i18n.localize(statusName)
	statusID = statusID:lower()
	if defaultValue == nil then defaultValue = true end

	local data = friends.typesCache[statusID]

	if not data then
		data = {
			id = statusID,
			crc = util.CRC(statusID),
			uid = tonumber(util.CRC(statusID)),
			def = defaultValue
		}

		friends.typesCacheUID[data.uid] = data
		friends.typesCacheCRC[data.crc] = data
		friends.typesCache[statusID] = data

		if CLIENT then
			friends.FillGaps(statusID)
		end
	end

	data.name = statusName
	data.localizedName = localized
	data.def = defaultValue
end

--[[
	@doc
	@fname DLib.friends.IsRegistered
	@args string statusID

	@returns
	boolean
]]
function friends.IsRegistered(statusID)
	return friends.typesCache[statusID] ~= nil or friends.typesCacheUID[statusID] ~= nil or friends.typesCacheCRC[statusID] ~= nil
end

--[[
	@doc
	@fname DLib.friends.Serealize
	@args table savedata

	@desc
	for current network message
	@enddesc

	@internal
]]
function friends.Serealize(status)
	net.WriteBool(status.isFriend)

	for fID, fVal in pairs(status.status) do
		local uid = friends.typesCache[fID]

		if uid then
			net.WriteUInt(uid.uid, 32)
			net.WriteBool(fVal)
		end
	end

	net.WriteUInt(0, 32)
end

--[[
	@doc
	@fname DLib.friends.Read

	@desc
	from current network message
	@enddesc

	@internal

	@returns
	Player: read player
	table: savedata
]]
function friends.Read()
	local rply = net.ReadPlayer()

	local readData = {
		isFriend = false,
		status = {}
	}

	local friendStatus = net.ReadBool()
	readData.isFriend = friendStatus

	for i = 1, 100 do
		local nextfriendID = net.ReadUInt(32)
		if nextfriendID == 0 then break end
		local nfriendstatus = net.ReadBool()
		local readID = friends.typesCacheUID[nextfriendID]

		if readID then
			readData.status[readID.id] = nfriendstatus
		end
	end

	return rply, readData
end

local plyMeta = FindMetaTable('Player')

-- whenever player is just a friend in any way
function plyMeta:CheckDLibFriend(target)
	return self:IsFriend(target) or self:IsDLibFriend(target)
end

function plyMeta:CheckDLibFriendIn(target, tp)
	return self:IsFriend(target) or self:IsDLibFriendIn(target, tp)
end

-- whenever player is just a friend in any way + checking steam friends <-> dlib friends preference.
function plyMeta:CheckDLibFriend2(target)
	return self:IsFriend2(target) or self:IsDLibFriend(target)
end

function plyMeta:CheckDLibFriendIn2(target, tp)
	return self:IsFriend2(target) or self:IsDLibFriendIn(target, tp)
end

function plyMeta:CheckDLibFriendOverride(target)
	return self:IsFriend2(target) or self:IsDLibFriend(target)
end

function plyMeta:CheckDLibFriendInOverride(target, tp)
	return self:IsFriend2(target) or self:IsDLibFriendIn(target, tp)
end

--[[
	@doc
	@fname Player:GetAllFriends

	@returns
	table: of Players
]]
function plyMeta:GetAllFriends()
	local reply = {}

	for i, ply in ipairs(player.GetHumans()) do
		if self:IsDLibFriend(ply) then
			table.insert(reply, ply)
		end
	end

	return reply
end

hook.Add('DLib.LanguageChanged', 'FriendsTableUpdate', function()
	for k, data in pairs(friends.typesCache) do
		data.localizedName = DLib.i18n.localize(data.name)
	end
end)
