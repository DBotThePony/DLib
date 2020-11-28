
-- Copyright (C) 2017-2020 DBotThePony

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

local DLib = DLib
local HUDCommons = DLib.HUDCommons
local meta = HUDCommons.BaseMetaObj
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
	@fname HUDCommonsBase:GetSortedConvars

	@client
	@internal
	@returns
	table
]]
function meta:GetSortedConvars()
	local sort = table.qcopy(self.convars)

	table.sort(sort, function(a, b)
		if a.priority ~= b.priority then
			return a.priority > b.priority
		end

		if a.type ~= b.type then
			return a.type < b.type
		end

		return a.desc > b.desc
	end)

	return sort
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

	local presets = vgui.Create('ControlPresets', panel)
	panel.m_Presets = presets
	panel:AddItem(presets)
	presets:Dock(TOP)
	presets:DockMargin(0, 5, 0, 5)

	presets:SetPreset(self:GetID() .. '_def')

	self:PopulateDefaultSettingsOs(panel)

	for i, data in ipairs(self:GetSortedConvars()) do
		if not data.nomenu then
			presets:AddConVar(data.name)

			if data.type == self.CONVAR_TYPE_BOOL then
				panel:CheckBox(data.desc, data.name):SetTooltip(data.desc)
			elseif data.type == self.CONVAR_TYPE_NUM then
				panel:NumSlider(data.desc, data.name, data.min, data.max, data.decimals):SetTooltip(data.desc)
			elseif data.type == self.CONVAR_TYPE_STRING then
				panel:TextEntry(data.desc, data.name):SetTooltip(data.desc)
			elseif data.type == self.CONVAR_TYPE_STRING then
				local left = vgui.Create('DLabel', self)
				left:SetText(data.desc)

				local entry = vgui.Create('DLib_TextEntry', panel)
				entry:SetConVar(data.name)
				entry:SetPlaceholderText(data.convar:GetDefault())

				panel:AddItem(left, entry)
			elseif data.type == self.CONVAR_TYPE_ENUM then
				local box = panel:ComboBox(data.desc, data.name)
				local shake = table.GetKeys(data.enum)
				table.sort(shake)

				for i, key in ipairs(shake) do
					if type(key) == 'number' then
						box:AddChoice(data.enum[key])
					else
						box:AddChoice(key, data.enum[key])
					end
				end
			else
				error('???')
			end
		end
	end

	DLib.VGUI.GenerateDefaultPreset(presets)

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

	local presets = vgui.Create('ControlPresets', panel)
	panel.m_Presets = presets
	panel:AddItem(presets)
	presets:Dock(TOP)
	presets:DockMargin(0, 5, 0, 5)

	presets:SetPreset(self:GetID() .. '_position')

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
		presets:AddConVar(convar.cvarX:GetName())
		presets:AddConVar(convar.cvarY:GetName())

		panel:Help(convar.name)
		panel:NumSlider('X', convar.cvarX:GetName(), 0, 1, 3)
		panel:NumSlider('Y', convar.cvarY:GetName(), 0, 1, 3)
		panel:Button('Reset').DoClick = function()
			convar.cvarX:Reset()
			convar.cvarY:Reset()
		end
	end

	DLib.VGUI.GenerateDefaultPreset(presets)

	self:PopulatePositionSettingsOe(panel)
end

local defFonts = {
	'Roboto',
	'PT Sans',
	'PT Sans Caption',
	'PT Mono',
	'Exo 2',
	'Exo 2 Thin',
	'Exo 2'
}

