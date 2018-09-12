
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
import newLines, allowedOrigin from Notify

class NotifyBase
	new: (contents = {'Sample Text'}) =>
		if type(contents) == 'string'
			contents = {contents}

		if not @m_sound then @m_sound = ''
		if not @m_font then @m_font = 'Default'
		if not @m_color then @m_color = Color(255, 255, 255)
		if not @m_length then @m_length = 4

		@m_text = contents

		@m_lastThink = CurTimeL!
		@m_created = @m_lastThink
		@m_start = @m_created
		@m_finish = @m_start + @m_length
		@m_console = true

		@m_timer = true

		if not @m_align then @m_align = TEXT_ALIGN_LEFT

		@m_isDrawn = false
		@m_isValid = true
		if @m_shadow == nil then @m_shadow = true
		if @m_shadowSize == nil then @m_shadowSize = 2

		@m_fontobj = Notify.Font(@m_font)
		@CompileCache!
		@CalculateTimer!

	Bind: (obj) =>
		@dispatcher = obj
		@thinkID = insert(@dispatcher.thinkHooks, @)
		@dispatcher.xSmoothPositions[@thinkID] = nil
		@dispatcher.ySmoothPositions[@thinkID] = nil
		return @

	GetDrawInConsole: => @m_console
	GetNotifyInConsole: => @m_console
	GetAlign: => @m_align
	GetTextAlign: => @m_align
	GetSound: => @m_sound
	HasSound: => @m_sound ~= ''
	GetStart: => @m_start
	GetLength: => @m_length
	FinishesOn: => @m_finish
	StopsOn: => @m_finish
	IsTimer: => @m_timer
	GetText: => @m_text
	GetFont: => @m_font
	GetColor: => @m_color
	GetTextColor: => @m_color
	GetDrawShadow: => @m_shadow
	GetShadowSize: => @m_shadowSize

	IsValid: => @m_isValid

	Start: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(@dispatcher, 'Not bound to a dispatcher!')
		if @m_isDrawn then return @
		@m_isDrawn = true
		if @m_sound ~= '' then surface.PlaySound(@m_sound)
		@SetStart!

		if @m_console
			MsgC(Color(0, 255, 0), '[Notify] ', @m_color, unpack(@m_text))
			MsgC('\n')

		return @

	Remove: =>
		if not @m_isDrawn then return false
		@m_isValid = false
		return true

	SetNotifyInConsole: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be boolean')
		@m_console = val
		return @

	SetAlign: (val = TEXT_ALIGN_LEFT) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(allowedOrigin(val), 'Not a valid align')
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
		@CompileCache!
		return @

	FixFont: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		result = pcall(surface.SetFont, @m_font)
		if not result
			print '[Notify] ERROR: Invalid font: ' .. @m_font
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
			elseif type(value) == 'number'
				insert(@m_text, tostring(value))

	SetText: (...) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		tryTable = {...}
		tryFirst = tryTable[1]

		if type(tryFirst) == 'string' or type(tryFirst) == 'number'
			@__setTextInternal(tryTable)
			@CompileCache!
			if not @m_isDrawn then @CalculateTimer!

			return @
		elseif type(tryFirst) == 'table'
			if (not tryFirst.r or not tryFirst.g or not tryFirst.b or not tryFirst.a) and not tryFirst.m_Notify_type
				@__setTextInternal(tryFirst)
			else
				@__setTextInternal(tryTable)

			@CompileCache!
			if not @m_isDrawn then @CalculateTimer!

			return @
		else
			error('Unknown argument!')

		return @

	SetStart: (val = CurTimeL(), resetTimer = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'number', '#1 must be a number')
		assert(type(resetTimer) == 'boolean', '#2 must be a boolean')
		@m_start = val
		if resetTimer then @ResetTimer(false)
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

	ResetTimer: (affectStart = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		if affectStart then @m_start = CurTimeL()
		@m_finish = @m_start + @m_length

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
		@ResetTimer!
		return @

	SetFinish: (new = CurTimeL! + 4) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(new) == 'number', 'must be a number')
		@m_finish = new
		@m_length = new - @m_start
		return @

	CalculateTimer: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		newLen = 2

		for i, object in pairs @m_text
			if type(object) == 'string'
				newLen += (#object) ^ (1 / 2)

		@m_calculatedLength = math.Clamp(newLen, 4, 10)
		@SetLength(@m_calculatedLength)
		return @

	ExtendTimer: (val = @m_calculatedLength) =>
		assert(type(val) == 'number', 'must be a number')
		@SetFinish(CurTimeL! + val)
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
		lastColor = @GetColor!
		lastFont = @m_font
		surface.SetFont(@m_font)

		for i, object in pairs @m_text
			if type(object) == 'table' -- But we will skip colors
				if object.m_Notify_type
					if object.m_Notify_type == 'font'
						surface.SetFont(object\GetFont())
						lastFont = object\GetFont()
				else
					lastColor = object
			elseif type(object) == 'string'
				split = newLines(object)
				first = true
				firstHitX = 0

				for i, str in pairs split
					sizeX, sizeY = surface.GetTextSize(str)
					firstHitX = sizeX

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

				if maxX == 0 then maxX = firstHitX

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

	ThinkNotTimer: =>
		-- Override

	ThinkTimer: =>
		-- Override

	GetNonValidTime: => @m_finish

	Think: =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		deltaThink = CurTimeL() - @m_lastThink

		if not @m_timer
			@m_created += deltaThink
			@m_finish += deltaThink

			@ThinkNotTimer(deltaThink)
		else
			cTime = CurTimeL()

			if @GetNonValidTime! <= cTime
				@Remove!
				return false

			@ThinkTimer(deltaThink, cTime)
		if @m_thinkf then @m_thinkf!

		return @

class NotifyDispatcherBase
	new: (data = {}) =>
		@x_start = data.x or 0
		@y_start = data.y or 0
		@width = data.width or ScrWL!
		@height = data.height or ScrHL!

		@heightFunc = data.getheight
		@xFunc = data.getx
		@widthFunc = data.getwidth
		@yFunc = data.gety

		@heightArgs = data.height_func_args or {}
		@widthArgs = data.width_func_args or {}

		@xArgs = data.x_func_args or {}
		@yArgs = data.y_func_args or {}

		@data = data

		if not @obj then @obj = NotifyBase

		@thinkHooks = {}
		@ySmoothPositions = {}
		@xSmoothPositions = {}

	IsValid: => true

	Create: (...) => self.obj(...)\Bind(@)

	Clear: => for i, obj in pairs @thinkHooks do obj\Remove()

	Draw: =>
		print 'Non-overriden version!'
		print debug.traceback!
		return @

	Think: =>
		if type(@xFunc) == 'function'
			@x_start = @xFunc(unpack(@xArgs)) or @x_start

		if type(@yFunc) == 'function'
			@y_start = @yFunc(unpack(@yArgs)) or @y_start

		if type(@heightFunc) == 'function'
			@height = @heightFunc(unpack(@heightArgs)) or @height

		if type(@widthFunc) == 'function'
			@width = @widthFunc(unpack(@widthArgs)) or @width

		for k, func in pairs @thinkHooks
			if func\IsValid()
				status, err = pcall(func.Think, func)

				if not status
					print '[Notify] ERROR ', err
			else
				@thinkHooks[k] = nil
				@ySmoothPositions[func.thinkID] = nil

		return @

Notify.NotifyBase = NotifyBase
Notify.NotifyDispatcherBase = NotifyDispatcherBase
