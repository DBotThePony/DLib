
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
DLib.nativeNet = DLib.nativeNet or table.Copy(_G.net)

local DLib = DLib
local util = util
local gnet = _G.net
local type = type
local debug = debug
local ErrorNoHalt2 = ErrorNoHalt
local table = table
local ipairs = ipairs
local pairs = pairs
local math = math
local ProtectedCall = ProtectedCall

local NetworkIDToString = util.NetworkIDToString
local NetworkStringToID = util.NetworkStringToID
local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

net.NetworkIDToString = NetworkIDToString
net.NetworkStringToID = NetworkStringToID

local ReadHeader = nnet.ReadHeader
local WriteBitNative = nnet.WriteBit
local ReadBitNative = nnet.ReadBit
local ReadUIntNative = nnet.ReadUInt

local toImport

local function ErrorNoHalt(message)
	if not DLib.DEBUG_MODE:GetBool() then return end
	return ErrorNoHalt2(traceback(message) .. '\n')
end

net.SMART_COMPRESSION = CreateConVar('dlib_net_compress', '0', {FCVAR_REPLICATED}, 'Enable smart network compression')
net.SMART_COMPRESSION_SIZE = CreateConVar('dlib_net_compress_s', '2000', {FCVAR_REPLICATED}, 'Message size (in bytes) before set Compression flag')

net.Hooks = net.Hooks or {}
net.Receivers = net.Hooks
local Hooks = net.Hooks

-- set this to false if you want to debug
-- dlib network library with native net library
-- (DLib.nativeNet)
net.AllowMessageFlags = true

net.NO_FLAGS = 0x0
net.MESSAGE_COMPRESSED = 0x2
net.MESSAGE_FRAGMENTED = 0x4
net.MESSAGE_BUFFERED = 0x8
net.MESSAGE_CONTAINS_MULTIPLE = 0x10
net.MESSAGE_ORDERED = 0x20

if gnet.Receivers ~= net.Receivers then
	toImport = gnet.Receivers
end

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

net.CURRENT_OBJECT_TRACE = nil
net.CURRENT_OBJECT = nil
net.CURRENT_SEND_OBJECT = nil

function net.Reset()
	if not net.CURRENT_OBJECT then
		error('net.Reset - not currently reading net message')
	end

	net.CURRENT_OBJECT:Reset()
	return net.CURRENT_OBJECT
end

function net.RegisterWrapper(nameIn)
	local read, write = 'Read' .. nameIn, 'Write' .. nameIn

	net[read] = function(...)
		if not net.CURRENT_OBJECT then
			ErrorNoHalt('net.' .. read .. ' - Not currently reading a message.')
			return
		end

		return net.CURRENT_OBJECT[read](net.CURRENT_OBJECT, ...)
	end

	net[write] = function(...)
		if not net.CURRENT_SEND_OBJECT then
			ErrorNoHalt('net.' .. write .. ' - Not currently writing a message.')
			return
		end

		net.CURRENT_SEND_OBJECT[write](net.CURRENT_SEND_OBJECT, ...)
	end
end

