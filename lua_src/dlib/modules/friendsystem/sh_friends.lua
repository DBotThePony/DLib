
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


friends.typesCache = friends.typesCache or {}
friends.typesCacheUID = friends.typesCacheUID or {}
friends.typesCacheCRC = friends.typesCacheCRC or {}

function friends.Register(statusID, statusName, defaultValue)
	if not statusID then error('No status ID was passed') end

	statusName = statusName or statusID
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
	data.def = defaultValue
end

function friends.IsRegistered(statusID)
	return friends.typesCache[statusID] ~= nil or friends.typesCacheUID[statusID] ~= nil or friends.typesCacheCRC[statusID] ~= nil
end

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

function plyMeta:CheckDLibFriend(target)
	return self:IsFriend(target) or self:IsDLibFriend(target)
end

function plyMeta:CheckDLibFriendIn(target, tp)
	return self:IsFriend(target) or self:IsDLibFriendIn(target, tp)
end

function plyMeta:CheckDLibFriend2(target)
	return self:IsFriend2(target) or self:IsDLibFriend(target)
end

function plyMeta:CheckDLibFriendIn2(target, tp)
	return self:IsFriend2(target) or self:IsDLibFriendIn(target, tp)
end

function plyMeta:GetAllFriends()
	local reply = {}

	for i, ply in ipairs(player.GetHumans()) do
		if self:IsDLibFriend(ply) then
			table.insert(reply, ply)
		end
	end

	return reply
end
