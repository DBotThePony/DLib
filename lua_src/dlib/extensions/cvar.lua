
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

local ConVar = FindMetaTable('ConVar')
local math = math
local error = error

function ConVar:GetByType(typeIn, ...)
	if typeIn == 'string' then
		return self:GetString(...)
	elseif typeIn == 'int' or typeIn == 'integer' or typeIn == 'number' then
		return self:GetInt(...)
	elseif typeIn == 'uint' or typeIn == 'uinteger' or typeIn == 'unumber' then
		return math.max(self:GetInt(...), 0)
	elseif typeIn == 'float' then
		return self:GetFloat(...)
	elseif typeIn == 'bool' or typeIn == 'boolean' then
		return self:GetBool(...)
	else
		error('Unknown variable type - ' .. typeIn .. '!')
	end
end
