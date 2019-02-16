
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

file.mkdir('dlib/keybinds')

DLib.bind = DLib.bind or {}
bind = DLib.bind

bind.KeyMap = {
	[KEY_FIRST]: 'FIRST'
	[KEY_NONE]: 'NONE'
	[KEY_0]: '0'
	[KEY_1]: '1'
	[KEY_2]: '2'
	[KEY_3]: '3'
	[KEY_4]: '4'
	[KEY_5]: '5'
	[KEY_6]: '6'
	[KEY_7]: '7'
	[KEY_8]: '8'
	[KEY_9]: '9'
	[KEY_A]: 'A'
	[KEY_B]: 'B'
	[KEY_C]: 'C'
	[KEY_D]: 'D'
	[KEY_E]: 'E'
	[KEY_F]: 'F'
	[KEY_G]: 'G'
	[KEY_H]: 'H'
	[KEY_I]: 'I'
	[KEY_J]: 'J'
	[KEY_K]: 'K'
	[KEY_L]: 'L'
	[KEY_M]: 'M'
	[KEY_N]: 'N'
	[KEY_O]: 'O'
	[KEY_P]: 'P'
	[KEY_Q]: 'Q'
	[KEY_R]: 'R'
	[KEY_S]: 'S'
	[KEY_T]: 'T'
	[KEY_U]: 'U'
	[KEY_V]: 'V'
	[KEY_W]: 'W'
	[KEY_X]: 'X'
	[KEY_Y]: 'Y'
	[KEY_Z]: 'Z'
	[KEY_PAD_0]: 'PAD_0'
	[KEY_PAD_1]: 'PAD_1'
	[KEY_PAD_2]: 'PAD_2'
	[KEY_PAD_3]: 'PAD_3'
	[KEY_PAD_4]: 'PAD_4'
	[KEY_PAD_5]: 'PAD_5'
	[KEY_PAD_6]: 'PAD_6'
	[KEY_PAD_7]: 'PAD_7'
	[KEY_PAD_8]: 'PAD_8'
	[KEY_PAD_9]: 'PAD_9'
	[KEY_PAD_DIVIDE]: 'PAD_DIVIDE'
	[KEY_PAD_MULTIPLY]: 'PAD_MULTIPLY'
	[KEY_PAD_MINUS]: 'PAD_MINUS'
	[KEY_PAD_PLUS]: 'PAD_PLUS'
	[KEY_PAD_ENTER]: 'PAD_ENTER'
	[KEY_PAD_DECIMAL]: 'PAD_DECIMAL'
	[KEY_LBRACKET]: 'LBRACKET'
	[KEY_RBRACKET]: 'RBRACKET'
	[KEY_SEMICOLON]: 'SEMICOLON'
	[KEY_APOSTROPHE]: 'APOSTROPHE'
	[KEY_BACKQUOTE]: 'BACKQUOTE'
	[KEY_COMMA]: 'COMMA'
	[KEY_PERIOD]: 'PERIOD'
	[KEY_SLASH]: 'SLASH'
	[KEY_BACKSLASH]: 'BACKSLASH'
	[KEY_MINUS]: 'MINUS'
	[KEY_EQUAL]: 'EQUAL'
	[KEY_ENTER]: 'ENTER'
	[KEY_SPACE]: 'SPACE'
	[KEY_BACKSPACE]: 'BACKSPACE'
	[KEY_TAB]: 'TAB'
	[KEY_CAPSLOCK]: 'CAPSLOCK'
	[KEY_NUMLOCK]: 'NUMLOCK'
	[KEY_ESCAPE]: 'ESCAPE'
	[KEY_SCROLLLOCK]: 'SCROLLLOCK'
	[KEY_INSERT]: 'INSERT'
	[KEY_DELETE]: 'DELETE'
	[KEY_HOME]: 'HOME'
	[KEY_END]: 'END'
	[KEY_PAGEUP]: 'PAGEUP'
	[KEY_PAGEDOWN]: 'PAGEDOWN'
	[KEY_BREAK]: 'BREAK'
	[KEY_LSHIFT]: 'LSHIFT'
	[KEY_RSHIFT]: 'RSHIFT'
	[KEY_LALT]: 'LALT'
	[KEY_RALT]: 'RALT'
	[KEY_LCONTROL]: 'LCONTROL'
	[KEY_RCONTROL]: 'RCONTROL'
	[KEY_LWIN]: 'LWIN'
	[KEY_RWIN]: 'RWIN'
	[KEY_APP]: 'APP'
	[KEY_UP]: 'UP'
	[KEY_LEFT]: 'LEFT'
	[KEY_DOWN]: 'DOWN'
	[KEY_RIGHT]: 'RIGHT'
	[KEY_F1]: 'F1'
	[KEY_F2]: 'F2'
	[KEY_F3]: 'F3'
	[KEY_F4]: 'F4'
	[KEY_F5]: 'F5'
	[KEY_F6]: 'F6'
	[KEY_F7]: 'F7'
	[KEY_F8]: 'F8'
	[KEY_F9]: 'F9'
	[KEY_F10]: 'F10'
	[KEY_F11]: 'F11'
	[KEY_F12]: 'F12'
	[KEY_CAPSLOCKTOGGLE]: 'CAPSLOCKTOGGLE'
	[KEY_NUMLOCKTOGGLE]: 'NUMLOCKTOGGLE'
	[KEY_LAST]: 'LAST'
	[KEY_SCROLLLOCKTOGGLE]: 'SCROLLLOCKTOGGLE'
	[KEY_COUNT]: 'COUNT'
	[KEY_XBUTTON_A]: 'XBUTTON_A'
	[KEY_XBUTTON_B]: 'XBUTTON_B'
	[KEY_XBUTTON_X]: 'XBUTTON_X'
	[KEY_XBUTTON_Y]: 'XBUTTON_Y'
	[KEY_XBUTTON_LEFT_SHOULDER]: 'XBUTTON_LEFT_SHOULDER'
	[KEY_XBUTTON_RIGHT_SHOULDER]: 'XBUTTON_RIGHT_SHOULDER'
	[KEY_XBUTTON_BACK]: 'XBUTTON_BACK'
	[KEY_XBUTTON_START]: 'XBUTTON_START'
	[KEY_XBUTTON_STICK1]: 'XBUTTON_STICK1'
	[KEY_XBUTTON_STICK2]: 'XBUTTON_STICK2'
	[KEY_XBUTTON_UP]: 'XBUTTON_UP'
	[KEY_XBUTTON_RIGHT]: 'XBUTTON_RIGHT'
	[KEY_XBUTTON_DOWN]: 'XBUTTON_DOWN'
	[KEY_XBUTTON_LEFT]: 'XBUTTON_LEFT'
	[KEY_XSTICK1_RIGHT]: 'XSTICK1_RIGHT'
	[KEY_XSTICK1_LEFT]: 'XSTICK1_LEFT'
	[KEY_XSTICK1_DOWN]: 'XSTICK1_DOWN'
	[KEY_XSTICK1_UP]: 'XSTICK1_UP'
	[KEY_XBUTTON_LTRIGGER]: 'XBUTTON_LTRIGGER'
	[KEY_XBUTTON_RTRIGGER]: 'XBUTTON_RTRIGGER'
	[KEY_XSTICK2_RIGHT]: 'XSTICK2_RIGHT'
	[KEY_XSTICK2_LEFT]: 'XSTICK2_LEFT'
	[KEY_XSTICK2_DOWN]: 'XSTICK2_DOWN'
	[KEY_XSTICK2_UP]: 'XSTICK2_UP'
}

