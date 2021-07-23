
-- Copyright (C) 2018-2020 DBotThePony

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

local function populate(self)
	if not IsValid(self) then return end

	self:SetSkin('DLib_Black')

	self:Button('gui.dlib.friends.open', 'dlib_friends')
	self:CheckBox('gui.dlib.friends.settings.steam', 'cl_dlib_steamfriends')

	self:Help('')
	self:CheckBox('gui.dlib.menu.settings.blur_enable', 'dlib_blur_enable')
	self:CheckBox('gui.dlib.menu.settings.blur_new', 'dlib_blur_new')
	self:NumSlider('gui.dlib.menu.settings.blur_passes', 'dlib_blur_passes', 1, 10, 0)
	self:NumSlider('gui.dlib.menu.settings.blur_x', 'dlib_blur_x', 1, 10, 0)
	self:NumSlider('gui.dlib.menu.settings.blur_y', 'dlib_blur_y', 1, 10, 0)

	self:CheckBox('gui.dlib.menu.settings.vgui_blur', 'dlib_vguiblur')

	self:Help('')
	self:CheckBox('gui.dlib.menu.settings.screenscale', 'dlib_screenscale')
	self:NumSlider('gui.dlib.menu.settings.screenscale_mul', 'dlib_screenscale_mul', 0.01, 10, 1)

	self:Help('DLibColorMixer')
	self:CheckBox('gui.dlib.menu.settings.oldalpha', 'cl_dlib_colormixer_oldalpha')
	self:CheckBox('gui.dlib.menu.settings.oldhue', 'cl_dlib_colormixer_oldhue')
	self:CheckBox('gui.dlib.menu.settings.wangbars', 'cl_dlib_colormixer_wangbars')

	self:Help('')
	self:CheckBox('gui.dlib.menu.settings.strict', 'dlib_strict')
	self:CheckBox('gui.dlib.menu.settings.debug', 'dlib_debug')

	self:Help('')
	self:CheckBox('gui.dlib.menu.settings.donation_never', 'dlib_donate_never')

	-- self:Help('')
	-- self:CheckBox('gui.dlib.menu.settings.net_compress', 'dlib_net_compress_cl')

	self:Help('gui.dlib.menu.settings.profile_hooks_tip')
	self:Button('gui.dlib.menu.settings.profile_hooks', 'dlib_profile_hooks_cl')
	self:Button('gui.dlib.menu.settings.print_profile_hooks', 'dlib_profile_hooks_last_cl')
	self:Button('gui.dlib.menu.settings.reload_materials', 'dlib_reload_materials')

	self:Help('')
	self:CheckBox('gui.dlib.menu.settings.replace_missing_textures', 'dlib_replace_missing_textures')
	self:CheckBox('gui.dlib.menu.settings.replace_missing_textures_sugar', 'dlib_replace_missing_textures_sugar')

	self:Help('')
	self:CheckBox('gui.dlib.menu.settings.performance_screen', 'dlib_performance')
end

hook.Add('PopulateToolMenu', 'DLib.Settings', function()
	spawnmenu.AddToolMenuOption('Utilities', 'User', 'DLib.Settings', 'gui.dlib.menu.settings.name', '', '', populate)
end)
