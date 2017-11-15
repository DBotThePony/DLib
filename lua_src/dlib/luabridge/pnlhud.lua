
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

if SERVER then return end

local hook = hook
local DLib = DLib
local surface = surface
local ScrH = ScrH
local ScrW = ScrW
local IsValid = IsValid

hook.Add('Think', 'DLib.HUDPanelHidden', function()
	if IsValid(DLib.HUDPanelHidden) then
		DLib.HUDPanelHidden:SetPos(0, 0)
		DLib.HUDPanelHidden:SetSize(ScrW(), ScrH())
		return
	end

	DLib.HUDPanelHidden = vgui.Create('EditablePanel')
	if not IsValid(DLib.HUDPanelHidden) then return end
	DLib.HUDPanelHidden:SetPos(0, 0)
	DLib.HUDPanelHidden:SetSize(ScrW(), ScrH())
	DLib.HUDPanelHidden:SetMouseInputEnabled(false)
	DLib.HUDPanelHidden:SetKeyboardInputEnabled(false)
	DLib.HUDPanelHidden:SetRenderInScreenshots(false)

	DLib.HUDPanelHidden.Paint = function(pnl, w, h)
		surface.DisableClipping(true)

		hook.Run('HUDDrawHidden', w, h)

		surface.DisableClipping(false)
	end
end)
