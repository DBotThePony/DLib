
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
DLib.fnlib = {}

local fnlib = DLib.fnlib
local meta = debug.getmetatable(function() end) or {}

meta.MetaName = 'function'

function meta:__index(key)
	local val = meta[key]

	if val ~= nil then
		return val
	end

	return fnlib[key]
end

function meta:IsValid()
	return false
end

debug.setmetatable(function() end, meta)
