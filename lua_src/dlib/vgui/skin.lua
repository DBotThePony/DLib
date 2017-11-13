
-- Copyright (C) 2016-2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- this needs cleanup

local surface = surface
local draw = draw
local Color = Color
local GWEN = GWEN
local nomat = surface.GetTextureID('gui/corner8')
local surface_SetTexture = surface.SetTexture
local surface_DrawRect = surface.DrawRect
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local surface_SetFont = surface.SetFont
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine

local function Simple_DrawBox(x, y, w, h, color)
	if color then
		surface_SetDrawColor(color)
	end

	surface_SetTexture(nomat)
	surface_DrawRect(x, y, w, h)
end

local function Simple_DrawText(text, font, x, y, col, center)
	if font then
		surface_SetFont(font)
	end

	if center then
		x = x - surface_GetTextSize(text) / 2
	end

	if col then
		surface_SetTextColor(col.r, col.g, col.b, col.a)
	end

	surface_SetTextPos(x, y)
	surface_DrawText(text)
end

local colors = {}
colors.white = Color(255, 255, 255)
colors.black = Color(0, 0, 0)
colors.gray_bright = Color(225, 225, 225)
colors.gray = Color(200, 200, 200)
colors.gray_dark = Color(175, 175, 175)
colors.bg_bright = Color(45, 45, 45, 200)

local White = Color(255, 255, 255)

local CColors = {}

function GetColor(id, r, g, b, a)
	CColors[id] = CColors[id] or Color(r, g, b, a)
	return CColors[id]
end

local WINDOW_ALPHA = 200

SKIN = {}
local Skin, skin = SKIN, SKIN

surface.CreateFont('DLib.SkinRoboto', {
	font = 'Roboto',
	size = 18,
	weight = 500,
	extended = true,
})

SKIN.PrintName  = 'DLib FlatBlack Skin utilizing Lua draw functions'
SKIN.Author  = 'DBot'
SKIN.DermaVersion = 1
SKIN.GwenTexture = Material('gwenskin/GModDefault.png')
SKIN.fontFrame = 'DLib.SkinRoboto'
SKIN.texGradientUp = Material('gui/gradient_up')
SKIN.texGradientDown = Material('gui/gradient_down')
SKIN.fontTab = 'DLib.SkinRoboto'
SKIN.fontCategoryHeader = 'TabLarge'

--Colors
--Left unchanged tabs from original skin file
SKIN.bg_color  = Color(55, 55, 55, WINDOW_ALPHA)
SKIN.bg_color_sleep  = Color(70, 70, 70, WINDOW_ALPHA)
SKIN.bg_color_dark = Color(0, 0, 0, WINDOW_ALPHA)
SKIN.bg_color_bright = Color(220, 220, 220, WINDOW_ALPHA)
SKIN.frame_border = Color(50, 50, 50, WINDOW_ALPHA)

SKIN.control_color  = Color(120, 120, 120)
SKIN.control_color_highlight = Color(150, 150, 150, 255)
SKIN.control_color_active  = Color(110, 150, 250, 255)
SKIN.control_color_bright  = Color(255, 200, 100, 255)
SKIN.control_color_dark  = Color(100, 100, 100, 255)

SKIN.bg_alt1  = Color(50, 50, 50, WINDOW_ALPHA)
SKIN.bg_alt2  = Color(55, 55, 55, WINDOW_ALPHA)

SKIN.listview_hover = Color(70, 70, 70, 255)
SKIN.listview_selected = Color(100, 170, 220, 255)

SKIN.text_bright = Color(255, 255, 255, 255)
SKIN.text_normal = Color(255, 255, 255, 255)
SKIN.text_dark = Color(175, 175, 175, 255)
SKIN.text_highlight = Color(255, 20, 20, 255)

SKIN.combobox_selected = SKIN.listview_selected

SKIN.panel_transback = Color(255, 255, 255, 50)
SKIN.tooltip = Color(255, 245, 175, 255)

SKIN.colPropertySheet  = Color(170, 170, 170, 255)
SKIN.colTab			  = SKIN.colPropertySheet
SKIN.colTabInactive = Color(140, 140, 140, 255)
SKIN.colTabShadow = Color(0, 0, 0, 170)
SKIN.colTabText		  = Color(255, 255, 255, 255)
SKIN.colTabTextInactive = Color(0, 0, 0, 200)

SKIN.colCollapsibleCategory = Color(255, 255, 255, 20)

SKIN.colCategoryText = Color(255, 255, 255, 255)
SKIN.colCategoryTextInactive = Color(200, 200, 200, 255)

SKIN.colNumberWangBG = Color(255, 240, 150, 255)
SKIN.colTextEntryBG = Color(200, 200, 200, 255)
SKIN.colTextEntryBorder = Color(140, 140, 140, 255)
SKIN.colTextEntryText = Color(25, 25, 25, 255)
SKIN.colTextEntryTextHighlight = Color(255, 255, 255, 255)
SKIN.colTextEntryTextCursor = Color(0, 0, 100, 255)

SKIN.colMenuBG = Color(255, 255, 255, 200)
SKIN.colMenuBorder = Color(0, 0, 0, 200)

SKIN.colButtonText = Color(255, 255, 255, 255)
SKIN.colButtonTextDisabled = Color(255, 255, 255, 55)
SKIN.colButtonBorder = Color(20, 20, 20, 255)
SKIN.colButtonBorderHighlight = Color(255, 255, 255, 50)
SKIN.colButtonBorderShadow = Color(0, 0, 0, 100)

Skin.bg_verybright  = Color(80, 80, 80, 200)
Skin.bg_hightlight = Color(40, 80, 40, 200)

--Colors aliases
SKIN.background = SKIN.bg_color
SKIN.background_inactive  = SKIN.bg_color_dark
SKIN.frame_top  = Color(90, 90, 90, WINDOW_ALPHA)

