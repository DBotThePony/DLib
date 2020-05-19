
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

		if @shouldNotifyServerside
			net.Start('vll2.gma_notify')
			net.WriteUInt(@workshopID, 32)
			net.WriteString(@path)
			net.SendToServer()
			@Msg('Notifying server realm that we downloaded GMA.')
			@shouldNotifyServerside = false

		return if not @mountAfterLoad
		@MountDelay()

	Mount: (...) =>
		if @shouldNotifyServerside
			net.Start('vll2.gma_notify')
			net.WriteUInt(@workshopID, 32)
			net.WriteString(@path)
			net.SendToServer()
			@Msg('Notifying server realm that we downloaded GMA.')
			@shouldNotifyServerside = false

		return super(...)
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

	if SERVER
		util.AddNetworkString('vll2.gma_notify')
		net.Receive 'vll2.gma_notify', (len = 0, ply = NULL) ->
			return if not ply\IsValid()
			return if game.IsDedicated()
			return if ply\EntIndex() ~= 1

			wsid = net.ReadUInt(32)
			path = net.ReadString()

			for name, bundle in pairs(@LISTING)
				if bundle.workshopID == wsid
					bundle\SpecifyPath(path)
					bundle\__Mount()
					return

			VLL2.Message('Received bundle path from clientside, but no associated bundle found.')
			VLL2.Message('W.T.F? Workshop id is ' .. wsid)
	else
		net.Receive 'vll2.gma_notify', (len = 0) ->
			wsid = net.ReadUInt(32)
			hcontent_file = net.ReadString()

			for name, bundle in pairs(@LISTING)
				if bundle.workshopID == wsid
					if bundle.wscontentPath
						net.Start('vll2.gma_notify')
						net.WriteUInt(wsid, 32)
						net.WriteString(bundle.wscontentPath)
						net.SendToServer()
						bundle\Msg('Notifying server realm that we already got GMA')
					else
						bundle.shouldNotifyServerside = true
						bundle\Msg('We are still downloading bundle. Will notify server realm when we are done.')

					return

			msgid = 'vll2_dl_' .. wsid
			notification.AddProgress(msgid, 'Downloading ' .. wsid .. ' from workshop (SERVER)')
			VLL2.Message('Downloading addon for server realm: ' .. wsid)

			steamworks.Download hcontent_file, true, (path) ->
				notification.Kill(msgid)
				net.Start('vll2.gma_notify')
				net.WriteUInt(wsid, 32)
				net.WriteString(path)
				net.SendToServer()

	DownloadGMA: (url, filename = util.CRC(url), data, callback) =>
		msgid = 'vll2_dl_' .. @workshopID
		@status = @@STATUS_LOADING
		notification.AddProgress(msgid, 'Downloading ' .. data.title .. ' from workshop') if CLIENT and data

		fdir, fname = VLL2.FileSystem.StripFileName(filename)
		fadd = ''
		fadd = util.CRC(fdir) .. '_' if fdir ~= ''

		fpath = 'vll2/ws_cache/' .. fadd .. fname .. '.dat'

		if file.Exists(fpath, 'DATA')
			notification.Kill(msgid) if CLIENT
			@Msg('Found GMA in cache, mounting in-place...')
			@wscontentPath = 'data/' .. fpath
			@SpecifyPath(@wscontentPath)
			callback(@wscontentPath) if callback
			@__Mount()
			return

		if not game.IsDedicated() and SERVER
			@Msg('Singleplayer detected, waiting for client realm to download...')
			timer.Simple 1, ->
				net.Start('vll2.gma_notify')
				net.WriteUInt(@workshopID, 32)
				net.WriteString(@hcontent_file)
				net.Send(Entity(1))
			return

		@gmadownloader = VLL2.LargeFileLoader(url, fpath)

		@gmadownloader\AddFinishHook ->
			notification.Kill(msgid) if CLIENT
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

			@wscontentPath = 'data/' .. fpath
			@SpecifyPath(@wscontentPath)
			callback(@wscontentPath) if callback
			@__Mount()

		@gmadownloader\AddErrorHook (_, reason = 'failure') ->
			notification.Kill(msgid) if CLIENT
			@status = @@STATUS_ERROR
			@Msg('Failed to download the GMA! Reason: ' .. reason)
			@CallError()

		@Msg('Downloading ' .. @wsTitle .. '...')
		@gmadownloader\Load()

	@INVALID_WS_DATA = 912

	Load: =>
		@status = @@STATUS_LOADING

		if CLIENT and steamworks.IsSubscribed(tostring(@workshopID)) and not @loadLua
			@Msg('Not downloading addon ' .. @workshopID .. ' since it is already mounted on client.')
			@status = @@STATUS_LOADED
			return

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

			@Msg('Got info reply')

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
						@hcontent_file = item.hcontent_file

						if tobool(item.banned)
							@Msg('-----------------------------')
							@Msg('--- This workshop item was BANNED!')
							@Msg('--- Ban reason: ' .. (item.ban_reason or '<unknown>'))
							@Msg('--- But the addon will still be mounted though')
							@Msg('-----------------------------')

						if CLIENT
							if not DO_DOWNLOAD_WORKSHOP\GetBool()
								@Msg('Not downloading workshop GMA file, since we have it disabled')
								@status = @@STATUS_ERROR
								@CallError('Restricted by user')
							else
								@Msg('Downloading from workshop')

								@DownloadGMA item.file_url, item.filename, item, ->
									@Msg('Downloaded from workshop')

									if @shouldNotifyServerside
										net.Start('vll2.gma_notify')
										net.WriteUInt(@workshopID, 32)
										net.SendToServer()
										@Msg('Notifying server realm that we downloaded GMA.')
										@shouldNotifyServerside = false

									@__Mount()
						else
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
