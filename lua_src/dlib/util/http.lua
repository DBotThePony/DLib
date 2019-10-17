
-- Copyright (C) 2017-2019 DBotThePony

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

local http = http
local DLib = DLib
local HTTP = HTTP
local assert = assert
local type = type
local istable = istable
local isstring = isstring
local pairs = pairs
local table = table
local error = error
local string = string

function http.EncodeQuery(params)
	assert(istable(params), 'Params input must be a table!')

	local build = {}

	for key, value in pairs(params) do
		table.insert(build, http.EncodeComponent(key) .. '=' .. http.EncodeComponent(value))
	end

	return table.concat(build, '&')
end

local function escapeUnicode(input)
	if #input == 1 then return input end

	local buf = ''

	for char in input:gmatch('.') do
		buf = buf .. '%' .. string.format('%X', string.byte(char))
	end

	return buf
end

local function escape(input)
	return '%' .. string.format('%X', string.byte(input))
end

function http.EncodeComponent(component)
	assert(isstring(component), 'Input must be a string!')
	return component:gsub("[\x01-\x26]", escape)
		:gsub("[\x2b-\x2f]", escape)
		:gsub("[\x3a-\x40]", escape)
		:gsub("[\x5b-\x5e]", escape)
		:gsub("\x60", escape)
		:gsub("[\x7b-\x7d]", escape)
		:gsub(utf8.charpattern, escapeUnicode)
end

function http.Head(url, onsuccess, onfailure, headers)
	local request = {
		url = url,
		method = 'HEAD',
		headers = headers or {},
	}

	if onsuccess then
		function request.success(code, _, headers)
			return onsuccess(headers, code)
		end
	end

	if onfailure then
		function request.failed(err)
			return onfailure(err)
		end
	end

	return HTTP(request)
end

function http.Put(url, body, onsuccess, onfailure, headers)
	local request = {
		url = url,
		body = body,
		method = 'PUT',
		headers = headers or {},
	}

	if onsuccess then
		function request.success(code, body, headers)
			return onsuccess(headers, body, code)
		end
	end

	if onfailure then
		function request.failed(err)
			return onfailure(err)
		end
	end

	return HTTP(request)
end
