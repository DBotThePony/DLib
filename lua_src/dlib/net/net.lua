
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
local NetworkStringToID = util.NetworkStringToID
local traceback = debug.traceback
local nnet = DLib.nativeNet
local net = DLib.netModule

net.NetworkIDToString = NetworkIDToString
net.NetworkStringToID = NetworkStringToID

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

net.CURRENT_OBJECT_TRACE = nil

local CURRENT_OBJECT
local CURRENT_SEND_OBJECT

function net.RegisterWrapper(nameIn)
	local read, write = 'Read' .. nameIn, 'Write' .. nameIn

	net[read] = function(...)
		if not CURRENT_OBJECT then
			ErrorNoHalt('Not currently reading a message.')
			return
		end

		return CURRENT_OBJECT[read](CURRENT_OBJECT, ...)
	end

	net[write] = function(...)
		if not CURRENT_SEND_OBJECT then
			ErrorNoHalt('Not currently writing a message.')
			return
		end

		return CURRENT_SEND_OBJECT[write](CURRENT_SEND_OBJECT, ...)
	end
end

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

	-- safety rule, read extra 7 bits to make sure we are received entrie message
	CURRENT_OBJECT = net.CreateMessage((length - 3) * 8 + 7, true)
	CURRENT_OBJECT:SetMessageName(strName)
	local status = ProtectedCall(function() triggerNetworkEvent(length, ply, CURRENT_OBJECT) end)

	if not status then
		DLib.Message('Listener on ' .. strName .. ' has failed!')
	end
end

function net.Incoming(...)
	return net.Incoming2(...)
end

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

function net.Start(messageName, unreliable)
	if not messageName then
		error('net.Start - no message name was specified at all!')
	end

	if type(messageName) ~= 'string' or type(messageName) ~= 'number' then
		error('net.Start - input name is not a string and not a number!')
	end

	if type(messageName) ~= 'number' then
		local num = messageName
		messageName = NetworkIDToString(messageName)

		if not messageName then
			error('net.Send - no such a network string with ID ' .. num)
		end
	end

	messageName = messageName:lower()
	local convert = NetworkStringToID(messageName)
	unreliable = unreliable or false

	if convert == 0 then
		error('Starting unpooled message! Messages MUST be pooled first, because of bandwidth reasons. http://wiki.garrysmod.com/page/util/AddNetworkString')
	end

	if net.CURRENT_OBJECT_TRACE then
		ErrorNoHalt2('Starting new net message without finishing old one!\n------------------------\nOLD:\n' .. net.CURRENT_OBJECT_TRACE .. '\n------------------------\nNEW:\n' .. traceback())
	end

	net.CURRENT_OBJECT_TRACE = traceback()

	CURRENT_SEND_OBJECT = net.CreateMessage(0, false)
	CURRENT_SEND_OBJECT:SetUnreliable(unreliable)
	CURRENT_SEND_OBJECT:SetMessageName(messageName)

	return true, CURRENT_SEND_OBJECT
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

	for i, func in ipairs(sendFuncs) do
		net[func] = function(...)
			if not CURRENT_SEND_OBJECT then
				ErrorNoHalt('net. - Not currently writing a message.')
				return
			end

			return CURRENT_SEND_OBJECT[func](CURRENT_SEND_OBJECT, ...)
		end
	end
end

DLib.simpleInclude('net/net_object.lua')
DLib.simpleInclude('net/net_ext.lua')

net.RegisterWrapper('Bit')
net.RegisterWrapper('Data')
net.RegisterWrapper('String')
net.RegisterWrapper('Double')
net.RegisterWrapper('Bool')
net.RegisterWrapper('Entity')
net.RegisterWrapper('Vector')
net.RegisterWrapper('Angle')
net.RegisterWrapper('Matrix')
net.RegisterWrapper('Color')
net.RegisterWrapper('Table')
net.RegisterWrapper('Float')
net.RegisterWrapper('Int')
net.RegisterWrapper('UInt')
net.RegisterWrapper('Normal')
net.RegisterWrapper('Type')
net.RegisterWrapper('Header')
