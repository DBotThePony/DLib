
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
local HUDCommons = DLib.HUDCommons
local meta = HUDCommons.BaseMetaObj
local LocalPlayer = LocalPlayer
local LocalWeapon = LocalWeapon
local IsValid2 = IsValid
local IsValid = FindMetaTable('Entity').IsValid
local table = table
local surface = surface
local math = math
local ScreenSize = ScreenSize
local RealTimeL = RealTimeL

--[[
	@doc
	@fname HUDCommonsBase:GetWeapon

	@client

	@returns
	Weapon: or NULL
]]
function meta:GetWeapon()
	local ply = self:SelectPlayer()

	if ply == LocalPlayer() then
		return LocalWeapon()
	end

	return ply:GetActiveWeapon() or NULL
end

--[[
	@doc
	@fname HUDCommonsBase:WeaponsInVehicle

	@client

	@returns
	boolean: whenever weapons are currently allowed
]]
function meta:WeaponsInVehicle()
	return not self:GetVarInVehicle() or self:GetVarWeaponsInVehicle()
end

--[[
	@doc
	@fname HUDCommonsBase:PredictSelectWeapon

	@client

	@desc
	HUD's method `self:LookupSelectWeapon()` must be present
	Provides builtin method of tracking last selected weapon in menu
	(not the one that was clicked!)
	Useless without `LookupSelectWeapon()` method defined by you in your HUD
	(and thus making functions which reliable on this useless too)
	Refer to 4HUD's/FFGSHUD code for example.
	@enddesc

	@returns
	Weapon: or NULL
]]
function meta:PredictSelectWeapon()
	if self.LookupSelectWeapon then
		local weapon, state = self:LookupSelectWeapon()
		local gweapon = self:GetWeapon()

		if state == nil then state = true end

		if IsValid(weapon) and weapon ~= gweapon then
			local rtime = RealTimeL()

			if state then
				if self.tryToSelectWeaponLast < rtime then
					self.tryToSelectWeaponFadeIn = rtime + 0.5
				end

				self.tryToSelectWeaponLast = rtime + 0.75
				self.tryToSelectWeaponLastEnd = rtime + 1.25
			end

			return weapon
		else
			return gweapon
		end
	end

	if not IsValid(self.tryToSelectWeapon) then
		return self:GetWeapon()
	end

	if self.tryToSelectWeaponLastEnd < RealTimeL() then
		return self:GetWeapon()
	end

	return self.tryToSelectWeapon
end

--[[
	@doc
	@fname HUDCommonsBase:HasPredictedWeapon

	@client

	@returns
	boolean
]]
function meta:HasPredictedWeapon()
	return IsValid(self:PredictSelectWeapon()) and self:PredictSelectWeapon() ~= self:GetWeapon()
end

--[[
	@doc
	@fname HUDCommonsBase:HasWeapon

	@client

	@returns
	boolean
]]
function meta:HasWeapon()
	return IsValid(self:GetWeapon())
end

--[[
	@doc
	@fname HUDCommonsBase:GetPreviousWeapon

	@client

	@returns
	Weapon: or NULL
]]
function meta:GetPreviousWeapon()
	return IsValid(self.prevWeapon) and self.prevWeapon or self:GetWeapon()
end

--[[
	@doc
	@fname HUDCommonsBase:SafeWeaponCall
	@args string funcname, any ifNone, vararg arguments

	@client

	@returns
	any
]]
function meta:SafeWeaponCall(func, ifNone, ...)
	local wep = self:GetWeapon()

	if not IsValid(wep) then
		return ifNone
	end

	return wep[func](wep, ...)
end

