
--
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


local LocalPlayer = LocalPlayer
local HUDCommons = DLib.HUDCommons
local IsValid = IsValid
local math = math

--[[
	@doc
	@fname DLib.HUDCommons.SelectPlayer

	@client

	@desc
	use this instead of !g:LocalPlayer in HUDs
	@enddesc

	@returns
	Player: the player from which eyes we are currently looking
]]
function HUDCommons.SelectPlayer()
	local ply = LocalPlayer()
	if not IsValid(ply) then return ply end
	local obs = ply:GetObserverTarget()

	if IsValid(obs) and obs:IsPlayer() then
		return obs
	else
		return ply
	end
end

--[[
	@doc
	@fname DLib.HUDCommons.TranslatePolyMatrix
	@args table matrix, number x, number y

	@client

	@desc
	moves x and y coordinates of !s:PolygonVertex
	@enddesc

	@returns
	table: matrix
]]
function HUDCommons.TranslatePolyMatrix(data, x, y)
	for i, vertex in ipairs(data) do
		vertex.x, vertex.y = vertex.x + x, vertex.y + y
	end

	return data
end

--[[
	@doc
	@fname DLib.HUDCommons.RotatePolyMatrix
	@args table matrix, number rotateBy

	@client

	@desc
	rotates all x and y points of !s:PolygonVertex relative 0, 0
	`rotateBy` is a degree number, not radian
	@enddesc

	@returns
	table: matrix
]]
function HUDCommons.RotatePolyMatrix(data, rotateBy)
	if rotateBy == 0 then return data end

	local deg = rotateBy:rad()
	local sin, cos = deg:sin(), deg:cos()

	for i, vertex in ipairs(data) do
		local x, y = vertex.x, vertex.y

		local xn = x * cos - y * sin
		local yn = x * sin + y * cos

		vertex.x, vertex.y = xn, yn
	end

	return data
end
