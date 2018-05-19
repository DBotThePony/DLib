
--
-- Copyright (C) 2017-2018 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local function PopulateColors(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()

	for k, v in SortedPairsByMemberValue(HUDCommons.ColorsVars, 'name') do
		local collapse = vgui.Create('DCollapsibleCategory', Panel)
		Panel:AddItem(collapse)
		collapse:SetExpanded(false)
		collapse:SetLabel(v.name .. ' (' .. k .. ')')

		local picker = vgui.Create('DColorMixer', collapse)
		collapse:SetContents(picker)
		picker:SetConVarR(v.r:GetName())
		picker:SetConVarG(v.g:GetName())
		picker:SetConVarB(v.b:GetName())
		picker:SetConVarA(v.a:GetName())

		picker:Dock(TOP)
		picker:SetHeight(200)
	end
end

local function PopulateColors2(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()

	for k, v in SortedPairsByMemberValue(HUDCommons.ColorsVarsN, 'name') do
		local collapse = vgui.Create('DCollapsibleCategory', Panel)
		Panel:AddItem(collapse)
		collapse:SetExpanded(false)
		collapse:SetLabel(v.name .. ' (' .. k .. ')')

		local picker = vgui.Create('DColorMixer', collapse)
		collapse:SetContents(picker)
		picker:SetConVarR(v.r:GetName())
		picker:SetConVarG(v.g:GetName())
		picker:SetConVarB(v.b:GetName())
		picker:SetAlphaBar(false)

		picker:Dock(TOP)
		picker:SetHeight(200)
	end
end

local function PopulatePositions(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()

	for name, v in SortedPairs(HUDCommons.Position2.XPositions_CVars) do
		local collapse = vgui.Create('DCollapsibleCategory', Panel)
		Panel:AddItem(collapse)
		collapse:SetExpanded(false)
		local cvarX = HUDCommons.Position2.XPositions_CVars[name]
		local cvarY = HUDCommons.Position2.YPositions_CVars[name]
		collapse:SetLabel(name)

		local parent = vgui.Create('EditablePanel', Panel)
		collapse:SetContents(parent)

		parent:Add(Panel:NumSlider('X', cvarX:GetName(), 0, 1, 2))
		parent:Add(Panel:NumSlider('Y', cvarY:GetName(), 0, 1, 2))
		local reset = Panel:Button('Reset')

		parent:Add(reset)

		reset.DoClick = function()
			cvarX:Reset()
			cvarY:Reset()
		end
	end
end

hook.Add('PopulateToolMenu', 'HUDCommons.PopulateMenus', function()
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Populate', 'HUDCommons Colors', '', '', PopulateColors)
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Populate2', 'HUDCommons Colors 2', '', '', PopulateColors2)
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Positions2', 'HUDCommons Positions 2', '', '', PopulatePositions)
end)
