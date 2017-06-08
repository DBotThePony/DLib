
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

function HUDCommons.DrawBox(x, y, w, h, color)
	if color then
		surface.SetDrawColor(color)
	end
	
	surface.DrawRect(x, y, w, h)
end

function HUDCommons.SimpleText(text, font, x, y, col)
	if col then 
		surface.SetTextColor(col)
	end
	
	if font then
		surface.SetFont(font)
	end
	
	surface.SetTextPos(x, y)
	surface.DrawText(text)
end

function HUDCommons.SkyrimBar(x, y, w, h, color)
	HUDCommons.DrawBox(x - w / 2, y, w, h, color)
end

function HUDCommons.WordBox(text, font, x, y, col, colBox, center)
	if font then
		surface.SetFont(font)
	end
	
	if col then
		surface.SetTextColor(col)
	end
	
	local w, h = surface.GetTextSize(text)
	
	if center then
		x = x - w / 2
	end
	
	HUDCommons.DrawBox(x - 4, y - 2, w + 8, h + 4, colBox)
	surface.SetTextPos(x, y)
	surface.DrawText(text)
end
