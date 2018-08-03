
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
local unpack = unpack
local gxpcall = xpcall
local ITERATING = false
local IS_DIRTY = false
local IS_DIRTY_ID

DLib.hook = DLib.hook or {}
local ghook = _G.hook
local hook = DLib.hook

hook.__tableOptimized = hook.__tableOptimized or {}
hook.__table = hook.__table or {}
hook.__tableGmod = hook.__tableGmod or {}
hook.__tableModifiersPost = hook.__tableModifiersPost or {}
hook.__tableModifiersPostOptimized = hook.__tableModifiersPostOptimized or {}
hook.__disabled = hook.__disabled or {}

local __table = hook.__table
local __disabled = hook.__disabled
local __tableOptimized = hook.__tableOptimized
local __tableGmod = hook.__tableGmod
local __tableModifiersPost = hook.__tableModifiersPost
local __tableModifiersPostOptimized = hook.__tableModifiersPostOptimized

-- ULib compatibility
-- ugh
_G.HOOK_MONITOR_HIGH = -2
_G.HOOK_HIGH = -1
_G.HOOK_NORMAL = 0
_G.HOOK_LOW = 1
_G.HOOK_MONITOR_LOW = 2

local maximalPriority = -10
local minimalPriority = 10

local function GetTable()
	return __tableGmod
end

function hook.GetDLibOptimizedTable()
	return __tableOptimized
end

function hook.GetDLibModifiers()
	return __tableModifiersPost
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

function hook.GetDisabledHooks()
	return __disabled
end

local oldHooks

if ghook ~= DLib.ghook then
	if ghook.GetULibTable then
		oldHooks = ghook.GetULibTable()
	else
		hook.include = hook.include or include
		local linclude = hook.include

		function _G.include(fil)
			if fil:find('ulib') and fil:find('hook') then
				if DLib.DEBUG_MODE:GetBool() then
					DLib.Message('--------------------')
					DLib.Message('ULib hook system is DISABLED')
					DLib.Message('--------------------')
				end

				_G.include = linclude

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

local function transformStringID(stringID, event)
	if type(stringID) == 'number' then
		stringID = tostring(stringID)
	end

	if type(stringID) ~= 'string' then
		local success = pcall(function()
			stringID.IsValid(stringID)
		end)

		if not success then
			--if DLib.DEBUG_MODE:GetBool() then
				DLib.Message(traceback('hook.Add - hook ID is not a string and not a valid object! Using tostring() instead. ' .. type(stringID)))
			--end
			stringID = tostring(stringID)
		end
	end

	return stringID
end

function hook.DisableHook(event, stringID)
	assert(type(event) == 'string', 'hook.DisableHook - event is not a string! ' .. type(event))

	if not stringID then
		if __disabled[event] then
			return false
		end

		__disabled[event] = true
		return true
	else
		if not __table[event] then return false end
		stringID = transformStringID(stringID, event)

		for priority = -10, 10 do
			if __table[event][priority] and __table[event][priority][stringID] then
				local wasDisabled = __table[event][priority][stringID].disabled
				__table[event][priority][stringID].disabled = true
				hook.Reconstruct(event)
				return not wasDisabled
			end
		end

		return false
	end
end

function hook.DisableAllHooksExcept(event, stringID)
	assert(type(event) == 'string', 'hook.DisableAllHooksExcept - event is not a string! ' .. type(event))
	assert(type(stringID) ~= 'nil', 'hook.DisableAllHooksExcept - ID is not a valid value! ' .. type(stringID))

	if not __table[event] then return false end
	stringID = transformStringID(stringID, event)

	for priority = -10, 10 do
		if __table[event][priority] then
			for id, hookData in pairs(__table[event][priority]) do
				if id ~= stringID then
					hookData.disabled = true
				end
			end
		end
	end

	hook.Reconstruct(event)
	return true
end

