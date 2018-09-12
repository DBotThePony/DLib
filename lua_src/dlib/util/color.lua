
-- Copyright (C) 2017-2018 DBot

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
