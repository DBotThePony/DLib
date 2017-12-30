
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

if SERVER then return end

timer.Simple(0, function()
	for k, info in pairs(scripted_ents.GetList()) do
		if info.t and info.t.ClassName and info.t.PrintName and info.t.PrintName:sub(1, 1) ~= '#' then
			language.Add(info.t.ClassName, info.t.PrintName)
		end
	end

	for i, info in ipairs(weapons.GetList()) do
		if info.ClassName and info.PrintName and info.PrintName:sub(1, 1) ~= '#' then
			language.Add(info.ClassName, info.PrintName)
		end
	end
end)
