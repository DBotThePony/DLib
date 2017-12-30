
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

function DLib.skin.tex.Tree(x, y, w, h, self)
	Simple_DrawBox(x, y, w, h, DLib.skin.bg_color)
end

function DLib.skin.tex.Input.ListBox.Background(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.Input.ListBox.BG)
end

function DLib.skin.tex.Input.ListBox.Hovered(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.Input.ListBox.BG)
end

function DLib.skin.tex.Input.ListBox.EvenLine(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.Input.ListBox.First)
end

function DLib.skin.tex.Input.ListBox.OddLine(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.Input.ListBox.Second)
end

function DLib.skin.tex.Input.ListBox.EvenLineSelected(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.Input.ListBox.Select)
end

function DLib.skin.tex.Input.ListBox.OddLineSelected(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.Input.ListBox.Select)
end

function DLib.skin.tex.Input.ComboBox.Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.colours.ComboBoxNormal)
end

function DLib.skin.tex.Input.ComboBox.Hover(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.colours.ComboBoxHover)
end

function DLib.skin.tex.Input.ComboBox.Down(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.colours.ComboBoxDown)
end

function DLib.skin.tex.Input.ComboBox.Disabled(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.colours.ComboBoxDisabled)
end