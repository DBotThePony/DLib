
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

function net.ReadPlayer()
	return Entity(net.ReadUInt(8))
end

function net.WriteArray(input)
	net.WriteUInt(#input, 16)

	for i, value in ipairs(input) do
		net.WriteType(value)
	end
end

function net.ReadArray()
	return table.construct({}, net.ReadType, net.ReadUInt(16), nil)
end

return net
