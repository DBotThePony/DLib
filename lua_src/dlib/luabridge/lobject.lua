
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
local FindMetaTable = FindMetaTable
local debug = debug
local type = type
local error = error
local setmetatable = setmetatable
local rawget = rawget

DLib.METADATA = DLib.METADATA or {}

function DLib.CreateLuaObject(objectName, registerMetadata)
	local meta

	if registerMetadata then
		meta = FindMetaTable(objectName) or {}
		debug.getregistry()[objectName] = meta
	else
		meta = DLib.METADATA[objectName] or {}
		DLib.METADATA[objectName] = meta
	end

	meta.__getters = meta.__getters or {}

	if not meta.__index then
		function meta:__index(key)
			local getter = meta.__getters[key]

			if getter then
				return getter(self, key)
			end

			local value = rawget(self, key)

			if value ~= nil then
				return value
			end

			return meta[key]
		end
	end

	if not meta.GetClass then
		local lower = objectName:lower()

		function meta:GetClass()
			return lower
		end
	end

	if not meta.Create then
		function meta.Create(self, ...)
			if type(self) == 'table' then
				if not self.Copy then
					error(objectName .. ':Copy() - method is not implemented')
				end

				return self:Copy(...)
			end

			local newObject = setmetatable({}, meta)

			if meta.Initialize then
				meta.Initialize(newObject, self, ...)
			elseif meta.__construct then
				meta.__construct(newObject, self, ...)
			end

			return newObject
		end
	end

	return meta
end

function DLib.FindMetaTable(classIn)
	return DLib.METADATA[classIn] or FindMetaTable(classIn) or nil
end

function DLib.ConsturctClass(classIn, ...)
	local classGet = DLib.FindMetaTable(classIn)
	if not classGet then return false end
	return classGet.Create(...)
end
