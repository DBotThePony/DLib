
-- Copyright (C) 2017-2020 DBotThePony

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

local SysTime = SysTime
local timeStart = SysTime()

DLib.MessageNoNL('Initializing DLib serverside ... ')

CreateConVar('sv_dlib_hud_shift', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'SV Override: Enable HUD shifting')

AddCSLuaFile('dlib/modules/notify/client/cl_init.lua')
AddCSLuaFile('dlib/modules/hudcommons/advanced_draw.lua')
AddCSLuaFile('dlib/modules/hudcommons/colors.lua')
AddCSLuaFile('dlib/modules/hudcommons/functions.lua')
AddCSLuaFile('dlib/modules/hudcommons/hl2icons.lua')
AddCSLuaFile('dlib/modules/hudcommons/matrix.lua')
AddCSLuaFile('dlib/modules/hudcommons/menu.lua')
AddCSLuaFile('dlib/modules/hudcommons/poly.lua')
AddCSLuaFile('dlib/modules/hudcommons/position.lua')
AddCSLuaFile('dlib/modules/hudcommons/position2.lua')
AddCSLuaFile('dlib/modules/hudcommons/simple_draw.lua')
AddCSLuaFile('dlib/modules/hudcommons/stencil.lua')
AddCSLuaFile('dlib/modules/hudcommons/stripped.lua')
AddCSLuaFile('dlib/modules/hudcommons/pattern.lua')

AddCSLuaFile('dlib/modules/hudcommons/base/crosshairs.lua')
AddCSLuaFile('dlib/modules/hudcommons/base/defaultvars.lua')
AddCSLuaFile('dlib/modules/hudcommons/base/functions.lua')
AddCSLuaFile('dlib/modules/hudcommons/base/init.lua')
AddCSLuaFile('dlib/modules/hudcommons/base/logic.lua')
AddCSLuaFile('dlib/modules/hudcommons/base/menus.lua')
AddCSLuaFile('dlib/modules/hudcommons/base/variables.lua')
AddCSLuaFile('dlib/modules/hudcommons/base/wepselect.lua')

AddCSLuaFile('dlib/modules/notify/client/animated_base.lua')
AddCSLuaFile('dlib/modules/notify/client/badges.lua')
AddCSLuaFile('dlib/modules/notify/client/base_class.lua')
AddCSLuaFile('dlib/modules/notify/client/centered_class.lua')
AddCSLuaFile('dlib/modules/notify/client/cl_init.lua')
AddCSLuaFile('dlib/modules/notify/client/font_obj.lua')
AddCSLuaFile('dlib/modules/notify/client/legacy.lua')
AddCSLuaFile('dlib/modules/notify/client/slide_class.lua')
AddCSLuaFile('dlib/modules/notify/client/templates.lua')

AddCSLuaFile('dlib/util/client/blur.lua')
AddCSLuaFile('dlib/util/client/buystuff.lua')
AddCSLuaFile('dlib/util/client/chat.lua')
AddCSLuaFile('dlib/util/client/donate.lua')
AddCSLuaFile('dlib/util/client/localglobal.lua')
AddCSLuaFile('dlib/util/client/matnotify.lua')
AddCSLuaFile('dlib/util/client/scrsize.lua')
AddCSLuaFile('dlib/util/client/ttfreader.lua')
AddCSLuaFile('dlib/util/client/menu.lua')
AddCSLuaFile('dlib/util/client/displayprogress.lua')
AddCSLuaFile('dlib/util/client/performance.lua')

AddCSLuaFile('dlib/modules/client/friendstatus.lua')
AddCSLuaFile('dlib/modules/client/lastnick.lua')

include('modules/notify/sv_dnotify.lua')

include('modules/server/dmysql4.lua')
include('modules/server/dmysql4_bake.lua')
include('modules/server/dmysql.lua')
include('modules/server/friendstatus.lua')

AddCSLuaFile('dlib/vgui/avatar.lua')
AddCSLuaFile('dlib/vgui/button_layout.lua')
AddCSLuaFile('dlib/vgui/colormixer.lua')
AddCSLuaFile('dlib/vgui/dtextentry.lua')
AddCSLuaFile('dlib/vgui/dtextinput.lua')
AddCSLuaFile('dlib/vgui/extendedmenu.lua')
AddCSLuaFile('dlib/vgui/player_button.lua')
AddCSLuaFile('dlib/vgui/skin/colours.lua')
AddCSLuaFile('dlib/vgui/skin/draw/buttons.lua')
AddCSLuaFile('dlib/vgui/skin/draw/common.lua')
AddCSLuaFile('dlib/vgui/skin/draw/gwen.lua')
AddCSLuaFile('dlib/vgui/skin/draw/menus.lua')
AddCSLuaFile('dlib/vgui/skin/draw/util.lua')
AddCSLuaFile('dlib/vgui/skin/draw/window.lua')
AddCSLuaFile('dlib/vgui/skin/hooks.lua')
AddCSLuaFile('dlib/vgui/skin/icons.lua')
AddCSLuaFile('dlib/vgui/skin.lua')
AddCSLuaFile('dlib/vgui/util.lua')
AddCSLuaFile('dlib/vgui/window.lua')
AddCSLuaFile('dlib/vgui/filebrowser.lua')

include('dlib/util/server/chat.lua')

DLib.MessageNoPrefix(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
DLib.Message('Running addons ...')

if not VLL_CURR_FILE and not VLL2_FILEDEF then
	DLib.Loader.SharedLoad('dlib/autorun')
	DLib.Loader.ServerLoad('dlib/autorun/server')
	DLib.Loader.ClientLoad('dlib/autorun/client')
end

DLib.Message(string.format('Addons were initialized in %.2f ms', (SysTime() - timeStart) * 1000))

timeStart = SysTime()
DLib.MessageNoNL('[DLib] Loading translations for i18n ... ')

DLib.I18n.Reload()

concommand.Add('dlib_reload_i18n', function(ply)
	if IsValid(ply) then return end
	timeStart = SysTime()

	DLib.Message('Reloading translations for i18n ... ')
	DLib.I18n.Reload()
	hook.Run('DLib.TranslationsReloaded')
	DLib.Message(string.format('i18n reload took %.2f ms', (SysTime() - timeStart) * 1000))
end)

hook.Run('DLib.TranslationsReloaded')

DLib.MessageNoPrefix(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))

MsgC('---------------------------------------------------------------\n')
