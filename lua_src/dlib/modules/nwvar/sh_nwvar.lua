
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

nw.NETWORK_DB = nw.NETWORK_DB or {}
nw.NetworkVars = nw.NetworkVars or {}

function entMeta:DLibVar(var, ifNothing)
	var = var:lower()
	local uid = self:EntIndex()

	if uid > 0 then
		local data = nw.NETWORK_DB[uid]

		if not data or data[var] == nil then
			if ifNothing ~= nil then
				return ifNothing
			else
				return nw.NetworkVars[var].default()
			end
		end

		return data[var]
	else
		self.DLibVars = self.DLibVars or {}

		if self.DLibVars[var] == nil then
			if ifNothing ~= nil then
				return ifNothing
			else
				return nw.NetworkVars[var].default()
			end
		end

		return self.DLibVars[var]
	end
end

function nw.GetNetworkDataTable(self)
	local uid = self:EntIndex()

	if uid > 0 then
		nw.NETWORK_DB[uid] = nw.NETWORK_DB[uid] or {}
		return nw.NETWORK_DB[uid], true
	else
		self.DLibVars = self.DLibVars or {}
		return self.DLibVars, false
	end
end

function nw.var(id, send, receive, default)
	if type(default) ~= 'function' then
		local dval = default
		default = function() return dval end
	end

	id = id:lower()

	nw.NetworkVars[id] = {
		send = send,
		receive = receive,
		default = default,
		ID = id,
		crc = util.CRC(id)
	}

	nw.NetworkVars[id].crcnw = tonumber(nw.NetworkVars[id].crc)
end

function nw.poolInt(id, default, val)
	val = val or 32
	return nw.var(id, net.GWriteInt(val), net.GReadInt(val), default or 0)
end

function nw.poolUInt(id, default, val)
	val = val or 32
	return nw.var(id, net.GWriteUInt(val), net.GReadUInt(val), default or 0)
end

function nw.poolString(id, default)
	return nw.var(id, net.WriteString, net.ReadString, default or '')
end

function nw.poolBoolean(id, default)
	return nw.var(id, net.WriteBool, net.ReadBool, default or '')
end

function nw.poolFloat(id, default)
	return nw.var(id, net.WriteFloat, net.ReadFloat, default or '')
end

function nw.poolEntity(id, default)
	return nw.var(id, net.WriteEntity, net.ReadEntity, default or '')
end

nw.pool = nw.var
nw.RegisterNetworkVar = nw.RegisterNetworkVar
