
-- Copyright (C) 2018-2019 DBot

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
	-- Possible values are sqlite, mysql, (reserved) pgsql
	driver = 'sqlite',
	host = '127.0.0.1',
	port = 3306,
	database = '',
	username = '',
	password = ''
}

local Promise = Promise
local sql = sql
local table = table
local setmetatable = setmetatable
local type = type
local error = error
DMySQL4.meta = DMySQL4.meta or {}
local meta = DMySQL4.meta
meta.__index = meta

DMySQL4.STYLE_TMYSQL = 0
DMySQL4.STYLE_MYSQLOO = 1

local prohibited = {
	' ', '"', '`', ':', '<', '>', '|', '/', '\\', '?', '*'
}

--[[
	@doc
	@fname DMySQL4.Create
	@args string configName

	@server

	@desc
	entry point of DMySQL4 for your addon
	yes, this is fourth generation of DMySQL
	this addon is like MySQLoo by Falco (FPtje), but
	 * fully OOP based
	 * uses DLib.Promise object instead of callbacks
	 * multiple connections are allowed
	 * end user configures connections using JSON files
	@enddesc

	@returns
	table: a newly created/existant object (DMySQL4Connection)
]]
function DMySQL4.Create(name)
	if type(name) ~= 'string' then
		error('Configuration name must be a string! For default configuration, use "default" (which is not recommended, since it provide some restrictions)', 2)
	end

	name = name:lower():trim()
	assert(#name ~= 0, 'Config name length is zero')

	for i, symbol in ipairs(prohibited) do
		assert(not name:find(symbol, 1, true), string.format('%q is not allowed in config name', symbol))
	end

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

	return self:Connect(), self
end

local tmysql4, mysqloo = file.Exists('bin/gmsv_tmysql4_*', 'LUA'), file.Exists('bin/gmsv_mysqloo_*', 'LUA')

--[[
	@doc
	@fname DMySQL4Connection:IsMySQL

	@server

	@returns
	boolean
]]
function meta:IsMySQL()
	return self.config.driver == 'mysql'
end

--[[
	@doc
	@fname DMySQL4Connection:IsPGSQL

	@server

	@returns
	boolean
]]
function meta:IsPGSQL()
	return self.config.driver == 'pgsql'
end

--[[
	@doc
	@fname DMySQL4Connection:IsMySQLStyle

	@server

	@returns
	boolean
]]
function meta:IsMySQLStyle()
	return not self:IsPGSQL()
end

--[[
	@doc
	@fname DMySQL4Connection:IsSQLite

	@server

	@returns
	boolean
]]
function meta:IsSQLite()
	return not self:IsMySQL()
end

--[[
	@doc
	@fname DMySQL4Connection:Connect

	@server

	@desc
	throws an error if is already connected
	@enddesc

	@returns
	boolean: whenever connection was successful or not
]]
function meta:Connect()
	return Promise(function(resolve, reject)
		if self.connected then
			reject('Already connected. To reconnect use :Reconnect()')
			return
		end

		if self:IsSQLite() then
			self.connected = true
			DMySQL4.Message(self.configName .. ': Connected using SQLite')
			resolve(true)
			return
		end

		if self:IsPGSQL() then
			self.connected = false
			DMySQL4.Message(self.configName .. ': pgsql driver is reserved for future use')
			reject('pgsql driver is reserved for future use')
			return
		end

		if not tmysql4 and not mysqloo then
			self.connected = false
			DMySQL4.Message(self.configName .. ': Trying to use MySQL but none MySQL native drivers found! Aborting.')
			DMySQL4.Message(self.configName .. ': All queries will be rejected!')
			resolve(false)
			return
		end

		if tmysql4 then
			local status, returned = xpcall(function()
				require('tmysql4')

				DMySQL4.Message(self.configName .. ': Trying to connect to ' .. self.config.host .. ' using native driver TMySQL4')

				local connection, err = tmysql.initialize(self.config.host, self.config.user, self.config.password, self.config.database, self.config.port)

				if not connection then
					DMySQL4.Message(self.configName .. ': Connection failed: ' .. (err or '<unknown>'))
					DMySQL4.Message(self.configName .. ': All queries will be rejected!')
					self.connected = false
					reject(err or 'Connection failed')
					return
				end

				DMySQL4.Message(self.configName .. ': Connected using TMySQL4')
				self.connection = connection
				self.style = DMySQL4.STYLE_TMYSQL
				self.connected = true

				resolve(true)
			end, function(err)
				DMySQL4.Message(self.configName .. ': Could not initialize native driver TMySQL4')
				DMySQL4.Message(err)
				DMySQL4.Message(self.configName .. ': All queries will be rejected!')
				self.connected = false
				reject(err)
			end)
		elseif mysqloo then
			DMySQL4.Message('It is reccomended that you use TMySQL4 instead of MySQLoo')

			local status, returned = xpcall(function()
				require('mysqloo')

				DMySQL4.Message(self.configName .. ': Trying to connect to ' .. self.config.host .. ' using native driver MySQLoo')

				local connection = mysqloo.connect(self.config.host, self.config.user, self.config.password, self.config.database, self.config.port)

				connection:connect()

				connection.onConnected = function()
					DMySQL4.Message(self.configName .. ': Connected using MySQLoo')
					self.connection = connection
					self.style = DMySQL4.STYLE_MYSQLOO
					self.connected = true
					resolve(true)
				end

				connection.onConnectionFailed = function(err)
					DMySQL4.Message(self.configName .. ': Connection failed: ')
					DMySQL4.Message(connection:hostInfo())
					DMySQL4.Message(self.configName .. ': All queries will be rejected!')
					self.connected = false
					reject(connection:hostInfo())
				end
			end, function(err)
				DMySQL4.Message(self.configName .. ': Could not initialize native driver MySQLoo')
				DMySQL4.Message(err)
				DMySQL4.Message(self.configName .. ': All queries will be rejected!')
				self.connected = false
				reject(err)
			end)
		end

		reject('unknown error')
	end)
end

--[[
	@doc
	@fname DMySQL4Connection:Disconnect

	@server

	@desc
	throws an error if is already not connected
	this does (almost) nothing if end user has MySQLoo installed (unlike TMySQL4)
	@enddesc

	@returns
	boolean: whenever disconnection was successful or not
]]
function meta:Disconnect()
	if not self.connected then
		error('Already not connected!')
	end

	DMySQL4.Message(self.configName .. ': Disconnected from database')

	self.connected = false

	if self.style == DMySQL4.STYLE_TMYSQL then
		return self.connection:Disconnect()
	end

	return true
end

--[[
	@doc
	@fname DMySQL4Connection:Reconnect

	@server

	@returns
	boolean: whenever connection was successful or not
]]
function meta:Reconnect()
	if not self.connected then
		return self:Connect()
	end

	self:Disconnect()
	return self:Connect()
end

--[[
	@doc
	@fname DMySQL4Connection:Query
	@args string sqlQuery

	@server

	@returns
	Promise: Resolves with a table (even if no rows were returned by the query), rejects with string error
]]
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
					if data.error and isstring(data.error) and data.error:lower():trim() == 'mysql server has gone away' then
						self.connected = false

						self:Reconnect():Then(function()
							self:Query(query):Then(resolve):Catch(reject)
						end):Catch(function(err)
							reject(err)
						end)

						DMySQL4.Message(self.configName .. ': Connection to database lost while executing query!')

						return
					end

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
					self.connected = false

					self:Reconnect():Then(function()
						self:Query(query):Then(resolve):Catch(reject)
					end):Catch(function(err)
						reject(err)
					end)

					DMySQL4.Message(self.configName .. ': Connection to database lost while executing query!')
					return
				end

				reject(err)
			end

			obj:start()
		end
	end)