--[[
	@doc
	@fname HUDCommonsBase:SafeWeaponCall2
	@args string funcname, any ifNone, vararg arguments

	@client

	@desc
	calls `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	any
]]
function meta:SafeWeaponCall2(func, ifNone, ...)
	local wep = self:PredictSelectWeapon()

	if not IsValid(wep) then
		return ifNone
	end

	return wep[func](wep, ...)
end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponHUDShouldDraw
	@args string elem

	@client

	@desc
	A safe way to call current weapon's `HUDShouldDraw`
	@enddesc

	@returns
	boolean
]]
function meta:CallWeaponHUDShouldDraw(elem)
	local wep = self:GetWeapon()
	return not IsValid(wep) or not wep.HUDShoulDraw or wep:HUDShoulDraw(elem) ~= false
end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponHUDShouldDraw_Select
	@args string elem

	@client

	@desc
	A safe way to call currently predicted (select) weapon's `HUDShouldDraw`
	@enddesc

	@returns
	boolean
]]
function meta:CallWeaponHUDShouldDraw_Select(elem)
	local wep = self:PredictSelectWeapon()
	return not IsValid(wep) or not wep.HUDShoulDraw or wep:HUDShoulDraw(elem) ~= false
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayWeaponStats

	@client

	@returns
	boolean
]]
function meta:ShouldDisplayWeaponStats()
	return self:HasWeapon()
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmo

	@client

	@desc
	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmo()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return true
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		return cache.Draw and (cache.PrimaryAmmo ~= nil or cache.PrimaryClip ~= nil)
	end

	return self:HasWeapon()
		and self:GetWeapon().DrawAmmo ~= false
		and self:CallWeaponHUDShouldDraw('CHudAmmo')
		and (self:GetVarClipMax1() > 0 or
			self:GetVarAmmoType1() ~= -1)
		and self:WeaponsInVehicle()
end

meta.ShouldDisplayAmmo1 = meta.ShouldDisplayAmmo

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmo

	@client

	@desc
	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmo()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		return cache.Draw and cache.SecondaryAmmo ~= nil
	end

	return self:HasWeapon()
		and self:GetWeapon().DrawAmmo ~= false
		and self:CallWeaponHUDShouldDraw('CHudSecondaryAmmo')
		and (self:GetVarClipMax2() > 0 or
			self:GetVarClip2() > 0 or
			self:GetVarAmmoType2() ~= -1)
		and self:WeaponsInVehicle()
end

meta.ShouldDisplayAmmo2 = meta.ShouldDisplaySecondaryAmmo

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmo_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`

	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything

	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmo_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return true
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return cache.Draw and (cache.PrimaryAmmo ~= nil or cache.PrimaryClip ~= nil)
	end


	return self:HasPredictedWeapon()
		and self:PredictSelectWeapon().DrawAmmo ~= false
		and self:CallWeaponHUDShouldDraw_Select('CHudAmmo')
		and (self:GetVarClipMax1_Select() > 0 or
			self:GetVarAmmoType1_Select() ~= -1)
		and self:WeaponsInVehicle()
end

meta.ShouldDisplayAmmo1_Select = meta.ShouldDisplayAmmo_Select

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmo_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`

	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmo_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return cache.Draw and cache.SecondaryAmmo ~= nil
	end

	return self:HasPredictedWeapon()
		and self:PredictSelectWeapon().DrawAmmo ~= false
		and self:CallWeaponHUDShouldDraw_Select('CHudSecondaryAmmo')
		and (self:GetVarClipMax2_Select() > 0 or
			self:GetVarClip2_Select() > 0 or
			self:GetVarAmmoType2_Select() ~= -1)
		and self:WeaponsInVehicle()
end

meta.ShouldDisplayAmmo2_Select = meta.ShouldDisplaySecondaryAmmo_Select

--[[
	@doc
	@fname HUDCommonsBase:SelectSecondaryAmmoReady

	@client

	@returns
	number
]]
function meta:SelectSecondaryAmmoReady()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache and cache.SecondaryAmmo then
		return cache.SecondaryAmmo
	end

	if self:GetVarClipMax2() == 0 then
		return 0
	end

	return self:GetVarClip2()
end

--[[
	@doc
	@fname HUDCommonsBase:SelectSecondaryAmmoReady_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number
]]
function meta:SelectSecondaryAmmoReady_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache and cache.SecondaryAmmo then
		return cache.SecondaryAmmo
	end

	if self:GetVarClipMax2_Select() == 0 then
		return 0
	end

	return self:GetVarClip2_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:SelectSecondaryAmmoStored

	@client

	@returns
	number
]]
function meta:SelectSecondaryAmmoStored()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache and cache.SecondaryAmmo then
		return -1
	end

	if self:GetVarAmmoType2() == -1 then
		return -1
	end

	return self:GetVarAmmo2()
end

--[[
	@doc
	@fname HUDCommonsBase:SelectSecondaryAmmoStored_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number
]]
function meta:SelectSecondaryAmmoStored_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache and cache.SecondaryAmmo then
		return -1
	end

	if self:GetVarAmmoType2_Select() == -1 then
		return -1
	end

	return self:GetVarAmmo2_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:IsValidAmmoType1

	@client

	@returns
	boolean
]]
function meta:IsValidAmmoType1()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return true
	end

	--[[local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return cache.PrimaryAmmo ~= nil or cache.PrimaryClip ~= nil
	end]]

	return self:GetVarAmmoType1() ~= -1
end

--[[
	@doc
	@fname HUDCommonsBase:IsValidAmmoType2

	@client

	@returns
	boolean
]]
function meta:IsValidAmmoType2()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return false
	end

	--[[local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return cache.SecondaryAmmo ~= nil
	end]]

	return self:GetVarAmmoType2() ~= -1
end

--[[
	@doc
	@fname HUDCommonsBase:IsValidAmmoType1_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number
]]
function meta:IsValidAmmoType1_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return true
	end

	return self:GetVarAmmoType1_Select() ~= -1
end

--[[
	@doc
	@fname HUDCommonsBase:IsValidAmmoType2_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number
]]
function meta:IsValidAmmoType2_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return false
	end

	return self:GetVarAmmoType2_Select() ~= -1
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoStored

	@client

	@desc
	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoStored()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		return cache.Draw and cache.PrimaryAmmo ~= nil
	end

	return self:HasWeapon() and
		self:GetVarClipMax1() > 0 and
		self:GetVarAmmo1() >= 0 and
		self:IsValidAmmoType1()
end

meta.ShouldDisplayAmmo1Stored = meta.ShouldDisplayAmmoStored
meta.ShouldDisplayAmmoStored1 = meta.ShouldDisplayAmmoStored

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmoStored

	@client

	@desc
	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmoStored()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		return cache.Draw and cache.SecondaryAmmo ~= nil
	end

	return self:HasWeapon() and
		(self:GetVarClipMax2() > 0 or
		self:GetVarAmmo2() >= 0 or
		self:IsValidAmmoType2())
end

meta.ShouldDisplayAmmo2Stored = meta.ShouldDisplaySecondaryAmmoStored
meta.ShouldDisplayAmmoStored2 = meta.ShouldDisplaySecondaryAmmoStored

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoStored_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`

	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoStored_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return cache.Draw and cache.PrimaryAmmo ~= nil
	end

	return self:HasPredictedWeapon() and
		self:GetVarClipMax1_Select() > 0 and
		self:GetVarAmmo1_Select() >= 0 and
		self:IsValidAmmoType1_Select()
end

meta.ShouldDisplayAmmo1Stored_Select = meta.ShouldDisplayAmmoStored_Select
meta.ShouldDisplayAmmoStored1_Select = meta.ShouldDisplayAmmoStored_Select

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmoStored_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`

	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmoStored_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return cache.Draw and cache.PrimaryAmmo ~= nil
	end

	return self:HasPredictedWeapon() and
		self:GetVarClipMax2_Select() > 0 and
		self:GetVarAmmo2_Select() >= 0 and
		self:IsValidAmmoType2_Select()
end

meta.ShouldDisplayAmmo2Stored_Select = meta.ShouldDisplaySecondaryAmmoStored_Select
meta.ShouldDisplayAmmoStored2_Select = meta.ShouldDisplaySecondaryAmmoStored_Select

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayAmmo1

	@client

	@desc
	Use this instead of direct `self:GetVarAmmo1()`
	@enddesc

	@returns
	boolean
]]
function meta:GetDisplayAmmo1()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return self:GetVarAmmo2()
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		if cache.PrimaryAmmo then
			return cache.PrimaryAmmo
		end

		return -1
	end

	return self:GetVarAmmo1()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayAmmo2

	@client

	@desc
	Use this instead of direct `self:GetVarAmmo2()`
	@enddesc

	@returns
	boolean
]]
function meta:GetDisplayAmmo2()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		if cache.SecondaryAmmo then
			return cache.SecondaryAmmo
		end

		return -1
	end

	return self:GetVarAmmo2()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayAmmo1_Select

	@client

	@desc
	Use this instead of direct `self:GetVarAmmo1_Select()`
	@enddesc

	@returns
	boolean
]]
function meta:GetDisplayAmmo1_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return self:GetVarAmmo2_Select()
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		if cache.PrimaryAmmo then
			return cache.PrimaryAmmo
		end

		return -1
	end

	return self:GetVarAmmo1_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayAmmo2_Select

	@client

	@desc
	Use this instead of direct `self:GetVarAmmo2_Select()`
	@enddesc

	@returns
	boolean
]]
function meta:GetDisplayAmmo2_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		if cache.SecondaryAmmo then
			return cache.SecondaryAmmo
		end

		return -1
	end

	return self:GetVarAmmo2_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoReady

	@client

	@desc
	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoReady()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		return cache.Draw and cache.PrimaryAmmo ~= nil or cache.PrimaryClip ~= nil
	end

	return self:HasWeapon() and self:GetVarClipMax1() > 0
end

meta.ShouldDisplayAmmoReady1 = meta.ShouldDisplayAmmoReady

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmoReady

	@client

	@desc
	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmoReady()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		return false
	end

	return self:HasWeapon() and (self:GetVarClipMax2() > 0 or self:GetVarClip2() > 0)
end

meta.ShouldDisplayAmmoReady2 = meta.ShouldDisplaySecondaryAmmoReady

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoReady_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`

	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything

	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoReady_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return cache.Draw and (cache.PrimaryAmmo ~= nil or cache.PrimaryClip ~= nil or cache.SecondaryAmmo ~= nil)
	end

	return self:HasPredictedWeapon() and self:GetVarClipMax1_Select() > 0
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmoReady_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`

	Three functions exist: `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady` and `ShouldDisplayAmmoStored`, along with their X2 and `Secondary` counterparts.
	To understand how these work, there would be a table which describes what should you do in each ase
	Depending on your HUD logic you can get next cases (assuming they go as `ShouldDisplayAmmo`, `ShouldDisplayAmmoReady`, `ShouldDisplayAmmoStored`):
	`false`, N/A, N/A - Don't show anything
	`true`, `false`, `false` - Use and show directly GetDisplayAmmo
	`true`, `true`, `false` - Weapon got a clip, but got no reserve ammo. This is a very rare case (and a bit odd to be used by SWEP makers)
	`true`, `false`, `true` - Odd case/Doesn't make sense, handle as you wish. Maybe handle as `true`, `false`, `false`
	`true`, `true`, `true` - Display everything

	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmoReady_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return false
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		return false
	end

	return self:HasPredictedWeapon() and (self:GetVarClipMax2_Select() > 0 or self:GetVarClip2_Select() > 0)
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayClip1

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClip1()` since
	this function obey weapon's !g:WEAPON:CustomAmmoDisplay method
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayClip1()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		if not cache.Draw then
			return -1
		end

		if cache.PrimaryAmmo and not cache.PrimaryClip then
			return cache.PrimaryAmmo
		end

		if not cache.PrimaryAmmo and cache.PrimaryClip then
			return cache.PrimaryClip
		end

		return cache.PrimaryClip or -1
	end

	return self:GetVarClip1()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayMaxClip1

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClipMax1()`
	currently directly proxy to `self:GetVarClipMax1()` due to limitation in !g:WEAPON:CustomAmmoDisplay method
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayMaxClip1()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return -1
	end

	return self:GetVarClipMax1()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayClip2

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClip2()` since
	this function obey weapon's !g:WEAPON:CustomAmmoDisplay method
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayClip2()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		if not cache.Draw then
			return -1
		end

		if cache.SecondaryAmmo then
			return cache.SecondaryAmmo
		end

		return -1
	end

	return self:GetVarClip2()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayMaxClip2

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClipMax2()`
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayMaxClip2()
	if self:GetVarWeaponClass() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache()

	if cache then
		if not cache.Draw then
			return -1
		end

		if cache.SecondaryAmmo then
			return cache.SecondaryAmmo
		end

		return -1
	end

	return self:GetVarClipMax2()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayClip1_Select

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClip1_Select()` since
	this function obey weapon's !g:WEAPON:CustomAmmoDisplay method
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayClip1_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		if not cache.Draw then
			return -1
		end

		if cache.PrimaryAmmo and not cache.PrimaryClip then
			return cache.PrimaryAmmo
		end

		if not cache.PrimaryAmmo and cache.PrimaryClip then
			return cache.PrimaryClip
		end

		return cache.PrimaryClip or -1
	end

	return self:GetVarClip1_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayMaxClip1

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClipMax1_Select()`
	currently directly proxy to `self:GetVarClipMax1()` due to limitation in !g:WEAPON:CustomAmmoDisplay method
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayMaxClip1_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return -1
	end

	return self:GetVarClipMax1_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayClip2_Select

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClip2_Select()` since
	this function obey weapon's !g:WEAPON:CustomAmmoDisplay method
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayClip2_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		if not cache.Draw then
			return -1
		end

		if cache.SecondaryAmmo then
			return cache.SecondaryAmmo
		end

		return -1
	end

	return self:GetVarClip2_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:GetDisplayMaxClip2_Select

	@client

	@desc
	You should use this for draw operations instead of `self:GetVarClipMax2_Select()`
	@enddesc

	@returns
	number: or -1 if no solution for ammo count is found
]]
function meta:GetDisplayMaxClip2_Select()
	if self:GetVarWeaponClass_Select() == 'weapon_slam' then
		return -1
	end

	local cache = self:GetVarCustomAmmoDisplayCache_Select()

	if cache then
		if not cache.Draw then
			return -1
		end

		if cache.SecondaryAmmo then
			return cache.SecondaryAmmo
		end

		return -1
	end

	return self:GetVarClipMax2_Select()
