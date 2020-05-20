
-- Copyright (C) 2020 DBotThePony

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

local PANEL = {}

local rgba = {
	'red', 'green', 'blue', 'alpha'
}

local hsv = {
	'hue', 'saturation', 'value'
}

local wang_panels = table.qcopy(rgba)
table.append(wang_panels, hsv)

function PANEL:BindRegularWang(wang, index)
	function wang.OnValueChanged(wang, newvalue)
		if self.update then return end
		self[index] = newvalue
		self:UpdateColorCube()
		self:UpdateHSVWangs()
		self:UpdateAlphaBar()
	end
end

function PANEL:BindHSVWang(wang)
	function wang.OnValueChanged(wang, newvalue)
		if self.update then return end
		self:UpdateFromHSVWangs()
	end
end

function PANEL:Init()
	self.wang_canvas = vgui.Create('EditablePanel', self)
	self.wang_canvas:Dock(RIGHT)

	self.wang_label_rgb = vgui.Create('DLabel', self.wang_canvas)
	self.wang_label_rgb:SetText('   RGB')
	self.wang_label_rgb:Dock(TOP)
	self.wang_label_rgb:DockMargin(0, 0, 0, 5)

	for i, panelname in ipairs(wang_panels) do
		if panelname == 'hue' then
			self.wang_label_hsv = vgui.Create('DLabel', self.wang_canvas)
			self.wang_label_hsv:SetText('   HSV')
			self.wang_label_hsv:Dock(TOP)
			self.wang_label_hsv:DockMargin(0, 5, 0, 5)
		end

		self['wang_canvas_' .. panelname] = vgui.Create('EditablePanel', self.wang_canvas)
		self['wang_canvas_' .. panelname]:Dock(TOP)
	end

	self.hex_canvas = vgui.Create('EditablePanel', self.wang_canvas)
	self.hex_canvas:Dock(TOP)

	for i, panelname in ipairs(rgba) do
		self['wang_' .. panelname] = vgui.Create('DNumberWang', self['wang_canvas_' .. panelname])
		self['wang_' .. panelname]:Dock(RIGHT)
		self['wang_' .. panelname]:SetDecimals(0)
		self['wang_' .. panelname]:SetMinMax(0, 255)
	end

	for i, panelname in ipairs(hsv) do
		self['wang_' .. panelname] = vgui.Create('DNumberWang', self['wang_canvas_' .. panelname])
		self['wang_' .. panelname]:Dock(RIGHT)
		self['wang_' .. panelname]:SetDecimals(0)
		-- self['wang_' .. panelname]:SetMinMax(0, 255)
		self['wang_' .. panelname]:SetMinMax(0, 100)
	end

	self.wang_hue:SetMinMax(0, 360)

	self:BindRegularWang(self.wang_red, '_r')
	self:BindRegularWang(self.wang_green, '_g')
	self:BindRegularWang(self.wang_blue, '_b')
	self:BindRegularWang(self.wang_alpha, '_a')

	self:BindHSVWang(self.wang_hue)
	self:BindHSVWang(self.wang_saturation)
	self:BindHSVWang(self.wang_value)

	self.color_cube = vgui.Create('DColorCube', self)
	self.color_cube:Dock(FILL)

	function self.color_cube.OnUserChanged(color_cube, newvalue)
		newvalue:SetAlpha(self._a)
		self:_SetColor(newvalue)
		self:UpdateWangs()
		self:UpdateHSVWangs()
		self:UpdateAlphaBar()
	end

	self.color_wang = vgui.Create('DRGBPicker', self)
	self.color_wang:Dock(RIGHT)
	self.color_wang:SetWide(26)

	self.alpha_wang = vgui.Create('DAlphaBar', self)
	self.alpha_wang:Dock(RIGHT)
	self.alpha_wang:SetWide(26)

	function self.color_wang.OnChange(color_wang, newvalue)
		-- this is basically Hue wang by default
		-- so let's do this in Hue way

		--[[newvalue.a = self._a -- no color metatable
		self:_SetColor(newvalue)
		self:UpdateWangs()
		self:UpdateHSVWangs()
		self:UpdateColorCube()]]

		if self.update then return end

		local h, s, v = ColorToHSV(self:GetColor())
		local h2, s2, v2 = ColorToHSV(newvalue)
		self:_SetColor(HSVToColor(h2, s, v):SetAlpha(self._a))

		self:UpdateWangs()
		self:UpdateHSVWangs()
		self:UpdateColorCube()
		self:UpdateAlphaBar()
	end

	function self.alpha_wang.OnChange(color_wang, newvalue)
		self._a = math.round(newvalue * 255)
		self:UpdateData()
	end

	self._r = 255
	self._g = 255
	self._b = 255
	self._a = 255
	self.update = false

	self.allow_alpha = true

	self:UpdateData()
	self:SetTall(250)
end

function PANEL:UpdateData()
	self:UpdateWangs()
	self:UpdateHSVWangs()
	self:UpdateColorCube()
	self:UpdateAlphaBar()
	self:UpdateHueBar()
end

function PANEL:UpdateColorCube()
	self.update = true
	self.color_cube:SetColor(self:GetColor())
	self.update = false
end

function PANEL:UpdateHueBar()
	self.update = true

	local w, h = self.color_wang:GetSize()
	local hue = ColorToHSV(self:GetColor())

	self.color_wang.LastX = w / 2
	self.color_wang.LastY = h - hue / 360 * h

	self.update = false
end

function PANEL:UpdateAlphaBar()
	self.update = true

	self.alpha_wang:SetBarColor(self:GetColor():SetAlpha(255))
	local w, h = self.color_wang:GetSize()

	self.alpha_wang:SetValue(self._a / 255)

	self.update = false
