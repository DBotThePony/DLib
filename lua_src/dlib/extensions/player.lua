
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


local GetAll = player.GetAll
local player = player
local ipairs = ipairs
local math = math
local tonumber = tonumber
local tostring = tostring
local table = table
local type = type

player.all = player.GetAll
player.getAll = player.GetAll

function player.InRange(position, range)
	range = range ^ 2

	local output = {}

	for i, ply in ipairs(player.GetAll()) do
		if ply:GetPos():DistToSqr(position) <= range then
			table.insert(output, ply)
		end
	end

	return output
end

-- Fix performance a bit
function player.GetBySteamID(steamid)
	steamid = steamid:upper()

	for i, ply in ipairs(player.GetAll()) do
		if steamid == ply:SteamID() then return ply end
	end

	return false
end

function player.GetBySteamID64(steamid)
	steamid = tostring(steamid)

	for i, ply in ipairs(player.GetAll()) do
		if steamid == ply:SteamID64() then return ply end
	end

	return false
end

function player.GetByUniqueID(id)
	for i, ply in ipairs(player.GetAll()) do
		if id == ply:UniqueID() then return ply end
	end

	return false
end

local plyMeta = FindMetaTable('Player')

function plyMeta:GetInfoInt(convar, ifNone)
	ifNone = ifNone or 0
	local info = self:GetInfoDLib(convar)
	return math.floor(tonumber(info or ifNone) or ifNone)
end

function plyMeta:GetInfoFloat(convar, ifNone)
	ifNone = ifNone or 0
	local info = self:GetInfoDLib(convar)
	return tonumber(info or ifNone) or ifNone
end

local LocalPlayer = LocalPlayer
local SERVER = SERVER

function plyMeta:EyeAnglesFixed()
	if SERVER or self ~= LocalPlayer() then
		return self:EyeAngles()
	end

	if not self:InVehicle() then
		return self:EyeAngles()
	end

	return self:GetVehicle():GetAngles() + self:EyeAngles()
end

function plyMeta:GetInfoBool(convar, ifNone)
	if ifNone == nil then ifNone = false end
	local info = self:GetInfoDLib(convar)

	if type(info) == 'nil' or type(info) == 'no value' then
		return ifNone
	end

	if type(info) == 'boolean' then
		return info
	end

	if convar == 'false' then return false end
	if convar == 'true' then return true end

	local num = tonumber(info)

	if not num then
		return ifNone
	end

	return num ~= 0
end

-- differents from GetInfo only by 100% returning string
function plyMeta:GetInfoString(convar, ifNone)
	ifNone = ifNone or ''

	local info = self:GetInfoDLib(convar)

	if type(info) == 'nil' or type(info) == 'no value' then
		return ifNone
	end

	return info
end
