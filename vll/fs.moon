
-- Copyright (C) 2018 DBot

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

import string, table, VLL2 from _G

type = luatype or type

class VLL2.FSDirectory
	new: (name, parent) =>
		@name = name\lower()
		@parent = parent
		@subdirs = {}
		@files = {}

	Open: (directory, lowered) =>
		return @ if directory == '' or directory == '/' or directory\Trim() == ''
		directory = directory\lower() if not lowered

		if startpos = string.find(directory, '/', 1, true)
			namedir = string.sub(directory, 1, startpos - 1)
			nextdir = string.sub(directory, startpos + 1)
			return @subdirs[namedir]\Open(nextdir) if @subdirs[namedir]
			dir = VLL2.FSDirectory(namedir, @)
			@subdirs[namedir] = dir
			return dir\Open(nextdir, true)
		else
			return @subdirs[directory] if @subdirs[directory]
			dir = VLL2.FSDirectory(directory, @)
			@subdirs[directory] = dir
			return dir

	OpenRaw: (directory, lowered) =>
		return @ if directory == '' or directory == '/' or directory\Trim() == ''
		directory = directory\lower() if not lowered

		if startpos = string.find(directory, '/', 1, true)
			namedir = string.sub(directory, 1, startpos - 1)
			nextdir = string.sub(directory, startpos + 1)
			return @subdirs[namedir]\OpenRaw(nextdir, true) if @subdirs[namedir]
			return false
		else
			return @subdirs[directory] if @subdirs[directory]
			return false

	GetName: => @name

	Write: (name, contents) =>
		assert(type(name) == 'string', 'Invalid path type - ' .. type(name))
		assert(not string.find(name, '/', 1, true), 'Name should not contain slashes (/)')
		@files[name\lower()] = contents
		return @

	Read: (name) =>
		assert(type(name) == 'string', 'Invalid path type - ' .. type(name))
		assert(not string.find(name, '/', 1, true), 'Name should not contain slashes (/)')
		return @files[name\lower()]

	Exists: (name) =>
		assert(type(name) == 'string', 'Invalid path type - ' .. type(name))
		assert(not string.find(name, '/', 1, true), 'Name should not contain slashes (/)')
		return @files[name\lower()] ~= nil

	ConstructFullPath: =>
		return @name .. '/' if not @parent
		return @parent\ConstructFullPath() .. @name .. '/'

	ListFiles: =>
		arr = [fil for fil in pairs(@files)]
		table.sort(arr)
		return arr

	ListDirs: =>
		arr = [fil\GetName() for _, fil in pairs(@subdirs)]
		table.sort(arr)
		return arr

	List: =>
		arr = @ListFiles()
		table.insert(fil) for fil in ipairs(@ListDirs())
		table.sort(arr)
		return arr

splice = (arrIn, fromPos = 1, deleteCount = 2) ->
	copy = {}
	table.insert(copy, arrIn[i]) for i = 1, fromPos - 1
	table.insert(copy, arrIn[i]) for i = fromPos + deleteCount, #arrIn
	arrIn[i] = val for i, val in ipairs(copy)
	arrIn[i] = nil for i = #copy + 1, #arrIn
	return arrIn

class VLL2.FileSystem
	@StripFileName = (fname) ->
		explode = string.Explode('/', fname)
		filename = explode[#explode]
		explode[#explode] = nil
		return table.concat(explode, '/'), filename

	@ToPattern = (fexp) -> fexp\gsub('%.', '%%.')\gsub('%*', '.*')

	@Canonize = (fpath) ->
		return fpath if not string.find(fpath, '..', 1, true) and not string.find(fpath, '/./', 1, true)
		starts = string.find(fpath, '..', 1, true)
		return if starts == 1
		split = [str for str in string.gmatch(fpath, '/')]
		i = 0
		while true
			i += 1
			value = split[i]
			break if not value

			if value == '..'
				if i == 1
					return
				else
					splice(split, i - 1, 2)
					i -= 2
			elseif value == '.'
				splice(split, i - 1, 1)
				i -= 1

		return table.concat(split, '/')

	new: =>
		@root = VLL2.FSDirectory('')

	Write: (path, contents) =>
		assert(type(path) == 'string', 'Invalid path to write - ' .. type(path))
		assert(type(contents) == 'string', 'Contents must be a string - ' .. type(contents))
		assert(not string.find(path, '..', 1, true), 'Path must be absolute')
		dname, fname = VLL2.FileSystem.StripFileName(path\lower())
		dir = @root\Open(dname, true)
		dir\Write(fname, contents)
		return @

	Read: (path) =>
		assert(type(path) == 'string', 'Invalid path to write - ' .. type(path))
		assert(not string.find(path, '..', 1, true), 'Path must be absolute')
		dname, fname = VLL2.FileSystem.StripFileName(path\lower())
		dir = @root\Open(dname, true)
		return dir\Read(fname)

	Exists: (path) =>
		assert(type(path) == 'string', 'Invalid path to write - ' .. type(path))
		assert(not string.find(path, '..', 1, true), 'Path must be absolute')
		dname, fname = VLL2.FileSystem.StripFileName(path\lower())
		return @root\Open(dname, true)\Exists(fname)

	Find: (pattern) =>
		assert(type(pattern) == 'string', 'Invalid pattern type provided: ' .. type(pattern))
		assert(not string.find(pattern, '..', 1, true), 'Path must be absolute')
		dname, fname = VLL2.FileSystem.StripFileName(pattern\lower())
		dir = @root\Open(dname, true)
		return dir\ListFiles(), dir\ListDirs() if fname == '*'
		fpattern = VLL2.FileSystem.ToPattern(fname)
		result = [fil for fil in *dir\ListFiles() when string.find(fil, fpattern)]
		return result, dir\ListDirs()

VLL2.FileSystem.INSTANCE = VLL2.FileSystem()
