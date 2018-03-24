
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

-- this is a modified DLib's loader code
-- and VLL's adapted features (VLL.Include, VLL.Compile)

-- This allows you to create secure (or "private global" spaces withit file(s) you load recursively)
-- with your own variables and behaviour
-- in other words, it is much more advanced "module()"

-- WARNING: Regarding "sandbox", this isn't a sandbox
-- but a tool to load files with some "global" variables modified

-- ATTENTION - This will NOT work properly within context of
-- addons/code which thinkers with files environment (such as VLL)

local DLib = DLib
local CompileFile = CompileFile
local CompileString = CompileString
local sandbox = DLib.module('sandbox')

function sandbox.include(path, ...)
	return sandbox.compileFile(path, ...)()
end

local function wrap(compiled, environment, accessGlobal, global)
	if accessGlobal == nil then accessGlobal = true end
	function environment.include(fileIn)
		return sandbox.include(fileIn, environment, accessGlobal, global)
	end

	function environment.CompileFile(fileIn)
		return sandbox.compileFile(fileIn, environment, accessGlobal, global)
	end

	function environment.RunString(fileIn)
		return sandbox.runString(fileIn, environment, accessGlobal, global)
	end

	function environment.CompileString(fileIn, identifier)
		return sandbox.compileString(fileIn, identifier, environment, accessGlobal, global)
	end

	global = global or getfenv(compiled) or getfenv()
	local meta = getmetatable(environment) or {}

	if accessGlobal then
		if not meta.__newindex then
			function meta:__newindex(key, value)
				global[key] = value
			end
		end

		if not meta.__index then
			function meta:__index(key)
				local val = rawget(environment, key)

				if val ~= nil then
					return val
				end

				return global[key]
			end
		end
	end

	setmetatable(environment, meta)
	setfenv(compiled, environment)

	return compiled
end

function sandbox.compileFile(path, ...)
	local compiled = CompileFile(path)

	if not compiled then
		DLib.Message("Couldn't include file '" .. path .. "' (File not found) (<nowhere>)")
		return
	end

	return wrap(compiled, ...)
end

function sandbox.compileString(str, identifier, ...)
	local compiled = CompileString(str, identifier)

	if not compiled or type(compiled) == 'string' then
		return compiled
	end

	return wrap(compiled, ...)
end

function sandbox.runString(str, ...)
	local compiled = CompileString(str, 'RunString')

	if type(compiled) == 'string' then
		return error(compiled)
	end

	return wrap(compiled, ...)()
end

return sandbox
