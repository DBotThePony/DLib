
-- Copyright (C) 2017-2019 DBot

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


messaging = {}
DLib.MessageMaker(messaging, 'DLib/Message')

class DLib.Convars
	new: (namespace) =>
		error('No namespace!') if not namespace
		@namespace = namespace
		@convars = {}
		@help = {}
		@defaults = {}
		@setname = @namespace .. '_set'
		@cami = false
		-- lets trust gmod networking for now
		-- @networkname = 'DLib.Convars.' .. namespace
		-- net.pool(@networkname) if SERVER

		if SERVER
			concommand.Add @setname, (ply, cmd, args) ->
				name = args[1] or ''
				name = name\Trim()
				return messaging.MessagePlayer(ply, 'No access!') if IsValid(ply) and not ply\IsSuperAdmin()
				return messaging.MessagePlayer(ply, 'Invalid Console Variable - sv_' .. @namespace .. '_' .. name) if not @convars[name]
				return messaging.MessagePlayer(ply, 'Value is missing') if not args[2]
				table.remove(args, 1)
				newval = table.concat(args, ' ')
				@set(name, newval)
				messaging.Message(ply, ' has changed sv_' .. @namespace .. '_' .. name .. ' to ', newval)

	create: (name, defvalue = '0', flags = 0, desc = '') =>
		error('_set is reserved') if name == 'set'
		flags = DLib.util.composeEnums(flags, FCVAR_ARCHIVE, FCVAR_REPLICATED)
		@convars[name] = CreateConVar('sv_' .. @namespace .. '_' .. name, defvalue, flags, desc)
		@help[name] = desc
		@defaults[name] = defvalue
		return @convars[name]

	set: (name, ...) =>
		return false if not @convars[name]

		if CLIENT
			RunConsoleCommand(@setname, name, ...)
		else
			RunConsoleCommand('sv_' .. @namespace .. '_' .. name, ...)

		return true

	get: (name) => @convars[name]

	clickfunc: (name) =>
		return (pnl, newVal) ->
			if type(newVal) == 'boolean'
				@set(name, newVal and '1' or '0')
			else
				@set(name, newVal)

	checkbox: (pnlTarget, name) =>
		with pnlTarget\CheckBox(@help[name], 'sv_' .. @namespace .. '_' .. name)
			cvar = @convars[name]
			.Button.Think = -> \SetChecked(@getBool(name))
			.Button.DoClick = ->
				@set(name, not cvar\GetBool() and '1' or '0')

	checkboxes: (pnlTarget) =>
		output = [@checkbox(pnlTarget, name) for name, cvar in pairs @convars]
		return output

	getBool: (name, ifFail = false) =>
		return ifFail if not @convars[name]
		return @convars[name].GetBool(@convars[name], ifFail)

	getInt: (name, ifFail = 0) =>
		return ifFail if not @convars[name]
		return @convars[name].GetInt(@convars[name], ifFail)

	getFloat: (name, ifFail = 0) =>
		return ifFail if not @convars[name]
		return @convars[name].GetFloat(@convars[name], ifFail)

	getString: (name) =>
		return '' if not @convars[name]
		return @convars[name].GetString(@convars[name])
