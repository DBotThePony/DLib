
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
local SysTime = SysTime
local string = string

local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

local ReadHeader = nnet.ReadHeader
local WriteBitNative = nnet.WriteBit
local ReadBitNative = nnet.ReadBit

local WriteDataNative = nnet.WriteData
local WriteUIntNative = nnet.WriteUInt
local ReadDataNative = nnet.ReadData
local ReadUIntNative = nnet.ReadUInt

local function ErrorNoHalt(message)
	if not DLib.DEBUG_MODE:GetBool() then return end

	if not DLib.STRICT_MODE:GetBool() then
		return ErrorNoHalt2(traceback(message) .. '\n')
	else
		return error(message)
	end
end

local function ErrorNoHalt3(message)
	if not DLib.DEBUG_MODE:GetBool() then return end
	return ErrorNoHalt2(traceback(message) .. '\n')
end

local messageMeta = DLib.netMessageMeta or {}
DLib.netMessageMeta = messageMeta

function net.CreateMessage(length, read, msg, flags)
	local self = setmetatable({}, messageMeta)
	read = read or false
	length = length or 0

	self.pointer = 0
	self.outboundsScore = 0
	self.bits = {}
	self.isIncoming = read
	self.isReading = read
	self.flags = flags or 0

	if read then
		self:ReadNetwork(length, msg)
	else
		for i = 1, length do
			table.insert(self.bits, 0)
		end
	end

	return self
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

function messageMeta:IsCompressionEffective()
	return self.length >= 600
end

function messageMeta:Compress()
	if self.isReading then error('Compressing incoming message!') end
	return self:AddFlag(net.MESSAGE_COMPRESSED)
end

