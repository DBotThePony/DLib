
-- Copyright (C) 2017-2019 DBotThePony

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

local HUDCommons = HUDCommons
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
		output.push(`@args Weapon weapon`)
		output.push(`@returns`)
		output.push(`function: or nil`)

		output = []

		output.push(`@func DLib.HUDCommons.GetWeaponSecondaryAmmoIcon${size}`)
		output.push(`@client`)
		output.push(`@args Weapon weapon`)
		output.push(`@returns`)
		output.push(`function: or nil`)

		reply.push(output)
		output = []

		output.push(`@func DLib.HUDCommons.DrawWeaponAmmoIcon${size}`)
		output.push(`@client`)
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

--[[
	@doc
	@fname Weapon:DLibDrawWeaponSelection
	@args number x, number y, number width, number height, number alpha

	@client

	@desc
	Same as !g:Weapon:DrawWeaponSelection Except it support HL2 Sweps!
	Call this instead of `DrawWeaponSelection`
	This is perfect function for custom weapon selector
	@enddesc
]]

--[[
	@doc
	@fname Weapon:DLibDrawWeaponSelectionSelected
	@args number x, number y, number width, number height, number alpha

	@client

	@desc
	`DLibDrawWeaponSelection` but with glowing icons for HL2 weapons
	@enddesc
]]
do
	local wepMeta = FindMetaTable('Weapon')
	local Matrix = Matrix
	local cam = cam
	local surface = surface
	local Vector = Vector

	local mColor = Color(255, 176, 0)

	for i = 4, 400, 4 do
		surface.CreateFont('DLibDrawWeaponSelection' .. i, {
			font = 'HalfLife2',
			size = i,
			weight = 500,
			additive = true
		})

		surface.CreateFont('DLibDrawWeaponSelectionSelected' .. i, {
			font = 'HalfLife2',
			size = i,
			weight = 500,
			additive = true,
			scanlines = 2,
			blur = 5,
		})
	end

	local function InternalDrawIcon(self, x, y, width, height, alpha, data, selected)
		--[[local matrix = Matrix()
		matrix:Translate(Vector(x, y))
		matrix:Scale(Vector(width / 160, height / 80))]]

		--surface.SetFont(selected and 'DLibDrawWeaponSelectionSelected' or 'DLibDrawWeaponSelection')
		local text

		if data.texturedata.weapon_s then
			text = selected and data.texturedata.weapon_s.character or data.texturedata.weapon.character
		else
			text = data.texturedata.weapon.character
		end

		if not text then
			local data2

			if data.texturedata.weapon_s then
				data2 = selected and data.texturedata.weapon_s or data.texturedata.weapon
			else
				data2 = data.texturedata.weapon
			end

			local w, h = data2.width or data2.material:Width(), data2.height or data2.material:Height()
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.SetMaterial(data2.material)
			local w2, h2 = data2.material:Width(), data2.material:Height()

			local u1, v1, u2, v2 =
				(data2.x or 0) / data2.material:Width(),
				(data2.y or 0) / data2.material:Height(),
				((data2.x or 0) + (data2.width or 0)) / data2.material:Width(),
				((data2.y or 0) + (data2.height or 0)) / data2.material:Height()

			local size = width:max(height)

			if w > h then
				local nw, nh = size, size * (h / w)
				surface.DrawTexturedRectUV(x + width / 2 - nw / 2, y + height / 2 - nh / 2, nw, nh, u1, v1, u2, v2)
			else
				local nw, nh = size * (w / h), size
				surface.DrawTexturedRectUV(x + width / 2 - nw / 2, y + height / 2 - nh / 2, nw, nh, u1, v1, u2, v2)
			end

			return
		end

		local size = width:min(height)
		local selectFont = (size / 4):clamp(1, 100):ceil() * 4
		surface.SetFont(selected and ('DLibDrawWeaponSelectionSelected' .. selectFont) or ('DLibDrawWeaponSelection' .. selectFont))
		surface.SetTextColor(mColor:ModifyAlpha(alpha))

		local w, h = surface.GetTextSize(text)
		x = x + width / 2 - w / 2
		y = y + height / 2 - h / 2

		surface.SetTextPos(x, y)

		--cam.PushModelMatrix(matrix)

		surface.DrawText(text)

		--cam.PopModelMatrix()
	end

	function wepMeta:DLibDrawWeaponSelection(x, y, width, height, alpha, ...)
		assert(type(x) == 'number', 'x must be a number')
		assert(type(y) == 'number', 'y must be a number')
		assert(type(width) == 'number', 'width must be a number')
		assert(type(height) == 'number', 'height must be a number')
		assert(type(alpha) == 'number', 'alpha must be a number')

		local data = DLib.util.GetWeaponScript(self)

		if not data or not data.texturedata or not data.texturedata.weapon then
			local fcall = self.DrawWeaponSelection
			if not fcall then return end
			return fcall(self, x, y, width, height, alpha, ...)
		end

		if not data.texturedata.weapon.character and not data.texturedata.weapon.material then return end

		if hook.Run('DrawWeaponSelection', self, x, y, width, height, alpha) == false then return end

		hook.Run('PreDrawWeaponSelection', self, x, y, width, height, alpha)
		InternalDrawIcon(self, x, y, width, height, alpha, data, false)
		hook.Run('PostDrawWeaponSelection', self, x, y, width, height, alpha)
	end

	function wepMeta:DLibDrawWeaponSelectionSelected(x, y, width, height, alpha, ...)
		assert(type(x) == 'number', 'x must be a number')
		assert(type(y) == 'number', 'y must be a number')
		assert(type(width) == 'number', 'width must be a number')
		assert(type(height) == 'number', 'height must be a number')
		assert(type(alpha) == 'number', 'alpha must be a number')

		local data = DLib.util.GetWeaponScript(self)

		if not data or not data.texturedata or not data.texturedata.weapon then
			local fcall = self.DrawWeaponSelection
			if not fcall then return end
			return fcall(self, x, y, width, height, alpha, ...)
		end

		if data.texturedata.weapon_s and (not data.texturedata.weapon_s.character and not data.texturedata.weapon_s.material) then return end

		if hook.Run('DrawWeaponSelection', self, x, y, width, height, alpha) == false then return end

		hook.Run('PreDrawWeaponSelection', self, x, y, width, height, alpha)
		InternalDrawIcon(self, x, y, width, height, alpha, data, true)
		hook.Run('PostDrawWeaponSelection', self, x, y, width, height, alpha)
	end
end
