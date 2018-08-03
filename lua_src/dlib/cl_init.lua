
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

local MsgC = MsgC
local SysTime = SysTime
local timeStart = SysTime()

MsgC('[DLib] Initializing DLib clientside ... ')

DLib.Loader.start('Notify', true)
DLib.Loader.include('dlib/modules/notify/client/cl_init.lua')
DLib.Loader.finish(false)

function DLib.GetSkin()
	return 'DLib_Black'
end

DLib.Loader.start('HUDCommons')
DLib.Loader.loadPureCSTop('dlib/modules/hudcommons')
DLib.simpleInclude('modules/hudcommons/base/init.lua')
DLib.Loader.finish()

DLib.Loader.loadPureCS('dlib/vgui')
DLib.register('util/client/scrsize.lua')
DLib.register('util/client/chat.lua')
DLib.register('util/client/buystuff.lua')
DLib.register('util/client/donate.lua')

DLib.Loader.loadPureCSTop('dlib/modules/client')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
MsgC('[DLib] Running addons ... \n')

if not VLL_CURR_FILE then
	DLib.Loader.loadPureSHTop('dlib/autorun')
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
