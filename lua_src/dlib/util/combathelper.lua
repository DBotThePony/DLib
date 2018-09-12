
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

local function interval(val, min, max)
	return val > min and val <= max
end

function combat.inPVS(point1, point2, eyes, yawLimit, pitchLimit)
	if type(point1) ~= 'Vector' then
		if point1.EyeAnglesFixed then
			eyes = eyes or point1:EyeAnglesFixed()
		elseif point1.EyeAngles then
			eyes = eyes or point1:EyeAngles()
		end

		point1 = point1:EyePos()
	end

	if type(point2) ~= 'Vector' then
		point2 = point2:EyePos()
	end

	yawLimit = yawLimit or 60
	pitchLimit = pitchLimit or 60

	local ang = (point2 - point1):Angle()
	local diffPith = ang.p:AngleDifference(eyes.p)
	local diffYaw = ang.y:AngleDifference(eyes.y)

	return interval(diffYaw, -yawLimit, yawLimit) and interval(diffPith, -pitchLimit, pitchLimit)
end

function combat.turnAngle(point1, point2, eyes)
	if type(point1) ~= 'Vector' then
		if point1.EyeAnglesFixed then
			eyes = eyes or point1:EyeAnglesFixed()
		elseif point1.EyeAngles then
			eyes = eyes or point1:EyeAngles()
		end

		point1 = point1:EyePos()
	end

	if type(point2) ~= 'Vector' then
		point2 = point2:EyePos()
	end

	local ang = (point2 - point1):Angle()
	return ang.p:AngleDifference(eyes.p), ang.y:AngleDifference(eyes.y)
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
				local driver = ent2:GetDriver()

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
