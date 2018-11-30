
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

_G = _G
import include, getfenv, setfenv, rawget, setmetatable from _G

includes = (val) => return true for val2 in *@ when val == val2

class VLL2.FileDef
	new: (fpath, vm) =>
		@vm = vm
		@fpath = fpath
		@canonized = VLL2.FileSystem.Canonize(fpath)
		@dir, @fname = VLL2.FileSystem.StripFileName(fpath)
		@localFS = @vm.localFS
		@globalFS = @vm.globalFS

	FileExists: (fpath) => fpath and (@localFS\Exists(fpath) or @globalFS and @globalFS\Exists(fpath))
	ReadFile: (fpath) =>
		return '' if not @FileExists(fpath)
		return @localFS\Read(fpath) if @localFS\Exists(fpath)
		return @globalFS\Read(fpath) if @globalFS and @globalFS\Exists(fpath)
		return ''

	Dir: (fpath) => @dir .. '/' .. fpath

	FindRelative: (fpath) =>
		canonize = VLL2.FileSystem.Canonize(fpath)
		return canonize if @FileExists(canonize)
		canonize = VLL2.FileSystem.Canonize(@dir .. '/' .. fpath)
		return canonize if @FileExists(canonize)

	FindFiles: (fpath) =>
		files, dirs = @localFS\Find(fpath)
		return files, dirs if not @globalFS
		files2, dirs2 = @globalFS\Find(fpath)
		table.insert(files, _file) for _file in *files2 when not includes(files, _file)
		table.insert(dirs, _dir) for _dir in *dirs2 when not includes(dirs, _dir)
		table.sort(files)
		table.sort(dirs)
		return files, dirs

	IsDir: (fpath) => @localFS\OpenRaw(fpath) ~= nil or @globalFS and @globalFS\OpenRaw(fpath) ~= nil

	Msg: (...) => VLL2.MessageVM(@vm.vmName .. ':' .. @fpath .. ':', ...)