end

--[[
	@doc
	@fname HUDCommonsBase:DefinePosition

	@client

	@desc
	You should call this instead of `DLib.HUDCommons.Position2.DefinePosition` when making a HUD on `HUDCommonsBase`
	@enddesc

	@returns
	function: returns `x, y`
	function: returns screen side of element (`"LEFT"`, `"RIGHT"` or `"CENTER"`)
]]
function meta:DefinePosition(name, ...)
	local callable, cvarX, cvarY, callable2 = DLib.HUDCommons.Position2.DefinePosition(self:GetID() .. '_' .. name, ...)

	local fdata = {
		name = name:formatname2(),
		oname = name,
		cvarX = cvarX,
		cvarY = cvarY
	}

	for i, data in ipairs(self.positionsConVars) do
		if data.oname == name then
			self.positionsConVars[i] = fdata
			return callable, callable2
		end
	end

	table.insert(self.positionsConVars, fdata)

	return callable, callable2
end

--[[
	@doc
	@fname HUDCommonsBase:DefineStaticPosition

	@client

	@desc
	You should call this instead of `DLib.HUDCommons.Position2.DefinePosition` when making a HUD on `HUDCommonsBase`
	This also pass static function to `DefinePosition` which always return `false`, so element never shift on it's own
	@enddesc

	@returns
	function: returns `x, y`
	function: returns screen side of element (`"LEFT"`, `"RIGHT"` or `"CENTER"`)
]]
function meta:DefineStaticPosition(name, x, y)
	return self:DefinePosition(name, x, y, function() return false end)
