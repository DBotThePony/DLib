
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


local dump = SERVER and include('dump.lua') or {}
local dump_cl = CLIENT and include('dump_cl.lua') or {}
AddCSLuaFile('dump_cl.lua')

local table = table
local pairs = pairs
local hook = hook
local debug = debug
local scripted_ents = scripted_ents
local weapons = weapons
local string = string
local jit = jit
local system = system
local DLib = DLib
local CurTimeL = CurTimeL
local SysTime = SysTime
local ScrWL = ScrWL
local ScrHL = ScrHL
local collectgarbage = collectgarbage
local ipairs = ipairs

local function hashfunc(func)
	if type(func) ~= 'function' then return 'FUNCTION IS MISSING' end

	local info = debug.getinfo(func)
	local crc

	if info.short_src == '[C]' then
		crc = '[C]'
	else
		crc = util.CRC(string.dump(func))
	end

	return crc, info.short_src:startsWith('dlib/')
		or info.short_src:startsWith('addons/dlib/')
		or info.short_src:startsWith('lua/dlib/')
		or info.short_src:find('dlib/modules')
		or info.short_src:find('dlib/luabridge')
		or info.short_src:find('dlib/extensions')
		or info.short_src:find('dlib/core')
		or info.short_src:find('lua/dlib')
		or info.short_src:find('VLL: dlib')
end

local function getFuncInfo(func)
	if type(func) ~= 'function' then return '<none>' end

	local info = debug.getinfo(func)

	return string.format(
		'at %p (%s: %i->%i)',
		func,
		info.source,
		info.linedefined,
		info.lastlinedefined
	)
end