bind.LocalizedButtons =
	UP: 'UP Arrow'
	DOWN: 'DOWN Arrow'
	LEFT: 'LEFT Arrow'
	RIGHT: 'RIGHT Arrow'

KEY_LIST = [key for key, str in pairs bind.KeyMap]
bind.KeyMapReverse = {v, k for k, v in pairs bind.KeyMap}

bind.SerealizeKeys = (keys = {}) ->
	output = [bind.KeyMap[k] for k in *keys when bind.KeyMap[k]]
	return output

bind.UnSerealizeKeys = (keys = {}) ->
	output = [bind.KeyMapReverse[k] for k in *keys when bind.KeyMapReverse[k]]
	return output

class bind.KeyBindsAdapter
	new: (vname, binds, doLoad = true) =>
		error('Name is required') if not vname
		error('Binds are required') if not binds
		@vname = vname
		@fname = vname\lower()
		@fpath = 'dlib/keybinds/' .. @fname .. '.txt'
		@Setup(binds)
		@LoadKeybindings() if doLoad
		hook.Add 'Think', @vname .. '.Keybinds', -> @UpdateKeysStatus()

	Setup: (binds) =>
		@KeybindingsMap = binds

		for name, data in pairs @KeybindingsMap
			data.secondary = data.secondary or {}
			data.id = name
			data.name = data.name or '#BINDNAME?'
			data.desc = data.desc or '#BINDDESC?'
			data.order = data.order or 100

		@KeybindingsOrdered = [data for name, data in pairs @KeybindingsMap]
		table.sort(@KeybindingsOrdered, (a, b) -> a.order < b.order)

	RegisterBind: (id, name = '#BINDNAME?', desc = '#BINDDESC?', primary = {}, secondary = {}, order = 100) =>
		error('No ID specified!') if not id
		@KeybindingsMap[id] = {:name, :desc, :primary, :secondary, :order, :id}
		@KeybindingsOrdered = [data for name, data in pairs @KeybindingsMap]
		table.sort(@KeybindingsOrdered, (a, b) -> a.order < b.order)

	GetDefaultBindings: =>
		output = for id, data in pairs @KeybindingsMap
			primary = bind.SerealizeKeys(data.primary)
			secondary = bind.SerealizeKeys(data.secondary)
			{name: id, :primary, :secondary}
		return output

	UpdateKeysMap: =>
		watchButtons = {key, true for data in *@Keybindings for key in *data.primary}
		watchButtons[key] = true for data in *@Keybindings for key in *data.secondary
		@KeybindingsUserMap = {data.name, data for data in *@Keybindings}
		@KeybindingsUserMapCheck = {data.name, {name: data.name, primary: bind.UnSerealizeKeys(data.primary), secondary: bind.UnSerealizeKeys(data.secondary)} for data in *@Keybindings}
		@WatchingButtons = [bind.KeyMapReverse[key] for key, bool in pairs watchButtons]
		@PressedButtons = {key, false for key in *@WatchingButtons}
		@WatchingButtonsPerBinding = {key, {} for key in *@WatchingButtons}
		@BindPressStatus = {data.name, false for data in *@Keybindings}

		for {:name, :primary, :secondary} in *@Keybindings
			for key in *primary
				table.insert(@WatchingButtonsPerBinding[bind.KeyMapReverse[key]], name)
			for key in *secondary
				table.insert(@WatchingButtonsPerBinding[bind.KeyMapReverse[key]], name)

	SetKeyCombination: (bindid = '', isPrimary = true, keys = {}, update = true, doSave = true) =>
		if not @KeybindingsMap[bindid] return false
		if not @KeybindingsUserMap[bindid] return false

		if isPrimary
			for data in *@Keybindings
				if data.name == bindid
					data.primary = keys
					break
		else
			for data in *@Keybindings
				if data.name == bindid
					data.secondary = keys
					break

		@UpdateKeysMap() if update
		@SaveKeybindings() if doSave
		return true

	IsKeyDown: (keyid = KEY_NONE) => @PressedButtons[keyid] or false

	IsBindPressed: (bindid = '') =>
		return false if not @KeybindingsMap[bindid]
		return false if not @KeybindingsUserMap[bindid]
		return @BindPressStatus[bindid] or false

	IsBindDown: IsBindPressed

	InternalIsBindPressed: (bindid = '') =>
		return false if not @KeybindingsMap[bindid]
		return false if not @KeybindingsUserMapCheck[bindid]
		data = @KeybindingsUserMapCheck[bindid]
		total = #data.primary
		hits = 0
		total2 = #data.secondary
		hits2 = 0

		for key in *data.primary
			if @IsKeyDown(key)
				hits += 1
		for key in *data.secondary
			if @IsKeyDown(key)
				hits2 += 1

		return total ~= 0 and total == hits or total2 ~= 0 and total2 == hits2

	GetBindString: (bindid = '') =>
		return false if not @KeybindingsMap[bindid]
		return false if not @KeybindingsUserMap[bindid]
		local output
		data = @KeybindingsUserMap[bindid]

		if #data.primary ~= 0
			output = table.concat([bind.LocalizedButtons[key] or key for key in *data.primary], ' + ')

		if #data.secondary ~= 0
			tab = [bind.LocalizedButtons[key] or key for key in *data.secondary]
			output ..= ' or ' .. table.concat(tab, ' + ') if output
			output = table.concat(tab, ' + ') if not output

		return output or '<no key found>'

	SaveKeybindings: => file.Write(@fpath, util.TableToJSON(@Keybindings, true))
	LoadKeybindings: =>
		@Keybindings = nil
		settingsExists = file.Exists(@fpath, 'DATA')

		if settingsExists
			read = file.Read(@fpath, 'DATA')
			@Keybindings = util.JSONToTable(read)

			if @Keybindings
				defaultBinds = @GetDefaultBindings()
				valid = true
				hits = {}

				for data in *@Keybindings
					if not data.primary
						valid = false
						break

					if not data.secondary
						valid = false
						break

					if not data.name
						valid = false
						break

					if type(data.primary) ~= 'table'
						valid = false
						break

					if type(data.secondary) ~= 'table'
						valid = false
						break

					if type(data.name) ~= 'string'
						valid = false
						break

					hits[data.name] = true

				shouldSave = false

				if valid
					for data in *defaultBinds
						if not hits[data.name]
							table.insert(@Keybindings, data)
							shouldSave = true
					@UpdateKeysMap()
					@SaveKeybindings() if shouldSave
				else
					@Keybindings = nil

		if not @Keybindings
			@Keybindings = @GetDefaultBindings()
			@UpdateKeysMap()
			@SaveKeybindings()

		return @Keybindings

	UpdateKeysStatus: =>
		return if not @WatchingButtons
		for key in *@WatchingButtons
			oldStatus = @PressedButtons[key]
			newStatus = input.IsKeyDown(key)
			if oldStatus ~= newStatus
				@PressedButtons[key] = newStatus
				watching = @WatchingButtonsPerBinding[key]
				if watching
					for name in *watching
						oldPressStatus = @BindPressStatus[name]
						newPressStatus = @InternalIsBindPressed(name)
						if oldPressStatus ~= newPressStatus
							@BindPressStatus[name] = newPressStatus
							if not newPressStatus
								hook.Run(@vname .. '.BindReleased', name)
							else
								hook.Run(@vname .. '.BindPressed', name)

	OpenKeybindsMenu: =>
		with frame = vgui.Create('DFrame')
			\SetSkin('DLib_Black')
			\SetSize(470, ScrHL() - 200)
			\SetTitle(@vname .. ' Keybinds')
			\Center()
			\MakePopup()
			\SetKeyboardInputEnabled(true)

			.scroll = vgui.Create('DScrollPanel', frame)
			.scroll\Dock(FILL)

			.rows = for {:id} in *@KeybindingsOrdered
				with vgui.Create('DLibBindRow', .scroll)
					\SetTarget(@)
					\SetBindID(id)
					\Dock(TOP)

			return frame

