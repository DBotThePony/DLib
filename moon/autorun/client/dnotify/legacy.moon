
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
import newLines, allowedOrign, BadgeNotify, DNotifyDispatcherBase, DNotifyAnimated from DNotify

surface.CreateFont('DNotifyLegacy', {
	font: 'Roboto'
	size: 16
	weight: 500
})

-- Math on paper o.o
shiftLambdaFunction = (x) -> x ^ 4 - (10 * x) - 50
shiftTopLambdaFunction = (x) -> x ^ 4 - (x * 20)

-- Replaces notification.AddLegacy with more fancy variant!
class LegacyNotification extends BadgeNotify
	new: (...) =>
		super(...)
		@m_side = DNOTIFY_SIDE_RIGHT
		@m_defSide = DNOTIFY_SIDE_RIGHT
		@m_allowedSides = {DNOTIFY_SIDE_RIGHT, DNOTIFY_SIDE_LEFT}
		
		@m_color = Color(255, 255, 255)
		
		@m_slideShift = 0
		@m_topShift = 9999
		@m_alpha = 1
		
		@m_font = 'DNotifyLegacy'
		@CompileCache!
	
	Bind: (...) =>
		super(...)
		@m_topShiftStep = @dispatcher.height * 0.4
		@m_topShift = @dispatcher.height * 0.4
		return @
	
	Start: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(@dispatcher, 'Not bound to a dispatcher!')
		if @m_isDrawn then return @
		
		if @m_side == DNOTIFY_SIDE_RIGHT
			insert(@dispatcher.right, @)
		else
			insert(@dispatcher.left, @)
		
		return DNotifyAnimated.Start(@)
	
	Draw: (x = 0, y = 0) =>
		if @m_side == DNOTIFY_SIDE_LEFT
			newY = y + @m_topShift
			
			if y >= @dispatcher.height + @dispatcher.y_start
				return 0, 0
			else
				return super(x - @m_slideShift, newY)
		else
			newY = y + @m_topShift
			
			if y >= @dispatcher.height + @dispatcher.y_start
				return 0, 0
			else
				return super(x + @m_slideShift - @m_sizeOfTextX, newY)
	
	ThinkTimer: (deltaThink, cTime) =>
		if @m_animated
			deltaIn = @m_start + 1 - cTime
			deltaOut = cTime - @m_finish
			
			if deltaIn >= 0 and deltaIn <= 1 and @m_animin
				@m_topShift = Lerp(0.3, @m_topShift, shiftTopLambdaFunction(deltaIn * 6))
				@m_slideShift = Lerp(0.3, @m_slideShift, 0)
			elseif deltaOut >= 0 and deltaOut < 1 and @m_animout
				@m_topShift = Lerp(0.3, @m_topShift, 0)
				@m_slideShift = Lerp(0.3, @m_slideShift, shiftLambdaFunction(deltaOut * 10))
			else
				@m_topShift = Lerp(0.3, @m_topShift, 0)
				@m_slideShift = Lerp(0.3, @m_slideShift, 0)
		else
			@m_topShift = 0
			@m_slideShift = 0

DNotify.LegacyNotification = LegacyNotification

class LegacyNotifyDispatcher extends DNotifyDispatcherBase
	new: (data = {}) =>
		@left = {}
		@right = {}
		@obj = LegacyNotification
		super(data)
	
	Draw: =>
		yShift = 0
		
		x = @x_start
		y = @y_start
		
		for k, func in pairs @left
			if func\IsValid()
				newPosY = Lerp(0.4, @ySmoothPositions[func.thinkID] or (y + yShift), y + yShift)
				@ySmoothPositions[func.thinkID] = newPosY
				
				status, message = pcall(func.Draw, func, x, newPosY)
				
				if status
					yShift += func.m_sizeOfTextY + 6
				else
					print('[DNotify] ERROR ', message)
			else
				@left[k] = nil
		
		x = @width
		yShift = 0
		
		for k, func in pairs @right
			if func\IsValid()
				newPosY = Lerp(0.4, @ySmoothPositions[func.thinkID] or (y + yShift), y + yShift)
				@ySmoothPositions[func.thinkID] = newPosY
				
				status, message = pcall(func.Draw, func, x, newPosY)
				
				if status
					yShift += func.m_sizeOfTextY + 6
				else
					print('[DNotify] ERROR ', message)
			else
				@right[k] = nil

DNotify.LegacyNotifyDispatcher = LegacyNotifyDispatcher
