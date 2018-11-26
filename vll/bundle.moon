
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
	util.AddNetworkString('vll2.replicate_wscollection')
	util.AddNetworkString('vll2.replicate_all')

file.CreateDir('vll2')
file.CreateDir('vll2/lua_cache')
file.CreateDir('vll2/ws_cache')
file.CreateDir('vll2/gma_cache')

class VLL2.AbstractBundle
	@_S = {}
	@LISTING = {}
	@STATUS_NONE = 0
	@STATUS_LOADING = 1
	@STATUS_LOADED = 2
	@STATUS_RUNNING = 3
	@STATUS_ERROR = 4

	@DISK_CACHE = {fil\sub(1, -5)\Trim(), file.Time('vll2/lua_cache/' .. fil, 'DATA') for fil in *file.Find('vll2/lua_cache/*', 'DATA')}
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
				return @__FromCache(hash)
			else
				@DISK_CACHE_READ[hash] = nil
				@DISK_CACHE[hash] = nil
				file.Delete('vll2/lua_cache/' .. hash .. '.dat')
				return
		else
			return @__FromCache(hash)

	@WriteCache = (fname, contents) =>
		hash = util.CRC(fname)
		@DISK_CACHE[hash] = os.time()
		@DISK_CACHE_READ[fname] = contents
		file.Write('vll2/lua_cache/' .. hash .. '.dat', util.Compress(contents))

	new: (name) =>
		@name = name
		@@_S[name] = @
		@@LISTING[name] = @
		@status = @@STATUS_NONE
		@fs = VLL2.FileSystem()
		@globalFS = VLL2.FileSystem.INSTANCE
		@initAfterLoad = true
		@replicated = true
		@errorCallbacks = {}
		@finishCallbacks = {}
		@loadCallbacks = {}

	Msg: (...) => VLL2.MessageBundle(@name .. ': ', ...)

	IsLoading: => @status == @@STATUS_LOADING
	IsLoaded: => @status == @@STATUS_LOADED
	IsRunning: => @status == @@STATUS_RUNNING
	IsErrored: => @status == @@STATUS_ERROR
	IsIdle: => @status == @@STATUS_NONE
	IsReplicated: => @replicated

	SetInitAfterLoad: (status = @initAfterLoad) =>
		@initAfterLoad = status
		return @
	DoInitAfterLoad: => @SetInitAfterLoad(true)
	DoNotInitAfterLoad: => @SetInitAfterLoad(true)

	AddLoadedHook: (fcall) =>
		if @IsRunning()
			fcall(@)
			return @

		table.insert(@loadCallbacks, fcall)
		return @
	AddFinishHook: (fcall) =>
		if @IsRunning()
			fcall(@)
			return @

		table.insert(@finishCallbacks, fcall)
		return @
	AddErrorHook: (fcall) =>
		if @IsErrored()
			fcall(@)
			return @

		table.insert(@errorCallbacks, fcall)
		return @

	CallError: (...) => fcall(@, ...) for fcall in *@errorCallbacks
	CallFinish: (...) => fcall(@, ...) for fcall in *@finishCallbacks
	CallLoaded: (...) => fcall(@, ...) for fcall in *@loadCallbacks

	DoNotReplicate: =>
		@replicated = false
		return @

	DoReplicate: =>
		@replicated = true
		return @

	SetReplicate: (status = @replicated) =>
		@replicated = status
		return @

	Replicate: (ply = player.GetAll()) =>
		return if CLIENT
		error('Not implemented')

	Run: =>
		vm = VLL2.VM(@name, @fs, VLL2.FileSystem.INSTANCE)
		vm\LoadAutorun()
		vm\LoadEntities()
		vm\LoadWeapons()
		vm\LoadEffects() if CLIENT
		vm\LoadTFA()
		@Msg('Bundle successfully initialized!')
		@CallFinish()

	Load: => error('Not implemented')

