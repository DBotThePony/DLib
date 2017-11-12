
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

do
	local plyMeta = FindMetaTable('Player')
	local entMeta = FindMetaTable('Entity')
	local entMeta_GetTable = entMeta.GetTable

	local entCache1, entCacheTable1
	local entCache2, entCacheTable2
	local entCache3, entCacheTable3
	local entCache4, entCacheTable4
	local entCache5, entCacheTable5
	local entCache6, entCacheTable6
	local entCache7, entCacheTable7
	local entCache8, entCacheTable8
	local entCache9, entCacheTable9
	local entCache10, entCacheTable10
	local nextIndex = 1

	function plyMeta:__index(key)
		local val = plyMeta[key]
		if val ~= nil then return val end

		val = entMeta[key]
		if val ~= nil then return val end

		local tab

		if self == entCache1 then
			tab = entCacheTable1
		elseif self == entCache2 then
			tab = entCacheTable2
		elseif self == entCache3 then
			tab = entCacheTable3
		elseif self == entCache4 then
			tab = entCacheTable4
		elseif self == entCache5 then
			tab = entCacheTable5
		elseif self == entCache6 then
			tab = entCacheTable6
		elseif self == entCache7 then
			tab = entCacheTable7
		elseif self == entCache8 then
			tab = entCacheTable8
		elseif self == entCache9 then
			tab = entCacheTable9
		elseif self == entCache10 then
			tab = entCacheTable10
		else
			tab = entMeta_GetTable(self)

			if tab then
				nextIndex = nextIndex + 1

				if nextIndex > 10 then
					nextIndex = 1
				end

				if nextIndex == 1 then
					entCacheTable1 = tab
					entCache1 = self
				elseif nextIndex == 2 then
					entCacheTable2 = tab
					entCache2 = self
				elseif nextIndex == 3 then
					entCacheTable3 = tab
					entCache3 = self
				elseif nextIndex == 4 then
					entCacheTable4 = tab
					entCache4 = self
				elseif nextIndex == 5 then
					entCacheTable5 = tab
					entCache5 = self
				elseif nextIndex == 6 then
					entCacheTable6 = tab
					entCache6 = self
				elseif nextIndex == 7 then
					entCacheTable7 = tab
					entCache7 = self
				elseif nextIndex == 8 then
					entCacheTable8 = tab
					entCache8 = self
				elseif nextIndex == 9 then
					entCacheTable9 = tab
					entCache9 = self
				elseif nextIndex == 10 then
					entCacheTable10 = tab
					entCache10 = self
				end
			end
		end

		if tab then
			val = tab[key]
			if val ~= nil then return val end
		end

		return nil
	end
end

do
	local entMeta = FindMetaTable('Entity')
	local entMeta_GetTable = entMeta.GetTable
	entMeta.SpawnDLib = entMeta.SpawnDLib or entMeta.Spawn
	local entMeta_Spawn = entMeta.SpawnDLib
	local entMeta_GetOwner = entMeta.GetOwner
	local entMeta_GetClass = entMeta.GetClass

	function entMeta:Spawn()
		local val = entMeta_Spawn(self)
		hook.Run('EntitySpawned', self)
		return val
	end

	function entMeta:__index(key)
		local val = entMeta[key]
		if val ~= nil then return val end

		local tab = entMeta_GetTable(self)

		if tab then
			val = tab[key]
			if val ~= nil then return val end
		end

		if key == 'Entity' then
			return self
		end

		if key == 'Owner' then
			return entMeta_GetOwner(self)
		end

		return nil
	end
end

do
	local entMeta = FindMetaTable('Entity')
	local weaponMeta = FindMetaTable('Weapon')
	local entMeta_GetTable = entMeta.GetTable
	local entMeta_GetOwner = entMeta.GetOwner
	local entMeta_GetClass = entMeta.GetClass

	function weaponMeta:__index(key)
		local val = weaponMeta[key]
		if val ~= nil then return val end

		val = entMeta[key]
		if val ~= nil then return val end

		local tab = entMeta_GetTable(self)

		if tab then
			val = tab[key]
			if val ~= nil then return val end
		end

		if key == 'Entity' then
			return self
		end

		if key == 'Owner' then
			return entMeta_GetOwner(self)
		end

		return nil
	end
end
