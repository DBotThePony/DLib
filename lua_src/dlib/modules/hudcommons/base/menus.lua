
-- Copyright (C) 2017-2019 DBot

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


local meta = DLib.FindMetaTable('HUDCommonsBase')
local HUDCommons = DLib.HUDCommons
local DLib = DLib
local IsValid = IsValid
local table = table
local spawnmenu = spawnmenu
local ipairs = ipairs

--[[
	@doc
	@fname HUDCommonsBase:PopulateDefaultSettingsOe
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulateDefaultSettings at END of that function
	@enddesc
]]
function meta:PopulateDefaultSettingsOe(panel)

end

--[[
	@doc
	@fname HUDCommonsBase:PopulateDefaultSettingsOs
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulateDefaultSettings at START of that function
	@enddesc
]]
function meta:PopulateDefaultSettingsOs(panel)

end

--[[
	@doc
	@fname HUDCommonsBase:PopulateDefaultSettings
	@args Panel DFrame

	@client
	@internal
]]
function meta:PopulateDefaultSettings(panel)
	if not IsValid(panel) then return end

	self:PopulateDefaultSettingsOs(panel)

	for i, convar in ipairs(self.convars) do
		panel:CheckBox(convar:GetHelpText(), convar:GetName()):SetTooltip(convar:GetHelpText())
	end

	self:PopulateDefaultSettingsOe(panel)
end

--[[
	@doc
	@fname HUDCommonsBase:PopulatePositionSettingsOe
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulatePositionSettings on END of that function
	@enddesc
]]
function meta:PopulatePositionSettingsOe(panel)

end

--[[
	@doc
	@fname HUDCommonsBase:PopulatePositionSettingsOs
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulatePositionSettings on START of that function
	@enddesc
]]
function meta:PopulatePositionSettingsOs(panel)

end

function meta:PopulatePositionSettings(panel)
	if not IsValid(panel) then return end

	self:PopulatePositionSettingsOs(panel)

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
		panel:NumSlider('X', convar.cvarX:GetName(), 0, 1, 3)
		panel:NumSlider('Y', convar.cvarY:GetName(), 0, 1, 3)
		panel:Button('Reset').DoClick = function()
			convar.cvarX:Reset()
			convar.cvarY:Reset()
		end
	end

	self:PopulatePositionSettingsOe(panel)
end

--[[
	@doc
	@fname HUDCommonsBase:PopulateToolMenuDefault

	@client
	@internal
]]
function meta:PopulateToolMenuDefault()
	spawnmenu.AddToolMenuOption('Utilities', 'User', self:GetID() .. '_menus', self:GetName(), '', '', function(panel)
		self:PopulateDefaultSettings(panel)
	end)

	if table.Count(self.positionsConVars) ~= 0 then
		spawnmenu.AddToolMenuOption('Utilities', 'User', self:GetID() .. '_menus_pos', self:GetName() .. ' positions', '', '', function(panel)
			self:PopulatePositionSettings(panel)
		end)
	end
end
