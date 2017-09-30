
-- Copyright (C) 2016-2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

util.AddNetworkString('DLib.NetworkedVar')
util.AddNetworkString('DLib.NetworkedEntityVars')
util.AddNetworkString('DLib.NetworkedVarFull')
util.AddNetworkString('DLib.NetworkedRemove')

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

local Clients = {}

local function SendTo(ply, tosend)
	if not IsValid(ply) then
		Clients[ply] = nil
		return
	end

	local uid = table.remove(tosend)

	if not uid then
		Clients[ply] = nil
		return
	end

	local data = nw.NETWORK_DB[uid]
	if not data then return end

	net.Start('DLib.NetworkedEntityVars')
	net.WriteUInt(uid, 12)
	net.WriteUInt(table.Count(data), 16)
	hook.Run('DLib.PreNWSendVars', ply, data)

	for var, val in pairs(data) do
		if type(var) == 'string' and type(val) ~= 'table' and nw.NetworkVars[var] then
			net.WriteUInt(nw.NetworkVars[var].crcnw, 32)
			nw.NetworkVars[var].send(val)
		end
	end

	net.Send(ply)
end

local RED = Color(200, 100, 100)

local function NetworkError(Message)
	DLib.Message(RED, debug.traceback(Message))
end

local function SendTimer()
	for i = 1, 5 do
		for ply, tosend in pairs(Clients) do
			xpcall(SendTo, NetworkError, ply, tosend)
		end
	end
end

local function NetworkedVarFull(len, ply, auto)
	ply.DLib_NetowrkingFullLast = ply.DLib_NetowrkingFullLast or 0
	if ply.DLib_NetowrkingFullLast > CurTime() then return false end
	ply.DLib_NetowrkingFullLast = CurTime() + 10

	local reply = {}

	for uid, data in pairs(nw.NETWORK_DB) do
		table.insert(reply, uid)
	end

	Clients[ply] = reply
	hook.Run('DLib.NetworkedVarFull', ply, auto)

	return true
end

local function EntityRemoved(ent)
	local euid = ent:EntIndex()

	for ply, tosend in pairs(Clients) do
		for i, uid in pairs(tosend) do
			if uid == euid then
				tosend[i] = nil
				break
			end
		end
	end

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
timer.Create('DLib.NetworkedVarFull', 0.1, 0, SendTimer)
