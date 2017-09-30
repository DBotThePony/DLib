
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

local util = DLib.module('util', 'util')

function util.copy(var)
	if type(var) == 'table' then return table.Copy(var) end
	if type(var) == 'Angle' then return Angle(var.p, var.y, var.r) end
	if type(var) == 'Vector' then return Vector(var) end
	return var
end

function util.randomVector(mx, my, mz)
	return Vector(math.Rand(-mx, mx), math.Rand(-my, my), math.Rand(-mz, mz))
end

return util
