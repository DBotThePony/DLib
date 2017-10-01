
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
DLib.Loader = Loader

local currentModule, currentModuleEnv

function Loader.include(filIn)
	if not currentModule then
		return include(filIn)
	else
		local currentModule2, currentModuleEnv2 = currentModule, currentModuleEnv
		local compiled = CompileFile(filIn)

		if not compiled then
			DLib.Message("Couldn't include file '" .. filIn .. "' (File not found) (<nowhere>)")
			return
		end

		setfenv(compiled, setmetatable({}, {
			__index = function(self, key)
				if currentModule and key == 'DLib' then print(key, debug.traceback()) end
				if key == currentModule2 then
					return currentModuleEnv2
				end

				if key == 'include' then
					return Loader.include
				end

				return _G[key]
			end,

			__newindex = function(self, key, value)
				if key == currentModule2 then
					return
				end

				_G[key] = value
			end
		}))

		return compiled()
	end
end

function Loader.findShared(inFiles)
	return table.filterNew(inFiles, function(_, value) return value:find('/?sh_') end)
end

function Loader.findClient(inFiles)
	return table.filterNew(inFiles, function(_, value) return value:find('/?cl_') end)
end

function Loader.findServer(inFiles)
	return table.filterNew(inFiles, function(_, value) return value:find('/?sv_') end)
end

function Loader.filterShared(inFiles)
	return table.filter(inFiles, function(_, value) return value:find('/?sh_') end)
end

function Loader.filterClient(inFiles)
	return table.filter(inFiles, function(_, value) return value:find('/?cl_') end)
end

function Loader.filterServer(inFiles)
	return table.filter(inFiles, function(_, value) return value:find('/?sv_') end)
end

function Loader.filter(inFiles)
	return Loader.findShared(inFiles), Loader.findClient(inFiles), Loader.findServer(inFiles)
end

function Loader.shmodule(fil)
	if SERVER then AddCSLuaFile('dlib/modules/' .. fil) end
	return include('dlib/modules/' .. fil)
end

function Loader.clclass(fil)
	if SERVER then
		AddCSLuaFile('dlib/classes/' .. fil)
		return {register = function() end}
	end

	return include('dlib/classes/' .. fil)
end

function Loader.shclass(fil)
	if SERVER then AddCSLuaFile('dlib/classes/' .. fil) end
	return include('dlib/classes/' .. fil)
end

function Loader.svmodule(fil)
	if CLIENT then return end
	return include('dlib/modules/' .. fil)
end

function Loader.start(moduleName, noGlobal)
	currentModuleEnv = DLib[moduleName] or {}

	if DLib[moduleName] then
		local hit = false

		for k, v in pairs(DLib[moduleName]) do
			hit = true
			break
		end

		if not hit then
			DLib[moduleName] = {}
			currentModuleEnv = DLib[moduleName]
		end
	end

	DLib[moduleName] = currentModuleEnv
	currentModule = moduleName

	if not noGlobal then
		_G[moduleName] = currentModuleEnv
	end

	return currentModuleEnv
end

function Loader.finish(allowGlobal, renameHack)
	local created = currentModuleEnv
	local createdModule = currentModule

	if not allowGlobal then
		_G[currentModule] = nil
	end

	currentModule = nil
	currentModuleEnv = nil

	DLib[renameHack or createdModule] = created

	return created
end

include('loader_modes.lua')

if SERVER then
	AddCSLuaFile('loader_modes.lua')
end

return Loader
