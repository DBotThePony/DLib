
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- local Entity = Entity
-- local rawequal = rawequal
-- local entMeta = FindMetaTable('Entity')
-- local NULL = NULL
-- local type = type
-- local worldspawn = Entity(0)
-- local invalidVehicle
-- local game = game

-- function entMeta:IsValid()
-- 	local tp = type(self)
-- 	return tp ~= 'table'
-- 		and tp ~= 'string'
-- 		and tp ~= 'number'
-- 		and tp ~= 'boolean'
-- 		and tp ~= 'nil'
-- 		and self ~= NULL
-- 		and not rawequal(self, worldspawn)
-- 		and self ~= invalidVehicle
-- end

-- local function updateStuff()
-- 	worldspawn = game.GetWorld()

-- 	if worldspawn ~= NULL and not invalidVehicle then
-- 		invalidVehicle = ents.Create('prop_vehicle_prisoner_pod')
-- 		invalidVehicle:SetModel('models/nova/airboat_seat.mdl')
-- 		invalidVehicle:SetKeyValue('vehiclescript', 'scripts/vehicles/prisoner_pod.txt')
-- 		invalidVehicle:Spawn()
-- 		invalidVehicle:Activate()

-- 		timer.Simple(0.1, function()
-- 			invalidVehicle:Remove()
-- 		end)
-- 	end
-- end

-- timer.Create('dlib_worldspawn', 10, 0, updateStuff)
-- updateStuff()
