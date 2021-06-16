
-- Copyright (C) 20XX DBotThePony

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

local DLib = DLib

local PANEL = {}

local function canonize(path)
	local skip_next = 0

	for i = #path, 1, -1 do
		if path[i] == '' then
			table.remove(path, i)
		elseif path[i] == '.' then
			table.remove(path, i)
		elseif path[i] == '..' then
			table.remove(path, i)
			skip_next = skip_next + 1
		elseif skip_next > 0 then
			table.remove(path, i)
			skip_next = skip_next - 1
		end
	end
end

local function canonizeString(path)
	local split = path:split('/')
	canonize(split)
	return table.concat(split, '/')
end

local function isPathWritable(path)
	local canonical = path:split('/')
	canonize(canonical)

	-- return file.Exists(canonical[1], 'GAME') and canonical[1]:lower() == 'data'
	return canonical[1] == 'data'
end

local writable = {
	'txt',
	'dat',
	'json',
	'xml',
	'csv',
	'jpg',
	'jpeg',
	'png',
	'vtf',
	'vmt',
	'mp3',
	'wav',
	'ogg',
}

local function isExtensionWritable(path)
	local last = table.remove(path:split('/'))

	-- regexp should look like
	-- \.(.+?)$
	-- but same can't be done in patterns
	for i = #last, 1, -1 do
		if last[i] == '.' then
			return table.qhasValue(writable, last:sub(i + 1))
		end
	end

	return false
end

