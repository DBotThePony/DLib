
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
local plyMeta = FindMetaTable('Player')

local SteamID64 = plyMeta.SteamID64
local IsBot = plyMeta.IsBot

local isstring = isstring
local isbool = isbool
local isnumber = isnumber
local error = error
local type = type
local sql = sql

local Vector_Unpack = FindMetaTable('Vector').Unpack
local Angle_Unpack = FindMetaTable('Angle').Unpack
local IsColor = IsColor
local luatype = luatype
local string_rep = string.rep
local string_byte = string.byte
local math_min = math.min
local table_concat = table.concat
local tonumber = tonumber
local Vector = Vector
local Angle = Angle
local Color = Color

local string_gsub = string.gsub
local string_format = string.format
local string_find = string.find
local Query = sql.Query

sql.Query([[
	CREATE TABLE IF NOT EXISTS `dlib_pdata_string` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`value` TEXT NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);

	CREATE TABLE IF NOT EXISTS `dlib_pdata_integer` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`value` INTEGER NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);

	CREATE TABLE IF NOT EXISTS `dlib_pdata_real` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`value` REAL NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);

	CREATE TABLE IF NOT EXISTS `dlib_pdata_boolean` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`value` INTEGER NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);

	CREATE TABLE IF NOT EXISTS `dlib_pdata_vector` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`x` REAL NOT NULL,
		`y` REAL NOT NULL,
		`z` REAL NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);

	CREATE TABLE IF NOT EXISTS `dlib_pdata_angle` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`p` REAL NOT NULL,
		`y` REAL NOT NULL,
		`r` REAL NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);

	CREATE TABLE IF NOT EXISTS `dlib_pdata_color` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`r` INTEGER NOT NULL,
		`g` INTEGER NOT NULL,
		`b` INTEGER NOT NULL,
		`a` INTEGER NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);

	CREATE TABLE IF NOT EXISTS `dlib_pdata_blob` (
		`steamid` INTEGER NOT NULL,
		`key` TEXT NOT NULL,
		`value` BLOB NOT NULL,
		PRIMARY KEY (`steamid`, `key`)
	);
]])

local function SQLStr(value)
	return string_format("'%s'", string_gsub(value, "'", "''"))
end