do
	local gotBuffer = {}
	local heavyBuffer = {}

	function net.Incoming2(length, ply)
		local indetifier = ReadHeader()
		local strName = NetworkIDToString(indetifier)
		if not strName then return end

		strName = strName:lower()

		if CLIENT then
			local graph = net.GraphChannels[strName] and net.GraphChannels[strName].id or 'other'

			if graph == 'other' then
				heavyBuffer[strName] = (heavyBuffer[strName] or 0) + length / 8
			end

			gotBuffer[graph] = (gotBuffer[graph] or 0) + length / 8
		end

		local triggerNetworkEvent = Hooks[strName]

		if not triggerNetworkEvent then
			DLib.Message('Unhandled message at net channel: ' .. strName)
			return
		end

		local flags = 0

		if net.AllowMessageFlags then
			flags = ReadUIntNative(32)
			length = length - 32
		end

		length = length - 16

		net.CURRENT_OBJECT = net.CreateMessage(length, true, strName, flags)
		net.CURRENT_OBJECT:SetMessageName(strName)
		local status = ProtectedCall(function() triggerNetworkEvent(length, ply, net.CURRENT_OBJECT) end)
		net.CURRENT_OBJECT = nil

		if not status then
			DLib.Message('Listener on ' .. strName .. ' has failed!')
		end
	end

	if CLIENT then
		local AUTO_REGISTER = CreateConVar('net_graph_dlib_auto', '1', {FCVAR_ARCHIVE}, 'Auto register netmessages which produce heavy traffic as separated group')
		local AUTO_REGISTER_KBYTES = CreateConVar('net_graph_dlib_kbytes', '16', {FCVAR_ARCHIVE}, 'Auto register kilobytes limit per 5 seconds')

		local function flushGraph()
			local frame = gotBuffer
			gotBuffer = {}

			local value = 0

			for i, value2 in pairs(frame) do
				value = value + value2
			end

			frame.__TOTAL = value

			if #net.Graph >= net.GraphNodesMax then
				table.remove(net.Graph, 1)
			end

			table.insert(net.Graph, frame)

			net.RecalculateGraphScales()
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

		timer.Create('DLib.netGraph', 1, 0, flushGraph)
		timer.Create('DLib.netGraph.heavy', 10, 0, flushHeavy)
	end
end

function net.Incoming(...)
	return net.Incoming2(...)
end

function net.Start(messageName, unreliable)
	if not messageName then
		error('net.Start - no message name was specified at all!', 2)
	end

	if type(messageName) ~= 'string' and type(messageName) ~= 'number' then
		error('net.Start - input name is not a string and is not a number!', 2)
	end

	if type(messageName) == 'number' then
		local num = messageName
		messageName = NetworkIDToString(messageName)

		if not messageName then
			error('net.Send - no such a network string with ID ' .. num, 2)
		end
	end

	messageName = messageName:lower()
	local convert = NetworkStringToID(messageName)
	unreliable = unreliable or false

	if convert == 0 then
		error('Starting unpooled message! Messages MUST be pooled first, because of bandwidth reasons. http://wiki.garrysmod.com/page/util/AddNetworkString', 2)
	end

	if net.CURRENT_OBJECT_TRACE then
		DLib.Message('Starting new net message without finishing old one!\n------------------------\nOLD:\n' .. net.CURRENT_OBJECT_TRACE .. '\n------------------------\nNEW:\n' .. traceback())
	end

	net.CURRENT_OBJECT_TRACE = traceback()

	net.CURRENT_SEND_OBJECT = net.CreateMessage(0, false)
	net.CURRENT_SEND_OBJECT:SetUnreliable(unreliable)
	net.CURRENT_SEND_OBJECT:SetMessageName(messageName)

	return true, net.CURRENT_SEND_OBJECT
end

do
	local sendFuncs = {
		'Send',
		'SendOmit',
		'SendPAS',
		'SendPVS',
		'Broadcast',
		'SendToServer'
	}

	local sendFuncs2 = {
		'BitsWritten',
		'BytesWritten',
	}

	local sendFuncs3 = {
		CompressOngoing = 'Compress',
		CompressOngoingNow = 'CompressNow',
		DecompressOngoing = 'Decompress',
		DecompressOngoingNow = 'DecompressNow',
	}

	local sendFuncs4 = {
		CompressReceivedNow = 'CompressNow',
		DecompressReceivedNow = 'DecompressNow',
	}

	for i, func in ipairs(sendFuncs) do
		net[func] = function(...)
			if not net.CURRENT_SEND_OBJECT then
				ErrorNoHalt('net.' .. func .. ' - Not currently writing a message.')
				return
			end

			local obj = net.CURRENT_SEND_OBJECT
			net.CURRENT_SEND_OBJECT = nil
			net.CURRENT_OBJECT_TRACE = nil

			obj[func](obj, ...)
		end
	end

	for i, func in ipairs(sendFuncs2) do
		net[func] = function(...)
			if not net.CURRENT_SEND_OBJECT then
				ErrorNoHalt('net.' .. func .. ' - Not currently writing a message.')
				return
			end

			return net.CURRENT_SEND_OBJECT[func](net.CURRENT_SEND_OBJECT, ...)
		end
	end

	for func1, func2 in pairs(sendFuncs3) do
		net[func1] = function(...)
			if not net.CURRENT_SEND_OBJECT then
				ErrorNoHalt('net.' .. func1 .. ' - Not currently writing a message.')
				return
			end

			return net.CURRENT_SEND_OBJECT[func2](net.CURRENT_SEND_OBJECT, ...)
		end
	end

	for func1, func2 in pairs(sendFuncs4) do
		net[func1] = function(...)
			if not net.CURRENT_OBJECT then
				ErrorNoHalt('net.' .. func1 .. ' - Not currently reading a message.')
				return
			end

			return net.CURRENT_OBJECT[func2](net.CURRENT_OBJECT, ...)
		end
	end
