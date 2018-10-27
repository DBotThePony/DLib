
-- Copyright (C) 2018 DBot

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

file.mkdir('dmysql4')

_G.DMySQL4 = DMySQL4 or {}
DLib.DMySQL4 = DMySQL4
local DMySQL4 = DMySQL4
local DLib = DLib
DMySQL4.Clients = DMySQL4.Clients or {}

DLib.MessageMaker(DMySQL4, 'DMySQL4')

local default = {
	-- Possible values are sqlite, mysql
	driver = 'sqlite',
	host = '127.0.0.1',
	port = 3306,
	database = '',
	username = '',
	password = ''
}

local table = table
local setmetatable = setmetatable
local type = type
local error = error
DMySQL4.meta = DMySQL4.meta or {}
local meta = DMySQL4.meta
meta.__index = meta

DMySQL4.STYLE_TMYSQL = 0
DMySQL4.STYLE_MYSQLOO = 1

function DMySQL4.Create(name)
	if type(name) ~= 'string' then
		error('Configuration name must be a string! For default configuration, use "default"', 2)
	end

	name = name:lower():trim()
	local readConfig

	if not file.Exists('dmysql4/' .. name .. '.txt', 'DATA') then
		file.Write('dmysql4/' .. name .. '.txt', util.TableToJSON(default, true))
		readConfig = table.Copy(default)
	else
		local read = file.Read('dmysql4/' .. name .. '.txt', 'DATA')
		local json = util.JSONToTable(read)

		if not json then
			file.Write('dmysql4/__' .. name .. '.txt', read)
			DMySQL4.Message('!!!!!!!!!!!!!!!!!!')
			DMySQL4.Message('!!! Corrupted JSON connection configuration for ' .. name)
			DMySQL4.Message('!!! It were saved as __' .. name .. '.txt')
			DMySQL4.Message('!!!!!!!!!!!!!!!!!!')
			readConfig = table.Copy(default)
			file.Write('dmysql4/' .. name .. '.txt', util.TableToJSON(default, true))
		else
			for k, v in pairs(json) do
				if default[k] == nil then
					DMySQL4.Message(name .. ': Unknown variable ' .. k)
				end
			end

			for k, v in pairs(default) do
				if json[k] == nil then
					DMySQL4.Message(name .. ': Missing variable ' .. k .. ', forcing default to ' .. v)
					json[k] = v
				end
			end

			readConfig = json
		end
	end

	local self = setmetatable({}, meta)

	self.configName = name
	self.config = readConfig
	self.connected = false

	self:Connect()

	return self
end

local tmysql4, mysqloo = file.Exists('bin/gmsv_tmysql4_*', 'LUA'), file.Exists('bin/gmsv_mysqloo_*', 'LUA')

function meta:IsMySQL()
	return self.config.driver == 'mysql'
end

function meta:IsSQLite()
	return not self:IsMySQL()
end

function meta:Connect()
	if self.connected then
		error('Already connected. To reconnect use :Reconnect()')
	end

	if self:IsSQLite() then
		self.connected = true
		DMySQL4.Message(self.configName .. ': Connected using SQLite')
		return self
	end

	if not tmysql4 and not mysqloo then
		self.connected = false
		DMySQL4.Message(self.configName .. ': Trying to use MySQL but none MySQL native drivers found! Aborting.')
		DMySQL4.Message(self.configName .. ': All queries will be rejected!')
		return self
	end

	if tmysql4 then
		xpcall(function()
			require('tmysql4')

			DMySQL4.Message(self.configName .. ': Trying to connect to ' .. self.config.host .. ' using native driver TMySQL4')

			local connection, err = tmysql.initialize(self.config.host, self.config.user, self.config.password, self.config.database, self.config.port)

			if not connection then
				DMySQL4.Message(self.configName .. ': Connection failed: ' .. err)
				DMySQL4.Message(self.configName .. ': All queries will be rejected!')
				self.connected = false
			else
				DMySQL4.Message(self.configName .. ': Connected using TMySQL4')
				self.connection = connection
				self.style = DMySQL4.STYLE_TMYSQL
				self.connected = true
			end
		end, function(err)
			DMySQL4.Message(self.configName .. ': Could not initialize native driver TMySQL4')
			DMySQL4.Message(err)
			DMySQL4.Message(self.configName .. ': All queries will be rejected!')
			self.connected = false
		end)
	elseif mysqloo then
		DMySQL4.Message('It is reccomended that you use TMySQL4 instead of MySQLoo')

		xpcall(function()
			require('mysqloo')

			DMySQL4.Message(self.configName .. ': Trying to connect to ' .. self.config.host .. ' using native driver MySQLoo')

			local connection = mysqloo.connect(self.config.host, self.config.user, self.config.password, self.config.database, self.config.port)

			connection:connect()
			connection:wait()

			local status = connection:status()

			if status ~= mysqloo.DATABASE_CONNECTED then
				DMySQL4.Message(self.configName .. ': Connection failed: ')
				DMySQL4.Message(connection:hostInfo())
				DMySQL4.Message(self.configName .. ': All queries will be rejected!')
				self.connected = false
			else
				DMySQL4.Message(self.configName .. ': Connected using MySQLoo')
				self.connection = connection
				self.style = DMySQL4.STYLE_MYSQLOO
				self.connected = true
			end
		end, function(err)
			DMySQL4.Message(self.configName .. ': Could not initialize native driver MySQLoo')
			DMySQL4.Message(err)
			DMySQL4.Message(self.configName .. ': All queries will be rejected!')
			self.connected = false
		end)
	end
