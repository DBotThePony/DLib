
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

sv_allowcslua = GetConVar('sv_allowcslua')

disallow = => SERVER and not game.SinglePlayer() and IsValid(@) and not @IsSuperAdmin() or CLIENT and not @IsSuperAdmin() and not sv_allowcslua\GetBool()
disallow2 = => SERVER and not game.SinglePlayer() and IsValid(@) and not @IsSuperAdmin()

if SERVER
	util.AddNetworkString('vll2_cmd_load_server')

autocomplete = {}

timer.Simple 0, -> http.Fetch 'https://dbotthepony.ru/vll/plist.php', (body = '', size = string.len(body), headers = {}, code = 400) ->
	return if code ~= 200
	autocomplete = [_file\Trim()\lower() for _file in *string.Explode('\n', body) when _file\Trim() ~= '']
	table.sort(autocomplete)

vll2_load = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No bundle were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	fbundle = VLL2.URLBundle(bundle\lower())
	fbundle\Load()
	fbundle\Replicate()
	VLL2.MessagePlayer(ply, 'Loading URL Bundle: ' .. bundle)

vll2_mkautocomplete = (commandToReg) ->
	return (cmd, args) ->
		return if not args
		args = args\Trim()\lower()
		return [commandToReg .. ' ' .. _file for _file in *autocomplete] if args == ''
		result = [commandToReg .. ' ' .. _file for _file in *autocomplete when _file\StartWith(args)]
		return result

vll2_workshop = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No workshop ID were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	return VLL2.MessagePlayer(ply, 'Invalid ID provided. it must be an integer') if not tonumber(bundle)
	fbundle = VLL2.WSBundle(tostring(math.floor(tonumber(bundle)))\lower())
	fbundle\Load()
	fbundle\Replicate()
	VLL2.MessagePlayer(ply, 'Loading Workshop Bundle: ' .. bundle)

vll2_wscollection = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No workshop ID of collection were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	return VLL2.MessagePlayer(ply, 'Invalid ID provided. it must be an integer') if not tonumber(bundle)
	fbundle = VLL2.WSCollection(tostring(math.floor(tonumber(bundle)))\lower())
	fbundle\Load()
	fbundle\Replicate()
	VLL2.MessagePlayer(ply, 'Loading Workshop collection Bundle: ' .. bundle .. '. Hold on tigh!')

