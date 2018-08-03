
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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
