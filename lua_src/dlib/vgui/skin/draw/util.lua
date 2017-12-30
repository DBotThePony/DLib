
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

function DLib.skin.tex.CategoryList.Outer(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.CategoryList.BG)
end

function DLib.skin.tex.CategoryList.Inner(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.CategoryList.BG)
end

function DLib.skin.tex.CategoryList.Header(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.tex.CategoryList.Headerr)
end

function DLib.skin.tex.Tooltip(x, y, w, h)
	Simple_DrawBox(x, y, w, h, DLib.skin.background)
end

function DLib.skin.tex.ProgressBar.Back(x, y, w, h)
	Simple_DrawBox(x, y, w, h, Color(90, 90, 90))
end

function DLib.skin.tex.ProgressBar.Front(x, y, w, h)
	Simple_DrawBox(x + 2, y + 2, w - 4, h - 4, Color(160, 200, 130))
end