bind.PANEL_BIND_FIELD =
	Init: =>
		@SetSkin('DLib_Black')
		@lastMousePress = 0
		@lastMousePressRight = 0
		@primary = true
		@lock = false
		@combination = {}
		@combinationNew = {}
		@SetMouseInputEnabled(true)
		--@SetKeyboardInputEnabled(true)
		@SetTooltip('Double RIGHT mouse press to clear binding\nDouble LEFT mouse press to change binding\nWhen changing binding, press needed buttons WITHOUT releasing.\nRelease one of pressed buttons to save.\nTo cancel, press ESCAPE')
		@combinationLabel = vgui.Create('DLabel', @)
		@addColor = 0
		with @combinationLabel
			\Dock(FILL)
			\DockMargin(5, 0, 0, 0)
			\SetTextColor(color_white)
			\SetText('#COMBINATION?')
	SetCombinationLabel: (keys = {}) =>
		str = table.concat([bind.LocalizedButtons[key] or key for key in *bind.SerealizeKeys(keys)], ' + ')
		@combinationLabel\SetText(str)
	StopLock: =>
		@lock = false
		@SetCursor('none')
		if #@combinationNew == 0
			@combinationNew = @combination
			@SetCombinationLabel(@combination)
		else
			@GetParent()\OnCombinationUpdates(@, @combinationNew)
			@combination = keys
			@SetCombinationLabel(@combinationNew)
	OnMousePressed: (code = MOUSE_LEFT) =>
		if code == MOUSE_LEFT
			if @lock
				@StopLock()
				return
			prev = @lastMousePress
			@lastMousePress = RealTimeL() + 0.4
			return if prev < RealTimeL()
			@lock = true
			@combinationNew = {}
			@combinationLabel\SetText('???')
			@mouseX, @mouseY = @LocalToScreen(5, 5)
			@SetCursor('blank')
			@pressedKeys = {key, false for key in *KEY_LIST}
		elseif code == MOUSE_RIGHT and not @lock
			prev = @lastMousePressRight
			@lastMousePressRight = RealTimeL() + 0.4
			return if prev < RealTimeL()
			@combinationNew = {}
			@GetParent()\OnCombinationUpdates(@, @combinationNew)
			@combination = @combinationNew
			@SetCombinationLabel(@combination)
	OnKeyCodePressed: (code = KEY_NONE) =>
		return if code == KEY_NONE or code == KEY_FIRST
		return if not @lock
		if code == KEY_ESCAPE
			@lock = false
			@combinationNew = @combination
			@SetCombinationLabel(@combination)
			@SetCursor('none')
			return
		elseif code == KEY_ENTER
			@StopLock()
			return
		table.insert(@combinationNew, code)
		@SetCombinationLabel(@combinationNew)
	OnKeyCodeReleased: (code = KEY_NONE) =>
		return if code == KEY_NONE or code == KEY_FIRST
		@StopLock() if @lock
	Paint: (w = 0, h = 0) =>
		surface.SetDrawColor(40 + 90 * @addColor, 40 + 90 * @addColor, 40)
		surface.DrawRect(0, 0, w, h)
		if @lock
			surface.SetDrawColor(137, 130, 104)
			surface.DrawRect(4, 4, w - 8, h - 8)
	Think: =>
		if @IsHovered()
			@addColor = math.min(@addColor + FrameTime() * 10, 1)
		else
			@addColor = math.max(@addColor - FrameTime() * 10, 0)
		if @lock
			input.SetCursorPos(@mouseX, @mouseY)
			for key in *KEY_LIST
				old = @pressedKeys[key]
				new = input.IsKeyDown(key)
				if old ~= new
					@pressedKeys[key] = new
					if new
						@OnKeyCodePressed(key)
					else
						@OnKeyCodeReleased(key)

