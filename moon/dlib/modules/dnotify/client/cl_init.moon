
--
-- Copyright (C) 2017 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

export DNotify
export DNOTIFY_SIDE_LEFT
export DNOTIFY_SIDE_RIGHT
export DNOTIFY_POS_TOP
export DNOTIFY_POS_BOTTOM

DNotify = {}
DNotify.DefaultDispatchers = {}

X_SHIFT_CVAR = CreateConVar('dnofity_x_shift', '0', {FCVAR_ARCHIVE}, 'Shift at X of DNotify slide notifications')
Y_SHIFT_CVAR = CreateConVar('dnofity_y_shift', '45', {FCVAR_ARCHIVE}, 'Shift at Y of DNotify slide notifications')

DNOTIFY_SIDE_LEFT = 1
DNOTIFY_SIDE_RIGHT = 2
DNOTIFY_POS_TOP = 3
DNOTIFY_POS_BOTTOM = 4

DNotify.newLines = (str = '') -> string.Explode('\n', str)
DNotify.allowedOrigin = (enum) ->
	enum == TEXT_ALIGN_LEFT or
	enum == TEXT_ALIGN_RIGHT or
	enum == TEXT_ALIGN_CENTER

DNotify.Clear = -> for i, obj in pairs DNotify.DefaultDispatchers do obj\Clear!

DNotify.CreateSlide = (...) ->
	DNotify.CreateDefaultDispatchers() if not DNotify.DefaultDispatchers or not IsValid(DNotify.DefaultDispatchers.slide)
	DNotify.DefaultDispatchers.slide\Create(...)

DNotify.CreateCentered = (...) ->
	DNotify.CreateDefaultDispatchers() if not DNotify.DefaultDispatchers or not IsValid(DNotify.DefaultDispatchers.center)
	DNotify.DefaultDispatchers.center\Create(...)

DNotify.CreateBadge = (...) ->
	DNotify.CreateDefaultDispatchers() if not DNotify.DefaultDispatchers or not IsValid(DNotify.DefaultDispatchers.badges)
	DNotify.DefaultDispatchers.badges\Create(...)

DNotify.CreateLegacy = (...) ->
	DNotify.CreateDefaultDispatchers() if not DNotify.DefaultDispatchers or not IsValid(DNotify.DefaultDispatchers.legacy)
	DNotify.DefaultDispatchers.legacy\Create(...)

DNotify.CreateDefaultDispatchers = ->
	DNotify.DefaultDispatchers = {}

	slideData = {
		x: X_SHIFT_CVAR\GetInt()
		getx: => X_SHIFT_CVAR\GetInt()
		y: Y_SHIFT_CVAR\GetInt()
		gety: => Y_SHIFT_CVAR\GetInt()

		width: ScrW!
		height: ScrH!
		getheight: ScrH
		getwidth: ScrW
	}

	centerData = {
		x: 0
		y: 0

		width: ScrW!
		height: ScrH!

		getheight: ScrH
		getwidth: ScrW
	}

	badgeData = {
		x: 0
		y: ScrH! * 0.2

		gety: => ScrH! * 0.2

		width: ScrW!
		height: ScrH!

		getheight: => ScrH! * 0.6
		getwidth: ScrW
	}

	legacyData = {
		x: 50
		y: 0
		gety: => ScrH! * 0.55

		width: ScrW! - 50
		getwidth: => ScrW! - 50
		height: ScrH! * 0.45
		getheight: => ScrH! * 0.45
	}

	DNotify.DefaultDispatchers.slide = DNotify.SlideNotifyDispatcher(slideData)
	DNotify.DefaultDispatchers.center = DNotify.CenteredNotifyDispatcher(centerData)
	DNotify.DefaultDispatchers.badges = DNotify.BadgeNotifyDispatcher(badgeData)
	DNotify.DefaultDispatchers.legacy = DNotify.LegacyNotifyDispatcher(legacyData)

HUDPaint = ->
	return if not DNotify.DefaultDispatchers
	for i, dsp in pairs DNotify.DefaultDispatchers do dsp\Draw!

Think = ->
	return if not DNotify.DefaultDispatchers
	for i, dsp in pairs DNotify.DefaultDispatchers do dsp\Think!

NetHook = ->
	mode = net.ReadUInt(4)
	mes = net.ReadString!

	if mode == HUD_PRINTCENTER
		notif = DNotify.CreateCentered({color_white, mes})
		notif\Start()
	elseif mode == HUD_PRINTTALK
		print(mes)
		chat.AddText(mes)
	elseif mode == HUD_PRINTCONSOLE or mode == HUD_PRINTNOTIFY
		print(mes)

legacyColors = {
	[NOTIFY_GENERIC]: color_white
	[NOTIFY_ERROR]: Color(200, 120, 120)
	[NOTIFY_UNDO]: Color(108, 166, 247)
	[NOTIFY_HINT]: Color(147, 247, 108)
	[NOTIFY_CLEANUP]: Color(108, 219, 247)
}

if false
	notification.AddLegacy = (text, type, time) ->
		time = math.Clamp(time or 4, 4, 60)
		type = type or NOTIFY_GENERIC

		notif = DNotify.CreateLegacy({legacyColors[type], text})
		notif\SetLength(time)
		notif\SetNotifyInConsole(false)
		notif\Start()

hook.Add('HUDPaint', 'DNotify', HUDPaint)
net.Receive('DNotify.PrintMessage', NetHook)
hook.Add('Think', 'DNotify', Think)

include_ = include
include = (fil) -> include_('dlib/modules/dnotify/client/' .. fil)
include 'font_obj.lua'
include 'base_class.lua'
include 'templates.lua'
include 'animated_base.lua'
include 'slide_class.lua'
include 'centered_class.lua'
include 'badges.lua'
include 'legacy.lua'

timer.Simple(0, DNotify.CreateDefaultDispatchers)

return nil
