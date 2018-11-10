
--[[
Copyright (C) 2016-2018 DBot


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


TMySQL4: https://facepunch.com/showthread.php?t=1442438
mysqloo: https://facepunch.com/showthread.php?t=1515853
]]

file.CreateDir('dmysql3')

local DefaultOptions = {
	UseMySQL = false,
	Host = 'localhost',
	Database = 'test',
	User = 'user',
	Password = 'pass',
	Port = 3306,
}

local DefaultConfigString = util.TableToJSON(DefaultOptions, true)

if not file.Exists('dmysql3/default.txt', 'DATA') then
	file.Write('dmysql3/default.txt', DefaultConfigString)
else
	local read = file.Read('dmysql3/default.txt', 'DATA')
	local parse = util.JSONToTable(read)
	if not parse then
		file.Write('dmysql3/default.txt', DefaultConfigString)
	else
		DefaultConfigString = read
		DefaultOptions = parse
	end
end

DMySQL3 = DMySQL3 or {}
DLib.DMySQL3 = DMySQL3
DMySQL3.LINKS = DMySQL3.LINKS or {}

DMySQL3.obj = DMySQL3.obj or {}
local obj = DMySQL3.obj
obj.__index = obj

function DMySQL3.WriteConfig(config, data)
	file.Write('dmysql3/' .. config .. '.txt', util.TableToJSON(data, true))
end

function DMySQL3.Connect(config)
	config = config or 'default'

	if DMySQL3.LINKS[config] then
		DMySQL3.LINKS[config]:Disconnect()
		DMySQL3.LINKS[config]:ReloadConfig()
		DMySQL3.LINKS[config]:Connect()
		return DMySQL3.LINKS[config]
	end

	local self = setmetatable({}, obj)
	self.config = config

	self:ReloadConfig()

	DMySQL3.LINKS[config] = self

	self:Connect()

	return self
end

function DMySQL3.ToString(v)
	local t = type(v)
	if t == 'boolean' then
		return v and '1' or '0'
	elseif t == 'table' then
		return util.TableToJSON(v)
	else
		return tostring(v)
	end
end

local function concatNames(tab)
	local str = ''

	for k, v in ipairs(tab) do
		str = str .. ', `' .. v .. '`'
	end

	return str:sub(3)
end

local function concatValues(tab)
	local str = ''

	for k, v in ipairs(tab) do
		local new = DMySQL3.ToString(v)

		str = str .. ', ' .. SQLStr(new)
	end

	return str:sub(3)
end

local function GetValues(tab2)
	local tab = {}

	for k, v in pairs(tab2) do
		table.insert(tab, DMySQL3.ToString(v))
	end

	return tab
end

function DMySQL3.InsertEasy(tab, data)
	local keys = table.GetKeys(data)
	return 'INSERT INTO `' .. tab .. '` (' .. concatNames(keys) .. ') VALUES (' .. concatValues(GetValues(data)) .. ');'
end

function DMySQL3.ReplaceEasy(tab, data)
	local keys = table.GetKeys(data)
	return 'REPLACE INTO `' .. tab .. '` (' .. concatNames(keys) .. ') VALUES (' .. concatValues(GetValues(data)) .. ');'
end

function DMySQL3.Insert(tab, keys, ...)
	local add = ''
	local args = {...}

	local f = true

	for k, v in ipairs(args) do
		if f then
			add = '(' .. concatValues(v) .. ')'
			f = false
		else
			add = add .. ', (' .. concatValues(v) .. ')'
		end
	end

	return 'INSERT INTO `' .. tab .. '` (' .. concatNames(keys) .. ') VALUES ' .. add .. ';'
end

function DMySQL3.Replace(tab, keys, ...)
	local add = ''
	local args = {...}

	local f = true

	for k, v in ipairs(args) do
		if f then
			add = '(' .. concatValues(v) .. ')'
			f = false
		else
			add = add .. ', (' .. concatValues(v) .. ')'
		end
	end

	return 'REPLACE INTO `' .. tab .. '` (' .. concatNames(keys) .. ') VALUES ' .. add .. ';'
end

function DMySQL3.Update(tab, what, where)
	where = where or {}
	local wstr = ''
	local f = true

	for k, v in pairs(what) do
		if f then
			wstr = k .. ' = ' .. SQLStr(v)
			f = false
		else
			wstr = wstr .. ', ' .. k .. ' = ' .. SQLStr(v)
		end
	end

	local whstr = ''
	local f = true

	for k, v in pairs(where) do
		if f then
			whstr = ' WHERE ' .. k .. ' = ' .. SQLStr(v)
			f = false
		else
			whstr = whstr .. ' AND ' .. k .. ' = ' .. SQLStr(v)
		end
	end

	return 'UPDATE `' .. tab .. '` SET ' .. wstr .. whstr
