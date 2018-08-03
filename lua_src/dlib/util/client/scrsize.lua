
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

local DLib = DLib
local lastW, lastH = ScrWL(), ScrHL()
local hook = hook

local function check(w, h)
	if w == lastW and h == lastH then return end

	if w ~= lastW then
		hook.Run('ScreenWidthChanges', lastW, w)
	end

	if h ~= lastH then
		hook.Run('ScreenHeightChanges', lastH, h)
	end

	DLib.TriggerScreenSizeUpdate(lastW, lastH, w, h)

	lastW, lastH = w, h
end

function DLib.TriggerScreenSizeUpdate(...)
	hook.Run('ScreenResolutionChanged', ...)
	hook.Run('ScreenSizeChanged', ...)
	hook.Run('OnScreenSizeChanged', ...)
	hook.Run('OnScreenResolutionUpdated', ...)
end

local dlib_guiding_lines = CreateConVar('dlib_guiding_lines', '0', {}, 'Draw guiding lines on screen')
local gui = gui
local surface = surface
local ScreenSize = ScreenSize

surface.CreateFont('DLib.GuidingLine', {
	font = 'PT Mono',
	size = 24,
	weight = 500
})

local function DrawGuidingLines()
	if not dlib_guiding_lines:GetBool() then return end

	local x, y = gui.MousePos()
	if x == 0 and y == 0 then return end

	surface.SetDrawColor(183, 174, 174)

	surface.DrawRect(0, y - ScreenSize(2), lastW, ScreenSize(4))
	surface.DrawRect(x - ScreenSize(2), 0, ScreenSize(4), lastH)
	DLib.HUDCommons.WordBox(string.format('X percent: %.2f Y percent: %.2f', x / lastW, y / lastH), 'DLib.GuidingLine', x:clamp(lastW * 0.15, lastW * 0.85), (y - ScreenSize(17)):clamp(lastH * 0.1, lastH * 0.9), color_white, color_black, true)
end

hook.Add('DLib.ScreenSettingsUpdate', 'DLib.UpdateScreenSize', check)
hook.Add('HUDPaint', 'DLib.DrawGuidingLines', DrawGuidingLines)
