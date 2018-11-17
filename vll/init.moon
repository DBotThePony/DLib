
-- Copyright (C) 2018 DBot

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

if VLL2
	pcall () -> VLL2.Message('VLL2 was reloaded')

export VLL2
VLL2 = {}
VLL2.IS_WEB_LOADED = debug.getinfo(1).short_src == 'VLL2'

import SERVER, CLIENT, string, game, GetHostName, table, util, MsgC, Color from _G

PREFIX_COLOR = Color(0, 200, 0)
DEFAULT_TEXT_COLOR = Color(200, 200, 200)
BOOLEAN_COLOR = Color(33, 83, 226)
NUMBER_COLOR = Color(245, 199, 64)
STEAMID_COLOR = Color(255, 255, 255)
ENTITY_COLOR = Color(180, 232, 180)
FUNCTION_COLOR = Color(62, 106, 255)
TABLE_COLOR = Color(107, 200, 224)
URL_COLOR = Color(174, 124, 192)

WriteArray = (arr) ->
	net.WriteUInt(#arr, 16)
	net.WriteType(val) for val in *arr

ReadArray = -> [net.ReadType() for i = 1, net.ReadUInt(16)]

if SERVER
	util.AddNetworkString('vll2.message')
else
	net.Receive 'vll2.message', -> VLL2.Message(unpack(ReadArray()))

VLL2.Referer = -> (SERVER and '(SERVER) ' or '(CLIENT) ') .. string.Explode(':', game.GetIPAddress())[1] .. '/' .. GetHostName()

VLL2.FormatMessageInternal = (tabIn) ->
	prevColor = DEFAULT_TEXT_COLOR
	output = {prevColor}

	for _, val in ipairs(tabIn)
		valType = type(val)

		if valType == 'number'
			table.insert(output, NUMBER_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'string'
			if val\find('^https?://')
				table.insert(output, URL_COLOR)
				table.insert(output, val)
				table.insert(output, prevColor)
			else
				table.insert(output, val)
		elseif valType == 'Player'
			if team
				table.insert(output, team.GetColor(val\Team()) or ENTITY_COLOR)
			else
				table.insert(output, ENTITY_COLOR)

			table.insert(output, val\Nick())

			if val.SteamName and val\SteamName() ~= val\Nick()
				table.insert(output, ' (' .. val\SteamName() .. ')')

			table.insert(output, STEAMID_COLOR)
			table.insert(output, '<')
			table.insert(output, val\SteamID())
			table.insert(output, '>')
			table.insert(output, prevColor)
		elseif valType == 'Entity' or valType == 'NPC' or valType == 'Vehicle'
			table.insert(output, ENTITY_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'table'
			if val.r and val.g and val.b
				table.insert(output, val)
				prevColor = val
			else
				table.insert(output, TABLE_COLOR)
				table.insert(output, tostring(val))
				table.insert(output, prevColor)
		elseif valType == 'function'
			table.insert(output, FUNCTION_COLOR)
			table.insert(output, string.format('function - %p', val))
			table.insert(output, prevColor)
		elseif valType == 'boolean'
			table.insert(output, BOOLEAN_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		else
			table.insert(output, tostring(val))

	return output

genPrefix = ->
	if game.SinglePlayer()
		return SERVER and '[SV] ' or '[CL] '
	elseif game.IsDedicated()
		return ''

	return '' if CLIENT
	return '[SV] ' if SERVER and game.GetIPAddress() == '0.0.0.0'
	return ''

VLL2.Message = (...) ->
	formatted = VLL2.FormatMessageInternal({...})
	MsgC(PREFIX_COLOR, genPrefix() .. '[VLL2] ', unpack(formatted))
	MsgC('\n')
	return formatted

VLL2.MessageVM = (...) ->
	formatted = VLL2.FormatMessageInternal({...})
	MsgC(PREFIX_COLOR, genPrefix() .. '[VLL2:VM] ', unpack(formatted))
	MsgC('\n')
	return formatted

VLL2.MessageFS = (...) ->
	formatted = VLL2.FormatMessageInternal({...})
	MsgC(PREFIX_COLOR, genPrefix() .. '[VLL2:FS] ', unpack(formatted))
	MsgC('\n')
	return formatted

VLL2.MessageDL = (...) ->
	formatted = VLL2.FormatMessageInternal({...})
	MsgC(PREFIX_COLOR, genPrefix() .. '[VLL2:DL] ', unpack(formatted))
	MsgC('\n')
	return formatted

VLL2.MessageBundle = (...) ->
	formatted = VLL2.FormatMessageInternal({...})
	MsgC(PREFIX_COLOR, genPrefix() .. '[VLL2:BNDL] ', unpack(formatted))
	MsgC('\n')
	return formatted

VLL2.MessagePlayer = (ply, ...) ->
	if CLIENT or ply == NULL or ply == nil
		VLL2.Message(...)
		return
	net.Start('vll2.message')
	WriteArray({...})
	net.Send(ply)

if SERVER
	if VLL2.IS_WEB_LOADED
		hook.Add 'PlayerInitialSpawn', 'VLL2.LoadOnClient', (ply) ->
			timer.Simple 10, () ->
				ply\SendLua([[if VLL2 then return end http.Fetch('https://dbotthepony.ru/vll/vll2.lua',function(b)RunString(b,'VLL2')end)]]) if IsValid(ply)

		if not VLL2_GOING_TO_RELOAD
			ply\SendLua([[if VLL2 then return end http.Fetch('https://dbotthepony.ru/vll/vll2.lua',function(b)RunString(b,'VLL2')end)]]) for ply in *player.GetAll()
		else
			ply\SendLua([[http.Fetch('https://dbotthepony.ru/vll/vll2.lua',function(b)RunString(b,'VLL2')end)]]) for ply in *player.GetAll()
			VLL2_GOING_TO_RELOAD = false
	else
		AddCSLuaFile()
		hook.Remove 'PlayerInitialSpawn', 'VLL2.LoadOnClient'
