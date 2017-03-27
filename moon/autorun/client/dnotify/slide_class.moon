
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

class SlideNotify
	new: (contents = {'Sample Text'}) =>
		if type(contents) == 'string'
			contents = {contents}
		
		@m_sound = ''
		@m_text = contents
		@m_font = 'Default'
		@m_color = Color(255, 255, 255)
		@m_side = DNOTIFY_SIDE_LEFT
		@m_lastThink = CurTime!
		@m_created = @m_lastThink
		@m_start = @m_created
		@m_finish = @m_start + 4
		@m_finishFinal = @m_finish + 1
		
		@m_length = 4
		@m_lengthFinal = 5
		
		@m_timer = true
		@m_animated = true
		@m_animin = true
		@m_animout = true
		
		@m_align = TEXT_ALIGN_LEFT
		
		@m_isDrawn = false
		@m_isValid = true
		
		@m_fontobj = DNotify.Font(@m_font)
		@m_shift = -150
		@CompileCache!
		@m_background = true
		@m_backgroundColor = Color(0, 0, 0, 150)
	
	GetBackgroundColor: => @m_backgroundColor
	GetBackColor: => @m_backgroundColor
	ShouldDrawBackground: => @m_background
	ShouldDrawBack: => @m_background
	GetAlign: => @m_align
	GetTextAlign: => @m_align
	GetSound: => @m_sound
	HasSound: => @m_sound ~= ''
	GetStart: => @m_start
	GetAnimated: => @m_animated
	GetIsAnimated: => @m_animated
	GetAnimatedIn: => @m_animin
	GetAnimatedOut: => @m_animout
	GetLength: => @m_length
	GetLength: => @m_length
	GetFinishFinal: => @m_finishFinal
	FinishesOn: => @m_finish
	StopsOn: => @m_finish
	IsTimer: => @m_timer
	GetText: => @m_text
	GetFont: => @m_font
	GetColor: => @m_color
	GetStamp: => @m_created
	GetSide: => @m_side
	
	IsValid: => @m_isValid
	
	Start: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		if @m_isDrawn then return @
		@m_isDrawn = true
		
		if @m_animated and @m_animin
			@m_shift = -150
		else
			@m_shift = 0
		
		if @m_sound ~= '' then surface.PlaySound(@m_sound)
		
		@SetStart!
		
		if @m_side == DNOTIFY_SIDE_LEFT
			insert(DNotify.NotificationsSlideLeft, @)
		else
			insert(DNotify.NotificationsSlideRight, @)
		
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
	
	SetColor: (val = Color(255, 255, 255)) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(val.r and val.g and val.b and val.a, 'Not a valid color')
		@m_color = val
		return @
	
	SetBackgroundColor: (val = Color(255, 255, 255)) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(val.r and val.g and val.b and val.a, 'Not a valid color')
		@m_backgroundColor = val
		return @
	
	SetSide: (val = DNOTIFY_SIDE_LEFT, affectAlign = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(val == DNOTIFY_SIDE_LEFT or val == DNOTIFY_SIDE_RIGHT, 'Only left or right sides are allowed')
		assert(type(affectAlign) == 'boolean', 'Only left or right sides are allowed')
		assert(not @m_isDrawn, 'Can not change side while drawing')
		@m_side = val
		
		if affectAlign and val == DNOTIFY_SIDE_RIGHT
			@SetAlign(TEXT_ALIGN_RIGHT)
		
		return @
	
	FixFont: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		result = pcall(surface.SetFont, @m_font)
		if not result then @m_font = 'Default'
		return @
	
	SetFont: (val = 'Default') =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		@m_font = val
		@FixFont!
		@m_fontobj:SetFont(val)
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
	
	SetShouldDrawBackground: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_background = val
		return @
	
	SetAnimatedOut: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_animout = val
		return @
	
	SetAnimatedIn: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_animin = val
		return @
	
	SetAnimated: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_animated = val
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
		
	SetThink: (val = function() end) =>
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
						surface.SetFont(object:GetFont())
						lastFont = object:GetFont()
				else
					lastColor = object
			elseif type(object) == 'string'
				split = newLines(object)
				first = true
				
				for i, str in pairs split
					sizeX, sizeY = surface.GetTextSize(str)
					
					if not first -- Going to new line
						maxY += 2
						
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
		
		insert(@m_cache, {content: currentLine, :lineX, shiftX: 0, :maxY, :nextY})
		
		if @m_align == TEXT_ALIGN_RIGHT
			for i, line in pairs @m_cache
				line.shiftX = @m_sizeOfTextX - line.lineX
		elseif @m_align == TEXT_ALIGN_CENTER
			for i, line in pairs @m_cache
				line.shiftX = (@m_sizeOfTextX - line.lineX) / 2
				
		return @
	
	Draw: (x = 0, y = 0) =>
		import SetTextPos, SetDrawColor, DrawRect, SetFont, SetTextColor, DrawText from surface
		
		x += @m_shift
		
		SetTextPos(x + 2, y + 2)
		
		if @m_background
			SetDrawColor(@m_backgroundColor)
			DrawRect(x, y, @m_sizeOfTextX + 4, @m_sizeOfTextY + 4)
		
		for i, line in pairs @m_cache
			lineX = line.lineX
			shiftX = line.shiftX
			maxY = line.maxY
			nextY = line.nextY
			
			for i, strData in line.currentLine
				SetFont(strData.font)
				SetTextColor(strData.color)
				SetTextPos(x + shiftX + strData.x + 2, y + nextY + 2)
				DrawText(strData.content)
		
		return @m_sizeOfTextY + 4
	
	Think: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		deltaThink = CurTime() - @m_lastThink
		
		if not @m_timer
			@m_created += deltaThink
			@m_finish += deltaThink
			@m_finishFinal += deltaThink
		else
			cTime = CurTime()
			
			if @m_finishFinal <= cTime
				@Remove!
				return false
			
			if @m_animated
				deltaIn = @m_start + 1 - cTime
				deltaOut = cTime - @m_finish
				
				if deltaIn > 0 and deltaIn < 1 and @m_animin
					@m_shift = -150 * deltaIn
				elseif deltaOut > 0 and deltaOut < 1 and @m_animout
					@m_shift = -150 * deltaOut
				else
					@m_shift = 0
			else
				@m_shift = 0
		
		if @m_thinkf then @m_thinkf!
		return @

DNotify.Slide = SlideNotify
DNotify.slide = SlideNotify
DNotify.SlideNotify = SlideNotify
