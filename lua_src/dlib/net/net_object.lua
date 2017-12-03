
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
local ProtectedCall = ProtectedCall

local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

local ReadHeader = nnet.ReadHeader
local WriteBitNative = nnet.WriteBit
local ReadBitNative = nnet.ReadBit

local function ErrorNoHalt(message)
	return ErrorNoHalt2(traceback(message) .. '\n')
end

local messageMeta = {}

function net.CreateMessage(length, read)
	local obj = setmetatable({}, messageMeta)
	read = read or false
	length = length or 0

	obj.pointer = 0
	obj.bits = {}
	obj.isIncoming = read
	obj.isReading = read

	if read then
		obj:ReadNetwork()
	else
		for i = 1, length do
			table.insert(obj.bits, 0)
		end
	end

	return obj
end

function messageMeta:__index(key)
	if key == 'length' then
		return #self.bits
	end

	local val = messageMeta[key]

	if val ~= nil then
		return val
	end

	return rawget(self, key)
end

debug.getregistry().LNetworkMessage = messageMeta

function messageMeta:ReadNetwork(length)
	for i = 1, length do
		table.insert(self.bits, ReadBitNative())
	end

	return self
end

function messageMeta:Reset()
	self.pointer = 0
	return self
end

function messageMeta:ResetBuffer()
	self.bits = {}
	self:Reset()
	return self
end

function messageMeta:ReadBuffer(bits, start, movePointer)
	if movePointer == nil then
		movePointer = true
	end

	start = start or (self.pointer + 1)
	local output = {}

	for i = start, start + bits do
		if not self.bits[i] then
			error('ReadBuffer - out of range')
		end

		table.insert(output, self.bits[i])
	end

	if movePointer then
		self.pointer = self.pointer + bits + 1
	end

	return output
end

DLib.util.AccessorFuncJIT(messageMeta, 'm_MessageName', 'MessageName')
DLib.util.AccessorFuncJIT(messageMeta, 'm_isUnreliable', 'Unreliable')

function messageMeta:SendToServer()
	if SERVER then error('Not a client!') end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, self:GetUnreliable())

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.SendToServer()
end

local function CheckSendInput(targets)
	local inputType = type(targets)

	if inputType ~= 'CRecipientFilter' and inputType ~= 'Player' and inputType ~= 'table' then
		error('net.Send - unacceptable input! typeof ' .. inputType)
		return false
	end

	if inputType == 'table' and #targets == 0 then
		ErrorNoHalt('net.Send - Possibly a mistake: Input table is empty!')
		return false
	end

	if inputType == 'CRecipientFilter' and targets:GetCount() == 0 then
		ErrorNoHalt('net.Send - Possibly a mistake: Input CRecipientFilter is empty!')
		return false
	end

	return true
end

function messageMeta:Send(targets)
	if CLIENT then error('Not a server!') end
	local status = CheckSendInput(targets)
	if not status then return end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, self:GetUnreliable())

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.Send(targets)
	net.CURRENT_OBJECT_TRACE = nil
end

function messageMeta:SendOmit(targets)
	if CLIENT then error('Not a server!') end
	local status = CheckSendInput(targets)
	if not status then return end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, self:GetUnreliable())

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.SendOmit(targets)
	net.CURRENT_OBJECT_TRACE = nil
end

function messageMeta:SendPAS(targetPos)
	if CLIENT then error('Not a server!') end

	if type(targetPos) ~= 'Vector' then
		error('Invalid vector input. typeof ' .. type(targetPos))
	end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, self:GetUnreliable())

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.SendPAS(targetPos)
	net.CURRENT_OBJECT_TRACE = nil
end

function messageMeta:SendPVS(targetPos)
	if CLIENT then error('Not a server!') end

	if type(targetPos) ~= 'Vector' then
		error('Invalid vector input. typeof ' .. type(targetPos))
	end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, self:GetUnreliable())

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.SendPVS(targetPos)
	net.CURRENT_OBJECT_TRACE = nil
end

function messageMeta:Broadcast()
	if CLIENT then error('Not a server!') end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, self:GetUnreliable())

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.Broadcast()
	net.CURRENT_OBJECT_TRACE = nil
end

function messageMeta:BytesWritten()
	return math.floor(self.length / 4) + 3
end

function messageMeta:BitsWritten()
	return self.length + 24
end

function messageMeta:Seek(moveTo)
	if type(moveTo) ~= 'number' then
		error('Must be a number')
	end

	if moveTo > self.length or moveTo < 0 then
		error('Out of range')
	end

	self.pointer = math.floor(moveTo)
end

function messageMeta:PointerAt()
	return self.pointer
end

function messageMeta:CurrentBit()
	return self.bits[self.pointer] or 0
end

function messageMeta:BitAt(moveTo)
	if type(moveTo) ~= 'number' then
		error('Must be a number')
	end

	if moveTo > self.length or moveTo < 0 then
		error('Out of range')
	end

	return self.bits[math.floor(moveTo)]
end

function messageMeta:WriteBitRaw(bitIn)
	self.pointer = self.pointer + 1
	self.bits[self.pointer] = bitIn
	return self
end

DLib.simpleInclude('net/net_readers.lua')
DLib.simpleInclude('net/net_writers.lua')
