
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

if SERVER then
	net.pool('DLib.physgun.player')
	net.pool('DLib.physgun.playerAngles')
end

local ply, ent, holder, holderStatus

local function PhysgunPickup(Uply, Uent)
	ply, ent = Uply, Uent
end

local function PhysgunDrop(Uply, Uent)
	local target = Uply.__dlibPhysgunHandler

	if SERVER and IsValid(target) then
		net.Start('DLib.physgun.player')
		net.WriteBool(false)
		net.Send(target)
	end

	Uply.__dlibPhysgunHandler = nil
	Uply.__dlibPhysgunHolder = nil
	Uply.__dlibUpcomingEyeAngles = nil

	Uent.__dlibPhysgunHandler = nil
	Uent.__dlibPhysgunHolder = nil
	Uent.__dlibUpcomingEyeAngles = nil
end

-- Lets handle this mess by ourself
-- as admin addons doesnt even care
local function PlayerNoClip(ply)
	if CLIENT and holderStatus and IsValid(holder) then
		return false
	elseif SERVER and IsValid(ply.__dlibPhysgunHolder) then
		return false
	end
end

local function PhysgunPickupPost(status)
	if not IsValid(ply) or not IsValid(ent) then return status end
	if not ent:IsPlayer() then return status end

	if status then
		ply.__dlibPhysgunHandler = ent
		ent.__dlibPhysgunHolder = ply

		if SERVER then
			net.Start('DLib.physgun.player')
			net.WriteBool(true)
			net.WritePlayer(ply)
			net.Send(ent)
		end
	end

	return status
end

local function StartCommand(ply, cmd)
	if CLIENT and holderStatus and IsValid(holder) then
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
	end

	if SERVER and IsValid(ply.__dlibPhysgunHolder) then
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
		local ang = ply.__dlibUpcomingEyeAngles or ply:EyeAngles()
		cmd:SetViewAngles(ang)

		net.Start('DLib.physgun.playerAngles', true)
		net.WriteAngle(ang)
		net.Send(ply)

		return
	end

	local target = ply.__dlibPhysgunHandler
	if not IsValid(target) then return end
	if not cmd:KeyDown(IN_USE) then return end
	local x, y = cmd:GetMouseX() / 4, cmd:GetMouseY() / 7

	if x ~= 0 or y ~= 0 then
		if SERVER then
			cmd:SetMouseX(0)
			cmd:SetMouseY(0)
		end

		local ang = target:EyeAngles()
		ang.p = ang.p + y
		ang.y = ang.y + x
		ang:Normalize()
		-- target:SetEyeAngles(ang)
		target.__dlibUpcomingEyeAngles = ang
	end
end

if CLIENT then
	net.receive('DLib.physgun.player', function()
		holderStatus = net.ReadBool()

		if holderStatus then
			holder = net.ReadPlayer()
		else
			holder = NULL
		end
	end)

	net.receive('DLib.physgun.playerAngles', function()
		LocalPlayer():SetEyeAngles(net.ReadAngle())
	end)
end

hook.Add('StartCommand', 'DLib.PhysgunModifier', StartCommand, -10)
hook.Add('PhysgunPickup', 'DLib.PhysgunModifier', PhysgunPickup, -10)
hook.Add('PhysgunDrop', 'DLib.PhysgunModifier', PhysgunDrop, -10)
hook.Add('PlayerNoClip', 'DLib.PhysgunModifier', PlayerNoClip, -10)
hook.Add('CanPlayerEnterVehicle', 'DLib.PhysgunModifier', PlayerNoClip, -10)
hook.AddPostModifier('PhysgunPickup', 'DLib.PhysgunModifier', PhysgunPickupPost)
