
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

local hud_fastswitch = GetConVar('hud_fastswitch')

local function LEmit(soundIn)
	return LocalPlayer():EmitSound(soundIn)
end

--[[
	@doc
	@fname HUDCommonsBase:InitializeWeaponSelector

	@client

	@desc
	Initialize weapon selector for current HUD, allowing you to use selector functions
	@enddesc
]]
function meta:InitializeWeaponSelector(autoDefineTimer)
	self.ENABLE_WEAPON_SELECT = self:CreateConVar('wepselect', '1', 'Enable HUD weapon selection')

	self.DrawWepSelection = false
	self.HoldKeyTrap = false
	self.PrevSelectWeapon = NULL
	self.SelectWeapon = NULL
	self.SelectWeaponForce = NULL
	self.SelectWeaponForceTime = 0
	self.SelectWeaponPos = -1
	self.LastSelectSlot = -1
	self.WeaponListInSlot = {}
	self.WeaponListInSlots = {}

	self.SELECTOR_AUTO_TIMER = autoDefineTimer

	self:AddHookCustom('HUDShouldDraw', '__ShouldDrawWeaponSelection', nil, 2)
	self:AddHookCustom('CreateMove', 'TrapWeaponSelect', nil, 2)
	self:AddHookCustom('PlayerBindPress', 'WeaponSelectionBind', nil, 2)

	if autoDefineTimer then
		self.SelectorStartFade = 0
		self.SelectorEndFade = 0
		self:AddHookCustom('Think', 'InternalSelectorThink', nil, 2)
	end
end

function meta:InternalSelectorThink()
	if not self.SELECTOR_AUTO_TIMER then return end
	if not self.DrawWepSelection then return end

	if self.SelectorEndFade <= RealTimeL() then
		self:CallWeaponSelectorEndInternal()
	end
end

function meta:GetSelectorAlpha()
	if not self.SELECTOR_AUTO_TIMER then
		return 255
	end

	return ((1 - RealTimeL():progression(self.SelectorStartFade, self.SelectorEndFade)) * 255):floor()
end

function meta:GetActiveSlot()
	return self.LastSelectSlot
end

function meta:GetActiveWeaponPos()
	return self.SelectWeaponPos
end

function meta:IsSlotSelectable(slotID)
	return self.WeaponListInSlots[slotID] and #self.WeaponListInSlots[slotID] ~= 0
end

function meta:GetWeapons()
	return self.WeaponListInSlots
end

--[[
	@doc
	@fname HUDCommonsBase:ShouldDrawWeaponSelection

	@client

	@returns
	boolean
]]
function meta:ShouldDrawWeaponSelection()
	return self.DrawWepSelection and self.ENABLE_WEAPON_SELECT and self.ENABLE_WEAPON_SELECT:GetBool() and self:GetVarAlive()
end

--[[
	@doc
	@fname HUDCommonsBase:GetSelectWeapon

	@client

	@returns
	Weapon: the weapon that currently user currently hovered over in select menu
]]
function meta:GetSelectWeapon()
	return self.SelectWeapon
end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorStart

	@client

	@desc
	This is called by BASE to let you know user want to select a weapon
	@enddesc
]]
function meta:CallWeaponSelectorStart()

end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorEnd

	@client

	@desc
	This is called by base from `CallWeaponSelectorEndInternal`, safe to be overriden
	@enddesc
]]
function meta:CallWeaponSelectorEnd()

end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorEndInternal

	@client

	@desc
	This is called by YOU or by base internally to reset some variables
	Do not override this! Override `CallWeaponSelectorEnd`
	@enddesc
]]
function meta:CallWeaponSelectorEndInternal()
	self:CallWeaponSelectorEnd()

	self.DrawWepSelection = false
	self.HoldKeyTrap = false
	self.PrevSelectWeapon = NULL
	self.SelectWeapon = NULL
	self.SelectWeaponPos = -1
	self.LastSelectSlot = -1
