
-- Copyright (C) 2018-2020 DBotThePony

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

import table, type, error, assert from _G

-- Simulated
class DMySQL4.PlainBakedQuery
	new: (database, plain) =>
		assert(type(plain) == 'string', 'Raw query is not a string! typeof ' .. type(plain))
		@database = database
		@raw = plain
		@parts = plain\split('?')
		@length = #@parts - 1

	ExecInPlace: (...) => @database\Query(@Format(...))
	Execute: (...) => @Format(...)
	Format: (...) =>
		return @raw if @length == 0

		@buff = {}

		for i, val in ipairs @parts
			if i == #@parts
				table.insert(@buff, val)
			elseif select(i, ...) == nil
				table.insert(@buff, val)
				table.insert(@buff, 'null')
			elseif type(select(i, ...)) == 'boolean'
				table.insert(@buff, val)
				table.insert(@buff, SQLStr(select(i, ...) and '1' or '0'))
			else
				table.insert(@buff, val)
				table.insert(@buff, SQLStr(tostring(select(i, ...))))

		return table.concat(@buff)

class BakedQueryRawPart
	new: (query, str) =>
		@query = query
		@str = str

	Format: (args, style) => @str

class BakedQueryTableIdentifier
	new: (query, str) =>
		@strMySQL = str\gsub('`', '``')
		@strPGSQL = str\gsub('"', '""')
		@raw = str
		@query = query

	Format: (args, style) => style and ('"' .. @strPGSQL .. '"') or ('`' .. @strMySQL .. '`')

class BakedQueryVariable
	new: (query, str) =>
		@identifier = str
		@query = query

	Format: (args, style) =>
		if not @query.allowNulls and args[@identifier] == nil
			error(@identifier .. ' = NULL')

		return args[@identifier] == nil and 'NULL' or SQLStr(args[@identifier])

class DMySQL4.AdvancedBakedQuery
	new: (database, plain, allowNulls = false) =>
		assert(type(plain) == 'string', 'Raw query is not a string! typeof ' .. type(plain))
		@database = database
		@raw = plain
		@allowNulls = allowNulls
		@parsed = {}

		expectingTableIdentifier = false
		inTableIdentifier = false
		inVariableName = false
		escape = false
		variableName = ''
		identifierName = ''
		str = ''

		pushStr = ->
			if str ~= ''
				table.insert(@parsed, BakedQueryRawPart(@, str))
				str = ''

		pushChar = (char) ->
			if inTableIdentifier
				identifierName ..= char
				return

			if inVariableName
				variableName ..= char
				return

			str ..= char

		closure = (char) ->
			if escape
				pushChar(char)
				escape = false
				return

			if char == '\\'
				escape = true
				return

			if char == ' '
				if inVariableName
					table.insert(@parsed, BakedQueryVariable(@, variableName))
					variableName = ''
					inVariableName = false
					return

				pushChar(char)
				return

			if char == ':'
				if inVariableName or inTableIdentifier
					pushChar(char)
					return

				pushStr()
				inVariableName = true
				return

			if char == '['
				if inVariableName or inTableIdentifier
					pushChar(char)
					return

				if expectingTableIdentifier
					pushStr()
					expectingTableIdentifier = false
					inTableIdentifier = true
					return

				expectingTableIdentifier = true
				return

			if char == ']'
				if expectingTableIdentifier and inTableIdentifier
					table.insert(@parsed, BakedQueryTableIdentifier(@, identifierName))
					inTableIdentifier = false
					expectingTableIdentifier = false
					identifierName = ''
					return

				if inTableIdentifier
					expectingTableIdentifier = true
					return

			if expectingTableIdentifier
				if inTableIdentifier
					pushChar(']' .. char)
				else
					pushChar('[' .. char)
					expectingTableIdentifier = false

				return

			pushChar(char)

		closure(char) for char in plain\gmatch(utf8.charpattern)

		if inTableIdentifier
			error('Unclosed table name identifier in raw query')

		if inVariableName
			table.insert(@parsed, BakedQueryVariable(@, variableName, allowNulls))

		pushStr()

	ExecInPlace: (...) => assert(@database, 'database wasn\'t specified earlier')\Query(@Format(...))
	Execute: (...) => @Format(...)
	Format: (params = {}) =>
		style = false if @database == nil
		style = not @database\IsMySQLStyle() if style == nil

		build = {}
		table.insert(build, arg\Format(params, style)) for arg in *@parsed
		return table.concat(build, ' ')

