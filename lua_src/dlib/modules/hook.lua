
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

-- performance and functionality to the core

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
local SysTime = SysTime

local developer = ConVar('developer')

local coroutine = coroutine
local coroutine_resume = coroutine.resume
local coroutine_status = coroutine.status
local coroutine_create = coroutine.create

DLib.hook = DLib.hook or {}
local ghook = _G.hook
local hook = DLib.hook

hook.PROFILING = false
hook.PROFILING_RESULTS_EXISTS = false
hook.PROFILE_STARTED = 0
hook.PROFILE_ENDS = 0

hook.__tableOptimized = hook.__tableOptimized or {}
hook.__table = hook.__table or {}
hook.__tableGmod = hook.__tableGmod or {}
hook.__tableModifiersPost = hook.__tableModifiersPost or {}
hook.__tableModifiersPostOptimized = hook.__tableModifiersPostOptimized or {}
hook.__disabled = hook.__disabled or {}

hook.__tableTasks = hook.__tableTasks or {}

local __table = hook.__table
local __disabled = hook.__disabled
local __tableOptimized = hook.__tableOptimized
local __tableGmod = hook.__tableGmod
local __tableModifiersPost = hook.__tableModifiersPost
local __tableModifiersPostOptimized = hook.__tableModifiersPostOptimized
local __tableTasks = hook.__tableTasks

-- ULib compatibility
-- ugh
_G.HOOK_MONITOR_HIGH = -2
_G.HOOK_HIGH = -1
_G.HOOK_NORMAL = 0
_G.HOOK_LOW = 1
_G.HOOK_MONITOR_LOW = 2

--[[
	@doc
	@fname hook.GetTable
	@replaces
	@returns
	table: `table<string, table<string, function>>`
]]
local function GetTable()
	return __tableGmod
end

--[[
	@doc
	@fname hook.GetDLibOptimizedTable
	@returns
	table: of `eventName -> array of functions`
]]
function hook.GetDLibOptimizedTable()
	return __tableOptimized
end

--[[
	@doc
	@fname hook.GetDLibModifiers
	@returns
	table
]]
function hook.GetDLibModifiers()
	return __tableModifiersPost
end

--[[
	@doc
	@fname hook.GetDLibSortedTable
	@returns
	table
]]
function hook.GetDLibSortedTable()
	return __tableOptimized
end

--[[
	@doc
	@replaces
	@fname hook.GetULibTable

	@desc
	For mods like DarkRP
	Althrough, DarkRP can use DLib's Post Modifiers instead for things that
	DarkRP currently do with table provided by `GetULibTable`
	@enddesc

	@returns
	table
]]
function hook.GetULibTable()
	return __table
end

--[[
	@doc
	@fname hook.GetDLibTable
	@returns
	table
]]
function hook.GetDLibTable()
	return __table
end

--[[
	@doc
	@fname hook.GetDisabledHooks
	@returns
	table
]]
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

		function _G.include(fil, ...)
			if fil:find('ulib') and fil:find('hook') then
				if DLib.DEBUG_MODE:GetBool() then
					DLib.Message('--------------------')
					DLib.Message('ULib hook system is DISABLED')
					DLib.Message('--------------------')
				end

				_G.include = linclude

				return
			end

			return linclude(fil, ...)
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

local function transformStringID(funcname, stringID, event)
	if isstring(stringID) then return stringID end
	if type(stringID) == 'thread' then return stringID end

	if type(stringID) == 'number' then
		stringID = tostring(stringID)
	end

	if type(stringID) == 'boolean' then
		error(string.format('bad argument #2 to %s (object expected, got boolean)', funcname), 3)
	end

	if type(stringID) ~= 'string' then
		local success = pcall(function()
			stringID.IsValid(stringID)
		end)

		if not success then
			error(string.format('bad argument #2 to %s (object expected, got %s)', funcname, type(stringID)), 3)
			stringID = tostring(stringID)
		end
	end

	return stringID
end

--[[
	@doc
	@fname hook.DisableHook
	@args string event, any hookID

	@returns
	boolean
]]
function hook.DisableHook(event, stringID)
	assert(type(event) == 'string', 'hook.DisableHook - event is not a string! ' .. type(event))

	if not stringID then
		if __disabled[event] then
			return false
		end

		__disabled[event] = true
		return true
	end

	if not __table[event] then return end

	stringID = transformStringID('hook.DisableHook', stringID, event)

	for priority, eventData in pairs(__table[event]) do
		if eventData[stringID] then
			local wasDisabled = eventData[stringID].disabled
			eventData[stringID].disabled = true
			hook.Reconstruct(event)
			return not wasDisabled
		end
	end
end

--[[
	@doc
	@fname hook.DisableAllHooksExcept
	@args string event, any hookID

	@returns
	boolean
]]
function hook.DisableAllHooksExcept(event, stringID)
	assert(type(event) == 'string', 'bad argument #1 to hook.DisableAllHooksExcept (string expected, got ' .. type(event) .. ')')
	assert(type(stringID) ~= 'nil', 'hook.DisableAllHooksExcept - ID is not a valid value! ' .. type(stringID))

	if not __table[event] then return false end

	stringID = transformStringID('hook.DisableAllHooksExcept', stringID, event)

	for priority, eventData in pairs(__table[event]) do
		for id, hookData in pairs(eventData) do
			if id ~= stringID then
				hookData.disabled = true
			end
		end
	end

	hook.Reconstruct(event)
	return true
end

--[[
	@doc
	@fname hook.DisableHooksByPredicate
	@args string event, function predicate

	@desc
	Predicate should return true to disable hook
	and return false to enable hook
	Arguments passed to predicate are `event, id, priority, dlibHookData`
	@enddesc

	@returns
	boolean
]]
function hook.DisableHooksByPredicate(event, predicate)
	assert(type(event) == 'string', 'bad argument #1 to hook.DisableAllHooksByPredicate (string expected, got ' .. type(event) .. ')')
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	if not __table[event] then return false end

	for priority, eventData in pairs(__table[event]) do
		for id, hookData in pairs(eventData) do
			local reply = predicate(event, id, priority, hookData)

			if reply then
				hookData.disabled = true
			end
		end
	end

	hook.Reconstruct(event)
	return true
