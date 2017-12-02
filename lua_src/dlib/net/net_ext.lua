
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

local net = DLib.netModule
local messageMeta = FindMetaTable('LNetworkMessage')

function messageMeta:WritePlayer(ply)
	local i = ply:EntIndex()
	self:WriteUInt(i, 8)
	return i
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

function messageMeta:ReadPlayer()
	return Entity(self:ReadUInt(8))
end

function messageMeta:WriteArray(input)
	messageMeta:WriteTypedArray(input, self.WriteType)
end

function messageMeta:ReadArray()
	return table.construct({}, self.ReadType, self:ReadUInt(16), self)
end

function messageMeta:WriteStringArray(input)
	messageMeta:WriteTypedArray(input, self.WriteString)
end

function messageMeta:ReadStringArray()
	return table.construct({}, self.ReadString, self.ReadUInt(16), self)
end

function messageMeta:WriteEntityArray(input)
	messageMeta:WriteTypedArray(input, self.WriteEntity)
end

function messageMeta:ReadEntityArray()
	return table.construct({}, self.ReadEntity, self:ReadUInt(16), self)
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
