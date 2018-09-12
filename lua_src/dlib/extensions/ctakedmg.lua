
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


local meta = FindMetaTable('CTakeDamageInfo')
local ctakedmg = DLib.module('ctakedmg')

local damageTypes = {
	{DMG_CRUSH, 'Crush'},
	{DMG_BULLET, 'Bullet'},
	{DMG_SLASH, 'Slash'},
	{DMG_SLASH, 'Slashing'},
	{DMG_BURN, 'Burn'},
	{DMG_BURN, 'Fire'},
	{DMG_BURN, 'Flame'},
	{DMG_VEHICLE, 'Vehicle'},
	{DMG_FALL, 'Fall'},
	{DMG_BLAST, 'Blast'},
	{DMG_CLUB, 'Club'},
	{DMG_SHOCK, 'Shock'},
	{DMG_SONIC, 'Sonic'},
	{DMG_ENERGYBEAM, 'EnergyBeam'},
	{DMG_ENERGYBEAM, 'Laser'},
	{DMG_DROWN, 'Drown'},
	{DMG_PARALYZE, 'Paralyze'},
	{DMG_NERVEGAS, 'Gaseous'},
	{DMG_NERVEGAS, 'NergeGas'},
	{DMG_NERVEGAS, 'Gas'},
	{DMG_POISON, 'Poision'},
	{DMG_ACID, 'Acid'},
	{DMG_AIRBOAT, 'Airboat'},
	{DMG_BUCKSHOT, 'Buckshot'},
	{DMG_DIRECT, 'Direct'},
	{DMG_DISSOLVE, 'Dissolve'},
	{DMG_DROWNRECOVER, 'DrownRecover'},
	{DMG_PHYSGUN, 'Physgun'},
	{DMG_PLASMA, 'Plasma'},
	{DMG_RADIATION, 'Radiation'},
	{DMG_SLOWBURN, 'Slowburn'},
}

for i, dmg in ipairs(damageTypes) do
	ctakedmg['Is' .. dmg[2] .. 'Damage'] = function(self)
		return bit.band(self:GetDamageType(), dmg[1]) ~= 0
	end

	meta['Is' .. dmg[2] .. 'Damage'] = ctakedmg['Is' .. dmg[2] .. 'Damage']
end

function ctakedmg:TypesArray()
	local output = {}
	local types = self:GetDamageType()

	for i, dmg in ipairs(damageTypes) do
		if bit.band(types, dmg[1]) == dmg[1] then
			table.insert(output, dmg[1])
		end
	end

	return output
end

meta.TypesArray = ctakedmg.TypesArray

function ctakedmg:Copy(copyDataInto)
	local a = self:GetAttacker()
	local b = self:GetInflictor()
	local c = self:GetDamage()
	local d = self:GetMaxDamage()
	local e = self:GetReportedPosition()
	local j = self:GetDamagePosition()
	local g = self:GetDamageType()

	copyDataInto = copyDataInto or DamageInfo()
	copyDataInto:SetAttacker(a)
	copyDataInto:SetInflictor(b)
	copyDataInto:SetDamage(c)
	copyDataInto:SetMaxDamage(d)
	copyDataInto:SetReportedPosition(e)
	copyDataInto:SetDamagePosition(j)
	copyDataInto:SetDamageType(g)
	return copyDataInto
end

function ctakedmg:Receive(from)
	self:SetAttacker(from:GetAttacker())
	self:SetInflictor(from:GetInflictor())
	self:SetDamage(from:GetDamage())
	self:SetMaxDamage(from:GetMaxDamage())
	self:SetReportedPosition(from:GetReportedPosition())
	self:SetDamagePosition(from:GetDamagePosition())
	self:SetDamageType(from:GetDamageType())
	return self
end

meta.Copy = ctakedmg.Copy
meta.Receive = ctakedmg.Receive

return ctakedmg
