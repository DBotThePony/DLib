
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
