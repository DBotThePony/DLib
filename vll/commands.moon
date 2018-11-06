
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

import concommand, table, string, VLL2 from _G

if SERVER
	util.AddNetworkString('vll2_cmd_load_server')

autocomplete = {}

if CLIENT
	timer.Simple 0, -> http.Fetch 'https://dbotthepony.ru/vll/plist.php', (body = '', size = string.len(body), headers = {}, code = 400) ->
		return if code ~= 200
		autocomplete = [_file\Trim()\lower() for _file in *string.Explode('\n', body) when _file\Trim() ~= '']
		table.sort(autocomplete)

vll2_load = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if SERVER and not game.SinglePlayer() and IsValid(ply) and not ply\IsSuperAdmin()
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No bundle were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	fbandle = VLL2.URLBundle(bundle\lower())
	fbandle\Load()
	fbandle\Replicate()
	VLL2.MessagePlayer(ply, 'Loading URL Bundle: ' .. bundle)

vll2_autocomplete = (cmd, args) ->
	return if not args
	args = args\Trim()\lower()
	return ['vll2_load ' .. _file for _file in *autocomplete] if args == ''
	result = ['vll2_load ' .. _file for _file in *autocomplete when _file\StartWith(args)]
	return result

vll2_autocomplete2 = (cmd, args) ->
	return if not args
	args = args\Trim()\lower()
	return ['vll2_load_server ' .. _file for _file in *autocomplete] if args == ''
	result = ['vll2_load_server ' .. _file for _file in *autocomplete when _file\StartWith(args)]
	return result

vll2_workshop = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if SERVER and not game.SinglePlayer() and IsValid(ply) and not ply\IsSuperAdmin()
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No workshop ID were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	return VLL2.MessagePlayer(ply, 'Invalid ID provided. it must be an integer') if not tonumber(bundle)
	fbandle = VLL2.WSBundle(tostring(math.floor(tonumber(bundle)))\lower())
	fbandle\Load()
	fbandle\Replicate()
	VLL2.MessagePlayer(ply, 'Loading Workshop Bundle: ' .. bundle)

vll2_load_silent = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if SERVER and not game.SinglePlayer() and IsValid(ply) and not ply\IsSuperAdmin()
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No bundle were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	fbandle = VLL2.URLBundle(bundle\lower())
	fbandle\Load()
	fbandle\DoNotReplicate()
	VLL2.MessagePlayer(ply, 'Loading URL Bundle: ' .. bundle)

vll2_reload = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if SERVER and not game.SinglePlayer() and IsValid(ply) and not ply\IsSuperAdmin()
	VLL2.MessagePlayer(ply, 'Reloading VLL2, this can take some time...')
	http.Fetch "https://dbotthepony.ru/vll/vll2.lua", (b) -> RunString(b, "VLL2")

concommand.Add 'vll2_load', vll2_load, vll2_autocomplete
concommand.Add 'vll2_workshop', vll2_workshop
concommand.Add 'vll2_reload', vll2_reload

if SERVER
	net.Receive 'vll2_cmd_load_server', (_, ply) -> vll2_load(ply, nil, string.Explode(' ', net.ReadString()\Trim()))
	concommand.Add 'vll2_load_server', vll2_load
	concommand.Add 'vll2_load_silent', vll2_load_silent
	concommand.Add 'vll2_workshop_server', vll2_workshop
	concommand.Add 'vll2_reload_server', vll2_reload
else
	vll2_load_server = (ply, cmd, args) ->
		net.Start('vll2_cmd_load_server')
		net.WriteString(args[1])
		net.SendToServer()

	timer.Simple 0, ->
		timer.Simple 0, ->
			if not game.SinglePlayer()
				concommand.Add 'vll2_load_server', vll2_load_server, vll2_autocomplete2