end

--[[
	@doc
	@fname hook.DisableAllHooksByPredicate
	@args function predicate

	@desc
	same as `hook.DisableHooksByPredicate`, except it is ran for all events
	pass `function() return true end` as predicate to disable **EVERYTHING**
	@enddesc

	@returns
	boolean
]]
function hook.DisableAllHooksByPredicate(predicate)
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	for event, eventData in pairs(__table) do
		for priority, _eventData in pairs(eventData) do
			for id, hookData in pairs(_eventData) do
				local reply = predicate(event, id, priority, hookData)

				if reply then
					hookData.disabled = true
				end
			end
		end

		hook.Reconstruct(event)
	end

	return true
end

--[[
	@doc
	@fname hook.EnableHooksByPredicate
	@args string event, function predicate

	@desc
	counterpart of `hook.DisableHooksByPredicate`
	@enddesc

	@returns
	boolean
]]
function hook.EnableHooksByPredicate(event, predicate)
	assert(type(event) == 'string', 'bad argument #1 to hook.EnableHooksByPredicate (string expected, got ' .. type(event) .. ')')
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	if not __table[event] then return false end

	for priority, eventData in pairs(__table[event]) do
		for id, hookData in pairs(eventData) do
			local reply = predicate(event, id, priority, hookData)

			if reply then
				hookData.disabled = false
			end
		end
	end

	hook.Reconstruct(event)
	return true
end

--[[
	@doc
	@fname hook.EnableAllHooksByPredicate
	@args function predicate

	@desc
	counterpart of `hook.DisableAllHooksByPredicate`
	@enddesc

	@returns
	boolean
]]
function hook.EnableAllHooksByPredicate(predicate)
	assert(type(predicate) == 'function', 'hook.DisableAllHooksByPredicate - invalid predicate function! ' .. type(predicate))

	for event, eventData in pairs(__table) do
		for priority, _eventData in pairs(eventData) do
			for id, hookData in pairs(_eventData) do
				local reply = predicate(event, id, priority, hookData)

				if reply then
					hookData.disabled = false
				end
			end
		end

		hook.Reconstruct(event)
	end

	return true
end

--[[
	@doc
	@fname hook.EnableAllHooks

	@returns
	table: enabled hooks (copy of __disabled)
]]
function hook.EnableAllHooks()
	local toenable = {}

	for k, v in pairs(__disabled) do
		table.insert(toenable, k)
	end

	for i, v in ipairs(toenable) do
		__disabled[v] = nil
	end

	for event, eventData in pairs(__table) do
		for priority, _eventData in pairs(eventData) do
			for id, hookData in pairs(_eventData) do
				hookData.disabled = false
			end
		end

		hook.Reconstruct(event)
	end

	return toenable
end

--[[
	@doc
	@fname hook.EnableHook
	@args string event, any hookID

	@returns
	boolean
]]
function hook.EnableHook(event, stringID)
	assert(type(event) == 'string', 'bad argument #1 to hook.EnableHook (string expected, got ' .. type(event) .. ')')

	if not stringID then
		if not __disabled[event] then
			return false
		end

		__disabled[event] = nil
		return true
	end

	if not __table[event] then return end
	stringID = transformStringID('hook.EnableHook', stringID, event)

	for priority, eventData in pairs(__table[event]) do
		if eventData[stringID] then
			local wasDisabled = eventData[stringID].disabled
			eventData[stringID].disabled = false
			hook.Reconstruct(event)
			return wasDisabled
		end
	end
end

--[[
	@doc
	@fname hook.Add
	@replaces
	@args string event, any hookID, function callback, number priority = 0

	@desc
	Refer to !g:hook.Add for main information
	`priority` can be any number you want
	`hookID` **can** be a number or a **coroutine** thread, unlike default gmod behavior, but can not be a boolean
	if `hookID` is a coroutine, `callback` can be omitted.
	prints tracebacks when some of arguments are invalid instead of silent fail, unlike original hook
	throws an error when something goes horribly wrong instead of silent fail, unlike original hook
	if priority argument is omitted, then it uses `0` as priority (if hook was not defined before)
	and use previous priority if hook already exists (assuming we want to overwrite old hook definition) unlike ULib's hook
	this can be useful with software which can provide hook benchmarking by re-defining every single hook using hook.Add
	and it doesn't know about hook priorities
	@enddesc
]]
function hook.Add(event, stringID, callback, priority)
	if not isstring(event) then
		local trace = traceback('bad argument #1 to hook.Add (string expected, got ' .. type(event) .. ')', 2) .. '\n'

		if developer:GetBool() or trace:find('VLL2:VM') then
			ErrorNoHalt(trace)
		end

		return
	end

	if type(callback) ~= 'function' and type(stringID) ~= 'thread' then
		local trace = traceback('bad argument #3 to hook.Add (function expected, got ' .. type(callback) .. ')', 2) .. '\n'

		if developer:GetBool() or trace:find('VLL2:VM') then
			ErrorNoHalt(trace)
		end

		return
	end

	__table[event] = __table[event] or {}

	stringID = transformStringID('hook.Add', stringID, event)

	for _priority, eventsTable in pairs(__table[event]) do
		if eventsTable[stringID] then
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

	if type(stringID) == 'thread' and not callback then
		function callback(...)
			local status, err = coroutine_resume(stringID)

			if not status then
				hook.Remove(event, stringID)
				error(err)
			end
		end
	end

	local hookData = {
		event = event,
		priority = priority,
		callback = callback,
		fn = callback, -- ULib
		isstring = isstring(stringID), -- ULib
		id = stringID,
		idString = tostring(stringID),
		registeredAt = SysTime(),
		typeof = isstring(stringID),
		isthread = type(stringID) == 'thread'
	}

	__table[event][priority] = __table[event][priority] or {}
	__table[event][priority][stringID] = hookData
	__tableGmod[event] = __tableGmod[event] or {}
	__tableGmod[event][stringID] = callback

	hook.Reconstruct(event)
	return
