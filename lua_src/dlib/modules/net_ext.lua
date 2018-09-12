
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


local net = net
local table = table
local Entity = Entity
local type = type
local error = error

net.pool = util.AddNetworkString

function net.WritePlayer(ply)
	local i = ply:EntIndex()
	net.WriteUInt(i, 8)
	return i
end

function net.ReadPlayer()
	return Entity(net.ReadUInt(8))
end

function net.WriteTypedArray(input, callFunc)
	net.WriteUInt(#input, 16)

	for i, value in ipairs(input) do
		callFunc(value)
	end
end

function net.ReadTypedArray(callFunc)
	return table.construct({}, callFunc, net.ReadUInt(16))
end

function net.WriteArray(input)
	net.WriteTypedArray(input, net.WriteType)
end

function net.ReadArray()
	return table.construct({}, net.ReadType, net.ReadUInt(16))
end

function net.WriteStringArray(input)
	net.WriteTypedArray(input, net.WriteString)
end

function net.ReadStringArray()
	return table.construct({}, net.ReadString, net.ReadUInt(16))
end

function net.WriteEntityArray(input)
	net.WriteTypedArray(input, net.WriteEntity)
end

function net.ReadEntityArray()
	return table.construct({}, net.ReadEntity, net.ReadUInt(16))
end

function net.WritePlayerArray(input)
	net.WriteTypedArray(input, net.WritePlayer)
end

function net.ReadPlayerArray()
	return table.construct({}, net.ReadPlayer, net.ReadUInt(16))
end

function net.WriteFloatArray(input)
	net.WriteTypedArray(input, net.WriteFloat)
end

function net.ReadFloatArray()
	return table.construct({}, net.ReadFloat, net.ReadUInt(16))
end

function net.WriteDoubleArray(input)
	net.WriteTypedArray(input, net.WriteDouble)
end

function net.ReadDoubleArray()
	return table.construct({}, net.ReadDouble, net.ReadUInt(16))
end

function net.GReadUInt(val)
	return function()
		return net.ReadUInt(val)
	end
end

function net.GWriteUInt(val)
	return function(val2)
		return net.WriteUInt(val2, val)
	end
end

net.ReadUInt8 = net.GReadUInt(8)
net.ReadUInt16 = net.GReadUInt(16)
net.ReadUInt32 = net.GReadUInt(32)

net.WriteUInt8 = net.GWriteUInt(8)
net.WriteUInt16 = net.GWriteUInt(16)
net.WriteUInt32 = net.GWriteUInt(32)

function net.GReadInt(val)
	return function()
		return net.ReadInt(val)
	end
end

function net.GWriteInt(val)
	return function(val2)
		return net.WriteInt(val2, val)
	end
end

net.ReadInt8 = net.GReadInt(8)
net.ReadInt16 = net.GReadInt(16)
net.ReadInt32 = net.GReadInt(32)

net.WriteInt8 = net.GWriteInt(8)
net.WriteInt16 = net.GWriteInt(16)
net.WriteInt32 = net.GWriteInt(32)

local maxint = math.pow(2, 32) - 1
function net.WriteBigUInt(val)
	local first = val % maxint
	local second = (val - first) / maxint
	net.WriteUInt32(first)
	net.WriteUInt32(second)
end

function net.ReadBigUInt(val)
	local first = net.ReadUInt32()
	local second = net.ReadUInt32()

	return first + second * maxint
end

function net.WriteBigInt(val)
	net.WriteBool(val >= 0)
	net.WriteBigUInt(val:abs())
end

net.WriteUInt64 = net.WriteBigUInt
net.WriteInt64 = net.WriteBigInt

net.ReadUInt64 = net.ReadBigUInt
net.ReadInt64 = net.ReadBigInt

function net.ReadBigInt()
	local sign = net.ReadBool()
	local value = net.ReadBigUInt()

	if sign then
		return value
	end

	return -value
end

function net.ChooseOptimalBits(amount)
	local bits = 1

	while 2 ^ bits <= amount do
		bits = bits + 1
	end

	return math.max(bits, 4)
end

function net.WriteVectorDouble(vecIn)
	if type(vecIn) ~= 'Vector' then
		error('WriteVectorDouble - input is not a vector!')
	end

	net.WriteDouble(vecIn.x)
	net.WriteDouble(vecIn.y)
	net.WriteDouble(vecIn.z)

	return self
end

function net.WriteAngleDouble(angleIn)
	if type(angleIn) ~= 'Angle' then
		error('WriteAngleDouble - input is not an angle!')
	end

	net.WriteDouble(angleIn.p)
	net.WriteDouble(angleIn.y)
	net.WriteDouble(angleIn.r)

	return self
end

function net.ReadVectorDouble()
	return Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
end

function net.ReadAngleDouble()
	return Angle(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
end

local Color = Color

function net.WriteColor(colIn)
	if not IsColor(colIn) then
		error('Attempt to write a color which is not a color! ' .. type(colIn))
	end

	net.WriteUInt(colIn.r, 8)
	net.WriteUInt(colIn.g, 8)
	net.WriteUInt(colIn.b, 8)
	net.WriteUInt(colIn.a, 8)
end

function net.ReadColor()
	return Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
end
