
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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
			RunConsoleCommand(@setname, ...)
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
			.Button.Think = -> \SetChecked(@getBool(name))
			.Button.DoClick = @clickfunc(name)
	checkboxes: (pnlTarget) =>
		output = [@checkbox(pnlTarget, name) for name in pairs @convars]
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