function PANEL:Init()
	self:SetSize(1000, 700)

	self.row_tasks = {}
	self.row_tasks_ptr = 1

	self.dock_top = vgui.Create('EditablePanel', self)
	self.dock_top:Dock(TOP)
	self.dock_top:SetTall(22)

	self.dock_middle = vgui.Create('DHorizontalDivider', self)
	self.dock_middle:Dock(FILL)
	self.dock_middle:DockMargin(0, 5, 0, 5)

	self.dock_bottom = vgui.Create('EditablePanel', self)
	self.dock_bottom:Dock(BOTTOM)
	-- self.dock_bottom:SetTall(55)
	self.dock_bottom:SetTall(22)

	self.dock_bottom_right = vgui.Create('EditablePanel', self.dock_bottom)
	self.dock_bottom_right:Dock(RIGHT)
	self.dock_bottom_right:SetWide(180)
	self.dock_bottom_right:DockMargin(5, 0, 0, 0)

	self.dock_bottom_top = vgui.Create('EditablePanel', self.dock_bottom)
	self.dock_bottom_top:Dock(TOP)
	self.dock_bottom_top:DockMargin(0, 0, 5, 0)
	self.dock_bottom_top:SetTall(22)

	self.dock_buttons = vgui.Create('EditablePanel', self.dock_bottom_right)
	self.dock_buttons:Dock(BOTTOM)
	self.dock_buttons:SetTall(25)

	self.backward_button = vgui.Create('DButton', self.dock_top)
	self.forward_button = vgui.Create('DButton', self.dock_top)
	self.up_button = vgui.Create('DButton', self.dock_top)
	self.address_bar = vgui.Create('DTextEntry', self.dock_top)
	self.quick_search = vgui.Create('DTextEntry', self.dock_top)

	self.filename_label = vgui.Create('DLabel', self.dock_bottom_top)
	self.filename_bar = vgui.Create('DTextEntry', self.dock_bottom_top)

	-- self.filetype = vgui.Create('DComboBox', self.dock_bottom_right)
	self.open_file_button = vgui.Create('DButton', self.dock_buttons)
	self.cancel_button = vgui.Create('DButton', self.dock_buttons)

	self.folder_tree = vgui.Create('DTree', self.dock_middle)
	self.folder_contents = vgui.Create('DListView', self.dock_middle)

	self.dock_middle:SetLeft(self.folder_tree)
	self.dock_middle:SetRight(self.folder_contents)

	-- self.folder_tree:Dock(LEFT)
	-- self.folder_tree:DockMargin(0, 0, 10, 0)
	-- self.folder_contents:Dock(FILL)

	self.backward_button:Dock(LEFT)
	self.forward_button:Dock(LEFT)
	self.up_button:Dock(LEFT)
	self.quick_search:Dock(RIGHT)
	self.address_bar:Dock(FILL)

	self.backward_button:SetZPos(0)
	self.forward_button:SetZPos(1)
	self.up_button:SetZPos(2)
	self.address_bar:SetZPos(3)
	self.quick_search:SetZPos(4)

	self.filename_label:Dock(LEFT)
	self.filename_bar:Dock(FILL)

	-- self.filetype:Dock(TOP)
	self.open_file_button:Dock(LEFT)
	self.cancel_button:Dock(RIGHT)

	self.backward_button:DockMargin(2, 0, 2, 0)
	self.forward_button:DockMargin(2, 0, 2, 0)
	self.up_button:DockMargin(2, 0, 2, 0)
	self.address_bar:DockMargin(2, 0, 0, 0)
	self.quick_search:DockMargin(5, 0, 0, 0)

	self.quick_search:SetPlaceholderText(DLib.I18n.Localize('gui.dlib.filemanager.quick_search'))

	self.filename_label:SetText('gui.dlib.filemanager.file_name')
	self.filename_label:SizeToContents()
	self.filename_label:SetWide(self.filename_label:GetWide() + 5)

	self.open_file_button:SetText('gui.dlib.filemanager.open')
	self.open_file_button:SetWide(83)
	-- self.open_file_button:DockMargin(0, 0, 3, 0)

	self.cancel_button:SetText('gui.misc.cancel')
	self.cancel_button:SetWide(83)
	-- self.cancel_button:DockMargin(3, 0, 0, 0)

	-- self.filetype:SetTall(25)

	self.backward_button:SetText('')
	self.forward_button:SetText('')
	self.up_button:SetText('')

	self.backward_button:SetIcon('icon16/arrow_left.png')
	self.forward_button:SetIcon('icon16/arrow_right.png')
	self.up_button:SetIcon('icon16/arrow_up.png')

	self.backward_button:SetWide(24)
	self.forward_button:SetWide(24)
	self.up_button:SetWide(24)

	self.folder_contents:AddColumn('gui.dlib.filemanager.file_list.name')
	self.folder_contents:AddColumn('gui.dlib.filemanager.file_list.last_change')
	self.folder_contents:AddColumn('gui.dlib.filemanager.file_list.size')

	self.dock_middle:SetCookieName('dlib_filemanager')
	self.folder_contents:SetCookieName('dlib_filemanager_contents')
	self.folder_tree:SetCookieName('dlib_filemanager_tree')

	self.data_folder = 'DATA'
	self.current_path_str = ''
	self.current_path = {}
	self.file_mode = self.MODE_READ_FILE

	self.extension = 'txt'

	self:SetTitle('gui.dlib.filemanager.title_read')

	local _self = self

	function self.folder_contents:DoDoubleClick(_, line)
		_self:DoubleClickLine(line)
	end

	function self.folder_contents:OnRowRightClick(_, line)
		_self:OnRowRightClick(line)
	end

	function self.folder_contents:OnRowSelected(_, line)
		_self:OnRowSelected(line)
	end

	function self.cancel_button:DoClick()
		_self:Close()
	end

	function self.open_file_button:DoClick()
		local value = _self.filename_bar:GetValue()
		if value == '' then return end

		--if _self:OpenUserInput(value) then
		--  self.filename_bar:SetValue('')
		--end

		local success, folder = _self:OpenUserInputSelf(value)

		if success and folder then
			timer.Simple(0.1, function() if IsValid(_self) then _self.filename_bar:SetValue('') end end)
		end
	end

	function self.filename_bar:OnEnter()
		_self.open_file_button:DoClick()
	end

	function self.up_button:DoClick()
		if #_self.current_path == 0 then return end

		local cp = table.qcopy(_self.current_path)
		table.remove(cp)
		_self:SetPath(cp, false)
		_self:PushBackHistory(_self.current_path_str)

		_self:ScanCurrentDirectory()
		_self:RebuildFileList()

		_self.forward_button:SetEnabled(_self:GetHasForward())
		_self.backward_button:SetEnabled(_self:GetHasBackward())
	end

	self.quick_search:SetUpdateOnType(true)
	self.quick_search:SetWide(200)

	function self.quick_search:OnValueChange(value)
		if self._ignore then return end
		_self:RebuildFileList()
	end

	function self.quick_search:RealGetValue()
		if self._ignore then return '' end

		return self:GetValue()
	end

	function self.quick_search:OnEnter()
		local value = self:GetValue():lower()
		if value == '' then return end
		local first_match

		for i, data in ipairs(_self._file_list) do
			local lower = data[1]:lower()

			if lower == value then
				self._ignore = true

				timer.Simple(0.1, function()
					if IsValid(self) then
						self:SetValue('')
						self._ignore = false
					end
				end)

				_self:OpenUserInputSelf(data[1])
				return
			elseif lower:find(value, 1, true) then
				if first_match then return end
				first_match = data[1]
			end
		end

		if not first_match then return end
		_self:OpenUserInputSelf(first_match)

		timer.Simple(0.1, function()
			if IsValid(self) then
				self:SetValue('')
				self._ignore = false
			end
		end)
	end

	self.address_bar:SetValue('/')

	function self.address_bar:OnEnter()
		local path = self:GetValue()

		if path[1] == '/' then
			path = path:sub(2)
		end

		if _self:OpenUserInput(path) then
			timer.Simple(0.1, function() if IsValid(self) then self:SetValue('/' .. _self.current_path_str) end end)
		end
	end

	self.path_history = {}
	self.path_history_ptr = 0

	self.forward_button:SetEnabled(false)
	self.backward_button:SetEnabled(false)

	function self.forward_button:DoClick()
		_self.path_history_ptr = _self.path_history_ptr + 1
		_self:SetPathString(_self.path_history[_self.path_history_ptr], false)
		_self:ScanCurrentDirectory()
		_self:RebuildFileList()

		_self.forward_button:SetEnabled(_self:GetHasForward())
		_self.backward_button:SetEnabled(_self:GetHasBackward())
	end

	function self.backward_button:DoClick()
		_self.path_history_ptr = _self.path_history_ptr - 1
		_self:SetPathString(_self.path_history[_self.path_history_ptr], false)
		_self:ScanCurrentDirectory()
		_self:RebuildFileList()

		_self.forward_button:SetEnabled(_self:GetHasForward())
		_self.backward_button:SetEnabled(_self:GetHasBackward())
	end

	timer.Simple(0.1, function() if IsValid(self) then self:ThinkFirst() end end)

	hook.Add('Think', self, self.FMThink)
