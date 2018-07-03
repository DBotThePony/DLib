
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

if SERVER then
	net.pool('dlib.umsg')
end

DLib.umsg = DLib.umsg or table.Copy(umsg or {})
DLib.numsg = DLib.numsg or table.Copy(umsg or {})
local gumsg = umsg
local umsg = DLib.umsg

local DLib = DLib
local type = type
local error = error
local player = player
local tonumber = tonumber
local util = util
local traceback = debug.traceback
local net = DLib.netModule

local isWrittingMessage = false
local oldTrace, cPlayers
local currentMessagePayload = {}
local currentMessageName

function umsg.Start(strIn, pFilter)
	if type(strIn) ~= 'string' then
		error('umsg.Start - string name is not a string!')
	end

	if SERVER and type(pFilter) ~= 'Player' and type(pFilter) ~= 'CRecipientFilter' and type(pFilter) ~= 'table' then
		pFilter = player.GetAll()
	end

	if isWrittingMessage then
		if DLib.DEBUG_MODE:GetBool() then
			DLib.Message('umsg.Start - starting new message without finishing old one!\nOLD ->\n' .. oldTrace .. '\nNEW:\n' .. traceback())
		end
	end

	oldTrace = traceback()
	isWrittingMessage = true
	cPlayers = pFilter
	currentMessagePayload = {}

	--net.Start('dlib.umsg')
	--net.WriteUInt(tonumber(util.CRC(strIn)), 32)
	currentMessageName = strIn
end

function umsg.End()
	if not isWrittingMessage then
		error('umsg.End - not currently writting a message')
	end

	isWrittingMessage = false
	oldTrace = nil

	net.Start('dlib.umsg')
	net.WriteUInt(tonumber(util.CRC(currentMessageName)), 32)

	for i, payload in ipairs(currentMessagePayload) do
		payload()
	end

	if SERVER then
		net.QUIET_SEND = true
		net.Send(cPlayers)
		net.QUIET_SEND = false
	else
		net.SendToServer()
	end

	currentMessagePayload = nil
	currentMessageName = nil
end

local payloadFunctions = {
	'Angle',
	'Entity',
	'Float',
	'Vector',
	'String',
	'Bool',
	'Char',
	'Long',
	'Short',
	'VectorNormal',
}

do
	local mappings = {
		'Angle',
		'Entity',
		'Float',
		'Vector',
	}

	for i, map in ipairs(mappings) do
		umsg[map] = net['Write' .. map]
	end
end

function umsg.String(stringIn)
	net.WriteString(tostring(stringIn or ''))
end

function umsg.Bool(bitIn)
	net.WriteBool(tobool(bitIn))
end

function umsg.Char(valueIn)
	net.WriteInt(valueIn, 8)
end

function umsg.Long(valueIn)
	net.WriteInt(valueIn, 32)
end

function umsg.Short(valueIn)
	net.WriteInt(valueIn, 16)
end

-- many thanks to developers who used this function
function umsg.PoolString()

end

umsg.VectorNormal = net.WriteNormal

for i, payloadName in ipairs(payloadFunctions) do
	local payload = umsg[payloadName]

	if not payload then
		error('No payload function for ' .. payloadName .. '!')
	end

	umsg[payloadName] = function(value)
		if not isWrittingMessage then
			error('umsg.' .. payloadName .. ' - not currently writting a message')
		end

		table.insert(currentMessagePayload, function()
			payload(value)
		end)
	end
end

if not gumsg then
	gumsg = {}
	_G.umsg = gumsg
end

for key, value in pairs(umsg) do
	gumsg[key] = value
	rawset(gumsg, key, value)
end
