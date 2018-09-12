
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


class NotifyFont
	new: (val = 'Default') =>
		@m_font = val
		@m_Notify_type = 'font'
		@FixFont!

	Setup: =>
		surface.SetFont(@m_font)
		x, y = surface.GetTextSize('W')
		@m_height = y

	FixFont: =>
		if not self.IsValidFont(@m_font) then @m_font = 'Default'
		return @

	IsValidFont: (font) ->
		result = pcall(surface.SetFont, font)
		return result

	SetFont: (val = 'Default') =>
		@m_font = val
		@FixFont!
		@Setup!
		return @

	GetFont: => @m_font

	GetTextSize: (text) =>
		assert(type(text) == 'string', 'Not a string')
		surface.SetFont(@m_font)
		return @

	GetHeight: =>
		return @m_height

Notify.Font = NotifyFont