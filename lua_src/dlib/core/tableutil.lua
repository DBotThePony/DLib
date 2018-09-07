
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

local tableutil = DLib.module('table')
local ipairs = ipairs
local pairs = pairs
local table = table
local select = select
local remove = table.remove
local insert = function(self, val)
	local newIndex = #self + 1
	self[newIndex] = val
	return newIndex
end

--[[
	@Documentation
	@Path table.append
	@Arguments table destination, table source

	@Description
	Appends values from source table to destination table. Works only with nurmerical indexed tables
]]
function tableutil.append(destination, source)
	if #source == 0 then return destination end

	local i, nextelement = 1, source[1]

	::append::

	destination[#destination + 1] = source[i]
	i = i + 1
	nextelement = source[i]

	if nextelement ~= nil then
		goto append
	end

	return destination
end

--[[
	@Documentation
	@Path table.prependString
	@Arguments table destination, string prepend

	@Description
	Iterates over destination and prepends string to all values (assuming array contains only strings)
]]
function tableutil.prependString(destination, prepend)
	for i, value in ipairs(destination) do
		destination[i] = prepend .. value
	end

	return destination
end

--[[
	@Documentation
	@Path table.appendString
	@Arguments table destination, string append

	@Description
	Iterates over destination and appends string to all values (assuming array contains only strings)
]]
function tableutil.appendString(destination, append)
	for i, value in ipairs(destination) do
		destination[i] = value .. append
	end

	return destination
end

--[[
	@Documentation
	@Path table.filter
	@Arguments table target, function filterFunc

	@Description
	Filters table passed
	Second argument is a function(key, value, target)
	@EndDescription

	@Returns
	table: deleted elements
]]
function tableutil.filter(target, filterFunc)
	if not filterFunc then error('table.filter - missing filter function') end

	local filtered = {}
	local toRemove = {}

	for key, value in pairs(target) do
		local status = filterFunc(key, value, target)
		if not status then
			if type(key) == 'number' then
				insert(filtered, value)
				insert(toRemove, key)
			else
				filtered[key] = value
				target[key] = nil
			end
		end
	end

	for v, i in ipairs(toRemove) do
		remove(target, i - v + 1)
	end

	return filtered
end

--[[
	@Documentation
	@Path table.qfilter
	@Arguments table target, function filterFunc

	@Description
	Filters table passed using goto
	Second argument is a function(key, value, target)
	@EndDescription

	@Returns
	table: deleted elements
]]
function tableutil.qfilter(target, filterFunc)
	if not filterFunc then error('table.qfilter - missing filter function') end
	if #target == 0 then return {} end

	local filtered = {}
	local toRemove = {}

	local i = 1
	local nextelement = target[i]

	::filter::

	local status = filterFunc(i, nextelement, target)

	if not status then
		filtered[#filtered + 1] = nextelement
		toRemove[#toRemove + 1] = i
	end

	i = i + 1
	nextelement = target[i]

	if nextelement ~= nil then
		goto filter
	end

	if #toRemove ~= 0 then
		i = 1
		nextelement = toRemove[i]

		::rem::
		remove(target, toRemove[i] - i + 1)

		i = i + 1
		nextelement = toRemove[i]

		if nextelement ~= nil then
			goto rem
		end
	end

	return filtered
end

--[[
	@Documentation
	@Path table.filterNew
	@Arguments table target, function filterFunc

	@Description
	Filters table passed
	Second argument is a function(key, value, target) which should return boolean whenever element pass check
	@EndDescription

	@Returns
	table: passed elements
]]
function tableutil.filterNew(target, filterFunc)
	if not filterFunc then error('table.filterNew - missing filter function') end

	local filtered = {}

	for key, value in pairs(target) do
		local status = filterFunc(key, value, target)
		if status then
			insert(filtered, value)
		end
	end

	return filtered
end

--[[
	@Documentation
	@Path table.qfilterNew
	@Arguments table target, function filterFunc

	@Description
	Filters table passed using ipairs
	Second argument is a function(key, value, target) which should return boolean whenever element pass check
	@EndDescription

	@Returns
	table: passed elements
]]
function tableutil.qfilterNew(target, filterFunc)
	if not filterFunc then error('table.qfilterNew - missing filter function') end

	local filtered = {}

	for key, value in ipairs(target) do
		local status = filterFunc(key, value, target)
		if status then
			insert(filtered, value)
		end
	end

	return filtered
end

--[[
	@Documentation
	@Path table.qmerge
	@Arguments table into, table from

	@Description
	Filters table passed using ipairs
	Second argument is a function(key, value, target) which should return boolean whenever element pass check
	@EndDescription

	@Returns
	table: into
]]
function tableutil.qmerge(into, inv)
	for i, val in ipairs(inv) do
		into[i] = val
	end

	return into
end

--[[
	@Documentation
	@Path table.gcopy
	@Arguments table input
	@Alias table.qcopy

	@Description
	Fastly copies a table assuming it is numeric indexed array
	@EndDescription

	@Returns
	table: copied input
]]
function tableutil.gcopy(input)
	if #input == 0 then return {} end

	local reply = {}

	local nextValue, i = input[1], 1

	::loop::

	reply[i] = nextValue

	i = i + 1
	nextValue = input[i]

	if nextValue ~= nil then
		goto loop
	end

	return reply
end

tableutil.qcopy = tableutil.gcopy

--[[
	@Documentation
	@Path table.gcopyRange
	@Arguments table input, number start, number endPos

	@Description
	Copies array in specified range
	@EndDescription

	@Returns
	table: copied input
]]
function tableutil.gcopyRange(input, start, endPos)
	if #input < start then return {} end
	endPos = endPos or #input
	local endPos2 = endPos + 1

	local reply = {}

	local nextValue, i = input[start], start
	local i2 = 0

	::loop::
	i2 = i2 + 1
	reply[i2] = nextValue

	i = i + 1
	if i == endPos2 then return reply end
	nextValue = input[i]

	if nextValue ~= nil then
		goto loop
	end

	return reply
end

--[[
	@Documentation
	@Path table.unshift
	@Arguments table input, vararg values

	@Description
	Inserts values in the start of an array
	@EndDescription

	@Returns
	table: input
]]
function tableutil.unshift(tableIn, ...)
	local values = {...}
	local count = #values

	if count == 0 then return tableIn end

	for i = #tableIn + count, count, -1 do
		tableIn[i] = tableIn[i - count]
	end

	local i, nextelement = 1, values[1]

	::unshift::

	tableIn[i] = nextelement
	i = i + 1
	nextelement = values[i]

	if nextelement ~= nil then
		goto unshift
	end

	return tableIn
end

--[[
	@Documentation
	@Path table.construct
	@Arguments table input, function callback, number times, vararg prependArgs

	@Description
	Calls callback with prependArgs specified times to construct a new array or append values to existing array
	@EndDescription

	@Returns
	table: input or newly created array
]]
function tableutil.construct(input, funcToCall, times, ...)
	input = input or {}

	for i = 1, times do
		input[#input + 1] = funcToCall(...)
	end

	return input
end

--[[
	@Documentation
	@Path table.frandom
	@Arguments table input

	@Description
	Returns random value from passed array
	@EndDescription

	@Returns
	any: returned value from array
]]
function tableutil.frandom(tableIn)
	return tableIn[math.random(1, #tableIn)]
end

--[[
	@Documentation
	@Path table.qhasValue
	@Arguments table input, any value

	@Description
	Checks for value present in specified array quickly using ipairs
	@EndDescription

	@Returns
	boolean: whenever value is present in input
]]
function tableutil.qhasValue(findIn, value)
	for i, val in ipairs(findIn) do
		if val == value then return true end
	end

	return false
end

--[[
	@Documentation
	@Path table.flipIntoHash
	@Arguments table input

	@Description
	Iterates array over and creates new table {[value] = index}
	@EndDescription

	@Returns
	table: flipped hash table
]]
function tableutil.flipIntoHash(tableIn)
	local output = {}

	for i, value in ipairs(output) do
		output[value] = i
	end

	return output
end

--[[
	@Documentation
	@Path table.flip
	@Arguments table input

	@Description
	Returns new flipped array
	@EndDescription

	@Returns
	table: flipped array
]]
function tableutil.flip(tableIn)
	local values = {}

	for i = #tableIn, 1, -1 do
		values[#values + 1] = tableIn[i]
	end

	return values
end

--[[
	@Documentation
	@Path table.sortedFind
	@Arguments table findIn, table findWhat, any ifNone

	@Description
	Gets hash table (flipIntoHash) of passed table and attempts to search for ANY value specified in findWhat
	@EndDescription

	@Returns
	any: found value
]]
function tableutil.sortedFind(findIn, findWhat, ifNone)
	local hash = table.flipIntoHash(findIN)

	for i, valueFind in ipairs(findWhat) do
		if hash[valueFind] then
			return valueFind
		end
	end

	return ifNone
end

--[[
	@Documentation
	@Path table.removeValues
	@Arguments table findIn, vargarg values

	@Description
	Removes values at specified indexes. **INDEX LIST MUST BE SORTED!** (from the smallest index to biggest).
	Can also accept array of values as second argument.
	@EndDescription

	@Returns
	table: removed values
]]
function tableutil.removeValues(tableIn, ...)
	local first = select(1, ...)
	local args

	if type(first) == 'table' then
		args = first
	else
		args = {...}
	end

	local removed = {}

	for i = #args, 1, -1 do
		insert(removed, tableIn[args[i]])
		remove(tableIn, args[i])
	end

	return removed
end

--[[
	@Documentation
	@Path table.removeByMember
	@Arguments table findIn, any memberID, any memberValue

	@Description
	Iterates over array and looks for tables with memberID index present and removes it when it is equal to memberValue
	@EndDescription

	@Returns
	any: removed value. *nil if value is not found*
]]
function tableutil.removeByMember(tableIn, memberID, memberValue)
	local removed

	for i = 1, #tableIn do
		local v = tableIn[i]
		if type(v) == 'table' and v[memberID] == memberValue then
			table.remove(tableIn, i)
			removed = v
			break
		end
	end

	return removed
end

--[[
	@Documentation
	@Path table.deduplicate
	@Arguments table tableIn

	@Description
	Iterates over array and removed duplicated values
	@EndDescription

	@Returns
	table: passed table
	table: array contain removed values
]]
function tableutil.deduplicate(tableIn)
	local values = {}
	local toremove = {}

	for i, v in ipairs(tableIn) do
		if values[v] then
			insert(toremove, i)
		else
			values[v] = true
		end
	end

	return tableIn, tableutil.removeValues(tableIn, toremove)
end

return tableutil
