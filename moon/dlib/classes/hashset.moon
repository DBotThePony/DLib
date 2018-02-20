
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

string_format = string.format
import type, pairs from _G

class DLib.HashSet extends DLib.Set
	_hash: (object) =>
		tp = type(object)
		if tp == 'string' or tp == 'number'
			return object
		else
			return string_format('%p', object)

	add: (object) =>
		return false if object == nil
		p = @_hash(object)
		return false if @values[p] ~= nil
		@values[p] = object
		return true, p

	has: (object) =>
		return false if object == nil
		p = @_hash(object)
		return @values[p] ~= nil

	remove: (object) =>
		return false if object == nil
		p = @_hash(object)
		return false if @values[p] == nil
		@values[p] = nil
		return true, p

	getValues: => [val for i, val in pairs @values]
	copyHash: => {val, val for i, val in pairs @values}
