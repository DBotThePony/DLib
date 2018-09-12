
--
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


export Notify_SIDE_LEFT
export Notify_SIDE_RIGHT
export Notify_POS_TOP
export Notify_POS_BOTTOM

Notify.DefaultDispatchers = {}

Notify_SIDE_LEFT = 1
Notify_SIDE_RIGHT = 2
Notify_POS_TOP = 3
Notify_POS_BOTTOM = 4

Notify.newLines = (str = '') -> string.Explode('\n', str)
Notify.allowedOrigin = (enum) ->
	enum == TEXT_ALIGN_LEFT or
	enum == TEXT_ALIGN_RIGHT or
	enum == TEXT_ALIGN_CENTER

Notify.Clear = -> for i, obj in pairs Notify.DefaultDispatchers do obj\Clear!

Notify.CreateSlide = (...) ->
	Notify.CreateDefaultDispatchers() if not Notify.DefaultDispatchers or not IsValid(Notify.DefaultDispatchers.slide)
	Notify.DefaultDispatchers.slide\Create(...)

Notify.CreateCentered = (...) ->
	Notify.CreateDefaultDispatchers() if not Notify.DefaultDispatchers or not IsValid(Notify.DefaultDispatchers.center)
	Notify.DefaultDispatchers.center\Create(...)

Notify.CreateBadge = (...) ->
	Notify.CreateDefaultDispatchers() if not Notify.DefaultDispatchers or not IsValid(Notify.DefaultDispatchers.badges)
	Notify.DefaultDispatchers.badges\Create(...)

Notify.CreateLegacy = (...) ->
	Notify.CreateDefaultDispatchers() if not Notify.DefaultDispatchers or not IsValid(Notify.DefaultDispatchers.legacy)
	Notify.DefaultDispatchers.legacy\Create(...)

flipPos = (input) ->
	x, y = input()
	return y

Notify.CreateDefaultDispatchers = ->
	Notify.DefaultDispatchers = {}

	SLIDE_POS = DLib.HUDCommons.DefinePosition('notify_main', 0, 30)
	CENTER_POS = DLib.HUDCommons.DefinePosition('notify_center', 0, 0)
	BADGE_POS = DLib.HUDCommons.DefinePosition('notify_badge', 0, 0.2)
	LEGACY_POS = DLib.HUDCommons.DefinePosition('notify_legacy', 50, 0.55)

	slideData = {
		x: SLIDE_POS()
		getx: SLIDE_POS
		y: flipPos(SLIDE_POS)
		gety: => flipPos(SLIDE_POS)

		width: ScrWL!
		height: ScrHL!
		getheight: ScrHL
		getwidth: ScrWL
	}

	centerData = {
		x: CENTER_POS()
		getx: CENTER_POS
		y: flipPos(CENTER_POS)
		gety: => flipPos(CENTER_POS)

		width: ScrWL!
		height: ScrHL!

		getheight: ScrHL
		getwidth: ScrWL
	}

	badgeData = {
		x: BADGE_POS()
		getx: BADGE_POS
		y: flipPos(BADGE_POS)
		gety: => flipPos(BADGE_POS)

		width: ScrWL!
		height: ScrHL!

		getheight: => ScrHL! * 0.6
		getwidth: ScrWL
	}

	legacyData = {
		x: LEGACY_POS()
		getx: LEGACY_POS
		y: flipPos(LEGACY_POS)
		gety: => flipPos(LEGACY_POS)

		width: ScrWL! - 50
		getwidth: => ScrWL! - 50
		height: ScrHL! * 0.45
		getheight: => ScrHL! * 0.45
	}

	Notify.DefaultDispatchers.slide = Notify.SlideNotifyDispatcher(slideData)
	Notify.DefaultDispatchers.center = Notify.CentereNotifyDispatcher(centerData)
	Notify.DefaultDispatchers.badges = Notify.BadgeNotifyDispatcher(badgeData)
	Notify.DefaultDispatchers.legacy = Notify.LegacyNotifyDispatcher(legacyData)

HUDPaint = ->
	return if not Notify.DefaultDispatchers
	for i, dsp in pairs Notify.DefaultDispatchers do dsp\Draw!

Think = ->
	return if not Notify.DefaultDispatchers
	for i, dsp in pairs Notify.DefaultDispatchers do dsp\Think!

NetHook = ->
	mode = net.ReadUInt(4)
	mes = net.ReadString!

	if mode == HUD_PRINTCENTER
		notif = Notify.CreateCentered({color_white, mes})
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

		notif = Notify.CreateLegacy({legacyColors[type], text})
		notif\SetLength(time)
		notif\SetNotifyInConsole(false)
		notif\Start()

hook.Add('HUDPaint', 'DLib.Notify', HUDPaint)
net.Receive('DLib.Notify.PrintMessage', NetHook)
hook.Add('Think', 'DLib.Notify', Think)

include_ = include
include = (fil) -> include_('dlib/modules/notify/client/' .. fil)
include 'font_obj.lua'
include 'base_class.lua'
include 'templates.lua'
include 'animated_base.lua'
include 'slide_class.lua'
include 'centered_class.lua'
include 'badges.lua'
include 'legacy.lua'

timer.Simple(0, Notify.CreateDefaultDispatchers)

return Notify
