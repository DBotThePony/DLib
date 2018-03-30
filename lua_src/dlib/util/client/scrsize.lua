
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

	hook.Run('ScreenResolutionChanged', lastW, lastH, w, h)
	hook.Run('ScreenSizeChanged', lastW, lastH, w, h)
	hook.Run('OnScreenSizeChanged', lastW, lastH, w, h)
	hook.Run('OnScreenResolutionUpdated', lastW, lastH, w, h)

	lastW, lastH = w, h
end

hook.Add('DLib.ScreenSettingsUpdate', 'DLib.UpdateScreenSize', check)
