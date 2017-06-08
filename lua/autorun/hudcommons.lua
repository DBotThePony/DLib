
--
-- Copyright (C) 2017 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

if CLIENT then
    _G.HUDCommons = _G.HUDCommons or {}
    include('autorun/client/hudcommons/simple_draw.lua')
    include('autorun/client/hudcommons/advanced_draw.lua')
    include('autorun/client/hudcommons/position.lua')
    include('autorun/client/hudcommons/menu.lua')
    include('autorun/client/hudcommons/functions.lua')
    include('autorun/client/hudcommons/colors.lua')
else
    AddCSLuaFile('autorun/client/hudcommons/simple_draw.lua')
    AddCSLuaFile('autorun/client/hudcommons/advanced_draw.lua')
    AddCSLuaFile('autorun/client/hudcommons/position.lua')
    AddCSLuaFile('autorun/client/hudcommons/menu.lua')
    AddCSLuaFile('autorun/client/hudcommons/functions.lua')
    AddCSLuaFile('autorun/client/hudcommons/colors.lua')
end
