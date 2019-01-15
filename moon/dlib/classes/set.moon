
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


class DLib.Set
	new: =>
		@values = {}

	add: (object) =>
		return false if object == nil
		for i, val in ipairs @values
			if val == object
				return false

		return table.insert(@values, object)

	Add: (...) => @add(...)
	AddArray: (...) => @addArray(...)
	Has: (...) => @has(...)
	Includes: (...) => @has(...)
	Contains: (...) => @has(...)
	Remove: (...) => @remove(...)
	Delete: (...) => @remove(...)
	RM: (...) => @remove(...)
	UnSet: (...) => @remove(...)
	GetValues: (...) => @getValues(...)

	addArray: (objects) => @add(object) for object in *objects

	has: (object) =>
		return false if object == nil
		for i, val in ipairs @values
			if val == object
				return true

		return false

	includes: (...) => @has(...)
	contains: (...) => @has(...)

	remove: (object) =>
		return false if object == nil
		for i, val in ipairs @values
			if val == object
				table.remove(@values, i)
				return i

		return false

	delete: (...) => @remove(...)
	rm: (...) => @remove(...)
	unset: (...) => @remove(...)

	getValues: => @values