end

DLib.simpleInclude('net/net_object.lua')
DLib.simpleInclude('net/net_ext.lua')

net.RegisterWrapper('Bit')
net.RegisterWrapper('Data')
net.RegisterWrapper('String')
net.RegisterWrapper('StringBackward')
net.RegisterWrapper('StringForward')
net.RegisterWrapper('Double')
net.RegisterWrapper('Bool')
net.RegisterWrapper('Entity')
net.RegisterWrapper('Vector')
net.RegisterWrapper('Angle')
net.RegisterWrapper('Matrix')
net.RegisterWrapper('Color')
net.RegisterWrapper('Table')
net.RegisterWrapper('Float')
net.RegisterWrapper('FloatBackward')
net.RegisterWrapper('FloatForward')
net.RegisterWrapper('Int')
net.RegisterWrapper('IntTwos')
net.RegisterWrapper('IntForward')
net.RegisterWrapper('IntTwosForward')
net.RegisterWrapper('IntForwardTwos')
net.RegisterWrapper('IntBackward')
net.RegisterWrapper('IntTwosBackward')
net.RegisterWrapper('IntBackwardTwos')
net.RegisterWrapper('UInt')
net.RegisterWrapper('UIntBackward')
net.RegisterWrapper('UIntForward')
net.RegisterWrapper('Normal')
net.RegisterWrapper('Type')
net.RegisterWrapper('Header')
net.RegisterWrapper('Number')

if DLib.gNet ~= gnet then
	DLib.gNet = gnet

	for key, value in pairs(gnet) do
		rawset(gnet, key, nil)
	end

	setmetatable(gnet, {
		__index = function(self, key)
			return net[key]
		end,

		__newindex = function(self, key, value)
			if DLib.DEBUG_MODE:GetBool() and net[key] then
				DLib.Message(traceback('Probably better not to do that? net.' .. tostring(key) .. ' (' .. tostring(net[key]) .. ') -> ' .. tostring(value)))
			end

			net[key] = value
		end
	})
end

local messageMeta = FindMetaTable('LNetworkMessage')

function messageMeta:WriteColor(colIn)
	if not IsColor(colIn) then
		error('Attempt to write a color which is not a color! ' .. type(colIn))
	end

	self:WriteUInt(colIn.r, 8)
	self:WriteUInt(colIn.g, 8)
	self:WriteUInt(colIn.b, 8)
	self:WriteUInt(colIn.a, 8)

	return self
end

function messageMeta:ReadColor()
	return Color(self:ReadUInt(8), self:ReadUInt(8), self:ReadUInt(8), self:ReadUInt(8))
end

net.RegisterWrapper('Color')

if toImport then
	for key, value in pairs(toImport) do
		net.Receive(key, value)
	end
end

DLib.simpleInclude('net/umsg.lua')
DLib.simpleInclude('net/usermessage.lua')
DLib.simpleInclude('net/net_graph.lua')
