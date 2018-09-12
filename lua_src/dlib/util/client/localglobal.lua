
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

function _G.LocalViewModel(...)
	local ply = LocalPlayer()
	if not IsValid(ply) then return NULL end
	return ply:GetViewModel(...)
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