end

function PANEL:GetHasForward()
	return #self.path_history ~= 0 and #self.path_history > self.path_history_ptr
end

function PANEL:GetHasBackward()
	return #self.path_history ~= 0 and self.path_history_ptr > 1
end

function PANEL:PushBackHistory(path)
	if self.path_history[self.path_history_ptr + 1] then
		for i = self.path_history_ptr + 1, #self.path_history do
			self.path_history[i] = nil
		end
	end

	self.path_history_ptr = self.path_history_ptr + 1
	self.path_history[self.path_history_ptr] = path

	self.forward_button:SetEnabled(self:GetHasForward())
	self.backward_button:SetEnabled(self:GetHasBackward())
end

AccessorFunc(PANEL, 'data_folder', 'Fmod')
AccessorFunc(PANEL, 'data_folder', 'DataFolder')
AccessorFunc(PANEL, 'current_path_str', 'PathString')
AccessorFunc(PANEL, 'current_path', 'Path')
AccessorFunc(PANEL, 'file_mode', 'FileMode')
AccessorFunc(PANEL, 'extension', 'AutoExtension')

function PANEL:IsPathWritable(path)
	if path:find('"', 1, true) or path:find(':', 1, true) then return false end

	if self.data_folder:lower() == 'data' then return true end
	-- if self.data_folder:lower() ~= 'game' and not path:lower():trim():startsWith('data/') then return false end
	return isPathWritable(path)
end

