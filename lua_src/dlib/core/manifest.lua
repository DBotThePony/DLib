
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

return function(manifestData)
	manifestData.shared = manifestData.shared or {}
	manifestData.client = manifestData.client or {}
	manifestData.server = manifestData.server or {}
	manifestData.misc = manifestData.misc or {}

	local prefix = manifestData.prefix and (manifestData.prefix .. '/') or ''

	for i, fileName in ipairs(manifestData.shared) do
		include(prefix .. fileName)

		if SERVER then
			AddCSLuaFile(prefix .. fileName)
		end
	end

	hook.Run('DLib_SharedInitialize', manifestData.name, manifestData)

	if SERVER then
		for i, fileName in ipairs(manifestData.client) do
			AddCSLuaFile(prefix .. fileName)
		end

		for i, fileName in ipairs(manifestData.server) do
			include(prefix .. fileName)
		end

		hook.Run('DLib_ServerInitialize', manifestData.name, manifestData)
	else
		for i, fileName in ipairs(manifestData.client) do
			include(prefix .. fileName)
		end

		hook.Run('DLib_ClientInitialize', manifestData.name, manifestData)
	end

	hook.Run('DLib_ManifestInitialize', manifestData.name, manifestData)
end