end

--[[
	@doc
	@fname hook.SetPriority
	@args string event, any stringID, number priority

	@desc
	Sets priority of already registered hook
	@enddesc

	@returns
	boolean: whenever priority was set
]]
function hook.SetPriority(event, stringID, priority)
	if not isstring(event) then
		error('Bad argument #1 to hook.SetPriority (string expected, got ' .. type(event) .. ')', 2)
	end

	if not isnumber(priority) then
		error('Bad argument #3 to hook.SetPriority (number expected, got ' .. type(priority) .. ')', 2)
	end

	if not __table[event] then
		return false
	end

	stringID = transformStringID('hook.SetPriority', stringID, event)

	for _priority, eventsTable in pairs(__table[event]) do
		if eventsTable[stringID] then
			eventsTable[stringID].priority = priority
			hook.Reconstruct(event)
			return true
		end
	end

	return false
end

hook._O_SALT = hook._O_SALT or -0xFFFFFFF

--[[
	@doc
	@fname hook.Once
	@args string event, function callback, number priority = 0

	@desc
	`hook.Add`, but function would be called back only once.
	@enddesc
]]
function hook.Once(event, callback, priority)
	hook._O_SALT = hook._O_SALT + 1
	local id = 'hook.Once.' .. hook._O_SALT

	hook.Add(event, id, function(...)
		hook.Remove(event, id)
		return callback(...)
	end, priority)
end

--[[
	@doc
	@fname hook.Remove
	@replaces
	@args string event, any hookID
]]
function hook.Remove(event, stringID)
	if type(event) ~= 'string' then
		DLib.Message(traceback('hook.Remove - event is not a string! ' .. type(event)))
		return
	end

	if type(stringID) == 'nil' then
		DLib.Message(traceback('hook.Remove - hook id is nil!'))
		return
	end

	if not __table[event] then return end
	__tableGmod[event] = __tableGmod[event] or {}

	stringID = transformStringID('hook.Remove', stringID, event)

	__tableGmod[event][stringID] = nil

	for priority, eventsTable in pairs(__table[event]) do
		local oldData = eventsTable[stringID]

		if oldData ~= nil then
			eventsTable[stringID] = nil
			hook.Reconstruct(event)
			return
		end
	end
end

--[[
	@doc
	@fname hook.AddPostModifier
	@args string event, any hookID, function callback

	@desc
	Unique feature of DLib hook
	This allows you to define "post-hooks"
	hooks which transform data returned by previous hook
	Hooks bound to event will receive values returned by upvalue hook.
	**This is meant for advanced users only. Use with care and don't try anything stupid!**
	If you somehow don't want to mess with passed arguments, **you must return them back**
	otherwise engine/hook.Run caller/other post modifiers will receive empty values, like none of hooks returned values
	this can be useful for doing "final fixes" to data
	like custom final logic for PlayerSay (local chat/roleyplay for example) or fixes to CalcView
	using this will not affect admin/fun mods (they will use hook (e.g. PlayerSay) as usual)
	and final fixes will always work too despite type of hook
	*Limitation of this hook is that it can not see original arguments passed to* `hook.Run`
	@enddesc

	@returns
	boolean
	table: hookData
]]
function hook.AddPostModifier(event, stringID, callback)
	__tableModifiersPost[event] = __tableModifiersPost[event] or {}

	if type(event) ~= 'string' then
		DLib.Message(traceback('hook.AddPostModifier - event is not a string! ' .. type(event)))
		return false
	end

	if type(callback) ~= 'function' then
		DLib.Message(traceback('hook.AddPostModifier - function is not a function! ' .. type(funcToCall)))
		return false
	end

	stringID = transformStringID('hook.AddPostModifier', stringID, event)

	local hookData = {
		event = event,
		callback = callback,
		id = stringID,
		idString = tostring(stringID),
		registeredAt = SysTime(),
		typeof = isstring(stringID)
	}

	__tableModifiersPost[event][stringID] = hookData
	hook.ReconstructPostModifiers(event)
	return true, hookData
end

--[[
	@doc
	@fname hook.RemovePostModifier
	@args string event, any hookID

	@returns
	boolean
	table: hookData
]]
function hook.RemovePostModifier(event, stringID)
	if not __tableModifiersPost[event] then return false end

	stringID = transformStringID('hook.RemovePostModifier', stringID, event)
	if __tableModifiersPost[event][stringID] then
		local old = __tableModifiersPost[event][stringID]
		__tableModifiersPost[event][stringID] = nil
		hook.ReconstructPostModifiers(event)
		return true, old
	end

	return false
end

--[[
	@doc
	@fname hook.ReconstructPostModifiers
	@args string event

	@internal

	@desc
	builds optimized hook table
	@enddesc

	@returns
	table: sorted array of functions
	table: sorted array of hookData
]]
function hook.ReconstructPostModifiers(eventToReconstruct)
	if not eventToReconstruct then
		for event, tab in pairs(__tableModifiersPost) do
			hook.ReconstructPostModifiers(event)
		end

		return
	end

	if __tableModifiersPost[eventToReconstruct] == nil then
		__tableModifiersPostOptimized[eventToReconstruct] = nil
		return
	end

	__tableModifiersPostOptimized[eventToReconstruct] = {}
	local event = __tableModifiersPost[eventToReconstruct]
	local target = __tableModifiersPostOptimized[eventToReconstruct]
	local index = 1

	if event then
		for stringID, hookData in pairs(event) do
			local applicable = false

			if hookData.typeof then
				applicable = true
			else
				if hookData.id:IsValid() then
					applicable = true
				else
					event[stringID] = nil
				end
			end

			if applicable then
				target[index] = hookData.callback or hookData.funcToCall
				index = index + 1
			end
		end
	end
