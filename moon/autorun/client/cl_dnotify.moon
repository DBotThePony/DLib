
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
DNotify.RegisteredThinks = {}
DNotify.NotificationsSlideLeft = {}
DNotify.NotificationsSlideRight = {}

X_SHIFT_CVAR = CreateConVar('dnofity_x_shift', '0', {FCVAR_ARCHIVE}, 'Shift at X of DNotify slide notifications')
Y_SHIFT_CVAR = CreateConVar('dnofity_x_shift', '15', {FCVAR_ARCHIVE}, 'Shift at Y of DNotify slide notifications')

DNOTIFY_SIDE_LEFT = 1
DNOTIFY_SIDE_RIGHT = 2
DNOTIFY_POS_TOP = 3
DNOTIFY_POS_BOTTOM = 4

DNotify.newLines = (str = '') -> string.Explode('\r?\n', str)
DNotify.allowedOrign = (enum) ->
	enum == TEXT_ALIGN_LEFT or
	enum == TEXT_ALIGN_RIGHT or
	enum == TEXT_ALIGN_CENTER

HUDPaint = ->
	yShift = 0
	
	x = X_SHIFT_CVAR\GetInt()
	y = Y_SHIFT_CVAR\GetInt()
	
	for k, func in pairs DNotify.NotificationsSlideLeft
		if func\IsValid()
			currShift = func\Draw(x, y + yShift)
			yShift += currShift
		else
			DNotify.NotificationsSlideLeft[k] = nil

	
	yShift = 0
	x = ScrW! - X_SHIFT_CVAR\GetInt()
	y = Y_SHIFT_CVAR\GetInt()
	
	for k, func in pairs DNotify.NotificationsSlideRight
		if func\IsValid()
			currShift = func\Draw(x, y + yShift)
			yShift += currShift
		else
			DNotify.NotificationsSlideRight[k] = nil

Think = ->
	for k, func in pairs DNotify.RegisteredThinks
		if func\IsValid!
			func\Think!
		else
			DNotify.RegisteredThinks[k] = nil

hook.Add('HUDPaint', 'DNotify', HUDPaint)
hook.Add('Think', 'DNotify', Think)