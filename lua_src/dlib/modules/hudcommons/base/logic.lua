
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

local meta = DLib.FindMetaTable('HUDCommonsBase')
local DLib = DLib
local HUDCommons = HUDCommons
local LocalPlayer = LocalPlayer
local NULL = NULL
local type = type
local assert = assert
local RealTime = RealTime
local CurTime = CurTime
local math = math
local IsValid = FindMetaTable('Entity').IsValid

function meta:MimicPlayer(playerTarget)
	if not playerTarget then
		if IsValid(self.mimic) then
			self:MimicEnd(self.mimic, LocalPlayer())
		end

		self.mimic = NULL
		return
	end

	assert(type(playerTarget) == 'Player', 'MimicPlayer - input is not a target!')
	if self.mimic == playerTarget then return end
	self.mimic = playerTarget
	self.prevWeapon = self:GetWeapon()
	self.currWeaponTrack = self.prevWeapon
	self:MimicStart(IsValid(self.mimic) and self.mimic or LocalPlayer(), playerTarget)
end

function meta:MimicStart(oldPlayer, newPlayer)

end

function meta:MimicEnd(oldPlayer, newPlayer)

end

function meta:SelectPlayer()
	if IsValid(self.mimic) then
		return self.mimic
	end

	return HUDCommons.SelectPlayer()
end

meta.LocalPlayer = meta.SelectPlayer
meta.GetPlayer = meta.SelectPlayer

function meta:TickLogic(lPly)
	local wep = self:GetWeapon()

	if self.currWeaponTrack ~= wep then
		self:CallOnWeaponChanged(self.currWeaponTrack, wep)
		self:OnWeaponChanged(self.currWeaponTrack, wep)
		self.prevWeapon = self.currWeaponTrack
		self.currWeaponTrack = wep
	end
end

function meta:ThinkLogic(lPly)
	if self.glitching then
		local timeLeft = self:GlitchTimeRemaining()
		self.glitching = timeLeft ~= 0

		if self.glitching then
			-- lets make it a big faster
			local vars = self.variables

			for i = 1, #vars do
				local entry = vars[i]
				local grab = entry.onGlitch(entry.self, self, lPly, timeLeft)
			end
		else
			self:CallOnGlitchEnd()
			self:OnGlitchEnd()
		end
	end
end

-- override
function meta:OnGlitchStart(timeLong)

end

-- override
function meta:OnGlitchEnd()

end

function meta:TriggerGlitch(timeLong)
	local old = self.glitchEnd
	self.glitchEnd = math.max(self.glitchEnd, CurTime() + timeLong)

	if not self.glitching then
		self.glitching = true
		self.glitchingSince = CurTime()
		self:CallOnGlitchStart(timeLong)
		self:OnGlitchStart(timeLong)
	end

	return old ~= self.glitchEnd
end

function meta:ExtendGlitch(timeLong)
	self.glitchEnd = math.max(self.glitchEnd + timeLong, CurTime() + timeLong)

	if not self.glitching then
		self.glitching = true
		self.glitchingSince = CurTime()
		self:CallOnGlitchStart(timeLong)
		self:OnGlitchStart(timeLong)
	end

	return true
end

function meta:ClampGlitchTime(maximal)
	local old = self.glitchEnd
	self.glitchEnd = self.glitchEnd:min(CurTime() + maximal)
	return self.glitchEnd ~= old
end

function meta:GlitchTimeRemaining()
	return math.max(0, self.glitchEnd - CurTime())
end

function meta:GlitchingSince()
	return self.glitchingSince
end

function meta:GlitchingFor()
	return CurTime() - self.glitchingSince
end

function meta:IsGlitching()
	return self.glitching
end

-- override
function meta:OnWeaponChanged(old, new)

end

function meta:DrawWeaponSelection(wep)
	self.tryToSelectWeapon = wep

	if self.tryToSelectWeaponLast < RealTime() then
		self.tryToSelectWeaponFadeIn = RealTime() + 0.5
	end

	self.tryToSelectWeaponLast = RealTime() + 0.75
	self.tryToSelectWeaponLastEnd = RealTime() + 1.25
end
