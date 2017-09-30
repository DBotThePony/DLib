
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local tableutil = DLib.module('table')

-- Appends numeric indexed tables
function tableutil.append(destination, source)
	for i, value in ipairs(source) do
		table.insert(destination, value)
	end
end

function tableutil.prependString(destination, prepend)
	for i, value in ipairs(destination) do
		destination[i] = prepend .. value
	end
end

function tableutil.appendString(destination, append)
	for i, value in ipairs(destination) do
		destination[i] = value .. append
	end
end

-- Filters table passed
-- Second argument is a function(key, value, filteringTable)
-- Returns deleted elements
function tableutil.filter(target, filterFunc)
	if not filterFunc then error('table.filter - missing filter function') end

	local filtered = {}
	local toRemove = {}

	for key, value in pairs(target) do
		local status = filterFunc(key, value, target)
		if not status then
			if type(key) == 'number' then
				table.insert(filtered, value)
				table.insert(toRemove, key)
			else
				filtered[key] = value
				target[key] = nil
			end
		end
	end

	for v, i in ipairs(toRemove) do
		table.remove(target, i - v + 1)
	end

	return filtered
end

function tableutil.qfilter(target, filterFunc)
	if not filterFunc then error('table.filter - missing filter function') end

	local filtered = {}
	local toRemove = {}

	for key, value in ipairs(target) do
		local status = filterFunc(key, value, target)
		if not status then
			table.insert(filtered, value)
			table.insert(toRemove, key)
		end
	end

	for v, i in ipairs(toRemove) do
		table.remove(target, i - v + 1)
	end

	return filtered
end

function tableutil.filterNew(target, filterFunc)
	if not filterFunc then error('table.filterNew - missing filter function') end

	local filtered = {}

	for key, value in pairs(target) do
		local status = filterFunc(key, value, target)
		if status then
			table.insert(filtered, value)
		end
	end

	return filtered
end

function tableutil.qfilterNew(target, filterFunc)
	if not filterFunc then error('table.filterNew - missing filter function') end

	local filtered = {}

	for key, value in ipairs(target) do
		local status = filterFunc(key, value, target)
		if status then
			table.insert(filtered, value)
		end
	end

	return filtered
end

function tableutil.qmerge(into, inv)
	for i, val in ipairs(inv) do
		into[i] = val
	end

	return into
end

function tableutil.qcopy(input)
	local reply = {}

	reply[#input] = input[#input]

	for i, val in ipairs(input) do
		reply[i] = val
	end

	return reply
end

function tableutil.unshift(tableIn, ...)
	local values = {...}
	local count = #values

	if count == 0 then return tableIn end

	for i = #tableIn + count, count, -1 do
		tableIn[i] = tableIn[i - count]
	end

	for i, value in ipairs(values) do
		tableIn[i] = value
	end

	return tableIn
end

function tableutil.construct(input, funcToCall, times, ...)
	input = input or {}

	for i = 1, times do
		input[#input + 1] = funcToCall(...)
	end

	return input
end

function tableutil.frandom(tableIn)
	return tableIn[math.random(1, #tableIn)]
end

function tableutil.qhasValue(findIn, value)
	for i, val in ipairs(findIn) do
		if val == value then return true end
	end

	return false
end

function tableutil.flipIntoHash(tableIn)
	local output = {}

	for i, value in ipairs(output) do
		output[value] = i
	end

	return output
end

function tableutil.sortedFind(findIn, findWhat, ifNone)
	local hash = table.flipIntoHash(findIN)

	for i, valueFind in ipairs(findWhat) do
		if hash[valueFind] then
			return valueFind
		end
	end

	return ifNone
end

return tableutil
