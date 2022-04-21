
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

readhash = (handle) ->
	a, b, c, d, e = handle\ReadULong(), handle\ReadULong(), handle\ReadULong(), handle\ReadULong(), handle\ReadULong()
	return if not a or not b or not c or not d or not e
	return string.format('%08x%08x%08x%08x%08x', a, b, c, d, e)

OPERATION_REMOVE = 0
OPERATION_ADD = 1
OPERATION_ATIME = 2

coroutine_yield = coroutine.yield
SysTime = SysTime

if DLib.CacheManagerHandles
	for _, {handle} in pairs(DLib.CacheManagerHandles)
		handle\Flush()

	table.Empty(DLib.CacheManagerHandles)
else
	DLib.CacheManagerHandles = {}

hook.AddTask 'Think', 'DLib Cache Manager Flushes', ->
	t = SysTime()

	for key, {handle, time} in pairs(DLib.CacheManagerHandles)
		if time < t
			handle\Flush()
			DLib.CacheManagerHandles[key] = nil

		coroutine_yield()

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
			overwrites_or_removes = 0
			read_error = false
			local read_error_near

			while fread\Tell() < fread\Size()
				readbyte = fread\ReadByte()

				if not readbyte
					read_error = true
					read_error_near = 'cache entry operation'
					break

				readop = readbyte ~= 0
				hash = readhash(fread)

				if not hash
					read_error = true
					read_error_near = 'sha256 hash path'
					break

				if readbyte == OPERATION_ADD
					overwrites_or_removes += 1 if @state_hash[hash]

					created = fread\ReadDouble()
					last_access = fread\ReadDouble()
					last_modify = fread\ReadDouble()
					size = fread\ReadULong()

					if not created
						read_error = true
						read_error_near = 'metadata <creation>'
						break

					if not last_access
						read_error = true
						read_error_near = 'metadata <last_access>'
						break

					if not last_modify
						read_error = true
						read_error_near = 'metadata <last_modify>'
						break

					if not size
						read_error = true
						read_error_near = 'metadata <size>'
						break

					@state_hash[hash] = {
						hash: hash
						:created
						:last_access
						:last_modify
						:size
					}
				elseif readbyte == OPERATION_REMOVE
					@state_hash[hash] = nil
					overwrites_or_removes += 1
				elseif readbyte == OPERATION_ATIME
					@state_hash[hash].last_access = fread\ReadDouble() if @state_hash[hash]

			@state = [v for k, v in pairs(@state_hash)]

			fread\Close()

			if read_error
				DLib.MessageError('data/' .. folder .. '/swap.dat has been tampered with. Read error near ', read_error_near)
				DLib.MessageError('Forcing reconstruction of data/' .. folder .. '/swap.dat')
				file.Delete(folder .. '/swap.dat')
				@Rescan()
				@VacuumSwap()
			elseif overwrites_or_removes > #@state * 4 or overwrites_or_removes > 40000
				@VacuumSwap()
		elseif file.Exists(folder .. '/swap.json', 'DATA')
			@state = util.JSONToTable(file.Read(folder .. '/swap.json', 'DATA'))

			if @state
				@state_hash = {}

				for state in *@state
					if file.Exists(@folder .. '/' .. state.hash\sub(1, 2) .. '/' .. state.hash .. '.' .. @extension, 'DATA')
						@state_hash[state.hash] = state

				@state = [v for k, v in pairs(@state_hash)]

				@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle

				for data in *@state
					with data
						@fhandle\WriteByte(OPERATION_ADD)
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
		DLib.CacheManagerHandles[@folder] = nil
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
						@fhandle\WriteByte(OPERATION_ADD)
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
		return @

	SaveSwapIfDirty: =>
		@fhandle\Flush() if @fhandle
		return @

	SaveSwapIfDirtyForLong: =>
		@fhandle\Flush() if @fhandle
		return @

	VacuumSwap: =>
		@fhandle\Close() if @fhandle
		DLib.CacheManagerHandles[@folder] = nil
		@fhandle = nil
		fhandle = file.Open(@folder .. '/swap.dat', 'wb', 'DATA')

		if not fhandle
			DLib.LMessageError('message.dlib.cache_manager.vaccum_failure', @folder)
			return

		for data in *@state
			with data
				fhandle\WriteByte(OPERATION_ADD)
				writehash(fhandle, .hash)
				fhandle\WriteDouble(.created)
				fhandle\WriteDouble(.last_modify)
				fhandle\WriteDouble(.last_access)
				fhandle\WriteULong(.size)

		fhandle\Close()

		@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA')

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

			if not @CleanupIfFull(true)
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

		for i = #@state, 1, -1
			obj = @state[i]
			@state[i] = nil
			file.Delete(string.format('%s/%s/%s.%s', @folder, obj.hash\sub(1, 2), obj.hash, @extension))
			@state_hash[obj.hash] = nil
			deleted_size += obj.size
			deleted += 1

		if deleted > 0
			DLib.LMessage('message.dlib.cache_manager.cleanup', @folder, deleted, DLib.I18n.FormatAnyBytesLong(deleted_size))

			@fhandle\Close() if @fhandle
			@fhandle = nil
			-- file.Delete does not close open handles
			-- so to truncate the swap file we just open in write mode
			file.Open(@folder .. '/swap.dat', 'wb', 'DATA')\Close()
			@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA')

		return deleted > 0

	CleanupIfFull: (demand = false) =>
		size = @TotalSize()
		limit = @convar and @convar\GetFloat()\max(@minimal or 0) or @limit
		return false if limit <= 0
		return false if size <= limit * (demand and 1 or 1.2)
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
			@fhandle\WriteByte(OPERATION_REMOVE)
			writehash(@fhandle, obj.hash)

		if deleted > 0
			DLib.LMessage('message.dlib.cache_manager.cleanup', @folder, deleted, DLib.I18n.FormatAnyBytesLong(deleted_size))
			@fhandle\Flush()

		return deleted > 0

	HasHash: (key) =>
		get_data = @state_hash[key]
		return false if not get_data

		format_path = string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension)

		if not get_data.checked
			get_data.checked = true

			if not file.Exists(format_path, 'DATA')
				get_data = nil

				for i, data in ipairs(@state)
					if data.hash == key
						table.remove(@state, i)
						break

				@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle
				@fhandle\WriteByte(OPERATION_REMOVE)
				writehash(@fhandle, key)
				return false

		return format_path

	HasGetHash: (key) =>
		if get_data = @state_hash[key]
			format_path = string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension)

			if not get_data.checked
				get_data.checked = true

				if not file.Exists(format_path, 'DATA')
					get_data = nil

					for i, data in ipairs(@state)
						if data.hash == key
							table.remove(@state, i)
							break

					@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle
					@fhandle\WriteByte(OPERATION_REMOVE)
					writehash(@fhandle, key)
					return false

			should_update = get_data.last_access + 10 < os.time()
			get_data.last_access = os.time()

			if should_update
				@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle
				@fhandle\WriteByte(OPERATION_ATIME)
				writehash(@fhandle, key)
				@fhandle\WriteDouble(get_data.last_access)

				if data = DLib.CacheManagerHandles[@folder]
					data[2] = math.min(data[2] + 2, SysTime() + 10)
				else
					DLib.CacheManagerHandles[@folder] = {@fhandle, SysTime() + 2}

			return format_path

		return false

	GetHash: (key, if_none) =>
		get_data = @state_hash[key]
		return if_none if not get_data

		format_path = string.format('%s/%s/%s.%s', @folder, key\sub(1, 2), key, @extension)

		if not get_data.checked
			get_data.checked = true

			if not file.Exists(format_path, 'DATA')
				get_data = nil

				for i, data in ipairs(@state)
					if data.hash == key
						table.remove(@state, i)
						break

				@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle
				@fhandle\WriteByte(OPERATION_REMOVE)
				writehash(@fhandle, key)
				return if_none

		should_update = get_data.last_access + 10 < os.time()
		get_data.last_access = os.time()

		if should_update
			@fhandle = file.Open(@folder .. '/swap.dat', 'ab', 'DATA') if not @fhandle
			@fhandle\WriteByte(OPERATION_ATIME)
			writehash(@fhandle, get_data.hash)
			@fhandle\WriteDouble(get_data.last_access)

			if data = DLib.CacheManagerHandles[@folder]
				data[2] = math.min(data[2] + 2, SysTime() + 10)
			else
				DLib.CacheManagerHandles[@folder] = {@fhandle, SysTime() + 2}

		return file.Read(format_path, 'DATA')

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

			@fhandle\WriteByte(OPERATION_ADD)
			writehash(@fhandle, .hash)
			@fhandle\WriteDouble(.created)
			@fhandle\WriteDouble(.last_modify)
			@fhandle\WriteDouble(.last_access)
			@fhandle\WriteULong(.size)

		if data = DLib.CacheManagerHandles[@folder]
			data[2] = math.min(data[2] + 2, SysTime() + 10)
		else
			DLib.CacheManagerHandles[@folder] = {@fhandle, SysTime() + 2}

		@CleanupIfFull()

		return path