end

--[[
	@doc
	@fname hook.ListAllHooks
	@args boolean includeDisabled = true

	@returns
	table: sorted array of hookData
]]
function hook.ListAllHooks(includeDisabled)
	if includeDisabled == nil then includeDisabled = true end
	local output = {}

	for event, priorityTable in pairs(__table) do
		for priority, hookList in SortedPairs(priorityTable) do
			for stringID, hookData in pairs(hookList) do
				if not hookData.disabled or includeDisabled then
					table.insert(output, hookData)
				end
			end
		end
	end

	return output
end

--[[
	@doc
	@fname hook.Reconstruct
	@args string event

	@internal

	@desc
	builds optimized hook table
	@enddesc

	@returns
	table: sorted array of functions
	table: sorted array of hookData
]]
function hook.Reconstruct(eventToReconstruct)
	if not eventToReconstruct then
		for event, data in pairs(__table) do
			hook.Reconstruct(event)
		end

		return
	end

	if not __table[eventToReconstruct] then
		__tableOptimized[eventToReconstruct] = nil
		return
	end

	__tableOptimized[eventToReconstruct] = {}

	local index = 1
	local priorityTable = __table[eventToReconstruct]
	local inboundgmod = __tableGmod[eventToReconstruct]
	local target = __tableOptimized[eventToReconstruct]

	for priority, hookList in SortedPairs(priorityTable) do
		for stringID, hookData in pairs(hookList) do
			if not hookData.disabled then
				local applicable = false

				if hookData.typeof then
					applicable = true
				elseif hookData.isthread then
					if coroutine_status(hookData.id) == 'dead' then
						hookList[stringID] = nil
						inboundgmod[stringID] = nil
					else
						applicable = true
					end
				else
					if hookData.id:IsValid() then
						applicable = true
					else
						hookList[stringID] = nil
						inboundgmod[stringID] = nil
					end
				end

				if applicable then
					local callable

					if hookData.typeof then
						callable = hookData.callback or hookData.funcToCall
					elseif hookData.isthread then
						local self = hookData.id
						local upfuncCallableSelf = hookData.callback

						function callable(...)
							if coroutine_status(self) == 'dead' then
								hook.Remove(hookData.event, self)
								return
							end

							return upfuncCallableSelf(self, ...)
						end
					else
						local self = hookData.id
						local upfuncCallableSelf = hookData.callback or hookData.funcToCall

						function callable(...)
							if not self:IsValid() then
								hook.Remove(hookData.event, self)
								return
							end

							return upfuncCallableSelf(self, ...)
						end
					end

					if hook.PROFILING then
						local THIS_RUNTIME = 0
						local THIS_CALLS = 0
						local upfuncProfiled = callable

						function callable(...)
							THIS_CALLS = THIS_CALLS + 1
							local t = SysTime()
							local Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = upfuncProfiled(...)
							local t2 = SysTime()

							THIS_RUNTIME = THIS_RUNTIME + (t2 - t)
							return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M
						end

						function hookData.profileEnds()
							hookData.THIS_RUNTIME = THIS_RUNTIME
							hookData.THIS_CALLS = THIS_CALLS
						end
					end

					target[index] = callable
					index = index + 1
				end
			end
		end
	end

	if index == 1 then
		__tableOptimized[eventToReconstruct] = nil
	end
end

local function Call(...)
	return hook.Call2(...)
end

local function Run(...)
	return hook.Run2(...)
end

local __static1 = {
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

	'PostRender',
	'Think',
	'Tick',
}

local __static = {}

for i, str in ipairs(__static1) do
	__static[str] = true
end

-- these hooks can't return any values
hook.StaticHooks = __static

--[[
	@doc
	@fname hook.HasHooks
	@args string event

	@returns
	boolean
]]
function hook.HasHooks(event)
	return __tableOptimized[event] ~= nil
end

local last_trace, last_error
local getinfo = debug.getinfo
local find = string.find
local rep = string.rep
local hide_trace = CreateConVar('dlib_hide_hooktrace', '1', {FCVAR_ARCHIVE}, 'This bullshit exists solely for workshop hamsters (users)')

local function catchError(err)
	last_error = err
	last_trace = ''

	local i = 2
	local l = 1
	local info, infoup = getinfo(i), getinfo(i + 1)

	local developer = not hide_trace:GetBool() or developer:GetBool()
	local prevdlib = false

	while info do
		local isdlib = not developer and (find(info.source, 'dlib/modules/hook.lua', 1, true) or info.name == 'dlib_has_nothing_to_do_with_this_traceback')
		local fnname = info.name ~= '' and info.name or 'unknown'

		if infoup and infoup.name == 'dlib_has_nothing_to_do_with_this_traceback' then
			fnname = '__event'
		end

		if info.name == 'dlib_has_nothing_to_do_with_this_traceback' then
			if not developer then goto SKIP end
			fnname = 'xpcall'
		end

		if not isdlib then
			if last_trace == '' then
				last_trace = '  1. ' .. fnname .. ' - ' .. info.short_src .. ':' .. info.currentline
			else
				last_trace = last_trace .. '\n' .. rep(' ', l + 1) .. l .. '. ' .. fnname .. ' - ' .. info.short_src .. ':' .. info.currentline
			end

			l = l + 1
		end

		::SKIP::

		i = i + 1
		info = infoup
		infoup = getinfo(i + 1)
	end
end

local dlib_has_nothing_to_do_with_this_traceback = xpcall

