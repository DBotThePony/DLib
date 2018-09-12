
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


local meta = DLib.FindMetaTable('HUDCommonsBase')
local DLib = DLib
local HUDCommons = HUDCommons
local LocalPlayer = LocalPlayer
local NULL = NULL
local type = type
local assert = assert
local RealTimeL = RealTimeL
local CurTimeL = CurTimeL
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
	self.glitchEnd = math.max(self.glitchEnd, CurTimeL() + timeLong)

	if not self.glitching then
		self.glitching = true
		self.glitchingSince = CurTimeL()
		self:CallOnGlitchStart(timeLong)
		self:OnGlitchStart(timeLong)
	end

	return old ~= self.glitchEnd
end

function meta:ExtendGlitch(timeLong)
	self.glitchEnd = math.max(self.glitchEnd + timeLong, CurTimeL() + timeLong)

	if not self.glitching then
		self.glitching = true
		self.glitchingSince = CurTimeL()
		self:CallOnGlitchStart(timeLong)
		self:OnGlitchStart(timeLong)
	end

	return true
end

function meta:ClampGlitchTime(maximal)
	local old = self.glitchEnd
	self.glitchEnd = self.glitchEnd:min(CurTimeL() + maximal)
	return self.glitchEnd ~= old
end

function meta:GlitchTimeRemaining()
	return math.max(0, self.glitchEnd - CurTimeL())
end

function meta:GlitchingSince()
	return self.glitchingSince
end

function meta:GlitchingFor()
	return CurTimeL() - self.glitchingSince
end

function meta:IsGlitching()
	return self.glitching
end

-- override
function meta:OnWeaponChanged(old, new)

end

function meta:DrawWeaponSelection(wep)
	self.tryToSelectWeapon = wep

	if self.tryToSelectWeaponLast < RealTimeL() then
		self.tryToSelectWeaponFadeIn = RealTimeL() + 0.5
	end

	self.tryToSelectWeaponLast = RealTimeL() + 0.75
	self.tryToSelectWeaponLastEnd = RealTimeL() + 1.25
end
