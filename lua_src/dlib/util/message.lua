
-- Copyright (C) 2017-2018 DBot

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.


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
local WARNING_COLOR = Color(239, 215, 52)
local ERROR_COLOR = Color(239, 78, 52)
local BOOLEAN_COLOR = Color(33, 83, 226)
local NUMBER_COLOR = Color(245, 199, 64)
local STEAMID_COLOR = Color(255, 255, 255)
local ENTITY_COLOR = Color(180, 232, 180)
local FUNCTION_COLOR = Color(62, 106, 255)
local TABLE_COLOR = Color(107, 200, 224)
local URL_COLOR = Color(174, 124, 192)

local function __Format(tabIn, prevColor, output)
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
end

local function FormatMessageRegular(tabIn)
	local prevColor = DEFAULT_TEXT_COLOR
	local output = {prevColor}

	__Format(tabIn, prevColor, output)

	return output
end

local function FormatMessageWarning(tabIn)
	local prevColor = WARNING_COLOR
	local output = {prevColor}

	__Format(tabIn, prevColor, output)

	return output
end

local function FormatMessageError(tabIn)
	local prevColor = ERROR_COLOR
	local output = {prevColor}

	__Format(tabIn, prevColor, output)

	return output
end

local LocalPlayer = LocalPlayer

