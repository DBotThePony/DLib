
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


import insert, remove from table
import newLines, allowedOrign, BadgeNotify, NotifyDispatcherBase, NotifyAnimated from Notify

surface.CreateFont('NotifyLegacy', {
	font: 'Roboto'
	size: 16
	weight: 500
	extended: true
})

-- Math on paper o.o
shiftLambdaFunction = (x) -> x ^ 4 - (10 * x) - 50
shiftTopLambdaFunction = (x) -> x ^ 4 - (x * 20)

-- Replaces notification.AddLegacy with more fancy variant!
class LegacyNotification extends BadgeNotify
	new: (...) =>
		super(...)
		@m_side = Notify_SIDE_RIGHT
		@m_defSide = Notify_SIDE_RIGHT
		@m_allowedSides = {Notify_SIDE_RIGHT, Notify_SIDE_LEFT}

		@m_color = Color(255, 255, 255)

		@m_slideShift = 0
		@m_topShift = 9999
		@m_alpha = 1

		@m_font = 'NotifyLegacy'
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

		if @m_side == Notify_SIDE_RIGHT
			insert(@dispatcher.right, @)
		else
			insert(@dispatcher.left, @)

		return NotifyAnimated.Start(@)

	Draw: (x = 0, y = 0) =>
		if @m_side == Notify_SIDE_LEFT
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

Notify.LegacyNotification = LegacyNotification

class LegacyNotifyDispatcher extends NotifyDispatcherBase
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
					print('[Notify] ERROR ', message)
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
					print('[Notify] ERROR ', message)
			else
				@right[k] = nil

Notify.LegacyNotifyDispatcher = LegacyNotifyDispatcher
