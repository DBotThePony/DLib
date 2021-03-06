
--
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

DLib = DLib
Notify = DLib.Notify
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
	message = net.ReadString()
	message = language.GetPhrase(message\sub(2)) if message[1] == '#'

	if mode == HUD_PRINTCENTER
		rebuild = {color_white, message}

		if DLib.i18n.exists(message)
			rebuild = DLib.i18n.rebuildTable(rebuild, color_white)

		notif = Notify.CreateCentered(rebuild)
		notif\Start()
	elseif mode == HUD_PRINTTALK
		print(message)
		chat.AddText(message)
	elseif mode == HUD_PRINTCONSOLE or mode == HUD_PRINTNOTIFY
		print(message)

hook.Add('HUDPaint', 'DLib.Notify', HUDPaint)
net.Receive('DLib.Notify.PrintMessage', NetHook)
hook.Add('Think', 'DLib.Notify', Think)

timer.Simple(0, Notify.CreateDefaultDispatchers)

return Notify
