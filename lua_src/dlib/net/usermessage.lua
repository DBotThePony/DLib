
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

DLib.usermessage = DLib.usermessage or table.Copy(usermessage)
local gusermessage = usermessage
local usermessage = DLib.usermessage
usermessage.hooks = usermessage.hooks or {}
usermessage.hooks_crc = usermessage.hooks_crc or {}

local DLib = DLib
local type = type
local error = error
local player = player
local tonumber = tonumber
local util = util
local traceback = debug.traceback
local net = DLib.netModule
local unpack = unpack
local tostring = tostring
local IsValid = IsValid
local setmetatable = setmetatable

function usermessage.GetTable()
	return usermessage.hooks
end

function usermessage.IncomingMessage(msgName, msgBuffer)
	msgName = msgName:lower()

	DLib.Message('WARNING: ' .. msgName .. ' arrived outside of net library!')

	local data = usermessage.hooks[msgName]
	if not data then DLib.Message('WARNING: Unhandled usermessage - ' .. msgName) return end

	local triggerNetworkMessage = data.Function
	triggerNetworkMessage(msgBuffer, unpack(data.PreArgs, 1, #data.PreArgs))
end

function usermessage.Hook(msgName, funcIn, ...)
	if type(msgName) ~= 'string' then
		error('usermessage.Hook - msgName is not a string!')
	end

	if type(funcIn) ~= 'function' then
		error('usermessage.Hook - function is not a function!')
	end

	usermessage.hooks[msgName] = {
		Function = funcIn,
		PreArgs = {...}
	}

	usermessage.hooks_crc[util.CRC(msgName)] = usermessage.hooks[msgName]
end

local messageMeta = DLib.umsgMessageMeta or {}
DLib.umsgMessageMeta = messageMeta
messageMeta.__index = messageMeta

debug.getregistry().LUsermessageBuffer = messageMeta

do
	local bridged = {
		'Angle',
		'Bool',
		'Entity',
		'Float',
		'String',
		'Vector',
	}

	for i, map in ipairs(bridged) do
		local fname = 'Read' .. map

		messageMeta[fname] = function()
			return self.nwobject[fname](self.nwobject)
		end
	end
end

function messageMeta:ReadChar()
	return self.nwobject:ReadInt(8)
end

function messageMeta:ReadLong()
	return self.nwobject:ReadInt(32)
end

function messageMeta:ReadShort()
	return self.nwobject:ReadInt(16)
end

function messageMeta:ReadVectorNormal()
	return self.nwobject:ReadNormal()
end

function messageMeta:Reset()
	self.nwobject:Reset()
end

net.receive('dlib.umsg', function(len, ply, networkObject)
	local msgName = tostring(net.ReadUInt(32))
	local data = usermessage.hooks_crc[msgName]

	if not data then
		if not IsValid(ply) then
			DLib.Message('Unhandled network message at usermessage channel, CRC32 Header - ' .. msgName)
		end

		return
	end

	local newObject = {}
	newObject.nwobject = networkObject
	setmetatable(newObject, messageMeta)
	local triggerNetworkMessage = data.Function
	triggerNetworkMessage(newObject, unpack(data.PreArgs, 1, #data.PreArgs))
end)

if gusermessage ~= DLib.gusermessage then
	DLib.gusermessage = gusermessage

	for msgName, data in pairs(gusermessage.GetTable()) do
		usermessage.Hook(msgName, data.Function, unpack(data.PreArgs, 1, #data.PreArgs))
	end
end

gusermessage.GetTable = usermessage.GetTable
gusermessage.IncomingMessage = usermessage.IncomingMessage
gusermessage.Hook = usermessage.Hook
