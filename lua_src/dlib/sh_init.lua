
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

local function register(fil)
	if SERVER then AddCSLuaFile('dlib/' .. fil) end
	local result = include('dlib/' .. fil)
	return result.register()
end

DLib.module = include('dlib/core/module.lua')
DLib.MessageMaker = include('dlib/util/message.lua')
DLib.MessageMaker(DLib, 'DLib')

register('core/tableutil.lua').export(table)
register('core/fsutil.lua').export(file)
register('core/loader.lua')

DLib.Loader.shmodule('strong_entity_link.lua')
DLib.Loader.shmodule('sh_cami.lua')

DLib.Loader.start('HUDCommons')
DLib.Loader.loadPureCS('dlib/modules/hudcommons')
DLib.Loader.finish()

