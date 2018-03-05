
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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
	local rply = (net.ReadPlayer or net.ReadEntity)()

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
