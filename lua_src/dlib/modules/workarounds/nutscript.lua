
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

local HOOKS_CACHE
local SCHEMA = {}

local function patchHook(event)
	local hookTab = HOOKS_CACHE[event]

	if not hookTab then
		DLib.Message(debug.traceback('Nutscript event ' .. event .. ' is empty/missing!'))
		return
	end

	DLib.Message('Patched Nutscript ' .. event .. ' event')

	return hook.Add(event, 'nutscript', function(...)
		for funcID, func in pairs(hookTab) do
			local args = {func(funcID, ...)}

			if #args ~= 0 then
				return unpack(args, 1, #args)
			end
		end

		local sfunc = SCHEMA[event]

		if sfunc then
			return sfunc(SCHEMA, ...)
		end
	end, -10) -- as i understand nutscript wants to run in the front of all
end

local function patch()
	timer.Remove('DLib.PatchNutscript')

	if not nut then return end
	if not nut.plugin then return end
	if not nut.plugin.load then return end

	SCHEMA = _G.SCHEMA or {}

	local upvalName, upvalValue = debug.getupvalue(nut.plugin.load, 1)

	-- lets guess
	if upvalName ~= 'HOOKS_CACHE' then
		upvalValue = _G.HOOKS_CACHE or GAMEMODE.HOOKS_CACHE or nut.HOOKS_CACHE or nut.plugin.HOOKS_CACHE
	end

	if not upvalValue then
		DLib.Message('------------------------------')
		DLib.Message('Unable to patch nutscript hook')
		DLib.Message('------------------------------')
		return
	end

	HOOKS_CACHE = upvalValue

	setmetatable(HOOKS_CACHE, {
		__newindex = function(self, key, value)
			rawset(self, key, value)
			patchHook(key)
		end
	})

	for event, eventData in pairs(HOOKS_CACHE) do
		patchHook(event)
	end

	DLib.Message('------------------------------')
	DLib.Message('Nutscript successfully patched!')
	DLib.Message('------------------------------')
end

timer.Create('DLib.PatchNutscript', 0, 1, patch)

hook.Add('DLibHookChange', 'NutscriptPatch', function(key)
	if key == 'NutCall' then
		patch()
		hook.Remove('DLibHookChange', 'NutscriptPatch')
	end
end)
