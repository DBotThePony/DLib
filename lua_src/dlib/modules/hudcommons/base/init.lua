
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

local meta = DLib.CreateLuaObject('HUDCommonsBase', true)
local pairs = pairs
local hook = hook
local table = table
local IsValid = FindMetaTable('Entity').IsValid

function meta:__construct(hudID, hudName)
	self.id = hudID
	self.hudID = hudID
	self.name = hudName
	self.hooks = {}
	self.chooks = {}
	self.variables = {}
	self.variablesHash = {}
	self.paintHash = {}
	self.paint = {}

	self.glitching = false
	self.glitchEnd = 0

	self.enabled = CreateConVar(hudID .. '_enabled', '1', {FCVAR_ARCHIVE}, 'Enable ' .. hudName)
	cvars.AddChangeCallback(hudID .. '_enabled', function(var, old, new) self:EnableSwitch(old, new) end, hudID)

	self:AddHook('Tick')
	self:AddHook('Think')
	self:AddHook('HUDPaint')

	self:__InitVaribles()
	self:InitVaribles()

	self:InitHooks()
	self:InitHUD()
end

function self:InitHUD()

end

function self:InitHooks()

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

function meta:CreateConVar(name, default, desc)
	return CreateConVar(self.id .. '_' .. name, default or '1', desc or '')
end

function meta:AddHook(event, funcIfAny, priority)
	priority = priority or 3
	funcIfAny = funcIfAny or self[event]
	self.hooks[event] = {funcIfAny, priority}

	if self:IsEnabled() then
		hook.Add(event, self.id .. '_' .. event, function(...)
			funcIfAny(self, ...)
		end, priority)
	end

	return self.id .. '_' .. event
end

function meta:AddHookCustom(event, id, funcIfAny, priority)
	priority = priority or 3
	funcIfAny = funcIfAny or self[event]

	self.chooks[id] = {event, id, funcIfAny, priority}

	if self:IsEnabled() then
		hook.Add(event, id, function(...)
			funcIfAny(self, ...)
		end, priority)
	end

	return id
end

function meta:RemoveHook(event)
	self.hooks[event] = nil
	hook.Remove(event, self.id .. '_' .. event)
	return self.id .. '_' .. event
end

function meta:RemoveCustomHook(event, id)
	self.chooks[id] = nil
	hook.Remove(event, id)
	return id
end

function meta:Enable()
	--if self:IsEnabled() then return end

	for event, data in pairs(self.hooks) do
		local funcIfAny = data[1]

		hook.Add(event, self.id .. '_' .. event, function(...)
			funcIfAny(self, ...)
		end, data[2])
	end

	for id, data in pairs(self.chooks) do
		local funcIfAny = data[3]

		hook.Add(data[1], id, function(...)
			funcIfAny(self, ...)
		end, data[4])
	end

	self:CallOnEnabled()
end

function meta:Disable()
	--if not self:IsEnabled() then return end

	for event, data in pairs(self.hooks) do
		hook.Remove(event, self.id .. '_' .. event)
	end

	for id, data in pairs(self.chooks) do
		hook.Remove(data[1], id)
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
	self.paintHash[id] = funcToCall
	self.paint = {}

	for id, func in pairs(self.paintHash) do
		table.insert(self.paint, func)
	end
end

function meta:Tick()
	local lPly = self:SelectPlayer()
	if not IsValid(lPly) then return end
	self:TickVariables(lPly)
	self:TickLogic(lPly)
end

function meta:HUDPaint()
	local paint = self.paint
	if #paint == 0 then return end

	local i, nextevent = 1, paint[1]
	::loop::

	nextevent()
	i = i + 1
	nextevent = paint[i]

	if nextevent ~= nil then
		goto loop
	end
end

function meta:Think()
	local lPly = self:SelectPlayer()
	if not IsValid(lPly) then return end
	self:ThinkLogic(lPly)
end

include('functions.lua')
include('variables.lua')
include('logic.lua')