end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorDeny

	@client

	@desc
	This is called when user attempted to select a weapon, but conditions for opening specific menu are not met
	@enddesc
]]
function meta:CallWeaponSelectorDeny()

end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorMove
	@args boolean wasOpen

	@client

	@desc
	This is called **right after** user move cursor inside selector
	@enddesc
]]
function meta:CallWeaponSelectorMove(wasOpen)

end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorMoveInternal
	@args boolean wasOpen

	@client
	@internal
]]
function meta:CallWeaponSelectorMoveInternal(wasOpen)
	self.SelectorStartFade = RealTimeL() + 2
	self.SelectorEndFade = RealTimeL() + 2.5
end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorChosen
	@args Weapon chosenWeapon

	@client

	@desc
	This is called **right after** user has chosen weapon through any meanings
	@enddesc
]]
function meta:CallWeaponSelectorChosen(chosenWeapon)

end

--[[
	@doc
	@fname HUDCommonsBase:CallWeaponSelectorRefused

	@client

	@desc
	This is called after user refused to select any weapon (pressed mouse2)
	@enddesc
]]
function meta:CallWeaponSelectorRefused()

end

function meta:LookupSelectWeapon()
	return self.SelectWeapon, true
end

function meta:GetPrintNameFor(wep)
	if not IsValid(wep) then return '<missing>' end
	local class = wep:GetClass()
	local phrase = language.GetPhrase(class)
	return phrase ~= class and phrase or wep:GetPrintName()
end

local function sortTab(a, b)
	return a:GetSlotPos() < b:GetSlotPos()
end

function meta:UpdateWeaponList(weapons)
	weapons = weapons or self:SelectPlayer():GetWeapons()
	self.WeaponListInSlots[1] = {}
	self.WeaponListInSlots[2] = {}
	self.WeaponListInSlots[3] = {}
	self.WeaponListInSlots[4] = {}
	self.WeaponListInSlots[5] = {}
	self.WeaponListInSlots[6] = {}

	if #weapons == 0 then return end

	for i, weapon in pairs(weapons) do
		local slot = weapon:GetSlot() + 1

		if self.WeaponListInSlots[slot] then
			table.insert(self.WeaponListInSlots[slot], weapon)
		end
	end

	for i = 1, 6 do
		table.sort(self.WeaponListInSlots[i], sortTab)
	end
end

function meta:GetWeaponsInSlot(slotIn)
	for i, weapon in ipairs(self.WeaponListInSlots[slotIn]) do
		if not IsValid(weapon) then
			self:UpdateWeaponList(self:SelectPlayer():GetWeapons())
			break
		end
	end

	return self.WeaponListInSlots[slotIn]
end

function meta:__ShouldDrawWeaponSelection(element)
	if not self.ENABLE_WEAPON_SELECT:GetBool() then return end

	if element == 'CHudWeaponSelection' then
		return false
	end
end

local lastFrameAttack = false

