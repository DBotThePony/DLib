
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


local meta = DLib.FindMetaTable('HUDCommonsBase')
local pairs = pairs
local ipairs = ipairs
local assert = assert
local type = type
local error = error

function meta:RegisterVariable(var, default)
	self.varMeta = nil

	if default == nil then
		default = function() return 0 end
	end

	if type(default) ~= 'function' then
		local ret = default
		default = function() return ret end
	end

	local ldata

	for i, data in ipairs(self.variables) do
		if data.var == var then
			ldata = data
			break
		end
	end

	if not ldata then
		ldata = {
			var = var,
			fname = var:formatname(),
			func = 'GetVar' .. var:formatname()
		}

		ldata.id = table.insert(self.variables, ldata)
		self.variablesHash[var] = ldata

		self['GetVar' .. var:formatname()] = function()
			return ldata.value
		end
	end

	ldata.default = default
	ldata.self = ldata.self or {}
	ldata.tick = ldata.tick or function(self, hudSelf, localPlayer, currentValue, lastTick) return currentValue end
	ldata.onChange = ldata.onChange or function(self, hudSelf, localPlayer, oldVariable, newVariable) end

	ldata.onGlitch = ldata.onGlitch or function(self, hudSelf, localPlayer, remaining) end
	ldata.onGlitchStart = ldata.onGlitch or function(self, hudSelf, localPlayer, timeLong) end
	ldata.onGlitchEnd = ldata.onGlitch or function(self, hudSelf, localPlayer) end

	ldata.onDeath = ldata.onDeath or function(self, hudSelf, localPlayer) end
	ldata.onRespawn = ldata.onRespawn or function(self, hudSelf, localPlayer) end

	ldata.onDisabled = ldata.onDisabled or function(self, hudSelf, localPlayer) end
	ldata.onEnabled = ldata.onDisabled or function(self, hudSelf, localPlayer) end

	ldata.onWeaponChanged = ldata.onWeaponChanged or function(self, hudSelf, localPlayer, oldWeapon, newWeapon) end
	ldata.ammoTypeChanges = ldata.onDisabled or function(self, hudSelf, localPlayer, oldType, newType) end

	ldata.value = default()

	return ldata
end

local hooks = {
	'tick',
	'onChange',
	'onGlitch',
	'onDeath',
	'onRespawn',
	'onWeaponChanged',
	'onDisabled',
	'onEnabled',
	'onGlitchStart',
	'onGlitchEnd',
	'ammoTypeChanges',
}

function meta:GetVariable(var)
	assert(type(var) == 'string', 'ID is not a string!')
	return assert(self.variablesHash[var], 'No such variable: ' .. var).value
end

for i, hookType in ipairs(hooks) do
	local hName = hookType:formatname()

	meta['Set' .. hName .. 'Hook'] = function(self, var, newFunction)
		assert(type(var) == 'string', 'ID is not a string!')
		assert(type(newFunction) == 'function', 'Input is not a function!')

		local ldata

		for i, data in ipairs(self.variables) do
			if data.var == var then
				ldata = data
				break
			end
		end

		if not ldata then
			error('Variable must be initialized before setting its hooks')
		end

		ldata[hookType] = newFunction
		return ldata
	end

	meta['Patch' .. hName .. 'Hook'] = function(self, var, newFunction)
		assert(type(var) == 'string', 'ID is not a string!')
		assert(type(newFunction) == 'function', 'Input is not a function!')

		local ldata

		for i, data in ipairs(self.variables) do
			if data.var == var then
				ldata = data
				break
			end
		end

		if not ldata then
			error('Variable must be initialized before setting its hooks')
		end

		local old = ldata[hookType]

		ldata[hookType] = function(...)
			old(...)
			return newFunction(...)
		end

		return ldata
	end

	meta['SoftPatch' .. hName .. 'Hook'] = function(self, var, newFunction)
		assert(type(var) == 'string', 'ID is not a string!')
		assert(type(newFunction) == 'function', 'Input is not a function!')

		local ldata

		for i, data in ipairs(self.variables) do
			if data.var == var then
				ldata = data
				break
			end
		end

		if not ldata then
			error('Variable must be initialized before setting its hooks')
		end

		local old = ldata[hookType]

		ldata[hookType] = function(self1, self2, localPlayer, ...)
			return newFunction(self1, self2, localPlayer, old(self1, self2, localPlayer, ...))
		end

		return ldata
	end

	meta['Get' .. hName .. 'Hook'] = function(self, var)
		assert(type(var) == 'string', 'ID is not a string!')

		local ldata

		for i, data in ipairs(self.variables) do
			if data.var == var then
				ldata = data
				break
			end
		end

		if not ldata then
			error('Variable must be initialized before setting its hooks')
		end

		return ldata[hookType]
	end

	meta['Call' .. hName] = function(self, ...)
		if #self.variables == 0 then return end
		local vars = self.variables
		local lPly = self:SelectPlayer()

		local i, nextevent = 1, vars[1]
		::loop::

		nextevent[hookType](nextevent.self, self, lPly, ...)

		i = i + 1
		nextevent = vars[i]

		if nextevent ~= nil then
			goto loop
		end
	end
end

-- override
function meta:InitVaribles()

end

function meta:TickVariables(lPly)
	local vars = self.variables

	for i = 1, #vars do
		local entry = vars[i]
		local grab = entry.tick(entry.self, self, lPly, entry.value)

		if grab ~= entry.value then
			entry.onChange(entry.self, self, lPly, entry.value, grab)
			entry.value = grab
		end
	end
end

function meta:BuildVariableMeta()
	self.varMeta = {}

	for i, data in ipairs(self.variables) do
		self.varMeta[data.func] = function()
			return self[data.var]
		end
	end
end

local setmetatable = setmetatable

function meta:RecordVariableState()
	if not self.varMeta then
		self:BuildVariableMeta()
	end

	local vars = setmetatable({}, self.varMeta)

	for i, data in ipairs(self.variables) do
		vars[data.var] = self[data.func](self)
	end

	return vars
end

include('defaultvars.lua')
