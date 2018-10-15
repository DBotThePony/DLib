
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


local DLib = DLib
local meta = DLib.CreateLuaObject('HUDCommonsBase', true)
local HUDCommons = HUDCommons
local pairs = pairs
local hook = hook
local table = table
local IsValid = FindMetaTable('Entity').IsValid
local assert = assert
local type = type
local RealTimeL = RealTimeL

function meta:__construct(hudID, hudName)
	DLib.CMessage(self, hudName)
	self.id = hudID
	self.hudID = hudID
	self.name = hudName
	self.hooks = {}
	self.chooks = {}
	self.phooks = {}
	self.variables = {}
	self.variablesHash = {}
	self.paintHash = {}
	self.paint = {}
	self.paintPostHash = {}
	self.paintPost = {}
	self.paintOverlayHash = {}
	self.paintOverlay = {}
	self.tickHash = {}
	self.tick = {}
	self.thinkHash = {}
	self.think = {}
	self.fonts = {}
	self.fontsNames = {}
	self.convars = {}

	self.positionsConVars = {}

	self.fontCVars = {
		font = {},
		weight = {},
		size = {}
	}

	self.tryToSelectWeapon = NULL
	self.tryToSelectWeaponLast = 0
	self.tryToSelectWeaponFadeIn = 0
	self.tryToSelectWeaponLastEnd = 0

	self.glitching = false
	self.glitchEnd = 0
	self.glitchingSince = 0

	self.enabled = self:CreateConVar('enabled', '1', 'Enable ' .. hudName)
	cvars.AddChangeCallback(self.enabled:GetName(), function(var, old, new) self:EnableSwitch(old, new) end, hudID)

	self:AddHook('Tick')
	self:AddHook('Think')
	self:AddHook('HUDPaint')
	self:AddHook('PostDrawHUD')
	self:AddHook('DrawOverlay')
	self:AddHook('DrawWeaponSelection')
	self:AddHook('ScreenSizeChanged')
	self.PreInitFrameThinks = 0
	self:AddHookCustomPersistent('PopulateToolMenu', 'PopulateToolMenuDefault')

	self:__InitVaribles()
	self:InitVaribles()

	self:InitHooks()
	self:InitHUD()

	self:Concommand('set_all_font', function(args)
		if #args == 0 then
			self.Message('No arguments were passed')
			return
		end

		self:SetAllFontsTo(table.concat(args, ' '))
	end)

	self:Concommand('set_all_font_weight', function(args)
		if #args == 0 then
			self.Message('No arguments were passed')
			return
		end

		if not tonumber(args[1]) then
			self.Message('Invalid argument - ' .. args[1])
			return
		end

		self:SetAllWeightTo(tonumber(args[1]))
	end)

	self:Concommand('set_all_font_size', function(args)
		if #args == 0 then
			self.Message('No arguments were passed')
			return
		end

		if not tonumber(args[1]) then
			self.Message('Invalid argument - ' .. args[1])
			return
		end

		self:SetAllSizeTo(tonumber(args[1]))
	end)

	self:Concommand('reset_fonts', function(args)
		self:ResetFonts()
	end)

	self:Concommand('reset_fonts_size', function(args)
		self:ResetFontsSize()
	end)

	self:Concommand('reset_fonts_weight', function(args)
		self:ResetFontsWeight()
	end)

	self:Concommand('reset_fonts_bare', function(args)
		self:ResetFontsBare()
	end)
end

function meta:InitHUD()

end

function meta:InitHooks()

end

function meta:GetName()
	return self.name
end

function meta:IsEnabled()
	return self.enabled:GetBool()
end

function meta:GetID()
	return self.id
end

function meta:CreateConVar(cvar, default, desc, nomenu)
	local convar = CreateConVar(self:GetID() .. '_' .. cvar, default or '1', {FCVAR_ARCHIVE}, desc or '')

	if not nomenu then
		table.insert(self.convars, convar)
	end

	return convar
end

function meta:TrackConVar(cvar, func, id)
	if type(func) == 'string' then
		local a, b = func, id
		func = b
		id = a
	end

	cvars.AddChangeCallback(self:GetID() .. '_' .. cvar, func, id or self:GetID())
