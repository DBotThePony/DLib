
-- Copyright (C) 2016-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

net.pool('DLib.NetworkedVar')
net.pool('DLib.NetworkedVarFull')
net.pool('DLib.NetworkedRemove')

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

	if net.CompressOngoing then
		net.CompressOngoing()
	end

	net.Send(ply)

	return true
end

local function EntityRemoved(ent)
	local euid = ent:EntIndex()

	nw.NETWORK_DB[euid] = nil
	net.Start('DLib.NetworkedRemove')
	net.WriteUInt(euid, 12)
	net.Broadcast()
end

local function command(ply)
	if not IsValid(ply) then return end
	NetworkedVarFull(nil, ply, true)
end

concommand.Add('dlib_nw', command)
hook.Add('EntityRemoved', 'DLib.Networking', EntityRemoved)
net.Receive('DLib.NetworkedVarFull', NetworkedVarFull)
