
-- Copyright (C) 2017-2019 DBot

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


local meta = DLib.FindMetaTable('HUDCommonsBase')
local DLib = DLib
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

		if weapon:IsValid() and weapon ~= gweapon then
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

	@returns
	boolean
]]
function meta:ShouldDisplayAmmo()
	return self:HasWeapon() and self:GetWeapon().DrawAmmo ~= false and (self:GetVarClipMax1() > 0 or self:GetVarClipMax2() > 0 or self:GetVarAmmoType1() ~= -1 or self:GetVarAmmoType2() ~= -1)
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmo

	@client

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmo()
	return self:HasWeapon() and self:GetWeapon().DrawAmmo ~= false and (self:GetVarClipMax2() > 0 or self:GetVarClip2() > 0 or self:GetVarAmmoType2() ~= -1)
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmo2

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmo2()
	return self:HasPredictedWeapon() and self:PredictSelectWeapon().DrawAmmo ~= false and (self:GetVarClipMax1_Select() > 0 or self:GetVarClipMax2_Select() > 0 or self:GetVarAmmoType1_Select() ~= -1 or self:GetVarAmmoType2_Select() ~= -1)
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplaySecondaryAmmo2

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplaySecondaryAmmo2()
	return self:HasPredictedWeapon() and self:PredictSelectWeapon().DrawAmmo ~= false and (self:GetVarClipMax2_Select() > 0 or self:GetVarClip2_Select() > 0 or self:GetVarAmmoType2_Select() ~= -1)
end

--[[
	@doc
	@fname HUDCommonsBase:SelectSecondaryAmmoReady

	@client

	@returns
	number
]]
function meta:SelectSecondaryAmmoReady()
	if self:GetVarClipMax2() == 0 then
		return 0
	end

	return self:GetVarClip2()
end

--[[
	@doc
	@fname HUDCommonsBase:SelectSecondaryAmmoReady2

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number
]]
function meta:SelectSecondaryAmmoReady2()
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
	if self:GetVarAmmoType2() == -1 then
		return -1
	end

	return self:GetVarAmmo2()
end

