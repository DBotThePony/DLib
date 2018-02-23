
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

local vgui = vgui
local IsValid = IsValid

local numberEntry = {
	'GetNumber'
}

do
	local getset = {
		'DefaultNumber',
		'IsFloatAllowed',
		'IsNegativeValueAllowed',
		'LengthLimit',
		'TooltipTime',
		'TooltipShown',
		'IsWhitelistMode',
		'DisallowedHashSet',
		'AllowedHashSet',
		'DefaultReason',
	}

	for i, get in ipairs(getset) do
		table.insert(numberEntry, 'Get' .. get)
		table.insert(numberEntry, 'Set' .. get)
	end
end

local panels = {
	{'DLib_TextEntry_Number', 'Number', numberEntry},
	{'DLib_TextEntry', 'Text'},
}

for i, pnlData in ipairs(panels) do
	local NAME = pnlData[2] .. 'Input'
	local PANEL_ID = pnlData[1]

	local PANEL = {}
	DLib.VGUI[NAME] = PANEL

	local function Init(self)
		self:SetSize(140, 20)

		self.textInput = vgui.Create(PANEL_ID, self)
		self.apply = vgui.Create('DButton', self)
		self.apply:SetText('Apply')
		self.apply:Dock(RIGHT)
		self.apply:DockMargin(4, 0, 4, 0)
		self.textInput:Dock(FILL)
		self.apply:SizeToContents()
		self.apply:SetWide(self.apply:GetWide() + 6)

		function self.apply.DoClick()
			return self:OnEnter(self:GetValue())
		end

		function self.textInput.OnEnter(_, ...)
			return self:OnEnter(...)
		end
	end

	PANEL.Init = Init

	function PANEL:RemoveApply()
		if IsValid(self.apply) then
			self.apply:Remove()
		end
	end

	function PANEL:GetValue(...)
		return self.textInput:GetText(...)
	end

	function PANEL:GetText(...)
		return self.textInput:GetText(...)
	end

	function PANEL:SetValue(...)
		return self.textInput:SetText(...)
	end

	function PANEL:SetText(...)
		return self.textInput:SetText(...)
	end

	function PANEL:SetTitle(...)
		return self.apply:SetText(...)
	end

	function PANEL:GetTitle(...)
		return self.apply:GetText(...)
	end

	function PANEL:GetInput()
		return self.textInput
	end

	function PANEL:GetButton()
		return self.apply
	end

	function PANEL:OnEnter(value)

	end

	if pnlData[3] then
		for i2, func in ipairs(pnlData[3]) do
			PANEL[func] = function(self, ...)
				return self.textInput[func](self.textInput, ...)
			end
		end
	end

	vgui.Register('DLib_' .. NAME, PANEL, 'EditablePanel')

	PANEL = table.Copy(PANEL)

	function PANEL:Init()
		self.label = vgui.Create('DLabel', self)
		self.label:Dock(TOP)
		self.label:SetText('Field Input')

		Init(self)

		self:SetSize(140, 40)
	end

	function PANEL:SetTitle(...)
		return self.label:SetText(...)
	end

	function PANEL:SetLabel(...)
		return self.label:SetText(...)
	end

	vgui.Register('DLib_' .. NAME .. 'Labeled', PANEL, 'EditablePanel')

	PANEL = table.Copy(PANEL)

	function PANEL:Init()
		self.label = vgui.Create('DLabel', self)
		self.label:Dock(TOP)
		self.label:SetText('Field Input')

		Init(self)

		self:SetSize(140, 40)
		self.apply:Remove()
	end

	vgui.Register('DLib_' .. NAME .. 'LabeledBare', PANEL, 'EditablePanel')
end
