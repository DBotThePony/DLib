
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
local run_scanner, run_clone_tree, run_move_tree, delete_tree

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

function PANEL:MakeFolder(rooted_path, path_to_data_dir)
	local _text = ''

	local function request()
		Derma_StringRequest(
			'gui.dlib.filemanager.make_folder.title',
			'gui.dlib.filemanager.make_folder.description',
			_text,
			function(text)
				text = text:lower()
				_text = text

				if text:find('"', 1, true) or text:find(':', 1, true) or text:find('/', 1, true) or text == '.' or text == '' or text == '..' or #text >= 253 or file.Exists(rooted_path .. text, self.data_folder) then
					Derma_Query(
						'gui.dlib.filemanager.make_folder.error_description',
						'gui.dlib.filemanager.make_folder.error_title',

						'gui.misc.ok',
						request,
						'gui.misc.cancel'
					)

					return
				end

				file.mkdir(path_to_data_dir .. text)

				if not file.IsDir(rooted_path .. text, self.data_folder) then
					Derma_Query(
						'gui.dlib.filemanager.make_folder.error_description',
						'gui.dlib.filemanager.make_folder.error_title',

						'gui.misc.ok',
						request,
						'gui.misc.cancel'
					)
				else
					self:ScanCurrentDirectory()
					self:RebuildFileList()
				end
			end,
			nil,
			'gui.misc.ok',
			'gui.misc.cancel'
		)
	end

	request()
end

function PANEL:Init()
	self:SetSize(1000, 700)
	self:Center()

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
	self.new_folder_button = vgui.Create('DButton', self.dock_top)
	self.paste_button = vgui.Create('DButton', self.dock_top)
	self.address_bar = vgui.Create('DTextEntry', self.dock_top)
	self.quick_search = vgui.Create('DTextEntry', self.dock_top)

	self.filename_label = vgui.Create('DLabel', self.dock_bottom_top)
	self.filename_bar = vgui.Create('DTextEntry', self.dock_bottom_top)

	-- self.filetype = vgui.Create('DComboBox', self.dock_bottom_right)
	self.open_file_button = vgui.Create('DButton', self.dock_buttons)
	self.cancel_button = vgui.Create('DButton', self.dock_buttons)

	self.folder_tree = vgui.Create('DTree', self.dock_middle)
	self.folder_contents = vgui.Create('DListView', self.dock_middle)
	self.folder_contents:SetSortable(false)

	self.dock_middle:SetLeft(self.folder_tree)
	self.dock_middle:SetRight(self.folder_contents)

	-- self.folder_tree:Dock(LEFT)
	-- self.folder_tree:DockMargin(0, 0, 10, 0)
	-- self.folder_contents:Dock(FILL)

	self.backward_button:Dock(LEFT)
	self.forward_button:Dock(LEFT)
	self.up_button:Dock(LEFT)
	self.new_folder_button:Dock(LEFT)
	self.paste_button:Dock(LEFT)
	self.quick_search:Dock(RIGHT)
	self.address_bar:Dock(FILL)

	self.backward_button:SetZPos(0)
	self.forward_button:SetZPos(1)
	self.up_button:SetZPos(2)
	self.new_folder_button:SetZPos(3)
	self.paste_button:SetZPos(4)
	self.address_bar:SetZPos(5)
	self.quick_search:SetZPos(6)

	self.filename_label:Dock(LEFT)
	self.filename_bar:Dock(FILL)

	-- self.filetype:Dock(TOP)
	self.open_file_button:Dock(LEFT)
	self.cancel_button:Dock(RIGHT)

	self.backward_button:DockMargin(2, 0, 2, 0)
	self.forward_button:DockMargin(2, 0, 2, 0)
	self.up_button:DockMargin(2, 0, 2, 0)
	self.new_folder_button:DockMargin(2, 0, 2, 0)
	self.paste_button:DockMargin(2, 0, 2, 0)
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
	self.new_folder_button:SetText('')
	self.paste_button:SetText('')

	self.backward_button:SetIcon('icon16/arrow_left.png')
	self.forward_button:SetIcon('icon16/arrow_right.png')
	self.up_button:SetIcon('icon16/arrow_up.png')
	self.new_folder_button:SetIcon('icon16/folder_add.png')
	self.paste_button:SetIcon('icon16/folder_page.png')

	self.backward_button:SetWide(24)
	self.forward_button:SetWide(24)
	self.up_button:SetWide(24)
	self.new_folder_button:SetWide(24)
	self.paste_button:SetWide(24)

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

	function self.folder_tree:OnNodeSelected(node)
		if self._ignore then return end
		self._ignore = true
		_self:OpenUserInput(node:GetFolder())
		self._ignore = false
	end

	function self.folder_contents:DoDoubleClick(_, line)
		_self:DoubleClickLine(line)
	end

	function self.folder_contents:OnRowRightClick(_, line)
		_self:OnRowRightClick(self:GetSelected())
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
	self.paste_button:SetEnabled(false)

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

	function self.new_folder_button:DoClick()
		local rooted_path = _self:GetRootedPath()
		local path_to_data_dir = rooted_path

		if _self.data_folder ~= 'DATA' then
			path_to_data_dir = path_to_data_dir:gsub('^[dD][aA][tT][aA]/', '')
		end

		_self:MakeFolder(rooted_path, path_to_data_dir)
	end

	function self.paste_button:DoClick()
		local cpath = _self.current_path_str:lower()
		local cpath2 = _self.current_path_str
		local _type = _self.remembered_path_type
		local context = _self.remembered_path_context
		local rooted = _self:GetRootedPath()

		if system.IsWindows() and cpath == context:lower() then
			Derma_Message('gui.dlib.filemanager.same_path.description', 'gui.dlib.filemanager.same_path.title', 'gui.misc.ok')
			return
		end

		for i, path in ipairs(_self.remembered_path_list) do
			path = path:lower()

			if cpath:startsWith(path) then
				Derma_Message('gui.dlib.filemanager.same_path.description', 'gui.dlib.filemanager.same_path.title', 'gui.misc.ok')
				return
			end
		end

		run_scanner(_self.remembered_path_list, _self):Then(function(tree_files, tree_dirs, size)
			local _tree_files, _tree_dirs = {}, {}
			local len = #context

			if len ~= 0 then len = len + 1 end

			for i, path in ipairs(tree_dirs) do
				table.insert(_tree_dirs, cpath2 .. path:sub(len))
			end

			for i, path in ipairs(tree_files) do
				_tree_files[path] = cpath2 .. path:sub(len)
			end

			if _type then
				run_clone_tree(_tree_files, _tree_dirs, size):Then(function()
					if IsValid(_self) then
						_self:ScanCurrentDirectory()
						_self:RebuildFileList()
					end
				end):Catch(function()
					if IsValid(_self) then
						_self:ScanCurrentDirectory()
						_self:RebuildFileList()
					end
				end)
			else
				run_move_tree(_tree_files, _tree_dirs, size):Then(function()
					if IsValid(_self) then
						_self:ForgetPathList()

						delete_tree(tree_files, tree_dirs):Then(function()
							if IsValid(_self) then
								_self:ScanCurrentDirectory()
								_self:RebuildFileList()
							end
						end):Catch(function()
							if IsValid(_self) then
								_self:ScanCurrentDirectory()
								_self:RebuildFileList()
							end
						end)
					end
				end):Catch(function()
					if IsValid(_self) then
						_self:ForgetPathList()

						_self:ScanCurrentDirectory()
						_self:RebuildFileList()
					end
				end)
			end
		end)
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

