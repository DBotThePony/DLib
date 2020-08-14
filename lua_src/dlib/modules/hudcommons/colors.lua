
--
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


local HUDCommons = DLib.HUDCommons
local setmetatable = setmetatable
local Color = Color
local CreateConVar = CreateConVar
local FCVAR_ARCHIVE = FCVAR_ARCHIVE
local type = type
local cvars = cvars
local tostring = tostring

HUDCommons.Colors = HUDCommons.Colors or {}
HUDCommons.ColorsN = HUDCommons.ColorsN or {}
HUDCommons.ColorsVars = HUDCommons.ColorsVars or {}
HUDCommons.ColorsVars_Proxies = HUDCommons.ColorsVars_Proxies or {}
HUDCommons.ColorsVarsN = HUDCommons.ColorsVarsN or {}
HUDCommons.ColorsVarsN_Proxies = HUDCommons.ColorsVarsN_Proxies or {}

--[[
	@doc
	@fname DLib.HUDCommons.CreateColor
	@args string classname, string name, number r, number g, number b, number a

	@client

	@desc
	Allows you to define user-configured colors
	classname should be something unique that is short and predictable,
	like `ffgs_hud_ammobg`
	and `name` should be something that user will recognize easily
	like `FFGS HUD Ammo Counter background`
	i18n support is planned
	@enddesc

	@returns
	function: returns color. DO NOT MODIFY IT! (e.g. change alpha). Use cloning methods as described on !c:Color
]]
function HUDCommons.CreateColor(class, name, r, g, b, a)
	if type(r) == 'table' then
		g = r.g
		b = r.b
		a = r.a
		r = r.r
	end

	local help_r = 'Changes Red Channel of ' .. name .. ' HUDCommons element'
	local help_g = 'Changes Green Channel of ' .. name .. ' HUDCommons element'
	local help_b = 'Changes Blue Channel of ' .. name .. ' HUDCommons element'
	local help_a = 'Changes Alpha Channel of ' .. name .. ' HUDCommons element'

	r = (r or 255):clamp(0, 255):floor()
	g = (g or 255):clamp(0, 255):floor()
	b = (b or 255):clamp(0, 255):floor()
	a = (a or 255):clamp(0, 255):floor()

	local rn = 'h_color_' .. class .. '_r'
	local gn = 'h_color_' .. class .. '_g'
	local bn = 'h_color_' .. class .. '_b'
	local an = 'h_color_' .. class .. '_a'

	HUDCommons.ColorsVars[class] = {
		name = name,
		rdef = r,
		bdef = b,
		gdef = g,
		adef = a,
		r = CreateConVar(rn, tostring(r), {FCVAR_ARCHIVE}, help_r),
		g = CreateConVar(gn, tostring(g), {FCVAR_ARCHIVE}, help_g),
		b = CreateConVar(bn, tostring(b), {FCVAR_ARCHIVE}, help_b),
		a = CreateConVar(an, tostring(a), {FCVAR_ARCHIVE}, help_a),
	}

	local t = HUDCommons.ColorsVars[class]
	local currentColor

	local function colorUpdated()
		local old = HUDCommons.Colors[class]
		HUDCommons.Colors[class] = Color(t.r:GetInt() or r, t.g:GetInt() or g, t.b:GetInt() or b, t.a:GetInt() or a)
		currentColor = HUDCommons.Colors[class]

		if HUDCommons.ColorsVars_Proxies[class] then
			local target = HUDCommons.ColorsVars_Proxies[class]
			target.r = currentColor.r
			target.g = currentColor.g
			target.b = currentColor.b
			target.a = currentColor.a
		end

		hook.Run('HUDCommons_ColorUpdates', class, old, Color(HUDCommons.Colors[class]))
	end

	colorUpdated()

	cvars.AddChangeCallback(rn, colorUpdated, 'HUDCommons.Colors')
	cvars.AddChangeCallback(gn, colorUpdated, 'HUDCommons.Colors')
	cvars.AddChangeCallback(bn, colorUpdated, 'HUDCommons.Colors')
	cvars.AddChangeCallback(an, colorUpdated, 'HUDCommons.Colors')

	return function()
		return currentColor
	end
end

