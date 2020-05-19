
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
	@LISTING = {}

	new: (name = 'URL:' .. util.CRC(url), url) =>
		super(name)
		@crc = util.CRC(url)
		@url = url
		@_datapath = 'vll2/gma_cache/' .. @crc .. '.dat'
		@_datapath_full = 'data/vll2/gma_cache/' .. @crc .. '.dat'

		@mountAfterLoad = true

	if CLIENT
		net.Receive 'vll2.replicate_urlgma', ->
			graburl = net.ReadString()
			fname = 'URL:' .. util.CRC(graburl)
			return if not @Checkup(fname)
			loadLua = net.ReadBool()
			mountAfterLoad = net.ReadBool()
			VLL2.MessageBundle('Server requires URL GMA to be loaded: ' .. graburl)
			bundle = VLL2.URLGMABundle(nil, graburl)
			bundle.loadLua = loadLua
			bundle.mountAfterLoad = mountAfterLoad
			bundle\Load()

	Replicate: (ply = player.GetHumans()) =>
		return if CLIENT
		return if istable(ply) and #ply == 0
		net.Start('vll2.replicate_urlgma')
		net.WriteString(@url)
		net.WriteBool(@loadLua)
		net.WriteBool(@addToSpawnMenu)
		net.Send(ply)

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
		if CLIENT and @shouldNotifyServerside
			net.Start('vll2.gma_notify_url')
			net.WriteString(@url)
			net.WriteBool(true)
			net.SendToServer()
		@SpecifyPath(@_datapath_full)
		@__Mount()

	if SERVER
		util.AddNetworkString('vll2.gma_notify_url')
		net.Receive 'vll2.gma_notify_url', (len = 0, ply = NULL) ->
			return if not ply\IsValid()
			return if game.IsDedicated()
			return if ply\EntIndex() ~= 1

			url = net.ReadString()
			status = net.ReadBool()

			for name, self in pairs(@LISTING)
				if @url == url
					@SpecifyPath(@_datapath_full)
					@AfterLoad(true) if status
					if not status
						@status = @@STATUS_ERROR
						@Msg('Failed to download the GMA! Reason: ' .. reason)
						@CallError()
					return

			VLL2.Message('Received URL bundle path from clientside, but no associated bundle found.')
			VLL2.Message('W.T.F? URL is ' .. url)
	else
		net.Receive 'vll2.gma_notify_url', (len = 0) ->
			url = net.ReadString()
			_datapath = net.ReadString()

			for name, bundle in pairs(@LISTING)
				if bundle.url == url
					if bundle.finished
						net.Start('vll2.gma_notify_url')
						net.WriteString(url)
						net.WriteBool(true)
						net.SendToServer()
					else
						bundle.shouldNotifyServerside = true

					return

			gmadownloader = VLL2.LargeFileLoader(url, _datapath)

			gmadownloader\AddFinishHook ->
				net.Start('vll2.gma_notify_url')
				net.WriteString(url)
				net.WriteBool(true)
				net.SendToServer()

			gmadownloader\AddErrorHook (_, reason = 'failure') ->
				net.Start('vll2.gma_notify_url')
				net.WriteString(url)
				net.WriteBool(false)
				net.SendToServer()
				VLL2.Message('Failed to download the GMA for server! Reason: ' .. reason)

			gmadownloader\Load()

	Load: =>
		if SERVER and not game.IsDedicated()
			timer.Simple 1, ->
				net.Start('vll2.gma_notify_url')
				net.WriteString(@url)
				net.WriteString(@_datapath)
				net.Send(Entity(1))
			return

		if file.Exists(@_datapath, 'DATA')
			@Msg('Found GMA in cache, mounting in-place...')
			@SpecifyPath(@_datapath_full)
			@__Mount()
			return

		if CLIENT and not VLL2.DO_DOWNLOAD_WORKSHOP\GetBool()
			@Msg('Not downloading workshop GMA file, since we have it disabled')
			@status = @@STATUS_ERROR
			@CallError('Restricted by user')
			return

		@status = @@STATUS_LOADING

		@gmadownloader = VLL2.LargeFileLoader(@url, @_datapath)

		@gmadownloader\AddFinishHook -> @AfterLoad()

		@gmadownloader\AddErrorHook (_, reason = 'failure') ->
			if CLIENT and @shouldNotifyServerside
				net.Start('vll2.gma_notify_url')
				net.WriteString(@url)
				net.WriteBool(false)
				net.SendToServer()
			@status = @@STATUS_ERROR
			@Msg('Failed to download the GMA! Reason: ' .. reason)
			@CallError()

		@Msg('Downloading URL gma...')
		@gmadownloader\Load()

class VLL2.URLGMABundleZ extends VLL2.URLGMABundle
	@LISTING = {}

	if CLIENT
		net.Receive 'vll2.replicate_urlgmaz', ->
			graburl = net.ReadString()
			fname = 'URL:' .. util.CRC(graburl)
			return if not @Checkup(fname)
			loadLua = net.ReadBool()
			mountAfterLoad = net.ReadBool()
			VLL2.MessageBundle('Server requires URL GMA to be loaded: ' .. graburl)
			bundle = VLL2.URLGMABundleZ(nil, graburl)
			bundle.loadLua = loadLua
			bundle.mountAfterLoad = mountAfterLoad
			bundle\Load()

	Replicate: (ply = player.GetHumans()) =>
		return if CLIENT
		return if istable(ply) and #ply == 0
		net.Start('vll2.replicate_urlgmaz')
		net.WriteString(@url)
		net.WriteBool(@loadLua)
		net.WriteBool(@addToSpawnMenu)
		net.Send(ply)

	AfterLoad: (clientload) =>
		@Msg('--- DECOMPRESSING')
		stime = SysTime()
		decompress = util.Decompress(file.Read(@_datapath, 'DATA'))

		if decompress == '' or not decompress
			if SERVER and not game.IsDedicated() and clientload
				@SpecifyPath(@_datapath_full)
				@__Mount()
				return

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