function hook.DisableHooksByPredicate(event, predicate)
	assert(type(event) == 'string', 'hook.DisableAllHooksByPredicate - event is not a string! ' .. type(event))
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	if not __table[event] then return false end

	for priority = -10, 10 do
		if __table[event][priority] then
			for id, hookData in pairs(__table[event][priority]) do
				local reply = predicate(event, id, priority, hookData)

				if reply then
					hookData.disabled = true
				end
			end
		end
	end

	hook.Reconstruct(event)
	return true
end

function hook.DisableAllHooksByPredicate(predicate)
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	for event, eventData in pairs(__table) do
		for priority = -10, 10 do
			if eventData[priority] then
				for id, hookData in pairs(eventData[priority]) do
					local reply = predicate(event, id, priority, hookData)

					if reply then
						hookData.disabled = true
					end
				end
			end
		end

		hook.Reconstruct(event)
	end

	return true
end

function hook.EnableHooksByPredicate(event, predicate)
	assert(type(event) == 'string', 'hook.DisableAllHooksByPredicate - event is not a string! ' .. type(event))
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	if not __table[event] then return false end

	for priority = -10, 10 do
		if __table[event][priority] then
			for id, hookData in pairs(__table[event][priority]) do
				local reply = predicate(event, id, priority, hookData)

				if reply then
					hookData.disabled = false
				end
			end
		end
	end

	hook.Reconstruct(event)
	return true
end

function hook.EnableAllHooksByPredicate(predicate)
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	for event, eventData in pairs(__table) do
		for priority = -10, 10 do
			if eventData[priority] then
				for id, hookData in pairs(eventData[priority]) do
					local reply = predicate(event, id, priority, hookData)

					if reply then
						hookData.disabled = false
					end
				end
			end
		end

		hook.Reconstruct(event)
	end

	return true
end

function hook.EnableAllHooks()
	local toenable = {}

	for k, v in pairs(__disabled) do
		table.insert(toenable, k)
	end

	for i, v in ipairs(toenable) do
		__disabled[v] = nil
	end

	for event, eventData in pairs(__table) do
		for priority = -10, 10 do
			if eventData[priority] then
				for id, hookData in pairs(eventData[priority]) do
					hookData.disabled = false
				end
			end
		end

		hook.Reconstruct(event)
	end

	return toenable
end

function hook.EnableHook(event, stringID)
	assert(type(event) == 'string', 'hook.EnableHook - event is not a string! ' .. type(event))

	if not stringID then
		if not __disabled[event] then
			return false
		end

		__disabled[event] = nil
		return true
	else
		if not __table[event] then return false end
		stringID = transformStringID(stringID, event)

		for priority = -10, 10 do
			if __table[event][priority] and __table[event][priority][stringID] then
				local wasDisabled = __table[event][priority][stringID].disabled
				__table[event][priority][stringID].disabled = false
				hook.Reconstruct(event)
				return wasDisabled
			end
		end

		return false
	end
end

function hook.Add(event, stringID, funcToCall, priority)
	if type(event) ~= 'string' then
		--if DLib.DEBUG_MODE:GetBool() then
			DLib.Message(traceback('hook.Add - event is not a string! ' .. type(event)))
		--end

		return
	end

	__table[event] = __table[event] or {}

	if type(funcToCall) ~= 'function' then
		--if DLib.DEBUG_MODE:GetBool() then
			DLib.Message(traceback('hook.Add - function is not a function! ' .. type(funcToCall)))
		--end

		return
	end

	stringID = transformStringID(stringID, event)

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
		registeredAt = SysTime(),
		typeof = type(stringID) == 'string'
	}

	__table[event][priority] = __table[event][priority] or {}
	__table[event][priority][stringID] = hookData
	__tableGmod[event] = __tableGmod[event] or {}
	__tableGmod[event][stringID] = funcToCall

	hook.Reconstruct(event)
	return
end

