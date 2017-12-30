
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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

DLib.skin.icon = {key, (-> table.frandom(value)) for key, value in pairs DLib.skin.icons}