--[[
	@doc
	@fname HUDCommonsBase:GetAutocompleteFonts

	@client
	@desc
	Override this if you want your own list of fonts for autocomplete in setting menus
	@enddesc

	@returns
	table: or nil
]]
function meta:GetAutocompleteFonts(inputText, convar, fontName, textEntry)
	inputText = inputText:lower()
	local output = {}

	for i, font in ipairs(defFonts) do
		if font:lower():startsWith(inputText) then
			table.insert(output, font)
		end
	end

	if not DLib.ttf.IsFamilyCachePresent() and not DLib.ttf.IsFamilyCacheBuilding() then
		DLib.ttf.ASyncSearchFamiliesCached()
	elseif DLib.ttf.IsFamilyCachePresent() then
		for i, font in ipairs(DLib.ttf.SearchFamiliesCached()) do
			if font:lower():startsWith(inputText) then
				table.insert(output, font)
			end
		end
	end

	table.sort(output)
	return table.deduplicate(output)
end

--[[
	@doc
	@fname HUDCommonsBase:PopulateFontSettingsOe
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulateFontSettings on END of that function
	@enddesc
]]
function meta:PopulateFontSettingsOe(panel)

end

--[[
	@doc
	@fname HUDCommonsBase:PopulateFontSettingsOs
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulateFontSettings on START of that function
	@enddesc
]]
function meta:PopulateFontSettingsOs(panel)

end

--[[
	@doc
	@fname HUDCommonsBase:PopulateFontSettings

	@client
	@internal
]]
function meta:PopulateFontSettings(panel)
	if not IsValid(panel) then return end

	local presets = vgui.Create('ControlPresets', panel)
	panel.m_Presets = presets
	panel:AddItem(presets)
	presets:Dock(TOP)
	presets:DockMargin(0, 5, 0, 5)

	presets:SetPreset(self:GetID() .. '_font')

	panel:Help('gui.dlib.hudcommons.save_hint')

	self:PopulateFontSettingsOs(panel)

	for cI, cName in ipairs(self.fontCVars) do
		presets:AddConVar(self.fontCVars.font[cI]:GetName())
		presets:AddConVar(self.fontCVars.weight[cI]:GetName())
		presets:AddConVar(self.fontCVars.size[cI]:GetName())

		panel:Help(DLib.i18n.localize('gui.dlib.hudcommons.font_label', cName))

		local entry = vgui.Create('DLib_TextEntry', panel)
		entry:SetConVar(self.fontCVars.font[cI]:GetName())
		entry:SetPlaceholderText(self.fontCVars.font[cI]:GetDefault())

		panel:AddItem(entry)

		function entry.GetAutoComplete(pself, inputText)
			local tab = self:GetAutocompleteFonts(inputText, self.fontCVars.font[cI], cName, pself)

			if not tab then return end

			if self.fontCVars.font[cI]:GetDefault():lower():startsWith(inputText:lower()) then
				table.insert(tab, self.fontCVars.font[cI]:GetDefault())
			end

			return table.deduplicate(tab)
		end

		panel:NumSlider('gui.dlib.hudcommons.weight', self.fontCVars.weight[cI]:GetName(), 100, 800, 0)
		panel:NumSlider('gui.dlib.hudcommons.size', self.fontCVars.size[cI]:GetName(), 2, 128, 0)
	end

	DLib.VGUI.GenerateDefaultPreset(presets)

	self:PopulateFontSettingsOe(panel)
end

--[[
	@doc
	@fname HUDCommonsBase:PopulateColorsMenuOe
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulateColorsMenu on END of that function
	@enddesc
]]
function meta:PopulateColorsMenuOe(panel)

end

--[[
	@doc
	@fname HUDCommonsBase:PopulateColorsMenuOs
	@args Panel DFrame

	@client
	@desc
	Getting called from PopulateColorsMenu on START of that function
	@enddesc
]]
function meta:PopulateColorsMenuOs(panel)

end