end

function PANEL:UpdateWangs()
	self.update = true
	self.wang_red:SetValue(self._r)
	self.wang_green:SetValue(self._g)
	self.wang_blue:SetValue(self._b)
	self.wang_alpha:SetValue(self._a)
	self.update = false
end

function PANEL:UpdateHSVWangs()
	self.update = true
	local hue, saturation, value = ColorToHSV(self:GetColor())

	self.wang_hue:SetValue(hue)
	self.wang_saturation:SetValue(math.round(saturation * 100))
	self.wang_value:SetValue(math.round(value * 100))
	self.update = false
end

function PANEL:UpdateFromHSVWangs()
	local col = HSVToColorLua(self.wang_hue:GetValue(), self.wang_saturation:GetValue() / 100, self.wang_value:GetValue() / 100)
	col:SetAlpha(self._a)
	self:_SetColor(col)
	self:UpdateColorCube()
	self:UpdateWangs()
	self:UpdateAlphaBar()
	self:UpdateHueBar()
end

function PANEL:_SetColor(r, g, b, a)
	if IsColor(r) then
		r, g, b, a = r.r, r.g, r.b, r.a
	end

	self._r = r
	self._g = g
	self._b = b
	self._a = a

	self:ValueChanged(self:GetColor())
end

function PANEL:SetColor(r, g, b, a)
	if IsColor(r) then
		r, g, b, a = r.r, r.g, r.b, r.a
	end

	self._r = r
	self._g = g
	self._b = b
	self._a = a

	self:UpdateData()
end

function PANEL:ValueChanged(newvalue)

end

function PANEL:GetColor()
	return Color(self._r, self._g, self._b, self._a)
end

function PANEL:GetVector()
	return Vector(self._r / 255, self._g / 255, self._b / 255)
end

function PANEL:Think()
	self:CheckConVars()
end

function PANEL:GetAllowAlpha()
	return self.allow_alpha
end

PANEL.GetAlphaBar = PANEL.GetAllowAlpha

function PANEL:SetAllowAlpha(allow)
	assert(isbool(allow), 'allow should be a boolean')

	if self.allow_alpha == allow then return end
	self.allow_alpha = allow

	if allow then
		self:CheckConVar(self.con_var_alpha, '_a')
		self.alpha_wang:SetVisible(true)
		self.wang_canvas_alpha:SetVisible(true)
	else
		self._a = 255
		self.alpha_wang:SetVisible(false)
		self.wang_canvas_alpha:SetVisible(false)
	end

	self:InvalidateLayout()
end

PANEL.SetAlphaBar = PANEL.SetAllowAlpha

AccessorFunc(PANEL, 'con_var_red', 'ConVarR')
AccessorFunc(PANEL, 'con_var_green', 'ConVarG')
AccessorFunc(PANEL, 'con_var_blue', 'ConVarB')
AccessorFunc(PANEL, 'con_var_alpha', 'ConVarA')
-- AccessorFunc(PANEL, 'con_var_combined', 'ConVarCombined')

function PANEL:SetConVarR(con_var)
	if not con_var then
		self.con_var_red = nil
		return
	end

	self.con_var_red = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
	self:CheckConVar(self.con_var_red, '_r')
end

function PANEL:SetConVarG(con_var)
	if not con_var then
		self.con_var_green = nil
		return
	end

	self.con_var_green = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
	self:CheckConVar(self.con_var_green, '_g')
end

function PANEL:SetConVarB(con_var)
	if not con_var then
		self.con_var_blue = nil
		return
	end

	self.con_var_blue = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
	self:CheckConVar(self.con_var_blue, '_b')
end

function PANEL:SetConVarA(con_var)
	if not con_var then
		self.con_var_alpha = nil
		return
	end

	self.con_var_alpha = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)

	if self.allow_alpha then
		self:CheckConVar(self.con_var_alpha, '_a')
	end
end

--[[function PANEL:SetConVarCombined(con_var)
	if not con_var then
		self.con_var_combined = nil
		return
	end

	self.con_var_combined = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
end]]

function PANEL:SetConVarAll(prefix)
	self.con_var_red = prefix .. '_r'
	self.con_var_green = prefix .. '_g'
	self.con_var_blue = prefix .. '_b'
	self.con_var_alpha = prefix .. '_a'

	self:CheckConVars(true)
end

function PANEL:CheckConVars(force)
	if not force and input.IsMouseDown(MOUSE_LEFT) then return end

	local change = self:CheckConVar(self.con_var_red, '_r') or
		self:CheckConVar(self.con_var_green, '_g', false) or
		self:CheckConVar(self.con_var_blue, '_b', false) or
		self.allow_alpha and self:CheckConVar(self.con_var_alpha, '_a', false)

	if change then
		self:UpdateData()
	end
end

function PANEL:UpdateConVars()
	if self.con_var_red then
		local value = self.con_var_red:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_red:GetName(), self._r:tostring())
		end
	end

	if self.con_var_green then
		local value = self.con_var_green:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_green:GetName(), self._r:tostring())
		end
	end

	if self.con_var_blue then
		local value = self.con_var_blue:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_blue:GetName(), self._r:tostring())
		end
	end

	if self.allow_alpha and self.con_var_alpha then
		local value = self.con_var_alpha:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_alpha:GetName(), self._r:tostring())
		end
	end
end

function PANEL:CheckConVar(con_var, index, update_now)
	if not con_var then return false end

	local value = con_var:GetInt(255)

	if value ~= self[index] then
		self[index] = value

		if update_now or update_now == nil then
			self:UpdateData()
		end

		return true
	end

	return false
end

vgui.Register('DLibColorMixer', PANEL, 'EditablePanel')
