
--
-- Copyright (C) 2017-2019 DBot

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
import newLines, allowedOrign, NotifyAnimated, NotifyDispatcherBase from Notify

surface.CreateFont('NotifyCentered', {
	font: 'Roboto'
	size: 18
	weight: 600
	extended: true
})

class CentereNotify extends NotifyAnimated
	new: (...) =>
		@m_side = Notify_POS_TOP
		@m_defSide = Notify_POS_TOP
		@m_allowedSides = {Notify_POS_TOP, Notify_POS_BOTTOM}

		@m_color = Color(10, 185, 200)

		@m_alpha = 0
		@m_align = TEXT_ALIGN_CENTER
		@m_font = 'NotifyCentered'

		super(...)
		@m_shadowSize = 1

	GetSide: => @m_side

	Start: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(@dispatcher, 'Not bound to a dispatcher!')
		if @m_isDrawn then return @

		if @m_animated and @m_animin then @m_alpha = 0 else @m_alpha = 1

		if @m_side == Notify_POS_TOP
			insert(@dispatcher.top, @)
		else
			insert(@dispatcher.bottom, @)

		return super!

	SetSide: Notify.SetSideFunc

	Draw: (x = 0, y = 0) =>
		import SetTextPos, SetFont, SetTextColor, DrawText from surface

		x -= @m_sizeOfTextX / 2

		SetTextPos(x + 2, y + 2)

		for i, line in pairs @m_cache
			lineX = line.lineX
			shiftX = line.shiftX
			maxY = line.maxY
			nextY = line.nextY

			for i, strData in pairs line.content
				SetFont(strData.font)

				if @m_shadow
					SetTextColor(0, 0, 0, @m_alpha * 255)
					SetTextPos(x + shiftX + strData.x + 2 + @m_shadowSize, y + nextY + 2 + @m_shadowSize)
					DrawText(strData.content)

				SetTextColor(strData.color.r, strData.color.g, strData.color.b, @m_alpha * 255)
				SetTextPos(x + shiftX + strData.x + 2, y + nextY + 2)
				DrawText(strData.content)

		return @m_sizeOfTextY + 4

	ThinkTimer: (deltaThink, cTime) =>
		if @m_animated
			deltaIn = @m_start + 1 - cTime
			deltaOut = cTime - @m_finish

			if deltaIn >= 0 and deltaIn <= 1 and @m_animin
				@m_alpha = 1 - deltaIn
			elseif deltaOut >= 0 and deltaOut < 1 and @m_animout
				@m_alpha = 1 - deltaOut
			else
				@m_alpha = 1
		else
			@m_alpha = 1

Notify.CentereNotify = CentereNotify

class CentereNotifyDispatcher extends NotifyDispatcherBase
	new: (data = {}) =>
		@top = {}
		@bottom = {}
		@obj = CentereNotify
		super(data)

	Draw: =>
		yShift = 0
		x = @width / 2 + @x_start
		y = @height * 0.26 + @y_start

		for k, func in pairs @top
			if y + yShift >= @height then break

			newSmoothPos = Lerp(0.2, @ySmoothPositions[func.thinkID] or y + yShift, y + yShift)
			@ySmoothPositions[func.thinkID] = newSmoothPos

			if func\IsValid()
				status, currShift = pcall(func.Draw, func, x, newSmoothPos)

				if status
					yShift += currShift
				else
					print('[Notify] ERROR ', currShift)
			else
				@top[k] = nil

		y = @height * 0.75

		for k, func in pairs @bottom
			if y + yShift >= @height then break

			newSmoothPos = Lerp(0.2, @ySmoothPositions[func.thinkID] or y + yShift, y + yShift)
			@ySmoothPositions[func.thinkID] = newSmoothPos

			if func\IsValid()
				status, currShift = pcall(func.Draw, func, x, newSmoothPos)

				if status
					yShift += currShift
				else
					print('[Notify] ERROR ', currShift)
			else
				@bottom[k] = nil

Notify.CentereNotifyDispatcher = CentereNotifyDispatcher
