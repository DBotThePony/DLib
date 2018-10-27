
--[[
Copyright (C) 2016-2018 DBot

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

--[==[
If you are there, that means you want to know what is this.
This is VLL - Virtual Lua Loader
It downloads a bundle and simulates running lua code.

Load VLL
lua_run http.Fetch("https://dbot.serealia.ca/vll/vll.lua",function(b)RunString(b,"VLL")end)
rcon lua_run "http.Fetch([[https:]]..string.char(47)..[[/dbot.serealia.ca/vll/vll.lua]],function(b)RunString(b,[[VLL]])end)"
http.Fetch('https://dbot.serealia.ca/vll/vll.lua',function(b)RunString(b,'VLL')end)
ulx luarun "http.Fetch('https://dbot.serealia.ca/vll/vll.lua',function(b)RunString(b,'VLL')end)"
]==]

if SERVER then
	util.AddNetworkString('VLL.Load')
	util.AddNetworkString('VLL.LoadGMA')
	util.AddNetworkString('VLL.LoadGMAAs')
	util.AddNetworkString('VLL.Require')
	util.AddNetworkString('VLL.Message')
	util.AddNetworkString('VLL.LoadWorkshop')
	util.AddNetworkString('VLL.Admin')
end

file.CreateDir('vll')
file.CreateDir('vll/bundlecache')

VLL = VLL or {}
VLL.FILE_MEMORY = VLL.FILE_MEMORY or {}
VLL.DIRECTORY_MEMORY = VLL.DIRECTORY_MEMORY or {}
VLL.COMPILED_MEMORY = VLL.COMPILED_MEMORY or {}
VLL.BUNDLE_STATUS = VLL.BUNDLE_STATUS or {}
VLL.REPLICATED_GMA = VLL.REPLICATED_GMA or {}
VLL.REPLICATED_GMAAS = VLL.REPLICATED_GMAAS or {}
VLL.REPLICATED_WORK = VLL.REPLICATED_WORK or {}
VLL.REPLICATED = VLL.REPLICATED or {}
VLL.BUNDLE_DATA = VLL.BUNDLE_DATA or {}
VLL.HOOKS = VLL.HOOKS or {}
VLL.SPAWNLISTS = VLL.SPAWNLISTS or {}
VLL.PROVIDED_SPAWNLISTS = VLL.PROVIDED_SPAWNLISTS or {}
VLL.PSPAWNLISTS = VLL.PSPAWNLISTS or {}
VLL.WSADDONS = VLL.WSADDONS or {}
VLL.HOOKS_POST = {}

VLL.CMOUNTING = VLL.CMOUNTING or 0
VLL.WDOWNLOADING = VLL.WDOWNLOADING or 0
VLL.WINFO = VLL.WINFO or 0
VLL.CMOUNTING_GMA = VLL.CMOUNTING_GMA or {}

VLL.UNLOADED = 0
VLL.LOADING_IN_PROCESS = 1
VLL.LOADED = 2
VLL.RUNNING = 3

VLL.PACK_SEPERATOR = '----______VLL_PACK_FILE_SEPERATOR______----'

VLL.SPAWNLIST = 3100
VLL.SPAWNLIST_NEXT = 3101
VLL.TOPLIST = {
	id = VLL.SPAWNLIST,
	icon = 'icon16/folder.png',
	parentid = 0,
	name = 'VLL Mounted GMA\'s',
	version = 3,
	contents = {
		{
			type = 'header',
			text = 'All VLL mounted GMA\'s.',
		},{
			type = 'header',
			text = 'spawnlists is under this category',
		},{
			type = 'header',
			text = 'Please note that there can be',
		},{
			type = 'header',
			text = 'models that crashes gmod!',
		},
	}
}

VLL.URL = 'https://dbot.serealia.ca/vll/'

function VLL.EMPTY_FUNCTION() end

VLL.DOWNLOADING = VLL.DOWNLOADING or {}

local function Remove(name)
	local i

	for k, v in ipairs(VLL.DOWNLOADING) do
		if v == name then i = k break end
	end

	if i then
		table.remove(VLL.DOWNLOADING, i)
	end
end

local GMAWait = 0
local mountingAll = false

local function ContinueMountGMA(path, listname, nolist, loadLua, bundle)
	VLL.Message('Mounting ' .. path)
	local time = SysTime()
	local status, models = game.MountGMA(path)
	local newTime = (SysTime() - time) * 1000
	models = models or {}

	if newTime < 500 and not mountingAll then
		mountingAll = true
		RunConsoleCommand('vll_mountall')
		mountingAll = false
	end

	bundle = bundle or path

	GMAWait = CurTime() + 3

	if loadLua then
		local targets = {}

		for i, fileString in ipairs(models) do
			if fileString:sub(1, 3) == 'lua' then
				local filenameTrim = fileString:sub(5)
				table.insert(targets, filenameTrim)
			end
		end

		VLL.BUNDLE_STATUS[bundle] = VLL.RUNNING
		VLL.BUNDLE_DATA[bundle] = {
			total = #targets,
			done = 0,
			started = CurTime(),
			status = '0',
		}

		for i, fileString in ipairs(targets) do
			VLL.SaveFile(fileString, file.Read(fileString, 'LUA'), bundle)
		end

		VLL.RunBundle(bundle)
	end

	if not CLIENT then return end

	if not (status and models) then return end
	local new = {}

	for k, v in ipairs(models) do
		if v:find('.mdl') then
			table.insert(new, v)
		end
	end

	VLL.SPAWNLISTS[listname or path] = new

	if nolist or #new == 0 then return end

	VLL.PSPAWNLISTS[listname or path] = {}

	local self = VLL.PSPAWNLISTS[listname or path]
	self.parentid = VLL.SPAWNLIST
	self.icon = 'icon16/page.png'

	self.id = VLL.SPAWNLIST_NEXT
	VLL.SPAWNLIST_NEXT = VLL.SPAWNLIST_NEXT + 1

	self.contents = {'reserved', 'reserved'}

	for k, model in ipairs(new) do
		table.insert(self.contents, {
			type = 'model',
			model = model,
		})
	end

	self.total = #self.contents - 2
	self.name = ('%s (%s)'):format(listname or path, self.total)

	self.contents[1] = {
		type = 'header',
		text = listname
	}

	self.contents[2] = {
		type = 'header',
		text = 'Total models in that category: ' .. self.total
	}
end

timer.Create('VLL.MountQueue', 1, 0, function()
	if #VLL.CMOUNTING_GMA == 0 then return end
	if GMAWait > CurTime() then return end
	local val = table.remove(VLL.CMOUNTING_GMA)
	ContinueMountGMA(unpack(val))
end)

local function MountGMA(path, listname, nolist, loadLua, bundle)
	for k, v in ipairs(VLL.CMOUNTING_GMA) do
		if v[1] == path then return end
	end

	VLL.Message('Adding GMA ' .. path .. ' to mount queue')

	table.insert(VLL.CMOUNTING_GMA, {path, listname, nolist, loadLua, bundle})
end

function VLL.LoadGMA(path, noreplicate)
	VLL.LoadGMAAs(VLL.URL .. path .. '.gma', path, noreplicate)
end

local function Reffer()
	return (SERVER and '(SERVER) ' or '(CLIENT) ') .. string.Explode(':', game.GetIPAddress())[1] .. '/' .. GetHostName()
end

function VLL.LoadGMAAs(URL, path, noreplicate)
	if not noreplicate then
		VLL.REPLICATED_GMAAS[path] = URL
	end

	if table.HasValue(VLL.DOWNLOADING, path) then return end
	VLL.Message('GMA file ' .. path .. ' was required.')

	local INDEX = table.insert(VLL.DOWNLOADING, path)

	if not file.Exists('vll/' .. path .. '.gma.txt', 'DATA') then
		VLL.Message('Downloading ' .. path)

		local req = {}
		local oreq = req
		req.method = 'get'
		req.url = URL .. '.z'

		req.headers = {
			Referer = Reffer(),
		}

		req.success = function(code, body, headers)
			if code ~= 200 then
				VLL.Message('No compressed ' .. path .. '. Trying to download uncompressed file')

				local req = {}
				req.method = 'get'
				req.url = URL

				req.success = function(code, body, headers)
					if code ~= 200 then
						VLL.Message('Failed to download ' .. path .. '!')
						Remove(path)
						return
					end

					file.Write('vll/' .. path .. '.gma.txt', body)
					MountGMA('data/vll/' .. path .. '.gma.txt', path)

					Remove(path)
				end

				req.failed = oreq.failed

				HTTP(req)

				return
			end

			local uncompress = util.Decompress(body)
			VLL.Message('Unpacking ' .. path)
			file.Write('vll/' .. path .. '.gma.txt', uncompress)
			MountGMA('data/vll/' .. path .. '.gma.txt', path)

			Remove(path)
		end

		req.failed = function(reason)
			VLL.Message('ATTENTION! Failed to download ' .. path .. ': ', reason)
			Remove(path)
		end

		HTTP(req)
	else
		MountGMA('data/vll/' .. path .. '.gma.txt', path)
		Remove(path)
	end
end

function VLL.LoadGMAWS(URL, path, loadLua, bundle)
	VLL.WSADDONS[path] = URL

	local targetfolder = string.GetPathFromFilename('vll/' .. path)

	if not file.Exists(targetfolder, 'DATA') then
		file.CreateDir(targetfolder)
	end

	if table.HasValue(VLL.DOWNLOADING, path) then return end
	VLL.Message('[WS] GMA file ' .. path .. ' (' .. bundle .. ') was requested.')

	local INDEX = table.insert(VLL.DOWNLOADING, path)

	if file.Exists('vll/' .. path .. '.dat', 'DATA') then
		MountGMA('data/vll/' .. path .. '.dat', path, loadLua, bundle)
		Remove(path)
		return
	end

	VLL.Message('[WS] Downloading ' .. path .. ' (' .. bundle .. ')')

	local req = {}
	local oreq = req
	req.method = 'get'
	req.url = URL

	req.success = function(code, body, headers)
		local uncompress = util.Decompress(body)
		VLL.Message('[WS] Unpacking ' .. path)
		file.Write('vll/' .. path .. '.dat', uncompress)
		MountGMA('data/vll/' .. path .. '.dat', path, loadLua, bundle)

		Remove(path)
	end

	req.failed = function(reason)
		VLL.Message('[WS] ATTENTION! Failed to download ' .. path .. ' (' .. bundle .. '): ', reason)
		Remove(path)
	end

	HTTP(req)
end

function VLL.LoadWorkshopSV(id, noreplicate, loadLua)
	if not id then return false end

	if loadLua == nil then
		loadLua = false
	end

	if CLIENT then
		VLL.LoadWorkshop(id, false, loadLua, noreplicate)
		return
	end

	if not noreplicate then
		VLL.REPLICATED_WORK[tostring(id)] = id

		net.Start('VLL.LoadWorkshop')
		net.WriteString(tostring(id))
		net.WriteBool(loadLua)
		net.Broadcast()
	end

	local function success(responseText, contentLength, responseHeaders, statusCode)
		if statusCode ~= 200 then VLL.AdminMessage("Unknown error occured (status code " .. statusCode .. ")") return end

		local tbl = util.JSONToTable(responseText)

		if tbl.response and tbl.response.publishedfiledetails then
			for _,item in ipairs(tbl.response.publishedfiledetails) do
				if VLL.IsWSAddonMounted(item.publishedfileid) then
					VLL.AdminMessage("[WS] Addon " .. item.title .. " is mounted already.")
					goto CONTINUE
				end

				VLL.LoadGMAWS(item.file_url, item.filename, loadLua, id)
				VLL.AdminMessage("[WS] Added " .. item.title .. " to the workshop download queue.")

				::CONTINUE::
			end
		end
	end

	local function failure(errorMessage)
		VLL.AdminMessage("[WS] Unknown error occured: " .. errorMessage)
	end

	local postFields = {itemcount = "1", ["publishedfileids[0]"] = tostring(id)}

	http.Post("https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", postFields, success, failure)
end

function VLL.Unreplicate(bundle)
	VLL.REPLICATED[bundle] = nil
end

file.CreateDir('vll/wcache')

function VLL.LoadWorkshop(id, nolist, loadLua, noreplicate)
	VLL.Message('Trying to download workshop addon ' .. id .. '.')

	if not noreplicate then
		VLL.REPLICATED_WORK[tostring(id)] = id
	end

	--nuh
	if SERVER then
		VLL.LoadWorkshopSV(id, noreplicate, loadLua)
		return
	end

	if steamworks.IsSubscribed(tostring(id)) and not loadLua then
		VLL.Message('Not downloading addon ' .. id .. ' since it is already mounted on client.')
		return
	end

	VLL.WDOWNLOADING = VLL.WDOWNLOADING + 1
	VLL.WINFO = VLL.WINFO + 1

	steamworks.FileInfo(id, function(data)
		if not data then
			VLL.Message('Unknown error from steamworks, occured, check message above. (' .. id .. ')')
			VLL.WINFO = VLL.WINFO - 1
			VLL.WDOWNLOADING = VLL.WDOWNLOADING - 1
			return
		end

		VLL.Message('GOT FILE INFO FOR ' .. id .. ' (' .. data.title .. ')!')

		VLL.WINFO = VLL.WINFO - 1

		local path = 'cache/workshop/' .. data.fileid .. '.cache'

		if file.Exists(path, 'GAME') then
			VLL.Message('Mounting ' .. id .. ' (' .. data.title .. ') as ' .. path)
			MountGMA(path, data.title, nolist, loadLua, id)
			VLL.WDOWNLOADING = VLL.WDOWNLOADING - 1
		else
			VLL.Message('Downloading ' .. id .. ' (' .. data.title .. ')')
			steamworks.Download(data.fileid, true, function(path2)
				VLL.WDOWNLOADING = VLL.WDOWNLOADING - 1
				VLL.Message('Mounting ' .. id .. ' (' .. data.title .. ') as ' .. (path2 or path))
				MountGMA(path2 or path, data.title, nolist, loadLua, id)
			end)
		end
	end)
end

function VLL.ParseContent(contents)
	local split = string.Explode(VLL.PACK_SEPERATOR, contents)

	if #split == 0 then
		return false
	end

	table.remove(split)

	return split
end

function VLL.SetupFiles(contents, bundle)
	local parsed = VLL.ParseContent(contents)

	if not parsed then
		VLL.Message('No such bundle - ' .. bundle)
		return
	end

	VLL.BUNDLE_STATUS[bundle] = VLL.RUNNING
	VLL.BUNDLE_DATA[bundle] = {
		total = #parsed / 2,
		done = 0,
		started = CurTime(),
		status = '0',
	}

	for i = 1, #parsed, 2 do
		local FILE = parsed[i]
		local body = parsed[i + 1]
		local code = 200
		if body then
			VLL.SaveFile(FILE, body, bundle)
		end
	end
end

function VLL.LoadBundle(contents, bundle)
	if contents == 'Hack' then
		VLL.Message('Hack')
		return
	end

	if contents == 'No bundle!' then
		VLL.Message('No bundle!')
		return
	end

	if contents == '' then
		VLL.Message('No bundle!')
		return
	end

	file.Write('vll/bundlecache/' .. util.CRC(bundle) .. '.dat', util.Compress(contents))
	VLL.PurgeBundle(bundle)
	VLL.SetupFiles(contents, bundle)
	VLL.RunBundle(bundle)
end

function VLL.LoadCached(bundle)
	local contents = util.Decompress(file.Read('vll/bundlecache/' .. util.CRC(bundle) .. '.dat', 'DATA'))
	if not contents or contents == '' then
		VLL.Message('No specified bundle found on the disk')
		return
	end

	VLL.PurgeBundle(bundle)
	VLL.SetupFiles(contents, bundle)
	VLL.RunBundle(bundle)
end

function VLL.LoadFromURL(url, bundle)
	VLL.Message('Loading bundle ' .. bundle)

	local req = {}

	req.method = 'get'
	req.url = url

	req.headers = {
		Referer = Reffer(),
	}

	function req.failed(reason)
		VLL.Message('ATTENTION: Failed to load bundle - ' .. bundle .. ': ' .. reason)
	end

	function req.success(code, body, headers)
		VLL.LoadBundle(body, bundle)
	end

	HTTP(req)
end

function VLL.Load(bundle, silent, noreplicate)
	local URL = VLL.URL .. 'get_pack.php?bundle=' .. bundle
	VLL.LoadFromURL(URL, bundle)

	if not noreplicate then
		VLL.REPLICATED[bundle] = true
	end

	if SERVER and not silent then
		net.Start('VLL.Load')
		net.WriteString(bundle)
		net.Broadcast()
	end
end

VLL.LoadPack = VLL.Load

function VLL.ReadFile(path)
	path = string.lower(path)
	if not VLL.FILE_MEMORY[path] then return '' end
	return VLL.FILE_MEMORY[path].content
end

function VLL.FileBundle(path)
	path = string.lower(path)
	if not VLL.FILE_MEMORY[path] then return '' end
	return VLL.FILE_MEMORY[path].bundle
end

function VLL.IsWSAddonMounted(wsid)
	if not wsid then return false end

	for i, addon in ipairs(engine.GetAddons()) do
		if addon.mounted and addon.wsid == wsid then
			return true
		end
	end

	return false
end

function VLL.FixFilePath(path)
	local split = string.Explode('/', path)

	local currentIndex = 1
	local newSplit = {}

	for k, v in ipairs(split) do
		if v == '..' then
			currentIndex = currentIndex - 1
			if currentIndex <= 0 then
				VLL.Message(VLL.WARN_COLOR, 'Failed to fix next path: ', VLL.DEFAULT_COLOR, path, VLL.WARN_COLOR, ' Is it valid?')
				return path
			end
		elseif v == '..' then
			currentIndex = currentIndex
		else
			newSplit[currentIndex] = v
			currentIndex = currentIndex + 1
		end
	end

	return table.concat(newSplit, '/')
end

function VLL.PurgeBundle(bundle)
	for k, v in pairs(VLL.FILE_MEMORY) do
		if v.bundle == bundle then
			VLL.FILE_MEMORY[k] = nil
		end
	end
end

function VLL.__compileString(str, err, handle)
	local env = getfenv(2)
	local func = CompileString(str, err, handle)

	if isfunction(func) then
		setfenv(func, env)
	end

	return func
end

function VLL.__runString(str, identifier, handle)
	return VLL.__compileString(str, identifier or 'RunString', handle)()
end

function VLL.__realRequire(str)
	str = str:lower()
	if VLL.IsMyFile('includes/modules/' .. str .. '.lua') then
		return VLL.Include('includes/modules/' .. str .. '.lua')
	else
		return require(str)
	end
end

local eventsToRun = {
	'PostGamemodeLoaded',
	'OnGamemodeLoaded',
	'Initialize',
	'InitPostEntity'
}

function VLL.__addHook(event, id, func, priority)
	local bundle = getfenv(2).VLL_BUNDLE

	hook.Add(event, id, func, priority)

	if not bundle then return end

	VLL.HOOKS_POST[bundle] = VLL.HOOKS_POST[bundle] or {}
	local hooks = VLL.HOOKS_POST[bundle]

	for i, toCall in ipairs(eventsToRun) do
		if toCall == event then
			hooks[id] = func
			break
		end
	end

	if event == 'PlayerInitialSpawn' then
		hooks['__vll_fixplayers_' .. tostring(id)] = function()
			for i, ply in ipairs(player.GetAll()) do
				func(ply)
			end
		end
	end

	if event == 'PlayerSpawn' then
		hooks['__vll_fixplayers2_' .. tostring(id)] = function()
			for i, ply in ipairs(player.GetAll()) do
				func(ply)
			end
		end
	end

	VLL.HOOKS[bundle] = VLL.HOOKS[bundle] or {}
	VLL.HOOKS[bundle][event] = VLL.HOOKS[bundle][event] or {}
	VLL.HOOKS[bundle][event][id] = {func = func, priority = priority}
end

function VLL.UnloadHooks(bundle)
	VLL.HOOKS[bundle] = VLL.HOOKS[bundle] or {}

	for event, data in pairs(VLL.HOOKS[bundle]) do
		for id, Data in pairs(data) do
			hook.Remove(event, id)
		end
	end
end

function VLL.DirectoryContent(path)
	local len = #path
	local reply = {}
	local reply2 = {}
	local reply3 = {}

	for k, v in pairs(VLL.FILE_MEMORY) do
		local sub = string.sub(k, 1, len)
		if sub == path then
			if string.sub(k, len + 1, len + 1) ~= '.' then
				local subnext = string.sub(k, len + 2)

				if not string.find(subnext, '/') then
					table.insert(reply, subnext)
				else
					local dir = string.Explode('/', subnext)[1]
					reply2[dir] = dir
				end
			end
		end
	end

	for k, v in pairs(reply2) do
		table.insert(reply3, k)
	end

	return reply, reply3
end

function VLL.DirectoryFolders(path)
	local len = #path
	local reply = {}
	local reply2 = {}

	for k, v in pairs(VLL.FILE_MEMORY) do
		local sub = string.sub(k, 1, len)
		if sub ~= path then goto CONTINUE end
		local subnext = string.sub(k, len + 2)
		if not string.find(subnext, '/') then goto CONTINUE end
		local dir = string.Explode('/', subnext)[1]
		reply2[dir] = dir

		::CONTINUE::
	end

	for k, v in pairs(reply2) do
		table.insert(reply, k)
	end

	return reply
end

function VLL.StringLine(str, line)
	local split = string.Explode('\n', str)

	return split[line]
end

function VLL.__FileExists(File, Dir)
	if Dir ~= 'LUA' then return file.Exists(File, Dir) end
	return VLL.FileExists(File) or file.Exists(File, 'LUA')
end

function VLL.HasValue(tab, val)
	for k, v in ipairs(tab) do
		if v == val then return true end
	end

	return false
end

function VLL.__FileFind(File, Dir)
	if Dir ~= 'LUA' then return file.Find(File, Dir) end
	local split = string.Explode('/', File)
	local lastToken = split[#split]

	local one, dirs = VLL.DirectoryContent(table.concat(split, '/', 1, #split - 1))
	local two, tdirs = file.Find(File, Dir)

	local reply = {}
	local replyDirs = {}

	for k, v in ipairs(one) do
		if not VLL.HasValue(reply, v) then
			table.insert(reply, v)
		end
	end

	for k, v in ipairs(two) do
		if not VLL.HasValue(reply, v) then
			table.insert(reply, v)
		end
	end

	for k, v in ipairs(dirs) do
		if not VLL.HasValue(replyDirs, v) then
			table.insert(replyDirs, v)
		end
	end

	for k, v in ipairs(tdirs) do
		if not VLL.HasValue(replyDirs, v) then
			table.insert(replyDirs, v)
		end
	end

	if lastToken == '*' then
		return reply, replyDirs
	else
		local newToken = lastToken:gsub('%.', '%%%.'):gsub('%*', '.*')

		local newReply, newReplyDirs = {}, {}

		for k, v in ipairs(reply) do
			if not VLL.HasValue(newReply, v) and v:find(newToken) then
				table.insert(newReply, v)
			end
		end

		for k, v in ipairs(replyDirs) do
			if not VLL.HasValue(newReplyDirs, v) and v:find(newToken) then
				table.insert(newReplyDirs, v)
			end
		end

		return newReply, newReplyDirs
	end

	return {}, {} -- ???
end

function VLL.IsDir(Path, Dir)
	if Dir ~= 'LUA' then return file.IsDir(Path, Dir) end

	if VLL.DIRECTORY_MEMORY[Path] then return true end
	return file.IsDir(Path, Dir)
end

function VLL.FileRead(File, Dir)
	if Dir ~= 'LUA' then return file.Read(File, Dir) end

	if not VLL.IsMyFile(File) then return file.Read(File, Dir) end

	return VLL.ReadFile(File)
end

function VLL.ErrorHandlerLua(err, level)
	level = level or 1
	level = level + 1
	VLL.ErrorHandler(err, level)
	error(err, level)
end

function VLL.ErrorHandler(err)
	local trace = debug.traceback()

	if SERVER then
		VLL.AdminMessage(Color(200, 50, 50), 'SERVERSIDE LUA ERROR: ' .. (err or ''))
		VLL.AdminMessage(Color(255, 255, 255), trace)
	else
		VLL.Message(Color(200, 50, 50), 'LUA ERROR: ' .. (err or ''))
		VLL.Message(Color(255, 255, 255), trace)
	end
end

function VLL.ErrorHandlerSilent(err)
	if SERVER then
		VLL.AdminMessage(Color(200, 50, 50), 'SERVERSIDE LUA ERROR')
		VLL.AdminMessage(Color(255, 255, 255), err)
	else
		VLL.Message(Color(200, 50, 50), 'LUA ERROR')
		VLL.Message(Color(255, 255, 255), err)
	end

	Error('')
end

function VLL.ErrorHandlerSilentNoHalt(err)
	if SERVER then
		VLL.AdminMessage(Color(200, 50, 50), 'SERVERSIDE LUA ERROR')
		VLL.AdminMessage(Color(255, 255, 255), err)
	else
		VLL.Message(Color(200, 50, 50), 'LUA ERROR')
		VLL.Message(Color(255, 255, 255), err)
	end

	if VLL.IS_TESTING then
		VLL.Message('[..FAIL..] ', err)
		VLL.Message(debug.traceback())
	end
end

VLL.EMPTY_FUNCTION = function() end
VLL.ERROR_COLOR = Color(255, 100, 100)
VLL.DEFAULT_COLOR = Color(200, 200, 200)
VLL.WARN_COLOR = Color(255, 255, 0)

function VLL.Include(path)
	path = path:lower()
	local sayFunc = VLL.SILENT_INCLUDE and VLL.EMPTY_FUNCTION or VLL.Message
	local env = getfenv(2)
	local dir = env.VLL_CURR_DIR

	if not path and dir then VLL.Message(Color(255, 0, 0), 'File being loaded without path. Directory: ' .. dir) return end

	local path2

	if dir then
		path2 = VLL.FixFilePath(dir .. '/' .. path)
	end

	path = VLL.FixFilePath(path)
	local Exists1 = VLL.IsMyFile(path)
	local Exists2

	if path2 then
		Exists2 = VLL.IsMyFile(path2)
	end

	local fpath = Exists1 and path or Exists2 and path2

	if not fpath then
		local ErrMessage = ''
		local function ErrorHandler(err)
			ErrMessage = err

			if VLL.IS_TESTING then
				VLL.Message(VLL.ERROR_COLOR, '[..FAIL..] ERROR! ', VLL.DEFAULT_COLOR, err)
			else
				VLL.Message(VLL.ERROR_COLOR, 'ERROR! ', VLL.DEFAULT_COLOR, err)
			end

			VLL.Message(debug.traceback())
		end

		local reply = {}
		local actualFile = ''

		if path2 and VLL.__FileExists(path2, 'LUA') then
			reply = {xpcall(VLL.Compile(path2), ErrorHandler)}
			actualFile = path2
		elseif VLL.__FileExists(path, 'LUA') then
			reply = {xpcall(VLL.Compile(path), ErrorHandler)}
			actualFile = path
		else
			if not VLL.IS_TESTING then
				VLL.AdminMessage(VLL.WARN_COLOR, 'Tried to load non-exist file: ' .. (path2 or '<undefined>') .. ' || ' .. (path or '<undefined>'))
			else
				VLL.AdminMessage(VLL.WARN_COLOR, '[..WARN..] Tried to load non-exist file: ' .. (path2 or '<undefined>') .. ' || ' .. (path or '<undefined>'))
			end
		end

		if VLL.IS_TESTING then
			if reply[1] then
				sayFunc('[.. OK ..] Compiled and runned file     : ' .. actualFile)
			else
				if not actualFile or actualFile == '' then
					sayFunc(VLL.WARN_COLOR, '[..WARN..] Internal error on building virtual lua path')
				else
					sayFunc(VLL.ERROR_COLOR, '[..FAIL..] File filed to compile/execute: ' .. actualFile .. ' || ', VLL.DEFAULT_COLOR, ErrMessage)
				end
			end
		else
			sayFunc('Running File: ' .. actualFile)
		end

		return unpack(reply, 2)
	end

	--Catch em all

	if not VLL.IS_TESTING then
		sayFunc('Running File: ' .. fpath)
		local reply = {xpcall(VLL.Compile(fpath), VLL.ErrorHandler)}
		return unpack(reply, 2)
	else
		local ErrMessage = ''
		local function ErrorHandler(err)
			ErrMessage = err

			if VLL.IS_TESTING then
				VLL.Message(VLL.ERROR_COLOR, '[..FAIL..] ERROR! ', VLL.DEFAULT_COLOR, err)
			else
				VLL.Message(VLL.ERROR_COLOR, 'ERROR! ', VLL.DEFAULT_COLOR, err)
			end

			VLL.Message(debug.traceback())
		end

		local reply = {xpcall(VLL.Compile(fpath), ErrorHandler)}

		if reply[1] then
			sayFunc('[.. OK ..] Compiled and runned file     : ' .. fpath)
		else
			sayFunc(VLL.ERROR_COLOR, '[..FAIL..] File filed to compile/execute: ' .. fpath .. ' || ', VLL.DEFAULT_COLOR, ErrMessage)
		end

		return unpack(reply, 2)
	end
end

VLL.REQUIRE_CACHE = VLL.REQUIRE_CACHE or {}

function VLL.Require(File)
	File = File:lower()
	if VLL.REQUIRE_CACHE[File] ~= nil then
		return unpack(VLL.REQUIRE_CACHE[File].data)
	else
		VLL.REQUIRE_CACHE[File] = {
			data = {VLL.Include(File)},
			time = RealTime()
		}

		return unpack(VLL.REQUIRE_CACHE[File].data)
	end
end

function VLL.CSLua(File)
	if not File then return end
	File = File:lower()
	local env = getfenv(2)
	local path = env.VLL_CURR_DIR
	if VLL.IsMyFile(File) or (path and VLL.IsMyFile(path .. '/' .. File)) then return end

	if file.Exists(File, 'LUA') then
		AddCSLuaFile(File)
	elseif path and file.Exists(path .. '/' .. File, 'LUA') then
		AddCSLuaFile(path .. '/' .. File)
	else
		if not VLL.IS_TESTING then
			VLL.Message(VLL.WARN_COLOR, 'AddCSLuaFile() - Failed to find specified file - ' .. File)
		else
			VLL.Message(VLL.WARN_COLOR, '[..WARN..] AddCSLuaFile() - Failed to find specified file - ' .. File)
		end
	end
end

function VLL.SaveFile(Path, Contents, Bundle)
	VLL.FILE_MEMORY[Path] = {
		content = Contents,
		bundle = Bundle,
	}

	local split = string.Explode('/', Path)
	table.remove(split)

	local prev = ''

	for k, v in ipairs(split) do
		local new = prev .. '/' .. v
		VLL.DIRECTORY_MEMORY[new] = new
		prev = new
	end

	VLL.COMPILED_MEMORY[Path] = nil
end

function VLL.IsMyFile(File)
	return VLL.FILE_MEMORY[File:lower()] ~= nil
end

VLL.FileExists = VLL.IsMyFile

function VLL.FileDirectory(FILE)
	local arr = string.Explode('/', FILE)
	local str = ''

	for k = 1, #arr - 1 do
		str = str .. '/' .. arr[k]
	end

	return string.sub(str, 2)
end

function VLL.CopyTable(tab)
	local reply = {}

	for k, v in pairs(tab) do
		if k == '__index' or k == '__newindex' then goto CONTINUE end

		if type(v) ~= 'table' then
			reply[k] = v
		else
			reply[k] = VLL.CopyTable(tab)
		end

		::CONTINUE::
	end

	if tab.__index == tab then
		reply.__index = reply
	else
		reply.__index = tab.__index
	end

	if tab.__newindex == tab then
		reply.__newindex = reply
	else
		reply.__newindex = tab.__newindex
	end

	return reply
end

file.__index = file --Snort Snort

local fileFuncs = {
	Find = VLL.__FileFind,
	Read = VLL.FileRead,
	Exists = VLL.__FileExists,
	IsDir = VLL.IsDir,
}

for k, v in pairs(file) do
	if not fileFuncs[k] then
		fileFuncs[k] = v
	end
end

local hookFuncs = {
	Add = VLL.__addHook,
}

local EnvMeta = {
	__index = _G,
	__newindex = function(self, key, value)
		_G[key] = value
	end
}

setmetatable(fileFuncs, {
	__index = _G.file,
	__newindex = _G.file,
})

setmetatable(hookFuncs, {__index = hook})

function VLL.AdminMessage(...)
	VLL.Message(...)

	if SERVER then
		net.Start('VLL.Admin')
		net.WriteTable({...})
		net.Broadcast()
	end
end

function VLL.SafeCall(func)
	xpcall(func, VLL.ErrorHandler)
end

function VLL.__Compile(path)
	local compiled, fenv = VLL.Compile(path)

	local sayFunc = VLL.SILENT_INCLUDE and VLL.EMPTY_FUNCTION or VLL.Message
	local ErrMessage = 'undefined'

	local function ErrorHandler(err)
		ErrMessage = err
		VLL.Message(VLL.ERROR_COLOR, 'ERROR! ', VLL.DEFAULT_COLOR, err)
		VLL.Message(debug.traceback())
	end

	local newFunc
	function newFunc(...)
		setfenv(compiled, getfenv(newFunc))
		local reply = {xpcall(compiled, ErrorHandler, ...)}

		if reply[1] then
			if not VLL.IS_TESTING then
				sayFunc('Running File: ' .. path)
			else
				sayFunc('[.. OK ..] Compiled and runned file     : ' .. path)
			end
		else
			if not VLL.IS_TESTING then
				VLL.Message('Failed to run a File: ' .. path .. '. Error: ' .. ErrMessage)
			else
				VLL.Message(VLL.ERROR_COLOR, '[..FAIL..] File filed to compile/execute: ' .. path .. ' || ' .. ErrMessage)
			end
		end

		return unpack(reply, 2)
	end

	setfenv(newFunc, fenv)
	return newFunc
end

VLL.PRINT_COLOR = Color(200, 200, 0)
VLL.MSG_COLOR = Color(0, 200, 200)

function VLL.__print(...)
	print(...)

	if VLL.SendOutputTo then
		local tab = {VLL.PRINT_COLOR, ...}
		table.insert(VLL.SendOutputTo, tab)

		local last = tab[#tab]
		local hit = false

		if type(last) == 'string' then
			if last:find('\n') then
				hit = true
			end
		end

		if not hit then
			table.insert(VLL.SendOutputTo, {'\n'})
		end
	end
end

function VLL.__msg(...)
	Msg(...)

	if VLL.SendOutputTo then
		local tab = {VLL.MSG_COLOR, ...}
		local last = tab[#tab]

		if type(last) == 'string' then
			last = last:gsub('\r\n', '\n')
		end

		table.insert(VLL.SendOutputTo, tab)
	end
end

function VLL.__msgc(...)
	MsgC(...)

	if VLL.SendOutputTo then
		local tab = {VLL.MSG_COLOR, ...}
		local last = tab[#tab]

		if type(last) == 'string' then
			last = last:gsub('\r\n', '\n')
		end

		table.insert(VLL.SendOutputTo, tab)
	end
end

function VLL.module(name, ...)
	local oldEnv = getfenv(2)

	local newEnv = {
		VLL_CURR_FILE = oldEnv.VLL_CURR_FILE,
		VLL_BUNDLE = oldEnv.VLL_BUNDLE,
		VLL_CURR_DIR = oldEnv.VLL_CURR_DIR,
	}

	local moduleTable = _G[name] or {}
	_G[name] = moduleTable

	moduleTable[name] = moduleTable
	moduleTable._M = moduleTable

	local useGlobals = false

	for k, func in ipairs{...} do
		if func == package.seeall then
			useGlobals = true
		else
			func(moduleTable)
		end
	end

	local meta = {
		__newindex = function(self, key, val)
			moduleTable[key] = val
		end,

		__index = function(self, key)
			if moduleTable[key] ~= nil then
				return moduleTable[key]
			end

			if useGlobals then
				if oldEnv[key] ~= nil then
					return oldEnv[key]
				end
			end

			return rawget(newEnv, key)
		end,
	}

	setmetatable(newEnv, meta)
	setfenv(2, newEnv)

	return moduleTable
end

function VLL.Compile(File)
	File = File:lower()
	local Env = {
		file = fileFuncs,
		print = VLL.__print,
		Msg = VLL.__msg,
		module = VLL.module,
		MsgC = VLL.__msgc,
		require = VLL.__realRequire,
		AddCSLuaFile = VLL.CSLua,
		CompileString = VLL.__compileString,
		CompileFile = VLL.__Compile,
		RunString = VLL.__runString,
		include = VLL.Include,
		VLL_CURR_FILE = File,
		VLL_BUNDLE = VLL.FileBundle(File),
		VLL_CURR_DIR = VLL.FileDirectory(File),
		hook = hookFuncs,
		error = VLL.ErrorHandlerLua,
		Error = VLL.ErrorHandlerSilent,
		--ErrorNoHalt = VLL.ErrorHandlerSilentNoHalt,
		_G = _G,
	}

	setmetatable(Env, EnvMeta)

	local content = VLL.ReadFile(File)
	local status

	if #content < 10 then --Oops
		local estatus, nstatus = pcall(CompileFile, File)

		if not estatus then
			local ostatus = status

			status = function()
				if not VLL.IS_TESTING then
					VLL.AdminMessage('Tried to load file ' .. File .. ' with next error: ' .. status)

					string.gsub(ostatus, ':[0-9]+:', function(w)
						local new = string.sub(w, 2, #w - 1)
						print(VLL.StringLine(VLL.ReadFile(File), tonumber(new)))
					end)
				else
					local str = ''
					string.gsub(ostatus, ':[0-9]+:', function(w)
						local new = string.sub(w, 2, #w - 1)
						str = VLL.StringLine(VLL.ReadFile(File), tonumber(new))
					end)

					error('ERROR: ' .. ostatus .. ' (' .. str .. ')')
				end
			end
		elseif not nstatus then
			status = function()
				if not VLL.IS_TESTING then
					VLL.AdminMessage('Tried to load non-exist file: ' .. File)
				else
					VLL.AdminMessage('[..WARN..] Tried to load non-exist file: ' .. File)
				end
			end
		else
			status = nstatus
		end
	else
		status = CompileString(content, '[VLL: ' .. VLL.FileBundle(File) .. ' - ' .. File .. ']', false)

		if not isfunction(status) then
			local ostatus = status

			status = function()
				if not VLL.IS_TESTING then
					VLL.AdminMessage('Tried to load file ' .. File .. ' with next parse error: ' .. ostatus)

					string.gsub(ostatus, ':[0-9]+:', function(w)
						local new = string.sub(w, 2, #w - 1)
						print(VLL.StringLine(VLL.ReadFile(File), tonumber(new)))
					end)
				else
					local str = ''
					string.gsub(ostatus, ':[0-9]+:', function(w)
						local new = string.sub(w, 2, #w - 1)
						str = VLL.StringLine(VLL.ReadFile(File), tonumber(new))
					end)

					error('PARSE ERROR: ' .. ostatus .. ' (' .. str .. ')')
				end
			end
		end
	end

	setfenv(status, Env)

	return status, Env
end

function VLL.Message(...)
	MsgC(Color(0, 200, 0), '[DBot\'s VLL] ', Color(200, 200, 200), ...)
	MsgC('\n')

	if VLL.SendOutputTo then
		table.insert(VLL.SendOutputTo, {Color(0, 200, 0), '[DBot\'s VLL] ', Color(200, 200, 200), ...})
		table.insert(VLL.SendOutputTo, {'\n'})
	end
end

function VLL.BundleFiles(bundle)
	local reply = {}

	for k, v in pairs(VLL.FILE_MEMORY) do
		if v.bundle == bundle then
			table.insert(reply, k)
		end
	end

	return reply
end

local function RecursiveRegisterMetadata(classname, tableIn, metaRegistry)
	local base = tableIn.Base
	local findBase = base and metaRegistry[base]

	if not findBase and base then
		local getOld = baseclass.Get(base)

		if getOld then
			--print(classname .. ' <- ' .. base .. ' FOREIGN')
			for key, value in pairs(getOld) do
				if tableIn[key] == nil then
					tableIn[key] = value
				end
			end
		end
	end

	if findBase then
		RecursiveRegisterMetadata(base, findBase, metaRegistry)
		--print(classname .. ' <- ' .. base)

		for key, value in pairs(findBase) do
			if tableIn[key] == nil then
				tableIn[key] = value
			end
		end
	end

	--print(classname .. ' !')

	baseclass.Set(classname, tableIn)
end

local function loadFuckingTFA(path, bundle)
	local contents = VLL.DirectoryContent(path)
	table.sort(contents)

	for k, v in pairs(contents) do
		if not v:StartWith('cl_') and not v:StartWith('sv_') and VLL.FileBundle(path .. '/' .. v) == bundle then
			VLL.Include(path .. '/' .. v)
		end
	end

	for k, v in pairs(contents) do
		if ((v:StartWith('cl_') and CLIENT) or (v:StartWith('sv_') and SERVER)) and VLL.FileBundle(path .. '/' .. v) == bundle then
			VLL.Include(path .. '/' .. v)
		end
	end
end

function VLL.RunBundle(bundle)
	VLL.Message('Running bundle: ' .. bundle)

	local t = SysTime()

	if VLL.BUNDLE_DATA[bundle].status == '2' then
		VLL.Include(bundle .. '.lua')
		return
	end

	--[[local contents = VLL.DirectoryContent('includes/modules')
	table.sort(contents)

	for k, v in pairs(contents) do
		if VLL.FileBundle('includes/modules/' .. v) ~= bundle then continue end
		VLL.Include('includes/modules/' .. v)
	end]]

	local contents = VLL.DirectoryContent('autorun')
	table.sort(contents)

	for k, v in pairs(contents) do
		if VLL.FileBundle('autorun/' .. v) == bundle then VLL.Include('autorun/' .. v) end
	end

	if DLib then
		local contents = VLL.DirectoryContent('dlib/autorun')
		table.sort(contents)

		for k, v in pairs(contents) do
			if VLL.FileBundle('dlib/autorun/' .. v) == bundle then VLL.Include('dlib/autorun/' .. v) end
		end
	end

	if SERVER then
		local contents = VLL.DirectoryContent('autorun/server')
		table.sort(contents)

		for k, v in pairs(contents) do
			if VLL.FileBundle('autorun/server/' .. v) == bundle then VLL.Include('autorun/server/' .. v) end
		end

		if DLib then
			local contents = VLL.DirectoryContent('dlib/autorun/server')
			table.sort(contents)

			for k, v in pairs(contents) do
				if VLL.FileBundle('dlib/autorun/server/' .. v) == bundle then VLL.Include('dlib/autorun/server/' .. v) end
			end
		end
	else
		local contents = VLL.DirectoryContent('autorun/client')
		table.sort(contents)

		for k, v in pairs(contents) do
			if VLL.FileBundle('autorun/client/' .. v) == bundle then VLL.Include('autorun/client/' .. v) end

		end

		if DLib then
			local contents = VLL.DirectoryContent('dlib/autorun/client')
			table.sort(contents)

			for k, v in pairs(contents) do
				if VLL.FileBundle('dlib/autorun/client/' .. v) == bundle then VLL.Include('dlib/autorun/client/' .. v) end
			end
		end
	end

	local METATABLES = {}

	local folders = VLL.DirectoryFolders('weapons')
	table.sort(folders)

	for k, f in pairs(folders) do
		SWEP = {}
		SWEP.Folder = 'weapons/' .. f
		SWEP.Primary = {}
		SWEP.Secondary = {}

		local hit = false

		if SERVER and VLL.FileBundle('weapons/' .. f .. '/init.lua') == bundle then
			VLL.Include('weapons/' .. f .. '/init.lua')
			hit = true
		end

		if CLIENT and VLL.FileBundle('weapons/' .. f .. '/cl_init.lua') == bundle then
			VLL.Include('weapons/' .. f .. '/cl_init.lua')
			hit = true
		end

		if VLL.FileBundle('weapons/' .. f .. '/shared.lua') == bundle then
			VLL.Include('weapons/' .. f .. '/shared.lua')
			hit = true
		end

		if hit then
			weapons.Register(SWEP, f)
			baseclass.Set(f, SWEP)
			METATABLES[f] = SWEP
		end

		SWEP = nil
	end

	local contents = VLL.DirectoryContent('weapons')
	table.sort(contents)

	for k, v in pairs(contents) do
		if VLL.FileBundle('weapons/' .. v) == bundle then
			SWEP = {}
			SWEP.Folder = 'weapons'
			SWEP.Primary = {}
			SWEP.Secondary = {}

			VLL.Include('weapons/' .. v)

			weapons.Register(SWEP, string.sub(v, 1, -5))
			baseclass.Set(string.sub(v, 1, -5), SWEP)
			METATABLES[string.sub(v, 1, -5)] = SWEP
			SWEP = nil
		end
	end

	local folders = VLL.DirectoryFolders('entities')
	table.sort(folders)

	for k, f in pairs(folders) do
		ENT = {}
		ENT.Folder = 'entities/' .. f

		local hit = false

		if SERVER and VLL.FileBundle('entities/' .. f .. '/init.lua') == bundle then
			VLL.Include('entities/' .. f .. '/init.lua')
			hit = true
		end

		if CLIENT and VLL.FileBundle('entities/' .. f .. '/cl_init.lua') == bundle then
			VLL.Include('entities/' .. f .. '/cl_init.lua')
			hit = true
		end

		if VLL.FileBundle('entities/' .. f .. '/shared.lua') == bundle then
			VLL.Include('entities/' .. f .. '/shared.lua')
			hit = true
		end

		if hit then
			scripted_ents.Register(ENT, f)
			baseclass.Set(f, ENT)
			METATABLES[f] = ENT
		end

		ENT = nil
	end

	local contents = VLL.DirectoryContent('entities')
	table.sort(contents)

	for k, v in pairs(contents) do
		if VLL.FileBundle('entities/' .. v) == bundle then
			ENT = {}
			ENT.Folder = 'entities'

			VLL.Include('entities/' .. v)

			scripted_ents.Register(ENT, string.sub(v, 1, -5))
			baseclass.Set(string.sub(v, 1, -5), ENT)
			METATABLES[string.sub(v, 1, -5)] = ENT
		end
	end

	if CLIENT then
		local contents = VLL.DirectoryContent('effects')
		table.sort(contents)

		for k, v in pairs(contents) do
			if VLL.FileBundle('effects/' .. v) == bundle then
				EFFECT = {}
				VLL.Include('effects/' .. v)
				effects.Register(EFFECT, string.sub(v, 1, -5))
			end
		end

		contents = VLL.DirectoryFolders('effects')
		table.sort(contents)

		for k, v in pairs(contents) do
			if VLL.FileBundle('effects/' .. v .. '/init.lua') == bundle then
				EFFECT = {}
				VLL.Include('effects/' .. v .. '/init.lua')
				effects.Register(EFFECT, v)
			end
		end
	end

	if TFA then
		loadFuckingTFA('tfa/modules', bundle)
		loadFuckingTFA('tfa/external', bundle)
		local contents = VLL.DirectoryContent('tfa/att')

		for k, v in pairs(contents) do
			if VLL.FileBundle('tfa/att/' .. v) == bundle then
				TFAUpdateAttachments()
				break
			end
		end
	end

	for classname, metadata in pairs(METATABLES) do
		RecursiveRegisterMetadata(classname, metadata, METATABLES)
	end

	--[[
	local toolgunHit = false

	local contents = VLL.DirectoryContent('weapons/gmod_tool/stools')

	for k, fil in ipairs(contents) do
		if VLL.FileBundle('weapons/gmod_tool/stools/' .. fil) == bundle then
			toolgunHit = true
			break
		end
	end

	if toolgunHit then
		VLL.Message('Toolgun changes detected, reloading toolgun SWEP')

		SWEP = {}
		SWEP.Folder = 'weapons/gmod_tool'
		SWEP.Primary = {}
		SWEP.Secondary = {}

		if SERVER then
			VLL.Include('weapons/gmod_tool/init.lua')
		else
			VLL.Include('weapons/gmod_tool/cl_init.lua')
		end

		scripted_ents.Register(SWEP, 'gmod_tool')
	end
	]]

	if VLL.HOOKS_POST[bundle] then
		for k, v in pairs(VLL.HOOKS_POST[bundle]) do
			v()
		end
	end

	VLL.Message('Initialized bundle ' .. bundle .. ' in ' .. math.floor((SysTime() - t) * 100000) / 100 .. ' ms')
end

VLL.SendOutputTo = nil

function VLL.TestBundle(contents, bundle, output)
	output = output or {}
	local parsed = VLL.ParseContent(contents)

	if not parsed then
		return
	end

	VLL.BUNDLE_STATUS[bundle] = VLL.RUNNING
	VLL.BUNDLE_DATA[bundle] = {
		total = #parsed / 2,
		done = 0,
		started = CurTime(),
		status = '0',
	}

	for i = 1, #parsed, 2 do
		local FILE = parsed[i]
		local body = parsed[i + 1]
		local code = 200
		if body then
			VLL.SaveFile(FILE, body, bundle)
		end
	end

	VLL.IS_TESTING = true
	VLL.SendOutputTo = output
	VLL.RunBundle(bundle)
	VLL.SendOutputTo = nil
	VLL.IS_TESTING = false

	local strout = {}

	for k, data in ipairs(output) do
		for k, v in ipairs(data) do
			if type(v) == 'string' then
				table.insert(strout, v)
			end

			if type(v) == 'table' and v.a and v.r and v.g and v.b then
				table.insert(strout, VLL.Format256Color(v))
			end
		end

		table.insert(strout, VLL.Format256Color(color_white))
	end

	local stringToOut = table.concat(strout, '')
	file.Write('vll_bundletest.txt', stringToOut)

	return strout, stringToOut
end

function VLL.FileLoaded(code, body, FILE, bundle)
	VLL.Message('File loaded: ' .. FILE .. ' for bundle ' .. bundle .. ' with status code: ' .. code)
	VLL.SaveFile(FILE, body, bundle)
	VLL.BUNDLE_DATA[bundle].done = VLL.BUNDLE_DATA[bundle].done + 1

	VLL.BUNDLE_STATUS[bundle] = VLL.LOADING_IN_PROCESS

	if VLL.BUNDLE_DATA[bundle].done >= VLL.BUNDLE_DATA[bundle].total then
		VLL.BUNDLE_STATUS[bundle] = VLL.LOADED
		VLL.RunBundle(bundle)
		VLL.BUNDLE_STATUS[bundle] = VLL.RUNNING
	end
end

function VLL.LoadBundleFiles(array, bundle, status)
	VLL.Message('Loading Bundle: ' .. bundle)
	VLL.Message('Total Files: ' .. #array)

	for k, v in pairs(array) do
		VLL.LoadFile(v, bundle, status)
	end
end

VLL.ColorMapping = {
	{Color(255, 255, 255), '97'},   -- White
	{Color(0, 0, 0), '30'},         -- Black
	{Color(255, 0, 0), '31'},       -- Red
	{Color(0, 255, 0), '32'},       -- Green
	{Color(255, 255, 0), '33'},     -- Yellow
	{Color(0, 0, 255), '34'},       -- Blue
	{Color(255, 0, 255), '35'},     -- Magneta
	{Color(0, 255, 255), '36'},     -- Cyan
	{Color(200, 200, 200), '37'},   -- Light gray
	{Color(100, 100, 100), '90'},   -- Dark gray

	{Color(255, 100, 100), '91'},   -- Light Red
	{Color(100, 255, 100), '92'},   -- Light Green
	{Color(255, 255, 100), '93'},   -- Light Yellow
	{Color(100, 100, 255), '94'},   -- Light Blue
	{Color(255, 100, 255), '95'},   -- Light Magneta
	{Color(100, 255, 255), '96'},   -- Cyan
}

VLL.ColorMapping256 = {{'0', Color(0, 0, 0)}, {'1', Color(128, 0, 0)}, {'2', Color(0, 128, 0)}, {'3', Color(128, 128, 0)}, {'4', Color(0, 0, 128)}, {'5', Color(128, 0, 128)}, {'6', Color(0, 128, 128)}, {'7', Color(192, 192, 192)}, {'8', Color(128, 128, 128)}, {'9', Color(255, 0, 0)}, {'10', Color(0, 255, 0)}, {'11', Color(255, 255, 0)}, {'12', Color(0, 0, 255)}, {'13', Color(255, 0, 255)}, {'14', Color(0, 255, 255)}, {'15', Color(255, 255, 255)}, {'16', Color(0, 0, 0)}, {'17', Color(0, 0, 95)}, {'18', Color(0, 0, 135)}, {'19', Color(0, 0, 175)}, {'20', Color(0, 0, 215)}, {'21', Color(0, 0, 255)}, {'22', Color(0, 95, 0)}, {'23', Color(0, 95, 95)}, {'24', Color(0, 95, 135)}, {'25', Color(0, 95, 175)}, {'26', Color(0, 95, 215)}, {'27', Color(0, 95, 255)}, {'28', Color(0, 135, 0)}, {'29', Color(0, 135, 95)}, {'30', Color(0, 135, 135)}, {'31', Color(0, 135, 175)}, {'32', Color(0, 135, 215)}, {'33', Color(0, 135, 255)}, {'34', Color(0, 175, 0)}, {'35', Color(0, 175, 95)}, {'36', Color(0, 175, 135)}, {'37', Color(0, 175, 175)}, {'38', Color(0, 175, 215)}, {'39', Color(0, 175, 255)}, {'40', Color(0, 215, 0)}, {'41', Color(0, 215, 95)}, {'42', Color(0, 215, 135)}, {'43', Color(0, 215, 175)}, {'44', Color(0, 215, 215)}, {'45', Color(0, 215, 255)}, {'46', Color(0, 255, 0)}, {'47', Color(0, 255, 95)}, {'48', Color(0, 255, 135)}, {'49', Color(0, 255, 175)}, {'50', Color(0, 255, 215)}, {'51', Color(0, 255, 255)}, {'52', Color(95, 0, 0)}, {'53', Color(95, 0, 95)}, {'54', Color(95, 0, 135)}, {'55', Color(95, 0, 175)}, {'56', Color(95, 0, 215)}, {'57', Color(95, 0, 255)}, {'58', Color(95, 95, 0)}, {'59', Color(95, 95, 95)}, {'60', Color(95, 95, 135)}, {'61', Color(95, 95, 175)}, {'62', Color(95, 95, 215)}, {'63', Color(95, 95, 255)}, {'64', Color(95, 135, 0)}, {'65', Color(95, 135, 95)}, {'66', Color(95, 135, 135)}, {'67', Color(95, 135, 175)}, {'68', Color(95, 135, 215)}, {'69', Color(95, 135, 255)}, {'70', Color(95, 175, 0)}, {'71', Color(95, 175, 95)}, {'72', Color(95, 175, 135)}, {'73', Color(95, 175, 175)}, {'74', Color(95, 175, 215)}, {'75', Color(95, 175, 255)}, {'76', Color(95, 215, 0)}, {'77', Color(95, 215, 95)}, {'78', Color(95, 215, 135)}, {'79', Color(95, 215, 175)}, {'80', Color(95, 215, 215)}, {'81', Color(95, 215, 255)}, {'82', Color(95, 255, 0)}, {'83', Color(95, 255, 95)}, {'84', Color(95, 255, 135)}, {'85', Color(95, 255, 175)}, {'86', Color(95, 255, 215)}, {'87', Color(95, 255, 255)}, {'88', Color(135, 0, 0)}, {'89', Color(135, 0, 95)}, {'90', Color(135, 0, 135)}, {'91', Color(135, 0, 175)}, {'92', Color(135, 0, 215)}, {'93', Color(135, 0, 255)}, {'94', Color(135, 95, 0)}, {'95', Color(135, 95, 95)}, {'96', Color(135, 95, 135)}, {'97', Color(135, 95, 175)}, {'98', Color(135, 95, 215)}, {'99', Color(135, 95, 255)}, {'100', Color(135, 135, 0)}, {'101', Color(135, 135, 95)}, {'102', Color(135, 135, 135)}, {'103', Color(135, 135, 175)}, {'104', Color(135, 135, 215)}, {'105', Color(135, 135, 255)}, {'106', Color(135, 175, 0)}, {'107', Color(135, 175, 95)}, {'108', Color(135, 175, 135)}, {'109', Color(135, 175, 175)}, {'110', Color(135, 175, 215)}, {'111', Color(135, 175, 255)}, {'112', Color(135, 215, 0)}, {'113', Color(135, 215, 95)}, {'114', Color(135, 215, 135)}, {'115', Color(135, 215, 175)}, {'116', Color(135, 215, 215)}, {'117', Color(135, 215, 255)}, {'118', Color(135, 255, 0)}, {'119', Color(135, 255, 95)}, {'120', Color(135, 255, 135)}, {'121', Color(135, 255, 175)}, {'122', Color(135, 255, 215)}, {'123', Color(135, 255, 255)}, {'124', Color(175, 0, 0)}, {'125', Color(175, 0, 95)}, {'126', Color(175, 0, 135)}, {'127', Color(175, 0, 175)}, {'128', Color(175, 0, 215)}, {'129', Color(175, 0, 255)}, {'130', Color(175, 95, 0)}, {'131', Color(175, 95, 95)}, {'132', Color(175, 95, 135)}, {'133', Color(175, 95, 175)}, {'134', Color(175, 95, 215)}, {'135', Color(175, 95, 255)}, {'136', Color(175, 135, 0)}, {'137', Color(175, 135, 95)}, {'138', Color(175, 135, 135)}, {'139', Color(175, 135, 175)}, {'140', Color(175, 135, 215)}, {'141', Color(175, 135, 255)}, {'142', Color(175, 175, 0)}, {'143', Color(175, 175, 95)}, {'144', Color(175, 175, 135)}, {'145', Color(175, 175, 175)}, {'146', Color(175, 175, 215)}, {'147', Color(175, 175, 255)}, {'148', Color(175, 215, 0)}, {'149', Color(175, 215, 95)}, {'150', Color(175, 215, 135)}, {'151', Color(175, 215, 175)}, {'152', Color(175, 215, 215)}, {'153', Color(175, 215, 255)}, {'154', Color(175, 255, 0)}, {'155', Color(175, 255, 95)}, {'156', Color(175, 255, 135)}, {'157', Color(175, 255, 175)}, {'158', Color(175, 255, 215)}, {'159', Color(175, 255, 255)}, {'160', Color(215, 0, 0)}, {'161', Color(215, 0, 95)}, {'162', Color(215, 0, 135)}, {'163', Color(215, 0, 175)}, {'164', Color(215, 0, 215)}, {'165', Color(215, 0, 255)}, {'166', Color(215, 95, 0)}, {'167', Color(215, 95, 95)}, {'168', Color(215, 95, 135)}, {'169', Color(215, 95, 175)}, {'170', Color(215, 95, 215)}, {'171', Color(215, 95, 255)}, {'172', Color(215, 135, 0)}, {'173', Color(215, 135, 95)}, {'174', Color(215, 135, 135)}, {'175', Color(215, 135, 175)}, {'176', Color(215, 135, 215)}, {'177', Color(215, 135, 255)}, {'178', Color(215, 175, 0)}, {'179', Color(215, 175, 95)}, {'180', Color(215, 175, 135)}, {'181', Color(215, 175, 175)}, {'182', Color(215, 175, 215)}, {'183', Color(215, 175, 255)}, {'184', Color(215, 215, 0)}, {'185', Color(215, 215, 95)}, {'186', Color(215, 215, 135)}, {'187', Color(215, 215, 175)}, {'188', Color(215, 215, 215)}, {'189', Color(215, 215, 255)}, {'190', Color(215, 255, 0)}, {'191', Color(215, 255, 95)}, {'192', Color(215, 255, 135)}, {'193', Color(215, 255, 175)}, {'194', Color(215, 255, 215)}, {'195', Color(215, 255, 255)}, {'196', Color(255, 0, 0)}, {'197', Color(255, 0, 95)}, {'198', Color(255, 0, 135)}, {'199', Color(255, 0, 175)}, {'200', Color(255, 0, 215)}, {'201', Color(255, 0, 255)}, {'202', Color(255, 95, 0)}, {'203', Color(255, 95, 95)}, {'204', Color(255, 95, 135)}, {'205', Color(255, 95, 175)}, {'206', Color(255, 95, 215)}, {'207', Color(255, 95, 255)}, {'208', Color(255, 135, 0)}, {'209', Color(255, 135, 95)}, {'210', Color(255, 135, 135)}, {'211', Color(255, 135, 175)}, {'212', Color(255, 135, 215)}, {'213', Color(255, 135, 255)}, {'214', Color(255, 175, 0)}, {'215', Color(255, 175, 95)}, {'216', Color(255, 175, 135)}, {'217', Color(255, 175, 175)}, {'218', Color(255, 175, 215)}, {'219', Color(255, 175, 255)}, {'220', Color(255, 215, 0)}, {'221', Color(255, 215, 95)}, {'222', Color(255, 215, 135)}, {'223', Color(255, 215, 175)}, {'224', Color(255, 215, 215)}, {'225', Color(255, 215, 255)}, {'226', Color(255, 255, 0)}, {'227', Color(255, 255, 95)}, {'228', Color(255, 255, 135)}, {'229', Color(255, 255, 175)}, {'230', Color(255, 255, 215)}, {'231', Color(255, 255, 255)}, {'232', Color(8, 8, 8)}, {'233', Color(18, 18, 18)}, {'234', Color(28, 28, 28)}, {'235', Color(38, 38, 38)}, {'236', Color(48, 48, 48)}, {'237', Color(58, 58, 58)}, {'238', Color(68, 68, 68)}, {'239', Color(78, 78, 78)}, {'240', Color(88, 88, 88)}, {'241', Color(96, 96, 96)}, {'242', Color(102, 102, 102)}, {'243', Color(118, 118, 118)}, {'244', Color(128, 128, 128)}, {'245', Color(138, 138, 138)}, {'246', Color(148, 148, 148)}, {'247', Color(158, 158, 158)}, {'248', Color(168, 168, 168)}, {'249', Color(178, 178, 178)}, {'250', Color(188, 188, 188)}, {'251', Color(198, 198, 198)}, {'252', Color(208, 208, 208)}, {'253', Color(218, 218, 218)}, {'254', Color(228, 228, 228)}, {'255', Color(238, 238, 238)},}

function VLL.GetColorCode(col)
	for k, v in ipairs(VLL.ColorMapping) do
		local curr = v[1]

		if curr.r == col.r and curr.g == col.g and curr.b == col.b then
			return v[2]
		end
	end
end

function VLL.GetColorCode256(col)
	for k, v in ipairs(VLL.ColorMapping256) do
		local curr = v[2]

		if curr.r == col.r and curr.g == col.g and curr.b == col.b then
			return v[1]
		end
	end
end

function VLL.GetNearestColor(col)
	local new
	local cdelta = 1000

	for k, v in ipairs(VLL.ColorMapping) do
		local curr = v[1]

		local deltaR, deltaG, deltaB = math.abs(col.r - curr.r), math.abs(col.g - curr.g), math.abs(col.b - curr.b)
		local summ = deltaR + deltaG + deltaB

		if summ < cdelta then
			new = curr
			cdelta = summ
		end
	end

	return new
end

function VLL.GetNearestColor256(col)
	local new
	local cdelta = 1000

	for k, v in ipairs(VLL.ColorMapping256) do
		local curr = v[2]

		local deltaR, deltaG, deltaB = math.abs(col.r - curr.r), math.abs(col.g - curr.g), math.abs(col.b - curr.b)
		local summ = deltaR + deltaG + deltaB

		if summ < cdelta then
			new = curr
			cdelta = summ
		end
	end

	return new
end

function VLL.TranslateColor(col)
	return VLL.GetColorCode(VLL.GetNearestColor(col))
end

function VLL.TranslateColor256(col)
	return VLL.GetColorCode256(VLL.GetNearestColor256(col))
end

function VLL.ReplaceColorsWithCodes(tab)
	for k, v in ipairs(tab) do
		if type(v) == 'table' and v.a and v.r and v.g and v.b then
			tab[k] = '\\033[' .. VLL.TranslateColor(v) .. 'm'
		end
	end
end

function VLL.ReplaceColorsWithCodes256(tab)
	for k, v in ipairs(tab) do
		if type(v) == 'table' and v.a and v.r and v.g and v.b then
			tab[k] = '\\033[38;5;' .. VLL.TranslateColor256(v) .. 'm'
		end
	end
end

function VLL.FormatColor(col)
	return '\\033[' .. VLL.TranslateColor(col) .. 'm'
end

function VLL.Format256Color(col)
	return '\\033[38;5;' .. VLL.TranslateColor256(col) .. 'm'
end

concommand.Add('vll_load', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	if not args[1] then
		VLL.Message('No Bundle!')
		return
	end

	VLL.Load(args[1])
end)

concommand.Add('vll_cload', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	if not args[1] then
		VLL.Message('No Bundle!')
		return
	end

	VLL.LoadCached(args[1])
end)

concommand.Add('vll_workshop', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	if not args[1] then
		VLL.Message('Not a valid workshop ID')
		return
	end

	if not tonumber(args[1]) then
		VLL.Message('Not a valid workshop ID')
		return
	end

	VLL.LoadWorkshop(args[1])
end)

concommand.Add('vll_load_silent', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	if not args[1] then
		VLL.Message('No Bundle!')
		return
	end

	VLL.Load(args[1], true)
end)

concommand.Add('vll_cload_silent', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	if not args[1] then
		VLL.Message('No Bundle!')
		return
	end

	VLL.LoadCached(args[1], true)
end)

concommand.Add('vll_unload_hooks', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	if not args[1] then
		VLL.Message('No Bundle!')
		return
	end

	VLL.Message('Unloading hooks for ' .. args[1])
	VLL.UnloadHooks(args[1])
end)

concommand.Add('vll_reload', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	http.Fetch('https://dbot.serealia.ca/vll/vll.lua', function(b) RunString(b, 'VLL') end)
end)

concommand.Add('vll_reload_silent', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	http.Fetch('https://dbot.serealia.ca/vll/vll.lua', function(b)
		VLL.LoadSilent = true
		RunString(b, 'VLL')
	end)
end)

concommand.Add('vll_mountall', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end

	for i, val in ipairs(VLL.CMOUNTING_GMA) do
		ContinueMountGMA(unpack(val))
	end

	VLL.CMOUNTING_GMA = {}
end)

concommand.Add('vll_workshop', function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then VLL.MessagePlayer(ply, 'Not a Super Admin!') return end

	local id = tonumber(args[1])

	if not id then
		VLL.Message('Not a valid workshop ID')
		return
	end

	VLL.LoadWorkshopSV(id, false, true)
end)

concommand.Add('vll', function(ply, cmd, args)
	if IsValid(ply) and SERVER and not game.SinglePlayer() then return end
	MsgC([[
VVL - Virtual Lua Loader
Maded by DBot

Usage:
vll_load bundle - loads bundle
vll_load_silent bundle - loads bundle silently from clients on serverside, same as vll_load on clientside
vll_load_server bundle - loads bundle serverside from client if superadmin
vll_load_server_silent bundle - loads bundle silently on serverside from client if superadmin
vll_unreplicate bundle - makes bundle not sended to client when they join
vll_unload_hooks bundle - unloads hooks created by bundle
]])
end)

local dots = '.  '
local dot = 1
local nextdot = 0

local dottab = {
	'.   ',
	' .  ',
	'  . ',
	'   .',
	'  . ',
	' .  ',
}

local DisplayColor = Color(188, 15, 20)

local function HUDPaint()
	if #VLL.CMOUNTING_GMA ~= 0 then
		local x, y = ScrW() / 2, 200

		draw.DrawText('VLL is mounting content', 'VLL.Warning1', x, y, DisplayColor, TEXT_ALIGN_CENTER)
		draw.DrawText(#VLL.CMOUNTING_GMA .. ' files in queue\nvll_mountall in console to mount all files instantly', 'VLL.Warning2', x, y + 30, DisplayColor, TEXT_ALIGN_CENTER)
	end

	if VLL.WDOWNLOADING ~= 0 then
		local x, y = ScrW() / 2, 150

		draw.DrawText('Downloading ' .. VLL.WDOWNLOADING .. ' workshop addons', 'VLL.Warning3', x, y + 30, DisplayColor, TEXT_ALIGN_CENTER)
	end

	if VLL.WINFO ~= 0 then
		local x, y = ScrW() / 2, 130

		draw.DrawText('Receiving info about ' .. VLL.WINFO .. ' workshop addons', 'VLL.Warning3', x, y + 30, DisplayColor, TEXT_ALIGN_CENTER)
	end

	if #VLL.DOWNLOADING == 0 then return end

	if nextdot < CurTime() then
		dot = dot + 1
		if dot > #dottab then
			dot = 1
		end

		nextdot = CurTime() + .1
	end

	dots = dottab[dot]

	surface.SetDrawColor(0, 0, 0, 150)
	surface.SetTextColor(255, 255, 255)
	surface.SetFont('VLL.Roboto')

	local text = 'VLL - Downloading GMAs: ' .. #VLL.DOWNLOADING .. ' ' .. dots

	local w, h = surface.GetTextSize(text)
	local x, y = ScrW() - w - 4, 0

	surface.DrawRect(x - 2, y, w + 2, h)
	surface.SetTextPos(x, y)
	surface.DrawText(text)

	for k, v in ipairs(VLL.DOWNLOADING) do
		y = y + h + 3

		local text = 'GMA: ' .. v .. '.gma'

		local w, h = surface.GetTextSize(text)
		surface.DrawRect(x - 2, y, w + 2, h)
		surface.SetTextPos(x, y)
		surface.DrawText(text)
	end
end

local function PopulatePropMenuPost()
	local list = VLL.TOPLIST
	spawnmenu.AddPropCategory('vll_spawnlist', 'VLL GMA\'s', list.contents, list.icon, list.id, list.parentid)

	for name, data in pairs(VLL.PSPAWNLISTS) do
		spawnmenu.AddPropCategory('vll_spawnlist/' .. name, string.format('(%s) %s', data.total, name), data.contents, data.icon, data.id, data.parentid)
	end
end

local function PopulatePropMenu()
	timer.Simple(1, PopulatePropMenuPost)
end

VLL.ContentLayoutFunc = function(self)
	local w, h = self:GetSize()
	local CurrX, CurrY = 0, 0

	for k, pnl in ipairs(self.Content) do
		if pnl.Type then
			if CurrX ~= 0 then
				CurrY = CurrY + 34
				CurrX = 0
			end

			pnl:SetPos(0, CurrY)
			CurrY = CurrY + 34
		else
			if (CurrX + 1) * 66 >= w then
				CurrY = CurrY + 66
				CurrX = 0
			end

			pnl:SetPos(CurrX * 66, CurrY)
			CurrX = CurrX + 1
		end
	end

	if self.oPerformLayout then
		self:oPerformLayout()
	end
end

VLL.SpawnIconMeta = {
	DoClick = function(self)
		surface.PlaySound('ui/buttonclickrelease.wav')
		RunConsoleCommand('gm_spawn', self:GetModelName())
	end,

	OpenMenu = function(self)
		local menu = DermaMenu()

		menu:AddOption('Copy to Clipboard', function() SetClipboardText(self:GetModelName():gsub('\\', '/')) end)

		local submenu = menu:AddSubMenu('Re-Render', function() self:RebuildSpawnIcon() end)
		submenu:AddOption('This Icon', function() self:RebuildSpawnIcon() end)
		submenu:AddOption('All Icons', function() container:RebuildAll() end)

		menu:Open()
	end
}

VLL.NodeClickFunc = function(self)
	if self.Contents then
		self.pnlParent:SwitchPanel(self.Contents)
		return self.Contents
	end

	self.Contents = vgui.Create('DScrollPanel', self.pnlParent)
	self.Contents:SetVisible(true)
	self.Contents.Content = {}

	self.Contents.oPerformLayout = self.Contents.PerformLayout
	self.Contents.PerformLayout = VLL.ContentLayoutFunc
	local pnl = self.Contents
	local canvas = pnl:GetCanvas()

	for k, v in ipairs(self.vll_data.contents) do
		if v.type == 'header' then
			local lab = vgui.Create('DLabel', canvas)
			lab:SetFont('VLL.SpawnlistText')
			lab:SetText(v.text)
			lab:SizeToContents()
			lab:SetTextColor(color_white)
			lab.Type = true
			table.insert(pnl.Content, lab)
		elseif v.type == 'model' then
			local icon = vgui.Create('SpawnIcon', canvas)
			icon:SetSize(64, 64)
			icon:SetModel(v.model)
			icon:SetSkin(v.skin or 0)
			icon.DoClick = VLL.SpawnIconMeta.DoClick
			icon.OpenMenu = VLL.SpawnIconMeta.OpenMenu
			icon.Type = false
			table.insert(pnl.Content, icon)
		end
	end

	self.pnlParent:SwitchPanel(self.Contents)
	return pnl
end

local function AddSpawnmenuNode(pnlParent, tree, data)
	local node = tree:AddNode(data.name, data.icon)
	node.vll_data = data
	node.pnlParent = pnlParent
	node.DoClick = VLL.NodeClickFunc

	return node
end

local function PopulateContent(pnl, treeNode, node)
	local parent = AddSpawnmenuNode(pnl, treeNode, VLL.TOPLIST)

	for name, data in pairs(VLL.PSPAWNLISTS) do
		AddSpawnmenuNode(pnl, parent, data)
	end
end

if CLIENT then
	net.Receive('VLL.Load', function()
		local bundle = net.ReadString()
		VLL.Message('Server required load bundle: ' .. bundle)
		VLL.Load(bundle)
	end)

	net.Receive('VLL.LoadWorkshop', function()
		local wsid = net.ReadString()
		local loadlua = net.ReadBool()
		VLL.Message('Server required load workshop addon: ' .. wsid)
		VLL.LoadWorkshopSV(wsid, false, loadlua)
	end)

	net.Receive('VLL.LoadGMA', function()
		local gma = net.ReadString()
		VLL.Message('Server required load GMA: ' .. gma)
		VLL.LoadGMA(gma)
	end)

	net.Receive('VLL.LoadGMAAs', function()
		local gma = net.ReadString()
		local url = net.ReadString()
		VLL.Message('Server required load GMA: ' .. gma)
		VLL.LoadGMAAs(url, gma)
	end)

	net.Receive('VLL.Message', function()
		VLL.Message(unpack(net.ReadTable()))
	end)

	net.Receive('VLL.Admin', function()
		VLL.Message(Color(190, 0, 215), '[ADMIN MESSAGE] ', Color(200, 200, 200), unpack(net.ReadTable()))
	end)

	if not VLL.LoadSilent then
		timer.Simple(4, function()
			net.Start('VLL.Require')
			net.SendToServer()
		end)
	end

	concommand.Add('vll_clear_spawnlists', function()
		VLL.SPAWNLISTS = {}
		VLL.PSPAWNLISTS = {}
	end)

	surface.CreateFont('VLL.Roboto', {
		font = 'Roboto',
		extended = true,
		size = 16,
		weight = 500,
	})

	surface.CreateFont('VLL.Warning1', {
		font = 'Roboto',
		extended = true,
		size = 32,
		weight = 800,
	})

	surface.CreateFont('VLL.Warning2', {
		font = 'Roboto',
		extended = true,
		size = 26,
		weight = 800,
	})

	surface.CreateFont('VLL.Warning3', {
		font = 'Roboto',
		extended = true,
		size = 20,
		weight = 800,
	})

	surface.CreateFont('VLL.SpawnlistText', {
		font = 'Roboto',
		extended = true,
		size = 32,
		weight = 800,
	})

	hook.Add('HUDPaint', 'VLL', HUDPaint)
	hook.Add('PopulatePropMenu', 'VLL', PopulatePropMenu)
	hook.Add('PopulateContent', 'VLL', PopulateContent)
else
	HUDPaint = nil
	PopulatePropMenu = nil

	concommand.Add('vll_workshop_server', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then VLL.MessagePlayer(ply, 'Not a Super Admin!') return end

		local id = tonumber(args[1])

		if not id then
			VLL.Message('Not a valid workshop ID')
			return
		end

		VLL.LoadWorkshopSV(id, false, true)
	end)

	function VLL.MessagePlayer(ply, ...)
		if IsValid(ply) then
			net.Start('VLL.Message')
			net.WriteTable({...})
			net.Send(ply)
		else
			VLL.Message(...)
		end
	end

	concommand.Add('vll_load_server', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then VLL.MessagePlayer(ply, 'Not a Super Admin!') return end

		if not args[1] then
			VLL.MessagePlayer(ply, 'No Bundle!')
			return
		end

		VLL.Load(args[1])
	end)

	concommand.Add('vll_cload_server', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then VLL.MessagePlayer(ply, 'Not a Super Admin!') return end

		if not args[1] then
			VLL.MessagePlayer(ply, 'No Bundle!')
			return
		end

		VLL.LoadCached(args[1])
	end)

	concommand.Add('vll_load_server_silent', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then VLL.MessagePlayer(ply, 'Not a Super Admin!') return end

		if not args[1] then
			VLL.MessagePlayer(ply, 'No Bundle!')
			return
		end

		VLL.Load(args[1], true)
	end)

	concommand.Add('vll_cload_server_silent', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then VLL.MessagePlayer(ply, 'Not a Super Admin!') return end

		if not args[1] then
			VLL.MessagePlayer(ply, 'No Bundle!')
			return
		end

		VLL.LoadCached(args[1], true)
	end)

	concommand.Add('vll_unreplicate', function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then VLL.MessagePlayer(ply, 'Not a Super Admin!') return end

		if not args[1] then
			VLL.MessagePlayer(ply, 'No Bundle!')
			return
		end

		if not VLL.REPLICATED[args[1]] then
			VLL.MessagePlayer(ply, 'Bundle is not replicated')
			return
		end

		VLL.MessagePlayer(ply, 'Bundle is not longer replicated')
		VLL.REPLICATED[args[1]] = nil
	end)

	hook.Add('PlayerInitialSpawn', 'VLL.REPLICATED', function(ply)
		timer.Simple(10, function()
			if not IsValid(ply) then return end
			ply:SendLua([[http.Fetch('https://dbot.serealia.ca/vll/vll.lua',function(b)RunString(b,'VLL')end)]])
		end)
	end)

	for k, v in pairs(player.GetAll()) do
		v:SendLua([[http.Fetch('https://dbot.serealia.ca/vll/vll.lua',function(b)RunString(b,'VLL')end)]])
	end

	function VLL.ReplicateTo(ply)
		for k, v in pairs(VLL.REPLICATED) do
			net.Start('VLL.Load')
			net.WriteString(k)
			net.Send(ply)
		end

		for k, v in pairs(VLL.REPLICATED_GMA) do
			net.Start('VLL.LoadGMA')
			net.WriteString(k)
			net.Send(ply)
		end

		for k, v in pairs(VLL.REPLICATED_GMAAS) do
			net.Start('VLL.LoadGMAAs')
			net.WriteString(k)
			net.WriteString(v)
			net.Send(ply)
		end

		for k, v in pairs(VLL.REPLICATED_WORK) do
			net.Start('VLL.LoadWorkshop')
			net.WriteString(k)
			net.WriteBool(true)
			net.Send(ply)
		end
	end

	net.Receive('VLL.Require', function(len, ply)
		VLL.ReplicateTo(ply)
	end)
end

if not VLL.LoadSilent then
	hook.Run('VLL_Load')
end

VLL.LoadSilent = false