local function generate()
	local lines = {
		'\n\n/// DLib Report about Garry\'s Mod Information',
		'/// Dumped at ' .. os.date('%A %H:%M:%S %d.%m.%Y', os.time()) .. '\n',
		'/// SIDE: ' .. (CLIENT and 'CLIENT' or 'SERVER') .. '\n',
	}

	table.insert(lines, 'Garry\'s mod version: ' .. VERSIONSTR)
	table.insert(lines, 'Numeric: ' .. VERSION)
	table.insert(lines, _VERSION)
	table.insert(lines, jit.version)
	table.insert(lines, 'Arhitecture: ' .. jit.arch)
	table.insert(lines, 'JIT Status: ' .. (select(1, jit.status()) and 'enabled' or 'DISABLED!'))

	do
		local values = {jit.status()}
		table.remove(values, 1)
		table.insert(lines, 'JIT Specific optimizations: ' .. table.concat(values, ' '))
	end

	table.insert(lines, 'system.GetCountry(): ' .. tostring(system.GetCountry()))
	table.insert(lines, 'system.IsWindows(): ' .. tostring(system.IsWindows()))
	table.insert(lines, 'system.IsLinux(): ' .. tostring(system.IsLinux()))
	table.insert(lines, 'system.IsOSX(): ' .. tostring(system.IsOSX()))

	if CLIENT then
		table.insert(lines, 'system.IsWindowed(): ' .. tostring(system.IsWindowed()))
	else
		table.insert(lines, 'system.IsWindowed(): (yes)')
	end

	table.insert(lines, 'CurTime(): ' .. DLib.string.tformat(CurTimeL()))
	table.insert(lines, 'SysTime(): ' .. DLib.string.tformat(SysTime()))

	if CurTimeL() > 21600 then
		table.insert(lines, 'Uptime is too big! Server restart is required!')
	end

	if CLIENT then
		table.insert(lines, 'Screen size: ' .. ScrWL() .. 'x' .. ScrHL())
	end

	table.insert(lines, '\nDedicated status: ' .. tostring(game.IsDedicated()))
	table.insert(lines, 'Max players: ' .. tostring(game.MaxPlayers()))
	table.insert(lines, 'Current map: ' .. tostring(game.GetMap()))

	local ram1 = collectgarbage("count")
	collectgarbage()
	local ram2 = collectgarbage("count")

	table.insert(lines, string.format('\nLuaVM Memory usage before GC: %.2f megabytes', ram1 / 1024))
	table.insert(lines, string.format('LuaVM Memory usage after GC: %.2f megabytes', ram2 / 1024))

	if ram2 > 1024 * 1024 * 200 then
		table.insert(lines, 'LuaVM Memory usage is very high! Consider removing addons or optimizing existing code.')
	end

	table.insert(lines, '\n///// Begin hook dump')
	table.insert(lines, hook.GetDumpStr())
	table.insert(lines, '///// End hook dump')

	table.insert(lines, '///// Begin dump of registered entities')

	local llines = {}
	local entsList = scripted_ents.GetList()

	for classname, data in pairs(entsList) do
		table.insert(llines, '\t' .. classname .. ' (Base class: ' .. (data.Base or '<NONE?!>') .. '; Base class is ' .. (entsList[data.Base] and 'valid' or 'INVALID!!!') .. ')')
	end

	table.sort(llines)
	table.append(lines, llines)

	table.insert(lines, '///// End dump of registered entities')

	table.insert(lines, '///// Begin dump of registered weapons')

	llines = {}
	local weaponry = {}

	for i, data in pairs(weapons.GetList()) do
		weaponry[data.ClassName] = data
	end

	for classname, data in pairs(weaponry) do
		table.insert(llines, '\t' .. classname .. ' (Base class: ' .. (data.Base or '<none?!>') .. '; Base class is ' .. (weaponry[data.Base] and 'valid' or 'INVALID!!!') .. ')')
	end

	table.sort(llines)
	table.append(lines, llines)

	table.insert(lines, '///// End dump of registered weapons')

	table.insert(lines, '\n///// Scanning for replaced vanilla constants')

	local pick_dump = CLIENT and dump_cl or dump
	llines = {}

	for key, value in pairs(pick_dump.constants) do
		if _G[key] ~= value then
			table.insert(llines, string.format('\tCONSTANT MISMATCH AT %q: Expected %q but got %q; (%q vs %q)', key, value, tostring(_G[key]), type(value), type(_G[key])))
		end
	end

	if #llines ~= 0 then
		table.sort(llines)
		table.append(lines, llines)
	else
		table.insert(lines, '\tNone found.')
	end

	table.insert(lines, '\n///// Scanning for replaced vanilla functions')

	llines = {}

	for key, value in pairs(pick_dump.functions) do
		local crc, dlib = hashfunc(_G[key])

		if not dlib and crc ~= value then
			table.insert(llines, string.format('\tFUNCTION %q IS REPLACED: Expected %q, got %q; %s', key, value, crc, getFuncInfo(_G[key])))
		end
	end

	if #llines ~= 0 then
		table.sort(llines)
		table.append(lines, llines)
	else
		table.insert(lines, '\tNone found.')
	end

	table.insert(lines, '\n///// Scanning for replaced vanilla functions in libraries/global tables')

	llines = {}

	for libname, libvalue in pairs(pick_dump.libs) do
		if type(_G[libname]) ~= 'table' then
			table.insert(llines, string.format('\tLIBRARY IS MISSING! %q: Got %q; (%q vs %q)', libname, tostring(_G[libname]), type(value), type(_G[libname])))
		else
			local glib = _G[libname]

			for funcname, value in pairs(libvalue) do
				local crc, dlib = hashfunc(glib[funcname])

				if not dlib and crc ~= value then
					table.insert(llines, string.format('\tLIBRARY %q; FUNCTION %q IS REPLACED: Expected %q, got %q; %s', libname, funcname, value, crc, getFuncInfo(glib[funcname])))
				end
			end
		end
	end

	if #llines ~= 0 then
		table.sort(llines)
		table.append(lines, llines)
	else
		table.insert(lines, '\tNone found.')
	end

	table.insert(lines, '\n///// Scanning for registries')

	llines = {}

	local registry = debug.getregistry()
	local dump_registry = pick_dump.registries
	local foundResgistry = {}

	for k, v in pairs(registry) do
		if type(v) == 'table' and v.MetaName then
			if not dump_registry[v.MetaName] then
				table.insert(llines, '\tNon standart registry: ' .. v.MetaName)
			end

			foundResgistry[v.MetaName] = v
		end
	end

	for k, funclist in pairs(dump_registry) do
		if not foundResgistry[k] then
			table.insert(llines, string.format('\tREGISTRY %q IS MISSING!', k))
		else
			local glib = foundResgistry[k]

			for funcname, value in pairs(funclist) do
				local crc, dlib = hashfunc(glib[funcname])

				if not dlib and crc ~= value then
					table.insert(llines, string.format('\tRESITRY %q; FUNCTION %q IS REPLACED: Expected %q, got %q; %s', k, funcname, value, crc, getFuncInfo(glib[funcname])))
				end
			end

			for funcname, value in pairs(glib) do
				if type(value) == 'function' and not funclist[funcname] then
					local crc, dlib = hashfunc(value)

					if not dlib then
						table.insert(llines, string.format('\tRESITRY %q; Non default function %q: got %q; %s', k, funcname, crc, getFuncInfo(value)))
					end
				end
			end
		end
	end

	if #llines ~= 0 then
		table.sort(llines)
		table.append(lines, llines)
	else
		table.insert(lines, '\tNone mismatches found.')
	end

	table.insert(lines, '\n// Registry generic information')
	local funcs = 0
	local tables = 0
	local objects = 0

	for i, value in ipairs(registry) do
		if type(value) == 'function' then
			funcs = funcs + 1
		elseif type(value) == 'table' then
			tables = tables + 1
		else
			objects = objects
		end
	end

	table.insert(lines, funcs .. ' functions in total')
	table.insert(lines, tables .. ' tables in total')
	table.insert(lines, objects .. ' objects in total')
	table.insert(lines, 'Size of registry: ' .. #registry .. ' entries')

	table.insert(lines, '\n// addons/ folders')
	local files, folders = file.Find('addons/*', 'GAME')

	if #folders == 0 then
		table.insert(lines, '\tNone')
	else
		table.append(lines, table.prependString(folders, '\t'))
	end

	if #folders > 14 then
		table.insert(lines, '\nThere are more than 13 folders in addons/. Consider to combine them\nor remove if possible, because they have GREAT impact on game load time,\nincluding server\'s impact on client')
	end

	table.insert(lines, '\n// addons/ files (gma only)')

	if #files == 0 then
		table.insert(lines, '\tNone (?!)')
	else
		local found = false

		for i, fil in ipairs(files) do
			if fil:find('.gma') then
				found = true
				table.insert(lines, '\t' .. fil)
			end
		end

		if not found then
			table.insert(lines, '\tNone (?!)')
		elseif #files > 380 then
			table.insert(lines, 'the fuck')
		end
	end

	table.insert(lines, '///// END OF REPORT\n')

	return lines
end

local file = file
local concommand = concommand

file.mkdir('dlib_reports')

if CLIENT then
	concommand.Add('dlib_gen_report_cl', function()
		local stamp = os.date('%H-%M-%S_%d_%m_%Y', os.time())
		local path = 'dlib_reports/client_' .. stamp .. '.txt'
		local handle = file.Open(path, 'wb', 'DATA')
		local dump = generate()

		for i, line in ipairs(dump) do
			handle:Write(line .. '\n')
		end

		handle:Close()

		DLib.Message('Report saved onto ' .. path)
	end)
else
	concommand.Add('dlib_gen_report', function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end
		local stamp = os.date('%H-%M-%S_%d_%m_%Y', os.time())
		local path = 'dlib_reports/server_' .. stamp .. '.txt'
		local handle = file.Open(path, 'wb', 'DATA')
		local dump = generate()

		for i, line in ipairs(dump) do
			handle:Write(line .. '\n')
		end

		handle:Close()

		DLib.MessagePlayer(ply, 'Report saved onto ' .. path .. ' on the server')
	end)
end