SKIN.tex = {}

Skin.tex.SelectColor = Color(203, 225, 203, 50)

function SKIN.tex.Selection		 (x, y, w, h) Simple_DrawBox(x, y, w, h, Skin.tex.SelectColor) end

SKIN.tex.Panels = {}
function SKIN.tex.Panels.Normal(x, y, w, h) Simple_DrawBox(x, y, w, h, colors.bg_bright) end
function SKIN.tex.Panels.Bright(x, y, w, h) Simple_DrawBox(x, y, w, h, Skin.bg_verybright) end
function SKIN.tex.Panels.Dark(x, y, w, h) Simple_DrawBox(x, y, w, h, Skin.background) end
function SKIN.tex.Panels.Highlight(x, y, w, h) Simple_DrawBox(x, y, w, h, Skin.bg_hightlight) end

skin.ButtonHoverColor = Color(200, 200, 200, 150)
skin.ButtonAlpha = 150

function SKIN.tex.Button(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h, Color(self.Neon, self.Neon, self.Neon, skin.ButtonAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)
end

function SKIN.tex.Button_Hovered(x, y, w, h, self)
	if not self then return end
	self.Neon = self.Neon or 0

	Simple_DrawBox(x, y, w, h, Color(self.Neon, self.Neon, self.Neon, skin.ButtonAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 150)
end

function SKIN.tex.Button_Down(x, y, w, h, self)
	if not self then return end
	self.Neon = self.Neon or 0

	Simple_DrawBox(x, y, w, h, skin.ButtonHoverColor)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 150)
end

function SKIN.tex.Button_Dead(x, y, w, h, self)
	if not self then return end
	self.Neon = self.Neon or 0

	Simple_DrawBox(x, y, w, h, skin.ButtonHoverColor)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 150)
end

SKIN.tex.Shadow = GWEN.CreateTextureBorder(448, 0, 31, 31, 8, 8, 8, 8)

function SKIN.tex.Tree(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, skin.bg_color)
end

skin.CheckBoxBG = Color(30, 30, 30)
skin.CheckBoxBGD = Color(70, 70, 70)

skin.CheckBoxC = Color(105, 255, 250)
skin.CheckBoxU = Color(255, 148, 148)

function SKIN.tex.Checkbox_Checked(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.CheckBoxBG)
	Simple_DrawBox(x + 2, y + 2, w - 4, h - 4, skin.CheckBoxC)
end

function SKIN.tex.Checkbox(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.CheckBoxBG)
	Simple_DrawBox(x + 2, y + 2, w - 4, h - 4, skin.CheckBoxU)
end

function SKIN.tex.CheckboxD_Checked(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.CheckBoxBGD)
	Simple_DrawBox(x + 2, y + 2, w - 4, h - 4, skin.CheckBoxC)
end

function SKIN.tex.CheckboxD(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.CheckBoxBGD)
	Simple_DrawBox(x + 2, y + 2, w - 4, h - 4, skin.CheckBoxU)
end

SKIN.tex.TreePlus = GWEN.CreateTextureNormal(448, 96, 15, 15)
SKIN.tex.TreeMinus = GWEN.CreateTextureNormal(464, 96, 15, 15)
SKIN.tex.TextBox = GWEN.CreateTextureBorder(0, 150, 127, 21, 4, 4, 4, 4)
SKIN.tex.TextBox_Focus = GWEN.CreateTextureBorder(0, 172, 127, 21, 4, 4, 4, 4)
SKIN.tex.TextBox_Disabled = GWEN.CreateTextureBorder(0, 194, 127, 21, 4, 4, 4, 4)

function SKIN.tex.MenuBG_Column(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, skin.MenuHoverColor)
end

function SKIN.tex.MenuBG(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, skin.bg_color)
end

skin.MenuHoverColor = Color(140, 140, 140)
skin.MenuSpacer = Color(200, 200, 200)
skin.MenuSpacerStrip = Color(100, 100, 100, 200)

function SKIN.tex.MenuBG_Hover(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, skin.MenuHoverColor)
end

function SKIN.tex.MenuBG_Spacer(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, skin.MenuSpacer)
end

function SKIN.tex.Menu_Strip(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, skin.MenuSpacerStrip)
end

SKIN.tex.Menu_Check = GWEN.CreateTextureNormal(448, 112, 15, 15)

function SKIN.tex.Tab_Control(x, y, w, h)
	Simple_DrawBox(x, y, w, h, GetColor('TabControl', 0, 0, 0, 200))
end

function SKIN.tex.TabB_Active(x, y, w, h, self)
	Simple_DrawBox(x + 4, y, w - 8, h - 8, Selected)
end

function SKIN.tex.TabB_Inactive(x, y, w, h, self)
	Simple_DrawBox(x + 4, y + 2, w - 8, h - 2, UnSelected)
	Simple_DrawBox(x + 4, y + 12, w - 8, h - 2, UnSelected2)
end

local Selected = Color(200, 255, 200, 150)
local UnSelected = Color(80, 80, 80, 200)
local UnSelected2 = Color(255, 255, 255, 20)

function SKIN.tex.TabT_Active(x, y, w, h, self)
	Simple_DrawBox(x + 4, y, w - 8, h - 8, Selected)
end

function SKIN.tex.TabT_Inactive(x, y, w, h, self)
	Simple_DrawBox(x + 4, y + 2, w - 8, h - 2, UnSelected)
	Simple_DrawBox(x + 4, y + 12, w - 8, h - 2, UnSelected2)
end

