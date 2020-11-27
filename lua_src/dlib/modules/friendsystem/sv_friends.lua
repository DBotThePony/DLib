
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

net.pool('DLib.friendsystem')

local Friend = DLib.Friend
local DLib = DLib

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

plyMeta.IsDLibFriendIn = plyMeta.IsDLibFriendType

net.receive('DLib.friendsystem', function(len, ply)
	if not IsValid(ply) then return end

	local amount = net.ReadUInt(8)
	local namount = 0
	ply.DLib_Friends_currentStatus = {}
	local target = ply.DLib_Friends_currentStatus

	for i = 1, amount do
		local rply, status = Friend.Read()

		if IsValid(rply) then
			target[rply] = status
			hook.Run('DLib_FriendModified', ply, status)
			namount = namount + 1
		else
			break
		end
	end

	net.Start('DLib.friendsystem')
	net.WritePlayer(ply)
	net.WriteUInt(namount, 8)

	for ply2, status in pairs(target) do
		net.WritePlayer(ply2)
		Friend.Serealize(status)
	end

	net.SendOmit(ply)
end)
