
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

local table = table
local DLib = DLib

-- this WILL break EPOE
-- local MsgC = MsgC
-- local Msg = Msg

local type = type
local net = net

local function RepackMessage(strIn)
	local output = {}

	for line in string.gmatch(strIn, '([^ ]+)') do
		if #output ~= 0 then
			table.insert(output, ' ')
		end

		table.insert(output, line)
	end

	return output
end

local DEFAULT_TEXT_COLOR = Color(200, 200, 200)
local BOOLEAN_COLOR = Color(33, 83, 226)
local NUMBER_COLOR = Color(245, 199, 64)
local STEAMID_COLOR = Color(255, 255, 255)
local ENTITY_COLOR = Color(180, 232, 180)
local FUNCTION_COLOR = Color(62, 106, 255)
local TABLE_COLOR = Color(107, 200, 224)
local URL_COLOR = Color(174, 124, 192)

local function FormatMessageInternal(tabIn)
	local prevColor = DEFAULT_TEXT_COLOR
	local output = {prevColor}

	for i, val in ipairs(tabIn) do
		local valType = type(val)

		if valType == 'number' then
			table.insert(output, NUMBER_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'string' then
			if val:find('^https?://') then
				table.insert(output, URL_COLOR)
				table.insert(output, val)
				table.insert(output, prevColor)
			else
				table.insert(output, val)
			end
		elseif valType == 'Player' then
			if team then
				table.insert(output, team.GetColor(val:Team()) or ENTITY_COLOR)
			else
				table.insert(output, ENTITY_COLOR)
			end

			table.insert(output, val:Nick())

			if val.SteamName and val:SteamName() ~= val:Nick() then
				table.insert(output, ' (' .. val:SteamName() .. ')')
			end

			table.insert(output, STEAMID_COLOR)
			table.insert(output, '<')
			table.insert(output, val:SteamID())
			table.insert(output, '>')
			table.insert(output, prevColor)
		elseif valType == 'Entity' or valType == 'NPC' or valType == 'Vehicle' then
			table.insert(output, ENTITY_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'table' then
			if val.r and val.g and val.b then
				table.insert(output, val)
				prevColor = val
			else
				table.insert(output, TABLE_COLOR)
				table.insert(output, tostring(val))
				table.insert(output, prevColor)
			end
		elseif valType == 'function' then
			table.insert(output, FUNCTION_COLOR)
			table.insert(output, string.format('function - %p', val))
			table.insert(output, prevColor)
		elseif valType == 'boolean' then
			table.insert(output, BOOLEAN_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		else
			table.insert(output, tostring(val))
		end
	end

	return output
end

local LocalPlayer = LocalPlayer

return function(tableTarget, moduleName, moduleColor)
	local nwname = 'DLib.Message.' .. util.CRC(moduleName)
	local nwnameL = 'DLib.Message.' .. util.CRC(moduleName) .. '.L'

	if SERVER then
		net.pool(nwname)
		net.pool(nwnameL)
	end

	if net.BindMessageGroup then
		net.BindMessageGroup(nwname, 'dlibmessages')
		net.BindMessageGroup(nwnameL, 'dlibmessages')
	end

	local PREFIX = '[' .. moduleName .. '] '
	local PREFIX_COLOR = moduleColor or Color(0, 200, 0)

	local function Message(...)
		local formatted = FormatMessageInternal({...})
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function LMessage(...)
		local formatted = FormatMessageInternal(DLib.i18n.rebuildTable({...}))
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function Chat(...)
		local formatted = FormatMessageInternal({...})
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function LChat(...)
		local formatted = FormatMessageInternal(DLib.i18n.rebuildTable({...}))
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function FormatMessage(...)
		return FormatMessageInternal({PREFIX_COLOR, PREFIX, DEFAULT_TEXT_COLOR, ...})
	end

	local function LFormatMessage(...)
		return FormatMessageInternal(DLib.i18n.rebuildTable({PREFIX_COLOR, PREFIX, DEFAULT_TEXT_COLOR, ...}))
	end

	local function MessagePlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return Message(...) end
		if CLIENT then return end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwname)
			net.WriteArray({...})
			net.Send(ply)
		else
			Message(...)
		end
	end

	local function LMessagePlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return LMessage(...) end
		if CLIENT then return end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwnameL)
			net.WriteArray({...})
			net.Send(ply)
		else
			LMessage(...)
		end
	end

	if CLIENT then
		net.receive(nwname, function()
			local array = net.ReadArray()
			Message(unpack(array))
		end)

		net.receive(nwnameL, function()
			local array = net.ReadArray()
			LMessage(unpack(array))
		end)
	end

	local function export(tableTo)
		tableTo.Message = Message
		tableTo.LMessage = LMessage
		tableTo.message = Message
		tableTo.lmessage = LMessage
		tableTo.RepackMessage = RepackMessage
		tableTo.repackMessage = RepackMessage
		tableTo.FormatMessage = FormatMessage
		tableTo.formatMessage = FormatMessage
		tableTo.LFormatMessage = LFormatMessage
		tableTo.lformatMessage = LFormatMessage
		tableTo.prefix = PREFIX
		tableTo.textcolor = DEFAULT_TEXT_COLOR

		if CLIENT then
			tableTo.Chat = Chat
			tableTo.ChatMessage = Chat
			tableTo.ChatPrint = Chat
			tableTo.AddChat = Chat
			tableTo.chatMessage = Chat

			tableTo.LChat = LChat
			tableTo.LChatMessage = LChat
			tableTo.LChatPrint = LChat
			tableTo.LAddChat = LChat
			tableTo.lchatMessage = LChat
		end

		tableTo.MessagePlayer = MessagePlayer
		tableTo.messagePlayer = MessagePlayer
		tableTo.messageP = MessagePlayer

		tableTo.LMessagePlayer = LMessagePlayer
		tableTo.lmessagePlayer = LMessagePlayer
		tableTo.lmessageP = LMessagePlayer
	end

	tableTarget = tableTarget or {}
	export(tableTarget)
	return export, tableTarget
end
