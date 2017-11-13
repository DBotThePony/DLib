
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
DLib.VGUI.ButtonLayout = PANEL
local DScrollPanel = DScrollPanel

DLib.util.AccessorFuncJIT(PANEL, 'spacingX', 'SpacingX')
DLib.util.AccessorFuncJIT(PANEL, 'spacingY', 'SpacingY')
DLib.util.AccessorFuncJIT(PANEL, 'layoutSizeX', 'LayoutSizeX')
DLib.util.AccessorFuncJIT(PANEL, 'layoutSizeY', 'LayoutSizeY')

function PANEL:Init()
	DScrollPanel.Init(self)
	self.layoutSizeX = 64
	self.layoutSizeY = 64
	self.buttons = {}
	self.buttonsPositions = {}
	self.spacingX = 4
	self.spacingY = 4
end

function PANEL:SetLayoutSize(x, y)
	self.layoutSizeX, self.layoutSizeY = x, y
	self:InvalidateLayout()
end

function PANEL:OnSpacingXChanges()
	self:InvalidateLayout()
end

function PANEL:OnSpacingYChanges()
	self:InvalidateLayout()
end

function PANEL:OnLayoutSizeXChanges()
	self:InvalidateLayout()
end

function PANEL:OnLayoutSizeYChanges()
	self:InvalidateLayout()
end

function PANEL:AddButton(button)
	table.insert(self.buttons, button)
	button:SetParent(self:GetCanvas())
	button:SetSize(self.layoutSizeX, self.layoutSizeY)
	button.__dlibIsPopulated = false
	button:SetSize(self.layoutSizeX, self.layoutSizeY)
	self:InvalidateLayout()
end

function PANEL:GetVisibleArea()
	local scroll = self:GetVBar():GetScroll()
	return scroll - self.layoutSizeY, scroll + self:GetTall()
end

function PANEL:GetVisibleButtons()
	local topx, bottomx = self:GetVisibleArea()
	local reply = {}

	for i, button in ipairs(self.buttonsPositions) do
		local x, y = button.x, button.y

		if y > topx and y < bottomx then
			table.insert(reply, button.button)
		end
	end

	return reply
end

function PANEL:Clear()
	for i, button in ipairs(self.buttons) do
		button:Remove()
	end

	self.buttons = {}
	self:InvalidateLayout()
end

function PANEL:RebuildButtonsPositions(w, h)
	if w == self.__lastW and h == self.__lastH then return self.buttonsPositions end
	self.__lastW, self.__lastH = w, h
	self.buttonsPositions = {}
	local xm, ym = self.layoutSizeX + self.spacingX, self.layoutSizeY + self.spacingY

	local line = 0
	local row = 0
	local limitX = math.floor(w / xm)

	for i, button in ipairs(self.buttons) do
		if row > limitX then
			row = 0
			line = line + 1
		end

		local newx, newy = row * xm, line * ym
		button:SetPos(newx, newy)

		self.buttonsPositions[i] = {
			button = button,
			x = newx,
			y = newy
		}
	end

	return self.buttonsPositions
end

function PANEL:PerformLayout(width, height)
	DScrollPanel.PerformLayout(self, width, height)
	self:RebuildButtonsPositions(width, height)

	for i, button in ipairs(self:GetVisibleButtons()) do
		if not button.__dlibIsPopulated then
			button:Populate(self)
			button.__dlibIsPopulated = true
		end
	end
end

vgui.Register('DLib_ButtonLayout', PANEL, 'DScrollPanel')

return PANEL
