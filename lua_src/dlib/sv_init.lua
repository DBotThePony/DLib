
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

function DLib.registerSV(fil)
	local result = include('dlib/' .. fil)
	if not result then return end
	return result.register()
end

DLib.Loader.csModule('dlib/modules/dnotify/client')
DLib.Loader.svmodule('notify/sv_dnotify.lua')
DLib.Loader.csModule('dlib/util/client')
DLib.Loader.svmodule('dmysql.lua')

DLib.registerSV('util/server/chat.lua')

DLib.Loader.loadPureSHTop('dlib/autorun')
DLib.Loader.loadPureSVTop('dlib/autorun/server')
DLib.Loader.loadPureCSTop('dlib/autorun/client')
