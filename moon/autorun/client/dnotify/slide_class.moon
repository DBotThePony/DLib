
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
import newLines, allowedOrign, DNotifyBase from DNotify

class SlideNotify extends DNotifyBase
	new: (...) =>
		@m_side = DNOTIFY_SIDE_LEFT
		
		@m_animated = true
		@m_animin = true
		@m_animout = true
		
		@m_shift = -150
		@m_background = true
		@m_backgroundColor = Color(0, 0, 0, 150)
		
		super(...)
	
	GetBackgroundColor: => @m_backgroundColor
	GetBackColor: => @m_backgroundColor
	ShouldDrawBackground: => @m_background
	ShouldDrawBack: => @m_background
	GetAnimated: => @m_animated
	GetIsAnimated: => @m_animated
	GetAnimatedIn: => @m_animin
	GetAnimatedOut: => @m_animout
	GetSide: => @m_side
	
	Start: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		if @m_isDrawn then return @
		
		if @m_animated and @m_animin
			@m_shift = -150
		else
			@m_shift = 0
		
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
	
	SetSide: (val = DNOTIFY_SIDE_LEFT, affectAlign = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(val == DNOTIFY_SIDE_LEFT or val == DNOTIFY_SIDE_RIGHT, 'Only left or right sides are allowed')
		assert(type(affectAlign) == 'boolean', 'Only left or right sides are allowed')
		assert(not @m_isDrawn, 'Can not change side while drawing')
		@m_side = val
		
		if affectAlign and val == DNOTIFY_SIDE_RIGHT
			@SetAlign(TEXT_ALIGN_RIGHT)
		
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
			
			for i, strData in pairs line.content
				SetFont(strData.font)
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

DNotify.Slide = SlideNotify
DNotify.slide = SlideNotify
DNotify.SlideNotify = SlideNotify
