
-- Copyright (C) 2017-2018 DBot

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


function DLib.registerSV(fil)
	local result = include('dlib/' .. fil)
	if not result then return end
	return result.register()
end

local MsgC = MsgC
local SysTime = SysTime
local timeStart = SysTime()

MsgC('[DLib] Initializing DLib serverside ... ')

CreateConVar('sv_dlib_hud_shift', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'SV Override: Enable HUD shifting')

AddCSLuaFile('dlib/modules/notify/client/cl_init.lua')
DLib.Loader.loadPureCSTop('dlib/modules/hudcommons')
DLib.Loader.loadPureCSTop('dlib/modules/hudcommons/base')

DLib.Loader.csModule('dlib/modules/notify/client')
DLib.Loader.svmodule('notify/sv_dnotify.lua')
DLib.Loader.csModule('dlib/util/client')
DLib.Loader.csModule('dlib/modules/client')
DLib.Loader.loadPureSVTop('dlib/modules/server')
DLib.Loader.svmodule('dmysql.lua')

DLib.Loader.loadPureCS('dlib/vgui')
DLib.registerSV('util/server/chat.lua')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
MsgC('[DLib] Running addons ... \n')

if not VLL_CURR_FILE then
	DLib.Loader.loadPureSHTop('dlib/autorun')
	DLib.Loader.loadPureSVTop('dlib/autorun/server')
	DLib.Loader.loadPureCSTop('dlib/autorun/client')
end

MsgC(string.format('[DLib] Addons were initialized in %.2f ms\n', (SysTime() - timeStart) * 1000))

timeStart = SysTime()
MsgC('[DLib] Loading translations for i18n ... ')

DLib.i18n.refreshFileList()
DLib.i18n.loadFileList()

hook.Run('DLib.TranslationsReloaded')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))

MsgC('---------------------------------------------------------------\n')
