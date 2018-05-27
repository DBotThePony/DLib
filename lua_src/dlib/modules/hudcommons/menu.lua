
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

local HUDCommons = HUDCommons

local function PopulateColors(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()

	if table.Count(HUDCommons.ColorsVars) == 0 then
		Panel:Help('No convars registered!')
		Panel:Help('Nothing to edit.')
		return
	end

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

	if table.Count(HUDCommons.ColorsVarsN) == 0 then
		Panel:Help('No convars registered!')
		Panel:Help('Nothing to edit.')
		return
	end

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

	if #HUDCommons.Position2.XPositions == 0 then
		Panel:Help('No convars registered!')
		Panel:Help('Nothing to edit.')
		return
	end

	panel:Button('Reset all').DoClick = function()
		for name, v in pairs(HUDCommons.Position2.XPositions_CVars) do
			HUDCommons.Position2.XPositions_CVars[name]:Reset()
			HUDCommons.Position2.YPositions_CVars[name]:Reset()
		end
	end

	panel:Button('Enter interactive mode').DoClick = function()
		HUDCommons.EnterPositionEditMode()
	end

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

local IN_EDIT_MODE = false
local PANEL = {}
local MOUSE_LEFT = MOUSE_LEFT
local gui = gui
local ScreenSize = ScreenSize
local ScrWL, ScrHL = ScrWL, ScrHL

function HUDCommons.IsInEditMode()
	return IN_EDIT_MODE
end

surface.CreateFont('DLib.HUDThingName', {
	size = ScreenSize(12),
	font = 'Roboto',
	weight = 500
})

function PANEL:Init()
	self.valid = false
	self.dragging = false
	self.mouseXPrev = 0
	self.mouseYPrev = 0
	self.calculatedX = 0
	self.calculatedY = 0
	self.tw, self.th = 0, 0
	self.name = 'noname'
	self:SetSize(ScreenSize(12), ScreenSize(12))
	self:SetCursor('sizeall')
	self:SetMouseInputEnabled(true)
	hook.Add('PostRenderVGUI', self, self.PostRenderVGUI)
end

function PANEL:Reposition()
	local w, h = self:GetSize()
	self:SetPos(self.calculatedX - w / 2, self.calculatedY - h / 2)
end

function PANEL:SetCVars(name)
	self.convarname = name
	self.name = name:formatname2()
	self.cvarX = HUDCommons.Position2.XPositions_CVars[name]
	self.cvarY = HUDCommons.Position2.YPositions_CVars[name]
	self.calculatedX = self.cvarX:GetFloat() * ScrWL()
	self.calculatedY = self.cvarY:GetFloat() * ScrHL()

	surface.SetFont('DLib.HUDThingName')
	self.tw, self.th = surface.GetTextSize(self.name)

	self:Reposition()
	self.valid = true
end

function PANEL:OnMousePressed(code)
	if code ~= MOUSE_LEFT then return end
	self.dragging = true
	self.mouseXPrev, self.mouseYPrev = gui.MousePos()
end

function PANEL:ApplyChanges()
	self.cvarX:SetFloat(self.calculatedX / ScrWL())
	self.cvarY:SetFloat(self.calculatedY / ScrHL())
end

function PANEL:OnMouseReleased(code)
	if code ~= MOUSE_LEFT then return end
	self.dragging = false

	self:ApplyChanges()
end

function PANEL:Think()
	if not self.valid or not IN_EDIT_MODE then return self:Remove() end
	if not self.dragging then return end

	local x, y = gui.MousePos()
	local deltaX, deltaY = x - self.mouseXPrev, y - self.mouseYPrev
	self.calculatedX = self.calculatedX + deltaX
	self.calculatedY = self.calculatedY + deltaY
	self.mouseXPrev, self.mouseYPrev = x, y

	self:ApplyChanges()
	self:Reposition()
end

local DRAW_COLOR1 = Color(180, 180, 180)
local DRAW_COLOR_TEXT = Color()
local DRAW_COLOR_TEXT_SHADOW = Color(40, 40, 40)
local draw = draw
local surface = surface

function PANEL:PostRenderVGUI()
	surface.SetFont('DLib.HUDThingName')
	local w, h = self.tw, self.th
	local drawPosX, drawPosY = self.calculatedX + ScreenSize(14), self.calculatedY + ScreenSize(2)

	if drawPosX + w > ScrWL() then
		drawPosX = self.calculatedX - ScreenSize(14) - w
	end

	if drawPosY + h > ScrHL() then
		drawPosY = self.calculatedY - ScreenSize(2) - h
	end

	surface.SetTextColor(DRAW_COLOR_TEXT_SHADOW)
	local shift = ScreenSize(1)
	surface.SetTextPos(drawPosX + shift, drawPosY + shift / 2)
	surface.DrawText(self.name)

	surface.SetTextColor(DRAW_COLOR_TEXT)
	surface.SetTextPos(drawPosX, drawPosY)
	surface.DrawText(self.name)
end

function PANEL:Paint(w, h)
	draw.NoTexture()
	surface.SetDrawColor(DRAW_COLOR1)
	surface.DrawRect(0, h / 2 - w * 0.1, w, w * 0.2)
	surface.DrawRect(w / 2 - w * 0.1, 0, w * 0.2, h)
	HUDCommons.DrawCircleHollow(0, 0, w, w * 2, w * 0.2, DRAW_COLOR1)
end

vgui.Register('DLib.EditHUDPosition', PANEL, 'EditablePanel')

local hook = hook
local table = table
local input = input
local KEY_ESCAPE = KEY_ESCAPE
local EDIT_OVERLAY = Color(0, 0, 0, 80)

function HUDCommons.EnterPositionEditMode(filter)
	if IN_EDIT_MODE then return end

	if not filter then
		filter = {}

		for name, v in pairs(HUDCommons.Position2.XPositions_CVars) do
			table.insert(filter, name)
		end
	end

	if #filter == 0 then return end

	IN_EDIT_MODE = true
	local toppanel

	hook.Add('Think', 'DLib.EditHUDPositions', function()
		if not input.IsKeyDown(KEY_ESCAPE) then return end
		IN_EDIT_MODE = false
		toppanel:Remove()
	end)

	toppanel = vgui.Create('EditablePanel')
	toppanel:SetPos(0, 0)
	toppanel:SetSize(ScrWL(), ScrHL())
	toppanel:SetKeyboardInputEnabled(true)
	toppanel:SetMouseInputEnabled(true)
	toppanel:MakePopup()

	toppanel.Paint = function(self, w, h)
		surface.SetDrawColor(EDIT_OVERLAY)
		surface.DrawRect(0, 0, w, h)
	end

	for i, name in ipairs(filter) do
		local button = vgui.Create('DLib.EditHUDPosition', toppanel)
		button:SetCVars(name)
	end

	hook.Run('HUDCommons_EnterEditMode', filter)
end

hook.Add('PopulateToolMenu', 'HUDCommons.PopulateMenus', function()
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Populate', 'HUDCommons Colors', '', '', PopulateColors)
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Populate2', 'HUDCommons Colors 2', '', '', PopulateColors2)
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Positions2', 'HUDCommons Positions 2', '', '', PopulatePositions)
end)
