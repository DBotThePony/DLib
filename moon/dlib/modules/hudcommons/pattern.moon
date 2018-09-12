
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


HUDCommons = HUDCommons
util = util

class HUDCommons.Pattern
	new: (randomize = false, seed = 'HUDCommons.Pattern', iterations = 8, min = -2, max = 2) =>
		@isRandom = randomize
		@iterations = iterations
		@min = min
		@max = max
		@seed = seed
		@valuesX = {}
		@valuesY = {}
		@pointerX = 1
		@pointerY = 1
		@Randomize() if randomize

	Randomize: =>
		@isRandom = true
		@pointerX = 1
		@pointerY = 1
		@valuesX = [util.SharedRandom(@seed, @min, @max, i) for i = 1, @iterations]
		@valuesY = [util.SharedRandom(@seed, @min, @max, i + @iterations) for i = 1, @iterations]
		return @values

	Next: =>
		@NextValueX()
		@NextValueY()
		return @

	NextValueX: =>
		@pointerX += 1
		@pointerX = 1 if @pointerX > #@valuesX
		return @valuesX[@pointer]

	NextValueY: =>
		@pointerY += 1
		@pointerY = 1 if @pointerY > #@valuesY
		return @valuesY[@pointer]

	CurrentValueX: => @valuesX[@pointerX]
	CurrentValueY: => @valuesY[@pointerY]

	SimpleText: (text, font, x, y, col) => HUDCommons.SimpleText(text, font, x + @CurrentValueX(), y + @CurrentValueY(), col)
	WordBox: (text, font, x, y, col, colBox, center) => HUDCommons.WordBox(text, font, x + @CurrentValueX(), y + @CurrentValueY(), col, colBox, center)
	DrawBox: (x, y, w, h, color) => HUDCommons.DrawBox(x + @CurrentValueX(), y + @CurrentValueY(), w, h, col)
	VerticalBar: (x, y, w, h, mult, color) => HUDCommons.VerticalBar(x + @CurrentValueX(), y + @CurrentValueY(), w, h, mult, color)
	SkyrimBar: (x, y, w, h, color) => HUDCommons.SkyrimBar(x + @CurrentValueX(), y + @CurrentValueY(), w, h, color)

	Clear: =>
		@valuesX = {}
		@valuesY = {}
		return @

	AddValueX: (val) =>
		@valuesX[#@valuesX + 1] = val
		return @

	AddValueY: (val) =>
		@valuesY[#@valuesY + 1] = val
		return @

	PointerX: => @pointerX
	PointerY: => @pointerY
	SeekX: (val) => @pointerX = val
	SeekY: (val) => @pointerY = val
	Reset: =>
		@pointerX = 1
		@pointerY = 1
