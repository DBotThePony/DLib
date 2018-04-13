
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
	vgui.DLib_Create = vgui.DLib_Create or vgui.Create
	local ignore = 0

	function vgui.Create(...)
		if ignore == FrameNumberL() then return vgui.DLib_Create(...) end

		ignore = FrameNumberL()
		local pnl = vgui.DLib_Create(...)
		ignore = 0

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

local entMeta = FindMetaTable('Entity')
local Vector, Angle = Vector, Angle

function entMeta:ApplyBoneManipulations()
	self.__dlib_BoneManipCache = self.__dlib_BoneManipCache or {}
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache
	__dlib_BoneManipCache.working = false

	for boneid = 0, self:GetBoneCount() - 1 do
		if __dlib_BoneManipCache.angles[boneid + 1] then
			self:ManipulateBoneAngles(boneid, __dlib_BoneManipCache.angles[boneid + 1])
		end

		if __dlib_BoneManipCache.position[boneid + 1] then
			--print(boneid, __dlib_BoneManipCache.position[boneid + 1])
			self:ManipulateBonePosition(boneid, __dlib_BoneManipCache.position[boneid + 1])
		end

		if __dlib_BoneManipCache.scale[boneid + 1] then
			self:ManipulateBoneScale(boneid, __dlib_BoneManipCache.scale[boneid + 1])
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
		__dlib_BoneManipCache.position[boneid + 1] = self:GetManipulateBonePosition(boneid)
		__dlib_BoneManipCache.scale[boneid + 1] = self:GetManipulateBoneScale(boneid)
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
	__dlib_BoneManipCache.scale[boneid + 1] = __dlib_BoneManipCache.scale[boneid + 1] or Vector(0, 0, 0)
	return __dlib_BoneManipCache.scale[boneid + 1]
end

function entMeta:GetManipulateBoneScale2(boneid)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	local __dlib_BoneManipCache = assert(self.__dlib_BoneManipCache, 'second tables must be initialized first')
	__dlib_BoneManipCache.scale[boneid + 1] = __dlib_BoneManipCache.scale[boneid + 1] or Vector(0, 0, 0)
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
	assert(type(value) == 'Vector', 'invalid angles')
	__dlib_BoneManipCache.position[boneid + 1] = Vector(value)
	return self
end

function entMeta:ManipulateBoneScale2(boneid, value)
	assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
	assert(type(value) == 'Vector', 'invalid angles')
	__dlib_BoneManipCache.scale[boneid + 1] = Vector(value)
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
		__dlib_BoneManipCache.position[boneid + 1] = __dlib_BoneManipCache.position[boneid + 1] or Vector(0, 0, 0)
		return __dlib_BoneManipCache.position[boneid + 1]
	else
		return self:GetManipulateBonePosition(boneid)
	end
end

function entMeta:GetManipulateBoneScale2Safe(boneid)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		__dlib_BoneManipCache.scale[boneid + 1] = __dlib_BoneManipCache.scale[boneid + 1] or Vector(1, 1, 1)
		return __dlib_BoneManipCache.scale[boneid + 1]
	else
		return self:GetManipulateBoneScale(boneid)
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
		assert(type(value) == 'number', 'invalid angles')
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
		assert(type(value) == 'Vector', 'invalid angles')
		__dlib_BoneManipCache.position[boneid + 1] = Vector(value)
	else
		self:ManipulateBonePosition(boneid, value)
	end

	return self
end

function entMeta:ManipulateBoneScale2Safe(boneid, value)
	local __dlib_BoneManipCache = self.__dlib_BoneManipCache

	if __dlib_BoneManipCache and __dlib_BoneManipCache.working then
		assert(type(boneid) == 'number' and boneid >= 0, 'invalid boneid')
		assert(type(value) == 'Vector', 'invalid angles')
		__dlib_BoneManipCache.scale[boneid + 1] = Vector(value)
	else
		return self:ManipulateBoneScale(boneid, value)
	end

	return self
end
