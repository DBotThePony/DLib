
--
-- Copyright (C) 2017-2018 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

class DLib.Collector
	new: (steps = 100, timeout = 1, def = 0) =>
		@steps = steps
		@nextvalue = 1
		@timeout = timeout
		@def = def
		@rebuild()

	add: (val = @def, update = true) =>
		time = CurTime()
		@values[@nextvalue] = {val, time}
		@nextvalue += 1
		@nextvalue = 1 if @nextvalue > @steps
		@update() if update

	rebuild: =>
		time = CurTime()
		@values = [{@def, time} for i = 1, @steps]

	update: =>
		time = CurTime()
		@values = for valData in *@values
			if valData[2] + @timeout < time
				{@def, time}
			else
				valData

	calculate: =>
		output = 0
		output += val[1] for val in *@values
		return output

	think: => @update()
	Think: => @update()
	Update: => @update()

	setSteps: (steps = @steps) =>
		@steps = steps
		@nextvalue = 1
		@rebuild()

	setTimeout: (timeout = @timeout) =>
		@timeout = timeout
		@rebuild()

	setTimeout: (timeout = @timeout) =>
		@timeout = timeout
		@rebuild()

	setDefault: (def = @def) =>
		@def = def
		@rebuild()
