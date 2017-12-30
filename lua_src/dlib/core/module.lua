
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

local metaTable = {
	__index = function(self, key)
		local val = rawget(self, key)

		if val ~= nil then
			return val
		end

		return rawget(self, '__base')[key]
	end,

	__newindex = rawset
}

local indexLookup = {
	__index = function(self, key)
		local index = rawget(self, '__base')

		if _G[index] then
			return _G[index][key]
		end

		return nil
	end
}

local function setupLookup(index)
	return setmetatable({__base = index}, indexLookup)
end

return function(moduleName, basedOn, isCached)
	local self = isCached and DLib[moduleName] or {}

	function self:Name()
		return moduleName
	end

	function self.export(target)
		for k, v in pairs(self) do
			if type(v) == 'function' then
				target[k] = v
			end
		end

		return target
	end

	function self.exportAll(target)
		for k, v in pairs(self) do
			target[k] = v
		end

		return target
	end

	function self.register()
		DLib[moduleName] = DLib[moduleName] or {}
		setmetatable(DLib[moduleName], getmetatable(self))
		DLib[moduleName].__base = self.__base
		return self.exportAll(DLib[moduleName])
	end

	if basedOn then
		self.__base = type(basedOn) == 'string' and (_G[basedOn] or setupLookup(basedOn)) or basedOn
		setmetatable(self, metaTable)
	end

	return self
end
