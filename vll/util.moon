
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

import VLL2, baseclass, table, string, assert, type from _G

VLL2.RecursiveMergeBase = (mergeMeta) ->
	return if not mergeMeta
	metaGet = baseclass.Get(mergeMeta)
	return if not metaGet.Base
	return if metaGet.Base == mergeMeta
	VLL2.RecursiveMergeBase(metaGet.Base)
	metaBase = baseclass.Get(metaGet.Base)
	metaGet[key] = value for key, value in pairs(metaBase) when metaGet[key] == nil

-- Easy to access functions
-- for those who want to use features without creating classes
VLL2.API = {
	LoadBundle: (bundleName, silent = false, replicate = true) ->
		assert(type(bundleName) == 'string', 'Bundle name must be a string')
		fbundle = VLL2.URLBundle(bundleName\lower())
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshopContent: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSBundle(wsid)
		fbundle\Load()
		fbundle\DoNotLoadLua()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadURLContent: (name, url, silent = false, replicate = true) ->
		assert(type(name) == 'string', 'Bundle name must be a string')
		assert(type(url) == 'string', 'Bundle url must be a string')
		fbundle = VLL2.URLGMABundle(name, url)
		fbundle\Load()
		fbundle\DoNotLoadLua()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadURLGMA: (name, url, silent = false, replicate = true) ->
		assert(type(name) == 'string', 'Bundle name must be a string')
		assert(type(url) == 'string', 'Bundle url must be a string')
		fbundle = VLL2.URLGMABundle(name, url)
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadURLContentZ: (name, url, silent = false, replicate = true) ->
		assert(type(name) == 'string', 'Bundle name must be a string')
		assert(type(url) == 'string', 'Bundle url must be a string')
		fbundle = VLL2.URLGMABundleZ(name, url)
		fbundle\Load()
		fbundle\DoNotLoadLua()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadURLGMAZ: (name, url, silent = false, replicate = true) ->
		assert(type(name) == 'string', 'Bundle name must be a string')
		assert(type(url) == 'string', 'Bundle url must be a string')
		fbundle = VLL2.URLGMABundleZ(name, url)
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshopCollection: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSCollection(wsid)
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshopCollectionContent: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSCollection(wsid)
		fbundle\Load()
		fbundle\DoNotLoadLua()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle

	LoadWorkshop: (wsid, silent = false, replicate = true) ->
		assert(type(wsid) == 'string', 'Bundle wsid must be a string')
		wsid = tostring(math.floor(assert(tonumber(wsid), 'Bundle wsid must represent a valid number within string!')))
		fbundle = VLL2.WSBundle(wsid)
		fbundle\Load()
		fbundle\Replicate() if not silent
		fbundle\SetReplicate(replicate)
		return fbundle
}

