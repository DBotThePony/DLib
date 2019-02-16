
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


HUDCommons = HUDCommons
rnd = util.SharedRandom
Color = Color
math = math
sin = math.sin
cos = math.cos

class DLib.RandomRainbow
	new: (seed = 'DLib.RandomRainbow', iterations = 8, strength = 1, move = iterations * 2) =>
		@seed = seed
		@iterations = iterations
		@strength = strength
		@move = move
		@values = {}
		@pointer = 1
		@Randomize()

	Randomize: =>
		@pointer = 1
		@values = [Color(128 + rnd(@seed, -128, 127, i * @strength), 128 + rnd(@seed, -128, 127, i * @strength + @move), 128 + rnd(@seed, -128, 127, i * @strength + @move * 2)) for i = 1, @iterations]
		return @

	Next: =>
		@pointer += 1
		@pointer = 1 if #@values < @pointer
		return @values[@pointer]

class DLib.Rainbow
	new: (length = 64, strength = 0.2, move = 2, forward = true, mult = 1) =>
		@mult = mult
		@length = length
		@strength = strength
		@move = move
		@forward = forward
		@values = {}
		@pointer = 1
		@Create()

	Create: =>
		@pointer = 1
		if @forward
			@values = [Color(128 * @mult + cos(i * @strength) * 127 * @mult, 128 + cos(i * @strength + @move) * 127 * @mult, 128 * @mult + cos(i * @strength + @move * 2) * 127 * @mult) for i = 1, @length]
		else
			@values = [Color(128 * @mult + sin(i * @strength) * 127 * @mult, 128 + sin(i * @strength + @move) * 127 * @mult, 128 * @mult + sin(i * @strength + @move * 2) * 127 * @mult) for i = 1, @length]
		return @

	Next: =>
		@pointer += 1
		@pointer = 1 if #@values < @pointer
		return @values[@pointer]
