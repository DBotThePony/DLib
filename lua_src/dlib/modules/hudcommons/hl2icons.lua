
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


-- https://i.dbotthepony.ru/2019/04/hl2_19-26-56-40675b7.png

--[[
local chars = 'qwertyuiopasdfghjklzxcvbnm1234567890[]{}QWERTYUIOPASDFGHJKLZXCVBNM\'"<>!@?&^%$#()~`=+-_,./:;*'

surface.CreateFont('WeaponIconTest', {
	font = 'HalfLife2',
	size = ScreenSize(22),
	weight = 500
})

hook.Add('HUDPaint', 'WeaponIconTest', function()
	surface.SetTextPos(40, 40)
	surface.SetTextColor(255, 255, 255)
	local next = 0
	local next2 = 0

	for i in string.gmatch(chars, '.') do
		surface.SetFont('Trebuchet24')
		surface.DrawText(i .. ' === ')
		surface.SetFont('WeaponIconTest')
		surface.DrawText(i)
		next = next + 1
		if next > 8 then
			next2 = next2 + 1
			next = 0
		end
		surface.SetTextPos(next2 * 180 + 40, next * 60 + 40)
	end
end)
]]

jit.on()

local HUDCommons = DLib.HUDCommons
local type = type
local surface = surface

local stuff = {
	q = {'357Round', '357Bullet'},
	p = '9MM',
	w = 'CrossbowBolt',
	e = '357',
	r = 'SMGRound',
	t = 'SMGGrenade',
	u = 'PulseRound',
	i = 'RPG',
	o = 'SLAM',
	a = {'SMG', 'SMG1', 'MP7'},
	s = {'Buckshot', 'ShotgunRound'},
	d = 'Pistol',
	f = 'DoubleBarrel',
	q = 'Crossbow',
	h = {'TauGun', 'Tau', 'TauCannon'},
	j = 'Bugbait',
	k = 'Grenade',
	l = {'PulseRifle', 'AR2', 'OSIPR'},
	z = {'PulseEnergy', 'PulseBall', 'CombineBall'},
	x = 'RPGRound',
	c = 'Crowbar',
	v = 'GrenadeRound',
	b = 'Shotgun',
	n = 'Stunstick',
	m = {'Physcannon', 'PhysgunCannon'},
}

