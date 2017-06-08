
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

HUDCommons.BarData = HUDCommons.BarData or {}

local function InInterval(val, min, max)
	return val > min and val < max
end

function HUDCommons.SoftBar(x, y, w, h, color, name)
	HUDCommons.BarData[name] = HUDCommons.BarData[name] or w
	
	local delta = w - HUDCommons.BarData[name]
	
	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta * .1 * HUDCommons.Multipler
	else
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta
	end
	
	HUDCommons.DrawBox(x, y, HUDCommons.BarData[name], h, color)
end

function HUDCommons.SoftSkyrimBar(x, y, w, h, color, name, speed)
	speed = speed or .1
	HUDCommons.BarData[name] = HUDCommons.BarData[name] or w
	
	local delta = w - HUDCommons.BarData[name]
	
	if not InInterval(delta, -0.3, 0.3) then
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta * speed * HUDCommons.Multipler
	else
		HUDCommons.BarData[name] = HUDCommons.BarData[name] + delta
	end
	
	HUDCommons.DrawBox(x - HUDCommons.BarData[name] / 2, y, HUDCommons.BarData[name], h, color)
end
