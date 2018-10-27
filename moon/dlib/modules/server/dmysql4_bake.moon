
-- Copyright (C) 2018 DBot

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

import table, type, error, assert from _G

-- Simulated
class DMySQL4.PlainBakedQuery
	new: (database, plain) =>
		assert(type(plain) == 'string', 'Raw query is not a string! ' .. type(plain))
		@database = database
		@raw = plain
		@parts = plain\split('?')
		@length = #@parts - 1

	ExecInPlace: (args) => @database\Query(@Format(args))
	Execute: (args) => @Format(args)
	Format: (...) =>
		return @raw if @length == 0

		@buff = {}

		for i, val in ipairs @parts
			if i == #@parts
				table.insert(@buff, val)
			elseif select(i, ...) == nil
				table.insert(@buff, val)
				table.insert(@buff, 'null')
			elseif type(select(i, ...)) == 'boolean'
				table.insert(@buff, val)
				table.insert(@buff, SQLStr(select(i, ...) and '1' or '0'))
			else
				table.insert(@buff, val)
				table.insert(@buff, SQLStr(tostring(select(i, ...))))

		return table.concat(@buff)
