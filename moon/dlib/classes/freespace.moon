
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


class DLib.Freespace
	new: (posStart = Vector(0, 0, 0), step = 25, radius = 10) =>
		@pos = posStart
		@mins = Vector(-4, -4, -4)
		@maxs = Vector(4, 4, 4)
		@step = step
		@radius = radius
		@addition = Vector(0, 0, 0)
		@usehull = true
		@filter = DLib.Set()
		@mask = MASK_SOLID
		@maskReachable = MASK_SOLID
		@strict = false
		@smins = Vector(-16, -16, 0)
		@smaxs = Vector(16, 16, 0)
		@sheight = 70

	GetMins: => @mins
	GetMaxs: => @maxs
	SetMins: (val) => @mins = val
	SetMaxs: (val) => @maxs = val
	GetPos: => @pos
	SetPos: (val) => @pos = val

	GetAddition: => @addition
	SetAddition: (val) => @addition = val
	GetStrict: => @strict
	GetStrictHeight: => @sheight
	SetStrict: (val) => @strict = val
	SetStrictHeight: (val) => @sheight = val
	GetAABB: => @mins, @maxs
	GetSAABB: => @smins, @smaxs
	SetAABB: (val1, val2) => @mins, @maxs = val1, val2
	SetSAABB: (val1, val2) => @smins, @smaxs = val1, val2

	GetMask: => @mask
	SetMask: (val) => @mask = val

	GetMaskReachable: => @maskReachable
	SetMaskReachable: (val) => @maskReachable = val

	GetStep: => @step
	GetRadius: => @radius
	SetStep: (val) => @step = val
	SetRadius: (val) => @radius = val

	check: (target) =>
		if @usehull
			tr = util.TraceHull({
				start: @pos
				endpos: target + @addition
				mins: @mins
				maxs: @maxs
				mask: @maskReachable
				filter: @filter\getValues()
			})

			if @strict and not tr.Hit
				tr2 = util.TraceHull({
					start: target + @addition
					endpos: target + @addition + Vector(0, 0, @sheight)
					mins: @smins
					maxs: @smaxs
					mask: @mask
					filter: @filter\getValues()
				})

				return not tr2.Hit, tr, tr2

			return not tr.Hit, tr
		else
			tr = util.TraceLine({
				start: @pos
				endpos: target + @addition
				mask: @maskReachable
				filter: @filter\getValues()
			})

			if @strict and not tr.Hit
				tr2 = util.TraceHull({
					start: target + @addition
					endpos: target + @addition + Vector(0, 0, @sheight)
					mins: @smins
					maxs: @smaxs
					mask: @mask
					filter: @filter\getValues()
				})

				return not tr2.Hit, tr, tr2

			return not tr.Hit, tr

	Search: =>
		if @check(@pos)
			return @pos

		for radius = 1, @radius
			for x = -radius, radius
				pos = @pos + Vector(x * @step, radius * @step, 0)
				return pos if @check(pos)
				pos = @pos + Vector(x * @step, -radius * @step, 0)
				return pos if @check(pos)

			for y = -radius, radius
				pos = @pos + Vector(radius * @step, y * @step, 0)
				return pos if @check(pos)
				pos = @pos + Vector(-radius * @step, y * @step, 0)
				return pos if @check(pos)

		return false

	SearchOptimal: =>
		validPositions = @SearchAll()
		return false if #validPositions == 0
		table.sort validPositions, (a, b) -> a\DistToSqr(@pos) < b\DistToSqr(@pos)
		return validPositions[1]

	SearchAll: =>
		output = {}
		table.insert(output, @pos) if @check(@pos)

		for radius = 1, @radius
			for x = -radius, radius
				pos = @pos + Vector(x * @step, radius * @step, 0)
				table.insert(output, pos) if @check(pos)
				pos = @pos + Vector(x * @step, -radius * @step, 0)
				table.insert(output, pos) if @check(pos)

			for y = -radius, radius
				pos = @pos + Vector(radius * @step, y * @step, 0)
				table.insert(output, pos) if @check(pos)
				pos = @pos + Vector(-radius * @step, y * @step, 0)
				table.insert(output, pos) if @check(pos)

		return output