bind.PANEL_BIND_INFO =
	Init: =>
		@SetSkin('DLib_Black')
		@SetMouseInputEnabled(true)
		@SetKeyboardInputEnabled(true)
		@bindid = ''
		@label = vgui.Create('DLabel', @)
		@SetSize(200, 30)
		with @label
			\SetText(' #HINT?')
			\Dock(LEFT)
			\DockMargin(10, 0, 0, 0)
			\SetSize(200, 0)
			\SetTooltip(' #DESCRIPTION?')
			\SetTextColor(color_white)
			\SetMouseInputEnabled(true)

		@primary = vgui.Create('DLibBindField', @)
		with @primary
			\Dock(LEFT)
			\DockMargin(10, 0, 0, 0)
			\SetSize(100, 0)
			.Primary = true
			.combination = {}

		@secondary = vgui.Create('DLibBindField', @)
		with @secondary
			\Dock(LEFT)
			\DockMargin(10, 0, 0, 0)
			\SetSize(100, 0)
			.Primary = false
			.combination = {}

	SetTarget: (target) =>
		@target = target

	SetBindID: (id = '') =>
		@bindid = id
		data = bind.KeybindingsUserMap[id]
		dataLabels = bind.KeybindingsMap[id]
		return if not data
		return if not dataLabels
		with @label
			\SetText(dataLabels.name)
			\SetTooltip(dataLabels.desc)
		@primary.combination = [key for key in *bind.UnSerealizeKeys(data.primary)]
		@secondary.combination = [key for key in *bind.UnSerealizeKeys(data.secondary)]
		@primary\SetCombinationLabel(@primary.combination)
		@secondary\SetCombinationLabel(@secondary.combination)
	OnCombinationUpdates: (pnl, newCombination = {}) =>
		return if @bindid == ''
		@target\SetKeyCombination(@bindid, pnl.Primary, bind.SerealizeKeys(newCombination))
	Paint: (w = 0, h = 0) =>
		surface.SetDrawColor(106, 122, 120)
		surface.DrawRect(0, 0, w, h)

