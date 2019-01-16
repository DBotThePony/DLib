
-- Copyright (C) 2016-2018 DBot

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

local meta = FindMetaTable('Promise') or {}
debug.getregistry().Promise = meta

local setmetatable = setmetatable
local DLib = DLib
local type = type
local error = error
local xpcall = xpcall
local debug = debug
local ProtectedCall = ProtectedCall

meta.MetaName = 'Promise'
meta.__index = meta

local promises = {}

--[[
	@doc
	@fname DLib.Promise
	@args function handler

	@desc
	Same as [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) but:
	use `Promise:Catch(function)` and
	`Promise:Then(function)`
	@enddesc

	@returns
	Promise: created promise
]]
local function constructor(handler)
	if type(handler) ~= 'function' then
		error('Promise handler were not provided; got ' .. type(handler))
	end

	local self = setmetatable({}, meta)

	self.handler = handler
	self.executed = false
	self.success = false
	self.failure = false
	self.traceback = debug.traceback(nil, 2)

	self.__resolve = function(arg) return self:onResolve(arg) end
	self.__reject = function(arg) return self:onReject(arg) end

	table.insert(promises, self)

	return self
end

DLib.Promise = constructor
_G.Promise = constructor

function meta:onResolve(arg)
	self.success = true
	self.failure = false

	if not self.resolve then return end

	xpcall(self.resolve, function(err)
		self:onReject(debug.traceback(err, 2))
	end, arg)
end

function meta:onReject(arg)
	self.success = false
	self.failure = true

	if not self.reject then
		error('Unhandled promise rejection: ' .. tostring(arg), 2)
	end

	xpcall(self.reject, function(err)
		DLib.Message('Error while handling promise rejection. WTF?!')
		DLib.Message(debug.traceback(err, 2))
		DLib.Message('Promise created at')
		DLib.Message(self.traceback)

		ProtectedCall(error:Wrap('Unhandled promise rejection: ' .. err2, 3))
	end, arg)
end

function meta:execute()
	self.executed = true

	xpcall(self.handler, function(err)
		self:onReject(debug.traceback(err, 2))
	end, self.__resolve, self.__reject)

	return self
end

function meta:catch(handler)
	if type(handler) ~= 'function' then
		error('Invalid handler; got ' .. type(handler))
	end

	self.reject = handler

	if self.reject and self.resolve then
		self:execute()
	end

	return self
end

function meta:reslv(handler)
	if type(handler) ~= 'function' then
		error('Invalid handler; got ' .. type(handler))
	end

	self.resolve = handler

	if self.reject and self.resolve then
		self:execute()
	end

	return self
end

meta.resolv = meta.reslv
meta.after = meta.reslv
meta.Then = meta.reslv
meta.error = meta.catch
meta.Catch = meta.catch

local ipairs = ipairs

local function tickHandler()
	if #promises == 0 then return end

	for i, promise in ipairs(promises) do
		if not promise.executed then
			promise:execute()
		end
	end

	promises = {}
end

DLib.__PromiseTickHandler = tickHandler
