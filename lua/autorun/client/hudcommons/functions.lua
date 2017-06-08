
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

function HUDCommons.SelectPlayer()
	local ply = LocalPlayer()
	if not IsValid(ply) then return ply end
	local obs = ply:GetObserverTarget()
	
	if IsValid(obs) and obs:IsPlayer() then
		return obs
	else
		return ply
	end
end
