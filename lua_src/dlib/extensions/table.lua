
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

local table = table

table.unpack = unpack
table.pairs = pairs
table.ipairs = ipairs

local metaObjects = {
	__index = function(self, key)
		local val = rawget(self, key)

		if val ~= nil then
			return val
		end

		return table[key]
	end
}

local tableMeta = {
	__call = function(self, ...)
		local newObject = {...}
		setmetatable(newObject, metaObjects)
		return newObject
	end
}

local listMeta = {
	__index = function(self, key)
		local val = rawget(self, key)

		if val ~= nil then
			return val
		end

		return table[key]
	end,

	__call = function(self, ...)
		local newObject = {...}
		setmetatable(newObject, metaObjects)
		return newObject
	end
}

debug.setmetatable(table, tableMeta)
debug.setmetatable(list, listMeta)