function hook.Remove(event, stringID)
	if type(event) ~= 'string' then
		--if DLib.DEBUG_MODE:GetBool() then
			DLib.Message(traceback('hook.Remove - event is not a string! ' .. type(event)))
		--end

		return
	end

	if type(stringID) == 'nil' then
		--if DLib.DEBUG_MODE:GetBool() then
			DLib.Message(traceback('hook.Remove - hook id is nil!'))
		--end

		return
	end

	if not __table[event] then return end
	__tableGmod[event] = __tableGmod[event] or {}

	stringID = transformStringID(stringID, event)

	__tableGmod[event][stringID] = nil

	for priority = maximalPriority, minimalPriority do
		local eventsTable = __table[event][priority]

		if eventsTable ~= nil then
			local oldData = eventsTable[stringID]
			if oldData ~= nil then
				eventsTable[stringID] = nil

				if ITERATING == event then
					IS_DIRTY = true
					IS_DIRTY_ID = event
					return
				end

				hook.Reconstruct(event)
			end
		end
	end
end

function hook.AddPostModifier(event, stringID, funcToCall)
	__tableModifiersPost[event] = __tableModifiersPost[event] or {}

	if type(event) ~= 'string' then
		--if DLib.DEBUG_MODE:GetBool() then
			DLib.Message(traceback('hook.AddPostModifier - event is not a string! ' .. type(event)))
		--end

		return false
	end

	if type(funcToCall) ~= 'function' then
		--if DLib.DEBUG_MODE:GetBool() then
			DLib.Message(traceback('hook.AddPostModifier - function is not a function! ' .. type(funcToCall)))
		--end

		return false
	end

	stringID = transformStringID(stringID, event)

	local hookData = {
		event = event,
		funcToCall = funcToCall,
		id = stringID,
		idString = tostring(stringID),
		registeredAt = SysTime(),
		typeof = type(stringID) == 'string'
	}

	__tableModifiersPost[event][stringID] = hookData
	hook.ReconstructPostModifiers(event)
	return true, hookData
end

function hook.RemovePostModifier(event, stringID)
	if not __tableModifiersPost[event] then return false end

	stringID = transformStringID(stringID, event)
	if __tableModifiersPost[event][stringID] then
		local old = __tableModifiersPost[event][stringID]
		__tableModifiersPost[event][stringID] = nil
		hook.ReconstructPostModifiers(event)
		return true, old
	end

	return false
end

function hook.ReconstructPostModifiers(eventToReconstruct)
	if not eventToReconstruct then
		for event, tab in pairs(__tableModifiersPost) do
			hook.ReconstructPostModifiers(event)
		end

		return
	end

	__tableModifiersPostOptimized[eventToReconstruct] = {}
	local event = __tableModifiersPost[eventToReconstruct]

	local ordered = {}

	if event then
		for stringID, hookData in pairs(event) do
			if hookData.typeof == false then
				if hookData.id:IsValid() then
					table.insert(ordered, hookData)
				else
					event[stringID] = nil
				end
			else
				table.insert(ordered, hookData)
			end
		end
	end

	local cnt = #ordered

	if cnt == 0 then
		__tableModifiersPostOptimized[eventToReconstruct] = nil
	else
		local target = __tableModifiersPostOptimized[eventToReconstruct]

		for i = 1, cnt do
			table.insert(target, ordered[i].funcToCall)
		end
	end

	return __tableModifiersPostOptimized, ordered
end

function hook.Reconstruct(eventToReconstruct)
	if not eventToReconstruct then
		for event, data in pairs(__table) do
			hook.Reconstruct(event)
		end

		return
	end

	__tableOptimized[eventToReconstruct] = {}
	local ordered = {}
	local priorityTable = __table[eventToReconstruct]
	local inboundgmod = __tableGmod[eventToReconstruct]

	if priorityTable then
		for priority = maximalPriority, minimalPriority do
			local hookList = priorityTable[priority]

			if hookList then
				for stringID, hookData in pairs(hookList) do
					if not hookData.disabled then
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
	end

	local cnt = #ordered

	if cnt == 0 then
		__tableOptimized[eventToReconstruct] = nil
	else
		local target = __tableOptimized[eventToReconstruct]

		for i = 1, cnt do
			if type(ordered[i].id) == 'string' then
				table.insert(target, ordered[i].funcToCall)
			else
				local self = ordered[i].id
				local upvalueFunc = ordered[i].funcToCall
				table.insert(target, function(...)
					if not self:IsValid() then
						hook.Remove(ordered[i].event, self)
						return
					end

					return upvalueFunc(self, ...)
				end)
			end
		end
	end

	return __tableOptimized, ordered
