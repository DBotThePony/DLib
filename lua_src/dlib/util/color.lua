
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

function DLib.LerpColor(lerpValue, lerpFrom, lerpTo, affertAlpha)
	if affertAlpha then
		local r1, g1, b1, a1 = lerpFrom.r, lerpFrom.g, lerpFrom.b, lerpFrom.a
		local r2, g2, b2, a2 = lerpTo.r, lerpTo.g, lerpTo.b, lerpTo.a
		local r, g, b, a = Lerp(lerpValue, r1, r2), Lerp(lerpValue, g1, g2), Lerp(lerpValue, b1, b2), Lerp(lerpValue, a1, a2)
		return Color(r, g, b, a)
	else
		local r1, g1, b1 = lerpFrom.r, lerpFrom.g, lerpFrom.b
		local r2, g2, b2 = lerpTo.r, lerpTo.g, lerpTo.b
		local r, g, b = Lerp(lerpValue, r1, r2), Lerp(lerpValue, g1, g2), Lerp(lerpValue, b1, b2)
		return Color(r, g, b)
	end
end

function DLib.AddColor(addFrom, addTo, affertAlpha)
	if affertAlpha then
		local r1, g1, b1, a1 = addFrom.r, addFrom.g, addFrom.b, addFrom.a
		local r2, g2, b2, a2 = addTo.r, addTo.g, addTo.b, addTo.a
		local r, g, b, a = math.Clamp(r1 + r2, 0, 255), math.Clamp(g1 + g2, 0, 255), math.Clamp(b1 + b2, 0, 255), math.Clamp(a1 + a2, 0, 255)
		return Color(r, g, b, a)
	else
		local r1, g1, b1 = addFrom.r, addFrom.g, addFrom.b
		local r2, g2, b2 = addTo.r, addTo.g, addTo.b
		local r, g, b = math.Clamp(r1 + r2, 0, 255), math.Clamp(g1 + g2, 0, 255), math.Clamp(b1 + b2, 0, 255)
		return Color(r, g, b)
	end
end

function DLib.RandomColor()
	return Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))
end
