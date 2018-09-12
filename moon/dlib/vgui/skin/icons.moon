
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


DLib = DLib
Color = Color
table = table

DLib.skin.icons = {}

DLib.skin.icons.flags = ["icon16/flag_#{color}.png" for color in *{'blue', 'green', 'orange', 'pink', 'purple', 'red', 'yellow'}]
DLib.skin.icons.tags = ["icon16/tag_#{color}.png" for color in *{'blue', 'green', 'orange', 'pink', 'purple', 'red', 'yellow'}]
DLib.skin.icons.tag = DLib.skin.icons.tags
DLib.skin.icons.copy = DLib.skin.icons.tags
DLib.skin.icons.bugs = ["icon16/#{n}.png" for n in *{'bug', 'bug_go', 'bug_delete', 'bug_error'}]
DLib.skin.icons.url = {'icon16/link.png'}
DLib.skin.icons.bug = DLib.skin.icons.bugs
DLib.skin.icons.user = 'icon16/user.png'

DLib.skin.icon = {key, (-> table.frandom(value)) for key, value in pairs DLib.skin.icons}