function PANEL:SetFmod()
	error('Not implemented')
end

function PANEL:SetDataFolder()
	error('Not implemented')
end

function PANEL:SetFilenameBar(value)
	return self.filename_bar:SetValue(value)
end

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
		self.open_file_button:SetText('gui.dlib.filemanager.open')
	elseif mode == self.MODE_OPEN_DIRECTORY then
		self:SetTitle('gui.dlib.filemanager.title_open_dir')
		self.open_file_button:SetText('gui.dlib.filemanager.open')
	elseif mode == self.MODE_WIRTE_FILE then
		self:SetTitle('gui.dlib.filemanager.title_write')
		self.open_file_button:SetText('gui.dlib.filemanager.write')
	elseif mode == self.MODE_READ_WRITE then
		self:SetTitle('gui.dlib.filemanager.title_open')
		self.open_file_button:SetText('gui.dlib.filemanager.open')
	else
		error('Unknown file mode: ' .. mode)
	end
end

PANEL.MODE_READ_FILE = 0
PANEL.MODE_READ = 0
PANEL.MODE_OPEN = 0
PANEL.MODE_OPEN_DIRECTORY = 1
PANEL.MODE_WIRTE_FILE = 2
PANEL.MODE_WIRTE = 2
PANEL.MODE_READ_WRITE = 3

function PANEL:CallSelectFile(path, stripped_ext, stripped, stripped_dir)

end

