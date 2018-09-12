
--
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
