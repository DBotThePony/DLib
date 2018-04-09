
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local DLib = DLib

DLib.DEBUG_MODE = CreateConVar('dlib_debug', '0', {FCVAR_REPLICATED}, 'Enable debug mode. Setting this to 1 can help you solve weird bugs.')
DLib.STRICT_MODE = CreateConVar('dlib_strict', '0', {FCVAR_REPLICATED}, 'Enable strict mode. Enabling this turns all ErrorNoHalts into execution halting errors. The best way to fix bad code.')

function DLib.register(fil)
	if SERVER then AddCSLuaFile('dlib/' .. fil) end
	local result = include('dlib/' .. fil)
	if not result then return end
	return result.register()
end

function DLib.simpleInclude(fil)
	if SERVER then AddCSLuaFile('dlib/' .. fil) end
	return include('dlib/' .. fil)
end

local startupText = [[
	___  _    _ ___
	|  \ |    | |__]
	|__/ |___ | |__]

	____ ____ ___  ____ ____ _ _  _ _ _  _ ____
	|__/ |___ |  \ |___ |___ | |\ | | |\ | | __
	|  \ |___ |__/ |___ |    | | \| | | \| |__]

	____ _    _  _ ____
	| __ |    |  | |__|
	|__] |___ |__| |  |

]]

local startupText2 = [[
	___  _    _ ___
	|  \ |    | |__]
	|__/ |___ | |__]

	___  ____ ____ ____ _  _ _ _  _ ____
	|__] |__/ |___ |__| |_/  | |\ | | __
	|__] |  \ |___ |  | | \_ | | \| |__]

	_   _ ____ _  _ ____
	 \_/  |  | |  | |__/
	  |   |__| |__| |  \

	____ _  _ _ ___
	[__  |__| |  |
	___] |  | |  |

	___ _  _
	 |  |\/|
	 |  |  |

]]

MsgC('---------------------------------------------------------------\n')

if math.random() > 0.1 then
	for line in string.gmatch(startupText, '(.-)\r?\n') do
		MsgC(line .. '\n')
	end
else
	for line in string.gmatch(startupText2, '(.-)\r?\n') do
		MsgC(line .. '\n')
	end
end

local MsgC = MsgC
local SysTime = SysTime
local timeStart = SysTime()

MsgC('---------------------------------------------------------------\n')
MsgC('[DLib] Initializing DLib core ... ')

DLib.simpleInclude('core/core.lua')
DLib.simpleInclude('core/luaify.lua')
DLib.simpleInclude('core/funclib.lua')
DLib.simpleInclude('util/alias.lua')
DLib.module = DLib.simpleInclude('core/module.lua')
DLib.manifest = DLib.simpleInclude('core/manifest.lua')
DLib.MessageMaker = DLib.simpleInclude('util/message.lua')
DLib.MessageMaker(DLib, 'DLib')
DLib.register('core/sandbox.lua')

if jit then
	if SERVER then AddCSLuaFile('dlib/core/vmdef.lua') end
	local vmdef = CompileFile('dlib/core/vmdef.lua')
	jit.vmdef = nil
	vmdef('jit_vmdef')
	jit.vmdef = jit_vmdef
end

DLib.CMessage = DLib.MessageMaker
DLib.ConstructMessage = DLib.MessageMaker

DLib.simpleInclude('util/color.lua')

DLib.register('util/combathelper.lua')
DLib.register('util/util.lua')
DLib.register('util/constraint.lua')
DLib.register('util/vector.lua')

DLib.node = DLib.simpleInclude('util/node.lua')

if CLIENT then
	DLib.register('util/client/localglobal.lua')
end

file.mkdir('dlib')

DLib.register('core/tableutil.lua').export(_G.table)
DLib.register('core/fsutil.lua').export(_G.file)
DLib.register('core/loader.lua')
DLib.simpleInclude('core/loader_modes.lua')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
MsgC('[DLib] Initializing DLib GLua extensions ... ')

DLib.Loader.shmodule('bitworker.lua').register()
DLib.Loader.shmodule('bitworker2.lua').register()

DLib.simpleInclude('luabridge/luaify.lua')

DLib.register('extensions/extensions.lua')
DLib.register('extensions/string.lua')
DLib.register('extensions/ctakedmg.lua')
DLib.register('extensions/table.lua')
DLib.register('extensions/cvar.lua')
DLib.register('extensions/entity.lua')
DLib.register('extensions/render.lua')
DLib.register('extensions/player.lua').export(_G.player)

DLib.Loader.shmodule('hook.lua')
DLib.simpleInclude('luabridge/luaify2.lua')
DLib.simpleInclude('luabridge/lobject.lua')
DLib.Loader.shmodule('color.lua')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
MsgC('[DLib] Initializing DLib modules ... ')

DLib.simpleInclude('net/net.lua')
DLib.Loader.shmodule('bytesbuffer.lua')
DLib.Loader.shmodule('nbt.lua')
DLib.Loader.shmodule('lerp.lua')
DLib.Loader.shmodule('sh_cami.lua')
DLib.Loader.shmodule('getinfo.lua').register()
DLib.Loader.shmodule('strong_entity_link.lua')

DLib.Loader.start('nw')
DLib.Loader.load('dlib/modules/nwvar')
DLib.Loader.finish()

DLib.register('util/queue.lua')

DLib.Loader.loadPureSHTop('dlib/enums')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
MsgC('[DLib] Initializing DLib classes ... ')

DLib.Loader.shclass('astar.lua')
DLib.Loader.shclass('collector.lua')
DLib.Loader.shclass('average.lua')
DLib.Loader.shclass('set.lua')
DLib.Loader.shclass('hashset.lua')
DLib.Loader.shclass('enum.lua')
DLib.Loader.shclass('freespace.lua')
DLib.Loader.shclass('cvars.lua')
DLib.Loader.shclass('rainbow.lua')
DLib.Loader.shclass('camiwatchdog.lua')
DLib.Loader.shclass('measure.lua')
DLib.Loader.shclass('bezier.lua')
DLib.Loader.clclass('keybinds.lua').register()

DLib.Loader.start('lang')
DLib.Loader.load('dlib/modules/lang')
DLib.Loader.finish()

DLib.Loader.start('friends', true)
DLib.Loader.load('dlib/modules/friendsystem')
DLib.Loader.finish()

if CLIENT then
	DLib.VGUI = DLib.VGUI or {}
end

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
timeStart = SysTime()
MsgC('[DLib] Initializing DLib LuaBridge ... ')

DLib.simpleInclude('luabridge/luabridge.lua')
DLib.simpleInclude('luabridge/physgunhandler.lua')
DLib.simpleInclude('luabridge/pnlhud.lua')
DLib.simpleInclude('luabridge/loading_stages.lua')
DLib.Loader.loadPureSHTop('dlib/modules/workarounds')

DLib.hl2wdata = DLib.simpleInclude('data/hl2sweps.lua')

MsgC(string.format('%.2f ms\n', (SysTime() - timeStart) * 1000))
