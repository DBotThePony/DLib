
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
local table = table
local debug = debug

-- nope, nu stack object, because util.Stack() sux
local stack = {}

function render.PushScissorRect(x, y, xEnd, yEnd)
	x = assert(type(x) == 'number' and x, 'x must be a number!')
	y = assert(type(y) == 'number' and y, 'y must be a number!')
	xEnd = assert(type(xEnd) == 'number' and xEnd, 'xEnd must be a number!')
	yEnd = assert(type(yEnd) == 'number' and yEnd, 'xEnd must be a number!')
	local amount = #stack

	if amount ~= 0 then
		local x2, y2, xEnd2, yEnd2 = stack[amount - 4], stack[amount - 3], stack[amount - 2], stack[amount - 1]

		x = x2:max(x)
		y = y2:max(y)
		xEnd = xEnd2:min(xEnd)
		yEnd = yEnd2:min(yEnd)
	end

	table.insert(stack, x)
	table.insert(stack, y)
	table.insert(stack, xEnd)
	table.insert(stack, yEnd)
	table.insert(stack, debug.traceback())
	render.SetScissorRect(x, y, xEnd, yEnd, true)
end

function render.PopScissorRect()
	if #stack == 0 then
		render.SetScissorRect(0, 0, 0, 0, false)
		return
	end

	if #stack == 5 then
		table.remove(stack)
		table.remove(stack)
		table.remove(stack)
		table.remove(stack)
		table.remove(stack)
		render.SetScissorRect(0, 0, 0, 0, false)
		return
	end

	table.remove(stack)
	table.remove(stack)
	table.remove(stack)
	table.remove(stack)
	table.remove(stack)
	local amount = #stack
	local x, y, xEnd, yEnd = stack[amount - 4], stack[amount - 3], stack[amount - 2], stack[amount - 1]
	render.SetScissorRect(x, y, xEnd, yEnd, true)
end

local function PreRender()
	if #stack ~= 0 then
		for i = 5, #stack, 5 do
			print(stack[i])
		end

		stack = {}
	end
end

hook.Add('PreRender', 'render.PushScissorRect', PreRender)
