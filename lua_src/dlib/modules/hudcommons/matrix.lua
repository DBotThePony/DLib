
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

local clippingStack = 0
local HUDCommons = DLib.HUDCommons
local cam = cam
local surface = surface
local Matrix = Matrix

--[[
	@doc
	@fname DLib.HUDCommons.DrawMatrix
	@args number x, number y, Angle angle

	@client

	@desc
	quick alias for creating new !g:Matrix, rotating it and calling !g:cam.PushModelMatrix
	@enddesc
]]
function HUDCommons.DrawMatrix(x, y, ang)
	local matrix = Matrix()
	matrix:Translate(Vector(x, y, 0))
	matrix:Rotate(ang)
	cam.PushModelMatrix(matrix)
	clippingStack = clippingStack + 1
	surface.DisableClipping(true)
end

--[[
	@doc
	@fname DLib.HUDCommons.DrawCenteredMatrix
	@args number x, number y, number width, number height, Angle angle

	@client

	@desc
	same as `DLib.HUDCommons.DrawMatrix` but rotates matrix around it's center based on `width` and `height`
	@enddesc
]]
function HUDCommons.DrawCenteredMatrix(x, y, width, height, ang)
	local matrix = Matrix()
	matrix:Translate(Vector(x + width / 2, y - height, 0))
	matrix:Rotate(ang)
	matrix:Translate(Vector(-width / 2, height, 0))
	cam.PushModelMatrix(matrix)
	clippingStack = clippingStack + 1
	surface.DisableClipping(true)
end

--[[
	@doc
	@fname DLib.HUDCommons.DrawCustomMatrix
	@args number x, number y

	@client

	@desc
	`DLib.HUDCommons.DrawMatrix` but with predefined angle based on current HUD shift
	@enddesc
]]
function HUDCommons.DrawCustomMatrix(x, y)
	HUDCommons.DrawMatrix(x, y, HUDCommons.MatrixAngle(0.1))
end

--[[
	@doc
	@fname DLib.HUDCommons.DrawCustomCenteredMatrix
	@args number x, number y, number width, number height

	@client

	@desc
	`DLib.HUDCommons.DrawCenteredMatrix` but with predefined angle based on current HUD shift
	@enddesc
]]
function HUDCommons.DrawCustomCenteredMatrix(x, y, width, height)
	HUDCommons.DrawCenteredMatrix(x, y, width, height, HUDCommons.MatrixAngle(0.1))
end

--[[
	@doc
	@fname DLib.HUDCommons.MatrixAngle
	@args number mult = 1

	@client

	@returns
	Angle
]]
function HUDCommons.MatrixAngle(mult)
	return Angle(0, HUDCommons.Position2.ShiftX * (mult or 1), 0)
end

--[[
	@doc
	@fname DLib.HUDCommons.PositionDrawMatrix
	@args string elemID

	@client
	@deprecated

	@desc
	`DLib.HUDCommons.DrawMatrix` called with x, y of `elemID` position in `Position` submodule
	@enddesc
]]
function HUDCommons.PositionDrawMatrix(elem)
	local x, y = HUDCommons.GetPos(elem)
	HUDCommons.DrawMatrix(x, y, HUDCommons.MatrixAngle())
end

--[[
	@doc
	@fname DLib.HUDCommons.PopDrawMatrix

	@client

	@desc
	call this if you called `DLib.HUDCommons.DrawMatrix` before (or anything about matrix pushing from HUDCommons)
	@enddesc
]]
function HUDCommons.PopDrawMatrix()
	clippingStack = math.max(clippingStack - 1, 0)
	cam.PopModelMatrix()
	surface.DisableClipping(clippingStack == 0)
end