end

local function Call(...)
	return hook.Call2(...)
end

local function Run(...)
	return hook.Run2(...)
end

local __breakage1 = {
	'HUDPaint',
	'PreDrawHUD',
	'PostDrawHUD',
	'Initialize',
	'InitPostEntity',
	'PreGamemodeInit',
	'PostGamemodeInit',
	'PostGamemodeInitialize',
	'PreGamemodeInitialize',
	'PostGamemodeLoaded',
	'PreGamemodeLoaded',
	'PostRenderVGUI',
	'OnGamemodeLoaded',

	'CreateMove',
	'StartCommand',
	'SetupMove',
}

local __breakage = {}

for i, str in ipairs(__breakage1) do
	__breakage[str] = true
end

-- these hooks can't return any values
hook.StaticHooks = __breakage

function hook.HasHooks(event)
	return __tableOptimized[event] ~= nil and #__tableOptimized[event] ~= 0
end

function hook.CallStatic(event, hookTable, ...)
	local post = __tableModifiersPostOptimized[event]
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
	nextevent(...)
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

function hook.Call2(event, hookTable, ...)
	if IS_DIRTY then
		hook.Reconstruct(IS_DIRTY_ID)
		IS_DIRTY = false
		IS_DIRTY_ID = nil
	end

	if __disabled[event] then
		return
	end

	ITERATING = event

	if __breakage[event] == true then
		hook.CallStatic(event, hookTable, ...)
		return
	end

	local post = __tableModifiersPostOptimized[event]
	local events = __tableOptimized[event]

	if events == nil then
		if hookTable == nil then
			return
		end

		local gamemodeFunction = hookTable[event]

		if gamemodeFunction == nil then
			return
		end

		if post == nil then
			return gamemodeFunction(hookTable, ...)
		end

		local Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M = gamemodeFunction(hookTable, ...)
		local i = 1
		local nextevent = post[i]

		::post_mloop1::
		Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M = nextevent(Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M)

		i = i + 1
		nextevent = post[i]

		if nextevent ~= nil then
			goto post_mloop1
		end

		return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M
	end

	local i = 1
	local nextevent = events[i]

	::loop::
	local Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M = nextevent(...)

	if Q ~= nil then
		if post == nil then
			return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M
		end

		local i = 1
		local nextevent = post[i]

		::post_mloop2::
		Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M = nextevent(Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M)

		i = i + 1
		nextevent = post[i]

		if nextevent ~= nil then
			goto post_mloop2
		end

		return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M
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

	if post == nil then
		return gamemodeFunction(hookTable, ...)
	end

	local Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M = gamemodeFunction(hookTable, ...)
	local i = 1
	local nextevent = post[i]

	::post_mloop3::
	Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M = nextevent(Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M)

	i = i + 1
	nextevent = post[i]

	if nextevent ~= nil then
		goto post_mloop3
	end

	return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M, M
end

if gmod then
	local GetGamemode = gmod.GetGamemode

	function hook.Run2(event, ...)
		return hook.Call2(event, GetGamemode(), ...)
	end

	function gamemode.Call(event, ...)
		local gm = GetGamemode()

		if gm == nil then return false end
		if gm[event] == nil then return false end

		return hook.Call2(event, gm, ...)
	end
else
	function hook.Run2(event, ...)
		return hook.Call2(event, GAMEMODE, ...)
	end

	function gamemode.Call()
		return false
	end
