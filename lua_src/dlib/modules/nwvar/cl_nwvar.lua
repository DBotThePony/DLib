
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

local entMeta = FindMetaTable('Entity')

function entMeta:SetDLibVar(var, val)
	var = var:lower()
	local data = nw.GetNetworkDataTable(self)
	data[var] = val
	hook.Run('DLib.EntityVarsChanges', self, var, val)
end

local function NetworkedRemove()
	local uid = net.ReadUInt(12)
	nw.NETWORK_DB[uid] = nil
end

local function NetworkedVar()
	local id = net.ReadUInt(32)

	local data, var

	for k, v in pairs(nw.NetworkVars) do
		if v.crc == id then
			data = v
			var = k
			break
		end
	end

	if not data then return end

	local uid = net.ReadUInt(12)
	nw.NETWORK_DB[uid] = nw.NETWORK_DB[uid] or {}
	nw.NETWORK_DB[uid][var] = data.receive()

	local ent = Entity(uid)

	if IsValid(ent) then
		hook.Run('DLib.EntityVarsChanges', ent, var, ent:DLibVar(var))
	else
		hook.Run('DLib.EntityVarsChangesRaw', uid, var, nw.NETWORK_DB[uid][var])
	end
end

local function NetworkedEntityVars()
	local uid = net.ReadUInt(12)
	local count = net.ReadUInt(16)

	nw.NETWORK_DB[uid] = nw.NETWORK_DB[uid] or {}
	hook.Run('DLib.PreNWReceiveVars', uid, nw.NETWORK_DB[uid])

	for i = 1, count do
		local id = net.ReadUInt(32)
		local data, var

		for k, v in pairs(nw.NetworkVars) do
			if v.crc == id then
				data = v
				var = k
				break
			end
		end

		if data then
			nw.NETWORK_DB[uid][var] = data.receive()
		end
	end
end

local Initialize = false

local function KeyPress()
	Initialize = true
	hook.Remove('KeyPress', 'DLib.NWRequire')
	net.Start('DLib.NetworkedVarFull')
	net.SendToServer()
end

net.Receive('DLib.NetworkedRemove', NetworkedRemove)
net.Receive('DLib.NetworkedEntityVars', NetworkedEntityVars)
net.Receive('DLib.NetworkedVar', NetworkedVar)
hook.Add('KeyPress', 'DLib.NWRequire', KeyPress)