class VLL2.LargeFileLoader
	@PENDING = {}

	@STATUS_NONE = 0
	@STATUS_GETTING_INFO = 1
	@STATUS_WAITING = 2
	@STATUS_ERROR = 3
	@STATUS_DOWNLOADING = 4
	@STATUS_FINISHED = 5

	IsIdle: => @status == @@STATUS_NONE
	IsGettingInfo: => @status == @@STATUS_GETTING_INFO
	IsWaiting: => @status == @@STATUS_WAITING
	IsErrored: => @status == @@STATUS_ERROR
	IsDownloading: => @status == @@STATUS_DOWNLOADING
	IsFinished: => @status == @@STATUS_FINISHED

	@MIN_PART_SIZE = 1024 * 1024
	@MAX_PART_SIZE = 1024 * 1024 * 4
	@MAX_MEM_SIZE = 1024 * 1024 * 64

	@Recalc = =>
		for instance in *@PENDING
			return if instance\IsDownloading()

		for instance in *@PENDING
			if instance\IsWaiting()
				instance\Download()
				return

	new: (urlFrom, fileOutput) =>
		@url = urlFrom
		@outputPath = fileOutput
		@params = {}
		@currentMemSize = 0
		@downloaded = 0
		@length = -1
		@inProgressParts = 0
		@status = @@STATUS_NONE
		@nextParts = {}
		@success = {}
		@failure = {}
		table.insert(@@PENDING, @)

	Msg: (...) => VLL2.MessageDL(...)

	AddFinishHook: (fcall) =>
		table.insert(@success, fcall)
		return @

	AddErrorHook: (fcall) =>
		table.insert(@failure, fcall)
		return @

	CallFinish: (...) => fcall(@, ...) for fcall in *@success
	CallError: (...) => fcall(@, ...) for fcall in *@failure

	LoadNextPart: =>
		rem = table.remove(@nextParts, 1)
		return @DownloadPart(rem) if rem
		if @inProgressParts ~= 0
			@Msg('Downloaded ' .. string.NiceSize(@downloaded) .. ' / ' .. string.NiceSize(@length) .. ' of ' .. @url)
			return
		@status = @@STATUS_FINISHED
		@fstream\Flush()
		@fstream\Close()
		@Msg('File ' .. @url .. ' got downloaded and saved!')
		@CallFinish()
		@@Recalc()

	DownloadPart: (partid) =>
		assert(partid <= @parts, 'Invalid partid')
		table.remove(@nextParts, i) for i, part in ipairs(@nextParts) when part == partid
		@inProgressParts += 1
		bytesStart, bytesEnd = partid * @partlen, math.min(@length - 1, (partid + 1) * @partlen - 1)

		@currentMemSize += @partlen

		req = {
			method: 'GET'
			url: @url
			headers: {
				'User-Agent': 'VLL2'
				'Range': 'bytes=' .. bytesStart .. '-' .. bytesEnd
				Referer: VLL2.Referer()
			}
		}

		req.failed = (reason = 'failure') ->
			return if @status == @@STATUS_ERROR
			@Msg('Failed to GET the part of file! ' .. @url .. ' part ' .. partid .. ' out from ' .. @parts)
			@Msg('Reason: ' .. reason)
			@status = @@STATUS_ERROR
			@CallError(reason)
			@@Recalc()

		req.success = (code = 400, body = '', headers) ->
			return if @status == @@STATUS_ERROR
			if code ~= 206 and code ~= 200
				@Msg('Failed to GET the part of file! ' .. @url .. ' part ' .. partid .. ' out from ' .. @parts)
				@Msg('Server replied: ' .. code)
				@status = @@STATUS_ERROR
				@CallError('Server replied: ' .. code)
				@@Recalc()
				return

			for hname, hvalue in pairs(headers)
				if hname\lower() == 'content-length'
					if tonumber(hvalue) ~= bytesEnd - bytesStart + 1
						@Msg('Failed to GET the part of file! ' .. @url .. ' part ' .. partid .. ' out from ' .. @parts)
						@Msg('EXPECTED (REQUESTED) LENGTH: ' .. bytesEnd - bytesStart)
						@Msg('ACTUAL LENGTH REPORTED BY THE SERVER: ' .. hvalue)
						@status = @@STATUS_ERROR
						@CallError('Length mismatch')
						@@Recalc()
						return

			@downloaded += bytesEnd - bytesStart + 1
			@fstream\Seek(bytesStart)
			@fstream\Write(body)
			@fstream\Flush()
			@inProgressParts -= 1
			@LoadNextPart()

		HTTP(req)

	Download: =>
		file.Delete(@outputPath)
		@fstream = file.Open(@outputPath, 'wb', 'DATA')
		@status = @@STATUS_DOWNLOADING

		@Msg('Allocating disk space for ' .. @url .. ', this can take some time...')
		@fstream\WriteULong(0) for i = 1, (@length - @length % 4) / 4
		@fstream\WriteByte(0) for i = 1, @length % 4

		@nextParts = [i for i = 0, @parts - 1]

		for i = 0, @parts - 1
			@DownloadPart(i)
			break if @currentMemSize >= @@MAX_MEM_SIZE

	CalcParts: =>
		partlen = math.ceil(@length / 16)

		if partlen < @@MIN_PART_SIZE
			partlen = @@MIN_PART_SIZE

		if partlen > @@MAX_PART_SIZE
			partlen = @@MAX_PART_SIZE

		@parts = math.ceil(@length / partlen)
		@partlen = partlen

	Load: => @GetInfo()

	GetInfo: =>
		@status = @@STATUS_GETTING_INFO

		req = {
			method: 'HEAD'
			url: @url
			headers: {
				'User-Agent': 'VLL2'
				Referer: VLL2.Referer()
			}
		}

		req.failed = (reason = 'failure') ->
			@Msg('Failed to HEAD the url! ' .. @url)
			@Msg('Reason: ' .. reason)
			@status = @@STATUS_ERROR
			@CallError(reason)
			@@Recalc()

		req.success = (code = 400, body = '', headers) ->
			if code ~= 200
				@Msg('Failed to HEAD the url! ' .. @url)
				@Msg('Server replied: ' .. code)
				@status = @@STATUS_ERROR
				@CallError('Server replied: ' .. code)
				@@Recalc()
				return

			@headers = headers

			for hname, hvalue in pairs(headers)
				if hname\lower() == 'content-length'
					@length = tonumber(hvalue)
					@CalcParts()
					break

			if @length == -1
				@Msg('Server did not provided content-length header on HEAD request')
				@Msg(@url)
				@Msg('Load can not continue')
				@status = @@STATUS_ERROR
				@CallError('Server lacks content-length')
				@@Recalc()
				return

			@status = @@STATUS_WAITING
			@@Recalc()

		HTTP(req)
