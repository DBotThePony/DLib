
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

CAMI = CAMI
DLib = DLib
CLIENT = CLIENT
SERVER = SERVER
LocalPlayer = LocalPlayer
pairs = pairs
ipairs = ipairs
IsValid = IsValid
player = player
timer = timer
table = table

class DLib.CAMIWatchdog
	new: (idetifier, repeatSpeed = 10, ...) =>
		error('No idetifier!') if not idetifier
		@repeatSpeed = repeatSpeed
		@idetifier = idetifier
		@tracked = DLib.Set()
		@trackedReplies = {} if CLIENT
		@trackedPanels = {} if CLIENT
		@trackedRepliesPly = {} if SERVER
		@Track(...)
		timer.Create 'DLib.CAMIWatchdog.' .. @idetifier, repeatSpeed, 0, -> @TriggerUpdate()
		@TriggerUpdate()

	Track: (...) =>
		@tracked\addArray({...})
		return @

	HasPermission: (ply, perm) =>
		if CLIENT
			perm = ply
			return @trackedReplies[perm]
		else
			return @trackedRepliesPly[ply] and @trackedRepliesPly[ply][perm]

	HandlePanel: (perm, pnl) =>
		return if SERVER
		@trackedPanels[perm] = @trackedPanels[perm] or {}
		table.insert(@trackedPanels[perm], pnl)
		return @

	TriggerUpdate: =>
		@TriggerUpdateClient() if CLIENT
		@TriggerUpdateServer() if SERVER

	TriggerUpdateClient: =>
		ply = LocalPlayer()
		return if not ply\IsValid() or not ply.UniqueID

		for perm in *@tracked.values
			CAMI.PlayerHasAccess ply, perm, (has = false, reason = '') ->
				old = @trackedReplies[perm]
				@trackedReplies[perm] = has
				if old ~= has and @trackedPanels[perm]
					cleanup = {}
					for k, v in ipairs @trackedPanels[perm]
						if IsValid(v)
							v\SetEnabled(has)
						else
							table.insert(cleanup, k)
					table.removeValues(@trackedPanels[perm], cleanup)

	TriggerUpdateServer: =>
		@trackedRepliesPly = {ply, data for ply, data in pairs @trackedRepliesPly when ply\IsValid()}

		for ply in *player.GetAll()
			@trackedRepliesPly[ply] = @trackedRepliesPly[ply] or {}
			for perm in *@tracked.values
				CAMI.PlayerHasAccess ply, perm, (has = false, reason = '') -> @trackedRepliesPly[ply][perm] = has if IsValid(ply)

