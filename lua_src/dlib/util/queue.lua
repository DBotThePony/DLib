
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


local QUQUED_CALLS = {}
local QUQUED_CALLS_WRAPPED = {}

local table = table
local ipairs = ipairs
local select = select
local unpack = unpack

function DLib.QueuedFunction(funcIn, ...)
	table.insert(QUQUED_CALLS, {
		nextevent = funcIn,
		args = {...},
		argsNum = select('#', ...)
	})
end

function DLib.WrappedQueueFunction(funcIn)
	local p = ('%p'):format(funcIn)

	return function(...)
		for i, funcData in ipairs(QUQUED_CALLS_WRAPPED) do
			if funcData.p == p then return end
		end

		table.insert(QUQUED_CALLS_WRAPPED, {
			nextevent = funcIn,
			p = p,
			args = {...},
			argsNum = select('#', ...)
		})
	end
end

hook.Add('Think', 'DLib.util.QueuedFunction', function()
	local data = table.remove(QUQUED_CALLS, 1)
	if not data then return end
	data.nextevent(unpack(data.args, 1, data.argsNum))
end)

hook.Add('Think', 'DLib.util.WrappedQueueFunction', function()
	local data = table.remove(QUQUED_CALLS_WRAPPED, 1)
	if not data then return end
	data.nextevent(unpack(data.args, 1, data.argsNum))
end)
