
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
if game.SinglePlayer() then return end

local DLib = DLib
local update
_G.FrameNumberC = FrameNumberC or FrameNumber
local FrameNumberC = FrameNumberC
_G.RealTimeC = RealTimeC or RealTime
local RealTimeC = RealTimeC
_G.CurTimeC = CurTimeC or CurTime
local CurTimeC = CurTimeC

_G.ScrWC = ScrWC or ScrW
_G.ScrHC = ScrHC or ScrH
render.SetViewPortC = render.SetViewPortC or render.SetViewPort
render.PushRenderTargetC = render.PushRenderTargetC or render.PushRenderTarget
render.PopRenderTargetC = render.PopRenderTargetC or render.PopRenderTarget
render.SetRenderTargetC = render.SetRenderTargetC or render.SetRenderTarget

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

function _G.render.SetViewPort(x, y, w, h)
	assert(type(w) == 'number' and w >= 0, 'invalid W value')
	assert(type(h) == 'number' and h >= 0, 'invalid H value')
	assert(type(x) == 'number' and x >= 0, 'invalid X value')
	assert(type(y) == 'number' and y >= 0, 'invalid Y value')
	DLib.luaify_scrw = w
	DLib.luaify_scrh = h
	return render.SetViewPortC(x, y, w, h)
end

function _G.render.PushRenderTarget(texture)
	assert(type(texture) == 'ITexture', 'invalid texture specified')
	DLib.luaify_scrw = texture:Width()
	DLib.luaify_scrh = texture:Height()
	return render.PushRenderTargetC(texture)
end

function _G.render.PopRenderTarget()
	render.PopRenderTargetC()
	DLib.luaify_scrw = ScrWC()
	DLib.luaify_scrh = ScrHC()
end

function _G.render.SetRenderTarget(texture)
	assert(type(texture) == 'ITexture', 'invalid texture specified')
	DLib.luaify_scrw = texture:Width()
	DLib.luaify_scrh = texture:Height()
	return render.SetRenderTargetC(texture)
end

function update()
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