--[[
	@doc
	@fname HUDCommonsBase:PopulateColorsMenu

	@client
	@internal
]]
function meta:PopulateColorsMenu(panel)
	if not IsValid(panel) then return end
	panel:Clear()

	table.sort(self.colorNames)
	table.sort(self.colorNamesN)

	self:PopulateColorsMenuOs(panel)

	for i, class in ipairs(self.colorNames) do
		local v = HUDCommons.ColorsVars[class]

		local collapse = vgui.Create('DCollapsibleCategory', panel)
		panel:AddItem(collapse)

		collapse:SetExpanded(false)
		collapse:SetLabel(v.name .. ' (' .. class .. ')')

		if IsValid(collapse.Header) then
			collapse.Header:SetTooltip(v.name .. ' (' .. class .. ')')
		end

		local canvas = vgui.Create('Editablepanel', collapse)
		collapse:SetContents(canvas)

		local reset = vgui.Create('DButton', canvas)
		reset:Dock(TOP)
		reset:SetText('gui.dlib.hudcommons.reset')
		reset.DoClick = function()
			RunConsoleCommand(v.r:GetName(), v.r:GetDefault())
			RunConsoleCommand(v.g:GetName(), v.g:GetDefault())
			RunConsoleCommand(v.b:GetName(), v.b:GetDefault())
			RunConsoleCommand(v.a:GetName(), v.a:GetDefault())
		end

		local picker = vgui.Create('DLibColorMixer', canvas)
		picker:SetConVarR(v.r:GetName())
		picker:SetConVarG(v.g:GetName())
		picker:SetConVarB(v.b:GetName())
		picker:SetConVarA(v.a:GetName())

		picker:Dock(TOP)
		picker:SetTallLayout(true)
		-- picker:SetHeight(200)
	end

	for i, class in ipairs(self.colorNamesN) do
		local v = HUDCommons.ColorsVarsN[class]

		local collapse = vgui.Create('DCollapsibleCategory', panel)
		panel:AddItem(collapse)

		collapse:SetExpanded(false)
		collapse:SetLabel(v.name .. ' (' .. class .. ')')

		if IsValid(collapse.Header) then
			collapse.Header:SetTooltip(v.name .. ' (' .. class .. ')')
		end

		local canvas = vgui.Create('Editablepanel', collapse)
		collapse:SetContents(canvas)

		local reset = vgui.Create('DButton', canvas)
		reset:Dock(TOP)
		reset:SetText('gui.dlib.hudcommons.reset')
		reset.DoClick = function()
			RunConsoleCommand(v.r:GetName(), v.r:GetDefault())
			RunConsoleCommand(v.g:GetName(), v.g:GetDefault())
			RunConsoleCommand(v.b:GetName(), v.b:GetDefault())
		end

		local picker = vgui.Create('DLibColorMixer', canvas)
		picker:SetConVarR(v.r:GetName())
		picker:SetConVarG(v.g:GetName())
		picker:SetConVarB(v.b:GetName())
		picker:SetAllowAlpha(false)

		picker:Dock(TOP)
		picker:SetTallLayout(true)
		-- picker:SetHeight(200)
	end

	self:PopulateColorsMenuOe(panel)
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

	if #self.fontCVars ~= 0 then
		spawnmenu.AddToolMenuOption('Utilities', 'User', self:GetID() .. '_fonts', DLib.i18n.localize('gui.dlib.hudcommons.fonts', self:GetName()), '', '', function(panel)
			self:PopulateFontSettings(panel)
		end)
	end

	if #self.colorNames ~= 0 or #self.colorNamesN ~= 0 then
		spawnmenu.AddToolMenuOption('Utilities', 'User', self:GetID() .. '_colors', DLib.i18n.localize('gui.dlib.hudcommons.colors', self:GetName()), '', '', function(panel)
			self:PopulateColorsMenu(panel)
		end)
	end

	if table.Count(self.positionsConVars) ~= 0 then
		spawnmenu.AddToolMenuOption('Utilities', 'User', self:GetID() .. '_menus_pos', DLib.i18n.localize('gui.dlib.hudcommons.positions', self:GetName()), '', '', function(panel)
			self:PopulatePositionSettings(panel)
		end)
	end
end