end

--[[
	@doc
	@fname DMySQL4Connection:Transaction
	@args table queryStrings

	@server

	@desc
	unlike Falco's MySQLoo's transaction blocks, this rollbacks all queries on failure.
	@enddesc

	@returns
	Promise: Resolves when all queries are finished, rejects when at least one query fails with string error messages
]]
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
					return self:Query('COMMIT'):Then(resolve):Catch(reject)
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

--[[
	@doc
	@fname DMySQL4Connection:Bake
	@args table queryTemplate

	@server

	@desc
	Currently, they only simulate baked queries behavior
	placeholders are marked as `?` symbol (e.g. `INSERT INTO "mytable" VALUES (?, ?, ?)`)
	@enddesc

	@returns
	PlainBakedQuery
]]

--[[
	@doc
	@fname PlainBakedQuery:ExecInPlace
	@args vararg arguments

	@server

	@returns
	Promise
]]

--[[
	@doc
	@fname PlainBakedQuery:Execute
	@args vararg arguments

	@server

	@desc
	can confuse: this **DOES NOT** perform a query on database.
	it just return query string it want to execute
	@enddesc

	@returns
	string
]]
-- Currently only simulation is supported
function meta:Bake(...)
	return DMySQL4.PlainBakedQuery(self, ...)
