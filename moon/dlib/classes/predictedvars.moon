
-- Copyright (C) 2017-2019 DBotThePony

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

_OBJECTS = DLib.PredictedVarList and DLib.PredictedVarList._OBJECTS or {}

class DLib.PredictedVarList
	@_OBJECTS = _OBJECTS

	GetByName: (id) => @_OBJECTS[id]

	new: (netname) =>
		@netname = assert(netname, 'Missing network name')
		@@_OBJECTS[@netname] = @

		@vars = {}
		@prev = {}
		@cur = {}
		@first = {}
		@frame_id = 0
		@firstF = true
		@sync_cooldown = 60
		@_nw = 'dlib_pred_' .. netname

		if SERVER
			net.pool(@_nw)
			@sync_closure = -> @Sync(ply) for ply in *player.GetAll() when ply.__dlib_predvars and ply.__dlib_predvars[@netname]
			timer.Create 'DLib.PredictedVarList.Sync', @sync_cooldown, 0, -> ProtectedCall @sync_closure
		else
			net.receive @_nw, -> @prev = net.ReadTable()

	SetSyncTimer: (stimer = @sync_cooldown) =>
		@sync_cooldown = assert(type(stimer) == 'number' and stimer >= 0, 'Time must be a positive number!')
		timer.Create 'DLib.PredictedVarList.Sync', @sync_cooldown, 0, -> ProtectedCall @sync_closure

	Sync: (ply) =>
		error('Invalid realm') if CLIENT
		net.Start(@_nw)
		ply.__dlib_predvars = ply.__dlib_predvars or {}
		ply.__dlib_predvars[@netname] = ply.__dlib_predvars[@netname] or {}
		net.WriteTable(ply.__dlib_predvars[@netname])
		net.Send(ply)

	GetFrame: => @frame_id

	AddVar: (identifier, def) =>
		@vars[identifier] = def
		return @

	Invalidate: (ply) =>
		if SERVER
			@frame_id += 1

			ply.__dlib_predvars = {} if not ply.__dlib_predvars
			ply.__dlib_predvars[@netname] = {} if not ply.__dlib_predvars[@netname]

			return

		if IsFirstTimePredicted()
			@firstF = true
			@frame_id += 1

			for key, value in pairs(@first)
				@prev[key] = value
				@cur[key] = nil
				@first[key] = nil

			return

		@firstF = false
		@cur[key] = nil for key in pairs(@cur)

	Get: (ply, identifier, def = @vars[identifier]) =>
		if SERVER
			return def if not ply.__dlib_predvars or not ply.__dlib_predvars[@netname]
			val = ply.__dlib_predvars[@netname][identifier]
			return val if val ~= nil
			return def

		assert(def ~= nil, 'Variable does not exist')

		if @firstF
			val = @first[identifier]
			return val if val ~= nil
			return @prev[identifier] if @prev[identifier] ~= nil
			return def

		val = @cur[identifier]
		return val if val ~= nil
		return @prev[identifier] if @prev[identifier] ~= nil
		return def

	Set: (ply, identifier, val) =>
		if SERVER
			assert(assert(ply.__dlib_predvars, ':Invalidate() was never called with this player')[@netname], ':Invalidate() was never called with this player')[identifier] = val
			@Sync(ply) if game.SinglePlayer()
			return

		assert(@vars[identifier] ~= nil, 'Variable does not exist')

		if @firstF
			@first[identifier] = val
			return

		@cur[identifier] = val
