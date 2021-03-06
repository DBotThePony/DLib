
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


local file = file
local files, dirs = {}, {}
local endfix = '/*'
local searchIn = 'LUA'

local file_Find = file.Find
local table_prependString = table.prependString
local table_append = table.append
local table_filter = table.filter
local table_sort = table.sort

local function findRecursive(dirTarget)
	local findFiles = file_Find(dirTarget .. endfix, searchIn)
	local _, findDirs = file_Find(dirTarget .. '/*', searchIn)

	table_prependString(findFiles, dirTarget .. '/')
	table_prependString(findDirs, dirTarget .. '/')
	table_append(files, findFiles)
	table_append(dirs, findDirs)

	for i, dir in ipairs(findDirs) do
		findRecursive(dir)
	end
end

local function findRecursiveVisible(dirTarget)
	local findFiles, findDirs = file.FindVisible(dirTarget, searchIn)

	for i, dir in ipairs(findDirs) do
		findRecursiveVisible(dirTarget .. '/' .. dir)
	end

	table_prependString(findFiles, dirTarget .. '/')
	table_prependString(findDirs, dirTarget .. '/')
	table_append(files, findFiles)
	table_append(dirs, findDirs)
end

--[[
	@doc
	@fname file.FindVisible
	@args string dirIn, string datapatchIn = 'LUA'

	@returns
	table: found files (bare path)
	table: found dirs (bare path)
]]
function file.FindVisible(dir, searchIn)
	local fileFind, dirFind = file.Find(dir .. '/*', searchIn or 'LUA')
	return table_filter(fileFind, function(key, val) return val[1] ~= '.' end), table_filter(dirFind, function(key, val) return val[1] ~= '.' end)
end

local file_FindVisible = file.FindVisible

--[[
	@doc
	@fname file.FindVisiblePrepend
	@args string dirIn, string datapatchIn = 'LUA'

	@returns
	table: found files (full paths)
	table: found dirs (full paths)
]]
function file.FindVisiblePrepend(dir, searchIn)
	local fileFind, dirFind = file_FindVisible(dir, searchIn)

	table_prependString(fileFind, dir .. '/')
	table_prependString(dirFind, dir .. '/')

	return fileFind, dirFind
end

--[[
	@doc
	@fname file.FindRecursive
	@args string dirIn, string endfixTo = '/*', string datapatchIn = 'LUA'

	@returns
	table: found files (full paths)
	table: found dirs (full paths)
]]
function file.FindRecursive(dir, endfixTo, searchIn2)
	endfixTo = endfixTo or '/*'
	searchIn2 = searchIn2 or 'LUA'
	endfix = endfixTo
	searchIn = searchIn2
	files, dirs = {}, {}

	findRecursive(dir)
	table_sort(files)
	table_sort(dirs)

	return files, dirs
end

--[[
	@doc
	@fname file.FindRecursiveVisible
	@args string dirIn, string datapatchIn = 'LUA'

	@returns
	table: found files (full paths)
	table: found dirs (full paths)
]]
function file.FindRecursiveVisible(dir, searchIn2)
	searchIn2 = searchIn2 or 'LUA'
	searchIn = searchIn2
	files, dirs = {}, {}

	findRecursiveVisible(dir)
	table_sort(files)
	table_sort(dirs)

	return files, dirs
end

return file
