
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
