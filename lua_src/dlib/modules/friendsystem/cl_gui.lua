
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

local Friend = DLib.Friend
local DLib = DLib

--[[
	@doc
	@fname DLib.Friend.OpenGUIForPlayer
	@args string steamid

	@client
]]
function Friend.OpenGUIForPlayer(steamid)
	local nick = DLib.LastNickFormatted(steamid)
	local getData = Friend.LoadPlayer(steamid)
	local wasfriend = getData and getData.isFriend

	if not getData then
		getData = Friend.CreateFriend(steamid, false)
		wasfriend = false
	end

	local frame = vgui.Create('DLib_Window')
	frame:UpdateSize(400, 400)
	frame:SetTitle(wasfriend and 'gui.dlib.friends.edit.edit_title' or 'gui.dlib.friends.edit.add_title', nick, steamid)

	local label = vgui.Create('DLabel', frame)
	label:Dock(TOP)
	label:SetText(wasfriend and 'gui.dlib.friends.edit.youare' or 'gui.dlib.friends.edit.going', nick)

	local scroll = vgui.Create('DScrollPanel', frame)
	scroll:Dock(FILL)
	local canvas = scroll:GetCanvas()
	local boxes = {}

	for stringID, status in pairs(getData.status) do
		local name = Friend.typesCache[stringID] and
			Friend.typesCache[stringID].localizedName or
			(DLib.i18n.localize('gui.dlib.friends.settings.foreign') .. stringID)

		local box = vgui.Create('DCheckBoxLabel', canvas)
		box:Dock(TOP)
		box:DockMargin(4, 4, 4, 4)
		box:SetChecked(status)
		box:SetText(name)
		box.id = stringID
		table.insert(boxes, box)
	end

	local button = vgui.Create('DButton', frame)
	button:SetText('gui.misc.apply')
	button:Dock(BOTTOM)

	function button.DoClick()
		local newdata = {}
		local hitvalid = #boxes == 0

		for i, box in ipairs(boxes) do
			if box:GetChecked() then
				hitvalid = true
				newdata[box.id] = true
			else
				newdata[box.id] = false
			end
		end

		if hitvalid then
			Friend.ModifyFriend(steamid, {
				isFriend = true,
				status = newdata
			})
		else
			Friend.RemoveFriend(steamid)
		end

		frame:Close()
	end

	if wasfriend then
		button = vgui.Create('DButton', frame)
		button:SetText('gui.dlib.friends.edit.remove')
		button:Dock(BOTTOM)

		function button.DoClick()
			Friend.RemoveFriend(steamid)
			frame:Close()
		end
	end

	button = vgui.Create('DButton', frame)
	button:SetText('gui.misc.cancel')
	button:Dock(BOTTOM)

	function button.DoClick()
		frame:Close()
	end

	return frame
end

surface.CreateFont('DLib.FriendsTooltip', {
	font = 'Roboto',
	size = 20,
	weight = 600
})

--[[
	@doc
	@fname DLib.Friend.OpenGUI

	@client
]]
function Friend.OpenGUI()
	local frame = vgui.Create('DLib_Window')
	frame:SetTitle('gui.dlib.friends.title')

	local steamidInput = DLib.VCreate('DLib_TextInput', frame)
	steamidInput:SetPos(100, 3)
	steamidInput:SetSize(400, 20)
	steamidInput:SetText('STEAMID')

	function steamidInput:OnEnter(value)
		if DLib.Util.ValidateSteamID(value) then
			Friend.OpenGUIForPlayer(value)
		else
			Derma_Message(DLib.i18n.localize('gui.dlib.friends.invalid.desc', value), 'gui.dlib.friends.invalid.title', 'gui.dlib.friends.invalid.ok')
		end
	end

	local treat = DLib.VCreate('DCheckBoxLabel', frame)
	treat:SetText('gui.dlib.friends.settings.steam')
	treat:SetConVar('cl_dlib_steamfriends')
	treat:SetPos(510, 3)
	treat:SizeToContents()

	local topwrapper = DLib.VCreate('EditablePanel', frame)
	local bottomwrapper = DLib.VCreate('EditablePanel', frame)

	local myfriends = DLib.VCreate('DLib_ButtonLayout', topwrapper)
	local serverplayers = DLib.VCreate('DLib_ButtonLayout', bottomwrapper)

	local div = DLib.VCreate('DVerticalDivider', frame)
	div:Dock(FILL)

	div:SetTop(topwrapper)
	div:SetBottom(bottomwrapper)
	div:SetTopHeight(ScrHL() / 2) -- lesser than current friends

	local label = DLib.VCreate('DLabel', topwrapper)
	label:SetFont('DLib.FriendsTooltip')
	label:Dock(TOP)
	label:DockMargin(4, 4, 4, 4)
	label:SetText('gui.dlib.friends.settings.your')
	label:SizeToContents()

	label = DLib.VCreate('DLabel', bottomwrapper)
	label:SetFont('DLib.FriendsTooltip')
	label:Dock(TOP)
	label:DockMargin(4, 4, 4, 4)
	label:SetText('gui.dlib.friends.settings.server')
	label:SizeToContents()

	myfriends:Dock(FILL)
	serverplayers:Dock(FILL)

	local function Populate()
		myfriends:Clear()
		serverplayers:Clear()

		local steamidsData = sql.Query('SELECT steamid FROM dlib_friends GROUP BY steamid')
		local steamids = {}

		if steamidsData then
			for i, row in ipairs(steamidsData) do
				steamids[row.steamid] = row.steamid
			end
		end

		local lply = LocalPlayer()

		for i, ply in ipairs(player.GetHumans()) do
			if ply ~= lply then
				local steamid = ply:SteamID()
				local cfriend = Friend.CurrentStatus[ply]

				if not steamids[steamid] and (not cfriend or not cfriend.isFriend) then
					local button = DLib.VCreate('DLib_PlayerButton', serverplayers)
					button:SetSteamID(steamid)
					serverplayers:AddButton(button)

					function button.DoClick()
						Friend.OpenGUIForPlayer(steamid)
					end
				elseif cfriend and cfriend.isFriend then
					steamids[steamid] = steamid
				end
			end
		end

		for i, steamid in pairs(steamids) do
			local button = DLib.VCreate('DLib_PlayerButton', myfriends)
			button:SetSteamID(steamid)
			button:SetGreenIfOnline(true)
			myfriends:AddButton(button)

			function button.DoClick()
				Friend.OpenGUIForPlayer(steamid)
			end
		end
	end

	Populate()
	local populatehook = DLib.WrappedQueueFunction(Populate)

	hook.Add('DLib_FriendModified', frame, populatehook)
	hook.Add('DLib_FriendCreated', frame, populatehook)
	hook.Add('DLib_FriendSaved', frame, populatehook)

	return frame
end

concommand.Add('dlib_friends', Friend.OpenGUI)