end

--[[
	@doc
	@fname HUDCommonsBase:DefineFlexiblePosition
	@args string name, number x, number y, ConVar whenever

	@client

	@desc
	You should call this instead of `DLib.HUDCommons.Position2.DefinePosition` when making a HUD on `HUDCommonsBase`
	`whenever` is convar which control whenever hud element should shift or not
	@enddesc

	@returns
	function: returns `x, y`
	function: returns screen side of element (`"LEFT"`, `"RIGHT"` or `"CENTER"`)
]]
function meta:DefineFlexiblePosition(name, x, y, whenever)
	return self:DefinePosition(name, x, y, function() return whenever:GetBool() end)
end

--[[
	@doc
	@fname HUDCommonsBase:RegisterRegularVariable
	@args string var, string funcName, any default
	@client

	@desc
	Quickest way to define a direct variable of local player using direct getter
	@enddesc

	@returns
	table: variable's `self` table
]]
function meta:RegisterRegularVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		local --[[press]] F --[[to pay respects for Rubat at leasting doing something]] = localPlayer[funcName]

		if F then
			return F(localPlayer)
		else
			return default
		end
	end)

	return newSelf
end

--[[
	@doc
	@fname HUDCommonsBase:GetHealthFillage

	@client
	@returns
	number: between 0 and 1 inclusive
]]
function meta:GetHealthFillage()
	if self:GetVarHealth() <= 0 then return 0 end
	if self:GetVarMaxHealth() <= 0 then return 1 end
	return math.min(self:GetVarHealth() / self:GetVarMaxHealth(), 1)