end

for k, v in pairs(hook) do
	if type(v) == 'function' then
		hook[k:sub(1, 1):lower() .. k:sub(2)] = v
	end
end

-- Engine permanently remembers function address
-- So we need to transmit the call to our subfunction in order to modify it on the fly (with no runtime costs because JIT is <3)
-- and local "hook" will never point at wrong table

hook.Call = Call
hook.Run = Run
hook.GetTable = GetTable

if oldHooks then
	for event, priorityTable in pairs(oldHooks) do
		for priority, hookTable in pairs(priorityTable) do
			for hookID, hookFunc in pairs(hookTable) do
				hook.Add(event, hookID, hookFunc.fn, priority)
			end
		end
	end
end

setmetatable(hook, {
	__call = function(self, ...)
		return self.Add(...)
	end
})

if ghook ~= DLib.ghook and ents.GetCount() < 10 then
	DLib.ghook = ghook

	for k, v in pairs(ghook) do
		rawset(ghook, k, nil)
	end

	setmetatable(DLib.ghook, {
		__index = hook,

		__newindex = function(self, key, value)
			if hook[key] == value then return end

			if DLib.DEBUG_MODE:GetBool() then
				DLib.Message(traceback('DEPRECATED: Do NOT mess with hook system directly! https://goo.gl/NDAQqY\nReport this message to addon author which is involved in this stack trace:\nhook.' .. tostring(key) .. ' (' .. tostring(hook[key]) .. ') -> ' .. tostring(value), 2))
			end

			local status = hook.Call('DLibHookChange', nil, key, value)
			if status == false then return end
			rawset(hook, key, value)
		end,

		__call = function(self, ...)
			return self.Add(...)
		end
	})
elseif ghook ~= DLib.ghook then
	function ghook.AddPostModifier()

	end
end

DLib.benchhook = {
	Add = hook.Add,
	Call = hook.Call2,
	Run = hook.Run2,
	Remove = hook.Remove,
	GetTable = hook.GetTable,
}

local function lua_findhooks(eventName, ply)
	DLib.MessagePlayer(ply, '----------------------------------')
	DLib.MessagePlayer(ply, string.format('Finding %s hooks for event %q', CLIENT and 'CLIENTSIDE' or 'SERVERSIDE', eventName))

	local tableToUse = __table[eventName]

	if tableToUse and table.Count(tableToUse) ~= 0 then
		for priority = maximalPriority, minimalPriority do
			local hookList = tableToUse[priority]

			if hookList then
				for stringID, hookData in pairs(hookList) do
					local info = debug.getinfo(hookData.funcToCall)
					DLib.MessagePlayer(ply,
						string.format(
							'\t\t%q [%s] at %p (%s: %i->%i)',
							stringID,
							priority,
							hookData.funcToCall,
							info.source,
							info.linedefined,
							info.lastlinedefined
						)
					)
				end
			end
		end
	else
		DLib.MessagePlayer(ply, 'No hooks defined for specified event')
	end

	DLib.MessagePlayer(ply, '----------------------------------')
end

local function lua_findhooks_cl(ply, cmd, args)
	if not game.SinglePlayer() and IsValid(ply) and ply:IsPlayer() and not ply:IsAdmin() then return end

	if not args[1] then
		DLib.Message('No event name were provided!')
		return
	end

	lua_findhooks(table.concat(args, ' '):trim(), ply)
end

local function lua_findhooks_sv(ply, cmd, args)
	if not game.SinglePlayer() and IsValid(ply) and ply:IsPlayer() and not ply:IsAdmin() then return end

	if not args[1] then
		DLib.Message('No event name were provided!')
		return
	end

	lua_findhooks(table.concat(args, ' '):trim(), ply)
end

timer.Simple(0, function()
	if CLIENT then
		concommand.Add('lua_findhooks_cl', lua_findhooks_cl)
	else
		concommand.Add('lua_findhooks', lua_findhooks_sv)
	end
end)
