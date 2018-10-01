
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


local PANEL = {}
DLib.VGUI.ButtonLayout = PANEL

AccessorFunc(PANEL, 'spacingX', 'SpacingX')
AccessorFunc(PANEL, 'spacingY', 'SpacingY')
AccessorFunc(PANEL, 'layoutSizeX', 'LayoutSizeX')
AccessorFunc(PANEL, 'layoutSizeY', 'LayoutSizeY')

function PANEL:Init()
	self.layoutSizeX = 128
	self.layoutSizeY = 96
	self.buttons = {}
	self.buttonsPositions = {}
	self.spacingX = 4
	self.spacingY = 4
	self:SetSkin('DLib_Black')
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
	self.__lastW, self.__lastH = nil, nil
	self:InvalidateLayout()
end

function PANEL:RebuildButtonsPositions(w, h)
	if not w or not h then return end
	self.buttonsPositions = {}
	local xm, ym = self.layoutSizeX + self.spacingX, self.layoutSizeY + self.spacingY

	local line = 0
	local row = 0
	local limitX = math.max(math.floor(w / xm) - 1, 1)

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

		row = row + 1
	end

	self:GetCanvas():SetSize(w, (line + 1) * ym)

	return self.buttonsPositions
end

function PANEL:PerformLayout(width, height)
	if width == self.__lastW and height == self.__lastH then return end
	self.__lastW, self.__lastH = width, height
	DScrollPanel.PerformLayout(self, width, height)
	self:RebuildButtonsPositions(self:GetSize())

	for i, button in ipairs(self:GetVisibleButtons()) do
		if not button.__dlibIsPopulated then
			button:Populate(self)
			button.__dlibIsPopulated = true
		end
	end
end

vgui.Register('DLib_ButtonLayout', PANEL, 'DScrollPanel')

return PANEL
