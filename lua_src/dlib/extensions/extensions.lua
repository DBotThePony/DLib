
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
local Color = Color

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
