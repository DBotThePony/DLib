
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

local type = type
local pairs = pairs
local debug = debug
local util = util
local DLib = DLib
local concommand = concommand
local game = game

local blacklist = {
	'_VERSION',
	'VERSION',
	'jit',
	'DLib'
}

local function dump()
	local constants = {}
	local functions = {}
	local libs = {}

	for k, v in pairs(_G) do
		if not table.qhasValue(blacklist, k) then
			if type(v) == 'number' then
				constants[k] = v
			elseif type(v) == 'string' then
				constants[k] = v
			elseif type(v) == 'function' then
				local info = debug.getinfo(v)

				if info.short_src == '[C]' then
					functions[k] = '[C]'
				else
					local crc = util.CRC(string.dump(v))
					functions[k] = crc
				end
			elseif type(v) == 'table' and k ~= '_G' then
				libs[k] = libs[k] or {}

				for k2, v2 in pairs(v) do
					if type(v2) == 'function' then
						local info = debug.getinfo(v2)

						if info.short_src == '[C]' then
							libs[k][k2] = '[C]'
						else
							local crc = util.CRC(string.dump(v2))
							libs[k][k2] = crc
						end
					end
				end
			end
		end
	end

	local registries = {}

	for k, v in pairs(debug.getregistry()) do
		if type(v) == 'table' and v.MetaName then
			registries[v.MetaName] = registries[v.MetaName] or {}

			for key, value in pairs(v) do
				if type(value) == 'function' then
					local info = debug.getinfo(value)

					if info.short_src == '[C]' then
						registries[v.MetaName][key] = '[C]'
					else
						local crc = util.CRC(string.dump(value))
						registries[v.MetaName][key] = crc
					end
				end
			end
		end
	end

	return util.TableToJSON({
		constants = constants,
		registries = registries,
		functions = functions,
		libs = libs,
	})
end

local sv_allowcslua = GetConVar('sv_allowcslua')

local function allow()
	return game.SinglePlayer() or DLib.DEBUG_MODE:GetBool() and sv_allowcslua:GetBool()
end

if SERVER then
	concommand.Add('dlib_registry_dump', function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end
		if not allow() then return end
		file.Write('registry_dump.txt', dump())
		DLib.MessagePlayer(ply, 'Registry dumped into data/registry_dump.txt on the server')
	end)
else
	concommand.Add('dlib_registry_dump_cl', function(ply)
		if not allow() then return end
		file.Write('registry_dump_cl.txt', dump())
		DLib.Message('Registry dumped into data/registry_dump_cl.txt')
	end)
end
