
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
		@trackedRepliesPly = {}
		@Track(...)
		timer.Create 'DLib.CAMIWatchdog.' .. @idetifier, repeatSpeed, 0, -> @TriggerUpdate()
		@TriggerUpdate()

	Track: (...) =>
		@tracked\addArray({...})
		return @

	HasPermission: (ply, perm) =>
		if CLIENT and type(ply) == 'string'
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
		@TriggerUpdateRegular()

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

	TriggerUpdateRegular: =>
		@trackedRepliesPly = {ply, data for ply, data in pairs @trackedRepliesPly when ply\IsValid()}

		for ply in *player.GetAll()
			@trackedRepliesPly[ply] = @trackedRepliesPly[ply] or {}
			for perm in *@tracked.values
				CAMI.PlayerHasAccess ply, perm, (has = false, reason = '') -> @trackedRepliesPly[ply][perm] = has if IsValid(ply)

