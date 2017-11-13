
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

function friends.OpenGUIForPlayer(steamid)
	local nick = DLib.LastNickFormatted(steamid)
	local getData = friends.LoadPlayer(steamid)
	local wasfriend = getData and getData.isFriend

	if not getData then
		getData = friends.CreateFriend(steamid, false)
		wasfriend = false
	end

	local frame = vgui.Create('DLib_Window')
	frame:UpdateSize(400, 400)
	frame:SetTitle('Editing ' .. nick .. ' <' .. steamid .. '>')

	local label = vgui.Create('DLabel', frame)
	label:Dock(TOP)
	label:SetText('You are friend with ' .. nick .. ' in...')

	local scroll = vgui.Create('DScrollPanel', frame)
	scroll:Dock(FILL)
	local canvas = scroll:GetCanvas()
	local boxes = {}

	for stringID, status in pairs(getData.status) do
		local name = friends.typesCache[stringID] and friends.typesCache[stringID].name or ('(foreign) ' .. stringID)
		local box = vgui.Create('DCheckBoxLabel', canvas)
		box:Dock(TOP)
		box:DockMargin(4, 4, 4, 4)
		box:SetChecked(status)
		box:SetText(name)
		box.id = stringID
		table.insert(boxes, box)
	end

	local button = vgui.Create('DButton', frame)
	button:SetText('Apply')
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
			friends.ModifyFriend(steamid, {
				isFriend = true,
				status = newdata
			})
		else
			friends.RemoveFriend(steamid)
		end

		frame:Close()
	end

	if wasfriend then
		button = vgui.Create('DButton', frame)
		button:SetText('Remove friend')
		button:Dock(BOTTOM)

		function button.DoClick()
			friends.RemoveFriend(steamid)
			frame:Close()
		end
	end

	button = vgui.Create('DButton', frame)
	button:SetText('Decline')
	button:Dock(BOTTOM)

	function button.DoClick()
		frame:Close()
	end

	return frame
end

function friends.OpenGUI()
	local frame = vgui.Create('DLib_Window')
	frame:SetTitle('DLib Friends')

	local myfriends = DLib.VCreate('DLib_ButtonLayout', frame)
	local serverplayers = DLib.VCreate('DLib_ButtonLayout', frame)

	local div = DLib.VCreate('DVerticalDivider', frame)
	div:Dock(FILL)

	div:SetTop(myfriends)
	div:SetBottom(serverplayers)
	div:SetTopHeight(ScrH() / 2) -- lesser than current friends

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
				local cfriend = friends.currentStatus[ply]

				if not steamids[steamid] and (not cfriend or not cfriend.isFriend) then
					local button = DLib.VCreate('DLib_PlayerButton', serverplayers)
					button:SetSteamID(steamid)
					serverplayers:AddButton(button)

					function button.DoClick()
						friends.OpenGUIForPlayer(steamid)
					end
				elseif cfriend and cfriend.isFriend then
					steamids[steamid] = steamid
				end
			end
		end

		for i, steamid in pairs(steamids) do
			local button = DLib.VCreate('DLib_PlayerButton', myfriends)
			button:SetSteamID(steamid)
			myfriends:AddButton(button)

			function button.DoClick()
				friends.OpenGUIForPlayer(steamid)
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

concommand.Add('dlib_friends', friends.OpenGUI)
