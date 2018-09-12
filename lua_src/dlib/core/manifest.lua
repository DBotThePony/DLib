
-- Copyright (C) 2017-2018 DBot

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.


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