--[[
	@docpreprocess

	const stuff = {
		q: ['357Round', '357Bullet'],
		p: '9MM',
		w: 'CrossbowBolt',
		e: '357',
		r: 'SMGRound',
		t: 'SMGGrenade',
		u: 'PulseRound',
		i: 'RPG',
		o: 'SLAM',
		a: ['SMG', 'SMG1', 'MP7'],
		s: ['Buckshot', 'ShotgunRound'],
		d: 'Pistol',
		f: 'DoubleBarrel',
		q: 'Crossbow',
		h: ['TauGun', 'Tau', 'TauCannon'],
		j: 'Bugbait',
		k: 'Grenade',
		l: ['PulseRifle', 'AR2', 'OSIPR'],
		z: ['PulseEnergy', 'PulseBall', 'CombineBall'],
		x: 'RPGRound',
		c: 'Crowbar',
		v: 'GrenadeRound',
		b: 'Shotgun',
		n: 'Stunstick',
		m: ['Physcannon', 'PhysgunCannon'],
	}

	const sizes = [
		'',
		'Tiny',
		'Small',
		'VerySmall',
		'Big'
	]

	const reply = []

	for (const size of sizes) {
		let output = []

		output.push(`@func DLib.HUDCommons.GetWeaponAmmoIcon${size}`)
		output.push(`@client`)
		output.push(`@deprecated`)
		output.push(`@args Weapon weapon`)
		output.push(`@returns`)
		output.push(`function: or nil`)

		reply.push(output)
		output = []

		output.push(`@func DLib.HUDCommons.GetWeaponSecondaryAmmoIcon${size}`)
		output.push(`@client`)
		output.push(`@deprecated`)
		output.push(`@args Weapon weapon`)
		output.push(`@returns`)
		output.push(`function: or nil`)

		reply.push(output)
		output = []

		output.push(`@func DLib.HUDCommons.DrawWeaponAmmoIcon${size}`)
		output.push(`@client`)
		output.push(`@deprecated`)
		output.push(`@args Weapon weapon, number x, number y, Color r = nil, number g = nil, number b = nil, number a = nil`)
		output.push(`@desc`)
		output.push(`\`r\` argument can be either Color or a number`)
		output.push(`or color arguments can be fully omitted`)
		output.push(`x, y positions can be omitted, this will cause icons to draw at last`)
		output.push(`position defined by !g:surface.SetTextPos`)
		output.push(`@enddesc`)
		output.push(`@returns`)
		output.push(`function: or nil`)

		reply.push(output)
		output = []

		output.push(`@func DLib.HUDCommons.DrawWeaponSecondaryAmmoIcon${size}`)
		output.push(`@client`)
		output.push(`@deprecated`)
		output.push(`@args Weapon weapon, number x, number y, Color r = nil, number g = nil, number b = nil, number a = nil`)
		output.push(`@desc`)
		output.push(`\`r\` argument can be either Color or a number`)
		output.push(`or color arguments can be fully omitted`)
		output.push(`x, y positions can be omitted, this will cause icons to draw at last`)
		output.push(`position defined by !g:surface.SetTextPos`)
		output.push(`@enddesc`)
		output.push(`@returns`)
		output.push(`function: or nil`)

		reply.push(output)

		for (const key in stuff) {
			let value = stuff[key]

			if (typeof value == 'string') {
				value = [value]
			}

			for (const name of value) {
				const output = []

				output.push(`@func DLib.HUDCommons.Draw${name}${size}`)
				output.push(`@args number x, number y, Color r = nil, number g = nil, number b = nil, number a = nil`)
				output.push(`@client`)
				output.push(`@deprecated`)
				output.push(`@desc`)
				output.push(`Draws corresponding image`)
				output.push(`\`r\` argument can be either Color or a number`)
				output.push(`or color arguments can be fully omitted`)
				output.push(`x, y positions can be omitted, this will cause icons to draw at last`)
				output.push(`position defined by !g:surface.SetTextPos`)
				output.push(`@enddesc`)

				reply.push(output)
			}
		}
	}

	return reply
]]

local function registerFonts()
	surface.CreateFont('WeaponIconsSmall', {
		font = 'HalfLife2',
		size = ScreenSize(24),
		weight = 500
	})

	surface.CreateFont('WeaponIconsVerySmall', {
		font = 'HalfLife2',
		size = ScreenSize(14),
		weight = 500
	})

	surface.CreateFont('WeaponIconsTiny', {
		font = 'HalfLife2',
		size = ScreenSize(8),
		weight = 500
	})

	surface.CreateFont('WeaponIconsBig', {
		font = 'HalfLife2',
		size = ScreenSize(43),
		weight = 500
	})
end

registerFonts()

hook.Add('ScreenResolutionChanged', 'DLib.hl2icons', registerFonts)

local sizes = {
	'',
	'Tiny',
	'Small',
	'VerySmall',
	'Big'
}

for char, names in pairs(stuff) do
	for i, name in ipairs(type(names) == 'table' and names or {names}) do
		for i, size in ipairs(sizes) do
			local fontName = 'WeaponIcons' .. size

			HUDCommons['Draw' .. name .. size] = function(x, y, color, g, b, a)
				surface.SetFont(fontName)

				if x and y then
					surface.SetTextPos(x, y)
				end

				if color then
					surface.SetTextColor(color, g, b, a)
				end

				surface.DrawText(char)
			end
		end
	end
end

