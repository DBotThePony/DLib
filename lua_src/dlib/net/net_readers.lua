
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

function messageMeta:ReadBit()
	if self.pointer == self.length then
		ErrorNoHalt('Out of range')
		return 0
	end

	self.pointer = self.pointer + 1
	return self.bits[self.pointer]
end

function messageMeta:ReadBool()
	return self:ReadBit() == 1
end

function messageMeta:ReadInt(bitCount)
	bitCount = tonumber(bitCount)
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

	if bitCount > self.length or bitCount < 2 then
		ErrorNoHalt('Out of range')
		return 0
	end

	bitCount = math.floor(bitCount)
	local buffer = self:ReadBuffer(bitCount)
	return DLib.bitworker.BinaryToInteger(buffer)
end

function messageMeta:ReadUInt(bitCount)
	bitCount = tonumber(bitCount)
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

	if bitCount > self.length or bitCount < 2 then
		ErrorNoHalt('Out of range')
		return 0
	end

	bitCount = math.floor(bitCount)
	local buffer = self:ReadBuffer(bitCount)
	return DLib.bitworker.BinaryToUInteger(buffer)
end

function messageMeta:ReadFloat(bitsInteger, bitsFloat)
	bitsInteger = bitsInteger or 24
	bitsFloat = bitsFloat or 8

	bitsFloat = tonumber(bitsFloat)
	bitsInteger = tonumber(bitsInteger)

	if type(bitsInteger) ~= 'number' then error('Integer part Bit amount is not a number!') end
	if type(bitsFloat) ~= 'number' then error('Float part Bit amount is not a number!') end

	if bitCount > 127 or bitCount < 2 then error('Integer part Bit amount overflow') end
	if bitsFloat > 32 or bitsFloat < 2 then error('Float part Bit amount overflow') end

	local totalBits = bitsInteger + bitsFloat

	if totalBits > self.length then
		ErrorNoHalt('Out of range')
		return 0
	end

	local buffer = self:ReadBuffer(totalBits)
	return DLib.bitworker.BinaryToFloat(buffer)
end

local Angle, Vector = Angle, Vector

function messageMeta:ReadVector()
	return Vector(self:ReadFloat(24, 4), self:ReadFloat(24, 4), self:ReadFloat(24, 4))
end

function messageMeta:ReadAngle()
	return Angle(self:ReadFloat(24, 4), self:ReadFloat(24, 4), self:ReadFloat(24, 4))
end

function messageMeta:ReadData(bytesRead)
	if type(bytesRead) ~= 'number' then
		error('WriteData - length is not a number!')
	end

	bytesRead = math.floor(bytesRead)

	if bytesRead < 1 then
		error('WriteData - length overflow')
	end

	local bitsRead = bytesRead * 8

	if self.pointer + bitsRead + 1 > self.length then
		ErrorNoHalt('ReadData - out of bounds, clamping read range...')
		bitsRead = self.length - self.pointer
	end

	local bits = self:ReadBuffer(bitsRead)
	return string.char(unpack(bits))
end

function messageMeta:ReadDouble()
	return self:ReadFloat(32, 64)
end

function messageMeta:ReadString()
	local nextChar = DLib.bitworker.BinaryToUInteger(self:ReadBuffer(8))
	local readString = {}

	while nextChar ~= 0 do
		table.insert(readString, nextChar)
		nextChar = DLib.bitworker.BinaryToUInteger(self:ReadBuffer(8))
	end

	return string.char(unpack(readString))
end
