
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

local toImport

local function ErrorNoHalt(message)
	return ErrorNoHalt2(traceback(message) .. '\n')
end

net.Hooks = net.Hooks or {}
net.Receivers = net.Hooks
local Hooks = net.Hooks

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
			ErrorNoHalt('net.' .. read .. ' - Not currently writing a message.')
			return
		end

		net.CURRENT_SEND_OBJECT[write](net.CURRENT_SEND_OBJECT, ...)
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

	-- print(length, strName)

	net.CURRENT_OBJECT = net.CreateMessage(length, true)
	net.CURRENT_OBJECT:SetMessageName(strName)
	local status = ProtectedCall(function() triggerNetworkEvent(length, ply, net.CURRENT_OBJECT) end)
	net.CURRENT_OBJECT = nil

	if not status then
		DLib.Message('Listener on ' .. strName .. ' has failed!')
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
			--if net[key] then
				--DLib.Message(traceback('Probably better not to do that? net.' .. tostring(key) .. ' (' .. tostring(net[key]) .. ') -> ' .. tostring(value)))
			--end

			net[key] = value
		end
	})
end

if toImport then
	for key, value in pairs(toImport) do
		net.Receive(key, value)
	end
end