class VLL2.URLBundle extends VLL2.AbstractBundle
	@FETH_BUNDLE_URL = 'https://dbotthepony.ru/vll/package.php'
	@LISTING = {}

	@GetMessage = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsLoading()
		return if downloading == 0
		return 'VLL2 Is downloading ' .. downloading .. ' URL bundles'

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
		@CallLoaded()
		return if not @initAfterLoad
		@Run()

	DownloadFile: (fpath, url) =>
		if SERVER and @cDownloading >= 16 or CLIENT and @cDownloading >= 48
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
			@CallError()

		req.success = (code = 400, body = '', headers) ->
			@cDownloading -= 1

			if code ~= 200
				@Msg('download of ' .. fpath .. ' failed, server returned: ' .. code)
				@Msg('URL: ' .. url)
				@status = @@STATUS_ERROR
				@__DownloadCallback()
				@CallError()
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
			@CallError()

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@Msg('download of index file failed, server returned: ' .. code)
				@status = @@STATUS_ERROR
				@CallError()
				return

			@bundleList = string.Explode('\n', body\Trim())
			@Msg('Received index file, total ' .. #@bundleList .. ' files to load')
			@LoadFromList()

		HTTP(req)

		return @

class VLL2.GMABundle extends VLL2.AbstractBundle
	@LISTING = {}
	@STATUS_GONNA_MOUNT = 734

	new: (name) =>
		super(name)
		@validgma = false
		@loadLua = true
		@addToSpawnMenu = true
		@modelList = {}

	@GetMessage = =>
		return if SERVER
		msg1 = @GetMessage1()
		msg2 = @GetMessage2()
		return if not msg1 and not msg2
		return msg1 if msg1 and not msg2
		return msg2 if not msg1 and msg2
		return {msg1, msg2}

	@GetMessage1 = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsLoading()
		return if downloading == 0
		return 'VLL2 Is downloading ' .. downloading .. ' GMA bundles'

	@GetMessage2 = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsGoingToMount()
		return if downloading == 0
		return 'VLL2 going to mount ' .. downloading .. ' GMA bundles\nFreeze (or crash) may occur\nthat\'s fine'

	IsGoingToMount: => @status == @@STATUS_GONNA_MOUNT

	DoLoadLua: => @SetLoadLua(true)
	DoNotLoadLua: => @SetLoadLua(false)
	SetLoadLua: (status = @loadLua) =>
		@loadLua = status
		return @

	DoAddToSpawnMenu: => @SetAddToSpawnMenu(true)
	DoNotAddToSpawnMenu: => @SetAddToSpawnMenu(false)
	SetAddToSpawnMenu: (status = @addToSpawnMenu) =>
		@addToSpawnMenu = status
		return @

	SpecifyPath: (path) =>
		@path = path
		@validgma = file.Exists(path, 'GAME')
		return @

	Replicate: (ply = player.GetAll()) =>

	Load: => @Load()
	MountDelay: =>
		return if @IsGoingToMount()
		@status = @@STATUS_GONNA_MOUNT
		timer.Simple 3, -> @Mount()

	Mount: =>
		error('Path was not specified earlier') if not @path
		@status = @@STATUS_LOADING

		@Msg('Mounting GMA from ' .. @path)

		status, filelist = game.MountGMA(@path)
		if not status
			@Msg('Unable to mount gma!')
			@status = @@STATUS_ERROR
			@CallError()
			return

		@Msg('GMA IS EMPTY???!!!') if #filelist == 0

		if @loadLua
			for _file in *filelist
				if string.sub(_file, 1, 3) == 'lua'
					fread = file.Read(_file, 'GAME')
					@fs\Write(string.sub(_file, 5), fread)
					@globalFS\Write(string.sub(_file, 5), fread)
			@Run() if @initAfterLoad

		@modelList = [_file for _file in *filelist when string.sub(_file, 1, 6) == 'models' and string.sub(_file, -3) == 'mdl']
		@matList = [_file for _file in *filelist when string.sub(_file, 1, 9) == 'materials']
		@Msg('Total assets: ', #filelist, ' including ', #@modelList, ' models and ', #@matList, ' materials')

		@status = @@STATUS_LOADED

class VLL2.URLGMABundle extends VLL2.GMABundle
	new: (name, url) =>
		super(name)
		@crc = util.CRC(url)
		@url = url
		@_datapath = 'vll2/gma_cache/' .. @crc .. '.dat'
		@_datapath_full = 'data/vll2/gma_cache/' .. @crc .. '.dat'

		@mountAfterLoad = true

	SetMountAfterLoad: (status = @mountAfterLoad) =>
		@mountAfterLoad = status
		return @
	DoMountAfterLoad: => @SetMountAfterLoad(true)
	DoNotMountAfterLoad: => @SetMountAfterLoad(false)

	__Mount: =>
		@status = @@STATUS_LOADED
		@CallLoaded()
		return if not @mountAfterLoad
		@MountDelay()

	AfterLoad: =>
		@SpecifyPath(@_datapath_full)
		@__Mount()

	Load: =>
		if file.Exists(@_datapath, 'DATA')
			@Msg('Found GMA in cache, mounting in-place...')
			@SpecifyPath(@_datapath_full)
			@__Mount()
			return

		@status = @@STATUS_LOADING

		@gmadownloader = VLL2.LargeFileLoader(@url, @_datapath)

		@gmadownloader\AddFinishHook -> @AfterLoad()

		@gmadownloader\AddErrorHook (_, reason = 'failure') ->
			@status = @@STATUS_ERROR
			@Msg('Failed to download the GMA! Reason: ' .. reason)
			@CallError()

		@Msg('Downloading URL gma...')
		@gmadownloader\Load()

class VLL2.URLGMABundleZ extends VLL2.URLGMABundle
	AfterLoad: =>
		@Msg('--- DECOMPRESSING')
		stime = SysTime()
		decompress = util.Decompress(file.Read(@_datapath, 'DATA'))

		if decompress == ''
			@status = @@STATUS_ERROR
			@Msg('Failed to decompress the GMA! Did tranfer got interrupted?')
			@CallError()
			return

		@Msg(string.format('Decompression took %.2f ms', (SysTime() - stime) * 1000))
		stime = SysTime()
		@Msg('--- WRITING')
		file.Write(@_datapath, decompress)
		@Msg(string.format('Writing to disk took %.2f ms', (SysTime() - stime) * 1000))

		@SpecifyPath(@_datapath_full)
		@__Mount()

class VLL2.WSCollection extends VLL2.AbstractBundle
	@COLLECTION_INFO_URL = 'https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/'
	@INFO_URL = 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/'
	@LISTING = {}

	@STATUS_GETTING_INFO = 621

	if CLIENT
		net.Receive 'vll2.replicate_wscollection', ->
			graburl = net.ReadUInt(32)
			return if not @Checkup(graburl)
			loadLua = net.ReadBool()
			mountAfterLoad = net.ReadBool()
			VLL2.MessageBundle('Server requires workshop COLLECTION to be loaded: ' .. graburl)
			bundle = VLL2.WSCollection(graburl)
			bundle.loadLua = loadLua
			bundle.mountAfterLoad = mountAfterLoad
			bundle\Load()

	Replicate: (ply = player.GetAll()) =>
		return if CLIENT
		return if player.GetHumans() == 0
		net.Start('vll2.replicate_wscollection')
		net.WriteUInt(@workshopID, 32)
		net.WriteBool(@loadLua)
		net.WriteBool(@mountAfterLoad)
		net.Send(ply)

	new: (name) =>
		super(name)
		@workshopID = assert(tonumber(@name), 'Unable to cast workshopid to number')
		@mountAfterLoad = true
		@gmaListing = {}
		@loadLua = true

	@GetMessage = =>
		return if SERVER
		msg1 = @GetMessage1()
		msg2 = @GetMessage2()
		return if not msg1 and not msg2
		return msg1 if msg1 and not msg2
		return msg2 if not msg1 and msg2
		return {msg1, msg2}

	@GetMessage1 = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsLoading()
		return if downloading == 0
		return 'VLL2 Is downloading ' .. downloading .. ' Workshop COLLECTIONS'

	@GetMessage2 = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsGettingInfo()
		return if downloading == 0
		return 'Getting info of ' .. downloading .. ' workshop COLLECTIONS'

	SetMountAfterLoad: (status = @mountAfterLoad) =>
		@mountAfterLoad = status
		return @
	DoMountAfterLoad: => @SetMountAfterLoad(true)
	DoNotMountAfterLoad: => @SetMountAfterLoad(false)
	IsGettingInfo: => @status == @@STATUS_GETTING_INFO

	DoLoadLua: => @SetLoadLua(true)
	DoNotLoadLua: => @SetLoadLua(false)
	SetLoadLua: (status = @loadLua) =>
		@loadLua = status
		return @

	Mount: =>
		@Msg('GOING TO MOUNT WORKSHOP COLLECTION RIGHT NOW')
		fbundle\Mount() for fbundle in *@gmaListing
		@status = @@STATUS_RUNNING
		@Msg('Workshop collection initialized!')
		@CallFinish()

	OnAddonLoads: (...) =>
		for fbundle in *@gmaListing
			if not fbundle\IsLoaded()
				return

		@status = @@STATUS_LOADED
		@CallLoaded()
		return if not @mountAfterLoad
		@Mount()

	OnAddonFails: (fbundle, str, code, ...) =>
		if code == VLL2.WSBundle.INVALID_WS_DATA
			for i, fbundle2 in ipairs(@gmaListing)
				if fbundle == fbundle2
					table.remove(@gmaListing, i)
			@OnAddonLoads()
			return

		@status = @@STATUS_ERROR
		@Msg('One of collection addons has failed to load! Uh oh!')
		@CallError(str, code, ...)

	GetCollectionDetails: =>
		@status = @@STATUS_LOADING
		@gmaListing = {}

		@status = @@STATUS_GETTING_INFO
		req = {
			method: 'POST'
			url: @@COLLECTION_INFO_URL
			parameters: {collectioncount: '1', 'publishedfileids[0]': tostring(@workshopID)}
			headers: {
				'User-Agent': 'VLL2'
				Referer: VLL2.Referer()
			}
		}

		req.failed = (reason = 'failure') ->
			@status = @@STATUS_ERROR
			@Msg('Failed to grab collection info! Reason: ' .. reason)
			@CallError()

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@status = @@STATUS_ERROR
				@Msg('Failed to grab collection info! Server returned: ' .. code)
				@Msg(body)
				@CallError()
				return

			resp = util.JSONToTable(body)
			@steamResponse = resp
			@steamResponseRaw = body

			@status = @@STATUS_LOADING

			if resp and resp.response and resp.response.result == 1 and resp.response.collectiondetails and resp.response.collectiondetails[1] and resp.response.collectiondetails[1].result == 1 and resp.response.collectiondetails[1].children
				for item in *resp.response.collectiondetails[1].children
					fbundle = VLL2.WSBundle(item.publishedfileid)
					fbundle\DoNotMountAfterLoad()
					fbundle\DoNotReplicate()
					fbundle\SetLoadLua(@loadLua)
					fbundle\Load()
					fbundle\AddLoadedHook (_, ...) -> @OnAddonLoads(...)
					fbundle\AddErrorHook (_, ...) -> @OnAddonFails(_, ...)
					table.insert(@gmaListing, fbundle)
			else
				@status = @@STATUS_ERROR
				@Msg('Failed to grab collection info! Server did not sent valid reply or collection contains no items')

		HTTP(req)

	GetWorkshopDetails: =>
		@status = @@STATUS_GETTING_INFO
		req = {
			method: 'POST'
			url: @@INFO_URL
			parameters: {itemcount: '1', 'publishedfileids[0]': tostring(@workshopID)}
			headers: {
				'User-Agent': 'VLL2'
				Referer: VLL2.Referer()
			}
		}

		req.failed = (reason = 'failure') ->
			@status = @@STATUS_ERROR
			@Msg('Failed to grab GMA info! Reason: ' .. reason)
			@CallError()

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@status = @@STATUS_ERROR
				@Msg('Failed to grab GMA info! Server returned: ' .. code)
				@Msg(body)
				@CallError()
				return

			resp = util.JSONToTable(body)
			@steamResponse = resp
			@steamResponseRaw = body

			if resp and resp.response and resp.response.publishedfiledetails
				for item in *resp.response.publishedfiledetails
					if VLL2.WSBundle.IsAddonMounted(item.publishedfileid) and not @loadLua
						@status = @@STATUS_LOADED
						@Msg('Addon ' .. item.title .. ' is already mounted and running')
					elseif item.hcontent_file and item.title
						@Msg('GOT FILEINFO DETAILS FOR ' .. @workshopID .. ' (' .. item.title .. ')')
						@steamworksInfo = item
						@wsTitle = item.title
						@name = item.title

						if tobool(item.banned)
							@Msg('-----------------------------')
							@Msg('--- This workshop item was BANNED!')
							@Msg('--- Ban reason: ' .. (item.ban_reason or '<unknown>'))
							@Msg('--- But the addon will still be mounted though')
							@Msg('-----------------------------')

						@GetCollectionDetails()
					else
						@status = @@STATUS_ERROR
						@Msg('This workshop item contains no valid data.')
						@CallError('This workshop item contains no valid data.')
			else
				@status = @@STATUS_ERROR
				@Msg('Failed to grab GMA info! Server did not sent valid reply')
				@CallError()

		HTTP(req)

	Load: => @GetWorkshopDetails()

class VLL2.WSBundle extends VLL2.GMABundle
	@INFO_URL = 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/'
	@LISTING = {}

	@STATUS_GETTING_INFO = 5

	@IsAddonMounted = (addonid) ->
		return false if not addonid
		return true for addon in *engine.GetAddons() when addon.mounted and addon.wsid == addonid
		return false

	@GetMessage = =>
		return if SERVER
		msg1 = @GetMessage1()
		msg2 = @GetMessage2()
		msgOld = VLL2.GMABundle.GetMessage2(@)
		return if not msg1 and not msg2 and not msgOld
		output = {}
		table.insert(output, msg1) if msg1
		table.insert(output, msg2) if msg2
		table.insert(output, msgOld) if msgOld
		return output

	@GetMessage1 = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsLoading()
		return if downloading == 0
		return 'VLL2 Is downloading ' .. downloading .. ' Workshop addons'

	@GetMessage2 = =>
		return if SERVER
		downloading = 0
		downloading += 1 for _, bundle in pairs(@LISTING) when bundle\IsGettingInfo()
		return if downloading == 0
		return 'Getting info of ' .. downloading .. ' workshop addons'

	new: (name) =>
		super(name)
		@workshopID = assert(tonumber(@name), 'Unable to cast workshopid to number')
		@mountAfterLoad = true

	SetMountAfterLoad: (status = @mountAfterLoad) =>
		@mountAfterLoad = status
		return @
	DoMountAfterLoad: => @SetMountAfterLoad(true)
	DoNotMountAfterLoad: => @SetMountAfterLoad(false)
	IsGettingInfo: => @status == @@STATUS_GETTING_INFO

	__Mount: =>
		@status = @@STATUS_LOADED
		@CallLoaded()
		return if not @mountAfterLoad
		@MountDelay()

	if CLIENT
		net.Receive 'vll2.replicate_workshop', ->
			graburl = net.ReadUInt(32)
			return if not @Checkup(graburl)
			loadLua = net.ReadBool()
			addToSpawnMenu = net.ReadBool()
			VLL2.MessageBundle('Server requires workshop addon to be loaded: ' .. graburl)
			bundle = VLL2.WSBundle(graburl)
			bundle.loadLua = loadLua
			bundle.addToSpawnMenu = addToSpawnMenu
			bundle\Load()

	Replicate: (ply = player.GetAll()) =>
		return if CLIENT
		return if player.GetHumans() == 0
		net.Start('vll2.replicate_workshop')
		net.WriteUInt(@workshopID, 32)
		net.WriteBool(@loadLua)
		net.WriteBool(@addToSpawnMenu)
		net.Send(ply)

	DownloadGMA: (url, filename = util.CRC(url)) =>
		if CLIENT
			msgid = 'vll2_dl_' .. @workshopID
			notification.AddProgress(msgid, 'Downloading ' .. data.title .. ' from workshop')
			@status = @@STATUS_LOADING
			steamworks.Download data.fileid, true, (path2) ->
				notification.Kill(msgid)
				@Msg('Downloaded from workshop')
				@SpecifyPath(path2 or path)
				@__Mount()
			return

		fdir, fname = VLL2.FileSystem.StripFileName(filename)
		fadd = ''
		fadd = util.CRC(fdir) .. '_' if fdir ~= ''

		fpath = 'vll2/ws_cache/' .. fadd .. fname .. '.dat'

		if file.Exists(fpath, 'DATA')
			@Msg('Found GMA in cache, mounting in-place...')
			@SpecifyPath('data/' .. fpath)
			@__Mount()
			return

		@gmadownloader = VLL2.LargeFileLoader(url, fpath)

		@gmadownloader\AddFinishHook ->
			@Msg('--- DECOMPRESSING')
			stime = SysTime()
			decompress = util.Decompress(file.Read(fpath, 'DATA'))

			if decompress == ''
				@status = @@STATUS_ERROR
				@Msg('Failed to decompress the GMA! Did tranfer got interrupted?')
				@CallError()
				return

			@Msg(string.format('Decompression took %.2f ms', (SysTime() - stime) * 1000))
			stime = SysTime()
			@Msg('--- WRITING')
			file.Write(fpath, decompress)
			@Msg(string.format('Writing to disk took %.2f ms', (SysTime() - stime) * 1000))

			@SpecifyPath('data/' .. fpath)
			@__Mount()

		@gmadownloader\AddErrorHook (_, reason = 'failure') ->
			@status = @@STATUS_ERROR
			@Msg('Failed to download the GMA! Reason: ' .. reason)
			@CallError()

		@Msg('Downloading ' .. @wsTitle .. '...')
		@gmadownloader\Load()

	@INVALID_WS_DATA = 912

	Load: =>
		@status = @@STATUS_LOADING

		if CLIENT and steamworks.IsSubscribed(tostring(id)) and not @loadLua
			@Msg('Not downloading addon ' .. id .. ' since it is already mounted on client.')
			@status = @@STATUS_LOADED
			return

		if CLIENT
			@status = @@STATUS_GETTING_INFO
			req = {
				method: 'POST'
				url: @@INFO_URL
				parameters: {itemcount: '1', 'publishedfileids[0]': tostring(@workshopID)}
				headers: {
					'User-Agent': 'VLL2'
					Referer: VLL2.Referer()
				}
			}

			req.failed = (reason = 'failure') ->
				@status = @@STATUS_ERROR
				@Msg('Failed to grab GMA info! Reason: ' .. reason)
				@CallError()

			req.success = (code = 400, body = '', headers) ->
				if code ~= 200
					@status = @@STATUS_ERROR
					@Msg('Failed to grab GMA info! Server returned: ' .. code)
					@Msg(body)
					@CallError()
					return

				resp = util.JSONToTable(body)
				@steamResponse = resp
				@steamResponseRaw = body

				if resp and resp.response and resp.response.publishedfiledetails
					for item in *resp.response.publishedfiledetails
						if VLL2.WSBundle.IsAddonMounted(item.publishedfileid) and not @loadLua
							@status = @@STATUS_LOADED
							@Msg('Addon ' .. item.title .. ' is already mounted and running')
						elseif item.hcontent_file and item.title
							@Msg('GOT FILEINFO DETAILS FOR ' .. @workshopID .. ' (' .. item.title .. ')')
							path = 'cache/workshop/' .. item.hcontent_file .. '.cache'
							@steamworksInfo = item
							@wsTitle = item.title
							@name = item.title

							if tobool(item.banned)
								@Msg('-----------------------------')
								@Msg('--- This workshop item was BANNED!')
								@Msg('--- Ban reason: ' .. (item.ban_reason or '<unknown>'))
								@Msg('--- But the addon will still be mounted though')
								@Msg('-----------------------------')

							if file.Exists(path, 'GAME')
								@SpecifyPath(path)
								@__Mount()
							else
								@Msg('Downloading from workshop')
								msgid = 'vll2_dl_' .. @workshopID
								notification.AddProgress(msgid, 'Downloading ' .. item.title .. ' from workshop')
								@status = @@STATUS_LOADING
								steamworks.Download item.hcontent_file, true, (path2) ->
									notification.Kill(msgid)
									@Msg('Downloaded from workshop')
									@SpecifyPath(path2 or path)
									@__Mount()
						else
							@status = @@STATUS_ERROR
							@Msg('This workshop item contains no valid data.')
							@CallError('This workshop item contains no valid data.', @@INVALID_WS_DATA)
				else
					@status = @@STATUS_ERROR
					@Msg('Failed to grab GMA info! Server did not sent valid reply')
					@CallError()

			HTTP(req)
		else
			@status = @@STATUS_GETTING_INFO
			req = {
				method: 'POST'
				url: @@INFO_URL
				parameters: {itemcount: '1', 'publishedfileids[0]': tostring(@workshopID)}
				headers: {
					'User-Agent': 'VLL2'
					Referer: VLL2.Referer()
				}
			}

			req.failed = (reason = 'failure') ->
				@status = @@STATUS_ERROR
				@Msg('Failed to grab GMA info! Reason: ' .. reason)
				@CallError()

			req.success = (code = 400, body = '', headers) ->
				if code ~= 200
					@status = @@STATUS_ERROR
					@Msg('Failed to grab GMA info! Server returned: ' .. code)
					@Msg(body)
					@CallError()
					return

				resp = util.JSONToTable(body)
				@steamResponse = resp
				@steamResponseRaw = body

				if resp and resp.response and resp.response.publishedfiledetails
					for item in *resp.response.publishedfiledetails
						if VLL2.WSBundle.IsAddonMounted(item.publishedfileid) and not @loadLua
							@status = @@STATUS_LOADED
							@Msg('Addon ' .. item.title .. ' is already mounted and running')
						elseif item.hcontent_file and item.title
							@Msg('GOT FILEINFO DETAILS FOR ' .. @workshopID .. ' (' .. item.title .. ')')
							@steamworksInfo = item
							@wsTitle = item.title
							@name = item.title

							if tobool(item.banned)
								@Msg('-----------------------------')
								@Msg('--- This workshop item was BANNED!')
								@Msg('--- Ban reason: ' .. (item.ban_reason or '<unknown>'))
								@Msg('--- But the addon will still be mounted though')
								@Msg('-----------------------------')

							@DownloadGMA(item.file_url, item.filename)
						else
							@status = @@STATUS_ERROR
							@Msg('This workshop item contains no valid data.')
							@CallError('This workshop item contains no valid data.')
				else
					@status = @@STATUS_ERROR
					@Msg('Failed to grab GMA info! Server did not sent valid reply')
					@CallError()

			HTTP(req)

if SERVER
	net.Receive 'vll2.replicate_all', (len, ply) -> bundle\Replicate(ply) for _, bundle in pairs(VLL2.AbstractBundle._S) when bundle\IsReplicated()
else
	timer.Simple 5, ->
		net.Start('vll2.replicate_all')
		net.SendToServer()
