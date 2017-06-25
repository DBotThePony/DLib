
--
-- Copyright (C) 2017 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local clippingStack = 0

function HUDCommons.DrawMatrix(x, y, ang)
    local matrix = Matrix()
    matrix:Translate(Vector(x, y, 0))
    matrix:Rotate(ang)
    cam.PushModelMatrix(matrix)
    clippingStack = clippingStack + 1
    surface.DisableClipping(true)
end

function HUDCommons.DrawCenteredMatrix(x, y, width, height, ang)
    local matrix = Matrix()
    matrix:Translate(Vector(x + width / 2, y - height, 0))
    matrix:Rotate(ang)
    matrix:Translate(Vector(-width / 2, height, 0))
    cam.PushModelMatrix(matrix)
    clippingStack = clippingStack + 1
    surface.DisableClipping(true)
end

function HUDCommons.DrawCustomMatrix(x, y)
    HUDCommons.DrawMatrix(x, y, HUDCommons.MatrixAngle(0.1))
end

function HUDCommons.DrawCustomCenteredMatrix(x, y, width, height)
    HUDCommons.DrawCenteredMatrix(x, y, width, height, HUDCommons.MatrixAngle(0.1))
end

function HUDCommons.MatrixAngle(mult)
    return Angle(0, HUDCommons.ShiftX * (mult or 1), 0)
end

function HUDCommons.PositionDrawMatrix(elem)
    local x, y = HUDCommons.GetPos(elem)
    HUDCommons.DrawMatrix(x, y, HUDCommons.MatrixAngle())
end

function HUDCommons.PopDrawMatrix()
    clippingStack = math.max(clippingStack - 1, 0)
    cam.PopModelMatrix()
    surface.DisableClipping(clippingStack == 0)
end
