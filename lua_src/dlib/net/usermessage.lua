
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

DLib.usermessage = DLib.usermessage or table.Copy(usermessage)
DLib.nusermessage = DLib.nusermessage or table.Copy(usermessage)
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

	if DLib.DEBUG_MODE:GetBool() then
		DLib.Message('WARNING: ' .. msgName .. ' arrived outside of net library!')
	end

	local data = usermessage.hooks[msgName]

	if not data then
		if DLib.DEBUG_MODE:GetBool() then
			DLib.Message('WARNING: Unhandled usermessage - ' .. msgName)
		end

		return
	end

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
		PreArgs = {...},
		msgName = msgName
	}

	usermessage.hooks_crc[util.CRC(msgName)] = usermessage.hooks[msgName]
end

local messageMeta = DLib.umsgMessageMeta or {}
DLib.umsgMessageMeta = messageMeta
function messageMeta:__index(key)
	if key == 'length' then
		return self.nwobject.length
	elseif key == 'pointer' then
		return self.nwobject.pointer
	end

	return messageMeta[key] or rawget(self, key)
end

debug.getregistry().LUsermessageBuffer = messageMeta

do
	local bridged = {
		'Angle',
		'Entity',
		'Vector',
	}

	for i, map in ipairs(bridged) do
		local fname = 'Read' .. map

		messageMeta[fname] = function(self)
			return self.nwobject[fname](self.nwobject)
		end
	end
end

function messageMeta:ReadString()
	if self.length < self.pointer + 8 then return '' end
	return self.nwobject:ReadString()
end

function messageMeta:ReadFloat()
	if self.length < self.pointer + 32 then return 0 end
	return self.nwobject:ReadFloat()
end

function messageMeta:ReadBool()
	if self.length < self.pointer + 1 then return false end
	return self.nwobject:ReadBool()
end

function messageMeta:ReadChar()
	if self.length < self.pointer + 8 then return 0 end
	return self.nwobject:ReadInt(8)
end

function messageMeta:ReadLong()
	if self.length < self.pointer + 32 then return 0 end
	return self.nwobject:ReadInt(32)
end

function messageMeta:ReadShort()
	if self.length < self.pointer + 16 then return 0 end
	return self.nwobject:ReadInt(16)
end

function messageMeta:ReadVectorNormal()
	return self.nwobject:ReadNormal()
end

function messageMeta:Reset()
	self.nwobject:Seek(32)
end

function messageMeta:ResetFixed()
	self.nwobject:Seek(self.seekFixed)
end

net.receive('dlib.umsg', function(len, ply, networkObject)
	local msgName = tostring(net.ReadUInt(32))
	local data = usermessage.hooks_crc[msgName]

	if not data then
		if not IsValid(ply) and DLib.DEBUG_MODE:GetBool() then
			DLib.Message('Unhandled network message at usermessage channel, CRC32 Header - ' .. msgName)
		end

		return
	end

	networkObject:MoveBitsBuffer(32, (#data.msgName + 1) * 8)
	networkObject:Seek(32)
	networkObject:WriteString(data.msgName)
	local point = networkObject.pointer

	local newObject = {}
	newObject.nwobject = networkObject
	newObject.seekFixed = point
	newObject.player = ply
	newObject.client = ply
	newObject.ply = ply
	setmetatable(newObject, messageMeta)

	local triggerNetworkMessage = data.Function
	local status = ProtectedCall(function() triggerNetworkMessage(newObject, unpack(data.PreArgs, 1, #data.PreArgs)) end)

	if not status then
		DLib.Message('Usermessage hook on ' .. data.msgName .. ' has failed!')
	end
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
