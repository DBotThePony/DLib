
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

DNotify.CreateSlide = (...) -> DNotify.DefaultDispatchers.slide\Create(...)
DNotify.CreateCentered = (...) -> DNotify.DefaultDispatchers.center\Create(...)
DNotify.CreateBadge = (...) -> DNotify.DefaultDispatchers.badges\Create(...)

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
	
	DNotify.DefaultDispatchers.slide = DNotify.SlideNotifyDispatcher(slideData)
	DNotify.DefaultDispatchers.center = DNotify.CenteredNotifyDispatcher(centerData)
	DNotify.DefaultDispatchers.badges = DNotify.BadgeNotifyDispatcher(centerData)

HUDPaint = ->
	for i, dsp in pairs DNotify.DefaultDispatchers do dsp\Draw!

Think = ->
	for i, dsp in pairs DNotify.DefaultDispatchers do dsp\Think!

hook.Add('HUDPaint', 'DNotify', HUDPaint)
hook.Add('Think', 'DNotify', Think)
timer.Simple(0, DNotify.CreateDefaultDispatchers)

include 'dnotify/font_obj.lua'
include 'dnotify/base_class.lua'
include 'dnotify/templates.lua'
include 'dnotify/animated_base.lua'
include 'dnotify/slide_class.lua'
include 'dnotify/centered_class.lua'
include 'dnotify/badges.lua'

return nil
