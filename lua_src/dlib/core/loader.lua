
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

function Loader.load(targetDir)
	local output = {}
	local files = file.FindRecursive(targetDir)

	local sh, cl, sv = Loader.filter(files)

	if SERVER then
		for i, fil in ipairs(sh) do
			AddCSLuaFile(fil)
			table.insert(output, {fil, include(fil)})
		end

		for i, fil in ipairs(cl) do
			AddCSLuaFile(fil)
		end

		for i, fil in ipairs(sv) do
			table.insert(output, {fil, include(fil)})
		end
	else
		for i, fil in ipairs(sh) do
			table.insert(output, {fil, include(fil)})
		end

		for i, fil in ipairs(cl) do
			table.insert(output, {fil, include(fil)})
		end
	end

	return output
end

function Loader.loadCS(targetDir)
	local output = {}
	local files = file.FindRecursive(targetDir)

	local sh, cl = Loader.filter(files)

	if SERVER then
		for i, fil in ipairs(sh) do
			AddCSLuaFile(fil)
		end

		for i, fil in ipairs(cl) do
			AddCSLuaFile(fil)
		end
	else
		for i, fil in ipairs(sh) do
			table.insert(output, {fil, include(fil)})
		end

		for i, fil in ipairs(cl) do
			table.insert(output, {fil, include(fil)})
		end
	end

	return output
end

function Loader.loadPureCS(targetDir)
	local output = {}
	local files = file.FindRecursive(targetDir)

	if SERVER then
		for i, fil in ipairs(files) do
			AddCSLuaFile(fil)
		end
	else
		for i, fil in ipairs(files) do
			table.insert(output, {fil, include(fil)})
		end
	end

	return output
end

function Loader.shmodule(fil)
	if SERVER then AddCSLuaFile('dlib/modules/' .. fil) end
	return include('dlib/modules/' .. fil)
end

return Loader
