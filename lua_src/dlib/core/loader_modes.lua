
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

local Loader = DLib.Loader

local function include2(fileIn)
	local status = {xpcall(Loader.include, function(err) print(debug.traceback('[DLIB STARTUP ERROR] ' .. err)) end, fileIn)}
	local bool = table.remove(status, 1)

	if bool then
		return unpack(status)
	end
end

function Loader.load(targetDir)
	local output = {}
	local files = DLib.fs.FindRecursiveVisible(targetDir)

	local sh, cl, sv = Loader.filter(files)

	if SERVER then
		for i, fil in ipairs(sh) do
			AddCSLuaFile(fil)
			table.insert(output, {fil, include2(fil)})
		end

		for i, fil in ipairs(cl) do
			AddCSLuaFile(fil)
		end

		for i, fil in ipairs(sv) do
			table.insert(output, {fil, include2(fil)})
		end
	else
		for i, fil in ipairs(sh) do
			table.insert(output, {fil, include2(fil)})
		end

		for i, fil in ipairs(cl) do
			table.insert(output, {fil, include2(fil)})
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
			table.insert(output, {fil, include2(fil)})
		end

		for i, fil in ipairs(cl) do
			AddCSLuaFile(fil)
		end

		for i, fil in ipairs(sv) do
			table.insert(output, {fil, include2(fil)})
		end
	else
		for i, fil in ipairs(sh) do
			table.insert(output, {fil, include2(fil)})
		end

		for i, fil in ipairs(cl) do
			table.insert(output, {fil, include2(fil)})
		end
	end

	return output
end

function Loader.loadCS(targetDir)
	local output = {}
	local files = DLib.fs.FindRecursiveVisible(targetDir)

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
			table.insert(output, {fil, include2(fil)})
		end

		for i, fil in ipairs(cl) do
			table.insert(output, {fil, include2(fil)})
		end
	end

	return output
end

function Loader.loadPureCS(targetDir)
	local output = {}
	local files = DLib.fs.FindRecursiveVisible(targetDir)

	if SERVER then
		for i, fil in ipairs(files) do
			AddCSLuaFile(fil)
		end
	else
		for i, fil in ipairs(files) do
			table.insert(output, {fil, include2(fil)})
		end
	end

	return output
end

function Loader.loadPureSV(targetDir)
	if CLIENT then return end
	local output = {}
	local files = DLib.fs.FindRecursiveVisible(targetDir)

	for i, fil in ipairs(files) do
		table.insert(output, {fil, include2(fil)})
	end

	return output
end

function Loader.loadPureSH(targetDir)
	local output = {}
	local files = DLib.fs.FindRecursiveVisible(targetDir)

	if SERVER then
		for i, fil in ipairs(files) do
			AddCSLuaFile(fil)
			table.insert(output, {fil, include2(fil)})
		end
	else
		for i, fil in ipairs(files) do
			table.insert(output, {fil, include2(fil)})
		end
	end

	return output
end

function Loader.loadPureCSTop(targetDir)
	local output = {}
	local files = DLib.fs.FindVisiblePrepend(targetDir, 'LUA')

	if SERVER then
		for i, fil in ipairs(files) do
			AddCSLuaFile(fil)
		end
	else
		for i, fil in ipairs(files) do
			table.insert(output, {fil, include2(fil)})
		end
	end

	return output
end

Loader.loadPureCLTop = Loader.loadPureCSTop

function Loader.loadPureSVTop(targetDir)
	if CLIENT then return end
	local output = {}
	local files = DLib.fs.FindVisiblePrepend(targetDir, 'LUA')

	for i, fil in ipairs(files) do
		table.insert(output, {fil, include2(fil)})
	end

	return output
end

function Loader.loadPureSHTop(targetDir)
	local output = {}
	local files = DLib.fs.FindVisiblePrepend(targetDir, 'LUA')

	if SERVER then
		for i, fil in ipairs(files) do
			AddCSLuaFile(fil)
			table.insert(output, {fil, include2(fil)})
		end
	else
		for i, fil in ipairs(files) do
			table.insert(output, {fil, include2(fil)})
		end
	end

	return output
end

function Loader.csModule(targetDir)
	if CLIENT then return {} end

	local output = {}
	local files = DLib.fs.FindRecursiveVisible(targetDir)

	if #files == 0 then error('Empty module ' .. targetDir) end

	for i, fil in ipairs(files) do
		AddCSLuaFile(fil)
	end

	return output
end

return Loader
