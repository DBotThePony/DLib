
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

local entMeta = FindMetaTable('Entity')

local nw = DLib.nw
local DLib = DLib

-- not even gonna document it
-- full candidate to remove

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
		if v.crcnw == id then
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

local function NetworkedVarFull(len)
	for i = 1, net.ReadUInt(16) do
		local uid = net.ReadUInt(12)

		nw.NETWORK_DB[uid] = nw.NETWORK_DB[uid] or {}
		hook.Run('DLib.PreNWReceiveVars', uid, nw.NETWORK_DB[uid])

		for i = 1, 1000 do
			local id = net.ReadUInt(32)
			if id == 0 then break end
			local data, var

			for k, v in pairs(nw.NetworkVars) do
				if v.crcnw == id then
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
end

local Initialize = false

local function KeyPress()
	Initialize = true
	hook.Remove('KeyPress', 'DLib.NWRequire')
	net.Start('DLib.NetworkedVarFull')
	net.SendToServer()
end

net.Receive('DLib.NetworkedRemove', NetworkedRemove)
net.Receive('DLib.NetworkedVarFull', NetworkedVarFull)
net.Receive('DLib.NetworkedVar', NetworkedVar)
hook.Add('KeyPress', 'DLib.NWRequire', KeyPress)
