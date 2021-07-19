
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


local DLib = DLib

DLib.DEBUG_MODE = CreateConVar('dlib_debug', '0', {FCVAR_REPLICATED}, 'Enable debug mode. Setting this to 1 can help you solve weird bugs.')
DLib.STRICT_MODE = CreateConVar('dlib_strict', '0', {FCVAR_REPLICATED}, 'Enable strict mode. Enabling this turns all ErrorNoHalts into execution halting errors. The best way to fix bad code.')

function DLib.SharedInclude(fil)
	if SERVER then AddCSLuaFile('dlib/' .. fil) end

	return include('dlib/' .. fil)
end

function DLib.ClientInclude(fil)
	if SERVER then
		AddCSLuaFile('dlib/' .. fil)
		return
	end

	return include('dlib/' .. fil)
end

function DLib.ServerInclude(fil)
	if CLIENT then return end

	return include('dlib/' .. fil)
end

local MsgC = MsgC
local SysTime = SysTime
local timeStart = SysTime()

MsgC('---------------------------------------------------------------\n')
MsgC('[DLib] Initializing DLib core stage 1 ... ')

DLib.SharedInclude('core/core.lua')
DLib.SharedInclude('core/luaify.lua')
DLib.SharedInclude('core/funclib.lua')
DLib.SharedInclude('modules/color.lua')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
MsgC('[DLib] Initializing DLib core stage 2 ... ')

DLib.MessageMaker = DLib.SharedInclude('util/message.lua')
DLib.MessageMaker(DLib, 'DLib')
DLib.SharedInclude('core/sandbox.lua')
DLib.SharedInclude('core/moonclass.lua')
DLib.SharedInclude('core/promise.lua')

if jit then
	if SERVER then
		AddCSLuaFile('dlib/core/vmdef.lua')
		AddCSLuaFile('dlib/core/vmdef_x64.lua')
	end

	if jit.arch == 'x86' then
		local vmdef = CompileFile('dlib/core/vmdef.lua')
		jit.vmdef = nil
		vmdef('jit_vmdef')
		jit.vmdef = jit_vmdef
	elseif jit.arch == 'x64' then
		jit.vmdef = include('dlib/core/vmdef_x64.lua')
	end
end

DLib.CMessage = DLib.MessageMaker
DLib.ConstructMessage = DLib.MessageMaker

DLib.SharedInclude('util/util.lua')
DLib.SharedInclude('util/vector.lua')

DLib.node = DLib.SharedInclude('util/node.lua')
DLib.Node = DLib.node

DLib.ClientInclude('util/client/localglobal.lua')
DLib.SharedInclude('core/tableutil.lua')
DLib.SharedInclude('core/fsutil.lua')
DLib.SharedInclude('core/loader.lua')
DLib.SharedInclude('core/loader_modes.lua')

DLib.MessageNoPrefix(string.format('%.2f ms', (SysTime() - timeStart) * 1000))
timeStart = SysTime()

file.mkdir('dlib')

DLib.MessageNoNL('Initializing DLib GLua extensions ... ')

DLib.SharedInclude('modules/hook.lua')

DLib.SharedInclude('util/combathelper.lua')

DLib.SharedInclude('modules/bitworker.lua')

DLib.SharedInclude('extensions/extensions.lua')
DLib.SharedInclude('extensions/string.lua')
DLib.SharedInclude('extensions/ctakedmg.lua')
DLib.SharedInclude('extensions/cvar.lua')
DLib.SharedInclude('extensions/entity.lua')
DLib.SharedInclude('extensions/render.lua')
DLib.SharedInclude('extensions/player.lua')

DLib.SharedInclude('util/http.lua')
DLib.SharedInclude('util/httpclient.lua')
DLib.SharedInclude('util/promisify.lua')

