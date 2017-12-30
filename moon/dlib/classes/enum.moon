
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