end

local FormatFuncs = {
	'InsertEasy',
	'ReplaceEasy',
	'Insert',
	'Replace',
}

for k, v in ipairs(FormatFuncs) do
	obj[v] = function(self, ...)
		self:Query(DMySQL3[v](...))
	end
end

DLib.CMessage(DMySQL3, 'DMySQL3')

obj.UseMySQL = false
obj.IsMySQL = false
obj.UseTMySQL4 = false
obj.Host = 'localhost'
obj.Database = 'test'
obj.User = 'user'
obj.Password = 'pass'
obj.Port = 3306

local tmsql, moo = file.Exists("bin/gmsv_tmysql4_*", "LUA"), file.Exists("bin/gmsv_mysqloo_*", "LUA")

function obj:Connect()
	if not self.UseMySQL then
		if self.config ~= 'default' then
			DMySQL3.Message(self.config, ': Using SQLite')
		end

		self.IsMySQL = false
		return
	end

	if not tmsql and not moo then
		DMySQL3.Message(self.config, ': No TMySQL4 module installed!\nGet latest at https://facepunch.com/showthread.php?t=1442438')
		DMySQL3.Message(self.config, ': Using SQLite')
		self.IsMySQL = false
		return
	end

	if tmsql then
		local hit = false

		xpcall(function()
			require("tmysql4")

			DMySQL3.Message(self.config, ': Trying to connect to ' .. self.Host .. ' using driver TMySQL4')

			local Link, Error = tmysql.initialize(self.Host, self.User, self.Password, self.Database, self.Port)

			if not Link then
				DMySQL3.Message(self.config, ': connection failed: \nInvalid username or password, wrong hostname or port, database does not exists, or given user can\'t access it.\n' .. Error .. '')
				self.IsMySQL = false
			else
				DMySQL3.Message(self.config, ': Success')
				self.LINK = Link
				self.IsMySQL = true
				self.UseTMySQL4 = true
				hit = true
			end
		end, function(err)
			DMySQL3.Message(self.config, ': connection failed:\nCannot intialize a binary TMySQL4 module (internal error). Are you sure that your installed module for your OS? (linux/windows)\n' .. err .. '')
			self.IsMySQL = false
		end)

		if hit then return end
	end

	if moo then
		DMySQL3.Message('DMySQL3 recommends to use TMySQL4!')

		xpcall(function()
			require("mysqloo")

			DMySQL3.Message(self.config, ': Trying to connect to ' .. self.Host .. ' using driver MySQLoo')
			local Link = mysqloo.connect(self.Host, self.User, self.Password, self.Database, self.Port)

			Link:connect()
			Link:wait()

			local Status = Link:status()

			if Status == mysqloo.DATABASE_CONNECTED then
				DMySQL3.Message(self.config, ': Success')
				self.IsMySQL = true
				self.LINK = Link
			else
				DMySQL3.Message(self.config, ': connection failed: \nInvalid username or password, wrong hostname or port, database does not exists, or given user can\'t access it.')
				DMySQL3.Message(Link:hostInfo())
			end
		end, function(err)
			DMySQL3.Message(self.config, ': connection failed:\nCannot intialize a binary MySQLoo module (internal error). Are you sure that your installed module for your OS? (linux/windows)\n' .. err .. '')
			self.IsMySQL = false
		end)
	end
end

function obj:AI()
	return self.IsMySQL and 'AUTO_INCREMENT' or 'AUTOINCREMENT'
end

function obj:Disconnect()
	DMySQL3.Message(self.config .. ': disconnected from database')
	if not self.IsMySQL then return end
	if self.UseTMySQL4 then
		self.LINK:Disconnect()
		return
	end

	--Put MySQLoo disconnect function here
end

function obj:ReloadConfig()
	local config = self.config

	if not file.Exists('dmysql3/' .. config .. '.txt', 'DATA') then
		file.Write('dmysql3/' .. config .. '.txt', DefaultConfigString)
		DMySQL3.Message('Creating default config for "' .. config .. '"')
	end

	local confStr = file.Read('dmysql3/' .. config .. '.txt', 'DATA')

	if not confStr or confStr == '' then
		confStr = DefaultConfigString
		DMySQL3.Message(config, ': ATTENTION: Config corrupted!')
	end

	local config = util.JSONToTable(confStr)

	if not config then
		config = table.Copy(DefaultOptions)
		DMySQL3.Message(config, ': ATTENTION: Config corrupted!')
	end

	if config.Host == 'localhost' and not system.IsWindows() then
		config.Host = '127.0.0.1'
	end

	self.UseMySQL = config.UseMySQL
	self.Host = config.Host
	self.Database = config.Database
	self.User = config.User
	self.Password = config.Password
	self.Port = config.Port
