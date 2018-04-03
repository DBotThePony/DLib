
--
-- Copyright (C) 2017-2018 DBot
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

if CLIENT then
	local pixelvis_handle_t = FindMetaTable('pixelvis_handle_t')

	function pixelvis_handle_t:Visible(self, pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	function pixelvis_handle_t:IsVisible(self, pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	function pixelvis_handle_t:PixelVisible(self, pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	local player = player
	local IsValid = FindMetaTable('Entity').IsValid
	local GetTable = FindMetaTable('Entity').GetTable
	local GetVehicle = FindMetaTable('Player').GetVehicle
	local vehMeta = FindMetaTable('Vehicle')
	local NULL = NULL
	local ipairs = ipairs

	function vehMeta:GetDriver()
		return self._dlib_vehfix or NULL
	end

	local function Think()
		for i, ply in ipairs(player.GetAll()) do
			local ply2 = GetTable(ply)
			local veh = GetVehicle(ply)

			if veh ~= ply2._dlib_vehfix then
				if IsValid(ply2._dlib_vehfix) then
					ply2._dlib_vehfix._dlib_vehfix = NULL
				end

				ply2._dlib_vehfix = veh

				if IsValid(veh) then
					veh._dlib_vehfix = ply
				end
			end
		end
	end

	hook.Add('Think', 'DLib.GetDriverFix', Think)

	local LocalPlayer = LocalPlayer
	local GetWeapons = FindMetaTable('Player').GetWeapons

	local function updateWeaponFix()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local weapons = GetWeapons(ply)
		if not weapons then return end

		for k, wep in ipairs(weapons) do
			local tab = GetTable(wep)

			if not tab.DrawWeaponSelection_DLib then
				tab.DrawWeaponSelection_DLib = tab.DrawWeaponSelection

				tab.DrawWeaponSelection = function(self, x, y, w, h, a)
					local can = hook.Run('DrawWeaponSelection', self, x, y, w, h, a)
					if can == false then return end
					return tab.DrawWeaponSelection_DLib(self, x, y, w, h, a)
				end
			end
		end
	end

	timer.Create('DLib.DrawWeaponSelection', 10, 0, updateWeaponFix)
	updateWeaponFix()

	local vgui = vgui
	vgui.CreateC = vgui.CreateC or vgui.Create

	function vgui.Create(...)
		local pnl = vgui.CreateC(...)
		if not pnl then return end
		hook.Run('VGUIPanelCreated', pnl, ...)
		return pnl
	end
end

local CSoundPatch = FindMetaTable('CSoundPatch')

function CSoundPatch:IsValid()
	return self:IsPlaying()
end

function CSoundPatch:Remove()
	return self:Stop()
end

local topatch = {
	1, '', function() end, true
}

local tonumber, tostring = tonumber, tostring

local meta = getmetatable(function() end) or {}

function meta:tonumber()
	return tonumber(self)
end

function meta:tostring()
	return tostring(self)
end

debug.setmetatable(value, meta)

string.tonumber = meta.tonumber
string.tostring = meta.tostring

math.tonumber = meta.tonumber
math.tostring = meta.tostring
