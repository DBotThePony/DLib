
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

if SERVER
	util.AddNetworkString('vll2.replicate_url')
	util.AddNetworkString('vll2.replicate_urlgma')
	util.AddNetworkString('vll2.replicate_urlgmaz')
	util.AddNetworkString('vll2.replicate_workshop')
	util.AddNetworkString('vll2.replicate_wscollection')
	util.AddNetworkString('vll2.replicate_github')
	util.AddNetworkString('vll2.replicate_gitlab')
	util.AddNetworkString('vll2.replicate_all')
else
	VLL2.DO_DOWNLOAD_WORKSHOP = CreateConVar('vll2_dl_workshop', '1', {FCVAR_ARCHIVE}, 'Actually download GMA files. Disabling this is VERY experemental, and can cause undesired behaviour of stuff. You were warned.')
	cvars.AddChangeCallback 'vll2_dl_workshop', (-> RunConsoleCommand('host_writeconfig')), 'VLL2'

file.CreateDir('vll2')
file.CreateDir('vll2/ws_cache')
file.CreateDir('vll2/gma_cache')
file.CreateDir('vll2/luapacks')
file.CreateDir('vll2/git_luapacks')

sql.Query('DROP TABLE vll2_lua_cache')

class VLL2.AbstractBundle
	@_S = {}
	@LISTING = {}
	@STATUS_NONE = 0
	@STATUS_LOADING = 1
	@STATUS_LOADED = 2
	@STATUS_RUNNING = 3
	@STATUS_ERROR = 4

	@Checkup = (bname) =>
		return true if not @_S[bname]
		return not @_S[bname]\IsLoading()

	new: (name) =>
		@name = name
		@@_S[name] = @
		@@LISTING[name] = @
		@status = @@STATUS_NONE
		@fs = VLL2.FileSystem()
		@globalFS = VLL2.FileSystem.INSTANCE
		@initAfterLoad = true
		@replicated = true
		@dirtyCache = false
		@errorCallbacks = {}
		@finishCallbacks = {}
		@loadCallbacks = {}

		@cache = {}

		if @cacheExists = file.Exists(@GetCachePath(), 'DATA')
			success = ProtectedCall ->
				with fStream = file.Open(@GetCachePath(), 'rb', 'DATA')
					fsize = \Size()

					while \Tell() < fsize
						pathLen = \ReadUShort()
						path = \Read(pathLen)
						fstamp = \ReadULong()
						bodyLen = \ReadULong()
						body = \Read(bodyLen)
						@cache[path] = {:fstamp, :body}

					\Close()

			if not success
				VLL2.Message('Unable to read from file cache! Looks like your files got corrupted...')
				@cache = {}
				file.Delete(@GetCachePath())


	GetCachePath: => 'vll2/luapacks/' .. util.CRC(@name) .. '.dat'
	SaveCache: =>
		return if not @dirtyCache

		file.Delete(@GetCachePath()) if @cacheExists

		with fStream = file.Open(@GetCachePath(), 'wb', 'DATA')
			error('Failed to open ' .. @GetCachePath() .. ' for writing cache. Is disk full?') if not fStream

			for path, {:fstamp, :body} in pairs(@cache)
				\WriteUShort(#path)
				\Write(path)
				\WriteULong(fstamp)
				\WriteULong(#body)
				\Write(body)

			\Close()

		@dirtyCache = false

	GetFromCache: (path, fstamp) =>
		return if not @cache[path] or @cache[path].fstamp < fstamp
		return @cache[path].body

	WriteToCache: (path, fstamp, body) =>
		@cache[path] = {:fstamp, :body}
		@dirtyCache = true
		return @

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
		vm\LoadToolguns()
		vm\LoadTFA()
		@Msg('Bundle successfully initialized!')
		@CallFinish()

	Load: => error('Not implemented')

if SERVER
	net.Receive 'vll2.replicate_all', (len, ply) -> bundle\Replicate(ply) for _, bundle in pairs(VLL2.AbstractBundle._S) when bundle\IsReplicated()
else
	timer.Simple 5, ->
		net.Start('vll2.replicate_all')
		net.SendToServer()