end

--[[
	@doc
	@fname HUDCommonsBase:GetArmorFillage

	@client
	@returns
	number: between 0 and 1 inclusive
]]
function meta:GetArmorFillage()
	if self:GetVarArmor() <= 0 then return 0 end
	if self:GetVarMaxArmor() <= 0 then return 1 end
	return math.min(self:GetVarArmor() / self:GetVarMaxArmor(), 1)
end

--[[
	@doc
	@fname HUDCommonsBase:GetAmmoFillage1

	@client
	@returns
	number: between 0 and 1 inclusive
]]
function meta:GetAmmoFillage1()
	if not self:ShouldDisplayAmmo() then return 1 end
	if not self:ShouldDisplayAmmoReady() then return self:GetDisplayAmmo1() ~= 0 and 1 or 0 end
	if self:GetDisplayMaxClip1() <= 0 then return 1 end
	if self:GetDisplayClip1() <= 0 then return 0 end
	if self:GetDisplayMaxClip1() <= self:GetDisplayClip1() then return 1 end
	return (self:GetDisplayClip1() / self:GetDisplayMaxClip1()):clamp(0, 1)
end

--[[
	@doc
	@fname HUDCommonsBase:GetAmmoFillage2

	@client
	@returns
	number: between 0 and 1 inclusive
]]
function meta:GetAmmoFillage2()
	if not self:ShouldDisplaySecondaryAmmo() then return 1 end
	if not self:ShouldDisplaySecondaryAmmoReady() then return self:GetDisplayAmmo2() ~= 0 and 1 or 0 end
	if self:GetDisplayMaxClip2() <= 0 then return 1 end
	if self:GetDisplayClip2() <= 0 then return 0 end
	if self:GetDisplayMaxClip2() <= self:GetDisplayClip2() then return 1 end
	return (self:GetDisplayClip2() / self:GetDisplayMaxClip2()):clamp(0, 1)
end

--[[
	@doc
	@fname HUDCommonsBase:GetAmmoFillage2

	@client
	@returns
	number: between 0 and 1 inclusive
]]
function meta:GetAmmoFillageVehicle()
	if self:GetVarVehicleAmmoType() < 0 then return 1 end
	if self:GetVarVehicleAmmoClip() == 0 then return 0 end
	if self:GetVarVehicleAmmoMax() < 0 then return 1 end
	return (self:GetVarVehicleAmmoClip() / self:GetVarVehicleAmmoMax()):clamp(0, 1)
end

--[[
	@doc
	@fname HUDCommonsBase:GetAmmoFillage1_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number: between 0 and 1 inclusive
]]
function meta:GetAmmoFillage1_Select()
	if not self:ShouldDisplayAmmo_Select() then return 1 end
	if not self:ShouldDisplayAmmoReady_Select() then return self:GetDisplayAmmo1_Select() ~= 0 and 1 or 0 end
	if self:GetVarClipMax1_Select() <= 0 then return 1 end
	if self:GetVarClip1_Select() <= 0 then return 0 end
	if self:GetVarClipMax1_Select() <= self:GetVarClip1_Select() then return 1 end
	return (self:GetVarClip1_Select() / self:GetVarClipMax1_Select()):clamp(0, 1)
end

--[[
	@doc
	@fname HUDCommonsBase:GetAmmoFillage2_Select

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number: between 0 and 1 inclusive
]]
function meta:GetAmmoFillage2_Select()
	if not self:ShouldDisplaySecondaryAmmo_Select() then return 1 end
	if not self:ShouldDisplaySecondaryAmmoReady_Select() then return self:GetDisplayAmmo2_Select() ~= 0 and 1 or 0 end
	if self:GetVarClipMax2_Select() <= 0 then return 1 end
	if self:GetVarClip2_Select() <= 0 then return 0 end
	if self:GetVarClipMax2_Select() <= self:GetVarClip2_Select() then return 1 end
	return (self:GetVarClip2_Select() / self:GetVarClipMax2_Select()):clamp(0, 1)
end

