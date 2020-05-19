
-- Copyright (C) 2018-2020 DBotThePony

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

import file, util, error, assert, HTTP, Entity, game, VLL2 from _G

class VLL2.GitCache
	new: (name) =>
		@name = name
		@storage = {}
		@read = false
		@modified = false

	Release: =>
		@storage = {}
		@read = false

	GetPath: => 'vll2/git_luapacks/' .. @name .. '.dat'

	@TERMINATION = string.rep(string.char(0xFF), 20)

	ReadCacheIfExists: =>
		@exists = file.Exists(@GetPath(), 'DATA') if @exists == nil
		return false if not @exists
		@ReadCache()
		return true

	ReadCache: (stream) =>
		open = false

		if stream == nil
			stream = file.Open(@GetPath(), 'rb', 'DATA')
			open = true

		readHash = stream\Read(20)

		while readHash ~= @@TERMINATION
			long = stream\ReadULong()

			if long < 0xfffff
				@storage[@BytesToHash(readHash)] = stream\Read(long)
			else
				VLL2.Message('Insane content length: ' .. long .. ' (' .. string.NiceSize(long) .. ') !')
				break

			readHash = stream\Read(20)

		@read = true
		stream\Close() if open

	HashToBytes: (hash) => table.concat([string.char(tonumber(char, 16)) for char in string.gmatch(hash, '..')], '')
	BytesToHash: (bytes) => table.concat([string.format('%.2x', string.byte(char)) for char in string.gmatch(bytes, '.')], '')

	WriteIfModified: =>
		@exists = file.Exists(@GetPath(), 'DATA') if @exists == nil
		return false if not @modified and @read
		return false if not @read and @exists
		@WriteCache()
		return true

	WriteCache: (stream) =>
		open = false

		if stream == nil
			stream = file.Open(@GetPath(), 'wb', 'DATA')
			open = true

		for hash, content in pairs(@storage)
			stream\Write(@HashToBytes(hash))
			stream\WriteULong(#content)
			stream\Write(content)

		stream\Write(@@TERMINATION)
		stream\Flush()
		stream\Close() if open
		@exists = true
		@modified = false

	Has: (hash) =>
		@ReadCacheIfExists() if not @read and (@exists or @exists == nil)
		return @storage[hash] ~= nil

	Get: (hash) =>
		@ReadCacheIfExists() if not @read and (@exists or @exists == nil)
		return @storage[hash]

	Set: (hash, contents) =>
		@ReadCacheIfExists() if not @read and (@exists or @exists == nil)
		@storage[hash] = contents
		@modified = true

class VLL2.GitHubBundle extends VLL2.URLBundle
	@LISTING = {}

	@API_BASE = 'https://api.github.com/repos/'
	@FILE_BASE = 'https://raw.githubusercontent.com/'

	@GetMessage = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsLoading()
		return if downloading == 0
		return 'VLL2 Is downloading ' .. downloading .. ' GitHub bundles'

	if CLIENT
		net.Receive 'vll2.replicate_github', ->
			author = net.ReadString()
			repository = net.ReadString()
			subdir = net.ReadString()
			branch = net.ReadString()
			return if not @Checkup('github:' .. author .. '/' .. repository)
			VLL2.MessageBundle('Server requires GitHub bundle to be loaded from ' .. author .. ' git repo ' .. repository .. ' at branch ' .. (branch or 'master') .. (subdir ~= '' and ' with ' or ' without ') .. 'subdirectory check')
			VLL2.GitHubBundle(author, repository, branch, subdir)\Load()

	new: (author, repository, branch = 'master', subdir = '') =>
		assert(isstring(author), 'Author is not a string')
		assert(isstring(repository), 'Repository name is not a string')
		assert(isstring(branch), 'Branch name is not a string')
		assert(isstring(subdir), 'Sub directory is not a string')

		assert(not author\find('.', 1, true) and not author\find('/', 1, true) and not author\find('\\', 1, true), 'Bad author name')
		assert(not repository\find('.', 1, true) and not repository\find('/', 1, true) and not repository\find('\\', 1, true), 'Bad repository name')
		assert(not branch\find('.', 1, true), 'Bad branch name')

		subdir = subdir\sub(2) if subdir[1] == '/'
		subdir = subdir\sub(1, #subdir - 1) if subdir[#subdir] == '/'

		-- super('github:' .. author .. '/' .. repository .. '%' .. branch)
		super('github:' .. author .. '/' .. repository)
		@author = author
		@repository = repository
		@subdir = subdir
		@branch = branch

		@mountAfterLoad = true
		@loadLua = true

		@cache = VLL2.GitCache('github_' .. author .. '_' .. repository)

	Replicate: (ply = player.GetAll()) =>
		return if CLIENT
		return if istable(ply) and #ply == 0
		net.Start('vll2.replicate_github')
		net.WriteString(@author)
		net.WriteString(@repository)
		net.WriteString(@subdir)
		net.WriteString(@branch)
		net.Send(ply)

	WriteToCache: (fpath, sha, body) => @cache\Set(sha, body)
	SaveCache: =>
		@cache\WriteIfModified()
		@cache\Release()

	LoadFromList: (list = @file_index) =>
		@toDownload = #list
		@downloaded = 0

		for {path, url, sha} in *list
			fromCache = @cache\Get(sha)

			if fromCache
				@fs\Write(path, fromCache)
				@globalFS\Write(path, fromCache)
				@downloaded += 1
			else
				@DownloadFile(path, url, sha)

		@Msg(@downloaded .. ' files are present in cache and are fresh')
		@CheckIfRunnable()

	Load: =>
		@status = @@STATUS_LOADING

		req = {
			method: 'GET'
			url: @@API_BASE .. @author .. '/' .. @repository .. '/git/trees/' .. @branch .. '?recursive=1'
			headers: {
				'User-Agent': 'VLL2'
				Referer: VLL2.Referer()
			}
		}

		req.failed = (reason = 'failed') ->
			@cDownloading -= 1
			@__DownloadCallback()
			@status = @@STATUS_ERROR
			@Msg('download of ' .. fpath .. ' failed, reason: ' .. reason)
			@Msg('URL: ' .. url)
			@SaveCache()
			@CallError()

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@Msg('download of index file failed, server returned: ' .. code)
				@status = @@STATUS_ERROR
				@CallError()
				return

			json = util.JSONToTable(body)

			if not json or not json.tree
				@Msg('bad file index')
				@status = @@STATUS_ERROR
				@CallError()
				return

			@file_index = {}

			for {:path, :mode, :type, :sha, :size, :url} in *json.tree
				if string.StartWith(path, @subdir)
					path = path\sub(#@subdir + 1)
					path = path\sub(2) if path[1] == '/'

					if string.StartWith(path, 'lua/') and type == 'blob'
						_url = @@FILE_BASE .. @author .. '/' .. @repository .. '/' .. @branch .. '/' .. path
						path = path\sub(5)
						table.insert(@file_index, {path, _url, sha})

			@Msg('Received index file, total ' .. #@file_index .. ' files to load')
			@LoadFromList()

		HTTP(req)

		return @
