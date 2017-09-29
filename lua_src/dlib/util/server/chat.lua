
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

net.pool('DLib.AddChatText')

local chat = DLib.module('chat', 'chat')

function chat.generate(name, targetTable)
	local nw = 'DLib.AddChatText.' .. name
	net.pool(nw)

	local newModule = targetTable or {}

	function newModule.player(ply, ...)
		net.Start(nw, true)
		net.WriteArray({...})
		net.Send(ply)
	end

	function newModule.all(...)
		net.Start(nw, true)
		net.WriteArray({...})
		net.Broadcast()
	end

	return newModule
end

chat.generate('default', chat)

return chat
