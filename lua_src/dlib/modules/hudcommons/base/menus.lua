
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

local meta = DLib.FindMetaTable('HUDCommonsBase')
local HUDCommons = DLib.HUDCommons
local DLib = DLib
local IsValid = IsValid
local table = table
local spawnmenu = spawnmenu
local ipairs = ipairs

function meta:PopulateDefaultSettings(panel)
	if not IsValid(panel) then return end

	for i, convar in ipairs(self.convars) do
		panel:CheckBox(convar:GetHelpText(), convar:GetName()):SetTooltip(convar:GetHelpText())
	end
end

function meta:PopulatePositionSettings(panel)
	if not IsValid(panel) then return end

	if table.Count(self.positionsConVars) == 0 then
		Panel:Help('No convars registered!')
		Panel:Help('Nothing to edit.')
		return
	end

	panel:Button('Reset all').DoClick = function()
		for i, convar in pairs(self.positionsConVars) do
			convar.cvarX:Reset()
			convar.cvarY:Reset()
		end
	end

	panel:Button('Enter interactive mode').DoClick = function()
		local filter = {}

		for i, convar in pairs(self.positionsConVars, 'name') do
			table.insert(filter, self:GetID() .. '_' .. convar.oname)
		end

		HUDCommons.EnterPositionEditMode(filter)
	end

	for i, convar in SortedPairsByMemberValue(self.positionsConVars, 'name') do
		panel:Help(convar.name)
		panel:NumSlider('X', convar.cvarX:GetName(), 0, 1, 2)
		panel:NumSlider('Y', convar.cvarY:GetName(), 0, 1, 2)
		panel:Button('Reset').DoClick = function()
			convar.cvarX:Reset()
			convar.cvarY:Reset()
		end
	end
end

function meta:PopulateToolMenuDefault()
	spawnmenu.AddToolMenuOption('Utilities', 'User', self:GetID() .. '_menus', self:GetName(), '', '', function(panel)
		self:PopulateDefaultSettings(panel)
	end)

	spawnmenu.AddToolMenuOption('Utilities', 'User', self:GetID() .. '_menus_pos', self:GetName() .. ' positions', '', '', function(panel)
		self:PopulatePositionSettings(panel)
	end)
end
