
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
local FrameNumberC = FrameNumberC
local RealTimeC = RealTimeC
local CurTimeC = CurTimeC
local ScrWC = ScrWC
local ScrHC = ScrHC

local function update()
	DLib.luaify_rTime = RealTimeC()
	DLib.luaify_cTime = CurTimeC()
	DLib.luaify_frameNum = FrameNumberC()

	DLib.luaify_scrw = ScrWC()
	DLib.luaify_scrh = ScrHC()
	DLib.pstatus = false
end

hook.Add('PreRender', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('Think', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('Tick', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('PlayerSwitchWeapon', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('StartCommand', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('SetupMove', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('Move', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('VehicleMove', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('PlayerTick', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('ShouldCollide', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('PlayerButtonDown', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('PlayerButtonUp', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('PhysgunPickup', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('KeyPress', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('KeyRelease', 'DLib.UpdateFrameOptions', update, -9)
hook.Add('FinishMove', 'DLib.UpdateFrameOptions', update, -9)
