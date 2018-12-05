
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


local entMeta = FindMetaTable('Entity')
local plyMeta = FindMetaTable('Player')
local wepMeta = FindMetaTable('Weapon')
local vehMeta = FindMetaTable('Vehicle')
local npcMeta = FindMetaTable('NPC')

function entMeta:IsClientsideEntity()
	return false
end

function entMeta:SetNWUInt(name, value)
	assert(type(value) == 'number', 'Value passed is not a number')

	if value < 0 then
		error('Value can not be negative')
	end

	if value > 0x100000000 then
		error('Integer overflow')
	end

	if value >= 0x7FFFFFFF then
		value = value - 0x100000000
	end

	self:SetNWInt(name, value)
end

function entMeta:GetNWUInt(name, ifNone)
	if type(ifNone) == 'number' then
		if ifNone < 0 then
			error('Value can not be negative')
		end

		if ifNone > 0x100000000 then
			error('Integer overflow')
		end
	end

	local value = self:GetNWInt(name, ifNone)

	if grab < 0 then
		return 0x100000000 + value
	else
		return value
	end
end

function entMeta:SetNW2UInt(name, value)
	assert(type(value) == 'number', 'Value passed is not a number')

	if value < 0 then
		error('Value can not be negative')
	end

	if value > 0x100000000 then
		error('Integer overflow')
	end

	if value >= 0x7FFFFFFF then
		value = value - 0x100000000
	end

	self:SetNW2Int(name, value)
end

function entMeta:GetNW2UInt(name, ifNone)
	if type(ifNone) == 'number' then
		if ifNone < 0 then
			error('Value can not be negative')
		end

		if ifNone > 0x100000000 then
			error('Integer overflow')
		end
	end

	local value = self:GetNW2Int(name, ifNone)

	if grab < 0 then
		return 0x100000000 + value
	else
		return value
	end
end

function plyMeta:GetActiveWeaponClass()
	local weapon = self:GetActiveWeapon()
	if not weapon:IsValid() then return nil end
	return weapon:GetClass()
end

npcMeta.GetActiveWeaponClass = plyMeta.GetActiveWeaponClass

if CLIENT then
	local CSEnt = FindMetaTable('CSEnt')
	entMeta.RemoveDLib = entMeta.RemoveDLib or entMeta.Remove

	function CSEnt:IsClientsideEntity()
		return true
	end

	function entMeta:IsClientsideEntity()
		local class = self:GetClass()
		return class == 'class C_PhysPropClientside' or class == 'class C_ClientRagdoll' or class == 'class CLuaEffect'
	end

	function entMeta:Remove()
		local class = self:GetClass()

		if class ~= 'class C_PhysPropClientside' and class ~= 'class C_ClientRagdoll' and class ~= 'class CLuaEffect' then
			print(debug.traceback('[DLib] Maybe removal of non clientside entity (' .. (class or 'NOT_A_CLASS') .. ')', 1))
		end

		return self:RemoveDLib()
	end
else
	function entMeta:BuddhaEnable()
		self:SetSaveValue('m_takedamage', DAMAGE_MODE_BUDDHA)
	end

	function entMeta:BuddhaDisable()
		self:SetSaveValue('m_takedamage', DAMAGE_MODE_ENABLED)
	end

	function entMeta:IsBuddhaEnabled()
		return self:GetSaveTable().m_takedamage == DAMAGE_MODE_BUDDHA
	end
end

function plyMeta:GetHealth()
	return self:Health()
end

function plyMeta:GetArmor()
	return self:Armor()
end

function plyMeta:IsAlive()
	return self:Alive()
end

function plyMeta:GetIsAlive()
	return self:Alive()
end

function wepMeta:GetClip1()
	return self:Clip1()
end

function wepMeta:GetClip2()
	return self:Clip2()
end

-- placeholder for now
function plyMeta:GetMaxArmor()
	return 100
end

local VehicleListIterable = {}

local function rebuildVehicleList()
	for classname, data in pairs(list.GetForEdit('Vehicles')) do
		if data.Model then
			VehicleListIterable[data.Model:lower()] = data
		end
	end
end

timer.Create('DLib.RebuildVehicleListNames', 10, 0, rebuildVehicleList)
rebuildVehicleList()

if CLIENT then
	local player = player
	local IsValid = FindMetaTable('Entity').IsValid
	local GetTable = FindMetaTable('Entity').GetTable
	local GetVehicle = FindMetaTable('Player').GetVehicle
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

	function vehMeta:GetPrintName()
		if self.__dlibCachedName then
			return self.__dlibCachedName
		end

		local getname = self.PrintName or (VehicleListIterable[self:GetModel()] and VehicleListIterable[self:GetModel()].Name)

		if not getname then
			local classname = self:GetClass()
			getname = language.GetPhrase(classname)
		end

		self.__dlibCachedName = getname

		return getname
	end

	function entMeta:GetPrintNameDLib()
		if self.GetPrintName then return self:GetPrintName() end
		return self.PrintName or language.GetPhrase(self:GetClass())
	end
else
	entMeta.GetNetworkName = entMeta.GetName
	entMeta.SetNetworkName = entMeta.SetName
	entMeta.GetNetworkedName = entMeta.GetName
	entMeta.SetNetworkedName = entMeta.SetName
	entMeta.GetTargetName = entMeta.GetName
	entMeta.SetTargetName = entMeta.SetName

	function vehMeta:GetPrintName()
		if self.__dlibCachedName then
			return self.__dlibCachedName
		end

		local getname = self.PrintName

		if not getname then
			getname = VehicleListIterable[self:GetModel()] or self:GetClass()
		end

		self.__dlibCachedName = getname

		return getname
	end

	function entMeta:GetPrintNameDLib()
		if self.GetPrintName then return self:GetPrintName() end
		return self.PrintName
	end

	local nextBot = FindMetaTable('NextBot')
	local GetTable = entMeta.GetTable

	function nextBot:GetActiveWeapon(...)
		local tab = GetTable(self)

		if tab.GetActiveWeapon then
			return tab.GetActiveWeapon(self, ...)
		end

		return self
	end
end