--[[
	@doc
	@fname hook.CallStatic
	@args string event, table hookTable, vararg arguments

	@desc
	functions called can not interrupt call loop by returning arguments
	can not return arguments
	internall used to call some of most popular hooks
	which will break the game if at least one function in hook list will return value
	@enddesc

	@internal
]]
function hook.CallStatic(event, hookTable, ...)
	local events = __tableOptimized[event]

	if events == nil then
		if hookTable == nil then
			return
		end

		local gamemodeFunction = hookTable[event]

		if gamemodeFunction == nil then
			return
		end

		local state, errormsg = dlib_has_nothing_to_do_with_this_traceback(gamemodeFunction, catchError, hookTable, ...)

		if not state then
			if not last_error then
				last_error = errormsg
			end

			if last_trace then
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n' .. last_trace .. '\n')
			elseif last_error then
				local _getinfo = getinfo(gamemodeFunction)

				if _getinfo and _getinfo.short_src then
					ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '[' .. _getinfo.short_src .. ']\n')
				else
					ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '\n')
				end
			else
				ErrorNoHalt('\n[ERROR] Lua state is detorating away! This is very likely going to result into game crash! Hook GM:' .. event .. " didn't executed properly! Unable to provide traceback since error handler gave up!\n")
			end

			last_trace, last_error = nil, nil
		end

		return
	end

	local i = 1
	local nextevent = events[i]

	::loop::
	local state, errormsg = dlib_has_nothing_to_do_with_this_traceback(nextevent, catchError, ...)

	if not state then
		if not last_error then
			last_error = errormsg
		end

		if last_trace then
			ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n' .. last_trace .. '\n')
		elseif last_error then
			local _getinfo = getinfo(nextevent)

			if _getinfo and _getinfo.short_src then
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. event:' .. event .. '[' .. _getinfo.short_src .. ']\n')
			else
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. event:' .. event .. '\n')
			end
		else
			ErrorNoHalt('\n[ERROR] Lua state is detorating away! This is very likely going to result into game crash! Hook GM:' .. event .. " didn't executed properly! Unable to provide traceback since error handler gave up!\n")
		end

		last_trace, last_error = nil, nil
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

	local state, errormsg = dlib_has_nothing_to_do_with_this_traceback(gamemodeFunction, catchError, hookTable, ...)

	if not state then
		if not last_error then
			last_error = errormsg
		end

		if last_trace then
			ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n' .. last_trace .. '\n')
		elseif last_error then
			local _getinfo = getinfo(gamemodeFunction)

			if _getinfo and _getinfo.short_src then
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '[' .. _getinfo.short_src .. ']\n')
			else
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '\n')
			end
		else
			ErrorNoHalt('\n[ERROR] Lua state is detorating away! This is very likely going to result into game crash! Hook GM:' .. event .. " didn't executed properly! Unable to provide traceback since error handler gave up!\n")
		end

		last_trace, last_error = nil, nil
	end
end

--[[
	@doc
	@fname hook.Call
	@replaces
	@args string event, table hookTable, vararg arguments

	@returns
	vararg: values
]]
function hook.Call2(event, hookTable, ...)
	if __disabled[event] then
		return
	end

	ITERATING = event

	if __static[event] then
		hook.CallStatic(event, hookTable, ...)
		return
	end

	local post = __tableModifiersPostOptimized[event]
	local events = __tableOptimized[event]

	local state, Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M

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

		Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = gamemodeFunction(hookTable, ...)
		local i = 1
		local nextevent = post[i]

		::post_mloop1::
		Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = nextevent(Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M)

		i = i + 1
		nextevent = post[i]

		if nextevent ~= nil then
			goto post_mloop1
		end

		return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M
	end

	local i = 1
	local nextevent = events[i]

	::loop::
	state, Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = dlib_has_nothing_to_do_with_this_traceback(nextevent, catchError, ...)

	if not state then
		if not last_error then
			last_error = Q
		end

		Q = nil

		if last_trace then
			ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n' .. last_trace .. '\n')
		elseif last_error then
			local _getinfo = getinfo(nextevent)

			if _getinfo and _getinfo.short_src then
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. event:' .. event .. '[' .. _getinfo.short_src .. ']\n')
			else
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. event:' .. event .. '\n')
			end
		else
			ErrorNoHalt('\n[ERROR] Lua state is detorating away! This is very likely going to result into game crash! Hook GM:' .. event .. " didn't executed properly! Unable to provide traceback since error handler gave up!\n")
		end

		last_trace, last_error = nil, nil
	end

	if Q ~= nil then
		if post == nil then
			return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M
		end

		local i = 1
		local nextevent = post[i]

		::post_mloop2::
		Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = nextevent(Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M)

		i = i + 1
		nextevent = post[i]

		if nextevent ~= nil then
			goto post_mloop2
		end

		return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M
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
		state, Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = dlib_has_nothing_to_do_with_this_traceback(gamemodeFunction, catchError, hookTable, ...)

		if not state then
			if not last_error then
				last_error = Q
			end

			Q = nil

			if last_trace then
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n' .. last_trace .. '\n')
			elseif last_error then
				local _getinfo = getinfo(gamemodeFunction)

				if _getinfo and _getinfo.short_src then
					ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '[' .. _getinfo.short_src .. ']\n')
				else
					ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '\n')
				end
			else
				ErrorNoHalt('\n[ERROR] Lua state is detorating away! This is very likely going to result into game crash! Hook GM:' .. event .. " didn't executed properly! Unable to provide traceback since error handler gave up!\n")
			end

			last_trace, last_error = nil, nil
			return
		end

		return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M
	end

	state, Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = dlib_has_nothing_to_do_with_this_traceback(gamemodeFunction, catchError, hookTable, ...)

	if not state then
		if not last_error then
			last_error = Q
		end

		Q = nil

		if last_trace then
			ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n' .. last_trace .. '\n')
		elseif last_error then
			local _getinfo = getinfo(gamemodeFunction)

			if _getinfo and _getinfo.short_src then
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '[' .. _getinfo.short_src .. ']\n')
			else
				ErrorNoHalt('\n[ERROR] ' .. last_error .. '\n  1. GM:' .. event .. '\n')
			end
		else
			ErrorNoHalt('\n[ERROR] Lua state is detorating away! This is very likely going to result into game crash! Hook GM:' .. event .. " didn't executed properly! Unable to provide traceback since error handler gave up!\n")
		end

		last_trace, last_error = nil, nil
	end

	local i = 1
	local nextevent = post[i]

	::post_mloop3::
	Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M = nextevent(Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M)

	i = i + 1
	nextevent = post[i]

	if nextevent ~= nil then
		goto post_mloop3
	end

	return Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M
