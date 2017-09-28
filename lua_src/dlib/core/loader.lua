
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local Loader = DLib.module('Loader')

local include_ = include
local currentModule, currentModuleEnv

local include
function include(filIn)
	if not currentModule then
		return include_(filIn)
	else
		local currentModule, currentModuleEnv = currentModule, currentModuleEnv
		local compiled = CompileFile(filIn)

		if not compiled then
			DLib.Message("Couldn't include file '" .. filIn .. "' (File not found) (<nowhere>)")
			return
		end

		local getFEnv = getfenv(compiled) or _G

		setfenv(compiled, setmetatable({}, {
			__index = function(self, key)
				if key == currentModule then
					return currentModuleEnv
				end

				if key == 'include' then
					return include
				end

				return getFEnv[key]
			end,

			__newindex = getFEnv
		}))

		return compiled()
	end
end

Loader.include = include

function Loader.findShared(inFiles)
	return table.filterNew(inFiles, function(_, value) return value:sub(1, 3) == 'sh_' end)
end

function Loader.findClient(inFiles)
	return table.filterNew(inFiles, function(_, value) return value:sub(1, 3) == 'cl_' end)
end

function Loader.findServer(inFiles)
	return table.filterNew(inFiles, function(_, value) return value:sub(1, 3) == 'sv_' end)
end

function Loader.filterShared(inFiles)
	return table.filter(inFiles, function(_, value) return value:sub(1, 3) == 'sh_' end)
end

function Loader.filterClient(inFiles)
	return table.filter(inFiles, function(_, value) return value:sub(1, 3) == 'cl_' end)
end

function Loader.filterServer(inFiles)
	return table.filter(inFiles, function(_, value) return value:sub(1, 3) == 'sv_' end)
end

function Loader.filter(inFiles)
	return Loader.filterShared(inFiles), Loader.filterClient(inFiles), Loader.filterServer(inFiles)
end

function Loader.shmodule(fil)
	if SERVER then AddCSLuaFile('dlib/modules/' .. fil) end
	return include('dlib/modules/' .. fil)
end

function Loader.svmodule(fil)
	if CLIENT then return end
	return include('dlib/modules/' .. fil)
end

function Loader.start(moduleName)
	currentModuleEnv = DLib[moduleName] or {}
	currentModule = moduleName
	_G[moduleName] = currentModuleEnv
	return currentModuleEnv
end

function Loader.finish(allowGlobal)
	DLib[currentModule] = currentModuleEnv
	local created = currentModuleEnv

	if not allowGlobal then
		_G[currentModule] = nil
	end

	currentModule = nil
	currentModuleEnv = nil

	return created
end

include_('loader_modes.lua')

if SERVER then
	AddCSLuaFile('loader_modes.lua')
end

return Loader