function PANEL:DoCallSelectFile(path)
	local split = path:split('/')
	local stripped = split[#split]:find('(.-)%.')
	local status = self:CallSelectFile(path, split[#split], stripped, table.concat(split, '/', 1, #split - 1))

	if status == true then
		self:Close()
	end

	return status
end

local function file_scanner(path_list, tree_files, tree_dirs)
	local index = 1
	local size = 0

	coroutine.yield(0, 0, 0, '')

	while index <= #path_list do
		local path = path_list[index]

		local scan_files, scan_dirs = file.Find(path .. '/*', 'DATA')

		for i, path2 in ipairs(scan_files) do
			table.insert(tree_files, path .. '/' .. path2)

			local get_size = file.Size(path .. '/' .. path2, 'DATA')

			if get_size then
				size = size + get_size
			end

			if i % 10 == 0 then
				coroutine.yield(#tree_files, #tree_dirs, size, path .. '/' .. path2)
			end
		end

		for i, path2 in ipairs(scan_dirs) do
			table.insert(path_list, path .. '/' .. path2)
		end

		table.insert(tree_dirs, path)
		index = index + 1

		coroutine.yield(#tree_files, #tree_dirs, size, path)
	end

	return #tree_files, #tree_dirs, size, ''
end

function run_scanner(path_list, validity)
	local id = 'fm_scan_task' .. SysTime()

	local window = vgui.Create('DLib_Window')

	window:SetTitle('gui.dlib.filemanager.scanning.title')
	window:SetSize(400, 200)
	window:Center()

	local bar1 = vgui.Create('EditablePanel', window)
	local bar2 = vgui.Create('EditablePanel', window)
	local bar3 = vgui.Create('EditablePanel', window)
	local bar4 = vgui.Create('EditablePanel', window)
	local current_file_label = vgui.Create('DLabel', window)

	bar1:Dock(TOP)
	bar2:Dock(TOP)
	bar3:Dock(TOP)
	bar4:Dock(TOP)
	current_file_label:Dock(TOP)

	bar1:DockMargin(0, 2, 0, 2, 0)
	bar2:DockMargin(0, 2, 0, 2, 0)
	bar3:DockMargin(0, 2, 0, 2, 0)
	bar4:DockMargin(0, 2, 0, 2, 0)
	current_file_label:DockMargin(0, 5, 0, 5, 0)

	bar1:SetZPos(0)
	bar2:SetZPos(1)
	bar3:SetZPos(2)
	bar4:SetZPos(4)
	current_file_label:SetZPos(3)

	current_file_label:SetText('...')

	local cancel = vgui.Create('DButton', bar4)

	cancel:SetText('gui.misc.cancel')
	-- cancel:SetFont('dlib_fm_status')
	cancel.DoClick = window.Close:Wrap(window)
	cancel:Dock(RIGHT)
	cancel:SizeToContents()
	cancel:SetWide(cancel:GetWide() + 50)

	local pfiles = vgui.Create('DLabel', bar1)
	local pdirs = vgui.Create('DLabel', bar2)
	local psize = vgui.Create('DLabel', bar3)

	local pfiles_count = vgui.Create('DLabel', bar1)
	local pdirs_count = vgui.Create('DLabel', bar2)
	local psize_count = vgui.Create('DLabel', bar3)

	pfiles:SetText('gui.dlib.filemanager.scanning.files')
	pdirs:SetText('gui.dlib.filemanager.scanning.dirs')
	psize:SetText('gui.dlib.filemanager.scanning.size')
	pfiles_count:SetText('0')
	pdirs_count:SetText('0')
	psize_count:SetText(DLib.I18n.FormatAnyBytesLong(0))

	pfiles:Dock(FILL)
	pfiles_count:Dock(RIGHT)
	pdirs:Dock(FILL)
	pdirs_count:Dock(RIGHT)
	psize:Dock(FILL)
	psize_count:Dock(RIGHT)

	pfiles:DockMargin(10, 0, 0, 0)
	pfiles_count:DockMargin(0, 0, 10, 0)
	pdirs:DockMargin(10, 0, 0, 0)
	pdirs_count:DockMargin(0, 0, 10, 0)
	psize:DockMargin(10, 0, 0, 0)
	psize_count:DockMargin(0, 0, 10, 0)

	local tree_files, tree_dirs, copy = {}, {}, {}

	for i, path in ipairs(path_list) do
		if file.IsDir(path, 'DATA') then
			table.insert(copy, path)
		else
			table.insert(tree_files, path)
		end
	end

	local thread = coroutine.create(file_scanner)
	local _, files_count, dirs_count, size, file_path = coroutine.resume(thread, copy, tree_files, tree_dirs)

	return DLib.Promise(function(resolve, reject)
		hook.Add('Think', id, function()
			if validity and not IsValid(validity) or not IsValid(window) then
				hook.Remove('Think', id)
				reject('User input')
				return
			end

			_, files_count, dirs_count, size, file_path = coroutine.resume(thread, path_list, tree_files, tree_dirs, status)

			pfiles_count:SetText(files_count:tostring())
			pdirs_count:SetText(dirs_count:tostring())
			psize_count:SetText(DLib.I18n.FormatAnyBytesLong(size))
			pfiles_count:SizeToContents()
			pdirs_count:SizeToContents()
			psize_count:SizeToContents()
			current_file_label:SetText(file_path)

			if coroutine.status(thread) == 'dead' then
				hook.Remove('Think', id)
				resolve(tree_files, tree_dirs, size)
				window:Close()
			end
		end)
	end)
end

local function longer_first(a, b)
	return a > b
end

local function longer_last(a, b)
	return a < b
end

local function tree_delete_worker(tree_files, tree_dirs)
	local total_files, total_dirs = #tree_files, #tree_dirs

	coroutine.yield(total_files, left_dirs, '')

	for i, path in ipairs(tree_files) do
		file.Delete(path)

		if i % 10 == 0 then
			coroutine.yield(total_files - i, total_dirs, path)
		end
	end

	table.sort(tree_dirs, longer_first)

	for i, path in ipairs(tree_dirs) do
		file.Delete(path)

		if i % 10 == 0 then
			coroutine.yield(0, total_dirs - i, path)
		end
	end

	return 0, 0, ''
end

function delete_tree(tree_files, tree_dirs)
	local id = 'fm_delete_task' .. SysTime()

	local window = vgui.Create('DLib_Window')

	window:SetTitle('gui.dlib.filemanager.deleting.title')
	window:SetSize(400, 200)
	window:Center()

	local bar1 = vgui.Create('EditablePanel', window)
	local bar2 = vgui.Create('EditablePanel', window)
	local bar4 = vgui.Create('EditablePanel', window)
	local current_file_label = vgui.Create('DLabel', window)

	bar1:Dock(TOP)
	bar2:Dock(TOP)
	bar4:Dock(TOP)
	current_file_label:Dock(TOP)

	bar1:DockMargin(0, 2, 0, 2, 0)
	bar2:DockMargin(0, 2, 0, 2, 0)
	bar4:DockMargin(0, 2, 0, 2, 0)
	current_file_label:DockMargin(0, 5, 0, 5, 0)

	bar1:SetZPos(0)
	bar2:SetZPos(1)
	bar4:SetZPos(4)
	current_file_label:SetZPos(3)

	current_file_label:SetText('...')

	local cancel = vgui.Create('DButton', bar4)

	cancel:SetText('gui.misc.cancel')
	-- cancel:SetFont('dlib_fm_status')
	cancel.DoClick = window.Close:Wrap(window)
	cancel:Dock(RIGHT)
	cancel:SizeToContents()
	cancel:SetWide(cancel:GetWide() + 50)

	local pfiles = vgui.Create('DLabel', bar1)
	local pdirs = vgui.Create('DLabel', bar2)

	local pfiles_count = vgui.Create('DLabel', bar1)
	local pdirs_count = vgui.Create('DLabel', bar2)

	pfiles:SetText('gui.dlib.filemanager.deleting.files')
	pdirs:SetText('gui.dlib.filemanager.deleting.dirs')
	pfiles_count:SetText('0')
	pdirs_count:SetText('0')

	pfiles:Dock(FILL)
	pfiles_count:Dock(RIGHT)
	pdirs:Dock(FILL)
	pdirs_count:Dock(RIGHT)

	pfiles:DockMargin(10, 0, 0, 0)
	pfiles_count:DockMargin(0, 0, 10, 0)
	pdirs:DockMargin(10, 0, 0, 0)
	pdirs_count:DockMargin(0, 0, 10, 0)

	local thread = coroutine.create(tree_delete_worker)
	local _, files_count, dirs_count, file_path = coroutine.resume(thread, tree_files, tree_dirs)

	return DLib.Promise(function(resolve, reject)
		hook.Add('Think', id, function()
			if validity and not IsValid(validity) or not IsValid(window) then
				hook.Remove('Think', id)
				reject('User input')
				return
			end

			_, files_count, dirs_count, file_path = coroutine.resume(thread, path_list, tree_files, tree_dirs, status)

			pfiles_count:SetText(files_count:tostring())
			pdirs_count:SetText(dirs_count:tostring())
			pfiles_count:SizeToContents()
			pdirs_count:SizeToContents()
			current_file_label:SetText(file_path)

			if coroutine.status(thread) == 'dead' then
				hook.Remove('Think', id)
				resolve()
				window:Close()
			end
		end)
	end)
end

local function clone_tree_worker(tree_files, tree_dirs)
	local copied, copied_size = 0, 0
	local dirs = #tree_dirs

	table.sort(tree_dirs, longer_last)

	coroutine.yield(0, 0, 0, '')

	for i, path in ipairs(tree_dirs) do
		file.mkdir(path)
		coroutine.yield(0, i, 0, path)
	end

	local systime = SysTime() + 0.02

	for _from, _to in pairs(tree_files) do
		if file.Exists(_to, 'DATA') then
			copied = copied + 1

			if SysTime() > systime then
				coroutine.yield(copied, dirs, copied_size, path .. ' ALREADY EXISTS')
				systime = SysTime() + 0.02
			end
		else
			local open_read = file.Open(_from, 'rb', 'DATA')

			if open_read then
				local open_write = file.Open(_to, 'wb', 'DATA')

				if open_write then
					while open_read:Size() > open_write:Tell() do
						local read = open_read:Read(math.max(open_read:Size() - open_write:Tell(), 0x00020000))
						open_write:Write(read)
						copied_size = copied_size + #read

						open_write:Flush()

						if SysTime() > systime then
							coroutine.yield(copied, dirs, copied_size, _to)
							systime = SysTime() + 0.02
						end
					end

					open_write:Close()
				end

				open_read:Close()
			end

			copied = copied + 1

			if SysTime() > systime then
				coroutine.yield(copied, dirs, copied_size, _to)
				systime = SysTime() + 0.02
			end
		end
	end

	return copied, dirs, copied_size, ''
end

function run_clone_tree(tree_files, tree_dirs, total_size)
	local id = 'fm_clone_task' .. SysTime()

	local total_dirs, total_files = #tree_dirs, table.Count(tree_files)

	local window = vgui.Create('DLib_Window')

	window:SetTitle('gui.dlib.filemanager.clone.worker.title')
	window:SetSize(400, 200)
	window:Center()

	local bar1 = vgui.Create('EditablePanel', window)
	local bar2 = vgui.Create('EditablePanel', window)
	local bar3 = vgui.Create('EditablePanel', window)
	local bar4 = vgui.Create('EditablePanel', window)
	local current_file_label = vgui.Create('DLabel', window)

	bar1:Dock(TOP)
	bar2:Dock(TOP)
	bar3:Dock(TOP)
	bar4:Dock(TOP)
	current_file_label:Dock(TOP)

	bar1:DockMargin(0, 2, 0, 2, 0)
	bar2:DockMargin(0, 2, 0, 2, 0)
	bar3:DockMargin(0, 2, 0, 2, 0)
	bar4:DockMargin(0, 2, 0, 2, 0)
	current_file_label:DockMargin(0, 5, 0, 5, 0)

	bar1:SetZPos(0)
	bar2:SetZPos(1)
	bar3:SetZPos(2)
	bar4:SetZPos(4)
	current_file_label:SetZPos(3)

	current_file_label:SetText('...')

	local cancel = vgui.Create('DButton', bar4)

	cancel:SetText('gui.misc.cancel')
	-- cancel:SetFont('dlib_fm_status')
	cancel.DoClick = window.Close:Wrap(window)
	cancel:Dock(RIGHT)
	cancel:SizeToContents()
	cancel:SetWide(cancel:GetWide() + 50)

	local pfiles = vgui.Create('DLabel', bar1)
	local pdirs = vgui.Create('DLabel', bar2)
	local psize = vgui.Create('DLabel', bar3)

	local pfiles_count = vgui.Create('DLabel', bar1)
	local pdirs_count = vgui.Create('DLabel', bar2)
	local psize_count = vgui.Create('DLabel', bar3)

	pfiles:SetText('gui.dlib.filemanager.clone.worker.files')
	pdirs:SetText('gui.dlib.filemanager.clone.worker.dirs')
	psize:SetText('gui.dlib.filemanager.clone.worker.size')
	pfiles_count:SetText(string.format('%d / %d', 0, total_files))
	pdirs_count:SetText(string.format('%d / %d', 0, total_dirs))
	psize_count:SetText(string.format('%s / %s', DLib.I18n.FormatAnyBytesLong(0), DLib.I18n.FormatAnyBytesLong(total_size)))

	pfiles:Dock(FILL)
	pfiles_count:Dock(RIGHT)
	pdirs:Dock(FILL)
	pdirs_count:Dock(RIGHT)
	psize:Dock(FILL)
	psize_count:Dock(RIGHT)

	pfiles:DockMargin(10, 0, 0, 0)
	pfiles_count:DockMargin(0, 0, 10, 0)
	pdirs:DockMargin(10, 0, 0, 0)
	pdirs_count:DockMargin(0, 0, 10, 0)
	psize:DockMargin(10, 0, 0, 0)
	psize_count:DockMargin(0, 0, 10, 0)

	local thread = coroutine.create(clone_tree_worker)
	local _, files_count, dirs_count, size, file_path = coroutine.resume(thread, tree_files, tree_dirs)

	return DLib.Promise(function(resolve, reject)
		hook.Add('Think', id, function()
			if validity and not IsValid(validity) or not IsValid(window) then
				hook.Remove('Think', id)
				reject('User input')
				return
			end

			_, files_count, dirs_count, size, file_path = coroutine.resume(thread, path_list, tree_files, tree_dirs, status)

			pfiles_count:SetText(string.format('%d / %d', files_count, total_files))
			pdirs_count:SetText(string.format('%d / %d', dirs_count, total_dirs))
			psize_count:SetText(string.format('%s / %s', DLib.I18n.FormatAnyBytesLong(size), DLib.I18n.FormatAnyBytesLong(total_size)))
			pfiles_count:SizeToContents()
			pdirs_count:SizeToContents()
			psize_count:SizeToContents()
			current_file_label:SetText(file_path)

			if coroutine.status(thread) == 'dead' then
				hook.Remove('Think', id)
				resolve(tree_files, tree_dirs, size)
				window:Close()
			end
		end)
	end)
end

local function move_tree_worker(tree_files, tree_dirs)
	local copied, copied_size = 0, 0
	local dirs = #tree_dirs

	table.sort(tree_dirs, longer_last)

	coroutine.yield(0, 0, 0, '')

	for i, path in ipairs(tree_dirs) do
		file.mkdir(path)
		coroutine.yield(0, i, 0, path)
	end

	local systime = SysTime() + 0.02

	for _from, _to in pairs(tree_files) do
		if file.Exists(_to, 'DATA') then
			copied = copied + 1

			if SysTime() > systime then
				coroutine.yield(copied, dirs, copied_size, path .. ' ALREADY EXISTS')
				systime = SysTime() + 0.02
			end
		else
			if not file.Rename(_from, _to) then
				local open_read = file.Open(_from, 'rb', 'DATA')

				if open_read then
					local open_write = file.Open(_to, 'wb', 'DATA')

					if open_write then
						while open_read:Size() > open_write:Tell() do
							local read = open_read:Read(math.max(open_read:Size() - open_write:Tell(), 0x00020000))
							open_write:Write(read)
							copied_size = copied_size + #read

							open_write:Flush()

							if SysTime() > systime then
								coroutine.yield(copied, dirs, copied_size, _to)
								systime = SysTime() + 0.02
							end
						end

						open_write:Close()
					end

					open_read:Close()
				end
			end

			copied = copied + 1

			if SysTime() > systime then
				coroutine.yield(copied, dirs, copied_size, _to)
				systime = SysTime() + 0.02
			end
		end
	end

	return copied, dirs, copied_size, ''
end

function run_move_tree(tree_files, tree_dirs, total_size)
	local id = 'fm_clone_task' .. SysTime()

	local total_dirs, total_files = #tree_dirs, table.Count(tree_files)

	local window = vgui.Create('DLib_Window')

	window:SetTitle('gui.dlib.filemanager.move.worker.title')
	window:SetSize(400, 200)
	window:Center()

	local bar1 = vgui.Create('EditablePanel', window)
	local bar2 = vgui.Create('EditablePanel', window)
	local bar3 = vgui.Create('EditablePanel', window)
	local bar4 = vgui.Create('EditablePanel', window)
	local current_file_label = vgui.Create('DLabel', window)

	bar1:Dock(TOP)
	bar2:Dock(TOP)
	bar3:Dock(TOP)
	bar4:Dock(TOP)
	current_file_label:Dock(TOP)

	bar1:DockMargin(0, 2, 0, 2, 0)
	bar2:DockMargin(0, 2, 0, 2, 0)
	bar3:DockMargin(0, 2, 0, 2, 0)
	bar4:DockMargin(0, 2, 0, 2, 0)
	current_file_label:DockMargin(0, 5, 0, 5, 0)

	bar1:SetZPos(0)
	bar2:SetZPos(1)
	bar3:SetZPos(2)
	bar4:SetZPos(4)
	current_file_label:SetZPos(3)

	current_file_label:SetText('...')

	local cancel = vgui.Create('DButton', bar4)

	cancel:SetText('gui.misc.cancel')
	-- cancel:SetFont('dlib_fm_status')
	cancel.DoClick = window.Close:Wrap(window)
	cancel:Dock(RIGHT)
	cancel:SizeToContents()
	cancel:SetWide(cancel:GetWide() + 50)

	local pfiles = vgui.Create('DLabel', bar1)
	local pdirs = vgui.Create('DLabel', bar2)
	local psize = vgui.Create('DLabel', bar3)

	local pfiles_count = vgui.Create('DLabel', bar1)
	local pdirs_count = vgui.Create('DLabel', bar2)
	local psize_count = vgui.Create('DLabel', bar3)

	pfiles:SetText('gui.dlib.filemanager.move.worker.files')
	pdirs:SetText('gui.dlib.filemanager.move.worker.dirs')
	psize:SetText('gui.dlib.filemanager.move.worker.size')
	pfiles_count:SetText(string.format('%d / %d', 0, total_files))
	pdirs_count:SetText(string.format('%d / %d', 0, total_dirs))
	psize_count:SetText(string.format('%s / %s', DLib.I18n.FormatAnyBytesLong(0), DLib.I18n.FormatAnyBytesLong(total_size)))

	pfiles:Dock(FILL)
	pfiles_count:Dock(RIGHT)
	pdirs:Dock(FILL)
	pdirs_count:Dock(RIGHT)
	psize:Dock(FILL)
	psize_count:Dock(RIGHT)

	pfiles:DockMargin(10, 0, 0, 0)
	pfiles_count:DockMargin(0, 0, 10, 0)
	pdirs:DockMargin(10, 0, 0, 0)
	pdirs_count:DockMargin(0, 0, 10, 0)
	psize:DockMargin(10, 0, 0, 0)
	psize_count:DockMargin(0, 0, 10, 0)

	local thread = coroutine.create(move_tree_worker)
	local _, files_count, dirs_count, size, file_path = coroutine.resume(thread, tree_files, tree_dirs)

	return DLib.Promise(function(resolve, reject)
		hook.Add('Think', id, function()
			if validity and not IsValid(validity) or not IsValid(window) then
				hook.Remove('Think', id)
				reject('User input')
				return
			end

			_, files_count, dirs_count, size, file_path = coroutine.resume(thread, path_list, tree_files, tree_dirs, status)

			pfiles_count:SetText(string.format('%d / %d', files_count, total_files))
			pdirs_count:SetText(string.format('%d / %d', dirs_count, total_dirs))
			psize_count:SetText(string.format('%s / %s', DLib.I18n.FormatAnyBytesLong(size), DLib.I18n.FormatAnyBytesLong(total_size)))
			pfiles_count:SizeToContents()
			pdirs_count:SizeToContents()
			psize_count:SizeToContents()
			current_file_label:SetText(file_path)

			if coroutine.status(thread) == 'dead' then
				hook.Remove('Think', id)
				resolve(tree_files, tree_dirs, size)
				window:Close()
			end
		end)
	end)
end

function PANEL:RememberPathList(path_list, context, type)
	self.remembered_path_list = assert(path_list, 'path_list')
	self.remembered_path_context = assert(context, 'context')
	assert(type ~= nil, 'type ~= nil')
	self.remembered_path_type = type
	self.paste_button:SetEnabled(true)
end

function PANEL:ForgetPathList()
	if not self.remembered_path_list then return end
	self.remembered_path_list = nil
	self.remembered_path_context = nil
	self.remembered_path_type = nil
	self.paste_button:SetEnabled(false)
end

function PANEL:OnRowRightClick(lines)
	local line = #lines == 1 and lines[1] or false
	local path, path_to_data_dir
	local rooted_path = self:GetRootedPath()
	local rooted_path_to_data_dir = rooted_path

	if self.data_folder ~= 'DATA' then
		rooted_path_to_data_dir = rooted_path_to_data_dir:gsub('^[dD][aA][tT][aA]/', '')
	end

	local menu = DermaMenu()

	if line then
		path = canonizeString(rooted_path .. line:GetValue(1))
		path_to_data_dir = path

		if self.data_folder ~= 'DATA' then
			path_to_data_dir = path_to_data_dir:gsub('^[dD][aA][tT][aA]/', '')
		end

		menu:AddOption('gui.dlib.filemanager.open', function()
			self:DoubleClickLine(line)
		end):SetIcon('icon16/accept.png')

		if line:GetValue(1) ~= '..' then
			menu:AddOption('gui.dlib.filemanager.copy_filename', function()
				SetClipboardText(line:GetValue(1))
			end):SetIcon('icon16/page.png')

			menu:AddOption('gui.dlib.filemanager.copy_path', function()
				SetClipboardText(path)
			end):SetIcon('icon16/page.png')
		end

		menu:AddOption('gui.dlib.filemanager.copy_date', function()
			SetClipboardText(line:GetValue(2))
		end):SetIcon('icon16/page.png')

		if not line.is_folder then
			menu:AddOption('gui.dlib.filemanager.copy_size', function()
				SetClipboardText(line:GetValue(3))
			end):SetIcon('icon16/page.png')
		end
	end

	if self:IsPathWritable(rooted_path) then
		menu:AddSpacer()

		if not line or line:GetValue(1) ~= '..' and self.data_folder == 'DATA' then
			local path_lines, path_lines_writable = {}, {}

			for i, line in ipairs(lines) do
				if line:GetValue(1) ~= '..' then
					path = canonizeString(self:GetRootedPath() .. line:GetValue(1))

					if self.data_folder ~= 'DATA' then
						path = path:gsub('^[dD][aA][tT][aA]/', '')
					end

					if self:IsPathWritable(path) then
						table.insert(path_lines_writable, path)
					end

					table.insert(path_lines, path)
				end
			end

			if #path_lines ~= 0 then
				menu:AddOption('gui.dlib.filemanager.copy.title', function()
					if IsValid(self) then
						self:RememberPathList(path_lines, self:GetRootedPath(), true)
					end
				end):SetIcon('icon16/page_add.png')
			end

			if #path_lines_writable ~= 0 then
				menu:AddOption('gui.dlib.filemanager.cut.title', function()
					if IsValid(self) then
						Derma_Query(
							'gui.dlib.filemanager.cut.description',
							'gui.dlib.filemanager.cut.title',

							'gui.misc.ok',
							function()
								if IsValid(self) then
									self:RememberPathList(path_lines_writable, self:GetRootedPath(), false)
								end
							end,
							'gui.misc.cancel'
						)
					end
				end):SetIcon('icon16/page_go.png')
			end

			if #path_lines_writable ~= 0 or #path_lines ~= 0 then
				menu:AddSpacer()
			end
		end

		if line then
			if line:GetValue(1) ~= '..' then
				menu:AddOption('gui.dlib.filemanager.clone.title', function()
					local initial = line:GetValue(1):lower()
					local _text = initial .. ' - copy'

					if not line.is_folder then
						_text = initial:split('.')
						local ext = table.remove(_text)
						_text = table.concat(_text, '.') .. ' - copy.' .. ext
					end

					local function request()
						Derma_StringRequest(
							'gui.dlib.filemanager.clone.title',
							'gui.dlib.filemanager.clone.description',
							_text,
							function(text)
								text = text:lower()
								_text = text

								if text:find('"', 1, true) or text:find(':', 1, true) or text:find('/', 1, true) or text == '.' or text == '' or text == '..' or #text >= 253 or file.Exists(rooted_path .. text, self.data_folder) then
									Derma_Query(
										'gui.dlib.filemanager.clone.error.description',
										'gui.dlib.filemanager.clone.error.title',

										'gui.misc.ok',
										request,
										'gui.misc.cancel'
									)

									return
								end

								if not line.is_folder and not isExtensionWritable(_text) then
									Derma_Query(
										'gui.dlib.filemanager.clone.error.description',
										'gui.dlib.filemanager.clone.error.title',

										'gui.misc.ok',
										request,
										'gui.misc.cancel'
									)

									return
								end

								run_scanner({path_to_data_dir}, self):Then(function(tree_files, tree_dirs, size)
									local _tree_files, _tree_dirs = {}, {}

									if line.is_folder then
										local replace_with = text .. '/'

										for i, _line in ipairs(tree_files) do
											_tree_files[_line] = _line:lower():gsub('^(.-)/', replace_with)
										end

										for i, _line in ipairs(tree_dirs) do
											_line = _line:lower()

											if _line == initial then
												table.insert(_tree_dirs, text)
											else
												local value = _line:gsub('^(.-)/', replace_with)
												table.insert(_tree_dirs, value)
											end
										end
									else
										_tree_files[path_to_data_dir] = rooted_path_to_data_dir .. text
									end

									run_clone_tree(_tree_files, _tree_dirs, size):Then(function()
										if IsValid(self) then
											self:ScanCurrentDirectory()
											self:RebuildFileList()
										end
									end):Catch(function()
										if IsValid(self) then
											self:ScanCurrentDirectory()
											self:RebuildFileList()
										end
									end)
								end)
							end,
							nil,
							'gui.misc.ok',
							'gui.misc.cancel'
						)
					end

					request()
				end):SetIcon('icon16/page.png')
			end

			menu:AddOption('gui.dlib.filemanager.make_folder.title', function()
				self:MakeFolder(rooted_path, rooted_path_to_data_dir)
			end):SetIcon('icon16/folder_add.png')
		end

		if not line or line:GetValue(1) ~= '..' then
			local sub, button = menu:AddSubMenu('gui.dlib.filemanager.delete')
			button:SetIcon('icon16/delete.png')

			sub:AddOption('gui.dlib.filemanager.delete', function()
				local path_lines = {}

				for i, line in ipairs(lines) do
					if line:GetValue(1) ~= '..' then
						path = canonizeString(self:GetRootedPath() .. line:GetValue(1))

						if self.data_folder ~= 'DATA' then
							path = path:gsub('^[dD][aA][tT][aA]/', '')
						end

						table.insert(path_lines, path)
					end
				end

				if #path_lines == 0 then return end

				run_scanner(path_lines, self):Then(function(tree_files, tree_dirs, size)
					Derma_Query(
						DLib.I18n.Localize('gui.dlib.filemanager.delete_confirm.description', #tree_files, DLib.I18n.FormatAnyBytesLong(size)),
						'gui.dlib.filemanager.delete_confirm.title',

						'gui.misc.confirm',
						function()
							delete_tree(tree_files, tree_dirs):Then(function()
								if IsValid(self) then
									self:ScanCurrentDirectory()
									self:RebuildFileList()
								end
							end):Catch(function()
								if IsValid(self) then
									self:ScanCurrentDirectory()
									self:RebuildFileList()
								end
							end)
						end,
						'gui.misc.cancel'
					)
				end)
			end):SetIcon('icon16/delete.png')
		end
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
			self:DoCallSelectFile(new_path)
		else
			if notify then
				Derma_Message('gui.dlib.filemanager.not_exists.description', 'gui.dlib.filemanager.not_exists.title', 'gui.misc.ok')
			end

			return false
		end
	elseif self.file_mode == self.MODE_READ_WRITE then
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

			self:DoCallSelectFile(new_path)
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
				self:OpenOverwriteModal(new_path, filename)
			else
				self:DoCallSelectFile(new_path)
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
		self:DoCallSelectFile(new_path)
	elseif self.file_mode == self.MODE_READ_WRITE then
		if not isExtensionWritable(new_path) then
			Derma_Message('gui.dlib.filemanager.not_writable_ext.description', 'gui.dlib.filemanager.not_writable_ext.title', 'gui.misc.ok')
		elseif self:IsPathWritable(new_path) then
			self:DoCallSelectFile(new_path)
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
		function() if IsValid(self) then self:DoCallSelectFile(path) end end,
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

	self.new_folder_button:SetEnabled(self:IsPathWritable(self.current_path_str))

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

	self.new_folder_button:SetEnabled(self:IsPathWritable(self.current_path_str))

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
					local count = file.Size(root .. name, self.data_folder)

					if count then
						self.row_tasks[i]:SetValue(3, DLib.I18n.FormatAnyBytes(count))
					else
						self.row_tasks[i]:SetValue(3, 'gui.dlib.filemanager.error')
					end
				end

				local time = file.Time(canonizeString(root .. name), self.data_folder)

				if time then
					self.row_tasks[i]:SetValue(2, DLib.string.qdate(time, true))
				else
					self.row_tasks[i]:SetValue(2, 'gui.dlib.filemanager.error')
				end

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

	if IsValid(self.folder_contents.VBar) then
		self.folder_contents.VBar:SetScroll(0)
	end

	self.row_tasks = {}
	self.row_tasks_ptr = 1

	local search = self.quick_search:RealGetValue():lower()

	if search == '' then
		for i, data in ipairs(self._file_list) do
			if data[2] then
				self.row_tasks[i] = self.folder_contents:AddLine(data[1], '???', 'gui.dlib.filemanager.folder')
				self.row_tasks[i].is_folder = true
			else
				self.row_tasks[i] = self.folder_contents:AddLine(data[1], '???', '???')
				self.row_tasks[i].is_folder = false
			end
		end
	else
		for i, data in ipairs(self._file_list) do
			if data[1]:lower():find(search, 1, true) or data[1] == '..' then
				local makerow

				if data[2] then
					makerow = self.folder_contents:AddLine(data[1], '???', 'gui.dlib.filemanager.folder')
				else
					makerow = self.folder_contents:AddLine(data[1], '???', '???')
				end

				makerow.is_folder = data[2]
				table.insert(self.row_tasks, makerow)
			end
		end
	end
end

local function search_node_tree(self)
	local search_tree = self.folder_tree:Root():GetChildNodes()
	local valid = true

	while valid and search_tree and #search_tree > 0 do
		valid = false

		for i, node in ipairs(search_tree) do
			local getpath = node:GetFolder()

			if getpath == self.current_path_str then
				self.folder_tree._ignore = true
				node:InternalDoClick()
				node:SetExpanded(true)
				self.folder_tree:ScrollToChild(node)
				self.folder_tree._ignore = false
				break
			elseif self.current_path_str:startsWith(getpath .. '/') then
				node:PopulateChildrenAndSelf()
				search_tree = node:GetChildNodes()
				node:SetExpanded(true)
				valid = true
				break
			end
		end
	end
end

function PANEL:ScanCurrentDirectory()
	--local delay = false

	if not self.folder_tree._populated then
		--delay = true
		self.folder_tree._populated = true

		for i, dir in ipairs(select(2, file.Find('*', self.data_folder))) do
			local node = self.folder_tree:AddNode(dir)
			node:MakeFolder(dir, self.data_folder)
		end
	end

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

	if self.folder_tree._ignore then return end

	search_node_tree(self)
end

DLib.FileManagerPanel = PANEL
vgui.Register('DLib_FileManager', PANEL, 'DLib_Window')