DLib.MessageNoPrefix(string.format('%.2f ms', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
DLib.MessageNoNL('Initializing DLib modules ... ')

DLib.SharedInclude('modules/luavector.lua')
DLib.SharedInclude('modules/net_ext.lua')
DLib.SharedInclude('modules/bytesbuffer.lua')
DLib.SharedInclude('util/hash.lua')
DLib.SharedInclude('modules/nbt.lua')
DLib.SharedInclude('modules/gobjectnotation.lua')
DLib.SharedInclude('modules/lerp.lua')
DLib.SharedInclude('modules/sh_cami.lua')
DLib.SharedInclude('modules/predictedvars.lua')

DLib.net = DLib.net or DLib.Net or {}
DLib.Net = DLib.net
DLib.SharedInclude('modules/net/sh_init.lua')
DLib.SharedInclude('modules/net/sh_nwvars2.lua')
DLib.ClientInclude('modules/net/cl_init.lua')
DLib.ClientInclude('modules/net/cl_nwvars2.lua')
DLib.ServerInclude('modules/net/sv_init.lua')
DLib.ServerInclude('modules/net/sv_nwvars2.lua')

DLib.SharedInclude('modules/getinfo.lua')

DLib.MessageMaker(DLib, 'DLib')

DLib.SharedInclude('util/debugoverlay.lua')

DLib.nw = DLib.nw or {}
DLib.NW = DLib.nw
DLib.SharedInclude('modules/nwvar/sh_nwvar.lua')
DLib.ClientInclude('modules/nwvar/cl_nwvar.lua')
DLib.ServerInclude('modules/nwvar/sv_nwvar.lua')

DLib.SharedInclude('util/queue.lua')
DLib.SharedInclude('util/pdata.lua')
DLib.SharedInclude('modules/textureworks.lua')
DLib.SharedInclude('modules/s3tc.lua')
DLib.SharedInclude('modules/vtf.lua')
DLib.SharedInclude('classes/cache_manager.lua')

DLib.SharedInclude('enums/gmod.lua')
DLib.SharedInclude('enums/keymapping.lua')
DLib.SharedInclude('enums/sdk.lua')

DLib.i18n = DLib.i18n or {}
DLib.I18n = DLib.i18n
DLib.SharedInclude('modules/i18n/sh_i18n.lua')
DLib.SharedInclude('modules/i18n/sh_functions.lua')
DLib.SharedInclude('modules/i18n/sh_units.lua')
DLib.ClientInclude('modules/i18n/cl_i18n.lua')
DLib.ServerInclude('modules/i18n/sv_i18n.lua')
DLib.SharedInclude('modules/i18n/sh_loader.lua')

do
	local remap = {}

	for k, v in pairs(DLib.I18n) do
		if isfunction(v) and isstring(k) then
			remap[k[1]:lower() .. k:sub(2)] = v
		end
	end

	for k, v in pairs(remap) do
		DLib.I18n[k] = v
	end
end

DLib.friends = DLib.friends or {}
DLib.Friend = DLib.friends
DLib.SharedInclude('modules/friendsystem/sh_friends.lua')
DLib.ClientInclude('modules/friendsystem/cl_friends.lua')
DLib.ClientInclude('modules/friendsystem/cl_gui.lua')
DLib.ServerInclude('modules/friendsystem/sv_friends.lua')

DLib.MessageNoPrefix(string.format('%.2f ms', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
DLib.MessageNoNL('Initializing DLib classes ... ')

DLib.SharedInclude('classes/astar.lua')
DLib.SharedInclude('classes/dmginfo.lua')
DLib.SharedInclude('classes/collector.lua')
DLib.SharedInclude('classes/set.lua')
DLib.SharedInclude('classes/freespace.lua')
DLib.SharedInclude('classes/cvars.lua')
DLib.SharedInclude('classes/rainbow.lua')
DLib.SharedInclude('classes/camiwatchdog.lua')
DLib.SharedInclude('classes/measure.lua')
DLib.SharedInclude('classes/bezier.lua')
DLib.SharedInclude('classes/predictedvars.lua')
DLib.ClientInclude('classes/keybinds.lua')

if CLIENT then
	DLib.VGUI = DLib.VGUI or {}
end

DLib.MessageNoPrefix(string.format('%.2f ms', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
DLib.MessageNoNL('Initializing DLib general Lua additions ... ')

DLib.SharedInclude('luabridge/luabridge.lua')
DLib.SharedInclude('luabridge/physgunhandler.lua')
DLib.SharedInclude('luabridge/loading_stages.lua')
DLib.SharedInclude('luabridge/savetable.lua')

DLib.ClientInclude('modules/workarounds/entlang.lua')
DLib.SharedInclude('modules/workarounds/killfeed.lua')
DLib.SharedInclude('modules/workarounds/starfall.lua')

DLib.hl2wdata = DLib.SharedInclude('data/hl2sweps.lua')

DLib.__net_ext_export(DLib.Net)

DLib.MessageNoPrefix(string.format('%.2f ms', (SysTime() - timeStart) * 1000))