end

function meta:Concommand(name, callback)
	return concommand.Add(self:GetID() .. '_' .. name, function(ply, cmd, args)
		return callback(args)
	end)
end

function meta:AddHook(event, funcIfAny, priority)
	priority = priority or 3
	funcIfAny = funcIfAny or self[event]

	if type(funcIfAny) == 'string' then
		funcIfAny = self[funcIfAny]
	end

	self.hooks[event] = {funcIfAny, priority}

	if self:IsEnabled() then
		hook.Add(event, self:GetID() .. '_' .. event, function(...)
			return funcIfAny(self, ...)
		end, priority)
	end

	return self:GetID() .. '_' .. event
end

function meta:AddHookCustom(event, id, funcIfAny, priority)
	priority = priority or 3
	funcIfAny = funcIfAny or self[id] or self[event]

	if type(funcIfAny) == 'string' then
		funcIfAny = self[funcIfAny]
	end

	if type(funcIfAny) ~= 'function' then
		error('Invalid function supplied (' .. type(funcIfAny) .. ')')
	end

	self.chooks[id] = {event, self:GetID() .. '_' .. id, funcIfAny, priority}

	if self:IsEnabled() then
		hook.Add(event, self:GetID() .. '_' .. id, function(...)
			return funcIfAny(self, ...)
		end, priority)
	end

	return id
end

function meta:AddHookCustomPersistent(event, id, funcIfAny, priority)
	priority = priority or 3
	funcIfAny = funcIfAny or self[id] or self[event]

	self.phooks[id] = {event, self:GetID() .. '_' .. id, funcIfAny, priority}

	hook.Add(event, self:GetID() .. '_' .. id, function(...)
		return funcIfAny(self, ...)
	end, priority)

	return id
end

function meta:RemoveHook(event)
	self.hooks[event] = nil
	hook.Remove(event, self:GetID() .. '_' .. event)
	return self:GetID() .. '_' .. event
end

function meta:RemoveCustomHook(event, id)
	self.chooks[id] = nil
	hook.Remove(event, self:GetID() .. '_' .. id)
	return id
end

function meta:RemoveCustomHookPersistent(event, id)
	self.phooks[id] = nil
	hook.Remove(event, self:GetID() .. '_' .. id)
	return id
end

function meta:CreateColor(class, name, r, g, b, a)
	return HUDCommons.CreateColor(self:GetID() .. '_' .. class, self:GetName() .. ' ' .. name, r, g, b, a)
end

function meta:CreateColorN(class, name, r, g, b, a)
	return HUDCommons.CreateColorN(self:GetID() .. '_' .. class, self:GetName() .. ' ' .. name, r, g, b, a)
end

function meta:CreateColorN2(class, name, r, g, b, a)
	return HUDCommons.CreateColorN2(self:GetID() .. '_' .. class, self:GetName() .. ' ' .. name, r, g, b, a)
end

function meta:Enable()
	--if self:IsEnabled() then return end

	for event, data in pairs(self.hooks) do
		local funcIfAny = data[1]

		hook.Add(event, self:GetID() .. '_' .. event, function(...)
			return funcIfAny(self, ...)
		end, data[2])
	end

	for id, data in pairs(self.chooks) do
		local funcIfAny = data[3]

		hook.Add(data[1], data[2], function(...)
			return funcIfAny(self, ...)
		end, data[4])
	end

	self:CallOnEnabled()
end

function meta:Disable()
	--if not self:IsEnabled() then return end

	for event, data in pairs(self.hooks) do
		hook.Remove(event, self:GetID() .. '_' .. event)
	end

	for id, data in pairs(self.chooks) do
		hook.Remove(data[1], data[2])
	end

	self:CallOnDisabled()
end

function meta:EnableSwitch(old, new)
	if old == new then return end

	if tobool(new) then
		self:Enable()
	else
		self:Disable()
	end
end