function meta:TrapWeaponSelect(cmd)
	if not self.ENABLE_WEAPON_SELECT or not self.ENABLE_WEAPON_SELECT:GetBool() then return end

	if self.SelectWeaponForce:IsValid() and self.SelectWeaponForceTime > RealTimeL() then
		cmd:SelectWeapon(self.SelectWeaponForce)

		if LocalWeapon() == self.SelectWeaponForce then
			self.SelectWeaponForce = NULL
			self.SelectWeaponForceTime = 0
		end
	end

	if self:GetVarInDrive() then return end

	if not self.DrawWepSelection and not self.HoldKeyTrap then
		lastFrameAttack = cmd:KeyDown(IN_ATTACK)
		return
	end

	if not lastFrameAttack and cmd:KeyDown(IN_ATTACK) then
		cmd:SetButtons(cmd:GetButtons() - IN_ATTACK)

		if not self.HoldKeyTrap then
			self.DrawWepSelection = false
			self.HoldKeyTrap = true

			if self.SelectWeapon:IsValid() then
				if self.SelectWeapon ~= LocalWeapon() then
					self.PrevSelectWeapon = LocalWeapon()
				end

				cmd:SelectWeapon(self.SelectWeapon)
				self.SelectWeaponForce = self.SelectWeapon
				self.SelectWeaponForceTime = RealTimeL() + 2
				self.LastSelectSlot = -1
				LEmit('Player.WeaponSelected')

				self:CallWeaponSelectorChosen(self.SelectWeapon)
			end
		end
	elseif cmd:KeyDown(IN_ATTACK2) then
		cmd:SetButtons(cmd:GetButtons() - IN_ATTACK2)

		if not self.HoldKeyTrap then
			LEmit('Player.WeaponSelectionClose')
			self.DrawWepSelection = false
			self.HoldKeyTrap = true
			self:CallWeaponSelectorRefused()
			self:CallWeaponSelectorEndInternal()
		end
	else
		self.HoldKeyTrap = false
	end

	if lastFrameAttack and not cmd:KeyDown(IN_ATTACK) then
		lastFrameAttack = false
	end
end

local function BindSlot(self, ply, bind, pressed, weapons)
	if not self.ENABLE_WEAPON_SELECT and not self.ENABLE_WEAPON_SELECT:GetBool() then return end

	if not bind:startsWith('slot') then return end

	local newslot = bind:sub(5):tonumber()
	if newslot < 1 or newslot > 6 then return end
	local getweapons = self:GetWeaponsInSlot(newslot)

	if #getweapons == 0 then
		LEmit('Player.DenyWeaponSelection')
		self:CallWeaponSelectorDeny()
		self.DrawWepSelection = true
		self.SelectWeapon = NULL
		self.LastSelectSlot = newslot
		self.WeaponListInSlot = {}
		return
	end

	if newslot ~= self.LastSelectSlot then
		self.LastSelectSlot = newslot
		self.SelectWeapon = getweapons[1]
		self.SelectWeaponPos = 1
	else
		self.SelectWeaponPos = self.SelectWeaponPos + 1

		if self.SelectWeaponPos > #getweapons then
			self.SelectWeaponPos = 1
		end

		self.SelectWeapon = getweapons[self.SelectWeaponPos]
	end

	if not hud_fastswitch:GetBool() then
		local prev = self.DrawWepSelection

		if not self.DrawWepSelection then
			self.DrawWepSelection = true
			LEmit('Player.WeaponSelectionOpen')
			self.SelectorStartFade = RealTimeL() + 2
			self.SelectorEndFade = RealTimeL() + 2.5
			self:CallWeaponSelectorStart()
		else
			LEmit('Player.WeaponSelectionMoveSlot')
		end

		self:CallWeaponSelectorMoveInternal(prev)
		self:CallWeaponSelectorMove(prev)
	end

	self.WeaponListInSlot = getweapons

	if hud_fastswitch:GetBool() then
		self.SelectWeaponForce = self.SelectWeapon
		self.SelectWeaponForceTime = RealTimeL() + 2
		LEmit('Player.WeaponSelected')
		self:CallWeaponSelectorChosen(self.SelectWeapon)
	else
		self.SelectWeaponForce = NULL
		self.SelectWeaponForceTime = 0
	end

	return true
end

