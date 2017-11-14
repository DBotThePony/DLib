
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
DLib.VGUI.TextEntry = PANEL

function PANEL:Init()
	self:SetText('')
	self:SetKeyboardInputEnabled(true)
	self:SetMouseInputEnabled(true)
end

function PANEL:OnEnter(value)

end

function PANEL:OnKeyCodeTyped(key)
	if key == KEY_FIRST or key == KEY_NONE or key == KEY_TAB then
		return true
	elseif key == KEY_ENTER then
		self:OnEnter((self:GetValue() or ''):Trim())
		self:KillFocus()
		return true
	end

	if DTextEntry.OnKeyCodeTyped then
		return DTextEntry.OnKeyCodeTyped(self, key)
	end

	return false
end

vgui.Register('DLib_TextEntry', PANEL, 'DTextEntry')
return PANEL
