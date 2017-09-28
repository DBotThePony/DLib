
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

local fsutil = DLib.module('fs')

local files, dirs = {}, {}
local endfix = '/*'
local searchIn = 'LUA'

local function findRecursive(dirTarget)
	local findFiles = file.Find(dirTarget .. endfix, searchIn)
	local _, findDirs = file.Find(dirTarget .. '/*', searchIn)
	table.prependString(findFiles, dirTarget .. '/')
	table.prependString(findDirs, dirTarget .. '/')
	table.append(files, findFiles)
	table.append(dirs, findDirs)

	for i, dir in ipairs(findDirs) do
		findRecursive(dirTarget .. '/' .. dir)
	end
end

local function findRecursiveVisible(dirTarget)
	local findFiles = file.FindVisible(dirTarget .. endfix, searchIn)
	local _, findDirs = file.FindVisible(dirTarget .. '/*', searchIn)
	table.prependString(findFiles, dirTarget .. '/')
	table.prependString(findDirs, dirTarget .. '/')
	table.append(files, findFiles)
	table.append(dirs, findDirs)

	for i, dir in ipairs(findDirs) do
		findRecursive(dirTarget .. '/' .. dir)
	end
end

function fsutil.FindVisible(dir, searchIn)
	local fileFind, dirFind = file.Find(dir, searchIn)
	table.filter(fileFind, function(key, val) return val:sub(1, 1) ~= '.' end)
	table.filter(dirFind, function(key, val) return val:sub(1, 1) ~= '.' end)
	return fileFind, dirFind
end

function fsutil.FindRecursive(dir, endfixTo, searchIn2)
	endfixTo = endfixTo or '/*'
	searchIn2 = searchIn2 or 'LUA'
	endfix = endfixTo
	searchIn = searchIn2
	files, dirs = {}, {}

	findRecursive(dir)
	table.sort(files)
	table.sort(dirs)

	return files, dirs
end

function fsutil.FindRecursiveVisible(dir, endfixTo, searchIn2)
	endfixTo = endfixTo or '/*'
	searchIn2 = searchIn2 or 'LUA'
	endfix = endfixTo
	searchIn = searchIn2
	files, dirs = {}, {}

	findRecursiveVisible(dir)
	table.sort(files)
	table.sort(dirs)

	return files, dirs
end

return fsutil
