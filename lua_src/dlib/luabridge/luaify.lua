
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

if SERVER then
	_G.CurTimeL = CurTime
	_G.RealTimeL = RealTime
	return
end

local DLib = DLib
_G.FrameNumberC = FrameNumberC or FrameNumber
_G.RealTimeC = RealTimeC or RealTime
_G.CurTimeC = CurTimeC or CurTime

_G.ScrWC = ScrWC or ScrW
_G.ScrHC = ScrHC or ScrH
local ScrWC = ScrWC
local ScrHC = ScrHC
local render = render
local type = type
local assert = assert

DLib.luaify_rTime = RealTimeC()
DLib.luaify_cTime = CurTimeC()
DLib.luaify_frameNum = FrameNumberC()

DLib.luaify_scrw = ScrWC()
DLib.luaify_scrh = ScrHC()
DLib.pstatus = false

function _G.RealTimeL()
	return DLib.luaify_rTime
end

function _G.FrameNumberL()
	return DLib.luaify_frameNum
end

function _G.CurTimeL()
	return DLib.luaify_cTime
end

function _G.ScrWL()
	return DLib.luaify_scrw
end

function _G.ScrHL()
	return DLib.luaify_scrh
end
