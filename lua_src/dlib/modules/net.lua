
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

DLib.netModule = DLib.netModule or {}
DLib.nativeNet = DLib.nativeNet or net

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

local NetworkIDToString = util.NetworkIDToString
local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

local ReadHeader = nnet.ReadHeader
local WriteBitNative = nnet.WriteBit
local ReadBitNative = nnet.ReadBit

local function ErrorNoHalt(message)
	return ErrorNoHalt2(traceback(message) .. '\n')
end

net.Hooks = net.Hooks or {}
net.Receivers = net.Hooks
local Hooks = net.Hooks

function net.GetTable()
	return net.Hooks
end

function net.Receive(messageID, funcIn)
	if type(messageID) ~= 'string' then
		ErrorNoHalt('net.Receive: argument №1 is not a string! typeof ' .. type(messageID))
		return
	end

	if type(funcIn) ~= 'function' then
		ErrorNoHalt('net.Receive: argument №2 is not a function! typeof ' .. type(funcIn))
		return
	end

	net.Hooks[messageID:lower()] = funcIn
end

net.pool = util.AddNetworkString
net.receive = net.Receive

local CURRENT_OBJECT
local CURRENT_SEND_OBJECT

function net.Incoming2(length, ply)
	local indetifier = ReadHeader()
	local strName = NetworkIDToString(indetifier)
	if not strName then return end

	strName = strName:lower()
	local triggerNetworkEvent = Hooks[strName]

	if not triggerNetworkEvent then
		DLib.Message('Unhandled message at net channel: ' .. strName)
		return
	end

	length = length - 16
	local status = ProtectedCall(function() triggerNetworkEvent(length, ply) end)

	if not status then
		DLib.Message('Listener on ' .. strName .. ' has failed!')
	end
end

function net.Incoming(...)
	return net.Incoming2(...)
end

local messageMeta = {}
local messageLookup = {
	__index = function(self, key)
		if key == 'length' then
			return #self.bits
		end

		local val = messageMeta[key]

		if val ~= nil then
			return val
		end

		return rawget(self, key)
	end
}

function net.CreateMessage(length, read)
	local obj = setmetatable({}, messageLookup)
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
end

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

DLib.util.AccessorFuncJIT(messageMeta, 'm_MessageName', 'MessageName')

function messageMeta:SendToServer(messageName)
	if SERVER then error('Not a client!') end
	if messageName then self:SetMessageName(messageName) end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg)

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
		ErrorNoHalt('Input table is empty!')
		return false
	end

	if inputType == 'CRecipientFilter' and targets:GetCount() == 0 then
		ErrorNoHalt('Input CRecipientFilter is empty!')
		return false
	end

	return true
end

function messageMeta:Send(targets, unreliable, messageName)
	if CLIENT then error('Not a server!') end
	if messageName then self:SetMessageName(messageName) end
	local status = CheckSendInput(targets)
	if not status then return end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, unreliable)

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.Send(targets)
end

function messageMeta:SendOmit(targets, unreliable, messageName)
	if CLIENT then error('Not a server!') end
	if messageName then self:SetMessageName(messageName) end
	local status = CheckSendInput(targets)
	if not status then return end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, unreliable)

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.SendOmit(targets)
end

function messageMeta:SendPAS(targetPos, unreliable, messageName)
	if CLIENT then error('Not a server!') end
	if messageName then self:SetMessageName(messageName) end

	if type(targetPos) ~= 'Vector' then
		error('Invalid vector input. typeof ' .. type(targetPos))
	end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, unreliable)

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.SendPAS(targetPos)
end

function messageMeta:SendPVS(targetPos, unreliable, messageName)
	if CLIENT then error('Not a server!') end
	if messageName then self:SetMessageName(messageName) end

	if type(targetPos) ~= 'Vector' then
		error('Invalid vector input. typeof ' .. type(targetPos))
	end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, unreliable)

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.SendPVS(targetPos)
end

function messageMeta:Broadcast(unreliable, messageName)
	if CLIENT then error('Not a server!') end
	if messageName then self:SetMessageName(messageName) end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	nnet.Start(msg, unreliable)

	for i, bit in ipairs(self.bits) do
		WriteBitNative(bit)
	end

	nnet.Broadcast()
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

function messageMeta:WriteBit(bitIn)
	if self.isReading then error('Message is read-only') end

	if type(bitIn) == 'boolean' then
		bitIn = bitIn and 1 or 0
	end

	if type(bitIn) ~= 'number' then
		error('Must be a number')
	end

	local input = math.floor(bitIn) ~= 0 and 0 or 1
	self.pointer = self.pointer + 1
	self.bits[self.pointer] = input
end

messageMeta.WriteBool = messageMeta.WriteBit

function messageMeta:WriteInt(input, bitCount)
	input = tonumber(input)
	bitCount = tonumber(bitCount)
	if type(input) ~= 'number' then error('Input is not a number!') end
	if type(bitCount) ~= 'number' then error('Bit amount is not a number!') end

	input = math.floor(input + 0.5)
	bitCount = math.floor(bitCount)
	if bitCount > 126 or bitCount < 1 then error('Bit amount overflow') end
end