function meta:AddPaintHook(id, funcToCall)
	funcToCall = funcToCall or self[id]
	assert(type(funcToCall) == 'function', 'Input is not a function!')
	self.paintHash[id] = funcToCall
	self.paint = {}

	for id, func in pairs(self.paintHash) do
		table.insert(self.paint, func)
	end
end

function meta:AddPostPaintHook(id, funcToCall)
	funcToCall = funcToCall or self[id]
	assert(type(funcToCall) == 'function', 'Input is not a function!')
	self.paintPostHash[id] = funcToCall
	self.paintPost = {}

	for id, func in pairs(self.paintPostHash) do
		table.insert(self.paintPost, func)
	end
end

function meta:AddOverlayPaintHook(id, funcToCall)
	funcToCall = funcToCall or self[id]
	assert(type(funcToCall) == 'function', 'Input is not a function!')
	self.paintOverlayHash[id] = funcToCall
	self.paintOverlay = {}

	for id, func in pairs(self.paintOverlayHash) do
		table.insert(self.paintOverlay, func)
	end
end

function meta:AddThinkHook(id, funcToCall)
	funcToCall = funcToCall or self[id]
	assert(type(funcToCall) == 'function', 'Input is not a function!')
	self.thinkHash[id] = funcToCall
	self.think = {}

	for id, func in pairs(self.thinkHash) do
		table.insert(self.think, func)
	end
end

function meta:AddTickHook(id, funcToCall)
	funcToCall = funcToCall or self[id]
	assert(type(funcToCall) == 'function', 'Input is not a function!')
	self.tickHash[id] = funcToCall
	self.tick = {}

	for id, func in pairs(self.tickHash) do
		table.insert(self.tick, func)
	end
end

function meta:Tick()
	local lPly = self:SelectPlayer()
	if not IsValid(lPly) then return end

	if self.LastThink ~= RealTimeL() then
		self:Think()
		self.LastThink = RealTimeL()
	end

	self:TickLogic(lPly)
	self:TickVariables(lPly)

	local tick = self.tick
	if #tick ~= 0 then
		local i, nextevent = 1, tick[1]
		::loop::

		nextevent(self, lPly)
		i = i + 1
		nextevent = tick[i]

		if nextevent ~= nil then
			goto loop
		end
	end
end

function meta:HUDPaint()
	local paint = self.paint
	if #paint == 0 then return end

	local ply = self:SelectPlayer()

	local i, nextevent = 1, paint[1]
	::loop::

	nextevent(self, ply)
	i = i + 1
	nextevent = paint[i]

	if nextevent ~= nil then
		goto loop
	end
end

local cam = cam

function meta:PostDrawHUD()
	local paint = self.paintPost
	if #paint == 0 then return end

	cam.Start2D()
	local ply = self:SelectPlayer()

	local i, nextevent = 1, paint[1]
	::loop::

	nextevent(self, ply)
	i = i + 1
	nextevent = paint[i]

	if nextevent ~= nil then
		goto loop
	end
	cam.End2D()
end

function meta:DrawOverlay()
	local paint = self.paintOverlay
	if #paint == 0 then return end

	cam.Start2D()
	local ply = self:SelectPlayer()

	local i, nextevent = 1, paint[1]
	::loop::

	nextevent(self, ply)
	i = i + 1
	nextevent = paint[i]

	if nextevent ~= nil then
		goto loop
	end
	cam.End2D()
end

function meta:Think()
	local lPly = self:SelectPlayer()
	if not IsValid(lPly) then return end
	if self.LastThink == RealTimeL() then return end
	self:ThinkLogic(lPly)

	if self.PreInitFrameThinks then
		self.PreInitFrameThinks = self.PreInitFrameThinks + 1

		if self.PreInitFrameThinks > 200 then
			self.PreInitFrameThinks = nil
			self:ScreenSizeChanged()
		end
	end

	local think = self.think
	if #think ~= 0 then
		local i, nextevent = 1, think[1]
		::loop::

		nextevent(self, lPly)
		i = i + 1
		nextevent = think[i]

		if nextevent ~= nil then
			goto loop
		end
	end
end

include('functions.lua')
include('variables.lua')
include('logic.lua')
include('menus.lua')