do
	local funcs = {
		weapon_357 = '357Round',
		weapon_pistol = '9MM',
		weapon_smg1 = 'SMGRound',
		weapon_shotgun = 'Buckshot',
		weapon_rpg = 'RPGRound',
		weapon_ar2 = 'PulseRound',
		weapon_frag = 'GrenadeRound',
		weapon_crossbow = 'CrossbowBolt',
	}

	local funcsSecondary = {
		weapon_smg1 = 'SMGGrenade',
		weapon_ar2 = 'CombineBall',
	}

	for i, size in ipairs({'', 'Small', 'VerySmall', 'Tiny', 'Big'}) do
		local funcsMap = {}
		local funcsMap2 = {}

		for wep, func in pairs(funcs) do
			funcsMap[wep] = HUDCommons['Draw' .. func .. size]
		end

		for wep, func in pairs(funcsSecondary) do
			funcsMap2[wep] = HUDCommons['Draw' .. func .. size]
		end

		HUDCommons['GetWeaponAmmoIcon' .. size] = function(weaponIn)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			return funcsMap[classIn]
		end

		HUDCommons['DrawWeaponAmmoIcon' .. size] = function(weaponIn, ...)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			local val = funcsMap[classIn]
			if val then val(...) end
		end

		HUDCommons['GetWeaponSecondaryAmmoIcon' .. size] = function(weaponIn)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			return funcsMap2[classIn]
		end

		HUDCommons['DrawWeaponSecondaryAmmoIcon' .. size] = function(weaponIn, ...)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			local val = funcsMap2[classIn]
			if val then val(...) end
		end
	end
end

-- CShaderAPIDX8::BlitTextureBits: couldn't lock texture rect or use UpdateSurface
-- CShaderAPIDX8::BlitTextureBits: couldn't lock texture rect or use UpdateSurface
local WTFSIZE = 160

for i = 4, 400, 4 do
	surface.CreateFont('DLibDrawWeaponSelection' .. i, {
		font = 'HalfLife2',
		--size = i:min(128),
		size = i:min(WTFSIZE),
		weight = 500,
		additive = true
	})

	surface.CreateFont('DLibDrawAmmoIcon' .. i, {
		font = 'HalfLife2',
		--size = i:min(128),
		size = i:min(WTFSIZE),
		weight = 500
	})

	surface.CreateFont('DLibDrawWeaponSelectionSelected' .. i, {
		font = 'HalfLife2',
		--size = i:min(128),
		size = i:min(WTFSIZE),
		weight = 500,
		additive = true,
		scanlines = 2,
		blur = 5,
	})
end

-- 1 = AR2
-- 2 = AR2AltFire
-- 3 = Pistol
-- 4 = SMG1
-- 5 = 357
-- 6 = XBowBolt
-- 7 = Buckshot
-- 8 = RPG_Round
-- 9 = SMG1_Grenade
-- 10 = Grenade
-- 11 = slam
-- 12 = AlyxGun
-- 13 = SniperRound
-- 14 = SniperPenetratedRound
-- 15 = Thumper
-- 16 = Gravity
-- 17 = Battery
-- 18 = GaussEnergy
-- 19 = CombineCannon
-- 20 = AirboatGun
-- 21 = StriderMinigun
-- 22 = HelicopterGun
-- 23 = 9mmRound
-- 24 = 357Round
-- 25 = BuckshotHL1
-- 26 = XBowBoltHL1
-- 27 = MP5_Grenade
-- 28 = RPG_Rocket
-- 29 = Uranium
-- 30 = GrenadeHL1
-- 31 = Hornet
-- 32 = Snark
-- 33 = TripMine
-- 34 = Satchel
-- 35 = 12mmRound
-- 36 = StriderMinigunDirect
-- 37 = CombineHeavyCannon

local ammo_map_id = {}
local ammo_map_name = {}

local function refreshTypes()
	local i = 1
	local nextAmmoType
	local types = {}

	repeat
		nextAmmoType = game.GetAmmoName(i)

		if nextAmmoType then
			types[nextAmmoType:lower()] = i
		end

		i = i + 1
	until not nextAmmoType

	local function batbat(name, wepclass, isSecondary)
		-- SKREEEEEEEEEEEEEEEE
		if not types[name] then return end

		ammo_map_name[name] = types[name]
		ammo_map_id[types[name]] = {
			name = name,
			wepclass = wepclass,
			isSecondary = isSecondary
		}
	end

	batbat('ar2', 'weapon_ar2')
	batbat('ar2altfire', 'weapon_ar2', true)
	batbat('pistol', 'weapon_pistol')
	batbat('smg1', 'weapon_smg1')
	batbat('357', 'weapon_357')
	batbat('xbowbolt', 'weapon_crossbow')
	batbat('xbowbolthl1', 'weapon_crossbow_hl1')
	batbat('buckshot', 'weapon_shotgun')
	batbat('buckshothl1', 'weapon_shotgun_hl1')
	batbat('rpg_round', 'weapon_rpg')
	batbat('rpg_rocket', 'weapon_rpg_hl1')
	batbat('smg1_grenade', 'weapon_smg1', true)
	batbat('grenade', 'weapon_frag')
	batbat('slam', 'weapon_slam')
	batbat('alyxgun', 'weapon_alyxgun')
	batbat('9mmround', 'weapon_glock_hl1')
	batbat('357round', 'weapon_357_hl1')
	batbat('mp5_grenade', 'weapon_mp5_hl1', true)
	batbat('uranium', 'weapon_gauss')
	batbat('grenadehl1', 'weapon_handgrenade')
	batbat('hornet', 'weapon_hornetgun')
	batbat('snark', 'weapon_snark')
	batbat('tripmine', 'weapon_tripmine')
	batbat('satchel', 'weapon_satchel')

	-- batbat('sniperround', 'q')
	-- batbat('sniperpenetratedround', 'q')
