
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

local IsValid = FindMetaTable('Entity').IsValid
local type = type
local NULL = NULL
local table = table
local combat = DLib.module('combat')

function combat.findWeapon(dmginfo)
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
	if not IsValid(attacker) or not IsValid(inflictor) then return NULL, attacker, inflictor end
	if type(attacker) ~= 'Player' or not (type(inflictor) == 'Weapon' or attacker == inflictor) then return end
	local weapon = type(inflictor) == 'Weapon' and inflictor or attacker:GetActiveWeapon()
	return weapon, attacker, inflictor
end

function combat.findWeaponAlt(dmginfo)
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
	local weapon = inflictor

	if not IsValid(inflictor) and IsValid(attacker) then
		inflictor = attacker
		weapon = attacker
	end

	if not IsValid(attacker) or not IsValid(inflictor) then
		return inflictor, attacker, inflictor
	end

	if type(inflictor) ~= 'Weapon' and attacker.GetActiveWeapon then
		inflictor = attacker:GetActiveWeapon()
		weapon = inflictor
	end

	return weapon, attacker, inflictor
end

function combat.detect(dmginfo)
	local weapon, attacker, inflictor = combat.findWeapon(dmginfo)

	if not IsValid(weapon) then
		weapon = inflictor
	end

	return attacker, weapon, inflictor
end

function combat.findPlayers(self)
	if not IsValid(self) then
		return false
	end

	if type(self) == 'Player' then
		return {self}
	end

	if type(self) == 'Vehicle' then
		local driver = self:GetDriver()

		if not IsValid(driver) then
			return false
		end

		return {driver}
	end

	local MEM = {}
	local iterate = {self}
	local list = {}

	while #iterate > 0 do
		local ent = table.remove(iterate)

		if MEM[ent] then
			goto CONTINUE
		end

		MEM[ent] = true

		for i, ent2 in ipairs(self:GetChildren()) do
			if type(ent2) == 'Player' then
				table.insert(list, ent2)
			elseif type(ent2) == 'Vehicle' then
				local driver = self:GetDriver()

				if IsValid(driver) then
					table.insert(list, driver)
				end
			else
				table.insert(iterate, ent2)
			end
		end

		::CONTINUE::
	end

	return #list ~= 0 and table.deduplicate(list) or false
end

return combat
