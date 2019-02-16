
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
import newLines, allowedOrign, CentereNotify, NotifyDispatcherBase from Notify

surface.CreateFont('NotifyBadge', {
	font: 'Roboto'
	size: 14
	weight: 500
	extended: true
})

class BadgeNotify extends CentereNotify
	new: (...) =>
		super(...)
		@m_side = Notify_POS_BOTTOM
		@m_defSide = Notify_POS_BOTTOM

		@m_color = Color(240, 128, 128)
		@m_background = true
		@m_backgroundColor = Color(0, 0, 0, 150)

		@m_font = 'NotifyBadge'
		@CompileCache!

	GetBackgroundColor: => @m_backgroundColor
	GetBackColor: => @m_backgroundColor
	ShouldDrawBackground: => @m_background
	ShouldDrawBack: => @m_background

	CompileCache: =>
		super!
		@m_sizeOfTextX += 8
		return @

	Draw: (x = 0, y = 0) =>
		if @m_background
			surface.SetDrawColor(@m_backgroundColor.r, @m_backgroundColor.g, @m_backgroundColor.b, @m_backgroundColor.a * @m_alpha)
			surface.DrawRect(x, y, @m_sizeOfTextX + 4, @m_sizeOfTextY + 4)

		super(x + @m_sizeOfTextX / 2 + 4, y)
		return @m_sizeOfTextX + 4, @m_sizeOfTextY + 4

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

Notify.BadgeNotify = BadgeNotify

class BadgeNotifyDispatcher extends NotifyDispatcherBase
	new: (data = {}) =>
		@top = {}
		@bottom = {}
		@obj = BadgeNotify
		super(data)

	Draw: =>
		yShift = 0
		xShift = 0
		maximalY = 0

		x = @x_start + @width / 2
		y = @y_start

		wrapperSizeTop = {0}
		wrapperSizeBottom = {0}

		-- We are shifting by X and Y
		-- Lets calculate our positions before drawing

		for k, func in pairs @top
			if func\IsValid()
				s = func.m_sizeOfTextY + 6
				if s > maximalY
					maximalY = s
			else
				@top[k] = nil

		for k, func in pairs @bottom
			if func\IsValid()
				s = func.m_sizeOfTextY + 6
				if s > maximalY
					maximalY = s
			else
				@bottom[k] = nil

		drawMatrix = {}
		prevSize = 0

		for k, func in pairs @top
			xShift += func.m_sizeOfTextX + 8

			if xShift + 250 > @width
				xShift = 0
				yShift += maximalY
				wrapperSizeTop = {0}
			else
				wrapperSizeTop[1] += prevSize
				prevSize = func.m_sizeOfTextX / 2 + 4

			insert(drawMatrix, {x: x - xShift, y: y + yShift, :func, wrapper: wrapperSizeTop})

		yShift = 0
		xShift = 0
		prevSize = 0

		y = @y_start + @height

		for k, func in pairs @bottom
			xShift += func.m_sizeOfTextX + 8

			if xShift + 250 > @width
				xShift = 0
				yShift -= maximalY
				wrapperSizeBottom = {0}
			else
				wrapperSizeBottom[1] += prevSize
				prevSize = func.m_sizeOfTextX / 2 + 4

			insert(drawMatrix, {x: x - xShift, y: y + yShift, :func, wrapper: wrapperSizeBottom})

		for k, data in pairs drawMatrix
			myX, myY, func = data.x, data.y, data.func
			myX += data.wrapper[1]

			newPosX = Lerp(0.2, @xSmoothPositions[func.thinkID] or myX, myX)
			@xSmoothPositions[func.thinkID] = newPosX

			newPosY = Lerp(0.4, @ySmoothPositions[func.thinkID] or myY, myY)
			@ySmoothPositions[func.thinkID] = newPosY

			status, message = pcall(func.Draw, func, newPosX, newPosY)

			if not status
				print('[Notify] ERROR ', message)

Notify.BadgeNotifyDispatcher = BadgeNotifyDispatcher