vgui.Register('DLibBindField', bind.PANEL_BIND_FIELD, 'EditablePanel')
vgui.Register('DLibBindRow', bind.PANEL_BIND_INFO, 'EditablePanel')

bind.exportBinds = (classIn, target) ->
	target.RegisterBind = (...) -> classIn\RegisterBind(...)
	target.SerealizeKeys = (...) -> bind.SerealizeKeys(...)
	target.UnSerealizeKeys = (...) -> bind.UnSerealizeKeys(...)
	target.GetDefaultBindings = (...) -> classIn\GetDefaultBindings(...)
	target.UpdateKeysMap = (...) -> classIn\UpdateKeysMap(...)
	target.SetKeyCombination = (...) -> classIn\SetKeyCombination(...)
	target.IsKeyDown = (...) -> classIn\IsKeyDown(...)
	target.IsBindPressed = (...) -> classIn\IsBindPressed(...)
	target.IsBindDown = (...) -> classIn\IsBindPressed(...)
	target.InternalIsBindPressed = (...) -> classIn\InternalIsBindPressed(...)
	target.GetBindString = (...) -> classIn\GetBindString(...)
	target.SaveKeybindings = (...) -> classIn\SaveKeybindings(...)
	target.LoadKeybindings = (...) -> classIn\LoadKeybindings(...)
	target.UpdateKeysStatus = (...) -> classIn\UpdateKeysStatus(...)
	target.OpenKeybindsMenu = (...) -> classIn\OpenKeybindsMenu(...)
	target.LocalizedButtons = bind.LocalizedButtons

return bind
