
-- Copyright (C) 2017-2018 DBot

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


local DLib = DLib
local util = util
local pairs = pairs
local ipairs = ipairs
local RealTimeL = RealTimeL
local GetConVar = GetConVar
local net = net
local table = table
local IsValid = IsValid
local LocalPlayer = LocalPlayer

if SERVER then
	net.pool('DLib.getinfo.replicate')
end

local plyMeta = FindMetaTable('Player')
local getinfo = DLib.module('getinfo', nil, true)

getinfo.bank = getinfo.bank or {}
getinfo.bankCRC = getinfo.bankCRC or {}
getinfo.bankOptimized = {}

function getinfo.Replicate(cvarname, valuetype, default)
	valuetype = valuetype or 'boolean'
	local crc = util.CRC(cvarname)
	local writeFunc, readFunc

	if valuetype == 'boolean' then
		readFunc = net.ReadBool
		writeFunc = net.WriteBool
		DLib.nw.poolBoolean(cvarname, default)
	elseif valuetype == 'integer' or valuetype == 'number' then
		readFunc = net.GReadInt(val)
		writeFunc = net.GWriteInt(val)
		DLib.nw.poolInt(cvarname, default)
	elseif valuetype == 'uinteger' then
		readFunc = net.GReadUInt(val)
		writeFunc = net.GWriteUInt(val)
		DLib.nw.poolUInt(cvarname, default)
	else
		readFunc = net.ReadString
		writeFunc = net.WriteString
		default = tostring(default)
		valuetype = 'string'
		DLib.nw.poolString(cvarname, default)
	end

	getinfo.bank[cvarname] = {
		crc = crc,
		uid = tonumber(crc),
		created = RealTimeL(),
		cvar = GetConVar(cvarname),
		default = default,
		valuetype = valuetype,
		id = cvarname,
		cvarname = cvarname,
		writeFunc = writeFunc,
		readFunc = readFunc,
	}

	getinfo.bankCRC[crc] = getinfo.bank[cvarname]
	getinfo.bankCRC[getinfo.bank[cvarname].uid] = getinfo.bank[cvarname]

	getinfo.Rebuild()
end

getinfo.Register = getinfo.Replicate

function getinfo.Rebuild()
	getinfo.bankOptimized = {}

	for cvar, data in pairs(getinfo.bank) do
		table.insert(getinfo.bankOptimized, data)
	end

	return getinfo.bankOptimized
end

getinfo.Rebuild()

if CLIENT then
	timer.Create('DLib.getinfo.replication', 10, 0, function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		net.Start('DLib.getinfo.replicate')

		for i, data in ipairs(getinfo.bankOptimized) do
			data.cvar = data.cvar or GetConVar(data.id)
			local val = data.cvar:GetByType(data.valuetype)

			--if val ~= data.oldval then
				net.WriteUInt(data.uid, 32)
				data.writeFunc(val)

				ply:SetDLibVar(data.id, val)
				data.oldval = val
			--end
		end

		net.WriteUInt(0, 32)

		net.SendToServer()
	end)
else
	net.receive('DLib.getinfo.replicate', function(len, ply)
		if not IsValid(ply) then return end
		local nextID = net.ReadUInt(32)

		while nextID ~= 0 and getinfo.bankCRC[nextID] do
			local bank = getinfo.bankCRC[nextID]

			local val = bank.readFunc()
			ply:SetDLibVar(bank.id, val)

			nextID = net.ReadUInt(32)
		end
	end)
end

function plyMeta:GetInfoDLib(cvarname)
	if getinfo.bank[cvarname] then
		return self:DLibVar(cvarname)
	else
		return self:GetInfo(cvarname)
	end
end

return getinfo
