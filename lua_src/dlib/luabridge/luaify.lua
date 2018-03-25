
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

-- make some functions be jit compilable

if SERVER then return end

local DLib = DLib
_G.FrameNumberC = FrameNumberC or FrameNumber
local FrameNumberC = FrameNumberC
_G.RealTimeC = RealTimeC or RealTime
local RealTimeC = RealTimeC
_G.CurTimeC = CurTimeC or CurTime
local CurTimeC = CurTimeC

DLib.luaify_rTime = RealTimeC()
DLib.luaify_cTime = CurTimeC()
DLib.luaify_frameNum = FrameNumberC()

function _G.RealTime()
	return DLib.luaify_rTime
end

function _G.FrameNumber()
	return DLib.luaify_frameNum
end

function _G.CurTime()
	return DLib.luaify_cTime
end

hook.Add('PreRender', 'DLib.UpdateFrameOptions', function()
	DLib.luaify_rTime = RealTimeC()
	DLib.luaify_cTime = CurTimeC()
	DLib.luaify_frameNum = FrameNumberC()
end, -9)
