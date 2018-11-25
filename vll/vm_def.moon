
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

import getfenv, assert, error, rawset, setfenv from _G

getvm = ->
	fret = getfenv(3).VLL2_VM or getfenv(2).VLL2_VM or getfenv(4).VLL2_VM
	if not fret
		VLL2.Message(getfenv(3), ' ', getfenv(2), ' ', getfenv(1))
		error('INVALID LEVEL OF CALL?!')

	return fret
getdef = ->
	fret = getfenv(3).VLL2_FILEDEF or getfenv(4).VLL2_FILEDEF or getfenv(2).VLL2_FILEDEF
	if not fret
		VLL2.Message(getfenv(3), ' ', getfenv(2), ' ', getfenv(1))
		error('INVALID LEVEL OF CALL?!')
	return fret

VLL2.ENV_TEMPLATE = {
	AddCSLuaFile: (fpath) ->
		return if not fpath
		def = getdef()
		return if def\FindRelative(fpath)
		return if file.Exists(fpath, 'LUA')
		canonize = VLL2.FileSystem.Canonize(def\Dir(fpath))
		return if file.Exists(canonize, 'LUA')
		def\Msg('Unable to find specified file for AddCSLuaFile: ' .. fpath)

	module: (moduleName, ...) ->
		assert(type(moduleName) == 'string', 'Invalid module name')
		allowGlobals = false
		mtab = _G[moduleName] or {}
		_G[moduleName] = mtab

		_env = getfenv(1)

		env = {
			VLL2_VM: getvm()
			VLL2_FILEDEF: getdef()
			__index: (key) =>
				return mtab[key] if mtab[key] ~= nil
				return _env[key] if allowGlobals
				return rawget(@, key)
			__newindex: (key, value) => mtab[key] = value
		}

		for fcall in *{...}
			if fcall == package.seeall
				allowGlobals = true
			else
				fcall(mtab)

		setfenv(1, env)

	setfenv: (func, env) ->
		assert(type(env) == 'table', 'Invalid function environment')
		rawset(env, 'VLL2_VM', getvm())
		rawset(env, 'VLL2_FILEDEF', getdef())
		return setfenv(func, env)

	require: (fpath) ->
		assert(type(fpath) == 'string', 'Invalid path')
		vm = getvm()
		if vm\Exists('includes/modules/' .. fpath .. '.lua')
			fget, fstatus, ferror = vm\CompileFile(canonize or fpath)
			assert(fstatus, ferror, 2)
			return fget()
		else
			return require(fpath)

	include: (fpath) ->
		assert(type(fpath) == 'string', 'Invalid path')
		vm = getvm()
		def = getdef()
		assert(vm, 'Missing VM. File: ' .. fpath)
		assert(def, 'Missing file def. File: ' .. fpath)
		canonize = def\FindRelative(fpath)
		vm\Msg('Running file ' .. (canonize or fpath))
		fget, fstatus, ferror = vm\CompileFile(canonize or fpath)
		assert(fstatus, ferror)
		return fget()

	CompileFile: (fpath) ->
		assert(type(fpath) == 'string', 'Invalid path')
		vm = getvm()
		def = getdef()
		canonize = def\FindRelative(fpath)
		vm\Msg('Compiling file ' .. (canonize or fpath))
		fget, fstatus, ferror = vm\CompileFile(canonize or fpath)
		assert(fstatus, ferror)
		return fget

	CompileString: (strIn, identifier, handle = true) ->
		assert(identifier, 'Missing identifier', 2)
		vm = getvm()
		fget, fstatus, ferror = vm\CompileString(strIn, identifier, getdef())
		return ferror if not handle and not fstatus
		error(ferror, 2) if handle and not fstatus
		return fget

	RunString: (strIn, identifier = 'RunString', handle = true) ->
		vm = getvm()
		fget, fstatus, ferror = vm\CompileString(strIn, identifier, getdef())
		return ferror if not handle and not fstatus
		error(ferror, 2) if handle and not fstatus
		fget()
		nil
}

import rawget, file from _G

VLL2.ENV_TEMPLATE.file = {
	Exists: (fpath, fmod) ->
		assert(fmod, 'Invalid FMOD provided')
		return file.Exists(fpath, fmod) if fmod\lower() ~= 'lua'
		return getdef()\FileExists(fpath) or file.Exists(fpath, fmod)

	Read: (fpath, fmod = 'DATA') ->
		return file.Read(fpath, fmod) if fmod\lower() ~= 'lua'
		return getdef()\ReadFile(fpath)

	Find: (fpath, fmod) ->
		assert(fmod, 'Invalid FMOD provided')
		return file.Find(fpath, fmod) if fmod\lower() ~= 'lua'
		return getdef()\FindFiles(fpath)

	IsDir: (fpath, fmod) ->
		assert(fmod, 'Invalid FMOD provided')
		return file.IsDir(fpath, fmod) if fmod\lower() ~= 'lua'
		return getdef()\IsDir(fpath)
}

-- wtf
VLL2.ENV_TEMPLATE.file[k] = v for k, v in pairs(file) when VLL2.ENV_TEMPLATE.file[k] == nil

setmetatable(VLL2.ENV_TEMPLATE.file, {
	__index: file
	__newindex: file
})