class VLL2.VM
	new: (vmName, localFS, globalFS) =>
		@vmName = vmName
		@localFS = localFS
		@globalFS = globalFS

		@env = {k, v for k, v in pairs(VLL2.ENV_TEMPLATE)}
		@env.VLL2_VM = @

		@env._G = _G

	LoadAutorun: =>
		@RunFile('dlib/autorun/' .. fil) for fil in *@localFS\Find('dlib/autorun/*.lua')
		if SERVER then @RunFile('dlib/autorun/server/' .. fil) for fil in *@localFS\Find('dlib/autorun/server/*.lua')
		if CLIENT then @RunFile('dlib/autorun/client/' .. fil) for fil in *@localFS\Find('dlib/autorun/client/*.lua')

		@RunFile('autorun/' .. fil) for fil in *@localFS\Find('autorun/*.lua')
		if SERVER then @RunFile('autorun/server/' .. fil) for fil in *@localFS\Find('autorun/server/*.lua')
		if CLIENT then @RunFile('autorun/client/' .. fil) for fil in *@localFS\Find('autorun/client/*.lua')

	LoadEntities: =>
		pendingMeta = {}
		files, dirs = @localFS\Find('entities/*.lua')

		for _file in *files
			_G.ENT = {}
			ENT.Folder = 'entities'

			@RunFile('entities/' .. _file)

			ename = string.sub(_file, 1, -5)
			scripted_ents.Register(ENT, ename)
			baseclass.Set(ename, ENT)
			table.insert(pendingMeta, ename)
			_G.ENT = nil

		for _dir in *dirs
			hit = @localFS\Exists('entities/' .. _dir .. '/shared.lua') or
				@localFS\Exists('entities/' .. _dir .. '/init.lua') and SERVER or
				@localFS\Exists('entities/' .. _dir .. '/cl_init.lua') and CLIENT

			if hit
				_G.ENT = {}
				ENT.Folder = 'entities/' .. _dir

				@RunFile('entities/' .. _dir .. '/shared.lua') if @localFS\Exists('entities/' .. _dir .. '/shared.lua')
				@RunFile('entities/' .. _dir .. '/init.lua') if @localFS\Exists('entities/' .. _dir .. '/init.lua') and SERVER
				@RunFile('entities/' .. _dir .. '/cl_init.lua') if @localFS\Exists('entities/' .. _dir .. '/cl_init.lua') and CLIENT

				scripted_ents.Register(ENT, _dir)
				baseclass.Set(_dir, ENT)
				table.insert(pendingMeta, _dir)
				_G.ENT = nil

		VLL2.RecursiveMergeBase(meta) for _meta in *pendingMeta

	LoadEffects: =>
		files, dirs = @localFS\Find('effects/*.lua')

		for _file in *files
			_G.EFFECT = {}
			EFFECT.Folder = 'effects'
			@RunFile('effects/' .. _file)
			ename = string.sub(_file, 1, -5)
			effects.Register(EFFECT, ename)
			_G.EFFECT = nil

		for _dir in *dirs
			if @localFS\Exists('effects/' .. _dir .. '/init.lua')
				_G.EFFECT = {}
				EFFECT.Folder = 'effects/' .. _dir
				@RunFile('effects/' .. _dir .. '/init.lua')
				effects.Register(EFFECT, _dir)
				_G.EFFECT = nil

	LoadWeapons: =>
		pendingMeta = {}
		files, dirs = @localFS\Find('weapons/*.lua')

		for _file in *files
			_G.SWEP = {}
			SWEP.Folder = 'weapons'
			SWEP.Primary = {}
			SWEP.Secondary = {}

			@RunFile('weapons/' .. _file)

			ename = string.sub(_file, 1, -5)
			weapons.Register(SWEP, ename)
			baseclass.Set(ename, SWEP)
			table.insert(pendingMeta, ename)
			_G.SWEP = nil

		for _dir in *dirs
			hit = @localFS\Exists('weapons/' .. _dir .. '/shared.lua') or
				@localFS\Exists('weapons/' .. _dir .. '/init.lua') and SERVER or
				@localFS\Exists('weapons/' .. _dir .. '/cl_init.lua') and CLIENT

			if hit
				_G.SWEP = {}
				SWEP.Folder = 'weapons/' .. _dir
				SWEP.Primary = {}
				SWEP.Secondary = {}

				@RunFile('weapons/' .. _dir .. '/shared.lua') if @localFS\Exists('weapons/' .. _dir .. '/shared.lua')
				@RunFile('weapons/' .. _dir .. '/init.lua') if @localFS\Exists('weapons/' .. _dir .. '/init.lua') and SERVER
				@RunFile('weapons/' .. _dir .. '/cl_init.lua') if @localFS\Exists('weapons/' .. _dir .. '/cl_init.lua') and CLIENT

				weapons.Register(SWEP, _dir)
				baseclass.Set(_dir, SWEP)
				table.insert(pendingMeta, _dir)
				_G.SWEP = nil

		VLL2.RecursiveMergeBase(meta) for _meta in *pendingMeta

	__TFALoader: (fpath) =>
		files = @localFS\Find(fpath .. '/*')

		@RunFile(fpath .. '/' .. _file) for _file in *files when not _file\StartWith('cl_') and not _file\StartWith('sv_')
		@RunFile(fpath .. '/' .. _file) for _file in *files when _file\StartWith('cl_') and CLIENT or _file\StartWith('sv_') and SERVER

	LoadTFA: =>
		@__TFALoader('tfa/modules')
		@__TFALoader('tfa/external')
		files = @localFS\Find('tfa/att/*')
		TFAUpdateAttachments() if #files > 0

	Exists: (fpath) => @localFS\Exists(fpath) or @globalFS and @globalFS\Exists(fpath)

	NewEnv: (fpath) =>
		assert(type(fpath) ~= 'nil', 'No fpath were provided!')
		env = {k, v for k, v in pairs(@env)}
		env.VLL2_FILEDEF = type(fpath) == 'string' and VLL2.FileDef(fpath, @) or fpath

		setmetatable(env, {
			__index: _G
			__newindex: (key, value) => _G[key] = value
		})

		return env

	CompileString: (strIn, identifier = 'CompileString', fdef) =>
		assert(fdef, 'File definition from where CompileString was called must be present')
		fcall, ferrMsg = CompileString(strIn, identifier, false)

		if type(fcall) == 'string' or ferrMsg
			emsg = type(fcall) == 'string' and fcall or ferrMsg
			callable = () ->
				VLL2.MessageVM('Compilation failed for "CompileString" inside ' .. @vmName .. ':', emsg)
				string.gsub emsg, ':[0-9]+:', (w) ->
					fline = string.sub(w, 2, #w - 1)
					i = 0
					for line in string.gmatch(strIn, '\r?\n')
						i += 1
						if i == fline
							VLL2.MessageVM(line)
							break
				error(emsg)
			callable()
			return callable, false, emsg

		setfenv(fcall, @NewEnv(fdef))
		return fcall, true

	__CompileFileFallback: (fpath) =>
		cstatus, fcall = pcall(CompileFile, fpath)

		if not cstatus
			callable = () -> VLL2.MessageVM('Compilation failed for ' .. fpath .. ' inside ' .. @vmName)
			callable()
			return callable, false, fcall

		if not fcall
			callable = () ->
				VLL2.MessageVM('File is missing: ' .. fpath .. ' inside ' .. @vmName)
				nil
			callable()
			--return callable, false, 'Failed to include file: file not found'
			return callable, true

		setfenv(fcall, @NewEnv(fpath))
		return fcall, true

	Msg: (...) => VLL2.MessageVM(@vmName .. ': ', ...)

	RunFile: (fpath) =>
		fget, fstatus, ferror = @CompileFile(fpath)
		--error(ferror) if not fstatus
		VLL2.MessageVM(ferror) if not fstatus
		@Msg('Running file ' .. fpath)
		return fget()

	CompileFile: (fpath2) =>
		fpath = VLL2.FileSystem.Canonize(fpath2)
		return @__CompileFileFallback(fpath2) if not fpath

		local fread

		if @localFS\Exists(fpath)
			fread = @localFS\Read(fpath)
		elseif @globalFS and @globalFS\Exists(fpath)
			fread = @globalFS\Read(fpath)
		else
			return @__CompileFileFallback(fpath)

		if #fread < 10
			VLL2.MessageVM(@vmName, ' ', @localFS, ' ', @globalFS)
			VLL2.MessageVM(key, ' ', value) for key, value in pairs(@env)
			VLL2.MessageVM('-----------------')
			VLL2.MessageVM(fread)
			VLL2.MessageVM('-----------------')
			error('wtf')

		fcall = CompileString(fread, '[VLL2:VM:' .. @vmName .. ':' .. fpath .. ']', false)

		if type(fcall) == 'string'
			callable = () ->
				VLL2.MessageVM('Compilation failed for ' .. fpath .. ' inside ' .. @vmName)
				string.gsub fcall, ':[0-9]+:', (w) ->
					fline = string.sub(w, 2, #w - 1)
					i = 0
					for line in string.gmatch(fread, '\r?\n')
						i += 1
						if i == fline
							VLL2.MessageVM(line)
							break
			callable()
			return callable, false, fcall

		setfenv(fcall, @NewEnv(fpath2))
		return fcall, true
