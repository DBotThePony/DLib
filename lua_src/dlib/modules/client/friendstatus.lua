
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

local plyMeta = FindMetaTable('Player')

function plyMeta:IsFriend()
	local f = self:GetFriendStatus()
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsSteamFriend()
	local f = self:GetFriendStatus()
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsSteamBlocked()
	local f = self:GetFriendStatus()
	return f == 'blocked'
end

local knownStatus = {}
local enums = DLib.Enum('none', 'friend', 'blocked', 'requested')
local IsValid = FindMetaTable('Entity').IsValid

local function update()
	local dirty = false

	for ply, status in pairs(knownStatus) do
		if not IsValid(ply) then
			dirty = true
			knownStatus[ply] = nil
		end
	end

	for i, ply in ipairs(player.GetAll()) do
		local newstatus = ply:GetFriendStatus()

		if knownStatus[ply] ~= newstatus then
			knownStatus[ply] = newstatus
			dirty = true
		end
	end

	if dirty then
		net.Start('DLib.friendstatus')

		net.WriteUInt(table.Count(knownStatus), 8)

		for ply, status in pairs(knownStatus) do
			net.WritePlayer(ply)
			enums:write(status)
		end

		net.SendToServer()
	end
end

timer.Create('DLib.FriendStatus', 5, 0, update)
