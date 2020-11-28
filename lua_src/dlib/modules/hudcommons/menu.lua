
--
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

local HUDCommons = DLib.HUDCommons

function HUDCommons.AddColorPanel(Panel, k, v, alpha)
	v = v or alpha and HUDCommons.ColorsVars[k] or not alpha and HUDCommons.ColorsVarsN[k]
	local collapse = vgui.Create('DCollapsibleCategory', Panel)
	Panel:AddItem(collapse)

	collapse:SetExpanded(false)
	collapse:SetLabel(v.name .. ' (' .. k .. ')')

	if IsValid(collapse.Header) then
		collapse.Header:SetTooltip(v.name .. ' (' .. k .. ')')
	end

	local canvas = vgui.Create('EditablePanel', collapse)
	collapse:SetContents(canvas)

	local reset = vgui.Create('DButton', canvas)
	reset:Dock(TOP)
	reset:SetText('gui.dlib.hudcommons.reset')

	function reset.DoClick()
		RunConsoleCommand(v.r:GetName(), v.r:GetDefault())
		RunConsoleCommand(v.g:GetName(), v.g:GetDefault())
		RunConsoleCommand(v.b:GetName(), v.b:GetDefault())

		if alpha then
			RunConsoleCommand(v.a:GetName(), v.a:GetDefault())
		end
	end

	local picker = vgui.Create('DLibColorMixer', canvas)
	picker:SetConVarR(v.r:GetName())
	picker:SetConVarG(v.g:GetName())
	picker:SetConVarB(v.b:GetName())

	if alpha then
		picker:SetConVarA(v.a:GetName())
	else
		picker:SetAllowAlpha(false)
	end

	picker:Dock(TOP)
	picker:SetTallLayout(true)
	-- picker:SetHeight(200)
end

