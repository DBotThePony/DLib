
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
	size = 14,
	extended = true,
})

local list = {}

local DLib = DLib
local Util = DLib.Util

Util.DisplayProgressList = Util.DisplayProgressList or {}

local assert = assert
local isstring = isstring
local table = table
local DisplayProgressList = Util.DisplayProgressList

local max_width = 200
local total_tall = 0

for _, data in pairs(DisplayProgressList) do
	table.insert(list, data)
	max_width = max_width:max(data[4])
	total_tall = total_tall + data[5]
end

max_width = max_width + 40

function Util.PushProgress(identifier, text, progress)
	assert(isstring(identifier), 'isstring(identifier)')
	assert(isstring(text), 'isstring(text)')

	progress = progress or 0

	if not DisplayProgressList[identifier] then
		surface.SetFont('DLib_LoadingNotify')

		local data = {
			identifier, text, progress, surface.GetTextSize(text)
		}

		table.insert(list, data)
		DisplayProgressList[identifier] = data

		max_width = 200
		total_tall = 0

		for i = 1, #list do
			max_width = max_width:max(list[i][4])
			total_tall = total_tall + list[i][5]
		end

		return
	end

	DisplayProgressList[identifier][2] = text
	DisplayProgressList[identifier][3] = progress
	surface.SetFont('DLib_LoadingNotify')
	DisplayProgressList[identifier][4], DisplayProgressList[identifier][4] = surface.GetTextSize(text)

	max_width = 200
	total_tall = 0

	for i = 1, #list do
		max_width = max_width:max(list[i][4])
		total_tall = total_tall + list[i][5]
	end

	max_width = max_width + 40
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

	max_width = 200
	total_tall = 0

	for i = 1, #list do
		max_width = max_width:max(list[i][4])
		total_tall = total_tall + list[i][5]
	end

	max_width = max_width + 40
end

local HUDCommons = DLib.HUDCommons
local render = render
local surface = surface
local draw = draw

local function HUDPaint()
	if #list == 0 then return end

	surface.SetFont('DLib_LoadingNotify')

	local Y = 0
	local ScrH = ScrH()
	local ScrW = ScrW()

	surface.SetDrawColor(0, 0, 0)
	surface.DrawRect(0, 0, max_width, total_tall)

	for i = 1, #list do
		local data = list[i]
		local text = data[2]
		local progress = data[3]

		local tall = select(2, surface.GetTextSize(text))

		surface.SetDrawColor(0, 100, 0)
		surface.DrawRect(0, Y, max_width * progress, tall)

		render.SetScissorRect(0, Y, max_width * progress, ScrH, true)

		HUDCommons.DrawLoading(2, Y + 2, tall - 4, color2, 16, 4)
		draw.SimpleText(text, 'DLib_LoadingNotify', 32, Y, color2)

		render.SetScissorRect(max_width * progress, 0, ScrW, ScrH, true)

		HUDCommons.DrawLoading(2, Y + 2, tall - 4, color, 16, 4)
		draw.SimpleText(text, 'DLib_LoadingNotify', 32, Y, color)

		render.SetScissorRect(0, 0, 0, 0, false)

		Y = Y + tall
	end
end

hook.Add('HUDPaint', 'DLib Draw Loading Notification', HUDPaint, 4)