end

local Promise = Promise
local sql = sql

function meta:Disconnect()
	if not self.connected then
		error('Already not connected!')
	end

	DMySQL4.Message(self.configName .. ': Disconnected from database')

	self.connected = false

	if self.style == DMySQL4.STYLE_TMYSQL then
		self.connection:Disconnect()
	end
end

function meta:Reconnect()
	if not self.connected then
		return self:Connect()
	end

	self:Disconnect()
	return self:Connect()
end

function meta:Query(query)
	return Promise(function(resolve, reject)
		if not self.connected then
			return reject('Not connected to the server')
		end

		if self:IsSQLite() then
			local data = sql.Query(query)

			if data == nil then
				return resolve({})
			end

			if data == false then
				reject(sql.LastError())
				return
			end

			resolve(data)
			return
		end

		if self.style == DMySQL4.STYLE_TMYSQL then
			self.connection:Query(query, function(data)
				local data = data[1]

				if not data.status then
					reject(data.error)
				else
					resolve(data.data or {})
				end
			end)
		elseif self.style == DMySQL4.STYLE_MYSQLOO then
			local obj = self.connection:query(query)

			function obj:onSuccess(data)
				resolve(data or {})
			end

			function obj:onError(err)
				if self.connection:status() == mysqloo.DATABASE_NOT_CONNECTED then
					self:Reconnect()
					DMySQL4.Message(self.configName .. ': Connection to database lost while executing query!')
				end

				reject(err)
			end

			obj:start()
		end
	end)
end

-- This is not the same as BEGIN in DMySQL3
-- Since it will rollback all changes done if one of queries fail
function meta:Transaction(queries)
	if type(queries) ~= 'table' then
		error('You must provide a table of queries')
	end

	if #queries == 0 then
		return Promise(function(resolve) resolve() end)
	end

	return Promise(function(resolve, reject)
		self:Query('BEGIN'):Then(function()
			local fuckup
			local i = 0

			local function next()
				i = i + 1
				local query = queries[i]

				if not query then
					return resolve()
				end

				self:Query(query):Then(next):Catch(fuckup)
			end

			function fuckup(err)
				self:Query('ROLLBACK'):Then(reject:Wrap(err)):Catch(reject)
			end

			next()
		end):Catch(reject)
	end)
end

-- Currently only simulation is supported
function meta:Bake(raw)
	return DMySQL4.PlainBakedQuery(self, raw)
end

-- This seems to be useful, so i ported from DMySQL3
function meta:TableColumns(tableIn)
	assert(type(tableIn) == 'string', 'Input is not a string! typeof ' .. type(tableIn))

	return Promise(function(resolve, reject)
		if self:IsMySQL() then
			self:Query('DESCRIBE `' .. tableIn .. '`'):Then(function(data)
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

				resolve(output)
			end):Catch(reject)
		else
			self:Query('PRAGMA table_info("' .. tableIn .. '")'):Then(function(data)
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

				resolve(output)
			end):Catch(reject)
		end
	end)
end