--[[
	@doc
	@fname HUDCommonsBase:RegisterRegularWeaponVariable
	@args string var, string funcName, any default
	@client

	@desc
	Quickest way to define a direct variable of local weapon using direct getter
	@enddesc

	@returns
	table: variable's `self` table
]]
function meta:RegisterRegularWeaponVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)
	local newSelf2 = self:RegisterVariable(var .. '_Select', default)

	self:SetTickHook(var .. '_Select', function(self, hudSelf, localPlayer)
		local wep = hudSelf:PredictSelectWeapon()

		if IsValid(wep) and wep[funcName] then
			return wep[funcName](wep), wep
		else
			return newSelf.default(), wep
		end
	end)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		local wep = hudSelf:GetWeapon()

		if IsValid(wep) and wep[funcName] then
			return wep[funcName](wep), wep
		else
			return newSelf.default(), wep
		end
	end)

	return newSelf, newSelf2
end

--[[
	@doc
	@fname HUDCommonsBase:GetEntityVehicle
	@client

	@desc
	Attempts to find local vehicle more preciosly. Despite it's name, **this does not return the "vehicle" entity type**, but the entity
	that you can assume that being a vehicle. This can be a tank entity from Neurotec, car's body from Simfphys vehicles (the "Comedy Effect")
	and so on
	@enddesc

	@returns
	Entity: the found vehicle or NULL if none found
]]
function meta:GetEntityVehicle()
	local ply = self:SelectPlayer()
	if not IsValid(ply) then return NULL end

	local vehicle, lastVehicle = ply:GetVehicle(), NULL
	local MEM = {}

	while IsValid2(vehicle) and (type(vehicle) == 'Vehicle' or not vehicle:GetClass():startsWith('prop_')) do
		if MEM[vehicle] then break end
		lastVehicle = vehicle
		MEM[vehicle] = true
		vehicle = vehicle:GetParent()
	end

	return lastVehicle
end

--[[
	@doc
	@fname HUDCommonsBase:GetVehicleRecursive
	@client

	@desc
	same as `GetEntityVehicle`, except it always return `Vehicle` type or `NULL`
	Use this if you need to find a vehicle, and vehicle should be Source Engine based
	@enddesc

	@returns
	Vehicle: the found vehicle or NULL if none found
]]
function meta:GetVehicleRecursive()
	local ply = self:SelectPlayer()
	if not IsValid(ply) then return NULL end

	local vehicle, lastVehicle, lastValidVehicle = ply:GetVehicle(), NULL, NULL
	local MEM = {}

	while IsValid2(vehicle) and (type(vehicle) == 'Vehicle' or not vehicle:GetClass():startsWith('prop_')) do
		if MEM[vehicle] then break end
		lastVehicle = vehicle

		if type(vehicle) == 'Vehicle' then
			lastValidVehicle = vehicle
		end

		MEM[vehicle] = true
		vehicle = vehicle:GetParent()
	end

	return lastValidVehicle
end

--[[
	@doc
	@fname HUDCommonsBase:GetVehicle
	@client

	@desc
	simply returns a vehicle if local player is driving a one
	this should be used instead of direct `LocalPlayer():GetVehicle()`
	@enddesc

	@returns
	Vehicle: the found vehicle or NULL if none found
]]
function meta:GetVehicle()
	local ply = self:SelectPlayer()
	if not IsValid(ply) then return NULL end
	return ply:GetVehicle() or NULL
end

--[[
	@doc
	@fname HUDCommonsBase:RegisterVehicleVariable
	@args string var, string funcName, any default
	@client

	@desc
	Quickest way to define a direct variable of local `GetEntityVehicle()` using direct getter
	@enddesc

	@returns
	table: variable's `self` table
]]
function meta:RegisterVehicleVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		local veh = hudSelf:GetEntityVehicle()

		if IsValid(veh) and veh[funcName] then
			return veh[funcName](veh)
		else
			return newSelf.default()
		end
	end)

	return newSelf
end

--[[
	@doc
	@fname HUDCommonsBase:RegisterStrictVehicleVariable
	@args string var, string funcName, any default
	@client

	@desc
	Quickest way to define a direct variable of local vehicle using direct getter
	@enddesc

	@returns
	table: variable's `self` table
]]
function meta:RegisterStrictVehicleVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		local veh = hudSelf:GetVehicleRecursive()

		if IsValid(veh) and veh[funcName] then
			return veh[funcName](veh)
		else
			return newSelf.default()
		end
	end)

	return newSelf
end

--[[
	@doc
	@fname HUDCommonsBase:SetAllFontsTo
	@args string fontTarget
	@client
]]
function meta:SetAllFontsTo(fontTarget)
	for i, cvar in ipairs(self.fontCVars.font) do
		cvar:SetString(fontTarget)
	end
end

--[[
	@doc
	@fname HUDCommonsBase:SetAllWeightTo
	@args number fontWeight
	@client
]]
function meta:SetAllWeightTo(weightTarget)
	for i, cvar in ipairs(self.fontCVars.weight) do
		cvar:SetInt(weightTarget)
	end
end

--[[
	@doc
	@fname HUDCommonsBase:SetAllSizeTo
	@args number fontSize
	@client
]]
function meta:SetAllSizeTo(sizeTarget)
	for i, cvar in ipairs(self.fontCVars.size) do
		cvar:SetFloat(sizeTarget)
	end
end