SKIN.tex.TabL_Active = GWEN.CreateTextureBorder(64, 384, 31, 63, 8, 8, 8, 8)
SKIN.tex.TabL_Inactive = GWEN.CreateTextureBorder(64 + 128, 384, 31, 63, 8, 8, 8, 8)
SKIN.tex.TabR_Active = GWEN.CreateTextureBorder(96, 384, 31, 63, 8, 8, 8, 8)
SKIN.tex.TabR_Inactive = GWEN.CreateTextureBorder(96 + 128, 384, 31, 63, 8, 8, 8, 8)
SKIN.tex.Tab_Bar = GWEN.CreateTextureBorder(128, 352, 127, 31, 4, 4, 4, 4)

SKIN.tex.Window = {}

function SKIN.tex.Window.Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, 25, skin.background) -- top
	Simple_DrawBox(x, y, w, h, skin.background)
end

function SKIN.tex.Window.Inactive(x, y, w, h)
	Simple_DrawBox(x, y, w, 25, skin.background) -- top
	Simple_DrawBox(x, y, w, h, skin.background_inactive)
end

skin.CloseAlpha = 150
skin.CloseHoverCol = Color(200, 130, 130, skin.CloseAlpha)

function SKIN.tex.Window.Close(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(200, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(255, self.Neon * 3, self.Neon * 3, self.Neon * 3)
	surface_DrawLine(x + 2, y + 5, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 16, w - 4, y + 5)
end

function SKIN.tex.Window.Close_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(200, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)
	surface_SetDrawColor(255, self.Neon * 3, self.Neon * 3, self.Neon * 3)
	surface_DrawLine(x + 2, y + 5, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 16, w - 4, y + 5)
end

function SKIN.tex.Window.Close_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, skin.CloseHoverCol)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(255, 200, 200)
	surface_DrawLine(x + 2, y + 5, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 16, w - 4, y + 5)
end

--Maximize
function SKIN.tex.Window.Maxi(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 24, w - 4, h - 24)
	surface_DrawLine(x + 2, h - 16, x + 2, h - 24)
	surface_DrawLine(w - 4, h - 16, w - 4, h - 24)
end

function SKIN.tex.Window.Maxi_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 24, w - 4, h - 24)
	surface_DrawLine(x + 2, h - 16, x + 2, h - 24)
	surface_DrawLine(w - 4, h - 16, w - 4, h - 24)
end

local Col = Color(200, 200, 200)

function SKIN.tex.Window.Maxi_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Col)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 24, w - 4, h - 24)
	surface_DrawLine(x + 2, h - 16, x + 2, h - 24)
	surface_DrawLine(w - 4, h - 16, w - 4, h - 24)
end

function SKIN.tex.Window.Restore(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 28, w - 4, h - 28)
	surface_DrawLine(x + 2, h - 16, x + 2, h - 28)
	surface_DrawLine(w - 4, h - 16, w - 4, h - 28)
end

function SKIN.tex.Window.Restore_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 28, w - 4, h - 28)
	surface_DrawLine(x + 2, h - 16, x + 2, h - 28)
	surface_DrawLine(w - 4, h - 16, w - 4, h - 28)
end

function SKIN.tex.Window.Restore_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Col)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
	surface_DrawLine(x + 2, h - 28, w - 4, h - 28)
	surface_DrawLine(x + 2, h - 16, x + 2, h - 28)
	surface_DrawLine(w - 4, h - 16, w - 4, h - 28)
end

function SKIN.tex.Window.Mini(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
end

function SKIN.tex.Window.Mini_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
end

function SKIN.tex.Window.Mini_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - 11, Col)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - 16, w - 4, h - 16)
end

SKIN.tex.Scroller = {}

SKIN.tex.Scroller.BackColor = Color(0, 0, 0, 50)
SKIN.tex.Scroller.ScrollerColI = Color(200, 200, 200, 255)
SKIN.tex.Scroller.ScrollerColD = Color(140, 140, 140, 255)
SKIN.tex.Scroller.ScrollerColH = Color(255, 255, 255, 255)
SKIN.tex.Scroller.ScrollerColP = Color(200, 255, 200, 255)
SKIN.tex.Scroller.BColor = Color(130, 130, 130, 200)
SKIN.tex.Scroller.BColorH = Color(160, 160, 160, 200)
SKIN.tex.Scroller.BColorP = Color(200, 200, 200, 200)
SKIN.tex.Scroller.BColorD = Color(30, 30, 30, 200)
SKIN.tex.Scroller.TextColr = Color(255, 255, 255)

function SKIN.tex.Scroller.TrackV(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BackColor)
end

function SKIN.tex.Scroller.ButtonV_Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.ScrollerColI)
end

function SKIN.tex.Scroller.ButtonV_Hover(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.ScrollerColH)
end

function SKIN.tex.Scroller.ButtonV_Down(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.ScrollerColP)
end

function SKIN.tex.Scroller.ButtonV_Disabled(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.ScrollerColD)
end

SKIN.tex.Scroller.TrackH = GWEN.CreateTextureBorder(384, 128, 127, 15, 4, 4, 4, 4)
SKIN.tex.Scroller.ButtonH_Normal = GWEN.CreateTextureBorder(384, 128 + 16, 127, 15, 4, 4, 4, 4)
SKIN.tex.Scroller.ButtonH_Hover = GWEN.CreateTextureBorder(384, 128 + 32, 127, 15, 4, 4, 4, 4)
SKIN.tex.Scroller.ButtonH_Down = GWEN.CreateTextureBorder(384, 128 + 48, 127, 15, 4, 4, 4, 4)
SKIN.tex.Scroller.ButtonH_Disabled = GWEN.CreateTextureBorder(384, 128 + 64, 127, 15, 4, 4, 4, 4)

