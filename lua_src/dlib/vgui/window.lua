
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

local surface = surface
local gui = gui
local vgui = vgui
local input = input

local PANEL = {}

function PANEL:Init()
	self.tapped = false
	self.target = NULL
	self.effects = true
	self.tapX, self.tapY = 0, 0
	self.oldW, self.oldH = 0, 0
	self.minW, self.minH = 100, 30
	self.currX, self.currY = 0, 0
	self.translucent = 0
	self:SetCursor('sizenwse')

	hook.Add('PostRenderVGUI', self, self.PostRenderVGUI)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(140, 140, 140, 150)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:SetTarget(targetPanel)
	self.target = targetPanel
	return self
end

function PANEL:PostRenderVGUI()
	if not self.tapped and not self.fadeout then return end
	surface.SetDrawColor(self.translucent * 2.5, self.translucent * 2.5, self.translucent * 2.5, self.translucent)
	surface.DrawRect(self.currX, self.currY, self:GetNewDimensions())
end

function PANEL:OnMousePressed(key)
	if key ~= MOUSE_LEFT then return end
	self.tapped = true
	self.tapX, self.tapY = gui.MousePos()
	self.oldW, self.oldH = self.target:GetSize()
	self.translucent = 0
	self.currX, self.currY = self.target:GetPos()
end

function PANEL:Think()
	if self.tapped then
		if not input.IsMouseDown(MOUSE_LEFT) then
			self:OnMouseReleased(MOUSE_LEFT)
			return
		end

		self.translucent = Lerp(FrameTime() * 5, self.translucent, 100)
	end

	if self.fadeout then
		self.translucent = Lerp(FrameTime() * 8, self.translucent, 0)
		self.fadeout = self.translucent > 1
	end
end

function PANEL:GetNewDimensions()
	local x, y = gui.MousePos()
	local diffX, diffY = x - self.tapX, y - self.tapY
	return math.max(self.oldW + diffX, self.minW), math.max(self.oldH + diffY, self.minH)
end

function PANEL:OnMouseReleased()
	self.tapped = false
	self.fadeout = true
	local w, h = self:GetNewDimensions()
	self.target:SetSize(w, h)
end

vgui.Register('DLib_ResizeTap', PANEL, 'EditablePanel')

PANEL = {}
DLib.VGUI.Window = PANEL

function PANEL:Init()
	self:SetSize(ScrW() - 100, ScrH() - 100)
	self:Center()
	self:MakePopup()
	self:SetTitle('DLib Window')
	self:SetSkin('DLib_Black')

	self.bottomBar = vgui.Create('EditablePanel', self)
	local bar = self.bottomBar
	bar:Dock(BOTTOM)
	bar:SetSize(0, 16)
	bar:SetMouseInputEnabled(true)

	self.bottomTap = vgui.Create('DLib_ResizeTap', bar)
	local tap = self.bottomTap
	tap:Dock(RIGHT)
	tap:SetSize(16, 16)
	tap:SetMouseInputEnabled(true)
	tap:SetTarget(self)
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
