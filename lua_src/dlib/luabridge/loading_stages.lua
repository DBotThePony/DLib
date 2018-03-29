
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

local hook = hook
local DLib = DLib
local CurTimeL = CurTimeL

local init_post_entity = CurTimeL() > 60
local initialize = CurTimeL() > 60

function _G.AreEntitiesAvaliable()
	return init_post_entity
end

function _G.IsGamemodeAvaliable()
	return initialize
end

if not init_post_entity then
	hook.Add('InitPostEntity', 'DLib.LoadingStages', function()
		init_post_entity = true
	end)
end

if not initialize then
	hook.Add('Initialize', 'DLib.LoadingStages', function()
		initialize = true
	end)
end
