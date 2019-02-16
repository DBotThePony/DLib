
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


import Lerp, DLib, table, assert, type from _G

DLib.Bezier = {}

class DLib.Bezier.Number
	new: (step = 0.05, startpos = 0, endpos = 1) =>
		@values = {}
		@step = step
		@startpos = startpos
		@endpos = endpos
		@populated = {}
		@status = false

	AddPoint: (value) =>
		table.insert(@values, value)
		return @
	PushPoint: (value) => @AddPoint(value)
	AddValue: (value) => @AddPoint(value)
	PushValue: (value) => @AddPoint(value)
	Add: (value) => @AddPoint(value)
	Push: (value) => @AddPoint(value)
	RemovePoint: (i) => table.remove(@values, i)
	PopPoint: => table.remove(@values)

	BezierValues: (t) => t\tbezier(@values)

	CheckValues: => #@values > 1
	Populate: =>
		assert(@CheckValues(), 'at least two values must present')
		@status = true
		@populated = [@BezierValues(t) for t = @startpos, @endpos, @step]
		return @

	CopyValues: => [val for val in *@values]
	GetValues: => @values
	GetPopulatedValues: => @populated
	CopyPopulatedValues: => [val for val in *@populated]
	Lerp: (t, a, b) => Lerp(t, a, b)
	GetValue: (t = 0) =>
		assert(@status, 'Not populated!')
		assert(type(t) == 'number', 'invalid T')
		t = t\clamp(0, 1) / @step + @startpos
		return @populated[t] if @populated[t]
		t2 = t\ceil()
		prevValue = @populated[t2 - 1] or @populated[1]
		nextValue = @populated[t2] or @populated[2]
		return @Lerp(t % 1, prevValue, nextValue)

import Vector, LerpVector from _G

class DLib.Bezier.Vector extends DLib.Bezier.Number
	new: (...) =>
		super(...)
		@valuesX = {}
		@valuesY = {}
		@valuesZ = {}

	CheckValues: => #@valuesX > 1
	GetValues: => @valuesX, @valuesY, @valuesZ
	CopyValues: => [val for val in *@valuesX], [val for val in *@valuesY], [val for val in *@valuesZ]
	AddPoint: (value) =>
		table.insert(@valuesX, value.x)
		table.insert(@valuesY, value.y)
		table.insert(@valuesZ, value.z)
		return @

	BezierValues: (t) => Vector(t\tbezier(@valuesX), t\tbezier(@valuesY), t\tbezier(@valuesZ))
	Lerp: (t, a, b) => LerpVector(t, a, b)

import Angle, LerpAngle from _G

class DLib.Bezier.Angle extends DLib.Bezier.Number
	new: (...) =>
		super(...)
		@valuesP = {}
		@valuesY = {}
		@valuesR = {}

	CheckValues: => #@valuesP > 1
	GetValues: => @valuesP, @valuesY, @valuesR
	CopyValues: => [val for val in *@valuesP], [val for val in *@valuesY], [val for val in *@valuesR]
	AddPoint: (value) =>
		table.insert(@valuesP, value.p)
		table.insert(@valuesY, value.y)
		table.insert(@valuesR, value.r)
		return @

	BezierValues: (t) => Angle(t\tbezier(@valuesX), t\tbezier(@valuesY), t\tbezier(@valuesZ))
	Lerp: (t, a, b) => LerpAngle(t, a, b)
