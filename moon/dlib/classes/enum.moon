
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


class DLib.Enum
	new: (...) =>
		@enums = {...}
		@enumsInversed = {v, i for i, v in ipairs @enums}

	encode: (val, indexFail = 1) =>
		return indexFail if @enumsInversed[val] == nil
		return @enumsInversed[val]

	decode: (val, indexFail = 1) =>
		val = tonumber(val) if type(val) ~= 'number'
		return @enums[indexFail] if @enums[val] == nil
		return @enums[val]

	write: (val, ifNone) =>
		net.WriteUInt(@encode(val, ifNone), net.ChooseOptimalBits(#@enums))

	read: (ifNone) =>
		@decode(net.ReadUInt(net.ChooseOptimalBits(#@enums)), ifNone)
