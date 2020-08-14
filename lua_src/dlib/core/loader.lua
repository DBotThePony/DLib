
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

DLib.Loader = DLib.Loader or {}
local Loader = DLib.Loader

local currentModule, currentModuleEnv
local fenv2 = debug.getinfo(1) and getfenv(1) or _G

function Loader.include(filIn)
	if not currentModule then
		return include(filIn)
	else
		local currentModule2, currentModuleEnv2 = currentModule, currentModuleEnv
		local compiled = CompileFile(filIn)

		if not compiled then
			DLib.MessageError("Couldn't include file '" .. filIn .. "'. Look for errors above!")
			ErrorNoHalt(debug.traceback("Couldn't include file '" .. filIn .. "'. Look for errors above!"))
			return
		end

		setfenv(compiled, setmetatable({}, {
			__index = function(self, key)
				if key == currentModule2 then
					return currentModuleEnv2
				end

				if key == 'include' then
					return Loader.include
				end

				return fenv2[key]
			end,

			__newindex = function(self, key, value)
				if key == currentModule2 then
					return
				end

				fenv2[key] = value
			end
		}))

		return compiled()
	end
end

Loader.Include = Loader.include

function DLib.SharedInclude(fil)
	if SERVER then AddCSLuaFile('dlib/' .. fil) end

	return Loader.Include('dlib/' .. fil)
end

function DLib.ClientInclude(fil)
	if SERVER then
		AddCSLuaFile('dlib/' .. fil)
		return
	end

	return Loader.Include('dlib/' .. fil)
end

function DLib.ServerInclude(fil)
	if CLIENT then return end

	return Loader.Include('dlib/' .. fil)
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

local loaderIsGlobal = false

function Loader.start(moduleName, noGlobal)
	currentModuleEnv = DLib[moduleName] or {}
	loaderIsGlobal = not noGlobal

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

	if not allowGlobal and loaderIsGlobal then
		_G[currentModule] = nil
	end

	currentModule = nil
	currentModuleEnv = nil

	DLib[renameHack or createdModule] = created

	return created
end

Loader.Start = Loader.start
Loader.Finish = Loader.finish
