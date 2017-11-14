
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

local PANEL = {}
DLib.VGUI.Window = PANEL

-- TODO: Stretching

function PANEL:Init()
	self:SetSize(ScrW() - 100, ScrH() - 100)
	self:Center()
	self:MakePopup()
	self:SetTitle('DLib Window')
	self:SetSkin('DLib_Black')
end

function PANEL:UpdateSize(w, h)
	self:SetSize(w, h)
	self:Center()
end

function PANEL:SetLabel(str)
	return self:SetTitle(str)
end

vgui.Register('DLib_Window', PANEL, 'DFrame')

return PANEL
