
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

return function(moduleName)
	local self = {}

	function self:Name()
		return moduleName
	end

	function self.export(target)
		for k, v in pairs(self) do
			if type(v) == 'function' then
				target[k] = v
			end
		end

		return target
	end

	function self.register()
		DLib[moduleName] = DLib[moduleName] or {}
		return self.export(DLib[moduleName])
	end

	return self
end
