
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

	SearchAll: =>
		output = table()
		output\insert(@pos) if @check(@pos)

		for radius = 1, @radius
			for x = -radius, radius
				pos = @pos + Vector(x * @step, radius * @step, 0)
				output\insert(pos) if @check(pos)
				pos = @pos + Vector(x * @step, -radius * @step, 0)
				output\insert(pos) if @check(pos)

			for y = -radius, radius
				pos = @pos + Vector(radius * @step, y * @step, 0)
				output\insert(pos) if @check(pos)
				pos = @pos + Vector(-radius * @step, y * @step, 0)
				output\insert(pos) if @check(pos)

		return output
