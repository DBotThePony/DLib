
-- Copyright (C) 2017-2018 DBot

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
