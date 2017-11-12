
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

local entMeta = FindMetaTable('Entity')

function entMeta:IsClientsideEntity()
	return false
end

if CLIENT then
	local CSEnt = FindMetaTable('CSEnt')

	function CSEnt:IsClientsideEntity()
		return true
	end
else
	function entMeta:BuddhaEnable()
		self:SetSaveValue('m_takedamage', DAMAGE_MODE_BUDDHA)
	end

	function entMeta:BuddhaDisable()
		self:SetSaveValue('m_takedamage', DAMAGE_MODE_ENABLED)
	end

	function entMeta:IsBuddhaEnabled()
		return self:GetSaveTable().m_takedamage == DAMAGE_MODE_BUDDHA
	end
end
