
-- Copyright (C) 2017-2018 DBot

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
DLib.VGUI.DMenu = PANEL

function PANEL:Init()
	self:SetSkin('DLib_Black')
end

function PANEL:AddCopyOption(name, value)
	local new = self:AddOption(name, function()
		SetClipboardText(value)
	end)

	new:SetIcon(DLib.skin.icon.copy())

	return new
end

function PANEL:AddURLOption(name, value)
	local new = self:AddOption(name, function()
		gui.OpenURL(value)
	end)

	new:SetIcon(DLib.skin.icon.url())

	return new
end

function PANEL:AddSteamID(name, value)
	return self:AddSteamID64(name, util.SteamIDTo64(value))
end

function PANEL:AddSteamID64(name, value)
	local new = self:AddURLOption(name, 'https://steamcommunity.com/profiles/' .. value)
	new:SetIcon(DLib.skin.icon.user())
	return new
end

vgui.Register('DLib_Menu', PANEL, 'DMenu')
return PANEL
