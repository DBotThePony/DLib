
-- Copyright (C) 2016-2018 DBot

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

net.pool('DLib.NetworkedVar')
net.pool('DLib.NetworkedVarFull')
net.pool('DLib.NetworkedRemove')

local nw = DLib.nw
local DLib = DLib

local entMeta = FindMetaTable('Entity')

function entMeta:SetDLibVar(var, val)
	var = var:lower()
	local data, isGlobal = nw.GetNetworkDataTable(self)

	if isGlobal and data[var] ~= val then
		local uid = self:EntIndex()
		net.Start('DLib.NetworkedVar')
		net.WriteUInt(nw.NetworkVars[var].crcnw, 32)
		net.WriteUInt(uid, 12)
		nw.NetworkVars[var].send(val)
		net.Broadcast()
	end

	data[var] = val

	hook.Run('DLib.EntityVarsChanges', self, var, val)
end

local function NetworkedVarFull(len, ply, auto)
	ply.DLib_NetowrkingFullLast = ply.DLib_NetowrkingFullLast or 0
	if ply.DLib_NetowrkingFullLast > CurTimeL() then return false end
	ply.DLib_NetowrkingFullLast = CurTimeL() + 10

	local reply = {}

	for uid, data in pairs(nw.NETWORK_DB) do
		table.insert(reply, uid)
	end

	hook.Run('DLib.NetworkedVarFull', ply, auto)

	net.Start('DLib.NetworkedVarFull')
	net.WriteUInt(#reply, 16)

	for i, value in ipairs(reply) do
		local data = nw.NETWORK_DB[value]

		net.WriteUInt(value, 12)
		hook.Run('DLib.PreNWSendVars', ply, data)

		for var, val in pairs(data) do
			if nw.NetworkVars[var] then
				net.WriteUInt(nw.NetworkVars[var].crcnw, 32)
				nw.NetworkVars[var].send(val)
			end
		end

		net.WriteUInt(0, 32)
	end

	net.Send(ply)

	return true
end

local function EntityRemoved(ent)
	if player.GetCount() == 0 then return end
	if game.SinglePlayer() and CurTime() < 10 then return end
	local euid = ent:EntIndex()
	if not nw.NETWORK_DB[euid] then return end

	nw.NETWORK_DB[euid] = nil

	timer.Simple(0, function()
		net.Start('DLib.NetworkedRemove')
		net.WriteUInt(euid, 12)
		net.Broadcast()
	end)
end

local function command(ply)
	if not IsValid(ply) then return end
	NetworkedVarFull(nil, ply, true)
end

concommand.Add('dlib_nw', command)
hook.Add('EntityRemoved', 'DLib.Networking', EntityRemoved)
net.Receive('DLib.NetworkedVarFull', NetworkedVarFull)