function messageMeta:CompressNow()
	if not self:IsCompressionEffective() then
		return self
	end

	self.knownForCompression = true

	local compressed = self:CompressBitsBuffer()
	local untouchedBits = self.length % 8
	local bits = table.gcopyRange(self.bits, self.length - untouchedBits + 1, self.length)

	self:ResetBuffer()
	self:WriteData(compressed, #compressed)
	self:WriteBitsRaw(bits)
	self:Seek(0)

	return self
end

function messageMeta:Decompress()
	if self.isReading then error('Compressing incoming message!') end
	return self:RemoveFlag(net.MESSAGE_COMPRESSED)
end

function messageMeta:DecompressNow(length)
	if not self:IsCompressionEffective() then
		return self
	end

	length = length or (self.length - self.length % 8) / 8

	local untouchedBits = self.length % 8
	local bits = table.gcopyRange(self.bits, self.length - untouchedBits + 1, self.length)
	local readBuff = self:ReadData(length)
	local decompressed = util.Decompress(readBuff)

	if not decompressed then
		error('Unable to decompress message! length to decompress - ' .. length .. ' bytes; message length - ' .. self.length .. ' bits (' .. ((self.length - self.length % 8) / 8) .. ' bytes)')
	end

	self:ResetBuffer()
	self:WriteData(decompressed, #decompressed)
	self:WriteBitsRaw(bits)
	self:Seek(0)

	return self
end

function messageMeta:ReadNetwork(length, msg)
	local time = SysTime()
	local bits = length % 32
	local bytes = (length - bits) / 32
	local bitsBuffer = self.bits

	if bytes ~= 0 then
		for byte = 1, bytes do
			local readByte = ReadUIntNative(32)
			local point = #bitsBuffer

			for iteration = 1, 32 do
				local div = readByte % 2
				readByte = (readByte - div) / 2
				bitsBuffer[point + iteration] = div
			end
		end
	end

	for i = 1, bits do
		bitsBuffer[#bitsBuffer + 1] = ReadBitNative()
	end

	local ntime = (SysTime() - time) * 1000

	if self:IsCompressed() then
		self:DecompressNow()
	end

	if ntime > 1 and DLib.DEBUG_MODE:GetBool() then
		DLib.Message('LNetworkMessage:ReadNetwork() - took ' .. string.format('%.2f ms', ntime) .. ' to read ' .. msg .. ' from network!')
	end

	return self
end

function messageMeta:ReadBytesBuffer(buffer, msg)
	local time = SysTime()
	local bytes = buffer.length
	local bitsBuffer = self.bits

	for byte = 1, bytes do
		local readByte = buffer:ReadUByte()
		local point = #bitsBuffer

		for iteration = 1, 8 do
			local div = readByte % 2
			readByte = (readByte - div) / 2
			bitsBuffer[point + iteration] = div
		end
	end

	local ntime = (SysTime() - time) * 1000

	if self:IsCompressed() then
		self:DecompressNow()
	end

	if ntime > 1 and DLib.DEBUG_MODE:GetBool() then
		DLib.Message('LNetworkMessage:ReadBytesBuffer() - took ' .. string.format('%.2f ms', ntime) .. ' to read ' .. msg .. ' from DLib.BytesBuffer!')
	end

	return self
end

function messageMeta:ToBytesBuffer()
	local buffer = DLib.BytesBuffer()
	local bits = self.bits
	local bytes = math.ceil(#bits / 8)

	for byte = 1, bytes do
		local mark = (byte - 1) * 8

		if byte == bytes then
			buffer:WriteUByte(
				(bits[mark + 1] or 0) +
				(bits[mark + 2] or 0) * 0x2 +
				(bits[mark + 3] or 0) * 0x4 +
				(bits[mark + 4] or 0) * 0x8 +
				(bits[mark + 5] or 0) * 0x10 +
				(bits[mark + 6] or 0) * 0x20 +
				(bits[mark + 7] or 0) * 0x40 +
				(bits[mark + 8] or 0) * 0x80
			)
		else
			buffer:WriteUByte(
				bits[mark + 1] +
				bits[mark + 2] * 0x2 +
				bits[mark + 3] * 0x4 +
				bits[mark + 4] * 0x8 +
				bits[mark + 5] * 0x10 +
				bits[mark + 6] * 0x20 +
				bits[mark + 7] * 0x40 +
				bits[mark + 8] * 0x80
			)
		end
	end

	return buffer
end

function messageMeta:HasFlag(flag)
	return self.flags:band(flag) == flag
end

function messageMeta:AddFlag(flag)
	self.flags = self.flags:bor(flag)
	return self
end

function messageMeta:RemoveFlag(flag)
	if self:HasFlag(flag) then
		self.flags = self.flags:bxor(flag)
	end

	return self
end

function messageMeta:ClearFlags()
	self.flags = 0
	return self
end

function messageMeta:IsCompressed()
	return self:HasFlag(net.MESSAGE_COMPRESSED)
end

function messageMeta:WriteNetwork()
	if net.SMART_COMPRESSION:GetBool() and not self.knownForCompression and not self:IsCompressed() and self:BytesWritten() >= net.SMART_COMPRESSION_SIZE:GetInt() then
		self:Compress()
	end

	-- compression is bad with very small messages
	if not self:IsCompressionEffective() then
		self:RemoveFlag(net.MESSAGE_COMPRESSED)
	end

	if net.AllowMessageFlags then
		WriteUIntNative(self.flags, 32)
	else
		return self:WriteNetworkRaw()
	end

	if not self:IsCompressed() then
		return self:WriteNetworkRaw()
	else
		return self:WriteNetworkCompressed()
	end
end

function messageMeta:CompressBitsBuffer()
	local bits = #self.bits
	local bitsArray = self.bits
	local bitsLast = bits % 8
	local bytes = (bits - bitsLast) / 8
	local numbers = {}

	for byte = 1, bytes do
		local mark = (byte - 1) * 8

		numbers[#numbers + 1] =
			bitsArray[mark + 1] +
			bitsArray[mark + 2] * 0x2 +
			bitsArray[mark + 3] * 0x4 +
			bitsArray[mark + 4] * 0x8 +
			bitsArray[mark + 5] * 0x10 +
			bitsArray[mark + 6] * 0x20 +
			bitsArray[mark + 7] * 0x40 +
			bitsArray[mark + 8] * 0x80
	end

	return util.Compress(DLib.string.bcharTable(numbers))
end

function messageMeta:WriteNetworkCompressed()
	local compressed = self:CompressBitsBuffer()

	for i, char in ipairs(DLib.string.bbyte(compressed, 1, #compressed)) do
		WriteUIntNative(char, 8)
	end

	local bits = #self.bits
	local bitsArray = self.bits
	local bitsLast = bits % 8
	local bytes = (bits - bitsLast) / 8

	for i = bytes * 8 + 1, bits do
		WriteBitNative(bitsArray[i])
	end

	return self
end

function messageMeta:WriteNetworkRaw()
	local bits = #self.bits
	local bitsArray = self.bits
	local bitsLast = bits % 32
	local bytes = (bits - bitsLast) / 32

	for byte = 1, bytes do
		local mark = (byte - 1) * 32

		local num =
			bitsArray[mark + 1] +
			bitsArray[mark + 2] * 0x2 +
			bitsArray[mark + 3] * 0x4 +
			bitsArray[mark + 4] * 0x8 +
			bitsArray[mark + 5] * 0x10 +
			bitsArray[mark + 6] * 0x20 +
			bitsArray[mark + 7] * 0x40 +
			bitsArray[mark + 8] * 0x80 +
			bitsArray[mark + 9] * 0x100 +
			bitsArray[mark + 10] * 0x200 +
			bitsArray[mark + 11] * 0x400 +
			bitsArray[mark + 12] * 0x800 +
			bitsArray[mark + 13] * 0x1000 +
			bitsArray[mark + 14] * 0x2000 +
			bitsArray[mark + 15] * 0x4000 +
			bitsArray[mark + 16] * 0x8000 +
			bitsArray[mark + 17] * 0x10000 +
			bitsArray[mark + 18] * 0x20000 +
			bitsArray[mark + 19] * 0x40000 +
			bitsArray[mark + 20] * 0x80000 +
			bitsArray[mark + 21] * 0x100000 +
			bitsArray[mark + 22] * 0x200000 +
			bitsArray[mark + 23] * 0x400000 +
			bitsArray[mark + 24] * 0x800000 +
			bitsArray[mark + 25] * 0x1000000 +
			bitsArray[mark + 26] * 0x2000000 +
			bitsArray[mark + 27] * 0x4000000 +
			bitsArray[mark + 28] * 0x8000000 +
			bitsArray[mark + 29] * 0x10000000 +
			bitsArray[mark + 30] * 0x20000000 +
			bitsArray[mark + 31] * 0x40000000 +
			bitsArray[mark + 32] * 0x80000000

		WriteUIntNative(num, 32)
	end

	for i = bytes * 32 + 1, bits do
		WriteBitNative(bitsArray[i])
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

function messageMeta:ReportOutOfRange(func, bitsToAdd)
	if not DLib.DEBUG_MODE:GetBool() then return end

	if bitsToAdd + self.pointer < self.length then
		ErrorNoHalt(string.format('%s - Read bits amount is smaller than possible! %i bits were provided', func, bitsToAdd))
	else
		self.outboundsScore = self.outboundsScore + bitsToAdd
		ErrorNoHalt(string.format('%s - Read buffer overflow. Message length is %i bits (~%i b/%.2f kb); Pointer: %i, reading %i bits -> %i bits outside from message bounds (%i total).', func, self.length, self.length / 8, self.length / 8192, self.pointer, bitsToAdd, self.pointer + bitsToAdd - self.length, self.outboundsScore))
	end
end

function messageMeta:ReadBuffer(bits, start, movePointer)
	if movePointer == nil then
		movePointer = true
	end

	if not start then
		start = self.pointer + 1
		bits = bits - 1
	end

	local output = {}

	-- print('readbuffer ' .. start .. ' -> ' .. (start + bits))

	for i = start, start + bits do
		if not self.bits[i] then
			error('ReadBuffer - out of range')
		end

		table.insert(output, self.bits[i])
	end

	if movePointer then
		self.pointer = start + bits
	end

	return output
end

function messageMeta:ReadBufferBackward(bits, start, movePointer)
	if movePointer == nil then
		movePointer = true
	end

	if not start then
		start = self.pointer + 1
		bits = bits - 1
	end

	local output = {}

	-- print('readbuffer ' .. start .. ' -> ' .. (start + bits))

	for i = start + bits, start, -1 do
		if not self.bits[i] then
			error('ReadBuffer - out of range')
		end

		table.insert(output, self.bits[i])
	end

	if movePointer then
		self.pointer = start + bits
	end

	return output
end

function messageMeta:ReadBufferDirection(bits, direction, ...)
	if direction then
		return self:ReadBuffer(bits, ...)
	else
		return self:ReadBufferBackward(bits, ...)
	end
end

DLib.util.AccessorFuncJIT(messageMeta, 'm_MessageName', 'MessageName')
DLib.util.AccessorFuncJIT(messageMeta, 'm_isUnreliable', 'Unreliable')

if CLIENT then
	local gotBuffer = {}
	local heavyBuffer = {}

	function messageMeta:SendToServer()
		local strName = self:GetMessageName()
		if not strName then error('Starting a net message without name!') end

		local graph = net.GraphChannels[strName] and net.GraphChannels[strName].id or 'other'

		if graph == 'other' then
			heavyBuffer[strName] = (heavyBuffer[strName] or 0) + (#self.bits + 16) / 8
		end

		gotBuffer[graph] = (gotBuffer[graph] or 0) + (#self.bits + 16) / 8

		nnet.Start(strName, self:GetUnreliable())
		self:WriteNetwork()
		nnet.SendToServer()
		net.CURRENT_OBJECT_TRACE = nil
	end

	local AUTO_REGISTER = CreateConVar('net_graph_dlib_auto', '1', {FCVAR_ARCHIVE}, 'Auto register netmessages which produce heavy traffic as separated group')
	local AUTO_REGISTER_KBYTES = CreateConVar('net_graph_dlib_kbytes', '16', {FCVAR_ARCHIVE}, 'Auto register kilobytes limit per 5 seconds')

	local function flushGraph()
		if not net.GraphUL then return end
		local frame = gotBuffer
		gotBuffer = {}

		local value = 0

		for i, value2 in pairs(frame) do
			value = value + value2
		end

		frame.__TOTAL = value

		if #net.GraphUL >= net.GraphNodesMax then
			table.remove(net.GraphUL, 1)
		end

		table.insert(net.GraphUL, frame)
	end

	local function flushHeavy()
		local frame = heavyBuffer
		heavyBuffer = {}

		if not AUTO_REGISTER:GetBool() then return end
		local value = AUTO_REGISTER_KBYTES:GetFloat() * 1024

		for msgName, bytes in pairs(frame) do
			if bytes >= value then
				net.RegisterGraphGroup('A: ' .. msgName:sub(1, 1):upper() .. msgName:sub(2), msgName)
				net.BindMessageGroup(msgName, msgName)
			end
		end
	end

	timer.Create('DLib.netGraph.UL', 1, 0, flushGraph)
	timer.Create('DLib.netGraph.heavy.UL', 10, 0, flushHeavy)
end

local function CheckSendInput(targets)
	local inputType = type(targets)

	if inputType ~= 'CRecipientFilter' and inputType ~= 'Player' and inputType ~= 'table' then
		error('net.Send - unacceptable input! typeof ' .. inputType .. ' (' .. tostring(targets) .. ')')
		return false
	end

	if inputType == 'table' and #targets == 0 then
		if not net.QUIET_SEND then ErrorNoHalt3('net.Send - Possibly a mistake: Input table is empty!') end
		return false
	end

	if inputType == 'CRecipientFilter' and targets:GetCount() == 0 then
		if not net.QUIET_SEND then ErrorNoHalt3('net.Send - Possibly a mistake: Input CRecipientFilter is empty!') end
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
	self:WriteNetwork()
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
	self:WriteNetwork()
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
	self:WriteNetwork()
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
	self:WriteNetwork()
	nnet.SendPVS(targetPos)
	net.CURRENT_OBJECT_TRACE = nil
end

local game = game
local CurTime = CurTime

function messageMeta:Broadcast()
	if CLIENT then error('Not a server!') end

	local msg = self:GetMessageName()
	if not msg then error('Starting a net message without name!') end

	if not game.SinglePlayer() or CurTime() > 60 then
		nnet.Start(msg, self:GetUnreliable())
		self:WriteNetwork()
		nnet.Broadcast()
	else
		DLib.Message('GMOD BUG: Broadcasting message too early, and game is singleplayer! Doing workaround... Affected message - ' .. self:GetMessageName())

		timer.Simple(0.5, function()
			timer.Simple(0.5, function()
				nnet.Start(msg, self:GetUnreliable())
				self:WriteNetwork()
				nnet.Broadcast()
			end)
		end)
	end

	net.CURRENT_OBJECT_TRACE = nil
end

-- Header 2 bytes + end of message one byte
function messageMeta:BytesWritten()
	return math.floor(self.length / 8) + 3
end

function messageMeta:BitsWritten()
	return self.length
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

function messageMeta:WriteBitsRaw(bitsIn, fixedAmount)
	if fixedAmount == nil or fixedAmount == #bitsIn then
		for i = 1, #bitsIn do
			self.pointer = self.pointer + 1
			self.bits[self.pointer] = bitsIn[i]
		end

		return self
	else
		for i = 1, fixedAmount - #bitsIn do
			self.pointer = self.pointer + 1
			self.bits[self.pointer] = 0
		end

		for i = 1, #bitsIn do
			self.pointer = self.pointer + 1
			self.bits[self.pointer] = bitsIn[i]
		end

		return self
	end
end

function messageMeta:WriteBitsRawBackward(bitsIn, fixedAmount)
	if fixedAmount == nil or fixedAmount == #bitsIn then
		for i = #bitsIn, 1, -1 do
			self.pointer = self.pointer + 1
			self.bits[self.pointer] = bitsIn[i]
		end

		return self
	else
		for i = #bitsIn, 1, -1 do
			self.pointer = self.pointer + 1
			self.bits[self.pointer] = bitsIn[i]
		end

		for i = 1, fixedAmount - #bitsIn do
			self.pointer = self.pointer + 1
			self.bits[self.pointer] = 0
		end

		return self
	end
end

function messageMeta:UnshiftWriteBitsRaw(bitsIn, positionAt)
	local bitsAmount = #self.bits
	local inputAmount = #bitsIn

	for i = bitsAmount, positionAt, -1 do
		self.bits[i + inputAmount] = self.bits[i]
	end

	for i = 1, inputAmount do
		self.bits[i + positionAt] = bitsIn[i]
	end

	return self
end

function messageMeta:MoveBitsBuffer(positionAt, moveUnits, insertBit)
	insertBit = insertBit or 0

	local bitsAmount = #self.bits

	for i = bitsAmount, positionAt, -1 do
		self.bits[i + moveUnits] = self.bits[i]
	end

	for i = 1, moveUnits do
		self.bits[i + positionAt] = insertBit
	end

	return self
end

function messageMeta:WriteBitsRawDirection(bitsIn, fixedAmount, direction)
	if direction then
		return self:WriteBitsRaw(bitsIn, fixedAmount)
	else
		return self:WriteBitsRawBackward(bitsIn, fixedAmount)
	end
end

DLib.simpleInclude('net/net_readers.lua')
DLib.simpleInclude('net/net_writers.lua')