end

function meta:AdvancedBake(...)
	return DMySQL4.AdvancedBakedQuery(self, ...)
end

--[[
	@doc
	@fname DMySQL4Connection:TableColumns
	@args string tableToCheck

	@server

	@desc
	{
		field = row.Field,
		type = {
			type = valueType,
			length = valueLength,
			isUnsigned = unsigned,
		},
		isNull = row.Null == 'YES',
		default = row.Default,
		unrecognized = row.Extra
	}
	@enddesc

	@returns
	table
]]
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

-- YYMMDD_hhmmss_.*
local filematch = '([0-9][0-9])([0-9][0-9])([0-9][0-9])_([0-9][0-9])([0-9][0-9])([0-9][0-9])_(.*)%.lua'
local filematch2 = '([0-9][0-9])([0-9][0-9])([0-9][0-9])_([0-9][0-9])([0-9][0-9])([0-9][0-9])_(.*)'

function meta:Migrate(doServerCrash)
	if doServerCrash == nil then doServerCrash = game.IsDedicated() end

	return Promise(function(resolve, reject)
		DMySQL4.MessageError(self.configName .. ': Migrating database')
		local files = file.Find('dlib/migration/' .. self.configName .. '/*.lua', 'Lua')
		local migrations = {}

		for i, file in ipairs(files) do
			local year, month, day, hour, minute, second, name = file:match(filematch)

			if year and month and day and hour and minute and second and name then
				local data = {
					year = year:tonumber() or 0,
					month = month:tonumber() or 0,
					day = day:tonumber() or 0,
					hour = hour:tonumber() or 0,
					minute = minute:tonumber() or 0,
					second = second:tonumber() or 0,
					name = name,
					migrationname = file:sub(1, -5),
					filename = 'dlib/migration/' .. self.configName .. '/' .. file
				}

				data.score = second + minute * 60 + hour * 3600 + day * 86400 + month * 2592000 + year * 31104000
				table.insert(migrations, data)
			else
				DMySQL4.MessageWarning(self.configName .. ': Unknown file in migrations folder: ', file)
				DMySQL4.MessageWarning('File should be named in this form: YYMMDD_hhmmss_your_own_name.lua')
				DMySQL4.MessageWarning('So migration controller can figure in which order is to apply migrations')
			end
		end

		if #migrations == 0 then
			resolve()
			DMySQL4.MessageError(self.configName .. ': Nothing to migrate')
			return
		end

		table.sort(migrations, function(a, b)
			return a.score < b.score
		end)

		local applied = {}

		local function doStuff()
			table.sort(applied, function(a, b)
				return a.score < b.score
			end)

			local migrationsToApply = {}

			for i, migration in ipairs(migrations) do
				if applied[i] and applied[i].migrationname ~= migration.migrationname then
					DMySQL4.MessageError('-------------------------------------------------')
					DMySQL4.MessageError(self.configName .. ': MIGRATION MISORDER !!!!!!!!!')
					DMySQL4.MessageError('Something VERY BAD happened!')
					DMySQL4.MessageError('Migrations in code do not match migrations in database!')
					DMySQL4.MessageError('This might be due to missing files inside addon,')
					DMySQL4.MessageError('Bad changes inside it\'s files or')
					DMySQL4.MessageError('Manual bad database edit.')
					DMySQL4.MessageError('Server load continuation is highly discouraged!' .. (doServerCrash and '\n' or ''))

					if doServerCrash then
						DMySQL4.MessageError('TO AVOID SEVERE DAMAGE TO DATABASE AND TO GAME SERVER')
						DMySQL4.MessageError('GAME SERVER WOULD EXIT NOW\n')
					end

					DMySQL4.MessageError('DO NOT IGNORE THIS ERROR')
					DMySQL4.MessageError('DO NOT IGNORE THIS ERROR')
					DMySQL4.MessageError('DO NOT IGNORE THIS ERROR')

					DMySQL4.MessageError('-------------------------------------------------')

					if doServerCrash then
						RunConsoleCommand('_restart')
						return
					end
				end

				if not applied[i] then
					table.insert(migrationsToApply, migration)
				-- else
				--  DMySQL4.MessageError(self.configName .. ': ' .. migration.migrationname .. ': Already migrated')
				end
			end

			if #migrationsToApply == 0 then
				resolve()
				DMySQL4.MessageError(self.configName .. ': Nothing to migrate')
				return
			end

			local function migrateNext()
				local migration = table.remove(migrationsToApply, 1)

				if not migration then
					resolve()
					DMySQL4.MessageError(self.configName .. ': All migrations were applied!')
					return
				end

				local fn = CompileFile(migration.filename)

				if type(fn) == 'string' then
					DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
					DMySQL4.MessageError('Unable to compile ' .. migration.filename)
					DMySQL4.MessageError(fn)
					reject(fn)
					return
				end

				local function continueDoingStuff()
					local thread = coroutine.create(function()
						local env = getfenv(0)

						setfenv(fn, setmetatable({}, {
							__index = function(_self, key)
								if key == 'Connection' or key == 'Link' or key == 'LINK' or key == 'SQL' then
									return self
								end

								return env[key]
							end,

							__newindex = function(_self, key, value)
								env[key] = value
							end
						}))

						fn()
					end)

					DMySQL4.MessageError(self.configName .. ': Migrating ' .. migration.migrationname)

					hook.Add('Think', self.configName .. '_migrate', function()
						local status, err = coroutine.resume(thread)

						if not status then
							DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
							DMySQL4.MessageError('Can\'t apply migration ' .. migration.migrationname)
							DMySQL4.MessageError(err)

							if not self:IsPGSQL() then
								DMySQL4.MessageError('PRAY TO GOD FOR YOUR DATABASE TO BE SAFE')
								DMySQL4.MessageError('SINCE BOTH MYSQL AND SQLITE CANT DO FULL ROLLBACK')
							end

							hook.Remove('Think', self.configName .. '_migrate')

							self:Query('ROLLBACK'):Then(function()
								reject(err)
							end):Catch(function(err2)
								DMySQL4.MessageError(self.configName .. ': UNABLE TO ROLLBACK')
								DMySQL4.MessageError(err2)
								DMySQL4.MessageError('SOMETHING VERY BAD HAPPENED')
								DMySQL4.MessageError('PRAY TO GOD FOR YOUR DATABASE TO BE SAFE')
							end)

							return
						end

						local status = coroutine.status(thread)

						if status == 'dead' then
							hook.Remove('Think', self.configName .. '_migrate')

							self:Query('INSERT INTO ' .. self.configName .. '_migrations VALUES (' .. SQLStr(migration.migrationname) .. ', ' .. os.time() .. ')'):Then(function()
								self:Query('COMMIT'):Then(function()
									DMySQL4.MessageError(self.configName .. ': Migrated ' .. migration.migrationname)
									migrateNext()
								end):Catch(function(err)
									DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
									DMySQL4.MessageError('Unable to COMMIT for ' .. migration.migrationname)
									DMySQL4.MessageError(err)
									DMySQL4.MessageError('PRAY TO GOD FOR YOUR DATABASE TO BE SAFE')
								end)
							end):Catch(function(err)
								DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
								DMySQL4.MessageError('Unable to insert migration name for ' .. migration.migrationname)
								DMySQL4.MessageError(err)
								DMySQL4.MessageError('PRAY TO GOD FOR YOUR DATABASE TO BE SAFE')
							end)
						end
					end)
				end

				self:Query('BEGIN'):Then(continueDoingStuff):Catch(function(err)
					if err == 'cannot start a transaction within a transaction' then
						self:Query('COMMIT'):Then(function()
							self:Query('BEGIN'):Then(function()
								continueDoingStuff()
							end):Catch(function(err)
								DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
								DMySQL4.MessageError('Unable to BEGIN for ' .. migration.migrationname)
								DMySQL4.MessageError(err)
							end)
						end):Catch(function(err)
							DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
							DMySQL4.MessageError('Unable to COMMIT open transaction block for ' .. migration.migrationname)
							DMySQL4.MessageError(err)
						end)

						return
					end

					DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
					DMySQL4.MessageError('Unable to BEGIN for ' .. migration.migrationname)
					DMySQL4.MessageError(err)
				end)
			end

			migrateNext()
		end

		self:Query('SELECT name FROM ' .. self.configName .. '_migrations'):Then(function(data)
			for i, row in ipairs(data) do
				local year, month, day, hour, minute, second, name = row.name:match(filematch2)

				if year and month and day and hour and minute and second and name then
					local data = {
						year = year:tonumber() or 0,
						month = month:tonumber() or 0,
						day = day:tonumber() or 0,
						hour = hour:tonumber() or 0,
						minute = minute:tonumber() or 0,
						second = second:tonumber() or 0,
						name = name,
						migrationname = row.name
					}

					data.score = second + minute * 60 + hour * 3600 + day * 86400 + month * 2592000 + year * 31104000
					table.insert(applied, data)
				else
					DMySQL4.MessageError(self.configName .. ': Unknown migration in database: ', row.name)
					DMySQL4.MessageError('This should NEVER happen!')
				end
			end

			doStuff()
		end):Catch(function()
			self:Query([[
				CREATE TABLE ]] .. self.configName .. [[_migrations (
					name VARCHAR(255) NOT NULL PRIMARY KEY,
					apply_time BIGINT NOT NULL
				)
			]]):Then(doStuff):Catch(function(...)
				DMySQL4.MessageError(self.configName .. ': CAN\'T MIGRATE')
				DMySQL4.MessageError(...)
				reject(...)
			end)
		end)
	end)
end

function meta:SerialColumn(name, primary_key, escapeStyle)
	assert(isstring(name), 'column name must be a string')
	escapeStyle = escapeStyle == nil or escapeStyle == true
	primary_key = (primary_key == nil or primary_key == true) and ' PRIMARY KEY' or ''

	if not escapeStyle then
		if self:IsMySQL() then
			return string.format('[[%s]] INT NOT NULL AUTO_INCREMENT%s', name, primary_key)
		end

		if self:IsSQLite() then
			return string.format('[[%s]] INT NOT NULL AUTOINCREMENT%s', name, primary_key)
		end

		if self:IsPGSQL() then
			return string.format('[[%s]] SERIAL NOT NULL%s', name, primary_key)
		end
	end

	if self:IsMySQL() then
		return string.format('`%s` INT NOT NULL AUTO_INCREMENT%s', name:gsub('`', '``'), primary_key)
	end

	if self:IsSQLite() then
		return string.format('`%s` INT NOT NULL AUTOINCREMENT%s', name:gsub('`', '``'), primary_key)
	end

	if self:IsPGSQL() then
		return string.format('"%s" SERIAL NOT NULL%s', name:gsub('"', '"'), primary_key)
	end

	error('Unknown driver')
end