end

if AreEntitiesAvailable() then
	refreshTypes()
else
	hook.Add('InitPostEntity', 'HUDCommons.AmmoIcons', refreshTypes)
end

local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

local function DrawSprite(drawdata, font, x, y, width, height, color, xalign, yalign)
	if not drawdata then return end

	xalign = xalign or TEXT_ALIGN_LEFT
	yalign = yalign or TEXT_ALIGN_TOP

	local text = drawdata.character

	local size = width:min(height)

	if not text then
		local w, h = drawdata.width or drawdata.material:Width(), drawdata.height or drawdata.material:Height()
		local w2, h2 = drawdata.material:Width(), drawdata.material:Height()
		surface.SetDrawColor(color)
		surface.SetMaterial(drawdata.material)

		local u1, v1, u2, v2 =
			(drawdata.x or 0) / drawdata.material:Width(),
			(drawdata.y or 0) / drawdata.material:Height(),
			((drawdata.x or 0) + (drawdata.width or 0)) / drawdata.material:Width(),
			((drawdata.y or 0) + (drawdata.height or 0)) / drawdata.material:Height()

		local nw, nh

		if w > h then
			nw, nh = size, size * (h / w)
		else
			nw, nh = size * (w / h), size
		end

		if xalign == TEXT_ALIGN_CENTER then
			x = x - nw / 2
		elseif xalign == TEXT_ALIGN_RIGHT then
			x = x - nw
		end

		if yalign == TEXT_ALIGN_CENTER then
			y = y - nh / 2
		elseif yalign == TEXT_ALIGN_BOTTOM then
			y = y - nh
		end

		surface.DrawTexturedRectUV(x, y, nw, nh, u1, v1, u2, v2)
		return
	end

	local recalc = false

	::RECALC::

	local selectFont = (size / 4):clamp(1, 100):ceil() * 4
	surface.SetFont(font .. selectFont)
	surface.SetTextColor(color)

	local w, h = surface.GetTextSize(text)
	local ratio = w / h

	if ratio < 0.9 and not recalc then
		size = width:max(height)
		recalc = true
		goto RECALC
	end

	if xalign == TEXT_ALIGN_CENTER then
		x = x - w / 2
	elseif xalign == TEXT_ALIGN_RIGHT then
		x = x - w
	end

	if yalign == TEXT_ALIGN_CENTER then
		y = y - h / 2
	elseif yalign == TEXT_ALIGN_BOTTOM then
		y = y - h
	end

	surface.SetTextPos(x, y)
	surface.DrawText(text)
end

--[[
	@doc
	@fname DLib.HUDCommons.DrawAmmoIcon
	@args number ammotype, number x, number y, number width, number height, Color alpha, number xalign, number yalign

	@client

	@desc
	Ammotype can be a string
	@enddesc
]]
function HUDCommons.DrawAmmoIcon(ammotype, x, y, width, height, color, xalign, yalign)
	local data = ammo_map_id[ammotype]

	if isstring(ammotype) then
		data = ammo_map_id[ammo_map_name[ammotype:lower()]]
	end

	if not data then return end
	local wepdata = DLib.Util.GetWeaponScript(data.wepclass)
	if not wepdata then return end
	if not wepdata.texturedata then return end

	return DrawSprite(
		data.isSecondary and wepdata.texturedata.ammo2 or wepdata.texturedata.ammo,
		'DLibDrawAmmoIcon',
		x, y, width, height, color, xalign, yalign)
