
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

local coroutine = coroutine
local assert = assert
local debug_traceback = debug.traceback

--[[
	@doc
	@fname DLib.Promise
	@args function handler

	@desc
	Same as [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) but:
	use `Promise:Catch(function)` and
	`Promise:Then(function)`

	Alse there is `Promise:Await(varargForYield)` for use inside coroutine available.
	@enddesc

	@returns
	Promise: created promise
]]
local function constructor(handler, ...)
	local mtype = type(handler)

	if mtype ~= 'function' and mtype ~= 'thread' then
		error('Promise handler were not provided (function/thread); got ' .. mtype, 2)
	end

	local self = setmetatable({
		handlerType = mtype,
		handler = handler,
		success = false,
		executed = false,
		executed_finish = false,
		failure = false,
		traceback = debug_traceback(nil, 2),
	}, meta)

	self:execute(...)

	return self
end

DLib.Promise = constructor
_G.Promise = constructor

local hook = hook
local coroutine_status = coroutine.status
local coroutine_resume = coroutine.resume
local table_remove = table.remove
local unpack = unpack

function meta:execute(...)
	if self.executed then error('wtf dude') end

	self.executed = true

	if self.handlerType == 'function' then
		xpcall(self.handler, function(err)
			self.errors = {debug_traceback(err, 2)}
			self.errors_num = 1
			self.failure = true
			self.executed_finish = true

			if self.reject then
				self.reject(debug_traceback(err, 2))
			end
		end, function(...)
			self.returns = {...}
			self.returns_num = select('#', ...)
			self.success = true
			self.executed_finish = true

			if self.resolve then
				self.resolve(...)
			end
		end, function(...)
			self.errors = {...}
			self.errors_num = select('#', ...)
			self.failure = true
			self.executed_finish = true

			if self.reject then
				self.reject(...)
			end
		end, ...)

		return
	end

	local args = {coroutine_resume(self.handler, ...)}

	if not args[1] then
		self.errors = {args[2]}
		self.errors_num = 1
		self.failure = true
		self.executed_finish = true

		if self.reject then
			self.reject(args[2])
		end

		return
	end

	local status = coroutine_status(self.handler)

	if status == 'dead' then
		table_remove(args, 1)

		local max = next(args)

		if max then
			for index in pairs(args) do
				if index > max then
					max = index
				end
			end
		end

		self.returns = args
		self.returns_num = max
		self.success = true
		self.executed_finish = true

		if self.resolve then
			self.resolve(unpack(args, 1, max))
		end

		return
	end

	hook.Add('Think', self, function()
		args = {coroutine_resume(self.handler)}

		if not args[1] then
			self.errors = {args[2]}
			self.errors_num = 1
			self.failure = true
			self.executed_finish = true

			if self.reject then
				self.reject(args[2])
			end

			return
		end

		status = coroutine_status(self.handler)

		if status == 'dead' then
			table_remove(args, 1)

			local max = next(args)

			if max then
				for index in pairs(args) do
					if index > max then
						max = index
					end
				end
			end

			self.returns = args
			self.returns_num = max
			self.success = true
			self.executed_finish = true

			if self.resolve then
				self.resolve(unpack(args, 1, max))
			end
		end
	end)

	return self
end

local isfunction = isfunction

function meta:catch(handler)
	if not isfunction(handler) then
		error('Invalid handler; typeof ' .. type(handler))
	end

	self.reject = handler

	if self.executed and self.failure then
		handler(unpack(self.errors, 1, self.errors_num))
	end

	return self
end

function meta:reslv(handler)
	if not isfunction(handler) then
		error('Invalid handler; typeof ' .. type(handler))
	end

	self.resolve = handler

	if self.executed and self.success then
		handler(unpack(self.returns, 1, self.returns_num))
	end

	return self
end

function meta:IsValid()
	return not self.executed_finish
end

local coroutine_running = coroutine.running
local coroutine_yield = coroutine.yield

function meta:Await(...)
	local thread = assert(coroutine_running(), 'not in a coroutine thread')

	local fulfilled = false
	local err

	self:reslv(function()
		fulfilled = true
	end)

	self:catch(function(err2)
		err = err2
		fulfilled = true
	end)

	while not fulfilled do
		coroutine_yield(...)
	end

	if err then
		error(err)
	end

	return unpack(self.returns, 1, #self.returns)
end

meta.await = meta.Await
meta.resolv = meta.reslv
meta.after = meta.reslv
meta.Then = meta.reslv
meta.error = meta.catch
meta.Catch = meta.catch
