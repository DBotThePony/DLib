
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

DLib.MessageNoNL('Initializing DLib clientside ... ')

DLib.Notify = DLib.Notify or {}
include('dlib/modules/notify/client/cl_init.lua')
include('dlib/modules/notify/client/font_obj.lua')
include('dlib/modules/notify/client/base_class.lua')
include('dlib/modules/notify/client/templates.lua')
include('dlib/modules/notify/client/animated_base.lua')
include('dlib/modules/notify/client/slide_class.lua')
include('dlib/modules/notify/client/centered_class.lua')
include('dlib/modules/notify/client/badges.lua')
include('dlib/modules/notify/client/legacy.lua')

function DLib.GetSkin()
	return 'DLib_Black'
end

DLib.HUDCommons = DLib.HUDCommons or {}

DLib.ClientInclude('modules/hudcommons/advanced_draw.lua')
DLib.ClientInclude('modules/hudcommons/colors.lua')
DLib.ClientInclude('modules/hudcommons/functions.lua')
DLib.ClientInclude('modules/hudcommons/hl2icons.lua')
DLib.ClientInclude('modules/hudcommons/matrix.lua')
DLib.ClientInclude('modules/hudcommons/menu.lua')
DLib.ClientInclude('modules/hudcommons/poly.lua')
DLib.ClientInclude('modules/hudcommons/position.lua')
DLib.ClientInclude('modules/hudcommons/position2.lua')
DLib.ClientInclude('modules/hudcommons/simple_draw.lua')
DLib.ClientInclude('modules/hudcommons/stencil.lua')
DLib.ClientInclude('modules/hudcommons/stripped.lua')
DLib.ClientInclude('modules/hudcommons/pattern.lua')
DLib.ClientInclude('modules/hudcommons/base/init.lua')
DLib.ClientInclude('modules/hudcommons/base/functions.lua')
DLib.ClientInclude('modules/hudcommons/base/variables.lua')
DLib.ClientInclude('modules/hudcommons/base/defaultvars.lua')
DLib.ClientInclude('modules/hudcommons/base/logic.lua')
DLib.ClientInclude('modules/hudcommons/base/wepselect.lua')
DLib.ClientInclude('modules/hudcommons/base/crosshairs.lua')
DLib.ClientInclude('modules/hudcommons/base/menus.lua')

DLib.ClientInclude('vgui/avatar.lua')
DLib.ClientInclude('vgui/button_layout.lua')
DLib.ClientInclude('vgui/colormixer.lua')
DLib.ClientInclude('vgui/dtextentry.lua')
DLib.ClientInclude('vgui/dtextinput.lua')
DLib.ClientInclude('vgui/extendedmenu.lua')
DLib.ClientInclude('vgui/player_button.lua')

DLib.ClientInclude('vgui/skin.lua')
DLib.ClientInclude('vgui/skin/hooks.lua')
DLib.ClientInclude('vgui/skin/icons.lua')
DLib.ClientInclude('vgui/skin/colours.lua')
DLib.ClientInclude('vgui/skin/draw/buttons.lua')
DLib.ClientInclude('vgui/skin/draw/common.lua')
DLib.ClientInclude('vgui/skin/draw/gwen.lua')
DLib.ClientInclude('vgui/skin/draw/menus.lua')
DLib.ClientInclude('vgui/skin/draw/util.lua')
DLib.ClientInclude('vgui/skin/draw/window.lua')

DLib.ClientInclude('vgui/util.lua')
DLib.ClientInclude('vgui/window.lua')
DLib.ClientInclude('vgui/filebrowser.lua')

DLib.ClientInclude('util/client/scrsize.lua')
DLib.ClientInclude('util/client/chat.lua')
DLib.ClientInclude('util/client/buystuff.lua')
DLib.ClientInclude('util/client/donate.lua')
DLib.ClientInclude('util/client/ttfreader.lua')
DLib.ClientInclude('util/client/matnotify.lua')
DLib.ClientInclude('util/client/blur.lua')
DLib.ClientInclude('util/client/menu.lua')
DLib.ClientInclude('util/client/displayprogress.lua')
DLib.ClientInclude('util/client/performance.lua')

DLib.ClientInclude('modules/client/friendstatus.lua')
DLib.ClientInclude('modules/client/lastnick.lua')

DLib.MessageNoPrefix(string.format('%.2f ms', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
DLib.Message('Running addons ...')

if not VLL_CURR_FILE and not VLL2_FILEDEF then
	DLib.Loader.SharedLoad('dlib/autorun')
	DLib.Loader.ClientLoad('dlib/autorun/client')
end

DLib.Message(string.format('Addons were initialized in %.2f ms', (SysTime() - timeStart) * 1000))

timeStart = SysTime()
DLib.MessageNoNL('Loading translations for i18n ... ')

DLib.I18n.Reload()

concommand.Add('dlib_reload_i18n_cl', function(ply)
	timeStart = SysTime()
	DLib.Message('Reloading translations for i18n ... ')
	DLib.I18n.Reload()
	hook.Run('DLib.TranslationsReloaded')
	DLib.Message(string.format('i18n reload took %.2f ms', (SysTime() - timeStart) * 1000))
end)

hook.Run('DLib.TranslationsReloaded')

DLib.MessageNoPrefix(string.format('%.2f ms', (SysTime() - timeStart) * 1000))

MsgC('---------------------------------------------------------------\n')
