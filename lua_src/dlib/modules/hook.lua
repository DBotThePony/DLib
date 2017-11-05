
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- performance and functionality to the core

jit.on()

local pairs = pairs
local ipairs = ipairs
local print = print
local debug = debug
local tostring = tostring
local tonumber = tonumber
local type = type
local traceback = debug.traceback
local DLib = DLib

DLib.hook = DLib.hook or {}
local ghook = _G.hook
local hook = DLib.hook

hook.__tableOptimized = hook.__tableOptimized or {}
hook.__table = hook.__table or {}
hook.__tableGmod = hook.__tableGmod or {}

local __table = hook.__table
local __tableOptimized = hook.__tableOptimized
local __tableGmod = hook.__tableGmod

local maximalPriority = -10
local minimalPriority = 10

function hook.GetTable()
	return __tableGmod
end

function hook.GetDLibOptimizedTable()
	return __tableOptimized
end

function hook.GetDLibSortedTable()
	return __tableOptimized
end

function hook.GetULibTable()
	return __table
end

function hook.GetDLibTable()
	return __table
end

local oldHooks

if ghook ~= hook then
	if ghook.GetULibTable then
		oldHooks = ghook.GetULibTable()
	else
		hook.include = hook.include or include
		local linclude = hook.include

		function _G.include(fil)
			if fil:find('ulib') and fil:find('hook') then
				DLib.Message('--------------------')
				DLib.Message('ULib hook system is DISABLED')
				DLib.Message('--------------------')
				return
			end

			return linclude(fil)
		end

		oldHooks = {}

		for event, eventData in pairs(ghook.GetTable()) do
			oldHooks[event] = {}
			oldHooks[event][0] = {}
			local target = oldHooks[event][0]

			for hookID, hookFunc in pairs(eventData) do
				target[hookID] = {fn = hookFunc}
			end
		end
	end
end

local function transformStringID(stringID, transformFuncCall, event)
	if type(stringID) == 'number' then
		stringID = tostring(stringID)
	end

	if type(stringID) ~= 'string' then
		local success = pcall(function()
			stringID.IsValid(stringID)
		end)

		if not success then
			stringID = tostring(stringID)
			DLib.Message(traceback('hook.Add - hook ID is not a string and not a valid object! Using tostring() instead. ' .. type(funcToCall)))
			--return
		elseif transformFuncCall and event then
			return stringID, function(...)
				if not stringID.IsValid(stringID) then
					hook.Remove(event, stringID)
					return
				end

				return transformFuncCall(stringID, ...)
			end
		end
	end

	return stringID, transformFuncCall
end

function hook.Add(event, stringID, funcToCall, priority)
	__table[event] = __table[event] or {}

	if type(event) ~= 'string' then
		DLib.Message(traceback('hook.Add - event is not a string! ' .. type(event)))
		return false
	end

	if type(funcToCall) ~= 'function' then
		DLib.Message(traceback('hook.Add - function is not a function! ' .. type(funcToCall)))
		return false
	end

	stringID, funcToCall = transformStringID(stringID, funcToCall, event)

	for priority = maximalPriority, minimalPriority do
		local eventsTable = __table[event][priority]

		if eventsTable and eventsTable[stringID] then
			if not priority then
				priority = eventsTable[stringID].priority
			end

			eventsTable[stringID] = nil
		end
	end

	priority = priority or 0

	if type(priority) ~= 'number' then
		priority = tonumber(priority) or 0
	end

	priority = math.Clamp(math.floor(priority), maximalPriority, minimalPriority)

	local hookData = {
		event = event,
		priority = priority,
		funcToCall = funcToCall,
		id = stringID,
		idString = tostring(stringID),
		registeredAt = RealTime(),
		typeof = type(stringID) == 'string'
	}

	__table[event][priority] = __table[event][priority] or {}
	__table[event][priority][stringID] = hookData
	__tableGmod[event] = __tableGmod[event] or {}
	__tableGmod[event][stringID] = funcToCall

	hook.Reconstruct(event)
	return true, hookData
end

