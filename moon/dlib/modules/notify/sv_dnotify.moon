
--
-- Copyright (C) 2017 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

export PrintMessage

_G.NOTIFY_GENERIC = 0
_G.NOTIFY_ERROR = 1
_G.NOTIFY_UNDO = 2
_G.NOTIFY_HINT = 3
_G.NOTIFY_CLEANUP = 4

net.pool('DLib.Notify.PrintMessage')

PrintMessage = (mode, message) ->
	if message\sub(#message) == '\n'
		message = message\sub(1, #message - 1)

	net.Start('DLib.Notify.PrintMessage')
	net.WriteUInt(mode, 4)
	net.WriteString(message)
	net.Broadcast()

plyMeta = FindMetaTable 'Player'

plyMeta.PrintMessage = (mode, message) =>
	if message\sub(#message) == '\n'
		message = message\sub(1, #message - 1)

	net.Start('DLib.Notify.PrintMessage')
	net.WriteUInt(mode, 4)
	net.WriteString(message)
	net.Send(self)
