
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

local string = DLib.module('string', 'string')

function string.tformat(time)
	local str = ''

	local hours = (time - time % 3600) / 3600
	time = time - hours * 3600
	local minutes = (time - time % 60) / 60
	time = time - minutes * 60
	local seconds = time

	if seconds ~= 0 then
		str = seconds .. ' seconds'
	end

	if minutes ~= 0 then
		str = minutes .. ' minutes ' .. str
	end

	if hours ~= 0 then
		str = hours .. ' hours ' .. str
	end

	return str
end

return string
