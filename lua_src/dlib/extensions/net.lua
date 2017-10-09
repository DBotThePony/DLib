
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

local net = DLib.module('net', 'net')

function net.WritePlayer(ply)
	local i = ply:EntIndex()
	net.WriteUInt(i, 8)
	return i
end

function net.WriteTypedArray(input, callFunc)
	net.WriteUInt(#input, 16)

	for i, value in ipairs(input) do
		net.WriteType(value)
	end
end

function net.ReadTypedArray(callFunc)
	return table.construct({}, callFunc, net.ReadUInt(16), nil)
end

function net.ReadPlayer()
	return Entity(net.ReadUInt(8))
end

function net.WriteArray(input)
	net.WriteTypedArray(input, net.WriteType)
end

function net.ReadArray()
	return table.construct({}, net.ReadType, net.ReadUInt(16), nil)
end

function net.WriteStringArray(input)
	net.WriteTypedArray(input, net.WriteString)
end

function net.ReadStringArray()
	return table.construct({}, net.ReadString, net.ReadUInt(16), nil)
end

function net.WriteEntityArray(input)
	net.WriteTypedArray(input, net.WriteEntity)
end

function net.ReadEntityArray()
	return table.construct({}, net.ReadEntity, net.ReadUInt(16), nil)
end

function net.WriteBigint(num, base)
	base = base or 63
	local reply = {}
	local signed = num < 0
	num = math.abs(num)

	while num > 0 do
		local div = num % 2
		num = (num - div) / 2
		table.insert(reply, div)
	end

	for i = 1, base do
		net.WriteBit(reply[base - i + 1] or 0)
	end

	net.WriteBool(signed)
end

function net.ReadBigint(base)
	base = base or 63
	local reply = {}
	local output = 0

	for i = 1, base do
		output = output + preProcessed[base - i + 1] * net.ReadBit()
	end

	local signed = net.ReadBool()

	return not signed and output or -output
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

function net.ChooseOptimalBits(amount)
	local bits = 1

	while 2 ^ bits <= amount do
		bits = bits + 1
	end

	return bits
end

return net
