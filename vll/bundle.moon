
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
file.CreateDir('vll2/ws_cache')

class VLL2.AbstractBundle
	@_S = {}
	@STATUS_NONE = 0
	@STATUS_LOADING = 1
	@STATUS_LOADED = 2
	@STATUS_RUNNING = 3
	@STATUS_ERROR = 4

	@DISK_CACHE = {fil\gsub('%.dat', ''), file.Time('vll2/lua_cache/' .. fil, 'DATA') for fil in *file.Find('vll2/lua_cache/*', 'DATA')}
	@DISK_CACHE_READ = {}

	@Checkup = (bname) =>
		return true if not @_S[bname]
		return not @_S[bname]\IsLoading()

	@__FromCache = (hash) =>
		return @DISK_CACHE_READ[hash] if @DISK_CACHE_READ[hash]
		@DISK_CACHE_READ[hash] = file.Read('vll2/lua_cache/' .. hash .. '.dat', 'DATA')
		decompress = util.Decompress(@DISK_CACHE_READ[hash] or '')

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

	@WriteCache = (fname, contents) =>
		hash = util.CRC(fname)
		@DISK_CACHE[hash] = os.time()
		@DISK_CACHE_READ[fname] = contents
		file.Write('vll2/lua_cache/' .. hash .. '.dat', util.Compress(contents))

	new: (name) =>
		@name = name
		@@_S[name] = @
		@status = @@STATUS_NONE
		@fs = VLL2.FileSystem()
		@globalFS = VLL2.FileSystem.INSTANCE
		@initAfterLoad = true
		@replicated = true

	Msg: (...) => VLL2.MessageBundle(@name .. ': ', ...)

	IsLoading: => @status == @@STATUS_LOADING
	IsLoaded: => @status == @@STATUS_LOADED
	IsRunning: => @status == @@STATUS_RUNNING
	IsErrored: => @status == @@STATUS_ERROR
	IsIdle: => @status == @@STATUS_NONE
	IsReplicated: => @replicated

	DoNotReplicate: =>
		@replicated = false
		return @

	DoReplicate: =>
		@replicated = true
		return @

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
		@downloadQueue = {}
		@cDownloading = 0

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
		if @cDownloading >= 16
			table.insert(@downloadQueue, {fpath, url})
			return

		@DownloadNextFile(fpath, url)
		return @

	__DownloadCallback: =>
		return if #@downloadQueue == 0
		{fpath, url} = table.remove(@downloadQueue)
		@DownloadNextFile(fpath, url)

	DownloadNextFile: (fpath, url) =>
		assert(fpath)
		assert(url)

		@cDownloading += 1

		req = {
			method: 'GET'
			url: url\gsub(' ', '%%20')
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

		req.success = (code = 400, body = '', headers) ->
			@cDownloading -= 1

			if code ~= 200
				@Msg('download of ' .. fpath .. ' failed, server returned: ' .. code)
				@Msg('URL: ' .. url)
				@status = @@STATUS_ERROR
				@__DownloadCallback()
				return

			@downloaded += 1
			@__DownloadCallback()
			@fs\Write(fpath, body)
			@globalFS\Write(fpath, body)
			@@WriteCache(fpath, body)
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
					@globalFS\Write(fpath, cached)
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

class VLL2.GMABundle extends VLL2.AbstractBundle
	new: (name) =>
		super(name)
		@validgma = false
		@loadLua = true
		@addToSpawnMenu = true
		@modelList = {}

	SpecifyPath: (path) =>
		@path = path
		@validgma = file.Exists(path, 'GAME')
		return @

	Replicate: (ply = player.GetAll()) =>

	Load: => @Load()
	Mount: =>
		error('Path was not specified earlier') if not @path

		@Msg('Mounting GMA from ' .. @path)

		status, filelist = game.MountGMA(@path)
		if not status
			@Msg('Unable to mount gma!')
			@status = @@STATUS_ERROR
			return

		if @loadLua
			for _file in *filelist
				if string.sub(_file, 1, 3) == 'lua'
					fread = file.Read(_file, 'GAME')
					@fs\Write(string.sub(_file, 5), fread)
					@globalFS\Write(string.sub(_file, 5), fread)
			@Run() if @initAfterLoad

		@modelList = [_file for _file in *filelist when string.sub(_file, 1, 6) == 'models' and string.sub(_file, -3) == 'mdl']

class VLL2.WSBundle extends VLL2.GMABundle
	@INFO_URL = 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/'

	@IsAddonMounted = (addonid) ->
		return false if not addonid
		return true for addon in *engine.GetAddons() when addon.mounted and addon.wsid == addonid
		return false

	new: (name) =>
		super(name)
		@workshopID = assert(tonumber(@name), 'Unable to cast workshopid to number')

	if CLIENT
		net.Receive 'vll2.replicate_workshop', ->
			graburl = net.ReadUInt(32)
			return if not @Checkup(graburl)
			VLL2.MessageBundle('Server requires workshop addon to be loaded: ' .. graburl)
			VLL2.WSBundle(graburl)\Load()

	Replicate: (ply = player.GetAll()) =>
		return if CLIENT
		return if player.GetHumans() == 0
		net.Start('vll2.replicate_workshop')
		net.WriteUInt(@workshopID, 32)
		net.Send(ply)

	DownloadGMA: (url, filename = util.CRC(url)) =>
		fdir, fname = VLL2.FileSystem.StripFileName(filename)
		fadd = ''
		fadd = util.CRC(fdir) .. '_' if fdir ~= ''

		fpath = 'vll2/ws_cache/' .. fadd .. fname .. '.dat'

		if file.Exists(fpath, 'DATA')
			@Msg('Found GMA in cache, mounting in-place...')
			@SpecifyPath('data/' .. fpath)
			@Mount()
			return

		req = {method: 'GET', :url}

		req.failed = (reason = 'failure') ->
			@status = @@STATUS_ERROR
			@Msg('Failed to download the GMA! Reason: ' .. reason)

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@status = @@STATUS_ERROR
				@Msg('Failed to download the GMA! Server returned: ' .. code)
				return

			@Msg('--- DECOMPRESSING')
			stime = SysTime()
			decompress = util.Decompress(body)
			if decompress == ''
				@status = @@STATUS_ERROR
				@Msg('Failed to decompress the GMA! Did tranfer got interrupted?')
				return

			@Msg(string.format('Decompression took %.2f ms', (SysTime() - stime) * 1000))
			stime = SysTime()
			@Msg('--- WRITING')
			file.Write(fpath, decompress)
			@Msg(string.format('Writing to disk took %.2f ms', (SysTime() - stime) * 1000))

			@SpecifyPath('data/' .. fpath)
			@Mount()

		HTTP(req)
		@Msg('Downloading ' .. @wsTitle .. '...')

	Load: =>
		@status = @@STATUS_LOADING

		if CLIENT and steamworks.IsSubscribed(tostring(id)) and not @loadLua
			@Msg('Not downloading addon ' .. id .. ' since it is already mounted on client.')
			@status = @@STATUS_LOADED
			return

		if CLIENT
			steamworks.FileInfo @workshopID, (data) ->
				if not data
					@Msg('Steamworks returned an error, check above')
					@status = @@STATUS_ERROR
					return

				@Msg('GOT FILEINFO DETAILS FOR ' .. @workshopID .. ' (' .. data.title .. ')')
				@name = data.title
				@steamworksInfo = data

				path = 'cache/workshop/' .. data.fileid .. '.cache'

				if file.Exists(path, 'GAME')
					@SpecifyPath(path)
					@Mount()
				else
					@Msg('Downloading from workshop')
					steamworks.Download data.fileid, true, (path2) ->
						@Msg('Downloaded from workshop')
						@SpecifyPath(path2 or path)
						@Mount()
		else
			req = {
				method: 'POST'
				url: @@INFO_URL
				parameters: {itemcount: '1', 'publishedfileids[0]': tostring(@workshopID)}
			}

			req.failed = (reason = 'failure') ->
				@status = @@STATUS_ERROR
				@Msg('Failed to grab GMA info! Reason: ' .. reason)

			req.success = (code = 400, body = '', headers) ->
				if code ~= 200
					@status = @@STATUS_ERROR
					@Msg('Failed to grab GMA info! Server returned: ' .. code)
					@Msg(body)
					return

				resp = util.JSONToTable(body)

				if resp and resp.response and resp.response.publishedfiledetails
					for item in *resp.response.publishedfiledetails
						if VLL2.WSBundle.IsAddonMounted(item.publishedfileid)
							@Msg('Addon ' .. item.title .. ' is already mounted and running')
						else
							@Msg('GOT FILEINFO DETAILS FOR ' .. @workshopID .. ' (' .. item.title .. ')')
							@steamworksInfo = item
							@wsTitle = item.title
							@name = item.title
							@DownloadGMA(item.file_url, item.filename)

			HTTP(req)

if SERVER
	net.Receive 'vll2.replicate_all', (len, ply) -> bundle\Replicate(ply) for _, bundle in pairs(VLL2.AbstractBundle._S) when bundle\IsReplicated()
else
	timer.Simple 5, ->
		net.Start('vll2.replicate_all')
		net.SendToServer()
