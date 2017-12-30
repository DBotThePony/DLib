
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

function DLib.skin.tex.Window.Normal(x, y, w, h)
	Simple_DrawBox(x, y, w, 25, DLib.skin.background) -- top
	Simple_DrawBox(x, y, w, h, DLib.skin.background)
end

function DLib.skin.tex.Window.Inactive(x, y, w, h)
	Simple_DrawBox(x, y, w, 25, DLib.skin.background) -- top
	Simple_DrawBox(x, y, w, h, DLib.skin.background_inactive)
end

local buttonOffset = 6

function DLib.skin.tex.Window.Close(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(200, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(255, self.Neon * 3, self.Neon * 3, self.Neon * 3)
	surface_DrawLine(x + 2, y + 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, y + 5)
end

function DLib.skin.tex.Window.Close_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(200, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)
	surface_SetDrawColor(255, self.Neon * 3, self.Neon * 3, self.Neon * 3)
	surface_DrawLine(x + 2, y + 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, y + 5)
end

function DLib.skin.tex.Window.Close_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, DLib.skin.CloseHoverCol)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(255, 200, 200)
	surface_DrawLine(x + 2, y + 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, y + 5)
end

--Maximize
function DLib.skin.tex.Window.Maxi(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 13, w - 4, h - buttonOffset - 13)
	surface_DrawLine(x + 2, h - buttonOffset - 5, x + 2, h - buttonOffset - 13)
	surface_DrawLine(w - 4, h - buttonOffset - 5, w - 4, h - buttonOffset - 13)
end

function DLib.skin.tex.Window.Maxi_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 13, w - 4, h - buttonOffset - 13)
	surface_DrawLine(x + 2, h - buttonOffset - 5, x + 2, h - buttonOffset - 13)
	surface_DrawLine(w - 4, h - buttonOffset - 5, w - 4, h - buttonOffset - 13)
end

function DLib.skin.tex.Window.Maxi_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, DLib.skin.colours.windowCol)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 13, w - 4, h - buttonOffset - 13)
	surface_DrawLine(x + 2, h - buttonOffset - 5, x + 2, h - buttonOffset - 13)
	surface_DrawLine(w - 4, h - buttonOffset - 5, w - 4, h - buttonOffset - 13)
end

function DLib.skin.tex.Window.Restore(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 13, w - 4, h - buttonOffset - 13)
	surface_DrawLine(x + 2, h - buttonOffset - 5, x + 2, h - buttonOffset - 13)
	surface_DrawLine(w - 4, h - buttonOffset - 5, w - 4, h - buttonOffset - 13)
end

function DLib.skin.tex.Window.Restore_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 13, w - 4, h - buttonOffset - 13)
	surface_DrawLine(x + 2, h - buttonOffset - 5, x + 2, h - buttonOffset - 13)
	surface_DrawLine(w - 4, h - buttonOffset - 5, w - 4, h - buttonOffset - 13)
end

function DLib.skin.tex.Window.Restore_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, DLib.skin.colours.windowCol)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(150 + self.Neon * 2, 150 + self.Neon * 2, 150 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
	surface_DrawLine(x + 2, h - buttonOffset - 13, w - 4, h - buttonOffset - 13)
	surface_DrawLine(x + 2, h - buttonOffset - 5, x + 2, h - buttonOffset - 13)
	surface_DrawLine(w - 4, h - buttonOffset - 5, w - 4, h - buttonOffset - 13)
end

function DLib.skin.tex.Window.Mini(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.max(self.Neon - 5 * (FrameTime() * 66), 0)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
end

function DLib.skin.tex.Window.Mini_Hover(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, Color(50 + self.Neon, 50 + self.Neon, 50 + self.Neon, DLib.skin.CloseAlpha))

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
end

function DLib.skin.tex.Window.Mini_Down(x, y, w, h, self)
	if not self then return end

	self.Neon = self.Neon or 0
	Simple_DrawBox(x, y, w, h - buttonOffset, DLib.skin.colours.windowCol)

	self.Neon = math.min(self.Neon + 5 * (FrameTime() * 66), 50)

	surface_SetDrawColor(125 + self.Neon * 2, 125 + self.Neon * 2, 125 + self.Neon * 2)
	surface_DrawLine(x + 2, h - buttonOffset - 5, w - 4, h - buttonOffset - 5)
end