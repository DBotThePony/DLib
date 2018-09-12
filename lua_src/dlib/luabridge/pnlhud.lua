
-- Copyright (C) 2017-2018 DBot

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


if SERVER then return end

local hook = hook
local DLib = DLib
local surface = surface
local ScrHL = ScrHL
local ScrWL = ScrWL
local IsValid = IsValid

hook.Add('Think', 'DLib.HUDPanelHidden', function()
	if IsValid(DLib.HUDPanelHidden) then
		DLib.HUDPanelHidden:SetPos(0, 0)
		DLib.HUDPanelHidden:SetSize(ScrWL(), ScrHL())
		return
	end

	DLib.HUDPanelHidden = vgui.Create('EditablePanel')
	if not IsValid(DLib.HUDPanelHidden) then return end
	DLib.HUDPanelHidden:SetPos(0, 0)
	DLib.HUDPanelHidden:SetSize(ScrWL(), ScrHL())
	DLib.HUDPanelHidden:SetMouseInputEnabled(false)
	DLib.HUDPanelHidden:SetKeyboardInputEnabled(false)
	DLib.HUDPanelHidden:SetRenderInScreenshots(false)

	DLib.HUDPanelHidden.Paint = function(pnl, w, h)
		surface.DisableClipping(true)

		hook.Run('HUDDrawHidden', w, h)

		surface.DisableClipping(false)
	end
end)
