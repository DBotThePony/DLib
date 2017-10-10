
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

	getMins: => @mins
	getMaxs: => @maxs
	setMins: (val) => @mins = val
	setMaxs: (val) => @maxs = val
	getPos: => @pos
	setPos: (val) => @pos = val

	getAddition: => @addition
	setAddition: (val) => @addition = val

	getStep: => @step
	getRadius: => @radius
	setStep: (val) => @step = val
	setRadius: (val) => @radius = val

	check: (target) =>
		if @usehull
			tr = util.TraceHull({
				start: @pos
				endpos: target + @addition
				mins: @mins
				maxs: @maxs
				filter: @filter\getValues()
			})

			return not tr.Hit, tr
		else
			tr = util.TraceLine({
				start: @pos
				endpos: target + @addition
				filter: @filter\getValues()
			})

			return not tr.Hit, tr

	search: =>
		if @check(@pos)
			return @pos

		for radius = 1, @radius
			for x = -radius, radius
				pos = @pos + Vector(x, radius, 0)
				return pos if @check(pos)
				pos = @pos + Vector(x, -radius, 0)
				return pos if @check(pos)

			for y = -radius, radius
				pos = @pos + Vector(radius, y, 0)
				return pos if @check(pos)
				pos = @pos + Vector(-radius, y, 0)
				return pos if @check(pos)

		return false

	searchAll: =>
		output = table()
		output\insert(@pos) if @check(@pos)

		for radius = 1, @radius
			for x = -radius, radius
				pos = @pos + Vector(x, radius, 0)
				output\insert(pos) if @check(pos)
				pos = @pos + Vector(x, -radius, 0)
				output\insert(pos) if @check(pos)

			for y = -radius, radius
				pos = @pos + Vector(radius, y, 0)
				output\insert(pos) if @check(pos)
				pos = @pos + Vector(-radius, y, 0)
				output\insert(pos) if @check(pos)

		return output