return function(tableTarget, moduleName, moduleColor)
	local nwname = 'DLib.Message.' .. util.CRC(moduleName)
	local nwnameL = 'DLib.Message.' .. util.CRC(moduleName) .. '.L'
	local nwnameW = 'DLib.MessageW.' .. util.CRC(moduleName)
	local nwnameWL = 'DLib.MessageW.' .. util.CRC(moduleName) .. '.L'
	local nwnameE = 'DLib.MessageE.' .. util.CRC(moduleName)
	local nwnameEL = 'DLib.MessageE.' .. util.CRC(moduleName) .. '.L'

	if SERVER then
		net.pool(nwname)
		net.pool(nwnameW)
		net.pool(nwnameE)
		net.pool(nwnameL)
		net.pool(nwnameWL)
		net.pool(nwnameEL)
	end

	local PREFIX = '[' .. moduleName .. '] '
	local PREFIX_COLOR = moduleColor or Color(0, 200, 0)

	local function Message(...)
		local formatted = FormatMessageRegular({...})
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function LMessage(...)
		local formatted = FormatMessageRegular(DLib.i18n.rebuildTable({...}))
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function Warning(...)
		local formatted = FormatMessageWarning({...})
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function LWarning(...)
		local formatted = FormatMessageWarning(DLib.i18n.rebuildTable({...}))
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function PrintError(...)
		local formatted = FormatMessageError({...})
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function LPrintError(...)
		local formatted = FormatMessageError(DLib.i18n.rebuildTable({...}))
		MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
		MsgC('\n')
		return formatted
	end

	local function Chat(...)
		local formatted = FormatMessageRegular({...})
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function LChat(...)
		local formatted = FormatMessageRegular(DLib.i18n.rebuildTable({...}))
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function ChatError(...)
		local formatted = FormatMessageError({...})
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function LChatError(...)
		local formatted = FormatMessageError(DLib.i18n.rebuildTable({...}))
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function ChatWarn(...)
		local formatted = FormatMessageWarning({...})
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function LChatWarn(...)
		local formatted = FormatMessageWarning(DLib.i18n.rebuildTable({...}))
		chat.AddText(PREFIX_COLOR, PREFIX, unpack(formatted))
		return formatted
	end

	local function FormatMessage(...)
		return FormatMessageRegular({PREFIX_COLOR, PREFIX, ...})
	end

	local function LFormatMessage(...)
		return FormatMessageRegular(DLib.i18n.rebuildTable({PREFIX_COLOR, PREFIX, ...}))
	end

	local function FormatMessageWarn(...)
		return FormatMessageWarning({PREFIX_COLOR, PREFIX, ...})
	end

	local function LFormatMessageWarn(...)
		return FormatMessageWarning(DLib.i18n.rebuildTable({PREFIX_COLOR, PREFIX, ...}))
	end

	local function FormatMessageErr(...)
		return FormatMessageError({PREFIX_COLOR, PREFIX, ...})
	end

	local function LFormatMessageErr(...)
		return FormatMessageError(DLib.i18n.rebuildTable({PREFIX_COLOR, PREFIX, ...}))
	end

	local function FormatMessageRaw(...)
		return FormatMessageRegular({...})
	end

	local function LFormatMessageRaw(...)
		return FormatMessageRegular(DLib.i18n.rebuildTable({...}))
	end

	local function FormatMessageWarnRaw(...)
		return FormatMessageWarning({...})
	end

	local function LFormatMessageWarnRaw(...)
		return FormatMessageWarning(DLib.i18n.rebuildTable({...}))
	end

	local function FormatMessageErrRaw(...)
		return FormatMessageError({...})
	end

	local function LFormatMessageErrRaw(...)
		return FormatMessageError(DLib.i18n.rebuildTable({...}))
	end

	local function MessagePlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return Message(...) end
		if CLIENT then return {} end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwname, true)
			net.WriteArray({...})
			net.Send(ply)
		else
			return Message(...)
		end
	end

	local function LMessagePlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return LMessage(...) end
		if CLIENT then return {} end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwnameL, true)
			net.WriteArray({...})
			net.Send(ply)
		else
			return LMessage(...)
		end
	end

	local function MessageAll(...)
		if CLIENT then return Message(...) end

		net.Start(nwname, true)
		net.WriteArray({...})
		net.Broadcast()

		return Message(...)
	end

	local function LMessageAll(...)
		if CLIENT then return LMessage(...) end

		net.Start(nwnameL, true)
		net.WriteArray({...})
		net.Broadcast()

		return LMessage(...)
	end

	local function PrintErrorPlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return PrintError(...) end
		if CLIENT then return {} end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwnameE, true)
			net.WriteArray({...})
			net.Send(ply)
		else
			return PrintError(...)
		end
	end

	local function LPrintErrorPlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return LPrintError(...) end
		if CLIENT then return {} end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwnameEL, true)
			net.WriteArray({...})
			net.Send(ply)
		else
			return LPrintError(...)
		end
	end

	local function PrintErrorAll(...)
		if CLIENT then return PrintError(...) end

		net.Start(nwnameE, true)
		net.WriteArray({...})
		net.Broadcast()

		return PrintError(...)
	end

	local function LPrintErrorAll(...)
		if CLIENT then return LPrintError(...) end

		net.Start(nwnameEL, true)
		net.WriteArray({...})
		net.Broadcast()

		return LPrintError(...)
	end

	local function WarningPlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return Warning(...) end
		if CLIENT then return {} end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwnameW, true)
			net.WriteArray({...})
			net.Send(ply)
		else
			return Warning(...)
		end
	end

	local function LWarningPlayer(ply, ...)
		if CLIENT and ply == LocalPlayer() then return LWarning(...) end
		if CLIENT then return {} end

		if type(ply) == 'table' or type(ply) == 'Player' then
			net.Start(nwnameWL, true)
			net.WriteArray({...})
			net.Send(ply)
		else
			return LWarning(...)
		end
	end

	local function WarningAll(...)
		if CLIENT then return Warning(...) end

		net.Start(nwnameW, true)
		net.WriteArray({...})
		net.Broadcast()

		return Warning(...)
	end

	local function LWarningAll(...)
		if CLIENT then return LWarning(...) end

		net.Start(nwnameWL, true)
		net.WriteArray({...})
		net.Broadcast()

		return LWarning(...)
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
		tableTo.Warning = Warning
		tableTo.LWarning = LWarning
		tableTo.PrintError = PrintError
		tableTo.LPrintError = LPrintError
		tableTo.MessageError = PrintError
		tableTo.LMessageError = LPrintError

		tableTo.RepackMessage = RepackMessage
		tableTo.FormatMessage = FormatMessage
		tableTo.FormatMessageWarning = FormatMessageWarn
		tableTo.FormatMessageWarn = FormatMessageWarn
		tableTo.FormatMessageError = FormatMessageErr
		tableTo.FormatMessageErr = FormatMessageErr

		tableTo.LFormatMessage = LFormatMessage
		tableTo.LFormatMessageWarning = LFormatMessageWarn
		tableTo.LFormatMessageWarn = LFormatMessageWarn
		tableTo.LFormatMessageError = LFormatMessageErr
		tableTo.LFormatMessageErr = LFormatMessageErr

		tableTo.FormatMessageRaw = FormatMessageRaw
		tableTo.FormatMessageWarningRaw = FormatMessageWarnRaw
		tableTo.FormatMessageWarnRaw = FormatMessageWarnRaw
		tableTo.FormatMessageErrorRaw = FormatMessageErrRaw
		tableTo.FormatMessageErrRaw = FormatMessageErrRaw

		tableTo.LFormatMessageRaw = LFormatMessageRaw
		tableTo.LFormatMessageWarningRaw = LFormatMessageWarnRaw
		tableTo.LFormatMessageWarnRaw = LFormatMessageWarnRaw
		tableTo.LFormatMessageErrorRaw = LFormatMessageErrRaw
		tableTo.LFormatMessageErrRaw = LFormatMessageErrRaw

		tableTo.lformatMessage = LFormatMessage
		tableTo.message = Message
		tableTo.lmessage = LMessage
		tableTo.repackMessage = RepackMessage
		tableTo.formatMessage = FormatMessage

		if CLIENT then
			tableTo.Chat = Chat
			tableTo.ChatWarn = ChatWarn
			tableTo.ChatError = ChatError
			tableTo.ChatMessage = Chat
			tableTo.ChatPrint = Chat
			tableTo.ChatPrintWarn = ChatWarn
			tableTo.ChatPrintWarning = ChatWarn
			tableTo.ChatPrintError = ChatError
			tableTo.AddChat = Chat
			tableTo.chatMessage = Chat

			tableTo.LChat = LChat
			tableTo.LChatError = LChatError
			tableTo.LChatWarn = LChatWarn
			tableTo.LChatMessage = LChat
			tableTo.LChatPrint = LChat
			tableTo.LChatPrintWarn = LChatWarn
			tableTo.LChatPrintWarning = LChatWarn
			tableTo.LChatPrintError = LChatError
			tableTo.LAddChat = LChat
			tableTo.lchatMessage = LChat
		else
			tableTo.MessageAll = MessageAll
			tableTo.PrintErrorAll = PrintErrorAll
			tableTo.LPrintErrorAll = LPrintErrorAll
			tableTo.WarningAll = WarningAll
			tableTo.LWarningAll = LWarningAll
			tableTo.LMessageAll = LMessageAll
		end

		tableTo.MessagePlayer = MessagePlayer
		tableTo.PrintErrorPlayer = PrintErrorPlayer
		tableTo.WarningPlayer = WarningPlayer

		tableTo.messagePlayer = MessagePlayer
		tableTo.messageP = MessagePlayer

		tableTo.LMessagePlayer = LMessagePlayer
		tableTo.LPrintErrorPlayer = LPrintErrorPlayer
		tableTo.LWarningPlayer = LWarningPlayer

		tableTo.lmessagePlayer = LMessagePlayer
		tableTo.lmessageP = LMessagePlayer
	end

	tableTarget = tableTarget or {}
	export(tableTarget)
	return export, tableTarget
end
