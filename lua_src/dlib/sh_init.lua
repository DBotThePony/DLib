
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

function DLib.register(fil)
	if SERVER then AddCSLuaFile('dlib/' .. fil) end
	local result = include('dlib/' .. fil)
	if not result then return end
	return result.register()
end

DLib.module = include('dlib/core/module.lua')
DLib.manifest = include('dlib/core/manifest.lua')
DLib.MessageMaker = include('dlib/util/message.lua')
DLib.MessageMaker(DLib, 'DLib')

DLib.CMessage = DLib.MessageMaker
DLib.ConstructMessage = DLib.MessageMaker

include('dlib/util/alias.lua')
include('dlib/util/color.lua')

DLib.register('util/combathelper.lua')

DLib.node = include('dlib/util/node.lua')

file.mkdir('dlib')

DLib.register('core/tableutil.lua').export(_G.table)
DLib.register('core/fsutil.lua').export(_G.file)
DLib.register('core/loader.lua')

DLib.register('extensions/string.lua')
DLib.register('extensions/ctakedmg.lua')
DLib.register('extensions/player.lua').export(_G.player)
DLib.register('extensions/net.lua').export(_G.net)

DLib.Loader.shmodule('sh_cami.lua')
DLib.Loader.shmodule('strong_entity_link.lua')

DLib.Loader.shclass('modifier_base.lua')
DLib.Loader.shclass('networked_data.lua')
DLib.Loader.shclass('sequence_base.lua')
DLib.Loader.shclass('sequence_holder.lua')
DLib.Loader.shclass('astar.lua')
DLib.Loader.clclass('keybinds.lua').register()

DLib.Loader.start('HUDCommons')
DLib.Loader.loadPureCS('dlib/modules/hudcommons')
DLib.Loader.finish()

DLib.Loader.start('nw')
DLib.Loader.load('dlib/modules/nwvar')
DLib.Loader.finish()

DLib.Loader.start('lang')
DLib.Loader.load('dlib/modules/lang')
DLib.Loader.finish()

DLib.Loader.loadPureCS('dlib/vgui')

DLib.Loader.loadPureSH('dlib/luabridge')
