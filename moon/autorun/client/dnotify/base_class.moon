
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

import insert, remove from table
import newLines, allowedOrign from DNotify

class DNotifyBase
	new: (contents = {'Sample Text'}) =>
		if type(contents) == 'string'
			contents = {contents}
		
		@m_text = contents
		if not @m_sound then @m_sound = ''
		if not @m_font then @m_font = 'Default'
		if not @m_color then @m_color = Color(255, 255, 255)
		if not @m_length then @m_length = 4
		
		@m_lastThink = CurTime!
		@m_created = @m_lastThink
		@m_start = @m_created
		@m_finish = @m_start + @m_length
		
		@m_timer = true
		
		if not @m_align then @m_align = TEXT_ALIGN_LEFT
		
		@m_isDrawn = false
		@m_isValid = true
		if @m_shadow == nil then @m_shadow = true
		if @m_shadowSize == nil then @m_shadowSize = 2
		
		@m_fontobj = DNotify.Font(@m_font)
		@CompileCache!
	
	GetAlign: => @m_align
	GetTextAlign: => @m_align
	GetSound: => @m_sound
	HasSound: => @m_sound ~= ''
	GetStart: => @m_start
	GetLength: => @m_length
	GetFinishFinal: => @m_finishFinal
	FinishesOn: => @m_finish
	StopsOn: => @m_finish
	IsTimer: => @m_timer
	GetText: => @m_text
	GetFont: => @m_font
	GetColor: => @m_color
	GetColor: => @m_color
	GetDrawShadow: => @m_shadow
	GetShadowSize: => @m_shadowSize
	
	IsValid: => @m_isValid
	
	Start: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		if @m_isDrawn then return @
		@m_isDrawn = true
		if @m_sound ~= '' then surface.PlaySound(@m_sound)
		@SetStart!
		insert(DNotify.RegisteredThinks, @)
		
		return @
	
	Remove: =>
		if not @m_isDrawn then return false
		@m_isValid = false
		return true
	
	SetAlign: (val = TEXT_ALIGN_LEFT) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(allowedOrign(val), 'Not a valid align')
		@m_align = val
		
		@CompileCache!
		
		return @
	
	SetTextAlign: (...) => @SetAlign(...)
	
	SetDrawShadow: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be boolean')
		@m_shadow = val
		return @
	
	SetShadowSize: (val = 2) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'number', 'must be number')
		@m_shadowSize = val
		return @
	
	SetColor: (val = Color(255, 255, 255)) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(val.r and val.g and val.b and val.a, 'Not a valid color')
		@m_color = val
		return @
	
	FixFont: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		result = pcall(surface.SetFont, @m_font)
		if not result
			print '[DNotify] ERROR: Invalid font: ' .. @m_font
			print debug.traceback!
			@m_font = 'Default'
		
		return @
	
	SetFont: (val = 'Default') =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		@m_font = val
		@FixFont!
		@m_fontobj\SetFont(val)
		@CompileCache!
		return @

	__setTextInternal: (tab) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		@m_text = {}
		
		for i, value in pairs tab
			if type(value) == 'table' and value.r and value.g and value.b and value.a
				insert(@m_text, value)
			elseif type(value) == 'string'
				insert(@m_text, value)
	
	SetText: (...) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		tryTable = {...}
		tryFirst = tryTable[1]
		
		if type(tryFirst) == 'string'
			@__setTextInternal(tryTable)
			return @
		elseif type(tryFirst) == 'table'
			if (not tryFirst.r or not tryFirst.g or not tryFirst.b or not tryFirst.a) and not tryFirst.m_dnotify_type
				@__setTextInternal(tryFirst)
			else
				@__setTextInternal(tryTable)
			
			return @
		else
			error('Unknown argument!')
		
		@CompileCache!
		
		return @
	
	SetStart: (val = CurTime(), resetTimer = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'number', '#1 must be a number')
		assert(type(resetTimer) == 'boolean', '#2 must be a boolean')
		@m_start = val
		if resetTimer then @ResetTimer!
		return @
	
	ClearSound: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		@m_sound = ''
		return @
	
	SetSound: (newSound = '') =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(newSound) == 'string', 'SetSound - must be a string')
		@m_sound = newSound
		return @
		
	ResetTimer: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		@m_start = CurTime()
		@m_finish = @m_start + @m_length
		@m_finishFinal = @m_finish + 1
		
		return @
	
	StopTimer: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		@m_timer = false
		return @
	
	StartTimer: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		@m_timer = true
		return @
	
	SetLength: (new = 4) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(new) == 'number', 'must be a number')
		if new < 3 then new = 3
		
		@m_length = new
		@m_lengthFinal = new + 1
		@ResetTimer!
		return @
		
	SetThink: (val = (->)) =>
		assert(type(val) == 'function', 'must be a function')
		@m_thinkf = val
		return @
	
	CompileCache: =>
		@m_cache = {}
		
		@m_sizeOfTextX = 0
		@m_sizeOfTextY = 0
		lineX = 0
		
		maxX = 0
		maxY = 0
		nextY = 0
		
		currentLine = {}
		lastColor = @m_color
		lastFont = @m_font
		surface.SetFont(@m_font)
		
		for i, object in pairs @m_text
			if type(object) == 'table' -- But we will skip colors
				if object.m_dnotify_type
					if object.m_dnotify_type == 'font'
						surface.SetFont(object\GetFont())
						lastFont = object\GetFont()
				else
					lastColor = object
			elseif type(object) == 'string'
				split = newLines(object)
				first = true
				
				for i, str in pairs split
					sizeX, sizeY = surface.GetTextSize(str)
					
					if not first -- Going to new line
						maxY += 4
						
						insert(@m_cache, {content: currentLine, :lineX, shiftX: 0, :maxY, :nextY})
						currentLine = {}
						@m_sizeOfTextY += maxY
						nextY += maxY
						if lineX > maxX then maxX = lineX
						
						lineX = 0
						maxY = 0
					
					first = false
					insert(currentLine, {color: lastColor, content: str, x: lineX, font: lastFont})
					lineX += sizeX
					if sizeY > maxY then maxY = sizeY
		
		@m_sizeOfTextY += maxY
		insert(@m_cache, {content: currentLine, :lineX, shiftX: 0, :maxY, :nextY})
		
		@m_sizeOfTextX = maxX
		
		if @m_align == TEXT_ALIGN_RIGHT
			for i, line in pairs @m_cache
				line.shiftX = @m_sizeOfTextX - line.lineX
		elseif @m_align == TEXT_ALIGN_CENTER
			for i, line in pairs @m_cache
				line.shiftX = (@m_sizeOfTextX - line.lineX) / 2
				
		return @
	
	Draw: (x = 0, y = 0) =>
		print 'Non overriden version!'
		print debug.traceback!
		return 0
	
	Think: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		deltaThink = CurTime() - @m_lastThink
		
		if not @m_timer
			@m_created += deltaThink
			@m_finish += deltaThink
			@m_finishFinal += deltaThink
			
			if @ThinkNotTimer
				@ThinkNotTimer(deltaThink)
		else
			cTime = CurTime()
			
			if @m_finishFinal <= cTime
				@Remove!
				return false
			
			if @ThinkTimer
				@ThinkTimer(deltaThink, cTime)
		
		if @m_thinkf then @m_thinkf!
		return @

DNotify.DNotifyBase = DNotifyBase