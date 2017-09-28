
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

local Loader = DLib.Loader
local include = DLib.Loader.include

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

function Loader.loadTop(targetDir)
	local output = {}
	local files = file.Find(targetDir .. '/*', 'LUA')

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

function Loader.loadPureSV(targetDir)
	if CLIENT then return end
	local output = {}
	local files = file.FindRecursive(targetDir)

	for i, fil in ipairs(files) do
		table.insert(output, {fil, include(fil)})
	end

	return output
end

function Loader.loadPureSH(targetDir)
	local output = {}
	local files = file.FindRecursive(targetDir)

	if SERVER then
		for i, fil in ipairs(files) do
			AddCSLuaFile(fil)
			table.insert(output, {fil, include(fil)})
		end
	else
		for i, fil in ipairs(files) do
			table.insert(output, {fil, include(fil)})
		end
	end

	return output
end

function Loader.loadPureCSTop(targetDir)
	local output = {}
	local files = file.Find(targetDir .. '/*', 'LUA')

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

function Loader.loadPureSVTop(targetDir)
	if CLIENT then return end
	local output = {}
	local files = file.Find(targetDir, 'LUA')

	for i, fil in ipairs(files) do
		table.insert(output, {fil, include(fil)})
	end

	return output
end

function Loader.loadPureSHTop(targetDir)
	local output = {}
	local files = file.Find(targetDir .. '/*', 'LUA')

	if SERVER then
		for i, fil in ipairs(files) do
			AddCSLuaFile(fil)
			table.insert(output, {fil, include(fil)})
		end
	else
		for i, fil in ipairs(files) do
			table.insert(output, {fil, include(fil)})
		end
	end

	return output
end

function Loader.csModule(targetDir)
	if CLIENT then return {} end
	local output = {}
	local files = file.FindRecursive(targetDir)

	for i, fil in ipairs(files) do
		AddCSLuaFile(fil)
	end

	return output
end

return Loader