vll2_wscollection_content = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow2(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No workshop ID of collection were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	return VLL2.MessagePlayer(ply, 'Invalid ID provided. it must be an integer') if not tonumber(bundle)
	fbundle = VLL2.WSCollection(tostring(math.floor(tonumber(bundle)))\lower())
	fbundle\DoNotLoadLua()
	fbundle\Load()
	fbundle\Replicate()
	VLL2.MessagePlayer(ply, 'Loading Workshop collection Bundle: ' .. bundle .. ' without mounting Lua. Hold on tigh!')

vll2_workshop_silent = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No workshop ID were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	return VLL2.MessagePlayer(ply, 'Invalid ID provided. it must be an integer') if not tonumber(bundle)
	fbundle = VLL2.WSBundle(tostring(math.floor(tonumber(bundle)))\lower())
	fbundle\Load()
	fbundle\DoNotReplicate()
	VLL2.MessagePlayer(ply, 'Loading Workshop Bundle: ' .. bundle)

vll2_workshop_content = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow2(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No workshop ID were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	return VLL2.MessagePlayer(ply, 'Invalid ID provided. it must be an integer') if not tonumber(bundle)
	fbundle = VLL2.WSBundle(tostring(math.floor(tonumber(bundle)))\lower())
	fbundle\DoNotLoadLua()
	fbundle\Load()
	fbundle\Replicate()
	VLL2.MessagePlayer(ply, 'Loading Workshop Bundle: ' .. bundle .. ' without mounting Lua')

vll2_workshop_content_silent = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow2(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No workshop ID were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	return VLL2.MessagePlayer(ply, 'Invalid ID provided. it must be an integer') if not tonumber(bundle)
	fbundle = VLL2.WSBundle(tostring(math.floor(tonumber(bundle)))\lower())
	fbundle\DoNotLoadLua()
	fbundle\Load()
	fbundle\DoNotReplicate()
	VLL2.MessagePlayer(ply, 'Loading Workshop Bundle: ' .. bundle .. ' without mounting Lua')

vll2_load_silent = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	bundle = args[1]
	return VLL2.MessagePlayer(ply, 'No bundle were specified.') if not bundle
	return VLL2.MessagePlayer(ply, 'Bundle is already loading!') if not VLL2.AbstractBundle\Checkup(bundle\lower())
	fbundle = VLL2.URLBundle(bundle\lower())
	fbundle\Load()
	fbundle\DoNotReplicate()
	VLL2.MessagePlayer(ply, 'Loading URL Bundle: ' .. bundle)

vll2_reload = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	VLL2.MessagePlayer(ply, 'Reloading VLL2, this can take some time...')
	_G.VLL2_GOING_TO_RELOAD = true
	http.Fetch "https://dbotthepony.ru/vll/vll2.lua", (b) -> _G.RunString(b, "VLL2")

vll2_reload_full = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	VLL2.MessagePlayer(ply, 'Flly Reloading VLL2, this can take some time...')
	_G.VLL2_GOING_TO_RELOAD = true
	_G.VLL2_FULL_RELOAD = true
	http.Fetch "https://dbotthepony.ru/vll/vll2.lua", (b) -> _G.RunString(b, "VLL2")

vll2_clear_lua_cache = (ply, cmd, args) ->
	return VLL2.MessagePlayer(ply, 'Not a super admin!') if disallow(ply)
	sql.Query('DELETE FROM vll2_lua_cache')
	VLL2.MessagePlayer(ply, 'Lua cache has been cleared.')

timer.Simple 0, ->
	if not game.SinglePlayer() or CLIENT
		concommand.Add 'vll2_load', vll2_load, vll2_mkautocomplete('vll2_load')
		concommand.Add 'vll2_workshop', vll2_workshop
		concommand.Add 'vll2_wscollection', vll2_wscollection
		concommand.Add 'vll2_wscollection_content', vll2_wscollection_content
		concommand.Add 'vll2_workshop_silent', vll2_workshop_silent
		concommand.Add 'vll2_workshop_content_silent', vll2_workshop_content_silent
		concommand.Add 'vll2_reload', vll2_reload
		concommand.Add 'vll2_reload_full', vll2_reload_full
		concommand.Add 'vll2_clear_lua_cache', vll2_clear_lua_cache

	if SERVER
		net.Receive 'vll2_cmd_load_server', (_, ply) -> vll2_load(ply, nil, string.Explode(' ', net.ReadString()\Trim()))
		concommand.Add 'vll2_load_server', vll2_load, vll2_mkautocomplete('vll2_load_server')
		concommand.Add 'vll2_load_silent', vll2_load_silent, vll2_mkautocomplete('vll2_load_silent')
		concommand.Add 'vll2_workshop_server', vll2_workshop
		concommand.Add 'vll2_wscollection_server', vll2_wscollection
		concommand.Add 'vll2_wscollection_content_server', vll2_wscollection_content
		concommand.Add 'vll2_workshop_content_server', vll2_workshop_content
		concommand.Add 'vll2_workshop_silent_server', vll2_workshop_silent
		concommand.Add 'vll2_workshop_content_silent_server', vll2_workshop_content_silent
		concommand.Add 'vll2_reload_server', vll2_reload
		concommand.Add 'vll2_reload_full_server', vll2_reload_full
		concommand.Add 'vll2_clear_lua_cache_server', vll2_clear_lua_cache
	else
		vll2_load_server = (ply, cmd, args) ->
			net.Start('vll2_cmd_load_server')
			net.WriteString(args[1])
			net.SendToServer()

		timer.Simple 0, ->
			timer.Simple 0, ->
				if not game.SinglePlayer()
					concommand.Add 'vll2_load_server', vll2_load_server, vll2_mkautocomplete('vll2_load_server')