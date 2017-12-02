
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
local string = string

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

function messageMeta:WriteVector(vecIn)
	if type(vecIn) ~= 'Vector' then
		error('WriteVector - input is not a vector!')
	end

	self:WriteFloat(vecIn.x, 24, 4)
	self:WriteFloat(vecIn.y, 24, 4)
	self:WriteFloat(vecIn.z, 24, 4)

	return self
end

function messageMeta:WriteAngle(angleIn)
	if type(vecIn) ~= 'Angle' then
		error('WriteAngle - input is not an angle!')
	end

	self:WriteFloat(vecIn.p, 24, 4)
	self:WriteFloat(vecIn.y, 24, 4)
	self:WriteFloat(vecIn.r, 24, 4)

	return self
end

function messageMeta:WriteData(binaryData, bytesToSend)
	if type(binaryData) ~= 'string' then
		error('WriteData - input is not a string!')
	end

	if type(bytesToSend) ~= 'number' then
		error('WriteData - length is not a number!')
	end

	bytesToSend = math.floor(bytesToSend)

	if bytesToSend < 1 then
		error('WriteData - length overflow')
	end

	bytesToSend = math.min(#binaryData, bytesToSend)

	local chars = {binaryData:byte(1, bytesToSend)}

	for i, char in ipairs(chars) do
		local newBits = DLib.bitworker.UIntegerToBinary(char)

		for i, bit in ipairs(newBits) do
			self:WriteBitRaw(bit)
		end
	end

	return self
end

function messageMeta:WriteDouble(value)
	return self:WriteFloat(value, 32, 64)
end

function messageMeta:WriteString(stringIn)
	if type(stringIn) ~= 'string' then
		error('WriteString - input is not a string!')
	end

	for i, char in ipairs({stringIn:byte(1, #stringIn)}) do
		for i, bit in ipairs(DLib.bitworker.UIntegerToBinary(char)) do
			self:WriteBitRaw(bit)
		end
	end

	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)
	self:WriteBitRaw(0)

	return self
end
