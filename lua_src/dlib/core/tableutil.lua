
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

table.unpack = unpack
table.pairs = pairs
table.ipairs = ipairs

-- Appends numeric indexed tables
function table.append(destination, source)
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

function table.prependString(destination, prepend)
	for i, value in ipairs(destination) do
		destination[i] = prepend .. value
	end

	return destination
end

function table.appendString(destination, append)
	for i, value in ipairs(destination) do
		destination[i] = value .. append
	end

	return destination
end

-- Filters table passed
-- Second argument is a function(key, value, filteringTable)
-- Returns deleted elements
function table.filter(target, filterFunc)
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

function table.qfilter(target, filterFunc)
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

function table.filterNew(target, filterFunc)
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

function table.qfilterNew(target, filterFunc)
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

function table.qmerge(into, inv)
	for i, val in ipairs(inv) do
		into[i] = val
	end

	return into
end

function table.gcopy(input)
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

table.qcopy = table.gcopy

function table.gcopyRange(input, start, endPos)
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

function table.unshift(tableIn, ...)
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

function table.construct(input, funcToCall, times, ...)
	input = input or {}

	for i = 1, times do
		input[#input + 1] = funcToCall(...)
	end

	return input
end

function table.construct2(funcToCall, times, ...)
	local output = {}

	for i = 1, times do
		output[#output + 1] = funcToCall(i, ...)
	end

	return output
end

function table.frandom(tableIn)
	return tableIn[math.random(1, #tableIn)]
end

function table.qhasValue(findIn, value)
	for i, val in ipairs(findIn) do
		if val == value then return true end
	end

	return false
end

function table.flipIntoHash(tableIn)
	local output = {}

	for i, value in ipairs(output) do
		output[value] = i
	end

	return output
end

function table.flip(tableIn)
	local values = {}

	for i = #tableIn, 1, -1 do
		values[#values + 1] = tableIn[i]
	end

	return values
end

function table.sortedFind(findIn, findWhat, ifNone)
	local hash = table.flipIntoHash(findIN)

	for i, valueFind in ipairs(findWhat) do
		if hash[valueFind] then
			return valueFind
		end
	end

	return ifNone
end

function table.removeValues(tableIn, ...)
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

function table.removeByMember(tableIn, memberID, memberValue)
	local removed = {}

	for i = 1, #tableIn do
		local v = tableIn[i]
		if type(v) == 'table' and v[memberID] == memberValue then
			table.remove(tableIn, i)
			break
		end
	end

	return removed
end

function table.deduplicate(tableIn)
	local values = {}
	local toremove = {}

	for i, v in ipairs(tableIn) do
		if values[v] then
			insert(toremove, i)
		else
			values[v] = true
		end
	end

	table.removeValues(tableIn, toremove)
	return tableIn
end
