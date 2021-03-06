
-- Copyright (C) 2017-2020 DBotThePony

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

-- CTakeDamageInfo/AddDamage
-- CTakeDamageInfo/GetAmmoType
-- CTakeDamageInfo/GetAttacker
-- CTakeDamageInfo/GetBaseDamage
-- CTakeDamageInfo/GetDamage
-- CTakeDamageInfo/GetDamageBonus
-- CTakeDamageInfo/GetDamageCustom
-- CTakeDamageInfo/GetDamageForce
-- CTakeDamageInfo/GetDamagePosition
-- CTakeDamageInfo/GetDamageType
--
-- CTakeDamageInfo/GetInflictor
-- CTakeDamageInfo/GetMaxDamage
-- CTakeDamageInfo/GetReportedPosition
-- CTakeDamageInfo/IsBulletDamage
-- CTakeDamageInfo/IsDamageType
-- CTakeDamageInfo/IsExplosionDamage
-- CTakeDamageInfo/IsFallDamage
-- CTakeDamageInfo/ScaleDamage
-- CTakeDamageInfo/SetAmmoType
-- CTakeDamageInfo/SetAttacker
--
-- CTakeDamageInfo/SetDamage
-- CTakeDamageInfo/SetDamageBonus
-- CTakeDamageInfo/SetDamageCustom
-- CTakeDamageInfo/SetDamageForce
-- CTakeDamageInfo/SetDamagePosition
-- CTakeDamageInfo/SetDamageType
-- CTakeDamageInfo/SetInflictor
-- CTakeDamageInfo/SetMaxDamage
-- CTakeDamageInfo/SetReportedPosition
-- CTakeDamageInfo/SubtractDamage

damageTypes = {
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

class DLib.LTakeDamageInfo
	for {dtype, dname} in *damageTypes
		@__base['Is' .. dname .. 'Damage'] = => @IsDamageType(dtype)

	TypesArray: => [dtype for {dtype, dname} in *damageTypes when @IsDamageType(dtype)]

	@__base.MetaName = 'LTakeDamageInfo'

	new: (copyfrom) =>
		@damage = 0
		@baseDamage = 0
		@maxDamage = 0
		@ammoType = 0
		@damageBonus = 0
		@damageCustomFlags = 0
		@damageForce = Vector()
		@reportedPosition = Vector()
		@damagePosition = Vector()
		@damageType = DMG_GENERIC
		@attacker = NULL
		@inflictor = NULL
		@recordedInflictor = NULL

		DLib.LTakeDamageInfo.CopyInto(copyfrom, @) if copyfrom

	RecordInflictor: =>
		if @inflictor ~= @attacker or not @attacker.GetActiveWeapon
			@recordedInflictor = @inflictor
			return

		weapon = @attacker\GetActiveWeapon()

		if not IsValid(weapon)
			@recordedInflictor = @inflictor
			return

		@recordedInflictor = weapon

	AddDamage: (damageNum = 0) => @damage = math.clamp(@damage + damageNum, 0, 0x7FFFFFFF)
	SubtractDamage: (damageNum = 0) => @damage = math.clamp(@damage - damageNum, 0, 0x7FFFFFFF)

	GetDamageType: => @damageType
	GetAttacker: => @attacker
	GetInflictor: => @inflictor
	GetRecordedInflictor: => @recordedInflictor
	GetBaseDamage: => @damage
	GetAmmoType: => @ammoType
	GetDamage: => @damage
	GetDamageBonus: => @damageBonus
	GetDamageCustom: => @damageCustomFlags
	GetDamageForce: => @damageForce
	GetDamagePosition: => @damagePosition
	GetReportedPosition: => @reportedPosition
	GetDamageForce: => @damageForce
	GetDamageType: => @damageType
	GetMaxDamage: => @maxDamage
	GetBaseDamage: => @baseDamage
	IsDamageType: (dtype) => @damageType\band(dtype) == dtype
	IsBulletDamage: => @IsDamageType(DMG_BULLET)
	IsExplosionDamage: => @IsDamageType(DMG_BLAST)
	IsFallDamage: => @IsDamageType(DMG_FALL)
	ScaleDamage: (scaleBy) => @damage = math.clamp(@damage * scaleBy, 0, 0x7FFFFFFF)
	SetAmmoType: (ammotype) => @ammoType = ammotype
	SetAttacker: (attacker) => @attacker = assert(isentity(attacker) and attacker, 'Invalid attacker')
	SetInflictor: (attacker) => @inflictor = assert(isentity(attacker) and attacker, 'Invalid inflictor')
	SetRecordedInflictor: (attacker) => @recordedInflictor = assert(isentity(attacker) and attacker, 'Invalid recorded inflictor')
	SetDamage: (dmg) => @damage = math.clamp(dmg, 0, 0x7FFFFFFF)
	SetDamageBonus: (dmg) => @damageBonus = math.clamp(dmg, 0, 0x7FFFFFFF)
	SetMaxDamage: (dmg) => @maxDamage = math.clamp(dmg, 0, 0x7FFFFFFF)
	SetDamageCustom: (dmg) => @damageCustomFlags = dmg
	SetDamageType: (dmg) => @damageType = dmg
	SetDamagePosition: (pos) => @damagePosition = pos
	SetReportedPosition: (pos) => @reportedPosition = pos
	SetDamageForce: (force) => @damageForce = force
	SetBaseDamage: (damage) => @baseDamage = damage

	Copy: => DLib.LTakeDamageInfo(@)

DLib.LTakeDamageInfo.CopyInto = (objectSource, self) ->
	with objectSource
		@SetAmmoType(\GetAmmoType())
		@SetAttacker(\GetAttacker())
		@SetBaseDamage(\GetBaseDamage()) if @SetBaseDamage and .SetBaseDamage
		@SetDamage(\GetDamage())
		@SetDamageBonus(\GetDamageBonus())
		@SetDamageCustom(\GetDamageCustom())
		@SetDamageForce(\GetDamageForce())
		@SetDamagePosition(\GetDamagePosition())
		@SetDamageType(\GetDamageType())
		@SetInflictor(\GetInflictor())
		@SetMaxDamage(\GetMaxDamage())
		@SetReportedPosition(\GetReportedPosition())

	return self
