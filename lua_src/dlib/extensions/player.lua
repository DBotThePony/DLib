
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local gplayer = _G.player
local GetAll = gplayer.GetAll
local player = DLib.module('player', 'player')
local ipairs = ipairs
local math = math
local tonumber = tonumber
local tostring = tostring
local table = table
local type = type

player.all = player.GetAll
player.getAll = player.GetAll

function player.inRange(position, range)
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

	for i, ply in ipairs(gplayer.GetAll()) do
		if steamid == ply:SteamID() then return ply end
	end

	return false
end

function player.GetBySteamID64(steamid)
	steamid = tostring(steamid)

	for i, ply in ipairs(gplayer.GetAll()) do
		if steamid == ply:SteamID64() then return ply end
	end

	return false
end

function player.GetByUniqueID(id)
	for i, ply in ipairs(gplayer.GetAll()) do
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

return player
