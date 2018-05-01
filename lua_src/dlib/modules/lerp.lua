
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

local Lerp = Lerp
local math = math

function _G.LerpQuintic(t, a, b)
	if t < 0 then return a end
	if t >= 1 then return b end
	local value = t * t * t * (t * (t * 6 - 15) + 10)
	return Lerp(math.min(1, value), a, b)
end

function _G.Quintic(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

function _G.LerpCosine(t, a, b)
	if t < 0 then return a end
	if t >= 1 then return b end
	local value = (1 - math.cos(t * math.pi)) / 2
	return Lerp(math.min(1, value), a, b)
end

function _G.Cosine(t)
	return (1 - math.cos(t * math.pi)) / 2
end

function _G.LerpSinusine(t, a, b)
	if t < 0 then return a end
	if t >= 1 then return b end
	local value = (1 - math.sin(t * math.pi)) / 2
	return Lerp(math.min(1, value), a, b)
end

function _G.Sinusine(t)
	return (1 - math.sin(t * math.pi)) / 2
end

function _G.LerpCubic(t, a, b)
	if t < 0 then return a end
	if t >= 1 then return b end
	local value = -2 * t * t * t + 3 * t * t
	return Lerp(math.min(1, value), a, b)
end

function _G.Cubic(t)
	return -2 * t * t * t + 3 * t * t
end
