
-- Copyright (C) 2017 DBot

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

local net = DLib.netModule
local net_graph = GetConVar('net_graph')

local ipairs = ipairs
local pairs = pairs
local table = table
local math = math
local ScrW, ScrH = ScrW, ScrH
local surface = surface
local string = string

net.GraphNodesMax = 100
net.Graph = {}
net.GraphChannels = net.GraphChannels or {}
net.GraphGroups = net.GraphGroups or {}

local minimalScale = 5 * 1024
local scale = minimalScale

local averageUpload = 0
local averageDownload = 0
local frameUpload = 0
local frameDownload = 0

function net.RecalculateGraphScales()
	local total = 0
	local max = 0
	local num = math.max(#net.Graph, 1)

	for i, frame in ipairs(net.Graph) do
		total = total + frame.__TOTAL

		if max < frame.__TOTAL then
			max = frame.__TOTAL
		end
	end

	averageDownload = total / num
	scale = math.max(max * 1.25, minimalScale)
	frameDownload = net.Graph[#net.Graph].__TOTAL
end

function net.RegisterGraphGroup(groupName, groupID, colorSeed)
	groupID = groupID or groupName
	groupID = groupID:lower()
	colorSeed = colorSeed or groupID
	net.GraphGroups[groupID] = net.GraphGroups[groupID] or {}
	local t = net.GraphGroups[groupID]
	t.name = groupName
	t.id = groupID
	t.color = ColorFromSeed(colorSeed)
	return t
end

function net.BindMessageGroup(networkID, groupID)
	groupID = groupID:lower()
	networkID = networkID:lower()
	net.GraphGroups[groupID] = net.GraphGroups[groupID] or {}
	net.GraphChannels[networkID] = net.GraphGroups[groupID]
end

local abscissaColor = Color(200, 200, 200, 150)
local textColorLevel = Color(200, 200, 200)
local totalColor = Color(0, 0, 0)

surface.CreateFont('DLib.NetGraphLevel', {
	font = 'Roboto',
	size = 16,
	weight = 400
})

surface.CreateFont('DLib.NetGraphTypes', {
	font = 'Roboto',
	size = 18,
	weight = 500
})

local function HUDPaint()
	if net_graph:GetInt() < 5 then return end
	local W, H = ScrW(), ScrH()
	local nodeStep = (W - 100) / net.GraphNodesMax
	local abscissa = H * 0.75

	local graphTop = H * 0.2

	local S, E = abscissa, graphTop
	local diff = S - E

	surface.SetDrawColor(abscissaColor)
	surface.SetTextColor(textColorLevel)
	surface.SetFont('DLib.NetGraphLevel')

	for i = S, E, H * (-0.13) do
		local perc = (S - i) / diff

		surface.DrawRect(W - 100, i, 40, 5)
		surface.SetTextPos(W - 100, i - 20)
		surface.DrawText(string.format('%.3f kb/s', scale * perc / 1024))
	end

	surface.DrawRect(0, abscissa, W, 5)

	local prevNodes = {}
	local hitGroups
	local allGroups = {}

	local function doDrawGraph(i, group, value)
		if group == '__TOTAL' then group = '__total' end
		local color, lastX, lastY
		local prev = prevNodes[group]
		local x, y = i * nodeStep, S - value / scale * diff

		if prev then
			lastX, lastY = prev[1], prev[2]
		else
			lastX, lastY = (i - 1) * nodeStep, S
		end

		prevNodes[group] = {x, y}
		color = net.GraphGroups[group].color

		surface.SetDrawColor(color)
		surface.DrawLine(lastX, lastY, x, y)
	end

	for i, frame in ipairs(net.Graph) do
		hitGroups = {}

		for group, value in pairs(frame) do
			doDrawGraph(i, group, value)
			hitGroups[group] = true
		end

		for group, data in pairs(prevNodes) do
			if not hitGroups[group] then
				data[1] = (i - 1) * nodeStep
				data[2] = S
				doDrawGraph(i, group, 0)
			end
		end
	end

	local tx, ty = 10, abscissa + 20
	surface.SetFont('DLib.NetGraphTypes')

	for group, _ in pairs(prevNodes) do
		surface.SetTextColor(net.GraphGroups[group].color)
		surface.SetTextPos(tx, ty)
		local t = net.GraphGroups[group].name
		surface.DrawText(t)
		local w, h = surface.GetTextSize(t)
		tx = tx + 20 + w

		if tx >= W - 60 then
			tx = 10
			ty = ty + 20
		end
	end
end

hook.Add('HUDPaint', 'DLib.NetGraph', HUDPaint)

-- Some known group
net.RegisterGraphGroup('Other').color = Color(255, 255, 255)
net.RegisterGraphGroup('Total', '__TOTAL').color = totalColor
net.RegisterGraphGroup('Usermessages')

-- some known messages
net.BindMessageGroup('dlib.umsg', 'Usermessages')
