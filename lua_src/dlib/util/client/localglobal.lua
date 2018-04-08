
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

local LocalPlayer = LocalPlayer
local IsValid = FindMetaTable('Entity').IsValid
local NULL = NULL

local function LocalWeapon()
	local ply = LocalPlayer()
	if not IsValid(ply) then return NULL end
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return NULL end
	return weapon
end

function _G.LocalClip1()
	local weapon = LocalWeapon()
	if not IsValid(weapon) then return -1 end
	return weapon:Clip1()
end

function _G.LocalClip2()
	local weapon = LocalWeapon()
	if not IsValid(weapon) then return -1 end
	return weapon:Clip2()
end

function _G.LocalMaxClip1()
	local weapon = LocalWeapon()
	if not IsValid(weapon) then return -1 end
	return weapon:GetMaxClip1()
end

function _G.LocalMaxClip2()
	local weapon = LocalWeapon()
	if not IsValid(weapon) then return -1 end
	return weapon:GetMaxClip2()
end

function _G.LocalAmmoType1()
	local weapon = LocalWeapon()
	if not IsValid(weapon) then return -1 end
	return weapon:GetPrimaryAmmoType()
end

function _G.LocalAmmoType2()
	local weapon = LocalWeapon()
	if not IsValid(weapon) then return -1 end
	return weapon:GetSecondaryAmmoType()
end

_G.ActiveWeapon = LocalWeapon
_G.GetActiveWeapon = LocalWeapon
_G.LocalWeapon = LocalWeapon

function _G.LocalPos()
	local ply = LocalPlayer()
	if not IsValid(ply) then return NULL end
	return ply:GetPos()
end

_G.LocalPosition = LocalPos

function _G.LocalAngles()
	local ply = LocalPlayer()
	if not IsValid(ply) then return NULL end
	return ply:GetAngles()
end

_G.LocalAng = LocalAngles