--[[
	@doc
	@fname HUDCommonsBase:SelectSecondaryAmmoStored2

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	number
]]
function meta:SelectSecondaryAmmoStored2()
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
	return self:GetVarAmmoType2_Select() ~= -1
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoStored

	@client

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoStored()
	return self:HasWeapon() and
		(self:GetVarClipMax1() > 0 or self:GetVarClipMax2() > 0) and
		(self:GetVarAmmo1() >= 0 or self:GetVarAmmo2() >= 0) and
		(self:IsValidAmmoType1() or self:IsValidAmmoType2())
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoStored2

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoStored2()
	return self:HasPredictedWeapon() and
		(self:GetVarClipMax1_Select() > 0 or self:GetVarClipMax2_Select() > 0) and
		(self:GetVarAmmo1_Select() >= 0 or self:GetVarAmmo2_Select() >= 0) and
		(self:IsValidAmmoType1_Select() or self:IsValidAmmoType2_Select())
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoReady

	@client

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoReady()
	return self:HasWeapon() and (self:GetVarClipMax1() > 0 or self:GetVarClipMax2() > 0)
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDisplayAmmoReady2

	@client

	@desc
	Based on `self:PredictSelectWeapon()` instead of `self:GetWeapon()`
	@enddesc

	@returns
	boolean
]]
function meta:ShouldDisplayAmmoReady2()
	return self:HasPredictedWeapon() and (self:GetVarClipMax1_Select() > 0 or self:GetVarClipMax2_Select() > 0)
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

	table.insert(self.positionsConVars, {
		name = name:formatname2(),
		oname = name,
		cvarX = cvarX,
		cvarY = cvarY
	})

	return callable, callable2
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
		return localPlayer[funcName](localPlayer)
	end)

	return newSelf
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
	if self:GetVarClipMax1() <= 0 then return 1 end
	if self:GetVarClip1() <= 0 then return 0 end
	if self:GetVarClipMax1() <= self:GetVarClip1() then return 1 end
	return (self:GetVarClip1() / self:GetVarClipMax1()):clamp(0, 1)
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
	if self:GetVarClipMax2() <= 0 then return 1 end
	if self:GetVarClip2() <= 0 then return 0 end
	if self:GetVarClipMax2() <= self:GetVarClip2() then return 1 end
	return (self:GetVarClip2() / self:GetVarClipMax2()):clamp(0, 1)
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
	if not self:ShouldDisplayAmmo2() then return 1 end
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
	if not self:ShouldDisplaySecondaryAmmo2() then return 1 end
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

	while IsValid2(vehicle) and (vehicle:IsVehicle() or not vehicle:GetClass():startsWith('prop_')) do
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

	while IsValid2(vehicle) and (vehicle:IsVehicle() or not vehicle:GetClass():startsWith('prop_')) do
		if MEM[vehicle] then break end
		lastVehicle = vehicle

		if vehicle:IsVehicle() then
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

	local cvarFont = self:CreateConVar('font_' .. fontBase:lower(), fontData.font, 'Font for ' .. fontBase .. ' stuff', true)
	local weightVar = self:CreateConVar('fontw_' .. fontBase:lower(), fontData.weight, 'Font weight for ' .. fontBase .. ' stuff', true)
	local sizeVar = self:CreateConVar('fonts_' .. fontBase:lower(), fontData.osize or fontData.size, 'Font size for ' .. fontBase .. ' stuff', true)

	table.insert(self.fontCVars.font, cvarFont)
	table.insert(self.fontCVars.weight, weightVar)
	table.insert(self.fontCVars.size, sizeVar)

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

	local function buildFonts()
		fontData.font = cvarFont:GetString()
		fontData.weight = weightVar:GetInt()
		fontData.size = sizeVar:GetFloat() * fontAspectRatio
		local fontDatas = {}

		surface.CreateFont(fontNames.REGULAR, fontData)
		fontDatas[fontNames.REGULAR] = fontData
		fontData._mapping = 'REGULAR'

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			surface.CreateFont(fontNames.ITALIC, newData)
			fontDatas[fontNames.ITALIC] = newData
			newData._mapping = 'ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			newData.blursize = fontData.size / 8
			surface.CreateFont(fontNames.STRIKE, newData)
			fontDatas[fontNames.STRIKE] = newData
			newData._mapping = 'STRIKE'
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			newData.blursize = fontData.size / 4
			surface.CreateFont(fontNames.BLURRY_STRIKE, newData)
			fontDatas[fontNames.BLURRY_STRIKE] = newData
			newData._mapping = 'BLURRY_STRIKE'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			newData.blursize = fontData.size / 2
			surface.CreateFont(fontNames.BLURRY_STRIKE_ITALIC, newData)
			fontDatas[fontNames.BLURRY_STRIKE_ITALIC] = newData
			newData._mapping = 'BLURRY_STRIKE_ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.blursize = fontData.size / 8
			surface.CreateFont(fontNames.BLURRY, newData)
			fontDatas[fontNames.BLURRY] = newData
			newData._mapping = 'BLURRY'
		end

		do
			local newData = table.Copy(fontData)
			newData.blursize = fontData.size / 16
			surface.CreateFont(fontNames.BLURRY_ROUGH, newData)
			fontDatas[fontNames.BLURRY_ROUGH] = newData
			newData._mapping = 'BLURRY_ROUGH'
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			surface.CreateFont(fontNames.STRIKE_SHARP, newData)
			fontDatas[fontNames.STRIKE_SHARP] = newData
			newData._mapping = 'STRIKE_SHARP'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			newData.blursize = 8
			surface.CreateFont(fontNames.STRIKE_ITALIC, newData)
			fontDatas[fontNames.STRIKE_ITALIC] = newData
			newData._mapping = 'STRIKE_ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.blursize = 8
			surface.CreateFont(fontNames.BLURRY_ITALIC, newData)
			fontDatas[fontNames.BLURRY_ITALIC] = newData
			newData._mapping = 'BLURRY_ITALIC'
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			surface.CreateFont(fontNames.STRIKE_SHARP_ITALIC, newData)
			fontDatas[fontNames.STRIKE_SHARP_ITALIC] = newData
			newData._mapping = 'STRIKE_SHARP_ITALIC'
		end

		for mapped, data in pairs(fontDatas) do
			local newData = table.Copy(data)
			newData.additive = true
			newData._mapping = newData._mapping .. '_ADDITIVE'
			fontNames[newData._mapping] = mapped .. '_ADDITIVE'
			surface.CreateFont(mapped .. '_ADDITIVE', newData)
		end

		for name, mapped in pairs(fontNames) do
			if type(mapped) == 'string' then
				surface.SetFont(mapped)
				fontNames[name .. '_SIZE_W'], fontNames[name .. '_SIZE_H'] = surface.GetTextSize('W')
			end
		end
	end

	buildFonts()
	self:TrackConVar('font_' .. fontBase:lower(), 'fonts', buildFonts)
	self:TrackConVar('fonts_' .. fontBase:lower(), 'fonts', buildFonts)
	self:TrackConVar('fontw_' .. fontBase:lower(), 'fonts', buildFonts)

	return fontNames
end

function meta:ScreenSizeChanged(ow, oh, w, h)
	for fontBase, fontData in pairs(self.fonts) do
		if fontData.osize then
			fontData.size = math.floor(ScreenSize(fontData.osize * 0.8) + 0.5)
			self:CreateFont(fontBase, fontData)
		end
	end
end
