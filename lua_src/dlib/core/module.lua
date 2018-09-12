
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
