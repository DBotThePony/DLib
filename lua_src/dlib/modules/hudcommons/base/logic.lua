
-- Copyright (C) 2017-2020 DBotThePony

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

local DLib = DLib
local HUDCommons = DLib.HUDCommons
local meta = HUDCommons.BaseMetaObj
local HUDCommons = DLib.HUDCommons
local LocalPlayer = LocalPlayer
local NULL = NULL
local type = type
local assert = assert
local RealTimeL = RealTimeL
local CurTimeL = CurTimeL
local math = math
local IsValid = FindMetaTable('Entity').IsValid

--[[
	@doc
	@fname HUDCommonsBase:MimicPlayer
	@args Player targetOrNil

	@client

	@desc
	Makes `HUDCommonsBase:SelectPlayer()` return different player
	@enddesc
]]
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

--[[
	@doc
	@fname HUDCommonsBase:MimicStart
	@args Player oldPlayer, Player newPlayer

	@client

	@desc
	that's a hook! override it if you want to.
	@enddesc
]]
function meta:MimicStart(oldPlayer, newPlayer)

end

--[[
	@doc
	@fname HUDCommonsBase:MimicEnd
	@args Player oldPlayer, Player newPlayer

	@client

	@desc
	that's a hook! override it if you want to.
	@enddesc
]]
function meta:MimicEnd(oldPlayer, newPlayer)

end

--[[
	@doc
	@fname HUDCommonsBase:SelectPlayer

	@client
	@returns
	Player
]]
function meta:SelectPlayer()
	if IsValid(self.mimic) then
		return self.mimic
	end

	return HUDCommons.SelectPlayer()
end

meta.LocalPlayer = meta.SelectPlayer
meta.GetPlayer = meta.SelectPlayer

--[[
	@doc
	@fname HUDCommonsBase:TickLogic
	@args Player ply

	@client
	@internal
]]
function meta:TickLogic(lPly)
	local wep = self:GetWeapon()

	if self.currWeaponTrack ~= wep then
		self:CallOnWeaponChanged(self.currWeaponTrack, wep)
		self:OnWeaponChanged(self.currWeaponTrack, wep)
		self.prevWeapon = self.currWeaponTrack
		self.currWeaponTrack = wep
	end
end

--[[
	@doc
	@fname HUDCommonsBase:ThinkLogic
	@args Player ply

	@client
	@internal
]]
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

--[[
	@doc
	@fname HUDCommonsBase:OnGlitchStart
	@args number timeLong

	@client

	@desc
	that's a hook! override it if you want to.
	@enddesc
]]
function meta:OnGlitchStart(timeLong)

end

--[[
	@doc
	@fname HUDCommonsBase:OnGlitchEnd

	@client

	@desc
	that's a hook! override it if you want to.
	@enddesc
]]
function meta:OnGlitchEnd()

end

--[[
	@doc
	@fname HUDCommonsBase:TriggerGlitch
	@args number timeLong

	@client

	@desc
	forces a HUD to glitch.
	does nothing if HUD does not support glitching.
	@enddesc
]]
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

--[[
	@doc
	@fname HUDCommonsBase:ExtendGlitch
	@args number timeLong

	@client

	@desc
	extends current glitch or starts a new one if not glitching.
	does nothing if HUD does not support glitching.
	@enddesc
]]
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

--[[
	@doc
	@fname HUDCommonsBase:ClampGlitchTime
	@args number maximal

	@client

	@desc
	clamps current glitch time to given amount of seconds starting from now
	@enddesc
]]
function meta:ClampGlitchTime(maximal)
	local old = self.glitchEnd
	self.glitchEnd = self.glitchEnd:min(CurTimeL() + maximal)
	return self.glitchEnd ~= old
end

--[[
	@doc
	@fname HUDCommonsBase:GlitchTimeRemaining
	@client

	@returns
	number
]]
function meta:GlitchTimeRemaining()
	return math.max(0, self.glitchEnd - CurTimeL())
end

--[[
	@doc
	@fname HUDCommonsBase:GlitchingSince
	@client

	@returns
	number
]]
function meta:GlitchingSince()
	return self.glitchingSince
end

--[[
	@doc
	@fname HUDCommonsBase:GlitchingFor
	@client

	@returns
	number
]]
function meta:GlitchingFor()
	return CurTimeL() - self.glitchingSince
end

--[[
	@doc
	@fname HUDCommonsBase:IsGlitching
	@client

	@returns
	boolean
]]
function meta:IsGlitching()
	return self.glitching
end

--[[
	@doc
	@fname HUDCommonsBase:OnWeaponChanged
	@args Weapon old, Weapon new

	@client

	@desc
	that's a hook! override it if you want to.
	@enddesc
]]
function meta:OnWeaponChanged(old, new)

end

--[[
	@doc
	@fname HUDCommonsBase:DrawWeaponSelection
	@args Weapon wep

	@client
	@internal
]]
function meta:DrawWeaponSelection(wep)
	self.tryToSelectWeapon = wep

	if self.tryToSelectWeaponLast < RealTimeL() then
		self.tryToSelectWeaponFadeIn = RealTimeL() + 0.5
	end

	self.tryToSelectWeaponLast = RealTimeL() + 0.75
	self.tryToSelectWeaponLastEnd = RealTimeL() + 1.25
end