--[[
	@doc
	@fname DLib.HUDCommons.CreateColorN
	@args string classname, string name, number r, number g, number b, number a

	@client

	@desc
	same as `DLib.HUDCommons.CreateColor` but disallows user to edit alpha channel
	@enddesc

	@returns
	function: returns color. Passing a number as first argument will modify the alpha of color and still return the color.
]]
function HUDCommons.CreateColorN(class, name, r, g, b, a)
	if type(r) == 'table' then
		g = r.g
		b = r.b
		a = r.a
		r = r.r
	end

	local help_r = 'Changes Red Channel of ' .. name .. ' HUDCommons element'
	local help_g = 'Changes Green Channel of ' .. name .. ' HUDCommons element'
	local help_b = 'Changes Blue Channel of ' .. name .. ' HUDCommons element'

	r = (r or 255):clamp(0, 255):floor()
	g = (g or 255):clamp(0, 255):floor()
	b = (b or 255):clamp(0, 255):floor()
	a = (a or 255):clamp(0, 255):floor()

	local rn = class .. '_r'
	local gn =  class .. '_g'
	local bn = class .. '_b'

	HUDCommons.ColorsVarsN[class] = {
		name = name,
		rdef = r,
		bdef = b,
		gdef = g,
		r = CreateConVar(rn, tostring(r), {FCVAR_ARCHIVE}, help_r),
		g = CreateConVar(gn, tostring(g), {FCVAR_ARCHIVE}, help_g),
		b = CreateConVar(bn, tostring(b), {FCVAR_ARCHIVE}, help_b),
	}

	local t = HUDCommons.ColorsVarsN[class]
	local currentColor

	local function colorUpdated()
		local color = Color(t.r:GetInt() or r, t.g:GetInt() or g, t.b:GetInt() or b, a)

		if HUDCommons.ColorsN[class] then
			color:SetAlpha(HUDCommons.ColorsN[class]:GetAlpha())
		end

		if HUDCommons.ColorsVarsN_Proxies[class] then
			local target = HUDCommons.ColorsVarsN_Proxies[class]
			target.r = color.r
			target.g = color.g
			target.b = color.b
			target.a = color.a
		end

		HUDCommons.ColorsN[class] = color
		local old = currentColor or color
		currentColor = color

		hook.Run('HUDCommons_ColorUpdates', class, old, Color(color))
	end

	colorUpdated()

	cvars.AddChangeCallback(rn, colorUpdated, 'HUDCommons.Colors')
	cvars.AddChangeCallback(gn, colorUpdated, 'HUDCommons.Colors')
	cvars.AddChangeCallback(bn, colorUpdated, 'HUDCommons.Colors')

	return function(alpha)
		if alpha ~= nil then
			currentColor:SetAlpha(alpha)
		end

		return currentColor
	end
end

--[[
	@doc
	@fname DLib.HUDCommons.CreateColorN2
	@args string classname, string name, number r, number g, number b, number a

	@client

	@desc
	same as `DLib.HUDCommons.CreateColorN` but returns color which is always valid
	@enddesc

	@returns
	Color: this color is being updated by the base internally, so you don't have to call function. You *are* allowed to edit alpha channel of this color.
]]
function HUDCommons.CreateColorN2(class, ...)
	local colorProxy = Color()
	local color = HUDCommons.CreateColorN(class, ...)
	HUDCommons.ColorsVarsN_Proxies[class] = colorProxy
	color = color()
	colorProxy.r = color.r
	colorProxy.g = color.g
	colorProxy.b = color.b
	colorProxy.a = color.a
	return colorProxy
end

--[[
	@doc
	@fname DLib.HUDCommons.CreateColor2
	@args string classname, string name, number r, number g, number b, number a

	@client

	@desc
	same as `DLib.HUDCommons.CreateColor` but returns color which is always valid
	@enddesc

	@returns
	Color: this color is being updated by the base internally, so you don't have to call function. You *are not* allowed to edit alpha channel of this color.
]]
function HUDCommons.CreateColor2(class, ...)
	local colorProxy = Color()
	local color = HUDCommons.CreateColor(class, ...)
	HUDCommons.ColorsVars_Proxies[class] = colorProxy
	color = color()
	colorProxy.r = color.r
	colorProxy.g = color.g
	colorProxy.b = color.b
	colorProxy.a = color.a
	return colorProxy
end

function HUDCommons.GetColor(class)
	return HUDCommons.Colors[class]
end

function HUDCommons.GetColorN(class)
	return HUDCommons.ColorsN[class]
end
