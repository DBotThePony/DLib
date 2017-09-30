
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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

return combat
