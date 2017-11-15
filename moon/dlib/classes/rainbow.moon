
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
rnd = util.SharedRandom
Color = Color
math = math

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

	Next: =>
		@pointer += 1
		@pointer = 1 if #@values < @pointer
		return @values[@pointer]
