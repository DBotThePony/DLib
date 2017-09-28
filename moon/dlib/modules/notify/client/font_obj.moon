
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