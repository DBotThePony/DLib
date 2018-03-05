
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

local net = net
local messageMeta = FindMetaTable('LNetworkMessage')
local table = table
local Entity = Entity
local type = type
local error = error

function messageMeta:WritePlayer(ply)
	local i = ply:EntIndex()
	self:WriteUInt(i, 8)
	return i
end

function messageMeta:ReadPlayer()
	return Entity(self:ReadUInt(8))
end

function messageMeta:WriteTypedArray(input, callFunc)
	self:WriteUInt(#input, 16)

	for i, value in ipairs(input) do
		callFunc(self, value)
	end
end

function messageMeta:ReadTypedArray(callFunc)
	return table.construct({}, callFunc, self:ReadUInt(16), self)
end

function messageMeta:WriteArray(input)
	self:WriteTypedArray(input, self.WriteType)
	return self
end

function messageMeta:ReadArray()
	return table.construct({}, self.ReadType, self:ReadUInt(16), self)
end

function messageMeta:WriteStringArray(input)
	self:WriteTypedArray(input, self.WriteString)
	return self
end

function messageMeta:ReadStringArray()
	return table.construct({}, self.ReadString, self:ReadUInt(16), self)
end

function messageMeta:WriteEntityArray(input)
	self:WriteTypedArray(input, self.WriteEntity)
	return self
end

function messageMeta:ReadEntityArray()
	return table.construct({}, self.ReadEntity, self:ReadUInt(16), self)
end

function messageMeta:WritePlayerArray(input)
	self:WriteTypedArray(input, self.WritePlayer)
	return self
end

function messageMeta:ReadPlayerArray()
	return table.construct({}, self.ReadPlayer, self:ReadUInt(16), self)
end

function messageMeta:WriteFloatArray(input)
	self:WriteTypedArray(input, self.WriteFloat)
	return self
end

function messageMeta:ReadFloatArray()
	return table.construct({}, self.ReadFloat, self:ReadUInt(16), self)
end

function messageMeta:WriteDoubleArray(input)
	self:WriteTypedArray(input, self.WriteDouble)
	return self
end

function messageMeta:ReadDoubleArray()
	return table.construct({}, self.ReadDouble, self:ReadUInt(16), self)
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

	return math.max(bits, 4)
end

function messageMeta:WriteVectorDouble(vecIn)
	if type(vecIn) ~= 'Vector' then
		error('WriteVectorDouble - input is not a vector!')
	end

	self:WriteDouble(vecIn.x)
	self:WriteDouble(vecIn.y)
	self:WriteDouble(vecIn.z)

	return self
end

function messageMeta:WriteAngleDouble(angleIn)
	if type(angleIn) ~= 'Angle' then
		error('WriteAngleDouble - input is not an angle!')
	end

	self:WriteDouble(angleIn.p)
	self:WriteDouble(angleIn.y)
	self:WriteDouble(angleIn.r)

	return self
end

function messageMeta:ReadVectorDouble()
	return Vector(self:ReadDouble(), self:ReadDouble(), self:ReadDouble())
end

function messageMeta:ReadAngleDouble()
	return Angle(self:ReadDouble(), self:ReadDouble(), self:ReadDouble())
end

net.RegisterWrapper('Player')
net.RegisterWrapper('TypedArray')
net.RegisterWrapper('Array')
net.RegisterWrapper('EntityArray')
net.RegisterWrapper('StringArray')
net.RegisterWrapper('PlayerArray')
net.RegisterWrapper('AngleDouble')
net.RegisterWrapper('VectorDouble')
net.RegisterWrapper('FloatArray')
net.RegisterWrapper('DoubleArray')
