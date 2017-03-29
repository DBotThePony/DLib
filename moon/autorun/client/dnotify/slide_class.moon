
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
import newLines, allowedOrign, DNotifyBase, DNotifyAnimated from DNotify

surface.CreateFont('DNotifySlide', {
	font: 'Roboto'
	size: 16
	weight: 500
})

class SlideNotify extends DNotifyAnimated
	new: (...) =>
		@m_side = DNOTIFY_SIDE_LEFT
		@m_defSide = DNOTIFY_SIDE_LEFT
		@m_allowedSides = {DNOTIFY_SIDE_LEFT, DNOTIFY_SIDE_RIGHT}
		
		@m_shift = -150
		@m_background = true
		@m_backgroundColor = Color(0, 0, 0, 150)
		@m_shadow = false
		@m_font = 'DNotifySlide'
		
		super(...)
	
	GetBackgroundColor: => @m_backgroundColor
	GetBackColor: => @m_backgroundColor
	ShouldDrawBackground: => @m_background
	ShouldDrawBack: => @m_background
	GetSide: => @m_side
	
	Start: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		if @m_isDrawn then return @
		
		if @m_animated and @m_animin
			@m_shift = -150
		else
			@m_shift = 0
		
		if @m_side == DNOTIFY_SIDE_RIGHT
			@m_shift = -@m_shift
		
		if @m_side == DNOTIFY_SIDE_LEFT
			insert(DNotify.NotificationsSlideLeft, @)
		else
			insert(DNotify.NotificationsSlideRight, @)
		
		return super!
	
	SetBackgroundColor: (val = Color(255, 255, 255)) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(val.r and val.g and val.b and val.a, 'Not a valid color')
		@m_backgroundColor = val
		return @
	
	SetSide: DNotify.SetSideFunc
	
	SetShouldDrawBackground: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_background = val
		return @
	
	Draw: (x = 0, y = 0) =>
		import SetTextPos, SetDrawColor, DrawRect, SetFont, SetTextColor, DrawText from surface
		
		x += @m_shift
		
		if @m_side == DNOTIFY_SIDE_RIGHT
			x -= @m_sizeOfTextX + 4
		
		SetTextPos(x + 2, y + 2)
		
		if @m_background
			SetDrawColor(@m_backgroundColor)
			DrawRect(x, y, @m_sizeOfTextX + 4, @m_sizeOfTextY + 4)
		
		for i, line in pairs @m_cache
			lineX = line.lineX
			shiftX = line.shiftX
			maxY = line.maxY
			nextY = line.nextY
			
			for i, strData in pairs line.content
				SetFont(strData.font)
				
				if @m_shadow
					SetTextColor(0, 0, 0)
					SetTextPos(x + shiftX + strData.x + 2 + @m_shadowSize, y + nextY + 2 + @m_shadowSize)
					DrawText(strData.content)
				
				SetTextColor(strData.color)
				SetTextPos(x + shiftX + strData.x + 2, y + nextY + 2)
				DrawText(strData.content)
		
		return @m_sizeOfTextY + 4
	
	ThinkTimer: (deltaThink, cTime) =>
		if @m_animated
			deltaIn = @m_start + 1 - cTime
			deltaOut = cTime - @m_finish
			
			if deltaIn >= 0 and deltaIn <= 1 and @m_animin
				@m_shift = -150 * deltaIn
			elseif deltaOut >= 0 and deltaOut < 1 and @m_animout
				@m_shift = -150 * deltaOut
			else
				@m_shift = 0
		else
			@m_shift = 0
		
		if @m_side == DNOTIFY_SIDE_RIGHT
			@m_shift = -@m_shift

DNotify.Slide = SlideNotify
DNotify.slide = SlideNotify
DNotify.SlideNotify = SlideNotify
