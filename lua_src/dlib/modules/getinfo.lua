
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

local DLib = DLib
local util = util
local pairs = pairs
local ipairs = ipairs
local RealTimeL = RealTimeL
local GetConVar = GetConVar
local net = DLib.Net
local table = table
local IsValid = IsValid
local LocalPlayer = LocalPlayer

if SERVER then
	net.pool('DLib.GetInfo.replicate')
end

local plyMeta = FindMetaTable('Player')
local entMeta = FindMetaTable('Entity')
DLib.GetInfo = DLib.GetInfo or {}
local GetInfo = DLib.GetInfo
DLib.getinfo = GetInfo

GetInfo.Bank = GetInfo.Bank or {}
GetInfo.BankCRC = GetInfo.BankCRC or {}
GetInfo.BankOptimized = {}

--[[
	@doc
	@fname DLib.GetInfo.Replicate
	@args string cvarname, string valueType = 'string', any default

	@desc
	Marks a console variable for replication after it's creation (e.g. when you can specify FCVAR_USERINFO flag on a cvar)
	valueType can be either:
	`'boolean'`
	`'number'` or `'integer'`
	`'uinteger'`
	`'float'`
	`'string'` (by default, if type is invalid or missing)
	@enddesc
]]
function GetInfo.Replicate(cvarname, valuetype, default)
	valuetype = valuetype or 'boolean'
	local crc = util.CRC(cvarname)
	local writeFunc, readFunc, nwGet, nwSet

	if valuetype == 'boolean' then
		readFunc = net.ReadBool
		writeFunc = net.WriteBool
		nwSet = entMeta.SetNWBool
		nwGet = entMeta.GetNWBool
	elseif valuetype == 'integer' or valuetype == 'number' then
		readFunc = net.ReadInt32
		writeFunc = net.WriteInt32
		nwSet = entMeta.SetNWInt
		nwGet = entMeta.GetNWInt
	elseif valuetype == 'uinteger' then
		readFunc = net.ReadUInt32
		writeFunc = net.WriteUInt32
		nwSet = entMeta.SetNWUInt
		nwGet = entMeta.GetNWUInt
	elseif valuetype == 'float' then
		readFunc = net.ReadFloat
		writeFunc = net.WriteFloat
		nwSet = entMeta.SetNWFloat
		nwGet = entMeta.GetNWFloat
	else
		readFunc = net.ReadString
		writeFunc = net.WriteString
		default = tostring(default)
		valuetype = 'string'
		nwSet = entMeta.SetNWString
		nwGet = entMeta.GetNWString
	end

	if not nwSet then
		error('Missing NW Set for ' .. cvarname .. '! This should never happen')
	end

	GetInfo.Bank[cvarname] = {
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
		nwGet = nwGet,
		nwSet = nwSet,
	}

	if CLIENT then
		cvars.AddChangeCallback(cvarname, GetInfo.ReplicateNow, 'DLib.GetInfo')
	end

	GetInfo.BankCRC[crc] = GetInfo.Bank[cvarname]
	GetInfo.BankCRC[GetInfo.Bank[cvarname].uid] = GetInfo.Bank[cvarname]

	GetInfo.Rebuild()
end

GetInfo.Register = GetInfo.Replicate

--[[
	@doc
	@fname DLib.GetInfo.Rebuild

	@internal

	@returns
	table: optimized list for ipairs iteration
]]
function GetInfo.Rebuild()
	GetInfo.BankOptimized = {}

	for cvar, data in pairs(GetInfo.Bank) do
		table.insert(GetInfo.BankOptimized, data)
	end

	return GetInfo.BankOptimized
end

GetInfo.Rebuild()

if CLIENT then
	timer.Remove('DLib.GetInfo.replication')

	function GetInfo.ReplicateNow()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		for i, data in ipairs(GetInfo.BankOptimized) do
			data.cvar = data.cvar or GetConVar(data.id)
			local val = data.cvar:GetByType(data.valuetype)

			if val ~= data.oldval then
				net.Start('DLib.GetInfo.replicate')
				net.WriteUInt(data.uid, 32)
				data.writeFunc(val)

				data.nwSet(ply, data.id, val)
				data.oldval = val
				net.SendToServer()
			end
		end
	end

	local yield = coroutine.yield

	function GetInfo.ReplicateNowCT()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		for i, data in ipairs(GetInfo.BankOptimized) do
			data.cvar = data.cvar or GetConVar(data.id)
			local val = data.cvar:GetByType(data.valuetype)

			if val ~= data.oldval then
				net.Start('DLib.GetInfo.replicate')

				net.WriteUInt(data.uid, 32)
				data.writeFunc(val)

				data.nwSet(ply, data.id, val)
				data.oldval = val
				net.SendToServer()
			end

			yield()
		end
	end

	hook.AddTask('Think', 'DLib.GetInfo.ReplicateNowCT', GetInfo.ReplicateNowCT)
else
	net.receive('DLib.GetInfo.replicate', function(len, ply)
		if not IsValid(ply) then return end
		local bank = GetInfo.BankCRC[net.ReadUInt32()]
		if not bank then return end

		local val = bank.readFunc()
		bank.nwSet(ply, bank.id, val)
	end)
end

local cache = {}
local GetConVar_Internal = GetConVar_Internal

--[[
	@doc
	@fname Player:GetInfoDLib

	@args string cvarname

	@returns
	string: or nil
]]
function plyMeta:GetInfoDLib(cvarname)
	if GetInfo.Bank[cvarname] then
		return GetInfo.Bank[cvarname].nwGet(self, cvarname)
	elseif SERVER then
		return self:GetInfo(cvarname)
	else
		if cache[cvarname] == nil then
			cache[cvarname] = GetConVar_Internal(cvarname)
			if not cache[cvarname] then
				cache[cvarname] = false
			end
		end

		if not cache[cvarname] then
			cache[cvarname] = false
			return -- no value, :GetInfo() can return "no value" in vanilla
			-- even if gmod wiki stands it (always) return string
		end

		return cache[cvarname]:GetString()
	end
end

return GetInfo
