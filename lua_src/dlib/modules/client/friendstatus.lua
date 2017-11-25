
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
local net = net
local plyMeta = FindMetaTable('Player')
local cl_dlib_steamfriends = CreateClientConVar('cl_dlib_steamfriends', '1', true, true, 'Treat Steam friends as ANY DLib buddy')

DLib.getinfo.Replicate('cl_dlib_steamfriends')

plyMeta.GetFriendStatusDLib = plyMeta.GetFriendStatusDLib or plyMeta.GetFriendStatus

function plyMeta:GetFriendStatus(targetPly)
	if not targetPly then
		return self:GetFriendStatusDLib()
	end

	if not IsValid(targetPly) then
		return 'none'
	end

	-- local lply = LocalPlayer()
	-- targetPly = targetPly or lply

	-- if lply == targetPly then
	-- 	return self:GetFriendStatusDLib()
	-- end

	local status = self.DLibFriends
	return status and status[targetPly] or 'none'
end

function plyMeta:IsFriend(target)
	local f = self:GetFriendStatus(target)
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsFriend2(target)
	if self == LocalPlayer() and not cl_dlib_steamfriends:GetBool() or self ~= LocalPlayer() and not self:GetInfoBool('cl_dlib_steamfriends', true) then return false end
	local f = self:GetFriendStatus(target)
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsSteamFriend(target)
	local f = self:GetFriendStatus(target)
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsSteamFriend2(target)
	if self == LocalPlayer() and not cl_dlib_steamfriends:GetBool() or self ~= LocalPlayer() and not self:GetInfoBool('cl_dlib_steamfriends', true) then return false end
	local f = self:GetFriendStatus(target)
	return f == 'friend' or f == 'requested'
end

function plyMeta:IsSteamBlocked(target)
	local f = self:GetFriendStatus(target)
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

local function friendstatus()
	local ply = net.ReadEntity()
	if not IsValid(ply) then return end

	local amount = net.ReadUInt(8)
	ply.DLibFriends = {}
	local status = ply.DLibFriends

	for i = 1, amount do
		local readPly = net.ReadPlayer()
		local readEnum = enums:read()

		if IsValid(readPly) then
			status[readPly] = readEnum
		end
	end
end

net.receive('DLib.friendstatus', friendstatus)
