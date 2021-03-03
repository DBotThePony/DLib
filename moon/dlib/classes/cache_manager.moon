
-- Copyright (C) 2017-2021 DBotThePony

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

sorter = (a, b) -> a.last_access > b.last_access

class DLib.CacheManager
	new: (folder, limit, extension = 'dat') =>
		assert(isstring(folder), 'isstring(folder)')
		assert(isnumber(limit), 'isnumber(limit)')
		assert(limit > 0, 'limit > 0')
		folder = folder\trim()
		assert(folder ~= '', "folder ~= ''")
		file.mkdir(folder)
		@folder = folder
		@limit = limit

		if file.Exists(folder .. '/swap.json', 'DATA')
			@state = util.JSONToTable(file.Read(folder .. '/swap.json', 'DATA'))
			@dirty = false
		else
			@state = {}

			files, folders = file.Find(folder .. '/*', 'DATA')

			for folder in *folders
				if #folder == 2
					for filename in *file.Find(@folder .. '/' .. folder .. '/*.' .. extension, 'DATA')
						time = file.Time(@folder .. '/' .. folder .. '/' .. filename, 'DATA')

						table.insert(@state, {
							hash: filename\sub(1, -#extension - 2)
							created: time
							last_access: time
							last_modify: time
							size: file.Size(@folder .. '/' .. folder .. '/' .. filename, 'DATA')
						})

			@dirty = true

		@state_hash = {}

		for state in *@state
			@state_hash[state.hash] = state

		@extension = extension

	SetConVar: (convar, minimal = 0) =>
		@convar = convar
		@minimal = minimal

	SaveSwap: =>
		file.Write(@folder .. '/swap.json', util.TableToJSON(@state, true))
		@dirty = false

	SaveSwapIfDirty: =>
		return false if not @dirty
		@SaveSwap()
		return true

	SetExtension: (extension) => @extension = assert(isstring(extension) and extension, 'isstring(extension)')
	GetExtension: => @extension

	Has: (key) => @HasHash(DLib.Util.QuickSHA1(key))
	HasGet: (key) => @HasGetHash(DLib.Util.QuickSHA1(key))
	Get: (key, if_none) => @GetHash(DLib.Util.QuickSHA1(key), if_none)
	Set: (key, value) => @SetHash(DLib.Util.QuickSHA1(key), value)

	TotalSize: =>
		calculate = 0

		for state in *@state
			calculate += state.size

		return calculate

	CleanupIfFull: =>
		size = @TotalSize()
		limit = @convar and @convar\GetInt()\max(@minimal) or @limit
		return false if size <= limit
		return false if #@state == 0

		table.sort(@state, sorter)

		time = SysTime()
		sessionstart = os.time() - time

		while size >= limit and #@state ~= 0
			obj = table.remove(@state)
			break if size < limit * 2 and obj.last_access < sessionstart
			@state_hash[obj.hash] = nil
			file.Delete(string.format('%s/%s/%s.%s', @folder, obj.hash\sub(1, 2), obj.hash, @extension))
			size -= obj.size

		@SaveSwap()
		return true

	HasHash: (key) => @state_hash[key] ~= nil
	HasGetHash: (key) =>
		if @state_hash[key]
			@state_hash[key].last_access = os.time()
			@dirty = true
			return true

		return false

	GetHash: (key, if_none) =>
		return if_none if not @state_hash[key]
		@state_hash[key].last_access = os.time()
		@dirty = true
		return file.Read(string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension), 'DATA')

	SetHash: (key, value) =>
		file.Write(string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension), value)

		if not @state_hash[key]
			@state_hash[key] = {
				hash: key
				created: os.time()
			}

		with @state_hash[key]
			.last_modify = os.time()
			.last_access = os.time()
			.size = #value

		@dirty = true
