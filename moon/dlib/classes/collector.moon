
--
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


class DLib.Collector
	new: (steps = 100, timeout = 1, def = 0) =>
		@steps = steps
		@nextvalue = 1
		@timeout = timeout
		@def = def
		@rebuild()

	Add: (...) => @add(...)
	Rebuild: (...) => @rebuild(...)
	Update: (...) => @update(...)
	Calculate: (...) => @calculate(...)
	SetSteps: (...) => @setSteps(...)
	SetTimeout: (...) => @setTimeout(...)
	SetDefault: (...) => @setDefault(...)

	add: (val = @def, update = true) =>
		time = CurTimeL()
		@values[@nextvalue] = {val, time}
		@nextvalue += 1
		@nextvalue = 1 if @nextvalue > @steps
		@update() if update

	rebuild: =>
		time = CurTimeL()
		@values = [{@def, time} for i = 1, @steps]

	update: =>
		time = CurTimeL()
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

	setDefault: (def = @def) =>
		@def = def
		@rebuild()

class DLib.Average extends DLib.Collector
	calculate: =>
		average = 0
		values = @steps
		average += val[1] for val in *@values
		return average / values
