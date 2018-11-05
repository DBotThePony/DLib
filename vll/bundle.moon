
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

import file, util, error, assert, HTTP from _G

if SERVER
	util.AddNetworkString('vll2.replicate_url')
	util.AddNetworkString('vll2.replicate_workshop')
	util.AddNetworkString('vll2.replicate_all')

file.CreateDir('vll2')
file.CreateDir('vll2/lua_cache')

class VLL2.AbstractBundle
	@_S = {}
	@STATUS_NONE = 0
	@STATUS_LOADING = 1
	@STATUS_LOADED = 2
	@STATUS_RUNNING = 3
	@STATUS_ERROR = 4

	@DISK_CACHE = {fil\gsub('%.dat', ''), file.Time('vll2/lua_cache/' .. fil, 'DATA') for _, fil in *file.Find('vll2/lua_cache/*', 'DATA')}
	@DISK_CACHE_READ = {}

	@Checkup = (bname) =>
		return true if not @_S[bname]
		return not @_S[bname]\IsLoading()

	@__FromCache = (hash) =>
		return @DISK_CACHE_READ[hash] if @DISK_CACHE_READ[hash]
		@DISK_CACHE_READ[hash] = file.Read('vll2/lua_cache/' .. hash .. '.dat', 'DATA')
		decompress = util.Decompress(@DISK_CACHE_READ[hash])

		if decompress == ''
			@DISK_CACHE_READ[hash] = nil
			@DISK_CACHE[hash] = nil
			file.Delete('vll2/lua_cache/' .. hash .. '.dat')
			return nil
		else
			@DISK_CACHE_READ[hash] = decompress
			return decompress

	@FromCache = (fname, fstamp) =>
		hash = util.CRC(fname)
		return if not @DISK_CACHE[hash]

		if fstamp
			if @DISK_CACHE[hash] >= fstamp
				return @__FromCache(fname)
			else
				@DISK_CACHE_READ[hash] = nil
				@DISK_CACHE[hash] = nil
				file.Delete('vll2/lua_cache/' .. hash .. '.dat')
				return
		else
			return @__FromCache(fname)

	new: (name) =>
		@name = name
		@@_S[name] = @
		@status = @@STATUS_NONE
		@fs = VLL2.FileSystem()
		@initAfterLoad = true
		@replicated = true

	Msg: (...) => VLL2.MessageBundle(@name .. ': ', ...)

	IsLoading: => @status == @@STATUS_LOADING
	IsLoaded: => @status == @@STATUS_LOADED
	IsRunning: => @status == @@STATUS_RUNNING
	IsErrored: => @status == @@STATUS_ERROR
	IsIdle: => @status == @@STATUS_NONE
	IsReplicated: => @replicated

	Replicate: (ply = player.GetAll()) =>
		return if CLIENT
		error('Not implemented')

	Run: =>
		vm = VLL2.VM(@name, @fs, VLL2.FileSystem.INSTANCE)
		vm\LoadAutorun()
		vm\LoadEntities()
		vm\LoadWeapons()
		vm\LoadTFA()
		@Msg('Bundle successfully initialized!')

	Load: => error('Not implemented')

class VLL2.URLBundle extends VLL2.AbstractBundle
	@FETH_BUNDLE_URL = 'https://dbotthepony.ru/vll/package.php'

	if CLIENT
		net.Receive 'vll2.replicate_url', ->
			graburl = net.ReadString()
			return if not @Checkup(graburl)
			VLL2.MessageBundle('Server requires URL bundle to be loaded: ' .. graburl)
			VLL2.URLBundle(graburl)\Load()

	new: (name) =>
		super(name)
		@toDownload = -1
		@downloaded = -1

	Replicate: (ply = player.GetAll()) =>
		return if CLIENT
		return if player.GetHumans() == 0
		net.Start('vll2.replicate_url')
		net.WriteString(@name)
		net.Send(ply)

	CheckIfRunnable: =>
		return if @toDownload == -1
		return if @toDownload > @downloaded
		@status = @@STATUS_LOADED
		@Msg('Bundle got downloaded')
		return if not @initAfterLoad
		@Run()

	DownloadFile: (fpath, url) =>
		assert(fpath)
		assert(url)

		req = {
			method: 'GET'
			url: url
			headers: {
				'User-Agent': 'VLL2'
				Referer: VLL2.Referer()
			}
		}

		req.failed = (reason = 'failed') ->
			@status = @@STATUS_ERROR
			@Msg('download of ' .. fpath .. ' failed, reason: ' .. reason)
			@Msg('URL: ' .. url)

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@Msg('download of ' .. fpath .. ' failed, server returned: ' .. code)
				@Msg('URL: ' .. url)
				@status = @@STATUS_ERROR
				return

			@downloaded += 1
			@fs\Write(fpath, body)
			@CheckIfRunnable()

		HTTP(req)

	LoadFromList: (bundle = @bundleList) =>
		@toDownload = #@bundleList
		@downloaded = 0

		for line in *@bundleList
			if line ~= ''
				{fpath, url, fstamp} = string.Explode(';', line)
				if not url
					VLL2.MessageBundle(line)
					error('wtf')

				cached = @@FromCache(fpath, tonumber(fstamp))

				if cached
					@fs\Write(fpath, cached)
					@downloaded += 1
				else
					@DownloadFile(fpath, url)

		@CheckIfRunnable()

	Load: =>
		@status = @@STATUS_LOADING

		req = {
			method: 'GET'
			url: @@FETH_BUNDLE_URL .. '?r=' .. @name
			headers: {
				'User-Agent': 'VLL2'
				Referer: VLL2.Referer()
			}
		}

		req.failed = (reason = 'failed') ->
			@status = @@STATUS_ERROR
			@errReason = reason
			@Msg('download of index file failed, reason: ' .. reason)

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@Msg('download of index file failed, server returned: ' .. code)
				@status = @@STATUS_ERROR
				return

			@bundleList = string.Explode('\n', body\Trim())
			@Msg('Received index file, total ' .. #@bundleList .. ' files to load')
			@LoadFromList()

		HTTP(req)

		return @

if SERVER
	net.Receive 'vll2.replicate_all', (len, ply) -> bundle\Replicate(ply) for _, bundle in pairs(VLL2.AbstractBundle._S) when bundle\IsReplicated()
else
	timer.Simple 5, ->
		net.Start('vll2.replicate_all')
		net.SendToServer()
