
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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
