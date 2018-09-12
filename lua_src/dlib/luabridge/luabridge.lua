
--
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
					local err2
					local status = xpcall(panel.Init, function(err)
						recursive = false
						err2 = err
						ProtectedCall(error:Wrap(err, 2))
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

local entMeta = FindMetaTable('Entity')
local Vector, Angle = Vector, Angle
local LVector = LVector

function entMeta:ApplyBoneManipulations()
	self.__dlib_BoneManipCache = self.__dlib_BoneManipCache or {}
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache
	__dlib_BoneManipCache.working = false

	for boneid = 0, self:GetBoneCount() - 1 do
		if __dlib_BoneManipCache.angles[boneid + 1] then
			self:ManipulateBoneAngles(boneid, __dlib_BoneManipCache.angles[boneid + 1])
		end

		if __dlib_BoneManipCache.position[boneid + 1] then
			self:ManipulateBonePosition(boneid, __dlib_BoneManipCache.position[boneid + 1]:ToNative())
		end

		if __dlib_BoneManipCache.scale[boneid + 1] then
			self:ManipulateBoneScale(boneid, __dlib_BoneManipCache.scale[boneid + 1]:ToNative())
		end

		if __dlib_BoneManipCache.jiggle[boneid + 1] then
			self:ManipulateBoneJiggle(boneid, __dlib_BoneManipCache.jiggle[boneid + 1])
		end
	end

	return self
end

function entMeta:ResetBoneManipCache()
	self.__dlib_BoneManipCache = self.__dlib_BoneManipCache or {}
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache
	__dlib_BoneManipCache.working = true
	__dlib_BoneManipCache.angles = {}
	__dlib_BoneManipCache.position = {}
	__dlib_BoneManipCache.scale = {}
	__dlib_BoneManipCache.jiggle = {}

	for boneid = 0, self:GetBoneCount() - 1 do
		__dlib_BoneManipCache.angles[boneid + 1] = self:GetManipulateBoneAngles(boneid)
		__dlib_BoneManipCache.position[boneid + 1] = LVector(self:GetManipulateBonePosition(boneid))
		__dlib_BoneManipCache.scale[boneid + 1] = LVector(self:GetManipulateBoneScale(boneid))
		__dlib_BoneManipCache.jiggle[boneid + 1] = self:GetManipulateBoneJiggle(boneid)
	end

	return self
end

local type = type
local assert = assert

function entMeta:GetManipulateBoneAngles2(boneid)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	local __dlib_BoneManipCache = assert(self.__dlib_BoneManipCache, 'second tables must be initialized first')
	__dlib_BoneManipCache.angles[boneid + 1] = __dlib_BoneManipCache.angles[boneid + 1] or Angle(0, 0, 0)
	return __dlib_BoneManipCache.angles[boneid + 1]
end

function entMeta:GetManipulateBoneJiggle2(boneid)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	local __dlib_BoneManipCache = assert(self.__dlib_BoneManipCache, 'second tables must be initialized first')
	__dlib_BoneManipCache.jiggle[boneid + 1] = __dlib_BoneManipCache.jiggle[boneid + 1] or 0
	return __dlib_BoneManipCache.jiggle[boneid + 1]
end

function entMeta:GetManipulateBonePosition2(boneid)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	local __dlib_BoneManipCache = assert(self.__dlib_BoneManipCache, 'second tables must be initialized first')
	__dlib_BoneManipCache.scale[boneid + 1] = __dlib_BoneManipCache.scale[boneid + 1] or LVector(0, 0, 0)
	return __dlib_BoneManipCache.scale[boneid + 1]
end

function entMeta:GetManipulateBoneScale2(boneid)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	local __dlib_BoneManipCache = assert(self.__dlib_BoneManipCache, 'second tables must be initialized first')
	__dlib_BoneManipCache.scale[boneid + 1] = __dlib_BoneManipCache.scale[boneid + 1] or LVector(0, 0, 0)
	return __dlib_BoneManipCache.scale[boneid + 1]
end

function entMeta:ManipulateBoneAngles2(boneid, value)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	assert(type(value) == 'Angle', 'invalid angles')
	__dlib_BoneManipCache.angles[boneid + 1] = Angle(value)
	return self
end

function entMeta:ManipulateBoneJiggle2(boneid, value)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	assert(type(value) == 'number', 'invalid angles')
	__dlib_BoneManipCache.jiggle[boneid + 1] = value
	return self
end

function entMeta:ManipulateBonePosition2(boneid, value)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	assert(type(value) == 'Vector' or type(value) == 'LVector', 'invalid position')
	__dlib_BoneManipCache.position[boneid + 1] = LVector(value)
	return self
end

function entMeta:ManipulateBoneScale2(boneid, value)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	assert(type(value) == 'Vector' or type(value) == 'LVector', 'invalid scale')
	__dlib_BoneManipCache.scale[boneid + 1] = LVector(value)
	return self
end

-- safe

function entMeta:GetManipulateBoneAngles2Safe(boneid)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		__dlib_BoneManipCache.angles[boneid + 1] = __dlib_BoneManipCache.angles[boneid + 1] or Angle(0, 0, 0)
		return __dlib_BoneManipCache.angles[boneid + 1]
	else
		return self:GetManipulateBoneAngles(boneid)
	end
end

function entMeta:GetManipulateBoneJiggle2Safe(boneid)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		__dlib_BoneManipCache.jiggle[boneid + 1] = __dlib_BoneManipCache.jiggle[boneid + 1] or 0
		return __dlib_BoneManipCache.jiggle[boneid + 1]
	else
		return self:GetManipulateBoneJiggle(boneid)
	end
end

function entMeta:GetManipulateBonePosition2Safe(boneid)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		__dlib_BoneManipCache.position[boneid + 1] = __dlib_BoneManipCache.position[boneid + 1] or LVector(0, 0, 0)
		return __dlib_BoneManipCache.position[boneid + 1]
	else
		return LVector(self:GetManipulateBonePosition(boneid))
	end
end

function entMeta:GetManipulateBoneScale2Safe(boneid)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		__dlib_BoneManipCache.scale[boneid + 1] = __dlib_BoneManipCache.scale[boneid + 1] or LVector(1, 1, 1)
		return __dlib_BoneManipCache.scale[boneid + 1]
	else
		return LVector(self:GetManipulateBoneScale(boneid))
	end
end

function entMeta:ManipulateBoneAngles2Safe(boneid, value)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		assert(type(value) == 'Angle', 'invalid angles')
		__dlib_BoneManipCache.angles[boneid + 1] = Angle(value)
	else
		self:ManipulateBoneAngles(boneid, value)
	end

	return self
end

function entMeta:ManipulateBoneJiggle2Safe(boneid, value)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		assert(type(value) == 'number', 'invalid jiggle amount')
		__dlib_BoneManipCache.jiggle[boneid + 1] = value
	else
		self:ManipulateBoneJiggle(boneid, value)
	end

	return self
end

function entMeta:ManipulateBonePosition2Safe(boneid, value)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		assert(type(value) == 'Vector' or type(value) == 'LVector', 'invalid position')
		__dlib_BoneManipCache.position[boneid + 1] = LVector(value)
	else
		self:ManipulateBonePosition(boneid, value:ToNative())
	end

	return self
end

function entMeta:ManipulateBoneScale2Safe(boneid, value)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		assert(type(value) == 'Vector' or type(value) == 'LVector', 'invalid scale')
		__dlib_BoneManipCache.scale[boneid + 1] = LVector(value)
	else
		return self:ManipulateBoneScale(boneid, value:ToNative())
	end

	return self
end
