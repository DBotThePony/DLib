
--
-- Copyright (C) 2017 DBot
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

function PhysObj:SetAngleVelocity(newAngle)
	return self:AddAngleVelocity(-self:GetAngleVelocity() + newAngle)
end

PhysObj.DLibSetMass = PhysObj.DLibSetMass or PhysObj.SetMass
PhysObj.DLibEnableCollisions = PhysObj.DLibEnableCollisions or PhysObj.EnableCollisions
PhysObj.DLibEnableDrag = PhysObj.DLibEnableDrag or PhysObj.EnableDrag
PhysObj.DLibEnableMotion = PhysObj.DLibEnableMotion or PhysObj.EnableMotion
PhysObj.DLibEnableGravity = PhysObj.DLibEnableGravity or PhysObj.EnableGravity

function PhysObj:SetMass(newMass)
	if newMass <= 0 then
		error('Mass can not be lower or equal to 0!')
	end

	return self:DLibSetMass(newMass)
end

local worldspawn, worldspawnPhys

-- shut up dumb addons
function PhysObj:EnableCollisions(newStatus)
	worldspawn = worldspawn or Entity(0)
	worldspawnPhys = worldspawnPhys or worldspawn:GetPhysicsObject()

	if worldspawnPhys == self then
		error('Attempt to call :EnableCollisions() on World PhysObj!')
	end

	return self:DLibEnableCollisions(newStatus)
end

function PhysObj:EnableDrag(newStatus)
	worldspawn = worldspawn or Entity(0)
	worldspawnPhys = worldspawnPhys or worldspawn:GetPhysicsObject()

	if worldspawnPhys == self then
		print(debug.traceback('Attempt to call :EnableDrag() on World PhysObj!'))
		return
	end

	return self:DLibEnableDrag(newStatus)
end

function PhysObj:EnableMotion(newStatus)
	worldspawn = worldspawn or Entity(0)
	worldspawnPhys = worldspawnPhys or worldspawn:GetPhysicsObject()

	if worldspawnPhys == self then
		print(debug.traceback('Attempt to call :EnableMotion() on World PhysObj!'))
		return
	end

	return self:DLibEnableMotion(newStatus)
end

function PhysObj:EnableGravity(newStatus)
	worldspawn = worldspawn or Entity(0)
	worldspawnPhys = worldspawnPhys or worldspawn:GetPhysicsObject()

	if worldspawnPhys == self then
		print(debug.traceback('Attempt to call :EnableGravity() on World PhysObj!'))
		return
	end

	return self:DLibEnableGravity(newStatus)
end