--[[
	@doc
	@fname HUDCommonsBase:ResetFonts
	@client

	@desc
	Force a factory reset of fonts
	this **SHOULD NOT** be used without notification of end user!
	@enddesc
]]
function meta:ResetFonts()
	for i, cvar in ipairs(self.fontCVars.font) do
		cvar:Reset()
	end

	for i, cvar in ipairs(self.fontCVars.weight) do
		cvar:Reset()
	end

	for i, cvar in ipairs(self.fontCVars.size) do
		cvar:Reset()
	end
end

--[[
	@doc
	@fname HUDCommonsBase:ResetFontsSize
	@client

	@desc
	Force a factory reset of fonts sizes
	this **SHOULD NOT** be used without notification of end user!
	@enddesc
]]
function meta:ResetFontsSize()
	for i, cvar in ipairs(self.fontCVars.size) do
		cvar:Reset()
	end
end

--[[
	@doc
	@fname HUDCommonsBase:ResetFontsBare
	@client

	@desc
	Force a factory reset of fonts strings
	this **SHOULD NOT** be used without notification of end user!
	@enddesc
]]
function meta:ResetFontsBare()
	for i, cvar in ipairs(self.fontCVars.font) do
		cvar:Reset()
	end
end

--[[
	@doc
	@fname HUDCommonsBase:ResetFontsWeight
	@client

	@desc
	Force a factory reset of fonts weights
	this **SHOULD NOT** be used without notification of end user!
	@enddesc
]]
function meta:ResetFontsWeight()
	for i, cvar in ipairs(self.fontCVars.weight) do
		cvar:Reset()
	end
end

--[[
	@doc
	@fname HUDCommonsBase:CreateScalableFont
	@args string fontBase, table fontData
	@client

	@desc
	This should be used to define custom fonts
	`fontData` is a regular font data structure
	`size` property is multiplied by `ScreenSize` function
	Returns a table that you should use with `surface.SetFont`
	@enddesc

	@returns
	table: table of `"REGULAR"/"ITALIC"/"STRIKE"/...` -> `"font name"`
]]
function meta:CreateScalableFont(fontBase, fontData)
	fontData.osize = fontData.size
	fontData.size = math.floor(ScreenSize(fontData.size * 0.8) + 0.5)
	return self:CreateFont(fontBase, fontData)
end

