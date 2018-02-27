
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

if SERVER then return end

local render = render
local assert = assert
local type = type

-- nope, nu stack object, because util.Stack() sux
local stack = {}

function render.PushScissorRect(x, y, xEnd, yEnd)
	x = assert(type(x) == 'number' and x, 'x must be a number!')
	y = assert(type(y) == 'number' and y, 'y must be a number!')
	xEnd = assert(type(xEnd) == 'number' and xEnd, 'xEnd must be a number!')
	yEnd = assert(type(yEnd) == 'number' and yEnd, 'xEnd must be a number!')

	local top = stack[#stack]

	if top then
		x = math.max(top[1], x)
		y = math.max(top[2], y)
		xEnd = math.min(top[3], xEnd)
		yEnd = math.min(top[4], yEnd)
	end

	table.insert(stack, {x, y, xEnd, yEnd})
	render.SetScissorRect(x, y, xEnd, yEnd, true)
end

function render.PopScissorRect()
	if #stack == 0 then
		render.SetScissorRect(0, 0, 0, 0, false)
	end

	local pop = table.remove(stack, #stack)
	render.SetScissorRect(pop[1], pop[2], pop[3], pop[4], false)
end

local function PreRender()
	if #stack == 0 then return end
	stack = {}
end

hook.Add('PreRender', 'render.PushScissorRect', PreRender)
