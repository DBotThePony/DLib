
-- Copyright (C) 2017-2018 DBot

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
