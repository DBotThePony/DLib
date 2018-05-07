
-- Copyright (C) 2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local filesLoad = {}
local i18n = i18n
local file = file
local ipairs = ipairs
local pairs = pairs
local table = table
local ProtectedCall = ProtectedCall
local getfenv = getfenv

function i18n.refreshFileList()
	filesLoad = {}

	local _, dirs = file.Find('dlib/i18n/*', 'LUA')

	for i, dir in ipairs(dirs) do
		local files = file.Find('dlib/i18n/' .. dir .. '/*', 'LUA')

		for i2, luafile in ipairs(files) do
			if luafile:sub(-4) == '.lua' then
				table.insert(filesLoad, {luafile:sub(1, -5), 'dlib/i18n/' .. dir .. '/' .. luafile})
			end
		end
	end

	return filesLoad
end

function i18n.loadFileList()
	for i, data in ipairs(filesLoad) do
		AddCSLuaFile(data[2])
		i18n.executeFile(data[1], data[2])
	end
end

function i18n.executeFile(langSpace, fileToRun)
	return i18n.executeFunction(langSpace, CompileFile(fileToRun))
end

local createNamedTable
local setmetatable = setmetatable
local mt = getmetatable

local tableMeta = {
	__index = function(self, key)
		if type(key) ~= 'string' then
			error('You can only use strings as indexes')
		end

		local value = rawget(self, key)
		if value ~= nil then return value end
		local newTable = createNamedTable(key, self)
		rawset(self, key, newTable)
		return newTable
	end,

	__newindex = function(self, key, value)
		if type(value) == 'table' then
			error("You don't have to define tables!")
		end

		if type(key) ~= 'string' then
			error('You can only use strings as indexes')
		end

		if type(value) == 'number' then
			value = value:tostring()
		end

		if type(value) ~= 'string' then
			error('You can only define strings')
		end

		local parent = mt(self).__parent
		local build = mt(self).__name .. '.' .. key

		while parent do
			build = mt(parent).__name .. '.' .. build
			parent = mt(parent).__parent
		end

		rawset(self, key, value)
		i18n.registerPhrase(mt(self).__lang, build, value)
	end
}

function createNamedTable(tableName, parent)
	local output = {}
	local meta = {
		__index = tableMeta.__index,
		__newindex = tableMeta.__newindex,
		__parent = parent,
		__name = tableName,
		__lang = i18n.LANG_SPACE
	}

	return setmetatable(output, meta)
end

local defaultNames = {
	'gui', 'attack', 'death', 'reason', 'command',
	'click', 'info', 'message', 'err', 'warning',
	'tip', 'player', 'help'
}

local function __indexEnv(self, key)
	local value = rawget(self, key)

	if value ~= nil then
		return value
	end

	value = getfenv(0)[key]

	if value ~= nil then
		return getfenv(0)[key]
	end

	local newTable = createNamedTable(key)
	rawset(self, key, newTable)
	return newTable
end

local function __newIndexEnv(self, key, value)
	getfenv(0)[key] = value
end

local function protectedFunc(langSpace, funcToRun)
	local envToRun = {
		LANGUAGE = langSpace
	}

	local namespace = {}

	for i, def in ipairs(defaultNames) do
		namespace[def] = createNamedTable(def)
	end

	for key, value in pairs(namespace) do
		envToRun[key] = value
	end

	envToRun.NAMESPACE = namespace
	envToRun.LANG_NAMESPACE = namespace
	envToRun.LANGUAGE_NAMESPACE = namespace

	setmetatable(envToRun, {
		__index = __indexEnv,
		__newindex = __newIndexEnv,
		__lang = langSpace,
		__space = namespace
	})

	local oldenv = getfenv(funcToRun)
	setfenv(funcToRun, envToRun)

	ProtectedCall(funcToRun)

	if oldenv then
		setfenv(funcToRun, oldenv)
	end
end

function i18n.executeFunction(langSpace, funcToRun)
	i18n.LANG_SPACE = langSpace
	local status = ProtectedCall(protectedFunc:Wrap(langSpace, funcToRun))
	i18n.LANG_SPACE = nil

	return status
end