local function WheelBind(self, ply, bind, pressed, weapons)
	if not self.ENABLE_WEAPON_SELECT or not self.ENABLE_WEAPON_SELECT:GetBool() then return end

	if bind ~= 'invprev' and bind ~= 'invnext' then return end

	local weapon = IsValid(self.SelectWeaponForce) and self.SelectWeaponForce or LocalWeapon()
	local slot

	if not self.DrawWepSelection then
		if weapon:IsValid() then
			slot = weapon:GetSlot() + 1
		else
			slot = 1
		end
	else
		slot = self.LastSelectSlot
	end

	local getweapons = self:GetWeaponsInSlot(slot)

	if #getweapons == 0 then
		for i = 1, 6 do
			getweapons = self:GetWeaponsInSlot(i)

			if #getweapons ~= 0 then
				slot = i
				break
			end
		end

		if #getweapons == 0 then return end
	end

	if not self.DrawWepSelection then
		local hit = false

		for i, wep in ipairs(getweapons) do
			if wep == weapon then
				self.SelectWeaponPos = i
				hit = true
				break
			end
		end

		if not hit then
			self.SelectWeaponPos = 0
		end
	end

	self.SelectWeaponPos = self.SelectWeaponPos + (bind == 'invnext' and 1 or -1)

	if self.SelectWeaponPos < 1 then
		for i = 1, 6 do
			slot = slot - 1

			if slot < 1 then
				slot = 6
			end

			getweapons = self:GetWeaponsInSlot(slot)
			if #getweapons ~= 0 then break end
		end

		self.SelectWeaponPos = #getweapons
	elseif self.SelectWeaponPos > #getweapons then
		self.SelectWeaponPos = 1

		for i = 1, 6 do
			slot = slot + 1

			if slot > 6 then
				slot = 1
			end

			getweapons = self:GetWeaponsInSlot(slot)
			if #getweapons ~= 0 then break end
		end
	end

	if #getweapons == 0 then
		-- might be annoying
		-- LEmit('Player.DenyWeaponSelection')
		return
	end

	self.SelectWeapon = getweapons[self.SelectWeaponPos]

	if slot ~= self.LastSelectSlot or not self.SelectWeapon:IsValid() then
		self.LastSelectSlot = slot
	end

	if not hud_fastswitch:GetBool() then
		local prev = self.DrawWepSelection

		if not self.DrawWepSelection then
			self.DrawWepSelection = true
			LEmit('Player.WeaponSelectionOpen')
			self.SelectorStartFade = RealTimeL() + 2
			self.SelectorEndFade = RealTimeL() + 2.5
			self:CallWeaponSelectorStart()
		else
			LEmit('Player.WeaponSelectionMoveSlot')
		end

		self:CallWeaponSelectorMoveInternal(prev)
		self:CallWeaponSelectorMove(prev)
	end

	self.WeaponListInSlot = getweapons
	self.DrawWepSelection = true

	if hud_fastswitch:GetBool() then
		self.SelectWeaponForce = self.SelectWeapon
		self.SelectWeaponForceTime = RealTimeL() + 2
		LEmit('Player.WeaponSelected')
	else
		self.SelectWeaponForce = NULL
		self.SelectWeaponForceTime = 0
	end

	return true
end

function meta:WeaponSelectionBind(ply, bind, pressed)
	if not self.ENABLE_WEAPON_SELECT or not self.ENABLE_WEAPON_SELECT:GetBool() then return end

	if lastFrameAttack then return end
	if not pressed then return end
	if not self:GetVarAlive() or not self:WeaponsInVehicle() then return end
	if self:GetVarInDrive() then return end
	local weapons = ply:GetWeapons()
	if #weapons == 0 then return end

	self:UpdateWeaponList(weapons)
	local status = BindSlot(self, ply, bind, pressed, weapons)
	if status then return status end
	status = WheelBind(self, ply, bind, pressed, weapons)
	if status then return status end

	if bind == 'lastinv' and IsValid(ply:GetPreviousWeapon()) then
		local next = ply:GetPreviousWeapon()
		local prev = LocalWeapon()

		self.PrevSelectWeapon = prev
		self.SelectWeaponForce = next
		self.SelectWeaponForceTime = RealTimeL() + 2
		LEmit('Player.WeaponSelected')
		self:CallWeaponSelectorChosen(next)
		return true
	end
end