function plyMeta:DLibSetPDataString(index, value)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if not isstring(value) then
		error('Bad value, it must be a string. typeof ' .. type(value), 2)
	end

	if string_find(value, '\x00', 1, true) then
		error('Value contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_string

		if not data then
			data = {}
			self.dlib_pdata_string = data
		end

		data[index] = value

		return value
	end

	local status = Query(string_format('REPLACE INTO `dlib_pdata_string` VALUES (%s, %s, %s)', SQLStr(SteamID64(self)), SQLStr(index), SQLStr(value)))

	if status == false then
		error(sql.LastError())
	end

	return value
end

function plyMeta:DLibSetPDataInt(index, value)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if not isnumber(value) then
		error('Bad value, it must be a number. typeof ' .. type(value), 2)
	end

	if IsBot(self) then
		local data = self.dlib_pdata_integer

		if not data then
			data = {}
			self.dlib_pdata_integer = data
		end

		data[index] = value

		return value
	end

	local status = Query(string_format('REPLACE INTO `dlib_pdata_integer` VALUES (%s, %s, %d)', SQLStr(SteamID64(self)), SQLStr(index), value))

	if status == false then
		error(sql.LastError())
	end

	return value
end

function plyMeta:DLibSetPDataFloat(index, value)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if not isnumber(value) then
		error('Bad value, it must be a number. typeof ' .. type(value), 2)
	end

	if IsBot(self) then
		local data = self.dlib_pdata_real

		if not data then
			data = {}
			self.dlib_pdata_real = data
		end

		data[index] = value

		return value
	end

	local status = Query(string_format('REPLACE INTO `dlib_pdata_real` VALUES (%s, %s, %f)', SQLStr(SteamID64(self)), SQLStr(index), value))

	if status == false then
		error(sql.LastError())
	end

	return value
end

function plyMeta:DLibSetPDataBoolean(index, value)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if not isbool(value) then
		error('Bad value, it must be a boolean. typeof ' .. type(value), 2)
	end

	if IsBot(self) then
		local data = self.dlib_pdata_boolean

		if not data then
			data = {}
			self.dlib_pdata_boolean = data
		end

		data[index] = value

		return value
	end

	local status = Query(string_format('REPLACE INTO `dlib_pdata_boolean` VALUES (%s, %s, %d)', SQLStr(SteamID64(self)), SQLStr(index), value and 1 or 0))

	if status == false then
		error(sql.LastError())
	end

	return value
end

function plyMeta:DLibSetPDataVector(index, value)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if type(value) ~= 'Vector' then
		error('Bad value, it must be a Vector. typeof ' .. type(value), 2)
	end

	if IsBot(self) then
		local data = self.dlib_pdata_vector

		if not data then
			data = {}
			self.dlib_pdata_vector = data
		end

		data[index] = Vector(value)

		return value
	end

	local x, y, z = Vector_Unpack(value)

	local status = Query(string_format('REPLACE INTO `dlib_pdata_vector` VALUES (%s, %s, %f, %f, %f)', SQLStr(SteamID64(self)), SQLStr(index), x, y, z))

	if status == false then
		error(sql.LastError())
	end

	return value
end

function plyMeta:DLibSetPDataAngle(index, value)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if type(value) ~= 'Angle' then
		error('Bad value, it must be a Angle. typeof ' .. type(value), 2)
	end

	if IsBot(self) then
		local data = self.dlib_pdata_angle

		if not data then
			data = {}
			self.dlib_pdata_angle = data
		end

		data[index] = Angle(value)

		return value
	end

	local x, y, z = Angle_Unpack(value)

	local status = Query(string_format('REPLACE INTO `dlib_pdata_angle` VALUES (%s, %s, %f, %f, %f)', SQLStr(SteamID64(self)), SQLStr(index), x, y, z))

	if status == false then
		error(sql.LastError())
	end

	return value
end

function plyMeta:DLibSetPDataColor(index, value)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if not IsColor(value) then
		error('Bad value, it must be a Color. typeof ' .. luatype(value), 2)
	end

	if IsBot(self) then
		local data = self.dlib_pdata_color

		if not data then
			data = {}
			self.dlib_pdata_color = data
		end

		data[index] = Color(value)

		return value
	end

	local x, y, z, a = value.r, value.g, value.b, value.a

	local status = Query(string_format('REPLACE INTO `dlib_pdata_color` VALUES (%s, %s, %d, %d, %d, %d)', SQLStr(SteamID64(self)), SQLStr(index), x, y, z, a))

	if status == false then
		error(sql.LastError())
	end

	return value
end

function plyMeta:DLibSetPDataBinary(index, valueOriginal)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if not isstring(valueOriginal) then
		error('Bad value, it must be a string. typeof ' .. luatype(valueOriginal), 2)
	end

	if IsBot(self) then
		local data = self.dlib_pdata_blob

		if not data then
			data = {}
			self.dlib_pdata_blob = data
		end

		data[index] = value

		return value
	end

	local value
	local valueLen = #valueOriginal

	if valueLen < 7996 then
		value = string_format(string_rep('%.2X', valueLen), string_byte(valueOriginal, 1, valueLen))
	else
		value = {}
		local index = 0

		for i = 1, valueLen, 7996 do
			index = index + 1
			local final = math_min(valueLen, i + 7995)
			local length = final - i
			value[index] = string_format(string_rep('%.2X', length + 1), string_byte(valueOriginal, i, final))
		end

		value = table_concat(value, '')
	end

	local status = Query(string_format("REPLACE INTO `dlib_pdata_blob` VALUES (%s, %s, x'%s')", SQLStr(SteamID64(self)), SQLStr(index), value))

	if status == false then
		error(sql.LastError())
	end

	return value
end

plyMeta.DLibSetPDataBlob = plyMeta.DLibSetPDataBinary

function plyMeta:DLibGetPDataString(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_string
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return value
	end

	-- LIMIT 1 tells database to not look for values any further
	-- improving performance
	local data = Query(string_format('SELECT `value` FROM `dlib_pdata_string` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	return data[1].value
end

function plyMeta:DLibRemovePDataString(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_string
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_string` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

function plyMeta:DLibGetPDataInt(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_integer
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return value
	end

	local data = Query(string_format('SELECT `value` FROM `dlib_pdata_integer` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	return tonumber(data[1].value)
end

function plyMeta:DLibRemovePDataInt(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_integer
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_integer` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

function plyMeta:DLibGetPDataFloat(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_real
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return value
	end

	local data = Query(string_format('SELECT `value` FROM `dlib_pdata_real` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	return tonumber(data[1].value)
end

function plyMeta:DLibRemovePDataFloat(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_real
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_real` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

function plyMeta:DLibGetPDataBoolean(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_boolean
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return value
	end

	local data = Query(string_format('SELECT `value` FROM `dlib_pdata_boolean` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	return data[1].value == "1"
end

function plyMeta:DLibRemovePDataBoolean(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_boolean
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_boolean` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

function plyMeta:DLibGetPDataVector(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_vector
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return Vector(value)
	end

	local data = Query(string_format('SELECT `x`, `y`, `z` FROM `dlib_pdata_vector` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	local row = data[1]
	return Vector(row.x, row.y, row.z)
end

function plyMeta:DLibRemovePDataVector(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_vector
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_vector` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

function plyMeta:DLibGetPDataAngle(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_angle
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return Angle(value)
	end

	local data = Query(string_format('SELECT `p`, `y`, `r` FROM `dlib_pdata_angle` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	local row = data[1]
	return Angle(row.p, row.y, row.r)
end

function plyMeta:DLibRemovePDataAngle(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_angle
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_angle` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

function plyMeta:DLibGetPDataColor(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_color
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return Color(value)
	end

	local data = Query(string_format('SELECT `r`, `g`, `b`, `a` FROM `dlib_pdata_color` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	local row = data[1]
	return Color(row.r, row.g, row.b, row.a)
end

function plyMeta:DLibRemovePDataColor(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_color
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_color` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

local function replaceHex(value)
	return '\\x' .. value
end

local CompileString = CompileString

function plyMeta:DLibGetPDataBinary(index, ifNotFound)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_blob
		if not data then return ifNotFound end

		local value = data[index]
		if value == nil then return ifNotFound end

		return value
	end

	local data = Query(string_format('SELECT hex(`value`) AS `value` FROM `dlib_pdata_blob` WHERE `steamid` = %s AND `key` = %s LIMIT 1', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == nil then
		return ifNotFound
	end

	if not data then
		error(sql.LastError())
	end

	return CompileString(string_format('return "%s"', string_gsub(data[1].value, '..', replaceHex)), 'Player:DLibGetPDataBinary')()
end

function plyMeta:DLibRemovePDataBinary(index)
	if not isstring(index) then
		error('Bad index, it must be a string. typeof ' .. type(index), 2)
	end

	if string_find(index, '\x00', 1, true) then
		error('Index contain NUL byte')
	end

	if IsBot(self) then
		local data = self.dlib_pdata_blob
		if not data then return end

		data[index] = nil

		return
	end

	local data = Query(string_format('DELETE FROM `dlib_pdata_blob` WHERE `steamid` = %s AND `key` = %s', SQLStr(SteamID64(self)), SQLStr(index)))

	if data == false then
		error(sql.LastError())
	end
end

plyMeta.DLibGetPDataBlob = plyMeta.DLibGetPDataBinary
plyMeta.DLibRemovePDataBlob = plyMeta.DLibRemovePDataBinary
plyMeta.DLibRemovePData = plyMeta.DLibRemovePDataBinary

function plyMeta:DLibSetPData(index, value)
	self:DLibSetPDataBlob(index, DLib.GON.Serialize(value):ToString())
	return value
end

function plyMeta:DLibGetPData(index, ifNotFound)
	local value = self:DLibGetPDataBlob(index)

	if value == nil then
		return ifNotFound
	end

	return DLib.GON.Deserialize(DLib.BytesBuffer(value))
end
