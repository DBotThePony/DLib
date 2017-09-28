
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

local function AddCSLuaFile(fil)
	return AddCSLuaFile_('dlib/' .. fil)
end

local function csmodule(fil)
	return AddCSLuaFile_('dlib/modules/' .. fil)
end

local function shmodule(fil)
	AddCSLuaFile_('dlib/modules/' .. fil)
	return include_('dlib/modules/' .. fil)
end

csmodule('hudcommons/simple_draw.lua')
csmodule('hudcommons/advanced_draw.lua')
csmodule('hudcommons/position.lua')
csmodule('hudcommons/menu.lua')
csmodule('hudcommons/functions.lua')
csmodule('hudcommons/colors.lua')
csmodule('hudcommons/matrix.lua')
csmodule('hudcommons/stripped.lua')
