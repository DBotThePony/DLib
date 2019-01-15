
moonc -t . bundle.moon fs.moon init.moon util.moon vm_def.moon vm.moon commands.moon hud.moon

echo "
-- Copyright (C) 2018 DBot

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the \"Software\"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- To Load VLL2 you can use any of these commands:
-- lua_run http.Fetch(\"https://dbotthepony.ru/vll/vll2.lua\",function(b)RunString(b,\"VLL2\")end,function(err)print(\"VLL2\",err)end)
-- rcon lua_run \"http.Fetch([[https:]]..string.char(47)..[[/dbotthepony.ru/vll/vll2.lua]],function(b)RunString(b,[[VLL2]])end,function(err)print([[VLL2]],err)end)\"
-- http.Fetch('https://dbotthepony.ru/vll/vll2.lua',function(b)RunString(b,'VLL2')end,function(err)print('VLL2',err)end)
-- ulx luarun \"http.Fetch('https://dbotthepony.ru/vll/vll2.lua',function(b)RunString(b,'VLL2')end,function(err)print('VLL2',err)end)\"

local __cloadStatus, _cloadError = pcall(function()
" > vll2.lua

cat init.lua >> vll2.lua

echo "
end)

if not __cloadStatus then
	print('UNABLE TO LOAD VLL2 CORE')
	print('LOAD CAN NOT CONTINUE')
	print('REASON:')
	print(_cloadError)
	return
end

VLL2.Message('Starting up...')
local ___status, ___err = pcall(function()" >> vll2.lua
cat util.lua >> vll2.lua
echo "end)
if not ___status then
	VLL2.Message('STARTUP FAILURE AT UTIL: ', ___err)
end" >> vll2.lua

echo "___status, ___err = pcall(function()" >> vll2.lua
cat fs.lua >> vll2.lua
echo "end)
if not ___status then
	VLL2.Message('STARTUP FAILURE AT FILE SYSTEM: ', ___err)
end" >> vll2.lua

echo "___status, ___err = pcall(function()" >> vll2.lua
cat bundle.lua >> vll2.lua
echo "end)
if not ___status then
	VLL2.Message('STARTUP FAILURE AT BUNDLE: ', ___err)
end" >> vll2.lua

echo "___status, ___err = pcall(function()" >> vll2.lua
cat vm_def.lua >> vll2.lua
echo "end)
if not ___status then
	VLL2.Message('STARTUP FAILURE AT VM DEFINITION: ', ___err)
end" >> vll2.lua

echo "___status, ___err = pcall(function()" >> vll2.lua
cat vm.lua >> vll2.lua
echo "end)
if not ___status then
	VLL2.Message('STARTUP FAILURE AT VM: ', ___err)
end" >> vll2.lua

echo "
if CLIENT then
	___status, ___err = pcall(function()" >> vll2.lua
	cat hud.lua >> vll2.lua
	echo "end)
	if not ___status then
		VLL2.Message('STARTUP FAILURE AT HUD: ', ___err)
	end
end" >> vll2.lua

echo "___status, ___err = pcall(function()" >> vll2.lua
cat commands.lua >> vll2.lua
echo "end)
if not ___status then
	VLL2.Message('STARTUP FAILURE AT COMMANDS: ', ___err)
end

VLL2.Message('Startup finished')
hook.Run('VLL2.Loaded')
" >> vll2.lua