end


--[[
	@doc
	@fname hook.Run
	@replaces
	@args string event, vararg arguments

	@returns
	vararg: values
]]

--[[
	@doc
	@fname gamemode.Call
	@replaces
	@args string event, vararg arguments

	@returns
	vararg: values
]]
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

local odd_line = Color(200, 200, 200)
local even_line = Color(150, 150, 150)

local function lua_findhooks(eventName, ply)
	DLib.MessagePlayer(ply, '----------------------------------')
	DLib.MessagePlayer(ply, string.format('Finding %s hooks for event %q', CLIENT and 'CLIENTSIDE' or 'SERVERSIDE', eventName))

	local tableToUse = __table[eventName]
	local odd = true

	if tableToUse and next(tableToUse) then
		local max_width = 0

		for priority, hookList in SortedPairs(tableToUse) do
			local priorityL = #tostring(priority) + 2

			for stringID, hookData in pairs(hookList) do
				max_width = max_width:max(utf8.len(tostring(stringID)) + priorityL)
			end
		end

		for priority, hookList in SortedPairs(tableToUse) do
			local priorityL = #tostring(priority) + 2

			for stringID, hookData in pairs(hookList) do
				local info = debug.getinfo(hookData.callback)

				DLib.MessagePlayer(ply, odd and odd_line or even_line,
					string.format(
						'\t\t[%d] %q%s at %p (%s: %i->%i)',
						priority,
						tostring(stringID),
						string.rep(' ', max_width - utf8.len(tostring(stringID)) - priorityL),
						hookData.callback,
						info.source,
						info.linedefined,
						info.lastlinedefined
					)
				)

				odd = not odd
			end
		end
	else
		DLib.MessagePlayer(ply, 'No hooks defined for specified event')
	end

	DLib.MessagePlayer(ply, '----------------------------------')
end

--[[
	@doc
	@fname hook.GetDumpStr

	@internal

	@returns
	string
]]
function hook.GetDumpStr()
	local lines = {}

	local max_width = 0

	for eventName, eventData in SortedPairs(__table) do
		for priority, hookList in SortedPairs(eventData) do
			local priorityL = #tostring(priority) + 2

			for stringID, hookData in pairs(hookList) do
				max_width = max_width:max(utf8.len(tostring(stringID)) + priorityL)
			end
		end
	end

	for eventName, eventData in SortedPairs(__table) do
		for priority, hookList in SortedPairs(eventData) do
			local llines = {}
			table.insert(lines, '// Begin list hooks of event ' .. eventName)
			local priorityL = #tostring(priority) + 2

			for stringID, hookData in pairs(hookList) do
				local info = debug.getinfo(hookData.callback)

				table.insert(llines,
					string.format(
						'\t[%d] %q%s at %p (%s: %i->%i)',
						priority,
						tostring(stringID),
						string.rep(' ', max_width - utf8.len(tostring(stringID)) - priorityL),
						hookData.callback,
						info.source,
						info.linedefined,
						info.lastlinedefined
					)
				)
			end

			table.sort(llines)
			table.append(lines, llines)

			table.insert(lines, '// End list hooks of event ' .. eventName .. '\n')
		end
	end

	return table.concat(lines, '\n')
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

