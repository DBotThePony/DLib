
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


import math from _G

prefixes = {
	{'deci', 10 ^ -1}
	{'centi', 10 ^ -2}
	{'milli', 10 ^ -3}
	{'micro', 10 ^ -6}
	{'nano', 10 ^ -9}

	{'deca', 10}
	{'hecto', 10 ^ 2}
	{'kilo', 10 ^ 3}
	{'mega', 10 ^ 6}
	{'giga', 10 ^ 9}
	{'tera', 10 ^ 12}
}

class DLib.Measurment
	new: (hammerUnits) =>
		@hammer = hammerUnits
		@metres = (hammerUnits * 19.05) / 1000
		for {prefix, size} in *prefixes
			@[prefix .. 'metres'] = @metres / size

	set: (hammerUnits) =>
		@hammer = hammerUnits
		@metres = (hammerUnits * 19.05) / 1000
		for {prefix, size} in *prefixes
			@[prefix .. 'metres'] = @metres / size

	GetMetres: => @metres

	for {prefix, size} in *prefixes
		valueOut = prefix .. 'metres'
		@__base['Get' .. prefix\sub(1, 1)\upper() .. prefix\sub(2) .. 'metres'] = => @[valueOut]
		@__base['Get' .. prefix\sub(1, 1)\upper() .. prefix\sub(2) .. 'meters'] = => @[valueOut]

class DLib.MeasurmentNoCache
	new: (hammerUnits) =>
		@hammer = hammerUnits
		@metres = (hammerUnits * 19.05) / 1000

	set: (hammerUnits) =>
		@hammer = hammerUnits
		@metres = (hammerUnits * 19.05) / 1000

	GetMetres: => @metres

	for {prefix, size} in *prefixes
		valueOut = prefix .. 'metres'
		@__base['Get' .. prefix\sub(1, 1)\upper() .. prefix\sub(2) .. 'metres'] = => @metres / size
		@__base['Get' .. prefix\sub(1, 1)\upper() .. prefix\sub(2) .. 'meters'] = => @metres / size
