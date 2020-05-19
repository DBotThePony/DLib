
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
		@SaveCache()
		@CallLoaded()
		return if not @initAfterLoad
		@Run()

	DownloadFile: (fpath, url, fstamp) =>
		if SERVER and @cDownloading >= 16 or CLIENT and @cDownloading >= 48
			table.insert(@downloadQueue, {fpath, url, fstamp})
			return

		@DownloadNextFile(fpath, url, fstamp)
		return @

	__DownloadCallback: =>
		return if #@downloadQueue == 0
		{fpath, url, fstamp} = table.remove(@downloadQueue)
		@DownloadNextFile(fpath, url, fstamp)

	DownloadNextFile: (fpath, url, fstamp) =>
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
			@SaveCache()
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
			@WriteToCache(fpath, fstamp, body)
			@CheckIfRunnable()

		HTTP(req)

	LoadFromList: (bundle = @bundleList) =>
		@toDownload = #@bundleList
		@downloaded = 0

		lines = [string.Explode(';', line) for line in *@bundleList when line ~= '']

		for {fpath, url, fstamp} in *lines
			fstamp = tonumber(fstamp)
			if not url
				VLL2.MessageBundle(fpath, url, fstamp)
				error('wtf')

			fromCache = @GetFromCache(fpath, fstamp)

			if fromCache
				@fs\Write(fpath, fromCache)
				@globalFS\Write(fpath, fromCache)
				@downloaded += 1
			else
				@DownloadFile(fpath, url, fstamp)

		@Msg(@downloaded .. ' files are present in cache and are fresh')
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
