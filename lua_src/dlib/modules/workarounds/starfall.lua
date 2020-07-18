
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

local function patch()
	if not istable(SF) then return end
	SF._DLib_OnRunningOps = SF._DLib_OnRunningOps or SF.OnRunningOps or function() end

	local whitelisted_functions = {
		-- built-in / C
		'ceil',
		'tan',
		'sinh',
		'min',
		'fmod',
		'log',
		'sqrt',
		'atan',
		'randomseed',
		'Min', -- garry, please
		'log10',
		'ldexp',
		'atan2',
		'frexp',
		'exp',
		'random',
		'cos',
		'mod',
		'asin',
		'Max', -- garry, please
		'abs',
		'tanh',
		'pow',
		'cosh',
		'acos',
		'max',
		'floor',
		'modf',
		'sin',

		-- MEGALUL ????
		'deg',
		'rad',

		-- DLib
		'tformatVararg',
		'untformat',
		'bezier',
		'average',
		'tostring',
		'progression',
		'tonumber',
		'dateToTimestamp',
		'untformatVararg',
		'tformat',
		'tbezier',
		'equal',

		-- gmod
		'clamp',
		'Clamp',
		'AngleDifference',
		'angleDifference',
		'NormalizeAngle',
		'normalizeAngle',
		'Round',
		'round',
		'Distance',
		'distance',
	}

	whitelisted_functions = table.flipIntoHash(whitelisted_functions)

	local meta = debug.getmetatable(0)

	if istable(meta) then
		meta.__dlib_sf_patch = true
	end

	local function on_run()
		local meta = debug.getmetatable(0)

		if istable(meta) then
			meta.__dlib_sf_patch = true
		end

		if istable(meta) and isfunction(meta.__index) and isstring(debug.getinfo(meta.__index).source) and string.find(debug.getinfo(meta.__index).source, 'starfall/sflib.lua', 1, true) then
			local bit = bit
			local math = math

			meta.__index_sf_patch = meta.__index_sf_patch or meta.__index

			function meta:__index(key)
				if bit[key] then
					return bit[key]
				end

				if whitelisted_functions[key] then
					return math[key]
				end
			end
		end
	end

	local function on_stop()
		local meta = debug.getmetatable(0)

		if istable(meta) then
			meta.__dlib_sf_patch = true
		end

		if istable(meta) and isfunction(meta.__index_sf_patch) then
			meta.__index = meta.__index_sf_patch
			meta.__index_sf_patch = nil
		end
	end

	function SF.OnRunningOps(new_state, ...)
		if new_state == true then
			on_run()
		elseif not new_state then
			on_stop()
		end

		return SF._DLib_OnRunningOps(new_state, ...)
	end
end

patch()
timer.Simple(0, patch)