function hook.Remove(event, stringID)
	if not __table[event] then return false end
	__tableGmod[event] = __tableGmod[event] or {}
	__tableGmod[event][stringID] = nil

	stringID = transformStringID(stringID, nil, event)

	for priority = maximalPriority, minimalPriority do
		local eventsTable = __table[event][priority]

		if eventsTable ~= nil then
			local oldData = eventsTable[stringID]
			if oldData ~= nil then
				eventsTable[stringID] = nil
				hook.Reconstruct(event)
				return true, oldData
			end
		end
	end

	return false
end

function hook.HookDataSorter(a, b)
	return a.priority < b.priority and a.idString < b.idString
end

function hook.Reconstruct(eventToReconstruct)
	if not eventToReconstruct then
		__tableOptimized = {}
		local ordered = {}

		for event, priorityTable in pairs(__table) do
			ordered[event] = {}
			local look = ordered[event]

			for priority = maximalPriority, minimalPriority do
				local hookList = priorityTable[priority]

				if hookList then
					for stringID, hookData in pairs(hookList) do
						table.insert(look, hookData)
					end
				end
			end
		end

		for event, order in pairs(ordered) do
			if #order == 0 then
				__tableOptimized[event] = nil
			else
				__tableOptimized[event] = {}
				local look = __tableOptimized[event]
				table.sort(order, hook.HookDataSorter)

				for i, hookData in ipairs(order) do
					table.insert(look, hookData.funcToCall)
				end
			end
		end

		return __tableOptimized, ordered
	else
		__tableOptimized[eventToReconstruct] = {}
		local ordered = {}
		local priorityTable = __table[eventToReconstruct]
		local inboundgmod = __tableGmod[eventToReconstruct]

		if priorityTable then
			for priority = maximalPriority, minimalPriority do
				local hookList = priorityTable[priority]

				if hookList then
					for stringID, hookData in pairs(hookList) do
						if hookData.typeof == false then
							if hookData.id:IsValid() then
								table.insert(ordered, hookData)
							else
								hookList[stringID] = nil
								inboundgmod[stringID] = nil
							end
						else
							table.insert(ordered, hookData)
						end
					end
				end
			end
		end

		local cnt = #ordered

		if cnt == 0 then
			__tableOptimized[eventToReconstruct] = nil
		else
			table.sort(ordered, hook.HookDataSorter)

			local target = __tableOptimized[eventToReconstruct]

			for i = 1, cnt do
				table.insert(target, ordered[i].funcToCall)
			end
		end

		return __tableOptimized, ordered
	end
end

function hook.Call2(event, hookTable, ...)
	local events = __tableOptimized[event]

	if events == nil then
		if hookTable == nil then
			return
		end

		local gamemodeFunction = hookTable[event]

		if gamemodeFunction == nil then
			return
		end

		return gamemodeFunction(hookTable, ...)
	end

	local i = 1
	local nextevent = events[i]

	::loop::
	local a, b, c, d, e, f, g, m, l = nextevent(...)

	if a ~= nil then
		return a, b, c, d, e, f, g, m, l
	end

	i = i + 1
	nextevent = events[i]

	if nextevent ~= nil then
		goto loop
	end

	if hookTable == nil then
		return
	end

	local gamemodeFunction = hookTable[event]

	if gamemodeFunction == nil then
		return
	end

	return gamemodeFunction(hookTable, ...)
end

if gmod then
	local GetGamemode = gmod.GetGamemode

	function hook.Run2(event, ...)
		return hook.Call2(event, GetGamemode(), ...)
	end
else
	function hook.Run2(event, ...)
		return hook.Call2(event, GAMEMODE, ...)
	end
end

-- Engine permanently remembers function address
-- So we need to transmit the call to our subfunction in order to modify it on the fly (with no runtime costs because JIT is <3)
-- and local "hook" will never point at wrong table
function hook.Call(...)
	return hook.Call2(...)
end

function hook.Run(...)
	return hook.Run2(...)
end

ghook = hook
_G.hook = hook

if oldHooks then
	for event, priorityTable in pairs(oldHooks) do
		for priority, hookTable in pairs(priorityTable) do
			for hookID, hookFunc in pairs(hookTable) do
				hook.Add(event, hookID, hookFunc.fn, priority)
			end
		end
	end
end

DLib.benchhook = {
	Add = hook.Add,
	Call = hook.Call2,
	Run = hook.Run2,
	Remove = hook.Remove,
	GetTable = hook.GetTable,
}
