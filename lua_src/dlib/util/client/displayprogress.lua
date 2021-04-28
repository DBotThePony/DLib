
-- Copyright (C) 2017-2020 DBotThePony

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

local color = Color(127, 127, 127)
local color2 = Color()

surface.DLibCreateFont('DLib_LoadingNotify', {
	font = 'Roboto',
	size = 7,
	minimum_size = 9,
	extended = true,
})

local list = {}

local DLib = DLib
local Util = DLib.Util
local math_max = math.max

Util.DisplayProgressList = Util.DisplayProgressList or {}

local assert = assert
local isstring = isstring
local table = table
local DisplayProgressList = Util.DisplayProgressList

local max_width = 100
local next_width_update = 0
local total_tall = 0

local function ComputeSizes()
	max_width = next_width_update > SysTime() and max_width or 100
	total_tall = 0

	for i = 1, #list do
		local computed = list[i][4] + list[i][5] + 20

		if computed >= max_width then
			max_width = computed
			next_width_update = SysTime() + 5
		end

		total_tall = total_tall + list[i][5] + 4
	end
end

for _, data in pairs(DisplayProgressList) do
	table.insert(list, data)
	max_width = max_width:max(data[4] + data[5] + 20)
	total_tall = total_tall + data[5] + 4
end

function Util.PushProgress(identifier, text, progress)
	assert(isstring(identifier), 'isstring(identifier)')
	assert(isstring(text), 'isstring(text)')

	progress = progress or 0
	assert(isnumber(progress), 'isnumber(progress)')

	if not DisplayProgressList[identifier] then
		surface.SetFont('DLib_LoadingNotify')

		local a, b = surface.GetTextSize(text)

		local data = {
			identifier, text, progress:clamp(0, 1), a, b, SysTime() + 10, SysTime() + 13
		}

		table.insert(list, data)
		DisplayProgressList[identifier] = data

		ComputeSizes()
		return
	end

	DisplayProgressList[identifier][2] = text
	DisplayProgressList[identifier][3] = progress:clamp(0, 1)
	surface.SetFont('DLib_LoadingNotify')
	DisplayProgressList[identifier][4], DisplayProgressList[identifier][5] = surface.GetTextSize(text)
	DisplayProgressList[identifier][6] = SysTime() + 10
	DisplayProgressList[identifier][7] = SysTime() + 13

	ComputeSizes()
end

function Util.PopProgress(identifier)
	assert(isstring(identifier), 'isstring(identifier)')

	if not DisplayProgressList[identifier] then return end

	local search = DisplayProgressList[identifier]

	for i = 1, #list do
		if list[i] == search then
			table.remove(list, i)
			break
		end
	end

	DisplayProgressList[identifier] = nil

	ComputeSizes()
end

local HUDCommons = DLib.HUDCommons
local render = render
local surface = surface
local draw = draw
local ScrH = ScrH
local ScrW = ScrW

local function HUDPaint()
	if #list == 0 then return end

	local time = SysTime()

	if next_width_update < time then
		ComputeSizes()
	end

	surface.SetFont('DLib_LoadingNotify')

	local Y = 0
	local ScrH = ScrH()
	local ScrW = ScrW()

	local max_alpha = 0

	for i = 1, #list do
		local data = list[i]
		local alpha = 255

		if data[6] < time then
			alpha = 255 - time:progression(data[6], data[7]) * 255

			if alpha <= 0 then
				Util.PopProgress(data[1])
				break
			end
		end

		max_alpha = math_max(max_alpha, alpha)
		if max_alpha == 255 then break end
	end

	surface.SetDrawColor(0, 0, 0, max_alpha)
	surface.DrawRect(0, 0, max_width, total_tall)

	for i = 1, #list do
		local data = list[i]
		local alpha = 255

		if data[6] < time then
			alpha = 255 - time:progression(data[6], data[7]) * 255
		end

		color.a = alpha
		color2.a = alpha

		local text = data[2]
		local progress = data[3]

		local tall = select(2, surface.GetTextSize(text)) + 4

		surface.SetDrawColor(0, 100, 0, alpha)
		surface.DrawRect(0, Y, max_width * progress, tall)

		render.SetScissorRect(0, Y, max_width * progress, ScrH, true)

		HUDCommons.DrawLoading(2, Y + 2, tall - 4, color2, 16, 4)
		draw.DrawText(text, 'DLib_LoadingNotify', tall + 6, Y + 2, color2)

		render.SetScissorRect(max_width * progress, 0, ScrW, ScrH, true)

		HUDCommons.DrawLoading(2, Y + 2, tall - 4, color, 16, 4)
		draw.DrawText(text, 'DLib_LoadingNotify', tall + 6, Y + 2, color)

		render.SetScissorRect(0, 0, 0, 0, false)

		Y = Y + tall
	end
end

hook.Add('HUDPaint', 'DLib Draw Loading Notification', HUDPaint, 4)