end

--[[
	@doc
	@fname Weapon:DLibDrawWeaponSelection
	@args number x, number y, number width, number height, any alpha

	@client

	@desc
	Same as !g:Weapon:DrawWeaponSelection Except it support HL2 Sweps!
	Call this instead of `DrawWeaponSelection`
	This is perfect function for custom weapon selector
	Alpha can be either a number (0-255) or a color
	@enddesc
]]

--[[
	@doc
	@fname Weapon:DLibDrawWeaponSelectionSelected
	@args number x, number y, number width, number height, any alpha

	@client

	@desc
	`DLibDrawWeaponSelection` but with glowing icons for HL2 weapons
	@enddesc
]]

local wepMeta = FindMetaTable('Weapon')
local Matrix = Matrix
local cam = cam
local Vector = Vector

local mColor = Color(255, 176, 0)

local function InternalDrawIcon(self, x, y, width, height, alpha, selected, color, ...)
	assert(type(x) == 'number', 'x must be a number')
	assert(type(y) == 'number', 'y must be a number')
	assert(type(width) == 'number', 'width must be a number')
	assert(type(height) == 'number', 'height must be a number')
	-- assert(type(alpha) == 'number', 'alpha must be a number')

	local data = DLib.Util.GetWeaponScript(self)

	if not data or not data.texturedata or not data.texturedata.weapon then
		local fcall = self.DrawWeaponSelection
		if not fcall then return end
		return fcall(self, x, y, width, height, alpha or color and color.a or error('wtf?'), ...)
	end

	if data.texturedata.weapon_s and (not data.texturedata.weapon_s.character and not data.texturedata.weapon_s.material) then return end

	if hook.Run('DrawWeaponSelection', self, x, y, width, height, alpha) == false then return end

	hook.Run('PreDrawWeaponSelection', self, x, y, width, height, alpha)

	DrawSprite(
		selected and data.texturedata.weapon_s or data.texturedata.weapon,
		selected and 'DLibDrawWeaponSelectionSelected' or 'DLibDrawWeaponSelection',
		x + width / 2,
		y + height / 2,
		width,
		height,
		alpha and mColor:ModifyAlpha(alpha) or color or error('wtf?'),
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_CENTER)

	hook.Run('PostDrawWeaponSelection', self, x, y, width, height, alpha)
end

function wepMeta:DLibDrawWeaponSelection(x, y, width, height, color, ...)
	if type(color) == 'number' then
		InternalDrawIcon(self, x, y, width, height, color, false, nil, ...)
	else
		InternalDrawIcon(self, x, y, width, height, nil, false, color, ...)
	end
end

function wepMeta:DLibDrawWeaponSelectionSelected(x, y, width, height, color, ...)
	if type(color) == 'number' then
		InternalDrawIcon(self, x, y, width, height, color, true, nil, ...)
	else
		InternalDrawIcon(self, x, y, width, height, nil, true, color, ...)
	end
end

--[[
	@doc
	@fname Weapon:DrawPrimaryAmmoIcon
	@args number x, number y, number width, number height, Color alpha, number xalign, number yalign

	@client
]]
function wepMeta:DrawPrimaryAmmoIcon(x, y, width, height, color, xalign, yalign)
	local ammotype = self:GetPrimaryAmmoType()
	if not ammotype or ammotype == -1 then return end

	return HUDCommons.DrawAmmoIcon(ammotype, x, y, width, height, color, xalign, yalign)
end

--[[
	@doc
	@fname Weapon:DrawSecondaryAmmoIcon
	@args number x, number y, number width, number height, Color alpha, number xalign, number yalign

	@client
]]
function wepMeta:DrawSecondaryAmmoIcon(x, y, width, height, color, xalign, yalign)
	local ammotype = self:GetSecondaryAmmoType()
	if not ammotype or ammotype == -1 then return end

	return HUDCommons.DrawAmmoIcon(ammotype, x, y, width, height, color, xalign, yalign)
end
