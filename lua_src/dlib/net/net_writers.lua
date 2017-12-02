
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
		ErrorNoHalt('WriteInt - input integer is larger than integer that can be represented with ' .. bitCount .. ' bits!')
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

function messageMeta:WriteUInt(input, bitCount)
	if self.isReading then error('Message is read-only') end

	input = tonumber(input)
	bitCount = tonumber(bitCount)
	if type(input) ~= 'number' then error('Input is not a number!') end
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	if bitCount > 127 or bitCount < 1 then error('Bit amount overflow') end

	if input < 0 then
		ErrorNoHalt('WriteUInt - input integer is lesser than 0! To keep backward compability, it gets bit shift to flip')
		input = math.pow(2, bitCount) + input
	end

	local output = DLib.bitworker.UIntegerToBinary(numberIn)

	if #output > bitCount then
		ErrorNoHalt('WriteUInt - input integer is larger than integer that can be represented with ' .. bitCount .. ' bits!')
	end

	for i = 1, bitCount - #output do
		self:WriteBitRaw(0)
	end

	for i = 1, #output do
		self:WriteBitRaw(output[i])
	end

	return self
end

function messageMeta:WriteFloat(input, bitsInteger, bitsFloat)
	if self.isReading then error('Message is read-only') end

	bitsInteger = bitsInteger or 24
	bitsFloat = bitsFloat or 8

	input = tonumber(input)
	bitsFloat = tonumber(bitsFloat)
	bitsInteger = tonumber(bitsInteger)
	if type(input) ~= 'number' then error('Input is not a number!') end
	if type(bitsInteger) ~= 'number' then error('Integer part Bit amount is not a number!') end
	if type(bitsFloat) ~= 'number' then error('Float part Bit amount is not a number!') end

	local totalBits = bitsInteger + bitsFloat

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	if bitCount > 127 or bitCount < 2 then error('Integer part Bit amount overflow') end
	if bitsFloat > 32 or bitsFloat < 2 then error('Float part Bit amount overflow') end

	local output = DLib.bitworker.FloatToBinary(numberIn, bitsFloat)

	self:WriteBitRaw(output[1])

	for i = 1, totalBits - #output do
		self:WriteBitRaw(0)
	end

	for i = 2, #output do
		self:WriteBitRaw(output[i])
	end

	return self
end