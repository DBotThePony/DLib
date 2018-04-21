
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

net.pool('DLib.AddChatText')

local chat = DLib.module('chat', 'chat')

function chat.generate(name, targetTable)
	local nw = 'DLib.AddChatText.' .. name
	local nwL = 'DLib.AddChatTextL.' .. name
	net.pool(nw)
	net.pool(nwL)

	local newModule = targetTable or {}

	function newModule.chatPlayer(ply, ...)
		net.Start(nw, true)
		net.WriteArray({...})
		net.Send(ply)
	end

	function newModule.lchatPlayer(ply, ...)
		net.Start(nwL, true)
		net.WriteArray({...})
		net.Send(ply)
	end

	function newModule.chatPlayer2(ply, ...)
		if IsValid(ply) and not ply:IsBot() then
			net.Start(nw, true)
			net.WriteArray({...})
			net.Send(ply)
		elseif newModule.Message then
			newModule.Message(ply, ' -> ', ...)
		end
	end

	function newModule.lchatPlayer2(ply, ...)
		if IsValid(ply) and not ply:IsBot() then
			net.Start(nwL, true)
			net.WriteArray({...})
			net.Send(ply)
		elseif newModule.Message then
			newModule.Message(ply, ' -> ', ...)
		end
	end

	function newModule.chatAll(...)
		net.Start(nw, true)
		net.WriteArray({...})
		net.Broadcast()
	end

	function newModule.lchatAll(...)
		net.Start(nwL, true)
		net.WriteArray({...})
		net.Broadcast()
	end

	newModule.ChatPlayer = chatPlayer.chatPlayer
	newModule.ChatPlayer2 = chatPlayer.chatPlayer2
	newModule.LChatPlayer = chatPlayer.lchatPlayer
	newModule.LChatPlayer2 = chatPlayer.lchatPlayer2
	newModule.ChatAll = chatPlayer.chatAll
	newModule.LChatAll = chatPlayer.lchatAll

	return newModule
end

function chat.generateWithMessages(targetTable, name)
	targetTable = targetTable or {}

	DLib.CMessage(targetTable, name)
	chat.generate(name, targetTable)

	targetTable.chatPlayerMessage = targetTable.chatPlayer

	function targetTable.chatPlayer(ply, ...)
		if not IsValid(ply) then
			targetTable.Message(...)
			return
		end

		return targetTable.chatPlayerMessage(ply, ...)
	end

	return targetTable
end

chat.generate('default', chat)

chat.player = chat.chatPlayer
chat.all = chat.chatAll

return chat
