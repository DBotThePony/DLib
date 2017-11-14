
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local PANEL = {}
DLib.VGUI.PlayerButton = PANEL
local DButton = DButton

DLib.util.AccessorFuncJIT(PANEL, 'm_DisplayGreen', 'GreenIfOnline')

function PANEL:Init()
	self.isAddingNew = false
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:SetText('')
	self.label = vgui.Create('DLabel', self)
	self.label:SetText('usernaem:tm:\nstaimid:tm:')
	self.label:SetPos(0, 64)
	self.label:SetContentAlignment(CONTENT_ALIGMENT_MIDDLECENTER)
	self.nickname = 'unknown'
	self:SetSize(128, 96)
	self:SetSkin('DLib_Black')
	self.m_DisplayGreen = false
end

function PANEL:DoClick()

end

local surface = surface
local derma = derma

function PANEL:Paint(w, h)
	derma.SkinHook('Paint', 'Button', self, w, h)

	if self.ply and self.m_DisplayGreen then
		surface.SetDrawColor(20, 180, 24, 100)
		surface.DrawRect(0, 0, w, h)
	end
end

function PANEL:PerformLayout(w, h)
	if not w or not h then return end
	self.label:SizeToContents()
	local W, H = self.label:GetSize()
	self.label:SetSize(w, H)

	if IsValid(self.avatar) then
		self.avatar:SetPos(w / 2 - self.avatar:GetWide() / 2)
	end
end

function PANEL:SetSteamID(steamid)
	self.steamid = steamid
	self.ply = player.GetBySteamID(steamid)

	if IsValid(self.avatar) then
		self.avatar:SetSteamID(steamid, 64)
	end

	self.label:SetText(self.nickname .. '\n' .. steamid)
end

function PANEL:Populate()
	self.avatar = vgui.Create('DLib_Avatar', self)
	local avatar = self.avatar
	avatar:SetSize(48, 48)
	avatar:SetPos(self:GetWide() / 2 - 24, 0)
	avatar:SetSteamID(self.steamid, 64)
	self.nickname = DLib.LastNickFormatted(self.steamid)
	self.label:SetText(self.nickname .. '\n' .. self.steamid)
end

vgui.Register('DLib_PlayerButton', PANEL, 'DButton')

return PANEL
