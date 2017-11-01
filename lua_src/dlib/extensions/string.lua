
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

local string = DLib.module('string', 'string')

function string.tformat(time)
	local str = ''

	local weeks = (time - time % 604800) / 604800
	time = time - weeks * 604800

	local days = (time - time % 86400) / 86400
	time = time - days * 86400

	local hours = (time - time % 3600) / 3600
	time = time - hours * 3600

	local minutes = (time - time % 60) / 60
	time = time - minutes * 60

	local seconds = math.floor(time)

	if seconds ~= 0 then
		str = seconds .. ' seconds'
	end

	if minutes ~= 0 then
		str = minutes .. ' minutes ' .. str
	end

	if hours ~= 0 then
		str = hours .. ' hours ' .. str
	end

	if days ~= 0 then
		str = days .. ' days ' .. str
	end

	if weeks ~= 0 then
		str = weeks .. ' weeks ' .. str
	end

	return str
end

function string.qdate(time)
	return os.date('%H:%M:%S - %d/%m/%Y', time)
end

string.HU_IN_M = 40
string.HU_IN_CM = string.HU_IN_M / 100

function string.ddistance(z, newline, from)
	if newline == nil then
		newline = true
	end

	local delta

	if from then
		delta = from - z
	else
		delta = LocalPlayer():GetPos().z - z
	end

	if delta > 200 and not newline then
		return string.fdistance(delta) .. ' lower'
	end

	if delta > 200 and newline then
		return '\n' .. string.fdistance(delta) .. ' lower'
	end

	if -delta > 200 and not newline then
		return string.fdistance(delta) .. 'upper'
	end

	if -delta > 200 and newline then
		return '\n' .. string.fdistance(delta) .. 'upper'
	end

	return ''
end

function string.fdistance(m)
	return string.format('%.1fm', m / string.HU_IN_M)
end

function string.niceName(ent)
	if not IsValid(ent) then return '' end
	if ent.Nick then return ent:Nick() end
	if ent.PrintName and ent.PrintName ~= '' then return ent.PrintName end
	if ent.GetPrintName then return ent:GetPrintName() end
	return ent:GetClass()
end

function string.split(stringIn, explodeIn, ...)
	return string.Explode(explodeIn, stringIn, ...)
end

-- fuck https://github.com/Facepunch/garrysmod/pull/1176
string.StartsWith = string.StartWith

return string
