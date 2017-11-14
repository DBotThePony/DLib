
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

jit.on()

local util = DLib.module('util', 'util')
local DLib = DLib
local vgui = vgui
local type = type
local ipairs = ipairs
local IsValid = IsValid

function DLib.VCreate(pnlName, pnlParent)
	if not IsValid(pnlParent) then
		DLib.Message(debug.traceback('Attempt to create ' .. pnlName .. ' without valid parent!'))
		return
	end

	return vgui.Create(pnlName, pnlParent)
end

function util.copy(var)
	if type(var) == 'table' then return table.Copy(var) end
	if type(var) == 'Angle' then return Angle(var.p, var.y, var.r) end
	if type(var) == 'Vector' then return Vector(var) end
	return var
end

function util.randomVector(mx, my, mz)
	return Vector(math.Rand(-mx, mx), math.Rand(-my, my), math.Rand(-mz, mz))
end

function util.composeEnums(input, ...)
	local num = 0

	if type(input) == 'table' then
		for k, v in ipairs(input) do
			num = num:bor(v)
		end
	else
		num = input
	end

	return num:bor(...)
end

function util.AccessorFuncJIT(target, variable, name)
	local set, get = CompileString([==[
		local variable = [[]==] .. variable .. [==[]]

		local function Set(self, newVar)
			self.]==] .. variable .. [==[ = newVar

			local callback = self.OnDVariableChange

			if callback then
				callback(self, variable, newVar)
			end

			callback = self.On]==] .. name .. [==[Changes

			if callback then
				callback(self, newVar)
			end

			return self
		end

		local function Get(self)
			return self.]==] .. variable .. [==[
		end

		return Set, Get
	]==], 'DLib.util.AccessorFuncJIT')()

	target['Get' .. name] = get
	target['Set' .. name] = set
end

function util.ValidateSteamID(input)
	if not input then return false end
	return input:match('STEAM_0:[0-1]:[0-9]+$') ~= nil
end

function util.SteamLink(steamid)
	if util.ValidateSteamID(steamid) then
		return 'https://steamcommunity.com/profiles/' .. util.SteamIDTo64(steamid) .. '/'
	else
		return 'https://steamcommunity.com/profiles/' .. steamid .. '/'
	end
end

function util.CreateSharedConvar(cvarname, cvarvalue, description)
	if CLIENT then
		return CreateConVar(cvarname, cvarvalue, {FCVAR_REPLICATED}, description)
	else
		return CreateConVar(cvarname, cvarvalue, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, description)
	end
end

return util
