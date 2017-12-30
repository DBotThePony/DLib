
--
-- Copyright (C) 2016-2018 DBot
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

local PANEL = {}
DLib.VGUI.Avatar = PANEL

function PANEL:AvatarHide()
	self.havatar:SetVisible(false)
	self.havatar:KillFocus()
	self.havatar:SetMouseInputEnabled(false)
	self.havatar:SetKeyboardInputEnabled(false)
	self.havatar.hover = false
	self:SetSkin('DLib_Black')
end

function PANEL:OnMousePressed(key)
	self.hover = true
	self.havatar:SetVisible(true)
	self.havatar:MakePopup()
	self.havatar:SetMouseInputEnabled(false)
	self.havatar:SetKeyboardInputEnabled(false)

	if IsValid(self.ply) and self.ply:IsBot() then return end

	if key == MOUSE_LEFT then
		if IsValid(self.ply) then
			gui.OpenURL('https://steamcommunity.com/profiles/' .. self.ply:SteamID64() .. '/')
		elseif self.steamid64 and self.steamid64 ~= '0' then
			gui.OpenURL('https://steamcommunity.com/profiles/' .. self.steamid64 .. '/')
		end
	end
end

function PANEL:Init()
	self:SetCursor('hand')

	local avatar = self:Add('AvatarImage')
	self.avatar = avatar
	avatar:Dock(FILL)

	local havatar = vgui.Create('AvatarImage')
	self.havatar = havatar
	havatar:SetVisible(false)
	havatar:SetSize(184, 184)

	hook.Add('OnSpawnMenuClose', self, self.AvatarHide)

	self:SetMouseInputEnabled(true)
	avatar:SetMouseInputEnabled(false)
	avatar:SetKeyboardInputEnabled(false)
	havatar:SetMouseInputEnabled(false)
	havatar:SetKeyboardInputEnabled(false)
end

function PANEL:Think()
	if not IsValid(self.ply) and not self.steamid then return end
	local x, y = gui.MousePos()

	local hover = self:IsHovered()

	local w, h = ScrW(), ScrH()

	if x + 204 >= w then
		x = x - 214
	end

	if y + 204 >= h then
		y = y - 214
	end

	if hover then
		if not self.hover then
			self.hover = true
			self.havatar:SetVisible(true)
			self.havatar:MakePopup()
			self.havatar:SetMouseInputEnabled(false)
			self.havatar:SetKeyboardInputEnabled(false)
		end

		self.havatar:SetPos(x + 20, y + 10)
	else
		if self.hover then
			self.havatar:SetVisible(false)
			self.havatar:KillFocus()
			self.hover = false
		end
	end
end

function PANEL:SetPlayer(ply, size)
	self.ply = ply

	self.avatar:SetPlayer(ply, size)
	self.havatar:SetPlayer(ply, 184)
end

function PANEL:SetSteamID(steamid, size)
	local steamid64 = util.SteamIDTo64(steamid)
	self.steamid = steamid
	self.steamid64 = steamid64

	self.avatar:SetSteamID(steamid64, size)
	self.havatar:SetSteamID(steamid64, 184)
end

function PANEL:OnRemove()
	if IsValid(self.havatar) then
		self.havatar:Remove()
	end
end

vgui.Register('DLib_Avatar', PANEL, 'EditablePanel')

return PANEL