function PANEL:SetFileMode(mode)
	assert(isnumber(mode))

	self.file_mode = mode

	if mode == self.MODE_READ_FILE then
		self:SetTitle('gui.dlib.filemanager.title_read')
	elseif mode == self.MODE_OPEN_DIRECTORY then
		self:SetTitle('gui.dlib.filemanager.title_open_dir')
	elseif mode == self.MODE_WIRTE_FILE then
		self:SetTitle('gui.dlib.filemanager.title_write')
	elseif mode == self.MODE_READ_WIRTE then
		self:SetTitle('gui.dlib.filemanager.title_open')
	else
		error('Unknown file mode: ' .. mode)
	end
end

PANEL.MODE_READ_FILE = 0
PANEL.MODE_OPEN_DIRECTORY = 1
PANEL.MODE_WIRTE_FILE = 2
PANEL.MODE_READ_WIRTE = 3

function PANEL:CallSelectFile(path)

end

function PANEL:OnRowRightClick(line)
	local path = canonizeString(self:GetRootedPath() .. line:GetValue(1))
	local menu = DermaMenu()

	menu:AddOption('gui.dlib.filemanager.open', function()
		self:DoubleClickLine(line)
	end)

	if line:GetValue(1) ~= '..' then
		menu:AddOption('gui.dlib.filemanager.copy_filename', function()
			SetClipboardText(line:GetValue(1))
		end)

		menu:AddOption('gui.dlib.filemanager.copy_path', function()
			SetClipboardText(path)
		end)
	end

	menu:AddOption('gui.dlib.filemanager.copy_date', function()
		SetClipboardText(line:GetValue(2))
	end)

	if line:GetValue(1) ~= '..' then
		menu:AddOption('gui.dlib.filemanager.copy_size', function()
			SetClipboardText(line:GetValue(3))
		end)
	end

	if self:IsPathWritable(path) then
		menu:AddSpacer()

		local sub, button = menu:AddSubMenu('gui.dlib.filemanager.delete')

		sub:AddSubMenu('gui.dlib.filemanager.delete', function()
			file.Delete(path)
		end)
	end

	menu:Open()
end

function PANEL:OnRowSelected(line)
	self.filename_bar:SetValue(line:GetValue(1))
end

function PANEL:OpenUserInputSelf(path, notify)
	return self:OpenUserInput(self:GetRootedPath() .. path, notify)
end

