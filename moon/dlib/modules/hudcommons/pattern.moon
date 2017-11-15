
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
