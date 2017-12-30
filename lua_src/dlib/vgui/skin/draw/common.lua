
-- Copyright (C) 2016-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local DLib = DLib
local surface = surface
local draw = draw
local Color = Color
local GWEN = GWEN
local surface_SetTexture = surface.SetTexture
local surface_DrawRect = surface.DrawRect
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local surface_SetFont = surface.SetFont
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local Simple_DrawBox = DLib.skin.Simple_DrawBox
local Simple_DrawText = DLib.skin.Simple_DrawText
local HUDCommons = DLib.HUDCommons

-- Buttons
function DLib.skin.tex.Button(x, y, w, h, self)
	if not self then return end
	self.Neon = self.Neon or 0

	Simple_DrawBox(x, y, w, h, DLib.skin.ButtonDefColor)
	Simple_DrawBox(x, y + h / 2 - h * self.Neon / 2, w, h * self.Neon, DLib.skin.ButtonDefColor2)

	self.Neon = Lerp(FrameTime() * 8, self.Neon, 0)
end

function DLib.skin.tex.Button_Hovered(x, y, w, h, self)
	if not self then return end
	self.Neon = self.Neon or 0

	Simple_DrawBox(x, y, w, h, DLib.skin.ButtonDefColor)
	Simple_DrawBox(x, y + h / 2 - h * self.Neon / 2, w, h * self.Neon, DLib.skin.ButtonDefColor2)

	self.Neon = Lerp(FrameTime() * 8, self.Neon, 1)
end

function DLib.skin.tex.Button_Down(x, y, w, h, self)
	if not self then return end
	self.Neon = self.Neon or 0

	Simple_DrawBox(x, y, w, h, DLib.skin.ButtonDefColor)
	Simple_DrawBox(x, y + h / 2 - h * self.Neon / 2, w, h * self.Neon, DLib.skin.ButtonDefColor2)

	self.Neon = Lerp(FrameTime() * 8, self.Neon, 1)
end

function DLib.skin.tex.Button_Dead(x, y, w, h, self)
	if not self then return end
	self.Neon = self.Neon or 0

	Simple_DrawBox(x, y, w, h, DLib.skin.ButtonDefColor)
	Simple_DrawBox(x, y + h / 2 - h * self.Neon / 2, w, h * self.Neon, DLib.skin.ButtonDefColor2)

	self.Neon = Lerp(FrameTime() * 8, self.Neon, 0)
end

-- Checkboxes

function DLib.skin.tex.Checkbox_Checked(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.CheckBoxBG)
	surface_SetDrawColor(DLib.skin.CheckBoxC)

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.2, y + size * 0.7, size * 0.5, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * .4, y + size * .47 + size * 0.6, size, size * 0.15, -45)
end

function DLib.skin.tex.Checkbox(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.CheckBoxBG)
	surface_SetDrawColor(DLib.skin.CheckBoxU)

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.25, y + size * 0.15, size * 1.2, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * 0.15, y + size, size * 1.2, size * 0.15, -45)
end

function DLib.skin.tex.CheckboxD_Checked(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.CheckBoxBGD)
	surface_SetDrawColor(DLib.skin.CheckBoxC)

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.2, y + size * 0.7, size * 0.5, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * .4, y + size * .47 + size * 0.6, size, size * 0.15, -45)
end

function DLib.skin.tex.CheckboxD(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.CheckBoxBGD)
	surface_SetDrawColor(DLib.skin.CheckBoxU)

	local size = math.min(w, h) * 0.8

	HUDCommons.DrawRotatedRect(x + size * 0.25, y + size * 0.15, size * 1.2, size * 0.15, 45)
	HUDCommons.DrawRotatedRect(x + size * 0.15, y + size, size * 1.2, size * 0.15, -45)
end

-- Menu

function DLib.skin.tex.MenuBG_Column(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, DLib.skin.MenuHoverColor)
end

function DLib.skin.tex.MenuBG(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, DLib.skin.bg_color)
end

function DLib.skin.tex.MenuBG_Hover(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, DLib.skin.MenuHoverColor)
end

function DLib.skin.tex.MenuBG_Spacer(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, DLib.skin.MenuSpacer)
end

function DLib.skin.tex.Menu_Strip(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, DLib.skin.MenuSpacerStrip)
end

function DLib.skin.tex.Tab_Control(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.colours.TabControl)
end

function DLib.skin.tex.TabB_Active(x, y, w, h, self)
	Simple_DrawBox(x + 4, y, w - 8, h - 8, Selected)
end

function DLib.skin.tex.TabB_Inactive(x, y, w, h, self)
	Simple_DrawBox(x + 4, y + 2, w - 8, h - 2, UnSelected)
	Simple_DrawBox(x + 4, y + 12, w - 8, h - 2, UnSelected2)
end

function DLib.skin.tex.TabT_Active(x, y, w, h, self)
	Simple_DrawBox(x + 4, y, w - 8, h - 8, DLib.skin.colours.TabSelected)
end

function DLib.skin.tex.TabT_Inactive(x, y, w, h, self)
	Simple_DrawBox(x + 4, y + 2, w - 8, h - 2, DLib.skin.colours.TabUnSelected)
	Simple_DrawBox(x + 4, y + 12, w - 8, h - 2, DLib.skin.colours.TabUnSelected2)
end