function PANEL:OpenUserInput(path, notify)
	local new_path = canonizeString(path)
	if #new_path == 0 then return false end
	if notify == nil then notify = true end
	-- if not file.Exists(new_path, self.data_folder) then return false end

	local split = new_path:split('/')
	local filename = split[#split]
	local exists = file.Exists(new_path, self.data_folder)
	local is_folder = exists and file.IsDir(new_path, self.data_folder)

	if is_folder then
		self:SetPathString(new_path, false)
		self.quick_search._ignore = true
		self.quick_search:SetValue('')
		self.quick_search._ignore = false
		self:ScanCurrentDirectory()
		self:RebuildFileList()
		self:PushBackHistory(new_path)
		return true, true
	elseif self.file_mode == self.MODE_READ_FILE then
		if exists then
			self:CallSelectFile(new_path)
		else
			if notify then
				Derma_Message('gui.dlib.filemanager.not_exists.description', 'gui.dlib.filemanager.not_exists.title', 'gui.misc.ok')
			end

			return false
		end
	elseif self.file_mode == self.MODE_READ_WIRTE then
		if not exists then
			if notify then
				Derma_Message('gui.dlib.filemanager.not_exists.description', 'gui.dlib.filemanager.not_exists.title', 'gui.misc.ok')
			end

			return false
		elseif not isExtensionWritable(new_path) then
			if notify then
				Derma_Message('gui.dlib.filemanager.not_writable_ext.description', 'gui.dlib.filemanager.not_writable_ext.title', 'gui.misc.ok')
			end

			return false
		elseif self:IsPathWritable(new_path) then
			for i = 1, #split - 1 do
				local construct_path = table.concat(split, '/', 1, i)

				if not file.IsDir(construct_path, self.data_folder) then
					if file.Exists(construct_path, self.data_folder) then
						Derma_Message('gui.dlib.filemanager.dir_is_file.description', 'gui.dlib.filemanager.dir_is_file.title', 'gui.misc.ok')
						return false
					elseif self:IsPathWritable(construct_path) then
						file.mkdir(construct_path)
					else
						Derma_Message('gui.dlib.filemanager.not_writable_dir.description', 'gui.dlib.filemanager.not_writable_dir.title', 'gui.misc.ok')
						return false
					end
				end
			end

			self:CallSelectFile(new_path)
		elseif notify then
			Derma_Message('gui.dlib.filemanager.not_writable.description', 'gui.dlib.filemanager.not_writable.title', 'gui.misc.ok')
			return false
		else
			return false
		end
	elseif self.file_mode == self.MODE_WIRTE_FILE then
		if not exists and not filename:find('.', 1, true) then
			filename = filename .. '.' .. self.extension
			new_path = new_path .. '.' .. self.extension
			exists = file.Exists(new_path, self.data_folder)
			is_folder = exists and file.IsDir(new_path, self.data_folder)
		end

		if not isExtensionWritable(new_path) then
			if notify then
				Derma_Message('gui.dlib.filemanager.not_writable_ext.description', 'gui.dlib.filemanager.not_writable_ext.title', 'gui.misc.ok')
			end

			return false
		elseif self:IsPathWritable(new_path) then
			if is_folder then
				Derma_Message('gui.dlib.filemanager.destination_is_dir.description', 'gui.dlib.filemanager.destination_is_dir.title', 'gui.misc.ok')
				return false
			elseif exists then
				self:OpenOverwriteModal(new_path, line:GetValue(1))
			else
				self:CallSelectFile(new_path)
			end
		elseif notify then
			Derma_Message('gui.dlib.filemanager.not_writable.description', 'gui.dlib.filemanager.not_writable.title', 'gui.misc.ok')
			return false
		else
			return false
		end
	else
		if notify then
			Derma_Message('gui.dlib.filemanager.not_exists.description', 'gui.dlib.filemanager.not_exists.title', 'gui.misc.ok')
		end

		return false
	end

	return true
end

function PANEL:DoubleClickLine(line)
	local new_path = canonizeString(self:GetRootedPath() .. line:GetValue(1))

	if line.is_folder then
		self:SetPathString(new_path, false)
		self.quick_search._ignore = true
		self.quick_search:SetValue('')
		self.quick_search._ignore = false
		self:ScanCurrentDirectory()
		self:RebuildFileList()
		self:PushBackHistory(new_path)
	elseif self.file_mode == self.MODE_READ_FILE then
		self:CallSelectFile(new_path)
	elseif self.file_mode == self.MODE_READ_WIRTE then
		if not isExtensionWritable(new_path) then
			Derma_Message('gui.dlib.filemanager.not_writable_ext.description', 'gui.dlib.filemanager.not_writable_ext.title', 'gui.misc.ok')
		elseif self:IsPathWritable(new_path) then
			self:CallSelectFile(new_path)
		else
			Derma_Message('gui.dlib.filemanager.not_writable.description', 'gui.dlib.filemanager.not_writable.title', 'gui.misc.ok')
		end
	elseif self.file_mode == self.MODE_WIRTE_FILE then
		if not isExtensionWritable(new_path) then
			Derma_Message('gui.dlib.filemanager.not_writable_ext.description', 'gui.dlib.filemanager.not_writable_ext.title', 'gui.misc.ok')
		elseif self:IsPathWritable(new_path) then
			self:OpenOverwriteModal(new_path, line:GetValue(1))
		else
			Derma_Message('gui.dlib.filemanager.not_writable.description', 'gui.dlib.filemanager.not_writable.title', 'gui.misc.ok')
		end
	end

	self.filename_bar:SetValue('')
end

function PANEL:OpenOverwriteModal(path, name)
	Derma_Query(
		DLib.I18n.Localize('gui.dlib.filemanager.overwrite.description', name),
		DLib.I18n.Localize('gui.dlib.filemanager.overwrite.title', name),
		'gui.misc.ok',
		function() if IsValid(self) then self:CallSelectFile(path) end end,
		'gui.misc.cancel'
	)
end

function PANEL:SetPathString(path, auto_rescan)
	assert(isstring(path))
	self.current_path = path:split('/')
	canonize(self.current_path)
	self.current_path_str = table.concat(self.current_path, '/')
	self.address_bar:SetValue('/' .. self.current_path_str)

	if auto_rescan == nil then auto_rescan = true end

	if not self.think_first or not auto_rescan then return end

	self:ScanCurrentDirectory()
	self:RebuildFileList()
end

function PANEL:SetPath(path, auto_rescan)
	assert(istable(path))
	self.current_path = path
	canonize(path)
	self.current_path_str = table.concat(path, '/')
	self.address_bar:SetValue('/' .. self.current_path_str)

	if auto_rescan == nil then auto_rescan = true end

	if not self.think_first or not auto_rescan then return end

	self:ScanCurrentDirectory()
	self:RebuildFileList()
end

function PANEL:ThinkFirst()
	self.think_first = true
	self:ScanCurrentDirectory()
	self:RebuildFileList()
	self:PushBackHistory(self.current_path_str)
end

function PANEL:GetRootedPath()
	return self.current_path_str == '' and '' or (self.current_path_str .. '/')
end

function PANEL:FMThink()
	if self.row_tasks[self.row_tasks_ptr] then
		local exhaust = 5
		local root = self:GetRootedPath()

		for i = self.row_tasks_ptr, #self.row_tasks do
			self.row_tasks_ptr = i

			if IsValid(self.row_tasks[i]) then
				local name = self.row_tasks[i]:GetValue(1)

				if not self.row_tasks[i].is_folder then
					self.row_tasks[i]:SetValue(3, DLib.I18n.FormatAnyBytes(file.Size(root .. name, self.data_folder)))
				end

				self.row_tasks[i]:SetValue(2, DLib.string.qdate(file.Time(root .. name, self.data_folder), true))

				exhaust = exhaust - 1

				if exhaust <= 0 then break end
			end
		end
	elseif self.row_tasks_ptr ~= 1 then
		self.row_tasks_ptr = 1
		self.row_tasks = {}
	end
end

local function sorter(a, b)
	return a:lower() < b:lower()
end

function PANEL:RebuildFileList()
	self.folder_contents:Clear()
	self.row_tasks = {}
	self.row_tasks_ptr = 1

	local search = self.quick_search:RealGetValue():lower()

	if search == '' then
		for i, data in ipairs(self._file_list) do
			if data[2] then
				self.row_tasks[i] = self.folder_contents:AddLine(data[1], '???', 'folder')
				self.row_tasks[i].is_folder = true
			else
				self.row_tasks[i] = self.folder_contents:AddLine(data[1], '???', '???')
				self.row_tasks[i].is_folder = false
			end
		end
	else
		for i, data in ipairs(self._file_list) do
			if data[1]:lower():find(search, 1, true) or data[1] == '..' then
				if data[2] then
					self.row_tasks[i] = self.folder_contents:AddLine(data[1], '???', 'folder')
					self.row_tasks[i].is_folder = true
				else
					self.row_tasks[i] = self.folder_contents:AddLine(data[1], '???', '???')
					self.row_tasks[i].is_folder = false
				end
			end
		end
	end
end

function PANEL:ScanCurrentDirectory()
	local root = self:GetRootedPath()
	local files, dirs = file.Find(root .. '*', self.data_folder)

	table.sort(files, sorter)
	table.sort(dirs, sorter)

	self._file_list = {}

	if #self.current_path ~= 0 then
		table.insert(self._file_list, {'..', true})
	end

	for i, dir in ipairs(dirs) do
		if dir ~= '/' and dir ~= '.' and dir ~= '..' then
			table.insert(self._file_list, {dir, true})
		end
	end

	for i, _file in ipairs(files) do
		table.insert(self._file_list, {_file, false})
	end
end

DLib.FileManagerPanel = PANEL
vgui.Register('DLib_FileManager', PANEL, 'DLib_Window')

