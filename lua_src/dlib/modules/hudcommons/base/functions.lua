
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

local meta = DLib.FindMetaTable('HUDCommonsBase')
local DLib = DLib
local LocalPlayer = LocalPlayer
local LocalWeapon = LocalWeapon
local IsValid = FindMetaTable('Entity').IsValid
local table = table
local surface = surface

function meta:GetWeapon()
	local ply = self:SelectPlayer()

	if ply == LocalPlayer() then
		return LocalWeapon()
	end

	return ply:GetActiveWeapon() or NULL
end

function meta:HasWeapon()
	return IsValid(self:GetWeapon())
end

function meta:GetPreviousWeapon()
	return IsValid(self.prevWeapon) and self.prevWeapon or self:GetWeapon()
end

function meta:SafeWeaponCall(func, ifNone, ...)
	local wep = self:GetWeapon()

	if not IsValid(wep) then
		return ifNone
	end
end

function meta:RegisterRegularVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		return localPlayer[funcName](localPlayer)
	end)

	return newSelf
end

function meta:RegisterRegularWeaponVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		local wep = hudSelf:GetWeapon()

		if IsValid(wep) then
			return wep[funcName](wep)
		else
			return newSelf.default()
		end
	end)

	return newSelf
end

function meta:CreateFont(fontBase, fontData)
	local font = self:GetID() .. fontBase
	local fontNames = {}

	fontNames.REGULAR = font .. '_REGULAR'
	fontNames.ITALIC = font .. '_ITALIC'

	fontNames.STRIKE = font .. '_STRIKE'
	fontNames.STRIKE_SHARP = font .. '_STRIKE'
	fontNames.BLURRY = font .. '_BLURRY'
	fontNames.BLURRY_STRIKE = font .. '_BLURRY_STRIKE'
	fontNames.STRIKE_BLURRY = font .. '_BLURRY_STRIKE'

	fontNames.STRIKE_ITALIC = font .. '_STRIKE_ITALIC'
	fontNames.STRIKE_SHARP_ITALIC = font .. '_STRIKE_SHARP_ITALIC'
	fontNames.BLURRY_ITALIC = font .. '_BLURRY_ITALIC'

	fontNames.BLURRY_STRIKE_ITALIC = font .. '_BLURRY_STRIKE_ITALIC'
	fontNames.STRIKE_BLURRY_ITALIC = font .. '_BLURRY_STRIKE_ITALIC'

	fontData.extended = true

	surface.CreateFont(fontNames.REGULAR, fontData)

	do
		local newData = table.Copy(fontData)
		newData.italic = true
		surface.CreateFont(fontNames.ITALIC, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.scanlines = 4
		newData.blursize = 8
		surface.CreateFont(fontNames.STRIKE, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.scanlines = 4
		newData.blursize = 16
		surface.CreateFont(fontNames.BLURRY_STRIKE, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.italic = true
		newData.scanlines = 4
		newData.blursize = 16
		surface.CreateFont(fontNames.BLURRY_STRIKE_ITALIC, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.blursize = 8
		surface.CreateFont(fontNames.BLURRY, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.scanlines = 4
		surface.CreateFont(fontNames.STRIKE_SHARP, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.italic = true
		newData.scanlines = 4
		newData.blursize = 8
		surface.CreateFont(fontNames.STRIKE_ITALIC, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.italic = true
		newData.blursize = 8
		surface.CreateFont(fontNames.BLURRY_ITALIC, newData)
	end

	do
		local newData = table.Copy(fontData)
		newData.italic = true
		newData.scanlines = 4
		surface.CreateFont(fontNames.STRIKE_SHARP_ITALIC, newData)
	end

	return fontNames
end
