
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

-- TODO: Move all addons to NW2
local entMeta = FindMetaTable('Entity')

local nw = DLib.nw
local DLib = DLib

nw.NETWORK_DB = nw.NETWORK_DB or {}
nw.NetworkVars = nw.NetworkVars or {}

function entMeta:DLibVar(var, ifNothing)
	if not self:IsValid() then return ifNothing end
	var = var:lower()
	if not nw.NetworkVars[var] then return ifNothing end

	local data = nw.GetNetworkDataTable(self)

	if data[var] == nil then
		if ifNothing ~= nil then
			return ifNothing
		else
			return nw.NetworkVars[var].default()
		end
	end

	return data[var]
end

entMeta.GetDLibVar = entMeta.DLibVar

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
	if default == nil then default = false end
	return nw.var(id, net.WriteBool, net.ReadBool, default)
end

function nw.poolFloat(id, default)
	return nw.var(id, net.WriteFloat, net.ReadFloat, 0)
end

function nw.poolEntity(id, default)
	return nw.var(id, net.WriteEntity, net.ReadEntity, 0)
end

nw.pool = nw.var
nw.RegisterNetworkVar = nw.RegisterNetworkVar

do
	local values = {}

	for key, val in pairs(nw) do
		if type(val) == 'function' then
			table.insert(values, {key, val})
		end
	end

	for i, data in ipairs(values) do
		nw[data[1]:sub(1, 1):upper() .. data[1]:sub(2)] = data[2]
	end
end
