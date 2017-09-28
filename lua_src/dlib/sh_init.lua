
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

local AddCSLuaFile_ = AddCSLuaFile
local include_ = include

local function shmodule(fil)
	if SERVER then AddCSLuaFile_('dlib/modules/' .. fil) end
	return include_('dlib/modules/' .. fil)
end

shmodule('strong_entity_link.lua')
