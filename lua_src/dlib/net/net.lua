
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

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

		return CURRENT_OBJECT[write](CURRENT_OBJECT, ...)
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
	local status = ProtectedCall(function() triggerNetworkEvent(length, ply) end)

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

DLib.simpleInclude('net/net_object.lua')
