
--
-- Copyright (C) 2017-2019 DBot

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


NAV_LOOPS_PER_FRAME = CreateConVar('sv_dlib_nav_loops_per_frame', '50', {FCVAR_ARCHIVE, FCVAR_NOTIFY}, 'A* Searcher iterations per frame')
NAV_OPEN_LIMIT = CreateConVar('sv_dlib_nav_open_limit', '700', {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, 'A* Searcher "open" nodes limit (at same time)')
NAV_LIMIT = CreateConVar('sv_dlib_nav_limit', '4000', {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, 'A* Searcher total iterations limit')
FRAME_THERSOLD = CreateConVar('sv_dlib_nav_frame_limit', '5', {FCVAR_ARCHIVE, FCVAR_NOTIFY}, 'A* Searcher time limit (in milliseconds) per calculation per frame')
TIME_LIMIT = CreateConVar('sv_dlib_nav_time_limit', '2500', {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, 'A* Searcher total time limit (in milliseconds) per one search')

class AStarNode
	@NORTH_WEST = 0
	@NORTH_EAST = 1
	@SOUTH_EAST = 2
	@SOUTH_WEST = 3

	@SIDES = {@NORTH_EAST, @NORTH_WEST, @SOUTH_EAST, @SOUTH_WEST}

	new: (nav, g = 0, target = Vector(0, 0, 0)) =>
		@nav = nav
		@pos = @nav\GetCenter()
		@positions = {@pos}
		@target = target
		@g = g
		@h = target\DistToSqr(@pos)
		@f = @g + @h

	SetG: (val = 0) =>
		@g = val
		@f = @g + @h
	SetH: (val = 0) =>
		@h = val
		@f = @g + @h
	SetFrom: (val) =>
		@from = val

	__tostring: => "[DLib:AStarNode:#{@nav}]"

	GetG: => @g
	GetH: => @h
	GetF: => @f
	GetPos: => @pos
	GetFrom: => @from
	HasParent: => @from ~= nil
	GetParent: => @from
	GetAdjacentAreas: => @nav\GetAdjacentAreas()
	Underwater: => @nav\IsUnderwater()

class AStarTracer
	@nextID = 1

	@NAV_STATUS_IDLE = -1
	@NAV_STATUS_SUCCESS = 0
	@NAV_STATUS_GENERIC_FAILURE = 1
	@NAV_STATUS_WORKING = 2
	@NAV_STATUS_FAILURE_TIME_LIMIT = 3
	@NAV_STATUS_FAILURE_OPEN_NODES_LIMIT = 4
	@NAV_STATUS_FAILURE_LOOPS_LIMIT = 5
	@NAV_STATUS_FAILURE_NO_OPEN_NODES = 6
	@NAV_STATUS_INTERRUPT = 7

	new: (startPos = Vector(0, 0, 0), endPos = Vector(0, 0, 0), loopsPerIteration = NAV_LOOPS_PER_FRAME\GetInt(), nodesLimit = NAV_OPEN_LIMIT\GetInt(), limit = NAV_LIMIT\GetInt(), frameThersold = FRAME_THERSOLD\GetFloat(), timeThersold = TIME_LIMIT\GetFloat()) =>
		@ID = @@nextID
		@@nextID += 1
		@working = false
		@hasfinished = false
		@failure = false
		@success = false
		@stop = false
		@opened = {}
		@closed = {}
		@database = {}
		@points = {startPos, endPos}
		@startPos = startPos
		@endPos = endPos
		@distToEnd = endPos\Distance(startPos)
		@loopsPerIteration = loopsPerIteration
		@limit = limit
		@hasLimit = limit ~= 0
		@frameThersold = frameThersold
		@timeThersold = timeThersold
		@totalTime = 0
		@iterations = 0
		@nodesLimit = nodesLimit
		@callbackFail = =>
		@callbackSuccess = =>
		@callbackStop = =>
		@status = @@NAV_STATUS_IDLE
		@currentG = 0

	GetOpenNodes: => @opened
	GetOpenNodesCount: => #@opened
	CopyOpenNodes: => [node for node in *@opened]

	GetClosedNodes: => @closed
	GetClosedNodesCount: => #@closed
	CopyClosedNodes: => [node for node in *@closed]

	GetTotalNodes: => @database
	GetTotalNodesCount: => #@database
	CopyTotalNodes: => [node for node in *@database]

	GetIterations: => @iterations
	GetTotalIterations: => @iterations
	GetCalculationTime: => @totalTime
	GetCurrentG: => @currentG
	GetLeftDistance: => math.max(@distToEnd - math.sqrt(@currentG), 0)
	GetDistance: => @distToEnd
	Distance: => @distToEnd
	IsStopped: => @stop
	IsWorking: => @working
	IsSuccess: => @success
	IsFailure: => @failure
	IsFinished: => @hasfinished
	HasFinished: => @hasfinished

	SetSuccessCallback: (val = (=>)) =>
		@callbackSuccess = val
	SetFailCallback: (val = (=>)) =>
		@callbackFail = val
	SetFailureCallback: (val = (=>)) =>
		@callbackFail = val
	SetStopCallback: (val = (=>)) =>
		@callbackStop = val

	__tostring: => "[DLib:AStarTracer:#{@ID}]"
	GetNode: (nav) =>
		for data in *@database
			return data if data.nav == nav
	AddNode: (node) => table.insert(@database, node)

	GetPath: => @points
	GetPoints: => @points
	RecalcPath: =>
		return @points if not @hasfinished
		return @points if @failure
		@points = {@endPos}
		current = @lastNode

		while current
			table.insert(@points, current\GetPos())
			current = current\GetFrom()

		table.insert(@points, @startPos)
		return @points

	Stop: =>
		return if not @working
		@status = @@NAV_STATUS_INTERRUPT
		@working = false
		@stop = true
		@hasfinished = true
		hook.Remove 'Think', tostring(@)
		@callbackStop()

	OnSuccess: (node) =>
		@status = @@NAV_STATUS_SUCCESS
		@lastNode = node
		@working = false
		@success = true
		@hasfinished = true
		hook.Remove 'Think', tostring(@)
		@RecalcPath()
		@callbackSuccess()

	OnFailure: (status = @@NAV_STATUS_GENERIC_FAILURE) =>
		@working = false
		@failure = true
		@hasfinished = true
		@status = status
		hook.Remove 'Think', tostring(@)
		@callbackFail(status)

	GetStatus: => @status

	Start: =>
		@lastNodeNav = navmesh.Find(@endPos, 1, 20, 20)[1]
		@firstNodeNav = navmesh.Find(@startPos, 1, 20, 20)[1]
		@status = @@NAV_STATUS_WORKING

		if not @lastNodeNav or not @firstNodeNav
			@OnFailure(@@NAV_STATUS_FAILURE_NO_OPEN_NODES)
			return

		@working = true
		@iterations = 0
		@totalTime = 0
		newNode = AStarNode(@firstNodeNav, @startPos\DistToSqr(@firstNodeNav\GetCenter()), @endPos)
		@opened = {newNode}
		@database = {newNode}
		hook.Add 'Think', tostring(@), -> @ThinkHook()

	GetNearestNode: =>
		local current
		local min
		local index

		for i = 1, #@opened
			data = @opened[i]
			if not min or data.f < min
				min = data.f
				current = data
				index = i

		table.remove(@opened, index) if index
		table.insert(@closed, current) if current
		return current
	@OnError = (err) ->
		print '[DLib AStarTracer ERROR]: ', err
		print debug.traceback()
	ThinkHook: =>
		status = xpcall(@Think, @@OnError, @)
		if not status
			@OnFailure()
	Think: =>
		if not @working
			hook.Remove 'Think', tostring(@)
			return

		if #@opened == 0
			@OnFailure(@@NAV_STATUS_FAILURE_NO_OPEN_NODES)
			return

		if #@opened >= @nodesLimit
			@OnFailure(@@NAV_STATUS_FAILURE_OPEN_NODES_LIMIT)
			return

		calculationTime = 0

		for i = 1, @loopsPerIteration
			sTime = SysTime()
			@iterations += 1
			if @hasLimit and @iterations > @limit
				@OnFailure(@@NAV_STATUS_FAILURE_LOOPS_LIMIT)
				return

			nearest = @GetNearestNode()
			if not nearest break
			if nearest.nav == @lastNodeNav
				@OnSuccess(nearest)
				return

			@currentG = nearest\GetG()
			for node in *nearest\GetAdjacentAreas()
				hitClosed = false
				for cl in *@closed
					if cl.nav == node
						hitClosed = true
						break
				if hitClosed continue

				nodeObject = @GetNode(node)

				if nodeObject
					dist = nodeObject\GetPos()\DistToSqr(nearest\GetPos())
					lengthMultiplier = 1
					lengthMultiplier += 20 if nodeObject\Underwater()
					deltaZ = nodeObject\GetPos().z - nearest\GetPos().z
					lengthMultiplier += math.max(0, deltaZ) if deltaZ > 0
					lengthMultiplier += math.max(0, -deltaZ) if deltaZ < 0

					distG = nearest\GetG() + dist * lengthMultiplier
					if nodeObject\GetG() > distG
						nodeObject\SetG(distG)
						nodeObject\SetFrom(nearest)
				else
					nodeObject = AStarNode(node, nearest\GetG() + node\GetCenter()\DistToSqr(nearest\GetPos()), @endPos)
					nodeObject\SetFrom(nearest)
					@AddNode(nodeObject)
					if node\IsValid()
						table.insert(@opened, nodeObject)
					else
						table.insert(@closed, nodeObject)
			cTime = (SysTime() - sTime) * 1000
			calculationTime += cTime
			@totalTime += cTime
			if @totalTime >= @timeThersold
				@OnFailure(@@NAV_STATUS_FAILURE_TIME_LIMIT)
				return
			if calculationTime >= @frameThersold
				break

DLib.AStarTracer = AStarTracer
DLib.AStarNode = AStarNode
