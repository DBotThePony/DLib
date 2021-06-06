
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

writehash = (handle, input) ->
	handle\WriteULong(tonumber(input\sub(1, 8), 16))
	handle\WriteULong(tonumber(input\sub(9, 16), 16))
	handle\WriteULong(tonumber(input\sub(17, 24), 16))
	handle\WriteULong(tonumber(input\sub(25, 32), 16))
	handle\WriteULong(tonumber(input\sub(33, 40), 16))

readhash = (handle) -> string.format('%08x%08x%08x%08x%08x', handle\ReadULong(), handle\ReadULong(), handle\ReadULong(), handle\ReadULong(), handle\ReadULong())

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
		@extension = extension

		if file.Exists(folder .. '/swap.dat', 'DATA')
			fread = file.Open(folder .. '/swap.dat', 'rb', 'DATA')
			@state_hash = {}
			@dirty = false
			overwrites_or_removes = 0

			while fread\Tell() < fread\Size()
				readbyte = fread\ReadByte()
				readop = readbyte ~= 0
				hash = readhash(fread)
				print('readhash', hash)

				if readop
					overwrites_or_removes += 1 if @state_hash[hash]

					@state_hash[hash] = {
						hash: hash
						created: fread\ReadDouble()
						last_access: fread\ReadDouble()
						last_modify: fread\ReadDouble()
						size: fread\ReadULong()
					}
				else
					@state_hash[hash] = nil
					overwrites_or_removes += 1

			@state = [v for k, v in pairs(@state_hash)]

			if overwrites_or_removes > #@state * 4 or overwrites_or_removes > 40000
				@VacuumSwap()

			fread\Close()
		elseif file.Exists(folder .. '/swap.json', 'DATA')
			@state = util.JSONToTable(file.Read(folder .. '/swap.json', 'DATA'))

			if @state
				@dirty = false
				@state_hash = {}
				@state_hash[state.hash] = state for state in *@state

				@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle

				for data in *@state
					with data
						@fhandle\WriteByte(1)
						writehash(@fhandle, .hash)
						@fhandle\WriteDouble(.created)
						@fhandle\WriteDouble(.last_modify)
						@fhandle\WriteDouble(.last_access)
						@fhandle\WriteULong(.size)

				@fhandle\Flush()
			else
				@state = {}
				@state_hash = {}
				@Rescan()

			file.Delete(folder .. '/swap.json')
		else
			@state = {}
			@state_hash = {}
			@Rescan()

	Rescan: =>
		files, folders = file.Find(@folder .. '/*', 'DATA')
		found_hashes = {}
		@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle

		for folder in *folders
			if #folder == 2
				for filename in *file.Find(@folder .. '/' .. folder .. '/*.' .. @extension, 'DATA')
					hash = filename\sub(1, -#@extension - 2)
					found_hashes[hash] = true

					if not @state_hash[hash]
						time = file.Time(@folder .. '/' .. folder .. '/' .. filename, 'DATA')

						data = {
							hash: hash
							created: time
							last_access: time
							last_modify: time
							size: file.Size(@folder .. '/' .. folder .. '/' .. filename, 'DATA')
						}

						table.insert(@state, data)
						@state_hash[hash] = data
						@fhandle\WriteByte(1)
						writehash(@fhandle, hash)
						@fhandle\WriteDouble(time)
						@fhandle\WriteDouble(time)
						@fhandle\WriteDouble(time)
						@fhandle\WriteULong(data.size)

		for i = #@state, 1, -1
			data = @state[i]

			if not found_hashes[data.hash]
				table.remove(@state, i)
				@state_hash[data.hash] = nil

		@fhandle\Flush()
		return @

	SetConVar: (convar = CreateConVar(@folder .. '_size', @limit, {FCVAR_ARCHIVE}, 'Cache size in bytes'), minimal = 0) =>
		@convar = convar
		@minimal = minimal
		return @

	SaveSwap: =>
		@fhandle\Flush() if @fhandle
		@dirty = false
		return @

	SaveSwapIfDirty: =>
		@fhandle\Flush() if @fhandle
		@dirty = false
		return @

	SaveSwapIfDirtyForLong: =>
		@fhandle\Flush() if @fhandle
		@dirty = false
		return @

	VacuumSwap: =>
		@fhandle\Close() if @fhandle
		@fhandle = nil
		fhandle = file.Open(@folder .. '/swap.dat', 'wb', 'DATA')

		for data in *@state
			with data
				fhandle\WriteByte(1)
				writehash(fhandle, .hash)
				fhandle\WriteDouble(.created)
				fhandle\WriteDouble(.last_modify)
				fhandle\WriteDouble(.last_access)
				fhandle\WriteULong(.size)

		fhandle\Close()

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

	AddCommands: (prefix = @folder) =>
		@AddCommandTotalSize(prefix .. '_print_size')
		@AddCommandRescan(prefix .. '_rescan')
		@AddCommandCleanupIfFull(prefix .. '_cleanup')
		@AddCommandRemoveEverything(prefix .. '_clear')

	AddCommandRescan: (name = @folder .. '_rescan') =>
		concommand.Add name, (ply) ->
			return if IsValid(ply) and SERVER
			@Rescan()
			DLib.LMessage('message.dlib.cache_manager.rescanned', @folder)
			DLib.LMessage('message.dlib.cache_manager.total_size', @folder, #@state, DLib.I18n.FormatAnyBytesLong(@TotalSize()))

	AddCommandTotalSize: (name = @folder .. '_print_size') =>
		concommand.Add name, (ply) ->
			return if IsValid(ply) and SERVER
			DLib.LMessage('message.dlib.cache_manager.total_size', @folder, #@state, DLib.I18n.FormatAnyBytesLong(@TotalSize()))

	AddCommandCleanupIfFull: (name = @folder .. '_cleanup') =>
		concommand.Add name, (ply) ->
			return if IsValid(ply) and SERVER

			if not @CleanupIfFull()
				DLib.LMessage('message.dlib.cache_manager.cleanup_not_required', @folder)

	AddCommandRemoveEverything: (name = @folder .. '_clear') =>
		concommand.Add name, (ply) ->
			return if IsValid(ply) and SERVER

			if not @RemoveEverything()
				DLib.LMessage('message.dlib.cache_manager.nothing_to_remove', @folder)

	RemoveEverything: =>
		return false if #@state == 0

		deleted = 0
		deleted_size = 0
		@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle

		for i = #@state, 1, -1
			obj = @state[i]
			@state[i] = nil
			file.Delete(string.format('%s/%s/%s.%s', @folder, obj.hash\sub(1, 2), obj.hash, @extension))
			@state_hash[obj.hash] = nil
			deleted_size += obj.size
			deleted += 1
			@fhandle\WriteByte(0)
			writehash(@fhandle, obj.hash)

		if deleted > 0
			DLib.LMessage('message.dlib.cache_manager.cleanup', @folder, deleted, DLib.I18n.FormatAnyBytesLong(deleted_size))
			@fhandle\Flush()

		return deleted > 0

	CleanupIfFull: =>
		size = @TotalSize()
		limit = @convar and @convar\GetInt()\max(@minimal or 0) or @limit
		return false if size <= limit
		return false if #@state == 0

		table.sort(@state, sorter)

		time = SysTime()
		sessionstart = os.time() - time

		deleted = 0
		deleted_size = 0
		@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle

		while size >= limit and #@state ~= 0
			obj = @state[#@state]
			break if size < limit * 2 and obj.last_access > sessionstart
			@state[#@state] = nil
			@state_hash[obj.hash] = nil
			file.Delete(string.format('%s/%s/%s.%s', @folder, obj.hash\sub(1, 2), obj.hash, @extension))
			size -= obj.size
			deleted_size += obj.size
			deleted += 1
			@fhandle\WriteByte(0)
			writehash(@fhandle, obj.hash)

		if deleted > 0
			DLib.LMessage('message.dlib.cache_manager.cleanup', @folder, deleted, DLib.I18n.FormatAnyBytesLong(deleted_size))
			@fhandle\Flush()

		return deleted > 0

	HasHash: (key) => @state_hash[key] and string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension) or false

	HasGetHash: (key) =>
		if @state_hash[key]
			@state_hash[key].last_access = os.time()
			@dirty = SysTime() if not @dirty
			@SaveSwapIfDirtyForLong()
			return string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension)

		return false

	GetHash: (key, if_none) =>
		return if_none if not @state_hash[key]
		@state_hash[key].last_access = os.time()
		@dirty = SysTime() if not @dirty
		return file.Read(string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension), 'DATA')

	SetHash: (key, value) =>
		file.mkdir(string.format('%s/%s', @folder, key\sub(1, 2)))
		path = string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension)
		file.Write(path, value)

		@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle

		if not @state_hash[key]
			data = {
				hash: key
				created: os.time()
			}

			@state_hash[key] = data
			table.insert(@state, data)

		with @state_hash[key]
			.last_modify = os.time()
			.last_access = os.time()
			.size = #value

			@fhandle\WriteByte(1)
			writehash(@fhandle, .hash)
			@fhandle\WriteDouble(.created)
			@fhandle\WriteDouble(.last_modify)
			@fhandle\WriteDouble(.last_access)
			@fhandle\WriteULong(.size)

		@dirty = SysTime() if not @dirty
		@CleanupIfFull()
		@fhandle\Flush()

		return path