end

local EMPTY = function() end

function obj:Query(str, success, failed)
	success = success or EMPTY
	failed = failed or EMPTY

	if not self.IsMySQL then
		local data = sql.Query(str)

		if data == false then
			xpcall(failed, DLib.Message:Compose(debug.traceback), sql.LastError())
		else
			xpcall(success, DLib.Message:Compose(debug.traceback), data or {})
		end

		return
	end

	if self.UseTMySQL4 then
		if not self.LINK then
			Connect()
		end

		if not self.LINK then
			DMySQL3.Message(self.config, ': Connection to database lost while executing query!')
			return
		end

		self.LINK:Query(str, function(data)
			local data = data[1]

			if not data.status then
				xpcall(failed, DLib.Message:Compose(debug.traceback), data.error)
			else
				xpcall(success, DLib.Message:Compose(debug.traceback), data.data or {})
			end
		end)

		return
	end

	local obj = self.LINK:query(str)

	function obj.onSuccess(q, data)
		xpcall(success, DLib.Message:Compose(debug.traceback), data or {})
	end

	function obj.onError(q, err)
		if self.LINK:status() == mysqloo.DATABASE_NOT_CONNECTED then
			Connect()
			DMySQL3.Message(self.config, ': Connection to database lost while executing query!')
			return
		end

		xpcall(failed, DLib.Message:Compose(debug.traceback), err)
	end

	obj:start()
end

obj.TRX = {}

function obj:Add(str, success, failed)
	success = success or EMPTY
	failed = failed or EMPTY

	table.insert(self.TRX, {str, success, failed})
end

function obj:Begin(nobegin)
	self.TRX = {}
	self.TRXNoCommit = nobegin

	if not nobegin then
		self:Add('BEGIN')
	end
end

function obj:Commit(finish)
	finish = finish or EMPTY

	if not self.TRXNoCommit then
		self:Add('COMMIT')
	end

	local TRX = self.TRX
	self.TRX = {}

	local current = 1
	local total = #TRX

	local success, err

	function success(data)
		xpcall(TRX[current][2], DLib.Message:Compose(debug.traceback), data)
		current = current + 1
		if current > total then xpcall(finish, DLib.Message:Compose(debug.traceback)) return end
		self:Query(TRX[current][1], success, err)
	end

	function err(data)
		xpcall(TRX[current][3], DLib.Message:Compose(debug.traceback), data)
		current = current + 1
		if current > total then xpcall(finish, DLib.Message:Compose(debug.traceback)) return end
		self:Query(TRX[current][1], success, err)
	end

	self:Query(TRX[current][1], success, err)
end

function obj:GatherTableColumns(tableIn, callback, error)
	assert(type(tableIn) == 'string', 'Input is not a string! typeof ' .. type(tableIn))

	if self.IsMySQL then
		self:Query('DESCRIBE `' .. tableIn .. '`;', function(data)
			local output = {}

			for i, row in ipairs(data) do
				local cName = row.Type:lower()
				local valueType = cName:match('^([^\\(]+)'):lower()
				local valueLength = tonumber(cName:match('([0-9]+)'))
				local unsigned = cName:match('unsigned') ~= nil

				if valueType == 'int' then
					valueType = 'integer'
				end

				table.insert(output, {
					field = row.Field,
					type = {
						type = valueType,
						length = valueLength,
						isUnsigned = unsigned,
					},
					isNull = row.Null == 'YES',
					default = row.Default,
					unrecognized = row.Extra
				})
			end

			callback(output)
		end, error)
	else
		self:Query('pragma table_info("' .. tableIn .. '")', function(data)
			local output = {}

			for i, row in ipairs(data) do
				local cName = row.type:lower()
				local valueType = cName:match('^([^\\(]+)'):lower()
				local valueLength = tonumber(cName:match('([0-9]+)'))
				local unsigned = cName:match('unsigned') ~= nil
				local default = row.dflt_value

				if default == 'NULL' then
					default = nil
				else
					default = default:match("^'?([^']*)'?$")
				end

				table.insert(output, {
					field = row.name,
					type = {
						type = valueType,
						length = valueLength,
						isUnsigned = unsigned
					},
					isNull = row.notnull == '0',
					default = default,
					unrecognized = row.extra
				})
			end

			callback(output)
		end, error)
	end
end

DMySQL3.Connect('default')
