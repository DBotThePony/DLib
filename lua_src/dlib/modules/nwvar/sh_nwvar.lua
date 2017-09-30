
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
				return nw.NetworkVars[var].default
			end
		end

		return data[var]
	else
		self.DLibVars = self.DLibVars or {}

		if self.DLibVars[var] == nil then
			if ifNothing ~= nil then
				return ifNothing
			else
				return nw.NetworkVars[var].default
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

function nw.var(id, send, receive, type, default)
	if type(default) ~= 'function' then
		local dval = default
		default = function() return dval end
	end

	id = id:lower()

	nw.NetworkVars[id] = {
		send = send,
		receive = receive,
		type = type,
		default = default,
		ID = id,
		crc = util.CRC(id)
	}
end

nw.pool = nw.var
nw.RegisterNetworkVar = nw.RegisterNetworkVar