local function PopulateColors(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()

	if table.Count(HUDCommons.ColorsVars) == 0 then
		Panel:Help('gui.dlib.hudcommons.menu.no_cvars_registered')
		Panel:Help('gui.dlib.hudcommons.menu.nothing_to_edit')
		return
	end

	for k, v in SortedPairsByMemberValue(HUDCommons.ColorsVars, 'name') do
		HUDCommons.AddColorPanel(Panel, k, v, true)
	end
end

local function PopulateColors2(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()

	if table.Count(HUDCommons.ColorsVarsN) == 0 then
		Panel:Help('gui.dlib.hudcommons.menu.no_cvars_registered')
		Panel:Help('gui.dlib.hudcommons.menu.nothing_to_edit')
		return
	end

	for k, v in SortedPairsByMemberValue(HUDCommons.ColorsVarsN, 'name') do
		HUDCommons.AddColorPanel(Panel, k, v, false)
	end
end

function HUDCommons.AddPositionPanel(Panel, name)
	local collapse = vgui.Create('DCollapsibleCategory', Panel)
	Panel:AddItem(collapse)
	collapse:SetExpanded(false)
	local cvarX = HUDCommons.Position2.XPositions_CVars[name]
	local cvarY = HUDCommons.Position2.YPositions_CVars[name]
	collapse:SetLabel(name)

	local parent = vgui.Create('EditablePanel', Panel)
	collapse:SetContents(parent)

	parent:Add(Panel:NumSlider('X', cvarX:GetName(), 0, 1, 3))
	parent:Add(Panel:NumSlider('Y', cvarY:GetName(), 0, 1, 3))
	local reset = Panel:Button('gui.dlib.hudcommons.reset')

	parent:Add(reset)

	function reset.DoClick()
		cvarX:Reset()
		cvarY:Reset()
	end
end

local function PopulatePositions(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()

	if table.Count(HUDCommons.Position2.XPositions_original) == 0 then
		Panel:Help('gui.dlib.hudcommons.menu.no_cvars_registered')
		Panel:Help('gui.dlib.hudcommons.menu.nothing_to_edit')
		return
	end

	Panel:Button('gui.dlib.hudcommons.menu.reset_all').DoClick = function()
		for name, v in pairs(HUDCommons.Position2.XPositions_CVars) do
			v:Reset()
			HUDCommons.Position2.YPositions_CVars[name]:Reset()
		end
	end

	Panel:Button('gui.dlib.hudcommons.menu.interactive_mode').DoClick = function()
		HUDCommons.EnterPositionEditMode()
	end

	for name in SortedPairs(HUDCommons.Position2.XPositions_CVars) do
		HUDCommons.AddPositionPanel(Panel, name)
	end
end

local IN_EDIT_MODE = false
local PANEL = {}
local MOUSE_LEFT = MOUSE_LEFT
local gui = gui
local ScreenSize = ScreenSize
local ScrWL, ScrHL = ScrWL, ScrHL

--[[
	@doc
	@panel DLib.EditHUDPosition

	@client
	@internal
]]

--[[
	@doc
	@fname DLib.HUDCommons.IsInEditMode

	@client
	@returns
	boolean
]]
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
	self.direction = 'LEFT'
	self.fade = 0
	self.name = 'noname'
	self:SetSize(ScreenSize(12), ScreenSize(12))
	self:SetCursor('sizeall')
	self:SetMouseInputEnabled(true)
	hook.Add('PostRenderVGUI', self, self.PostRenderVGUI)
end

function PANEL:Reposition()
	local w, h = self:GetSize()
	self:SetPos(self.calculatedX - w / 2, self.calculatedY - h / 2)
	self.direction = self.calculatedX / ScrWL() < 0.33 and 'LEFT' or self.calculatedX / ScrWL() > 0.66 and 'RIGHT' or 'CENTER'
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

function PANEL:Reset()
	self.cvarX:Reset()
	self.cvarY:Reset()

	timer.Simple(0, function()
		self.calculatedX = self.cvarX:GetFloat() * ScrWL()
		self.calculatedY = self.cvarY:GetFloat() * ScrHL()
		self:Reposition()
		input.SetCursorPos(self.calculatedX, self.calculatedY)
	end)
end

function PANEL:OnMousePressed(code)
	if code ~= MOUSE_LEFT then return end
	self.dragging = true
	self.mouseXPrev, self.mouseYPrev = input.GetCursorPos()
end

function PANEL:ApplyChanges()
	self.cvarX:SetFloat(self.calculatedX / ScrWL())
	self.cvarY:SetFloat(self.calculatedY / ScrHL())
end

function PANEL:OnMouseReleased(code)
	if code == MOUSE_RIGHT then
		local menu = DermaMenu()
		menu:AddOption('Hide', function() self:Remove() end)
		menu:AddOption('Reset', function() self:Reset() end)
		menu:AddOption('Close', function() end)
		menu:Open()
		self.openMenu = menu

		return
	end

	if code ~= MOUSE_LEFT then return end
	self.dragging = false

	self:ApplyChanges()
end

local RealFrameTime = RealFrameTime

function PANEL:Think()
	if not self.valid or not IN_EDIT_MODE then return self:Remove() end

	if self:IsHovered() then
		self.fade = math.min(0.7, self.fade + RealFrameTime() * 4)
	else
		self.fade = math.max(0, self.fade - RealFrameTime() * 4)
	end

	if not self.dragging then return end

	local x, y = input.GetCursorPos()
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
	if IsValid(self.openMenu) then return end
	surface.SetFont('DLib.HUDThingName')
	local w, h = self.tw, self.th
	local drawPosX, drawPosY = self.calculatedX + ScreenSize(14), self.calculatedY + ScreenSize(2)

	if self.direction == 'RIGHT' then
		drawPosX = self.calculatedX - ScreenSize(14) - w
	elseif self.direction == 'CENTER' then
		drawPosX = self.calculatedX - w / 2
	end

	if drawPosY + h > ScrHL() then
		drawPosY = self.calculatedY - ScreenSize(2) - h
	end

	local matrix = Matrix()

	if self.direction == 'RIGHT' then
		matrix:Translate(Vector(drawPosX + ScreenSize(14), drawPosY + self.tw * 0.47))
		matrix:Rotate(Angle(0, -30, 0))
	elseif self.direction == 'LEFT' then
		matrix:Translate(Vector(drawPosX - ScreenSize(12), drawPosY - ScreenSize(12)))
		matrix:Rotate(Angle(0, -30, 0))
	else
		matrix:Translate(Vector(drawPosX, drawPosY + ScreenSize(4)))
	end

	cam.PushModelMatrix(matrix)

	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	surface.SetTextColor(0, 0, 0, 255 * (1 - self.fade))
	local shift = ScreenSize(1)
	surface.SetTextPos(shift, shift / 2)
	surface.DrawText(self.name)

	surface.SetTextColor(255, 255, 255,  255 * (1 - self.fade))
	surface.SetTextPos(0, 0)
	surface.DrawText(self.name)

	render.PopFilterMag()
	render.PopFilterMin()

	cam.PopModelMatrix()
end

local function DrawRect(x, y, w, h)
	x = x:ceil()
	y = y:ceil()
	w = w:ceil()
	h = h:ceil()

	if w % 2 == 0 then
		w = w + 1
	end

	if h % 2 == 0 then
		h = h + 1
	end

	surface.DrawRect(x ~= 0 and (x - w / 2 - 1):ceil() or 0, y ~= 0 and (y - h / 2 - 1):ceil() or 0, w, h)
end

function PANEL:Paint(w, h)
	draw.NoTexture()
	surface.SetDrawColor(DRAW_COLOR1)
	DrawRect(0, h / 2, w, h * 0.1)
	DrawRect(w / 2, 0, w * 0.1, h)
end

vgui.Register('DLib.EditHUDPosition', PANEL, 'EditablePanel')

local hook = hook
local table = table
local input = input
local KEY_ESCAPE = KEY_ESCAPE
local EDIT_OVERLAY = Color(0, 0, 0, 80)

--[[
	@doc
	@fname DLib.HUDCommons.EnterPositionEditMode
	@args table filter

	@desc
	`filter` is array containing `elemID` of elements from `Position2` submodule
	which are objects to edit
	if `filter` is omitted, everything will be added to filter instead
	if `filter` is empty, this function does nothing
	@enddesc

	@client
]]
function HUDCommons.EnterPositionEditMode(filter)
	if IN_EDIT_MODE then return end

	if not filter then
		filter = {}

		for name, v in pairs(HUDCommons.Position2.XPositions_CVars) do
			table.insert(filter, name)
		end
	end

	if #filter == 0 then return end

	notification.AddLegacy(DLib.i18n.localize('message.dlib.hudcommons.edit.notice'), NOTIFY_GENERIC, 6)

	IN_EDIT_MODE = true
	local toppanel

	hook.Add('Think', 'DLib.EditHUDPositions', function()
		if not input.IsKeyDown(KEY_ESCAPE) then return end
		IN_EDIT_MODE = false
		toppanel:Remove()
		hook.Run('HUDCommons_ExitEditMode', filter)
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

--[[
	@doc
	@hook HUDCommons_EnterEditMode
	@args table filter

	@desc
	Called right after call of `DLib.HUDCommons.EnterPositionEditMode`
	`DLib.HUDCommons.IsInEditMode` returns `true` in this hook
	@enddesc

	@client
]]

--[[
	@doc
	@hook HUDCommons_ExitEditMode
	@args table filter

	@desc
	`DLib.HUDCommons.IsInEditMode` returns `false` in this hook
	@enddesc

	@client
]]
hook.Add('PopulateToolMenu', 'HUDCommons.PopulateMenus', function()
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Populate', 'gui.dlib.hudcommons.color_menu', '', '', PopulateColors)
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Populate2', 'gui.dlib.hudcommons.color_menu2', '', '', PopulateColors2)
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'HUDCommons.Positions2', 'gui.dlib.hudcommons.positions_menu', '', '', PopulatePositions)
end)
