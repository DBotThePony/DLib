
-- Copyright (C) 2018 DBot

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

import VLL2, table, hook, surface, draw, ScrW, ScrH, TEXT_ALIGN_CENTER from _G

bundlelist = {
	VLL2.URLBundle
	VLL2.WSBundle
	VLL2.GMABundle
	VLL2.WSCollection
}

surface.CreateFont('VLL2.Message', {
	font: 'Roboto'
	size: ScreenScale(14)
})

WARN_COLOR = Color(188, 15, 20)

hook.Add 'HUDPaint', 'VLL2.HUDMessages', ->
	local messages

	for bundle in *bundlelist
		msgs = bundle\GetMessage()

		if msgs
			messages = messages or {}

			if type(msgs) == 'string'
				table.insert(messages, msgs)
			else
				table.insert(messages, _i) for _i in *msgs

	return if not messages

	x, y = ScrW() / 2, ScrH() * 0.11

	for message in *messages
		draw.DrawText(message, 'VLL2.Message', x, y, WARN_COLOR, TEXT_ALIGN_CENTER)
		w, h = surface.GetTextSize(message)
		y += h * 1.1
