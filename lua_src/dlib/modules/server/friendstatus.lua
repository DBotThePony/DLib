
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

net.pool('DLib.friendstatus')
local IsValid = FindMetaTable('Entity').IsValid
local enums = DLib.Enum('none', 'friend', 'blocked', 'requested')

local function friendstatus(len, ply)
	if not IsValid(ply) then return end
	local amount = net.ReadUInt(8)
	ply.DLibFriends = {}
	local status = ply.DLibFriends
	local reply = {}

	for i = 1, amount do
		local readPly = net.ReadPlayer()
		local readEnum = enums:read()

		if IsValid(readPly) then
			status[readPly] = readEnum
			table.insert(reply, {readPly, readEnum})
		end
	end

	if #reply ~= 0 then
		net.Start('DLib.friendstatus')

		net.WritePlayer(ply)
		net.WriteUInt(#reply, 8)

		for i, plyData in ipairs(reply) do
			net.WritePlayer(plyData[1])
			enums:write(plyData[2])
		end

		net.SendOmit(ply)
	end
end

net.receive('DLib.friendstatus', friendstatus)

local plyMeta = FindMetaTable('Player')

function plyMeta:GetFriendStatus(target)
	local status = self.DLibFriends
	return status and status[target] or 'none'
end

function plyMeta:IsFriend(target)
	local f = self:GetFriendStatus(target)
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsSteamFriend(target)
	local f = self:GetFriendStatus(target)
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsSteamBlocked(target)
	local f = self:GetFriendStatus(target)
	return f == 'blocked'
end