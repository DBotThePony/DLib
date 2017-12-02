
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

local messageMeta = FindMetaTable('LNetworkMessage')

local DLib = DLib
local util = util
local gnet = net
local type = type
local debug = debug
local ErrorNoHalt2 = ErrorNoHalt
local table = table
local ipairs = ipairs
local pairs = pairs
local math = math

local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

local function ErrorNoHalt(message)
	return ErrorNoHalt2(traceback(message) .. '\n')
end

function messageMeta:WriteBit(bitIn)
	if self.isReading then error('Message is read-only') end

	if type(bitIn) == 'boolean' then
		bitIn = bitIn and 1 or 0
	end

	if type(bitIn) ~= 'number' then
		error('Must be a number')
	end

	local input = math.floor(bitIn) ~= 0 and 0 or 1
	self:WriteBitRaw(input)
	return self
end

messageMeta.WriteBool = messageMeta.WriteBit

function messageMeta:WriteInt(input, bitCount)
	if self.isReading then error('Message is read-only') end
	input = tonumber(input)
	bitCount = tonumber(bitCount)
	if type(input) ~= 'number' then error('Input is not a number!') end
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	if bitCount > 127 or bitCount < 2 then error('Bit amount overflow') end

	local output = DLib.bitworker.IntegerToBinary(numberIn)

	if #output > bitCount then
		ErrorNoHalt('WriteInt - input integer is larger than can be reproduced with ' .. bitCount .. ' bits!')
	end

	self:WriteBitRaw(output[1])

	for i = 1, bitCount - #output do
		self:WriteBitRaw(0)
	end

	for i = 2, #output do
		self:WriteBitRaw(output[i])
	end

	return self
end