--Left
function SKIN.tex.Scroller.LeftButton_Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColor)
	Simple_DrawText('◀', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.LeftButton_Hover(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorH)
	Simple_DrawText('◀', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.LeftButton_Down(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorP)
	Simple_DrawText('◀', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.LeftButton_Disabled(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorD)
	Simple_DrawText('◀', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

--Up
function SKIN.tex.Scroller.UpButton_Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColor)
	Simple_DrawText('▲', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.UpButton_Hover(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorH)
	Simple_DrawText('▲', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.UpButton_Down(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorP)
	Simple_DrawText('▲', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.UpButton_Disabled(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorD)
	Simple_DrawText('▲', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

--Down
function SKIN.tex.Scroller.DownButton_Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColor)
	Simple_DrawText('▼', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.DownButton_Hover(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorH)
	Simple_DrawText('▼', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.DownButton_Down(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorP)
	Simple_DrawText('▼', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.DownButton_Disabled(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorD)
	Simple_DrawText('▼', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

--Right
function SKIN.tex.Scroller.RightButton_Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColor)
	Simple_DrawText('▶', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.RightButton_Hover(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorH)
	Simple_DrawText('▶', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.RightButton_Down(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorP)
	Simple_DrawText('▶', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

function SKIN.tex.Scroller.RightButton_Disabled(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Scroller.BColorD)
	Simple_DrawText('▶', 'Default', x + 2, y + 1, skin.tex.Scroller.TextColr)
end

SKIN.tex.Menu = {}
SKIN.tex.Menu.RightArrow = GWEN.CreateTextureNormal(464, 112, 15, 15)

SKIN.tex.Input = {}

SKIN.tex.Input.ComboBox = {}
function SKIN.tex.Input.ComboBox.Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, h, GetColor('ComboBoxNormal', 30, 30, 30, 150))
end

function SKIN.tex.Input.ComboBox.Hover(x, y, w, h)
	Simple_DrawBox(x, y, w, h, GetColor('ComboBoxHover', 60, 80, 60, 150))
end

function SKIN.tex.Input.ComboBox.Down(x, y, w, h)
	Simple_DrawBox(x, y, w, h, GetColor('ComboBoxDown', 80, 120, 80, 150))
end

function SKIN.tex.Input.ComboBox.Disabled(x, y, w, h)
	Simple_DrawBox(x, y, w, h, GetColor('ComboBoxDisabled', 0, 0, 0, 130))
end

--Untouched original
SKIN.tex.Input.ComboBox.Button = {}
SKIN.tex.Input.ComboBox.Button.Normal = GWEN.CreateTextureNormal(496, 272, 15, 15)
SKIN.tex.Input.ComboBox.Button.Hover = GWEN.CreateTextureNormal(496, 272 + 16, 15, 15)
SKIN.tex.Input.ComboBox.Button.Down = GWEN.CreateTextureNormal(496, 272 + 32, 15, 15)
SKIN.tex.Input.ComboBox.Button.Disabled = GWEN.CreateTextureNormal(496, 272 + 48, 15, 15)

SKIN.tex.Input.UpDown = {}
SKIN.tex.Input.UpDown.Up = {}
SKIN.tex.Input.UpDown.Up.Normal = GWEN.CreateTextureCentered(384, 112, 7, 7)
SKIN.tex.Input.UpDown.Up.Hover = GWEN.CreateTextureCentered(384 + 8, 112, 7, 7)
SKIN.tex.Input.UpDown.Up.Down = GWEN.CreateTextureCentered(384 + 16, 112, 7, 7)
SKIN.tex.Input.UpDown.Up.Disabled = GWEN.CreateTextureCentered(384 + 24, 112, 7, 7)

SKIN.tex.Input.UpDown.Down = {}
SKIN.tex.Input.UpDown.Down.Normal = GWEN.CreateTextureCentered(384, 120, 7, 7)
SKIN.tex.Input.UpDown.Down.Hover = GWEN.CreateTextureCentered(384 + 8, 120, 7, 7)
SKIN.tex.Input.UpDown.Down.Down = GWEN.CreateTextureCentered(384 + 16, 120, 7, 7)
SKIN.tex.Input.UpDown.Down.Disabled = GWEN.CreateTextureCentered(384 + 24, 120, 7, 7)

SKIN.tex.Input.Slider = {}
SKIN.tex.Input.Slider.H = {}
SKIN.tex.Input.Slider.H.Normal = GWEN.CreateTextureNormal(416, 32, 15, 15)
SKIN.tex.Input.Slider.H.Hover = GWEN.CreateTextureNormal(416, 32 + 16, 15, 15)
SKIN.tex.Input.Slider.H.Down = GWEN.CreateTextureNormal(416, 32 + 32, 15, 15)
SKIN.tex.Input.Slider.H.Disabled = GWEN.CreateTextureNormal(416, 32 + 48, 15, 15)

SKIN.tex.Input.Slider.V = {}
SKIN.tex.Input.Slider.V.Normal = GWEN.CreateTextureNormal(416 + 16, 32, 15, 15)
SKIN.tex.Input.Slider.V.Hover = GWEN.CreateTextureNormal(416 + 16, 32 + 16, 15, 15)
SKIN.tex.Input.Slider.V.Down = GWEN.CreateTextureNormal(416 + 16, 32 + 32, 15, 15)
SKIN.tex.Input.Slider.V.Disabled = GWEN.CreateTextureNormal(416 + 16, 32 + 48, 15, 15)

SKIN.tex.Input.ListBox = {}
SKIN.tex.Input.ListBox.BG = Color(0, 0, 0, 200)
SKIN.tex.Input.ListBox.First = Color(100, 100, 100)
SKIN.tex.Input.ListBox.Second = Color(125, 125, 125)
SKIN.tex.Input.ListBox.Select = Color(75, 125, 75)

function SKIN.tex.Input.ListBox.Background(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Input.ListBox.BG)
end

function SKIN.tex.Input.ListBox.Hovered(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Input.ListBox.BG)
end

function SKIN.tex.Input.ListBox.EvenLine(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Input.ListBox.First)
end

function SKIN.tex.Input.ListBox.OddLine(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Input.ListBox.Second)
end

function SKIN.tex.Input.ListBox.EvenLineSelected(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Input.ListBox.Select)
end

function SKIN.tex.Input.ListBox.OddLineSelected(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.Input.ListBox.Select)
end

SKIN.tex.ProgressBar = {}
function SKIN.tex.ProgressBar.Back(x, y, w, h)
	Simple_DrawBox(x, y, w, h, Color(90, 90, 90))
end

function SKIN.tex.ProgressBar.Front(x, y, w, h)
	Simple_DrawBox(x + 2, y + 2, w - 4, h - 4, Color(160, 200, 130))
end

SKIN.tex.CategoryList = {}
SKIN.tex.CategoryList.BG = Color(65, 65, 65, 255)
SKIN.tex.CategoryList.Headerr = Color(200, 200, 200, 180)

function SKIN.tex.CategoryList.Outer(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.CategoryList.BG)
end

function SKIN.tex.CategoryList.Inner(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.CategoryList.BG)
end

function SKIN.tex.CategoryList.Header(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.tex.CategoryList.Headerr)
end

function SKIN.tex.Tooltip(x, y, w, h)
	Simple_DrawBox(x, y, w, h, skin.background)
end

SKIN.Colours = {} --British english
SKIN.Colors = SKIN.Colours --American english

SKIN.Colours.Window = {}
SKIN.Colours.Window.TitleActive = Color(255, 255, 255)
SKIN.Colours.Window.TitleInactive = Color(200, 200, 200)

SKIN.Colours.Button = {}
SKIN.Colours.Button.Normal = Color(200, 200, 200, 225)
SKIN.Colours.Button.Disabled = Color(145, 145, 145)
SKIN.Colours.Button.Down = Color(255, 255, 255)
SKIN.Colours.Button.Hover = Color(225, 225, 225)
SKIN.Colours.Button.Menu = Color(255, 255, 255)

SKIN.Colours.Tab = {}
SKIN.Colours.Tab.Active = {}
SKIN.Colours.Tab.Active.Normal = Color(120, 120, 120)
SKIN.Colours.Tab.Active.Hover = Color(0, 120, 0)
SKIN.Colours.Tab.Active.Down = Color(0, 140, 0)
SKIN.Colours.Tab.Active.Disabled = Color(170, 150, 170)

SKIN.Colours.Tab.Inactive = {}
SKIN.Colours.Tab.Inactive.Normal = Color(200, 200, 200)
SKIN.Colours.Tab.Inactive.Hover = Color(200, 225, 200)
SKIN.Colours.Tab.Inactive.Down = Color(200, 255, 200)
SKIN.Colours.Tab.Inactive.Disabled = Color(170, 170, 170)

SKIN.Colours.Label = {}
SKIN.Colours.Label.Default = Color(255, 255, 255)
SKIN.Colours.Label.Bright = Color(255, 255, 255)
SKIN.Colours.Label.Dark = Color(225, 225, 225)
SKIN.Colours.Label.Highlight = Color(200, 255, 200)

SKIN.Colours.Tree = {}
SKIN.Colours.Tree.Lines = Color(255, 255, 255) ---- !!!
SKIN.Colours.Tree.Normal = Color(200, 200, 200)
SKIN.Colours.Tree.Hover = Color(200, 255, 200)
SKIN.Colours.Tree.Selected = Color(255, 255, 255)

SKIN.Colours.Properties = {}
SKIN.Colours.Properties.Line_Normal = GWEN.TextureColor(4 + 8 * 12, 508)
SKIN.Colours.Properties.Line_Selected = GWEN.TextureColor(4 + 8 * 13, 508)
SKIN.Colours.Properties.Line_Hover = GWEN.TextureColor(4 + 8 * 12, 500)
SKIN.Colours.Properties.Title = Color(255, 255, 255)
SKIN.Colours.Properties.Column_Normal = GWEN.TextureColor(4 + 8 * 14, 508)
SKIN.Colours.Properties.Column_Selected = GWEN.TextureColor(4 + 8 * 15, 508)
SKIN.Colours.Properties.Column_Hover = GWEN.TextureColor(4 + 8 * 14, 500)
SKIN.Colours.Properties.Border = GWEN.TextureColor(4 + 8 * 15, 500)
SKIN.Colours.Properties.Label_Normal = Color(200, 200, 200)
SKIN.Colours.Properties.Label_Selected = Color(255, 255, 255)
SKIN.Colours.Properties.Label_Hover = Color(200, 255, 200)

SKIN.Colours.Category = {}

SKIN.Colours.Category.Header = Color(255, 255, 255)
SKIN.Colours.Category.Header_Closed = Color(0, 0, 0)

SKIN.Colours.Category.Line = {}
SKIN.Colours.Category.Line.Text = Color(200, 200, 200)
SKIN.Colours.Category.Line.Text_Hover = Color(200, 255, 200)
SKIN.Colours.Category.Line.Text_Selected = Color(255, 255, 255)
SKIN.Colours.Category.Line.Button = skin.background
SKIN.Colours.Category.Line.Button_Hover = Color(100, 100, 100)
SKIN.Colours.Category.Line.Button_Selected = Color(130, 130, 130)

SKIN.Colours.Category.LineAlt = {}
SKIN.Colours.Category.LineAlt.Text = Color(200, 200, 200)
SKIN.Colours.Category.LineAlt.Text_Hover = Color(200, 255, 200)
SKIN.Colours.Category.LineAlt.Text_Selected = Color(255, 255, 255)
SKIN.Colours.Category.LineAlt.Button = skin.background
SKIN.Colours.Category.LineAlt.Button_Hover = Color(100, 100, 100)
SKIN.Colours.Category.LineAlt.Button_Selected = Color(130, 130, 130)

SKIN.Colours.TooltipText = Color(255, 255, 255)

--There is panel functions

--[[---------------------------------------------------------
	ExpandButton
-----------------------------------------------------------]]
function SKIN:PaintExpandButton(panel, w, h)

	if not panel:GetExpanded() then
		self.tex.TreePlus(0, 0, w, h)
	else
		self.tex.TreeMinus(0, 0, w, h)
	end

end

--[[---------------------------------------------------------
	TextEntry
-----------------------------------------------------------]]
function SKIN:PaintTextEntry(panel, w, h)
	if panel.m_bBackground then
		if panel:GetDisabled() then
			self.tex.TextBox_Disabled(0, 0, w, h)
		elseif panel:HasFocus() then
			self.tex.TextBox_Focus(0, 0, w, h)
		else
			self.tex.TextBox(0, 0, w, h)
		end
	end

	panel:DrawTextEntryText(panel.m_colText, panel.m_colHighlight, panel.m_colCursor)
end

function SKIN:SchemeTextEntry(panel) ---------------------- TODO
	panel:SetTextColor(self.colTextEntryText)
	panel:SetHighlightColor(self.colTextEntryTextHighlight)
	panel:SetCursorColor(self.colTextEntryTextCursor)
end

--[[---------------------------------------------------------
	Menu
-----------------------------------------------------------]]
function SKIN:PaintMenu(panel, w, h)

	if panel:GetDrawColumn() then
		self.tex.MenuBG_Column(0, 0, w, h)
	else
		self.tex.MenuBG(0, 0, w, h)
	end

end

--[[---------------------------------------------------------
	Menu
-----------------------------------------------------------]]
function SKIN:PaintMenuSpacer(panel, w, h)
	self.tex.MenuBG(0, 0, w, h)
end

--[[---------------------------------------------------------
	MenuOption
-----------------------------------------------------------]]
function SKIN:PaintMenuOption(panel, w, h)
	if panel.m_bBackground and (panel.Hovered or panel.Highlight) then
		self.tex.MenuBG_Hover(0, 0, w, h)
	end

	if panel:GetChecked() then
		self.tex.Menu_Check(5, h/2-7, 15, 15)
	end
end

--[[---------------------------------------------------------
	MenuRightArrow
-----------------------------------------------------------]]
function SKIN:PaintMenuRightArrow(panel, w, h)

	self.tex.Menu.RightArrow(0, 0, w, h)

end

--[[---------------------------------------------------------
	PropertySheet
-----------------------------------------------------------]]
function SKIN:PaintPropertySheet(panel, w, h)

	-- TODO: Tabs at bottom, left, right
	local ActiveTab = panel:GetActiveTab()
	local Offset = 0
	if ActiveTab then Offset = ActiveTab:GetTall()-8 end

	self.tex.Tab_Control(0, Offset, w, h-Offset)
end

--[[---------------------------------------------------------
	Tab
-----------------------------------------------------------]]
function SKIN:PaintTab(panel, w, h)
	if panel:GetPropertySheet():GetActiveTab() == panel then
		return self:PaintActiveTab(panel, w, h)
	end

	self.tex.TabT_Inactive(0, 0, w, h)
end

function SKIN:PaintActiveTab(panel, w, h)
	self.tex.TabT_Active(0, 0, w, h)
end

--[[---------------------------------------------------------
	Button
-----------------------------------------------------------]]
function SKIN:PaintWindowCloseButton(panel, w, h)
	if not panel.m_bBackground then return end

	if panel:GetDisabled() then
		return self.tex.Window.Close(0, 0, w, h, Color(255, 255, 255, 50))
	end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Window.Close_Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Window.Close_Hover(0, 0, w, h)
	end

	self.tex.Window.Close(0, 0, w, h)
end

function SKIN:PaintWindowMinimizeButton(panel, w, h)
	if not panel.m_bBackground then return end

	if panel:GetDisabled() then
		return self.tex.Window.Mini(0, 0, w, h, Color(255, 255, 255, 50))
	end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Window.Mini_Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Window.Mini_Hover(0, 0, w, h)
	end

	self.tex.Window.Mini(0, 0, w, h)
end

function SKIN:PaintWindowMaximizeButton(panel, w, h)
	if not panel.m_bBackground then return end

	if panel:GetDisabled() then
		return self.tex.Window.Maxi(0, 0, w, h, Color(255, 255, 255, 50))
	end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Window.Maxi_Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Window.Maxi_Hover(0, 0, w, h)
	end

	self.tex.Window.Maxi(0, 0, w, h)
end

--[[---------------------------------------------------------
	VScrollBar
-----------------------------------------------------------]]
function SKIN:PaintVScrollBar(panel, w, h)
	self.tex.Scroller.TrackV(0, 0, w, h)
end

--[[---------------------------------------------------------
	ScrollBarGrip
-----------------------------------------------------------]]
function SKIN:PaintScrollBarGrip(panel, w, h)
	if panel:GetDisabled() then
		return self.tex.Scroller.ButtonV_Disabled(0, 0, w, h)
	end

	if panel.Depressed then
		return self.tex.Scroller.ButtonV_Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Scroller.ButtonV_Hover(0, 0, w, h)
	end

	return self.tex.Scroller.ButtonV_Normal(0, 0, w, h)
end

--[[---------------------------------------------------------
	ButtonDown
-----------------------------------------------------------]]
function SKIN:PaintButtonDown(panel, w, h)
	if not panel.m_bBackground then return end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Scroller.DownButton_Down(0, 0, w, h)
	end

	if panel:GetDisabled() then
		return self.tex.Scroller.DownButton_Dead(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Scroller.DownButton_Hover(0, 0, w, h)
	end

	self.tex.Scroller.DownButton_Normal(0, 0, w, h)
end

--[[---------------------------------------------------------
	ButtonUp
-----------------------------------------------------------]]
function SKIN:PaintButtonUp(panel, w, h)
	if not panel.m_bBackground then return end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Scroller.UpButton_Down(0, 0, w, h)
	end

	if panel:GetDisabled() then
		return self.tex.Scroller.UpButton_Dead(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Scroller.UpButton_Hover(0, 0, w, h)
	end

	self.tex.Scroller.UpButton_Normal(0, 0, w, h)
end

--[[---------------------------------------------------------
	ButtonLeft
-----------------------------------------------------------]]
function SKIN:PaintButtonLeft(panel, w, h)
	if not panel.m_bBackground then return end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Scroller.LeftButton_Down(0, 0, w, h)
	end

	if panel:GetDisabled() then
		return self.tex.Scroller.LeftButton_Dead(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Scroller.LeftButton_Hover(0, 0, w, h)
	end

	self.tex.Scroller.LeftButton_Normal(0, 0, w, h)
end

--[[---------------------------------------------------------
	ButtonRight
-----------------------------------------------------------]]
function SKIN:PaintButtonRight(panel, w, h)

	if not panel.m_bBackground then return end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Scroller.RightButton_Down(0, 0, w, h)
	end

	if panel:GetDisabled() then
		return self.tex.Scroller.RightButton_Dead(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Scroller.RightButton_Hover(0, 0, w, h)
	end

	self.tex.Scroller.RightButton_Normal(0, 0, w, h)

end

--[[---------------------------------------------------------
	ComboDownArrow
-----------------------------------------------------------]]
function SKIN:PaintComboDownArrow(panel, w, h)
	if panel.ComboBox:GetDisabled() then
		return self.tex.Input.ComboBox.Button.Disabled(0, 0, w, h)
	end

	if panel.ComboBox.Depressed or panel.ComboBox:IsMenuOpen() then
		return self.tex.Input.ComboBox.Button.Down(0, 0, w, h)
	end

	if panel.ComboBox.Hovered then
		return self.tex.Input.ComboBox.Button.Hover(0, 0, w, h)
	end

	self.tex.Input.ComboBox.Button.Normal(0, 0, w, h)
end

--[[---------------------------------------------------------
	ComboBox
-----------------------------------------------------------]]
function SKIN:PaintComboBox(panel, w, h)
	if panel:GetDisabled() then
		return self.tex.Input.ComboBox.Disabled(0, 0, w, h)
	end

	if panel.Depressed or panel:IsMenuOpen() then
		return self.tex.Input.ComboBox.Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Input.ComboBox.Hover(0, 0, w, h)
	end

	self.tex.Input.ComboBox.Normal(0, 0, w, h)
end

--[[---------------------------------------------------------
	ComboBox
-----------------------------------------------------------]]
function SKIN:PaintListBox(panel, w, h)

	self.tex.Input.ListBox.Background(0, 0, w, h)

end

--[[---------------------------------------------------------
	NumberUp
-----------------------------------------------------------]]
function SKIN:PaintNumberUp(panel, w, h)
	if panel:GetDisabled() then
		return self.Input.UpDown.Up.Disabled(0, 0, w, h)
	end

	if panel.Depressed then
		return self.tex.Input.UpDown.Up.Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Input.UpDown.Up.Hover(0, 0, w, h)
	end

	self.tex.Input.UpDown.Up.Normal(0, 0, w, h)
end

--[[---------------------------------------------------------
	NumberDown
-----------------------------------------------------------]]
function SKIN:PaintNumberDown(panel, w, h)
	if panel:GetDisabled() then
		return self.tex.Input.UpDown.Down.Disabled(0, 0, w, h)
	end

	if panel.Depressed then
		return self.tex.Input.UpDown.Down.Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Input.UpDown.Down.Hover(0, 0, w, h)
	end

	self.tex.Input.UpDown.Down.Normal(0, 0, w, h)
end

function SKIN:PaintTreeNode(panel, w, h)
	if not panel.m_bDrawLines then return end

	surface_SetDrawColor(self.Colours.Tree.Lines)

	if panel.m_bLastChild then
		surface_DrawRect(9, 0, 1, 7)
		surface_DrawRect(9, 7, 9, 1)
	else
		surface_DrawRect(9, 0, 1, h)
		surface_DrawRect(9, 7, 9, 1)
	end
end

function SKIN:PaintTreeNodeButton(panel, w, h)
	if not panel.m_bSelected then return end

	-- Don't worry this isn't working out the size every render
	-- it just gets the cached value from inside the Label
	local w, _ = panel:GetTextSize()

	self.tex.Selection(38, 0, w + 6, h)
end

function SKIN:PaintSelection(panel, w, h)
	self.tex.Selection(0, 0, w, h)
end

function SKIN:PaintSliderKnob(panel, w, h)
	if panel:GetDisabled()  then	return self.tex.Input.Slider.H.Disabled(0, 0, w, h) end

	if panel.Depressed then
		return self.tex.Input.Slider.H.Down(0, 0, w, h)
	end

	if panel.Hovered then
		return self.tex.Input.Slider.H.Hover(0, 0, w, h)
	end

	self.tex.Input.Slider.H.Normal(0, 0, w, h)
end

local function PaintNotches(x, y, w, h, num)
	if not num then return end

	local space = w / num
	for i=0, num do
		surface_DrawRect(x + i * space, y + 4, 1,  5)
	end
end

function SKIN:PaintNumSlider(panel, w, h)
	surface_SetDrawColor(Color(0, 0, 0, 100))
	surface_DrawRect(8, h / 2 - 1, w - 15, 1)

	PaintNotches(8, h / 2 - 1, w - 16, 1, panel.m_iNotches)
end

function SKIN:PaintProgress(panel, w, h)
	self.tex.ProgressBar.Back(0, 0, w, h)
	self.tex.ProgressBar.Front(0, 0, w * panel:GetFraction(), h)
end

function SKIN:PaintCollapsibleCategory(panel, w, h)
	if not panel:GetExpanded() and h < 40 then
		return self.tex.CategoryList.Header(0, 0, w, h)
	end

	self.tex.CategoryList.Inner(0, 0, w, h)
end

function SKIN:PaintCategoryList(panel, w, h)
	self.tex.CategoryList.Outer(0, 0, w, h)
end

function SKIN:PaintCategoryButton(panel, w, h)
	if panel.AltLine then
		if panel.Depressed or panel.m_bSelected then
			surface_SetDrawColor(self.Colours.Category.LineAlt.Button_Selected)
		elseif panel.Hovered then
			surface_SetDrawColor(self.Colours.Category.LineAlt.Button_Hover)
		else
			surface_SetDrawColor(self.Colours.Category.LineAlt.Button)
		end
	else
		if panel.Depressed or panel.m_bSelected then
			surface_SetDrawColor(self.Colours.Category.Line.Button_Selected)
		elseif panel.Hovered then
			surface_SetDrawColor(self.Colours.Category.Line.Button_Hover)
		else
			surface_SetDrawColor(self.Colours.Category.Line.Button)
		end
	end

	surface_DrawRect(0, 0, w, h)
end

function SKIN:PaintListViewLine(panel, w, h)
	if panel:IsSelected() then
		self.tex.Input.ListBox.EvenLineSelected(0, 0, w, h)
	elseif panel.Hovered then
		self.tex.Input.ListBox.Hovered(0, 0, w, h)
	elseif panel.m_bAlt then
		self.tex.Input.ListBox.EvenLine(0, 0, w, h)
	end
end

function SKIN:PaintListView(panel, w, h)
	self.tex.Input.ListBox.Background(0, 0, w, h)
end

function SKIN:PaintTooltip(panel, w, h)
	self.tex.Tooltip(0, 0, w, h)
end

function SKIN:PaintMenuBar(panel, w, h)
	local Childs = panel:GetChildren()

	for k, v in pairs(Childs) do
		if panel.SetTextColor and not panel.FixFuckingTextColor then
			panel.FixFuckingTextColor = true
			panel:SetTextColor(Skin.Colours.Button.Menu)
		end
	end

	self.tex.Menu_Strip(0, 0, w, h)
end

-- END DEFAULT

function SKIN:PaintMenuOption(panel, w, h)
	if panel.m_bBackground and (panel.Hovered or panel.Highlight) then
		self.tex.MenuBG_Hover(0, 0, w, h)
	end

	if panel:GetChecked() then
		self.tex.Menu_Check(5, h/2-7, 15, 15)
	end
end

function SKIN:PaintMenu(panel, w, h)
	if panel:GetDrawColumn() then
		self.tex.MenuBG_Column(0, 0, w, h)
	else
		self.tex.MenuBG(0, 0, w, h)
	end

	local Canvas = panel:GetCanvas()

	if IsValid(Canvas) then
		for k, v in pairs(Canvas:GetChildren()) do
			if v.SetTextColor and not v.FIX_FUCKING_COLOR then
				v:SetTextColor(skin.text_normal)
				v.FIX_FUCKING_COLOR = true
			end
		end
	end
end

function SKIN:PaintTree(panel, w, h)
	if not panel.m_bBackground then return end
	self.tex.Tree(0, 0, w, h, panel.m_bgColor, panel)
end

function SKIN:PaintCheckBox(panel, w, h)
	if panel:GetChecked() then
		if panel:GetDisabled() then
			self.tex.CheckboxD_Checked(0, 0, w, h)
		else
			self.tex.Checkbox_Checked(0, 0, w, h)
		end
	else
		if panel:GetDisabled() then
			self.tex.CheckboxD(0, 0, w, h)
		else
			self.tex.Checkbox(0, 0, w, h)
		end
	end
end

function SKIN:PaintButton(panel, w, h)
	if panel:GetIsMenu() then
		if not panel.FixFuckingTextColor then
			panel.FixFuckingTextColor = true
			panel:SetTextColor(Skin.Colours.Button.Menu)
		end
	end

	if not panel.m_bBackground then return end

	if panel.Depressed or panel:IsSelected() or panel:GetToggle() then
		return self.tex.Button_Down(0, 0, w, h, panel)
	end

	if panel:GetDisabled() then
		return self.tex.Button_Dead(0, 0, w, h, panel)
	end

	if panel.Hovered then
		return self.tex.Button_Hovered(0, 0, w, h, panel)
	end

	self.tex.Button(0, 0, w, h, panel)
end

function SKIN:PaintWindowCloseButton(panel, w, h)
	if not panel.m_bBackground then return end

	if panel:GetDisabled() then
		return self.tex.Window.Close(0, 0, w, h, panel)
	end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Window.Close_Down(0, 0, w, h, panel)
	end

	if panel.Hovered then
		return self.tex.Window.Close_Hover(0, 0, w, h, panel)
	end

	self.tex.Window.Close(0, 0, w, h, panel)
end

function SKIN:PaintWindowMinimizeButton(panel, w, h)
	if not panel.m_bBackground then return end

	if panel:GetDisabled() then
		return self.tex.Window.Mini(0, 0, w, h, panel)
	end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Window.Mini_Down(0, 0, w, h, panel)
	end

	if panel.Hovered then
		return self.tex.Window.Mini_Hover(0, 0, w, h, panel)
	end

	self.tex.Window.Mini(0, 0, w, h, panel)
end

function SKIN:PaintWindowMaximizeButton(panel, w, h)
	if not panel.m_bBackground then return end

	if panel:GetDisabled() then
		return self.tex.Window.Maxi(0, 0, w, h, panel)
	end

	if panel.Depressed or panel:IsSelected() then
		return self.tex.Window.Maxi_Down(0, 0, w, h, panel)
	end

	if panel.Hovered then
		return self.tex.Window.Maxi_Hover(0, 0, w, h, panel)
	end

	self.tex.Window.Maxi(0, 0, w, h, panel)
end

derma.DefineSkin('DLib_Black', 'Made to look like flat VGUI', SKIN)
derma.RefreshSkins()
