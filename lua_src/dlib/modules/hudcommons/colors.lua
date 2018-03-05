
--
-- Copyright (C) 2017-2018 DBot
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

local HUDCommons = HUDCommons
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
HUDCommons.ColorsVarsN = HUDCommons.ColorsVarsN or {}
HUDCommons.ColorsVarsN_Proxies = HUDCommons.ColorsVarsN_Proxies or {}

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
		HUDCommons.Colors[class] = Color(t.r:GetInt() or r, t.g:GetInt() or g, t.b:GetInt() or b, t.a:GetInt() or a)
		currentColor = HUDCommons.Colors[class]
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
		currentColor = color
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

function HUDCommons.GetColor(class)
	return HUDCommons.Colors[class]
end

function HUDCommons.GetColorN(class)
	return HUDCommons.ColorsN[class]
end
