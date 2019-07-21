
--
-- Copyright (C) 2017-2019 DBotThePony

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


if CLIENT then
	local pixelvis_handle_t = FindMetaTable('pixelvis_handle_t')
	local util = util

	--[[
		@doc
		@fname pixelvis_handle_t:Visible
		@alias pixelvis_handle_t:IsVisible
		@alias pixelvis_handle_t:PixelVisible
		@args Vector pos, number radius

		@client

		@desc
		!g:util.PixelVisible
		@enddesc

		@returns
		number: visibility
	]]
	function pixelvis_handle_t:Visible(pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	function pixelvis_handle_t:IsVisible(pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	function pixelvis_handle_t:PixelVisible(pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	local player = player
	local IsValid = FindMetaTable('Entity').IsValid
	local GetTable = FindMetaTable('Entity').GetTable
	local GetVehicle = FindMetaTable('Player').GetVehicle
	local vehMeta = FindMetaTable('Vehicle')
	local NULL = NULL
	local ipairs = ipairs

	local LocalPlayer = LocalPlayer
	local GetWeapons = FindMetaTable('Player').GetWeapons

	local function updateWeaponFix()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local weapons = GetWeapons(ply)
		if not weapons then return end

		for k, wep in ipairs(weapons) do
			local tab = GetTable(wep)

			if not tab.DrawWeaponSelection_DLib and tab.DrawWeaponSelection then
				tab.DrawWeaponSelection_DLib = tab.DrawWeaponSelection

				tab.DrawWeaponSelection = function(self, x, y, w, h, a)
					local can = hook.Run('DrawWeaponSelection', self, x, y, w, h, a)
					if can == false then return end

					hook.Run('PreDrawWeaponSelection', self, x, y, width, height, alpha)
					local A, B, C, D, E, F = tab.DrawWeaponSelection_DLib(self, x, y, w, h, a)
					hook.Run('PostDrawWeaponSelection', self, x, y, width, height, alpha)
					return A, B, C, D, E, F
				end
			end
		end
	end

	timer.Create('DLib.DrawWeaponSelection', 10, 0, updateWeaponFix)
	updateWeaponFix()

	--[[
		@doc
		@fname vgui.Create
		@replaces
		@args string tableName, Panel parent, vararg any

		@desc
		Patched !g:vgui.Create which
		throws an (no call aborting) error with stack trace when attempting to create non existant panel
		and with hooks `VGUIPanelConstructed`, `VGUIPanelInitialized` and `VGUIPanelCreated` being called inside it
		if other mod already overrides this function, override is aborted and i18n will be rendered useless for panels
		@enddesc

		@returns
		Panel: the created panel or nil if panel doesn't exist (with an error sent to error handler)
	]]

	--[[
		@doc
		@hook VGUIPanelConstructed
		@args Panel self, Panel parent, vararg any

		@desc
		Called **before** `Panel:Init()` called
		@enddesc
	]]

	--[[
		@doc
		@hook VGUIPanelInitialized
		@args Panel self, Panel parent, vararg any

		@desc
		Called **before** `Panel:Prepare()` called
		@enddesc
	]]

	--[[
		@doc
		@hook VGUIPanelCreated
		@args Panel self, Panel parent, vararg any

		@desc
		Called **after** everything.
		@enddesc
	]]
	if not DLib._PanelDefinitions then
		local patched = false

		(function()
			if not vgui.GetControlTable or not vgui.CreateX then
				return
			end

			local PanelDefinitions

			for i = 1, 10 do
				local name, value = debug.getupvalue(vgui.GetControlTable, 1)

				if name == 'PanelFactory' then
					PanelDefinitions = value
					break
				end
			end

			if not PanelDefinitions then
				return
			end

			patched = true
			local vgui = vgui
			vgui.CreateNative = vgui.CreateX
			DLib._PanelDefinitions = PanelDefinitions
			vgui.PanelDefinitions = PanelDefinitions
			local CreateNative = vgui.CreateNative
			local error = error
			local table = table

			local recursive = false

			function vgui.Create(class, parent, name, ...)
				if class == '' then return end

				if not PanelDefinitions[class] then
					local panel = CreateNative(class, parent, name, ...)

					if not panel and not recursive then
						ProtectedCall(function()
							error('Native panel "' .. class .. '" is either invalid or does not exist. If code is trying to create this panel directly - this panel simply does not exist.', 4)
						end)
					elseif panel and not recursive then
						hook.Run('VGUIPanelConstructed', panel, ...)
						hook.Run('VGUIPanelInitialized', panel, ...)
						hook.Run('VGUIPanelCreated', panel, ...)
					end

					return panel
				end

				local meta = PanelDefinitions[class]

				if not meta.Base then
					error('Missing panel base of ' .. class .. '. This should never happen!')
				end

				local prevrecursive = recursive
				if not prevrecursive then
					recursive = true
				end

				local panel = vgui.Create(meta.Base, parent, name or classname)

				if not panel then
					recursive = false

					if not prevrecursive then
						error('Unable to create base panel "' .. meta.Base .. '" of "' .. class .. '" because base panel does not exist!')
					else
						error('Unable to find base panel "' .. meta.Base .. '" of "' .. class .. '". Panel inheritance tree might be corrupted because of missing base panels.')
					end
				end

				table.Merge(panel:GetTable(), meta)
				panel.BaseClass = PanelDefinitions[meta.Base]
				panel.ClassName = class

				if not prevrecursive then
					recursive = false
					hook.Run('VGUIPanelConstructed', panel, ...)
				end

				if panel.Init then
					local err2 = '<lua memory corruption>'
					local status = xpcall(panel.Init, function(err)
						recursive = false
						err2 = err
						ProtectedCall(error:Wrap(err, 3))
					end, panel, ...)

					if not status then
						error('Rethrow: Look for error above - ' .. err2)
					end
				end

				if not prevrecursive then
					hook.Run('VGUIPanelInitialized', panel, ...)
				end

				panel:Prepare()

				if not prevrecursive then
					hook.Run('VGUIPanelCreated', panel, ...)
				end

				return panel
			end
		end)()

		if not patched then
			DLib.Message('Unable to fully replace vgui.Create, falling back to old one patch of vgui.Create... Localization might break!')
			local vgui = vgui
			vgui.DLib_Create = vgui.DLib_Create or vgui.Create
			local ignore = 0

			function vgui.Create(...)
				if ignore == FrameNumberL() then return vgui.DLib_Create(...) end

				ignore = FrameNumberL()
				local pnl = vgui.DLib_Create(...)
				ignore = 0

				if not pnl then return end
				hook.Run('VGUIPanelConstructed', pnl, ...)
				hook.Run('VGUIPanelInitialized', pnl, ...)
				hook.Run('VGUIPanelCreated', pnl, ...)
				return pnl
			end
		end
	end
end

local CSoundPatch = FindMetaTable('CSoundPatch')

--[[
	@doc
	@fname CSoundPatch:IsValid

	@returns
	boolean: IsPlaying()
]]
function CSoundPatch:IsValid()
	return self:IsPlaying()
end

--[[
	@doc
	@fname CSoundPatch:Remove
]]
function CSoundPatch:Remove()
	return self:Stop()
end

local meta = getmetatable(function() end) or {}

function meta:tonumber(base)
	return tonumber(self, base)
end

function meta:tostring()
	return tostring(self)
end

debug.setmetatable(function() end, meta)

--[[
	@doc
	@fname string.tonumber
	@args number base = 10

	@returns
	number
]]

--[[
	@doc
	@fname string:tonumber
	@args number base = 10

	@returns
	number
]]

--[[
	@doc
	@fname math.tonumber
	@args number base = 10

	@returns
	number
]]

--[[
	@doc
	@fname number:tonumber
	@args number base = 10

	@returns
	number
]]

--[[
	@doc
	@fname string.tostring

	@returns
	string
]]

--[[
	@doc
	@fname string:tostring

	@returns
	string
]]

--[[
	@doc
	@fname math.tostring

	@returns
	string
]]

--[[
	@doc
	@fname number:tostring

	@returns
	string
]]
string.tonumber = meta.tonumber
string.tostring = meta.tostring

math.tonumber = meta.tonumber
math.tostring = meta.tostring