do
	local function autocomplete(cmd, args)
		args = args:lower():trim()

		if args[1] == '"' then
			args = args:sub(2)
		end

		if args[#args] == '"' then
			args = args:sub(1, #args - 1)
		end

		local output = {}

		for k, v in pairs(__tableGmod) do
			if k:lower():startsWith(args) then
				table.insert(output, cmd .. ' "' .. k .. '"')
			end
		end

		table.sort(output)

		return output
	end

	timer.Simple(0, function()
		if CLIENT then
			concommand.Add('lua_findhooks_cl', lua_findhooks_cl, autocomplete)
		else
			concommand.Add('lua_findhooks', lua_findhooks_sv, autocomplete)
		end
	end)
end

local function printProfilingResults(ply)
	local deftable = {}

	local totalRuntime = 0

	for i, hookData in ipairs(hook.ListAllHooks(false)) do
		deftable[hookData.event] = deftable[hookData.event] or {runtime = 0, calls = 0, list = {}, name = hookData.event}

		table.insert(deftable[hookData.event].list, hookData)
		deftable[hookData.event].runtime = deftable[hookData.event].runtime + (hookData.THIS_RUNTIME or 0)
		totalRuntime = totalRuntime + (hookData.THIS_RUNTIME or 0)
		deftable[hookData.event].calls = deftable[hookData.event].calls + (hookData.THIS_CALLS or 0)
	end

	local sortedtable = {}

	for event, eventTable in pairs(deftable) do
		table.sort(eventTable.list, function(a, b)
			return (a.THIS_RUNTIME or 0) > (b.THIS_RUNTIME or 0)
		end)

		table.insert(sortedtable, eventTable)
	end

	table.sort(sortedtable, function(a, b)
		return a.runtime > b.runtime
	end)

	DLib.MessagePlayer(ply, '-----------------------------------')
	DLib.MessagePlayer(ply, '------ HOOK PROFILING REPORT ------')
	DLib.MessagePlayer(ply, '-----------------------------------')

	local time = hook.PROFILE_ENDS - hook.PROFILE_STARTED

	for pos, eventTable in ipairs(sortedtable) do
		if pos > 10 then
			DLib.MessagePlayer(ply, '... tail of events ... (', #sortedtable - 10, ' are not shown)')
			break
		end

		DLib.MessagePlayer(ply, '/// ' .. eventTable.name .. ': Runtime position: ', pos, string.format(' (%.2f%% of game runtime); - Total hook calls: ', (eventTable.runtime / time) * 100), eventTable.calls,
			string.format('; Total runtime: %.2f milliseconds (~%.2f microseconds per hook call on average)', eventTable.runtime * 1000, (eventTable.runtime * 1000000) / eventTable.calls))

		for pos2, hookData in ipairs(eventTable.list) do
			if hookData.THIS_RUNTIME <= 0.001 then
				DLib.MessagePlayer(ply, '(', #eventTable.list - pos2 + 1, ' are not shown)')
				break
			end

			DLib.MessagePlayer(ply, 'Hook ID: ', hookData.id)
			DLib.MessagePlayer(ply, string.format('\t - Runtime: %.2f milliseconds; %i calls; ~%.2f microseconds per call on average',
				hookData.THIS_RUNTIME * 1000, hookData.THIS_CALLS, (hookData.THIS_RUNTIME * 1000000) / hookData.THIS_CALLS))
		end
	end

	DLib.MessagePlayer(ply, '--')
	DLib.MessagePlayer(ply, 'In total, regular hooks took around ', math.floor((totalRuntime / time) * 10000) / 100, '% of game runtime.')
	DLib.MessagePlayer(ply, '--')

	DLib.MessagePlayer(ply, '-----------------------------------')
	DLib.MessagePlayer(ply, '--- END OF HOOK PROFILING REPORT --')
	DLib.MessagePlayer(ply, '-----------------------------------')
end

if CLIENT then
	concommand.Add('dlib_profile_hooks_cl', function(ply, cmd, args)
		if hook.PROFILING then
			hook.PROFILE_ENDS = SysTime()
			hook.PROFILING = false
			hook.PROFILING_RESULTS_EXISTS = true
			hook.Reconstruct()

			for i, hookData in ipairs(hook.ListAllHooks(false)) do
				hookData.profileEnds()
			end

			printProfilingResults(LocalPlayer())
			return
		end

		hook.PROFILE_STARTED = SysTime()
		hook.PROFILING = true

		DLib.Message('Hook profiling were started')
		DLib.Message('When you are ready you can type dlib_profile_hooks_cl again')
		DLib.Message('/// NOTE THAT RESULTS BECOME MORE ACCURATE AS PROFILING GOES!')
		DLib.Message('/// Disabling it too early will produce false results')
		hook.Reconstruct()
	end)

	concommand.Add('dlib_profile_hooks_last_cl', function(ply, cmd, args)
		if not hook.PROFILING_RESULTS_EXISTS then
			DLib.Message('No profiling results exists!')
			DLib.Message('Start a new one by typing dlib_profile_hooks_cl')
			return
		end

		printProfilingResults(LocalPlayer())
	end)
else
	concommand.Add('dlib_profile_hooks_last_sv', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then
			DLib.MessagePlayer(ply, 'Not a super admin!')
			return
		end

		if not hook.PROFILING_RESULTS_EXISTS then
			DLib.MessagePlayer(ply, 'No profiling results exists!')
			DLib.MessagePlayer(ply, 'Start a new one by typing dlib_profile_hooks_cl')
			return
		end

		DLib.Message(IsValid(ply) and ply or 'Console', ' requested hook profiling results')
		printProfilingResults(ply)
	end)

	concommand.Add('dlib_profile_hooks_sv', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then
			DLib.MessagePlayer(ply, 'Not a super admin!')
			return
		end

		if hook.PROFILING then
			DLib.Message(IsValid(ply) and ply or 'Console', ' stopped hook profiling')
			hook.PROFILE_ENDS = SysTime()
			hook.PROFILING = false
			hook.PROFILING_RESULTS_EXISTS = true
			hook.Reconstruct()

			for i, hookData in ipairs(hook.ListAllHooks(false)) do
				hookData.profileEnds()
			end

			printProfilingResults(ply)
			return
		end

		DLib.Message(IsValid(ply) and ply or 'Console', ' started hook profiling')

		hook.PROFILE_STARTED = SysTime()
		hook.PROFILING = true

		DLib.MessagePlayer(ply, 'Hook profiling were started')
		DLib.MessagePlayer(ply, 'When you are ready you can type dlib_profile_hooks_cl again')
		DLib.MessagePlayer(ply, '/// NOTE THAT RESULTS BECOME MORE ACCURATE AS PROFILING GOES!')
		DLib.MessagePlayer(ply, '/// Disabling it too early will produce false results')
		hook.Reconstruct()
	end)
end

if file.Exists('autorun/hat_init.lua', 'LUA') then
	DLib.Message(string.rep('-', 63))
	DLib.Message(string.rep('W', 63))
	DLib.Message(string.rep('A', 63))
	DLib.Message(string.rep('R', 63))
	DLib.Message(string.rep('N', 63))
	DLib.Message(string.rep('I', 63))
	DLib.Message(string.rep('N', 63))
	DLib.Message(string.rep('G', 63))
	DLib.Message('HAT INSTALLATION DETECTED')
	DLib.Message('HAT IS BASICALLY BROKEN FOR YEARS')
	DLib.Message('AND IT ALSO BREAK THE GAME, OBVIOUSLY')
	DLib.Message('IMPLEMENTING HAT LOADER TRAP')
	DLib.Message(string.rep('-', 63))

	table._DLibCopy = table._DLibCopy or table.Copy

	function table.Copy(tableIn)
		if tableIn == _G.concommand or tableIn == _G.hook then
			table.Copy = table._DLibCopy
			error('Nuh uh. No. Definitely Not. I dont even.', 2)
		end

		return table._DLibCopy(tableIn)
	end
end

function hook.ReconstructTasks(eventToReconstruct)
	if not eventToReconstruct then
		for event, data in pairs(__tableTasks) do
			hook.ReconstructTasks(event)
		end

		return
	end

	if not __tableTasks[eventToReconstruct] or not next(__tableTasks[eventToReconstruct]) then
		hook.Remove(eventToReconstruct, 'DLib Task Executor')
		return
	end

	local index = 1
	local target = {}
	local target_funcs = {}
	local target_data = {}
	local ignore_dead = false

	for stringID, hookData in pairs(__tableTasks[eventToReconstruct]) do
		if not hookData.disabled then
			local applicable = false

			if hookData.typeof then
				applicable = true
			else
				if hookData.id:IsValid() then
					applicable = true
				else
					hookList[stringID] = nil
					inboundgmod[stringID] = nil
				end
			end

			if applicable then
				local callable

				if hookData.typeof then
					callable = hookData.callback
				else
					local self = hookData.id
					local upfuncCallableSelf = hookData.callback

					function callable()
						if not self:IsValid() then
							ignore_dead = true
							hook.RemoveTask(hookData.event, self)
							return
						end

						return upfuncCallableSelf(self)
					end
				end

				if not hookData.thread or coroutine.status(hookData.thread) == 'dead' then
					hookData.thread = coroutine_create(callable)
				end

				target[index] = hookData.thread
				target_funcs[index] = callable
				target_data[index] = hookData
				index = index + 1
			end
		end
	end

	index = index - 1

	if index == 0 then
		hook.Remove(eventToReconstruct, 'DLib Task Executor')
		return
	end

	local task_i = 0

	hook.Add(eventToReconstruct, 'DLib Task Executor', function()
		task_i = task_i + 1

		if task_i > index then
			task_i = 1
		end

		local thread = target[task_i]
		ignore_dead = false
		local status, err = coroutine_resume(thread)

		if not status then
			target[task_i] = coroutine_create(target_funcs[task_i])
			target_data[task_i].thread = target[task_i]
			error('Task ' .. target_data[task_i].idString .. ' failed: ' .. err)
		end

		if not ignore_dead and coroutine_status(thread) == 'dead' then
			target[task_i] = coroutine_create(target_funcs[task_i])
			target_data[task_i].thread = target[task_i]
		end
	end)
end

--[[
	@doc
	@fname hook.AddTask
	@replaces
	@args string event, any hookID, function callback

	@desc
	Adds a hook on specified event to resume coroutine created of `callback`
	`callback` shouldn't be necessary endless loop, since if it "die", it is automatically recreated
	The more are tasks on one hook, the more sparsingly they are called
	This is meant for cases when you need specific code to be just executed *sometimes*,
	for example, checking for some not critical of all server entities on each game frame
	Example:
	`hook.AddTask("Think", "Check Ents", function() for ... do ... coroutine.yield() end end)`
	If used properly, can greatly help eliminating runtime requirement of background task execution
	If you need to have your coroutine executed each time on this specific event, just use `hook.Add` instead.
	@enddesc
]]
function hook.AddTask(event, stringID, callback)
	assert(type(event) == 'string', 'bad argument #1 to hook.AddTask (string expected, got ' .. type(event) .. ')', 2)
	assert(type(callback) == 'function', 'bad argument #3 to hook.AddTask (function expected, got ' .. type(callback) .. ')', 2)

	stringID = transformStringID('hook.AddTask', stringID, event)

	local hookData = {
		event = event,
		callback = callback,
		id = stringID,
		idString = tostring(stringID),
		registeredAt = SysTime(),
		typeof = isstring(stringID)
	}

	__tableTasks[event] = __tableTasks[event] or {}
	__tableTasks[event][stringID] = hookData

	hook.ReconstructTasks(event)
end

--[[
	@doc
	@fname hook.RemoveTask
	@replaces
	@args string event, any hookID
]]
function hook.RemoveTask(event, stringID)
	assert(type(event) == 'string', 'bad argument #1 to hook.AddTask (string expected, got ' .. type(event) .. ')', 2)
	stringID = transformStringID('hook.AddTask', stringID, event)

	if not __tableTasks[event] then return end
	if not __tableTasks[event][stringID] then return end
	__tableTasks[event][stringID] = nil

	hook.ReconstructTasks(event)
end

--[[
	@doc
	@fname hook.DisableTask
	@replaces
	@args string event, any hookID

	@returns
	boolean: whenever it was disabled
]]
function hook.DisableTask(event, stringID)
	assert(type(event) == 'string', 'hook.DisableTask - event is not a string! ' .. type(event))

	if not stringID then
		return hook.DisableHook(event, 'DLib Task Executor')
	end

	if not __tableTasks[event] then return end

	stringID = transformStringID('hook.DisableTask', stringID, event)

	if not __tableTasks[event][stringID] then return end

	local wasDisabled = __tableTasks[event][stringID].disabled
	__tableTasks[event][stringID].disabled = true
	hook.ReconstructTasks(event)
	return not wasDisabled
end

--[[
	@doc
	@fname hook.EnableTask
	@replaces
	@args string event, any hookID

	@returns
	boolean: whenever it was enabled
]]
function hook.EnableTask(event, stringID)
	assert(type(event) == 'string', 'hook.DisableTask - event is not a string! ' .. type(event))

	if not stringID then
		return hook.EnableHook(event, 'DLib Task Executor')
	end

	if not __tableTasks[event] then return end

	stringID = transformStringID('hook.DisableTask', stringID, event)

	if not __tableTasks[event][stringID] then return end

	local wasDisabled = __tableTasks[event][stringID].disabled
	__tableTasks[event][stringID].disabled = false
	hook.ReconstructTasks(event)
	return wasDisabled
end
