
-- Copyright (C) 2017-2020 DBotThePony

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

local DLib = DLib
local HUDCommons = DLib.HUDCommons
local meta = HUDCommons.BaseMetaObj
local pairs = pairs
local ipairs = ipairs
local assert = assert
local type = type
local error = error

--[[
	@doc
	@fname HUDCommonsBase:RegisterVariable
	@args string var, function defaultValue

	@client

	@desc
	Defines a new variable for HUD
	It has various hooks but by default these hooks do nothing.
	Calling this function when variable already exists will refresh variable's table
	`default` is a function which should return default value.
	`default` can be a special string: `'NULLABLE'`, which when used, tells that default value is `nil`
	Look for other functions in !c:HUDCommonsBase to see how to manipulate hooks of variables!

	Also, defining a variable will define getter for it over your HUD
	To access carible, call `self:GetVar[your variable name here]`

	**Keep in mind that:**
	names should be generic
	should not contain spaces (altrough it is not restricted, but you won't be able to call getter easily)
	variable name is being pretty formatted. It means that if you pass for example `'myVar'` it will turn into `GetVarMyVar()` on getter and so on.

	*Also checkout `HUDCommonsBase:RegisterRegularVariable` method!*
	@enddesc

	@returns
	table: variable data
]]
function meta:RegisterVariable(var, default)
	self.varMeta = nil

	if default == nil then
		default = function() return 0 end
	elseif default == 'NULLABLE' then
		default = function() end
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
			self = {},
			func = 'GetVar' .. var:formatname()
		}

		ldata.id = table.insert(self.variables, ldata)
		self.variablesHash[var] = ldata

		self['GetVar' .. var:formatname()] = function()
			return ldata.value
		end
	end

	ldata.default = default
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


--[[
	@docpreprocess

	const hooks = [
		'Tick',
		'OnChange',
		'OnGlitch',
		'OnDeath',
		'OnRespawn',
		'OnWeaponChanged',
		'OnDisabled',
		'OnEnabled',
		'OnGlitchStart',
		'OnGlitchEnd',
		'AmmoTypeChanges',
	]

	const reply = []

	for (const hName of hooks) {
		let output = []

		output.push(`@fname HUDCommonsBase:Set${hName}Hook`)
		output.push(`@args string var, function newFunction`)
		output.push(`@client`)
		output.push(`@desc`)
		output.push(`Sets \`${hName}\` hook function for variable names \`var\``)
		output.push(`Keep in mind that different hook functions will receive different arguments`)
		output.push(`Refer to \`defaultvars.lua\` in DLib and to 4HUD/FFGSHUD code`)
		output.push(`Some hooks are supposed to return values`)
		output.push(`But arguments of any hook will always start with:`)
		output.push(`variable's private self table`)
		output.push(`HUD's self table`)
		output.push(`current player`)
		output.push(`@enddesc`)
		output.push(`@returns`)
		output.push(`table: variable data`)

		reply.push(output)

		output = []

		output.push(`@fname HUDCommonsBase:Patch${hName}Hook`)
		output.push(`@args string var, function newFunction`)
		output.push(`@client`)
		output.push(`@desc`)
		output.push(`Wraps \`${hName}\`'s' hook function (if exists) or replaces it (if not exists)`)
		output.push(`Works pretty much the same as \`HUDCommonsBase:Set${hName}Hook\` except old function is still called`)
		output.push(`@enddesc`)
		output.push(`@returns`)
		output.push(`table: variable data`)

		reply.push(output)

		output = []

		output.push(`@fname HUDCommonsBase:SoftPatch${hName}Hook`)
		output.push(`@args string var, function newFunction`)
		output.push(`@client`)
		output.push(`@desc`)
		output.push(`Works pretty much the same as \`HUDCommonsBase:Patch${hName}Hook\` exceptd`)
		output.push(`old's function return values are being passed to new function provided (function composition)`)
		output.push(`@enddesc`)
		output.push(`@returns`)
		output.push(`table: variable data`)

		reply.push(output)

		output = []

		output.push(`@fname HUDCommonsBase:Call${hName}`)
		output.push(`@args vararg arguments`)
		output.push(`@internal`)
		output.push(`@client`)

		reply.push(output)
	}

	return reply
]]

--[[
	@doc
	@fname HUDCommonsBase:GetVariable
	@args string var

	@client

	@desc
	This is the same as calling `self:GetVar[varname]()`
	but slower
	@enddesc

	@returns
	any: value of that variable
]]
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

		if not old then
			return meta['Set' .. hName .. 'Hook'](self, var, newFunction)
		end

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

		if not old then
			return meta['Set' .. hName .. 'Hook'](self, var, newFunction)
		end

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

--[[
	@doc
	@fname HUDCommonsBase:TickVariables
	@args Player ply

	@client
	@internal

	@desc
	calls `tick` hook on all variables
	@enddesc
]]
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

--[[
	@doc
	@fname HUDCommonsBase:BuildVariableMeta

	@client
	@internal
]]
function meta:BuildVariableMeta()
	self.varMeta = {}

	for i, data in ipairs(self.variables) do
		self.varMeta[data.func] = function()
			return self[data.var]
		end
	end
end

local setmetatable = setmetatable

--[[
	@doc
	@fname HUDCommonsBase:RecordVariableState

	@client

	@returns
	table
]]
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
