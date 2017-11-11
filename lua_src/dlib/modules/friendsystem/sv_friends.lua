
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

net.pool('DLib.friendsystem')

local plyMeta = FindMetaTable('Player')
local IsValid = FindMetaTable('Entity').IsValid

function plyMeta:IsDLibFriend(target)
	if not IsValid(target) then return false end
	local tab = self.DLib_Friends_currentStatus
	if not tab then return false end
	if not tab[target] then return false end
	return tab[target].isFriend
end

function plyMeta:IsDLibFriendType(target, tp)
	if not IsValid(target) then return false end
	if not tp then return false end
	local tab = self.DLib_Friends_currentStatus
	if not tab then return false end
	if not tab[target] then return false end
	return tab[target].status[tp] or false
end

net.receive('DLib.friendsystem', function(len, ply)
	if not IsValid(ply) then return end

	local amount = net.ReadUInt(8)
	local namount = 0
	ply.DLib_Friends_currentStatus = {}
	local target = ply.DLib_Friends_currentStatus

	for i = 1, amount do
		local rply, status = friends.Read()

		if IsValid(rply) then
			target[rply] = status
			namount = namount + 1
		end
	end

	net.Start('DLib.friendsystem')
	net.WriteEntity(ply)

	net.WriteUInt(namount, 8)

	for ply, status in pairs(target) do
		net.WritePlayer(ply)
		friends.Serealize(status)
	end

	net.SendOmit(ply)
end)