--[[
	@doc
	@fname HUDCommonsBase:CreateFont
	@args string fontBase, table fontData
	@client
	@internal

	@desc
	Called internally from `CreateScalableFont` to define font convars and stuff
	Returns a table that you should use with `surface.SetFont`
	@enddesc

	@returns
	table: table of `"REGULAR"/"ITALIC"/"STRIKE"/...` -> `"font name"`
]]
function meta:CreateFont(fontBase, fontData)
	self.fonts[fontBase] = fontData
	local font = self:GetID() .. fontBase
	fontData.weight = fontData.weight or 500
	local defweight = fontData.weight
	local defsize = fontData.osize or fontData.size
	local cvarFont = self:CreateConVar('font_' .. fontBase:lower(), fontData.font, 'Font for ' .. fontBase .. ' stuff', true)
	local weightVar = self:CreateConVar('fontw_' .. fontBase:lower(), fontData.weight, 'Font weight for ' .. fontBase .. ' stuff', true)
	local sizeVar = self:CreateConVar('fonts_' .. fontBase:lower(), fontData.osize or fontData.size, 'Font size for ' .. fontBase .. ' stuff', true)

	if not table.qhasValue(self.fontCVars, fontBase) then
		table.insert(self.fontCVars, fontBase)
	end

	self:__InsertConvarIntoTable(self.fontCVars.font, cvarFont)
	self:__InsertConvarIntoTable(self.fontCVars.weight, weightVar)
	self:__InsertConvarIntoTable(self.fontCVars.size, sizeVar)

	local fontNames = self.fontsNames[fontBase] or {}
	self.fontsNames[fontBase] = fontNames

	local fontAspectRatio = 1

	if fontData.osize then
		fontAspectRatio = fontData.size / fontData.osize
	end

	fontNames.REGULAR = font .. '_REGULAR'
	fontNames.ITALIC = font .. '_ITALIC'

	fontNames.STRIKE = font .. '_STRIKE'
	fontNames.STRIKE_SHARP = font .. '_STRIKE'
	fontNames.BLURRY = font .. '_BLURRY'
	fontNames.BLURRY_ROUGH = font .. '_BLURRY_ROUGH'
	fontNames.BLURRY_STRIKE = font .. '_BLURRY_STRIKE'
	fontNames.STRIKE_BLURRY = font .. '_BLURRY_STRIKE'

	fontNames.STRIKE_ITALIC = font .. '_STRIKE_ITALIC'
	fontNames.STRIKE_SHARP_ITALIC = font .. '_STRIKE_SHARP_ITALIC'
	fontNames.BLURRY_ITALIC = font .. '_BLURRY_ITALIC'

	fontNames.BLURRY_STRIKE_ITALIC = font .. '_BLURRY_STRIKE_ITALIC'
	fontNames.STRIKE_BLURRY_ITALIC = font .. '_BLURRY_STRIKE_ITALIC'

	fontData.extended = true

	local fontDatas
	local fontSizes = {}

	local nameList = self.fontsNamesList[fontBase] or setmetatable({}, {
		__index = function(self, key)
			local fullName = fontNames[key]

			if fullName then
				surface.CreateFont(fullName, fontDatas[fullName])
				self[key] = fullName
			else
				fullName = fontSizes[key]

				if fullName then
					surface.SetFont(self[fullName])
					self[fullName .. '_SIZE_W'], self[fullName .. '_SIZE_H'] = surface.GetTextSize('W')
					return rawget(self, key)
				end

				return fullName
			end

			return fullName
		end
	})

	self.fontsNamesList[fontBase] = nameList

	local function buildFonts()
		for _, key in ipairs(table.GetKeys(nameList)) do
			nameList[key] = nil
		end

		fontData.font = cvarFont:GetString():trim()

		if fontData.font == '' then
			fontData.font = cvarFont:GetDefault()
		end

		fontData.weight = weightVar:GetInt(defweight):clamp(100, 1000)
		fontData.size = sizeVar:GetFloat(defsize):clamp(0.01, 70) * fontAspectRatio

		fontDatas = {}

		--surface.CreateFont(fontNames.REGULAR, fontData)
		fontDatas[fontNames.REGULAR] = fontData
		fontData._mapping = 'REGULAR'

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			--surface.CreateFont(fontNames.ITALIC, newData)
			fontDatas[fontNames.ITALIC] = newData
			newData._mapping = 'ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			newData.blursize = fontData.size / 8
			--surface.CreateFont(fontNames.STRIKE, newData)
			fontDatas[fontNames.STRIKE] = newData
			newData._mapping = 'STRIKE'
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			newData.blursize = fontData.size / 4
			--surface.CreateFont(fontNames.BLURRY_STRIKE, newData)
			fontDatas[fontNames.BLURRY_STRIKE] = newData
			newData._mapping = 'BLURRY_STRIKE'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			newData.blursize = fontData.size / 2
			--surface.CreateFont(fontNames.BLURRY_STRIKE_ITALIC, newData)
			fontDatas[fontNames.BLURRY_STRIKE_ITALIC] = newData
			newData._mapping = 'BLURRY_STRIKE_ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.blursize = fontData.size / 8
			--surface.CreateFont(fontNames.BLURRY, newData)
			fontDatas[fontNames.BLURRY] = newData
			newData._mapping = 'BLURRY'
		end

		do
			local newData = table.Copy(fontData)
			newData.blursize = fontData.size / 16
			--surface.CreateFont(fontNames.BLURRY_ROUGH, newData)
			fontDatas[fontNames.BLURRY_ROUGH] = newData
			newData._mapping = 'BLURRY_ROUGH'
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			--surface.CreateFont(fontNames.STRIKE_SHARP, newData)
			fontDatas[fontNames.STRIKE_SHARP] = newData
			newData._mapping = 'STRIKE_SHARP'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			newData.blursize = 8
			--surface.CreateFont(fontNames.STRIKE_ITALIC, newData)
			fontDatas[fontNames.STRIKE_ITALIC] = newData
			newData._mapping = 'STRIKE_ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.blursize = 8
			--surface.CreateFont(fontNames.BLURRY_ITALIC, newData)
			fontDatas[fontNames.BLURRY_ITALIC] = newData
			newData._mapping = 'BLURRY_ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			--surface.CreateFont(fontNames.STRIKE_SHARP_ITALIC, newData)
			fontDatas[fontNames.STRIKE_SHARP_ITALIC] = newData
			newData._mapping = 'STRIKE_SHARP_ITALIC'
		end

		for _, mapped in ipairs(table.GetKeys(fontDatas)) do
			local data = fontDatas[mapped]
			local newData = table.Copy(data)
			newData.additive = true
			newData._mapping = newData._mapping .. '_ADDITIVE'
			fontNames[newData._mapping] = mapped .. '_ADDITIVE'
			fontDatas[mapped .. '_ADDITIVE'] = newData
			--surface.CreateFont(mapped .. '_ADDITIVE', newData)
		end

		for name, mapped in pairs(fontNames) do
			if type(mapped) == 'string' then
				-- surface.SetFont(mapped)
				-- fontNames[name .. '_SIZE_W'], fontNames[name .. '_SIZE_H'] = surface.GetTextSize('W')
				fontSizes[name .. '_SIZE_W'], fontSizes[name .. '_SIZE_H'] = name, name
			end
		end

		hook.Run('HUDCommons_FontDataUpdates', self, name, fontNames, fontDatas)
	end

	buildFonts()
	self:TrackConVar('font_' .. fontBase:lower(), 'fonts', buildFonts)
	self:TrackConVar('fonts_' .. fontBase:lower(), 'fonts', buildFonts)
	self:TrackConVar('fontw_' .. fontBase:lower(), 'fonts', buildFonts)

	return nameList
end

function meta:ScreenSizeChanged(ow, oh, w, h)
	for fontBase, fontData in pairs(self.fonts) do
		if fontData.osize then
			fontData.size = math.floor(ScreenSize(fontData.osize * 0.8) + 0.5)
			self:CreateFont(fontBase, fontData)
		end
	end
end
