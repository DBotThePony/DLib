
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

local PhysObj = FindMetaTable('PhysObj')
local vectorMeta = FindMetaTable('Vector')
local vehicleMeta = FindMetaTable('Vehicle')
local entMeta = FindMetaTable('Entity')
local Color = Color
local math = math
local ipairs = ipairs
local assert = assert
local select = select
local language = language
local list = list
local pairs = pairs
local CLIENT = CLIENT

function PhysObj:SetAngleVelocity(newAngle)
	return self:AddAngleVelocity(newAngle - self:GetAngleVelocity())
end

PhysObj.DLibSetMass = PhysObj.DLibSetMass or PhysObj.SetMass
PhysObj.DLibEnableCollisions = PhysObj.DLibEnableCollisions or PhysObj.EnableCollisions
PhysObj.DLibEnableDrag = PhysObj.DLibEnableDrag or PhysObj.EnableDrag
PhysObj.DLibEnableMotion = PhysObj.DLibEnableMotion or PhysObj.EnableMotion
PhysObj.DLibEnableGravity = PhysObj.DLibEnableGravity or PhysObj.EnableGravity

function PhysObj:SetMass(newMass)
	if newMass <= 0 then
		error('Mass can not be lower or equal to 0!', 2)
	end

	return self:DLibSetMass(newMass)
end

local worldspawn, worldspawnPhys

-- shut up dumb addons
function PhysObj:EnableCollisions(newStatus)
	worldspawn = worldspawn or Entity(0)
	worldspawnPhys = worldspawnPhys or worldspawn:GetPhysicsObject()

	if worldspawnPhys == self then
		error('Attempt to call :EnableCollisions() on World PhysObj!', 2)
	end

	return self:DLibEnableCollisions(newStatus)
end

function vectorMeta:Copy()
	return Vector(self)
end

function vectorMeta:__call()
	return Vector(self)
end

function vectorMeta:Receive(target)
	local x, y, z = target.x, target.y, target.z
	self.x, self.y, self.z = x, y, z
	return self
end

function vectorMeta:RotateAroundAxis(axis, rotation)
	local ang = self:Angle()
	ang:RotateAroundAxis(axis, rotation)
	return self:Receive(ang:Forward() * self:Length())
end

function vectorMeta:ToColor()
	return Color(self.x * 255, self.y * 255, self.z * 255)
end

local gsql = sql
local sql = DLib.module('sql', 'sql')

function sql.Query(...)
	local data = gsql.Query(...)

	if data == false then
		DLib.Message('SQL: ', ...)
		DLib.Message(sql.LastError())
	end

	return data
end

sql.register()

function math.progression(self, min, max, middle)
	if self < min then return min end

	if middle then
		if self < min or self >= max then return 0 end

		if self < middle then
			return math.min((self - min) / (middle - min), 1)
		elseif self > middle then
			return 1 - math.min((self - middle) / (max - middle), 1)
		elseif self == middle then
			return 1
		end
	end

	return math.min((self - min) / (max - min), 1)
end

function math.equal(...)
	local amount = select('#', ...)
	assert(amount > 1, 'At least two numbers are required!')
	local lastValue

	for i = 1, amount do
		local value = select(i, ...)
		lastValue = lastValue or value
		if value ~= lastValue then return false end
	end

	return true
end

function math.average(...)
	local amount = select('#', ...)
	assert(amount > 1, 'At least two numbers are required!')
	local total = 0

	for i = 1, amount do
		total = total + select(i, ...)
	end

	return total / amount
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
	function vehicleMeta:GetPrintName()
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
	function vehicleMeta:GetPrintName()
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
end
