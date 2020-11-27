
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
local util = util
local net = net
local error = error

Friend.typesCache = Friend.typesCache or {}
Friend.typesCacheUID = Friend.typesCacheUID or {}
Friend.typesCacheCRC = Friend.typesCacheCRC or {}

--[[
	@doc
	@fname DLib.Friend.Register
	@args string statusID, string statusName, boolean defaultValue = true

	@desc
	statusID is internal ID you would use
	statusName is friendly name that player would use
	(it can be a DLib i18n string)
	defaultValue is status of this friend relationship for newly created friends
	or for steam friends
	@enddesc
]]
function Friend.Register(statusID, statusName, defaultValue)
	assert(type(statusID) == 'string', 'Invalid status id were provided. typeof ' .. type(statusID))

	statusName = statusName or statusID
	local localized = DLib.i18n.localize(statusName)
	statusID = statusID:lower()
	if defaultValue == nil then defaultValue = true end

	local data = Friend.typesCache[statusID]

	if not data then
		data = {
			id = statusID,
			crc = util.CRC(statusID),
			uid = tonumber(util.CRC(statusID)),
			def = defaultValue
		}

		Friend.typesCacheUID[data.uid] = data
		Friend.typesCacheCRC[data.crc] = data
		Friend.typesCache[statusID] = data

		if CLIENT then
			Friend.FillGaps(statusID)
		end
	end

	data.name = statusName
	data.localizedName = localized
	data.def = defaultValue
end

--[[
	@doc
	@fname DLib.Friend.IsRegistered
	@args string statusID

	@returns
	boolean
]]
function Friend.IsRegistered(statusID)
	return Friend.typesCache[statusID] ~= nil or Friend.typesCacheUID[statusID] ~= nil or Friend.typesCacheCRC[statusID] ~= nil
end

--[[
	@doc
	@fname DLib.Friend.Serealize
	@args table savedata

	@desc
	for current network message
	@enddesc

	@internal
]]
function Friend.Serealize(status)
	net.WriteBool(status.isFriend)

	for fID, fVal in pairs(status.status) do
		local uid = Friend.typesCache[fID]

		if uid then
			net.WriteUInt(uid.uid, 32)
			net.WriteBool(fVal)
		end
	end

	net.WriteUInt(0, 32)
end

--[[
	@doc
	@fname DLib.Friend.Read

	@desc
	from current network message
	@enddesc

	@internal

	@returns
	Player: read player
	table: savedata
]]
function Friend.Read()
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
		local readID = Friend.typesCacheUID[nextfriendID]

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
	for k, data in pairs(Friend.typesCache) do
		data.localizedName = DLib.i18n.localize(data.name)
	end
end)
