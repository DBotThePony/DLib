
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

local DLib = DLib

DLib.net = DLib.net or {}
local _net = net
local net = DLib.net

net.Receivers = net.Receivers or {}

function net.Receive(identifier, callback)
	net.Receivers[assert(isstring(identifier) and identifier:lower(), 'Bad identifier given. typeof ' .. type(identifier))] = assert(isfunction(callback) and callback, 'Bad callback given. typeof ' .. type(callback))
end

net.receive = net.Receive
net.active_write_buffers = {}
net.message_size_limit = 0x4000
net.message_chunk_limit = 0x8000
net.message_datagram_limit = 0x400
net._next_datagram = net._next_datagram or 0
net._next_chunk = net._next_chunk or 0

function net.Start(identifier)
	local id = util.NetworkStringToID(assert(isstring(identifier) and identifier, 'Bad identifier given. typeof ' .. type(identifier)))
	assert(id > 0, 'Identifier ' .. identifier .. ' is not pooled by net.pool/util.AddNetworkString!')

	local dgram_id = net._next_datagram
	net._next_datagram = net._next_datagram + 1

	table.insert(net.active_write_buffers, {
		identifier = identifier,
		id = id,
		buffer = DLib.BytesBuffer(),
		dgram_id = dgram_id,
	})

	if #net.active_write_buffers > 20 then
		DLib.MessageWarning('Net message send queue might got leaked. Currently ', #net.active_write_buffers, ' net messages are awaiting send.')
	end
end

function net.TriggerEvent(network_id, buffer, ply)
	local string_id = util.NetworkIDToString(network_id)

	local net_event_listener = net.Receivers[string_id:lower()]

	if net_event_listener then
		net.active_read = {
			identifier = string_id,
			id = network_id,
			buffer = buffer,
			ply = ply,
		}

		local status = ProtectedCall(function()
			net_event_listener(buffer and buffer.length * 8 or 0, ply, buffer)
		end)

		net.active_read = nil

		if not status then
			ErrorNoHalt('Listener on network message ' .. string_id .. ' has failed!\n')
		end
	else
		ErrorNoHalt('DLib.net: No network listener attached on network message ' .. string_id .. '\n')
	end
end

function net.AccessWriteData()
	return assert(net.active_write_buffers[#net.active_write_buffers], 'Currently not constructing a network message')
end

function net.AccessWriteBuffer()
	return net.AccessWriteData().buffer
end

function net.AccessReadData()
	return assert(net.active_read, 'Currently not reading a network message')
end

function net.AccessReadBuffer()
	return net.AccessReadData().buffer
end

local function round_bits(bitsin)
	if not isnumber(bitsin) then return end

	if bitsin <= 0 then
		error('Bit amount is lower than zero')
	end

	if bitsin > 64 then
		error('Bit amount overflow')
	end

	local round = math.round(bitsin / 8)

	if round > 0 and round <= 4 then
		return round * 8
	end

	return 64
end

-- Default GMod functions
function net.WriteUInt(numberin, bitsin)
	bitsin = assert(round_bits(bitsin), 'Bit amount is not a number')
	assert(isnumber(numberin), 'Input is not a number')
	assert(numberin >= 0, 'Input is lesser than zero')

	local buffer = net.AccessWriteBuffer()

	if bitsin == 8 then
		buffer:WriteUByte(numberin)
	elseif bitsin == 16 then
		buffer:WriteUInt16(numberin)
	elseif bitsin == 24 then
		buffer:WriteUInt16(numberin:rshift(8))
		buffer:WriteUByte(numberin:band(255))
	elseif bitsin == 32 then
		buffer:WriteUInt32(numberin)
	elseif bitsin == 64 then
		buffer:WriteUInt64(numberin)
	end
end

function net.ReadUInt(bitsin)
	bitsin = assert(round_bits(bitsin), 'Bit amount is not a number')
	assert(isnumber(numberin), 'Input is not a number')
	assert(numberin >= 0, 'Input is lesser than zero')

	local buffer = net.AccessReadBuffer()

	if bitsin == 8 then
		return buffer:ReadUByte()
	elseif bitsin == 16 then
		return buffer:ReadUInt16()
	elseif bitsin == 24 then
		return buffer:WriteUInt16():lshift(8) + buffer:ReadUByte()
	elseif bitsin == 32 then
		return buffer:ReadUInt32()
	elseif bitsin == 64 then
		return buffer:ReadUInt64()
	end
end

function net.WriteInt(numberin, bitsin)
	bitsin = assert(round_bits(bitsin), 'Bit amount is not a number')
	assert(isnumber(numberin), 'Input is not a number')
	assert(numberin >= 0, 'Input is lesser than zero')

	local buffer = net.AccessWriteBuffer()

	if bitsin == 8 then
		buffer:WriteByte(numberin)
	elseif bitsin == 16 then
		buffer:WriteInt16(numberin)
	elseif bitsin == 24 then
		if numberin >= 0 then
			buffer:WriteInt16(numberin:rshift(8))
			buffer:WriteByte(numberin:band(255))
		else
			buffer:WriteInt16(-(-numberin):rshift(8))
			buffer:WriteUByte((-numberin):band(255))
		end
	elseif bitsin == 32 then
		buffer:WriteInt32(numberin)
	elseif bitsin == 64 then
		buffer:WriteInt64(numberin)
	end
end

function net.ReadInt(bitsin)
	bitsin = assert(round_bits(bitsin), 'Bit amount is not a number')
	assert(isnumber(numberin), 'Input is not a number')
	assert(numberin >= 0, 'Input is lesser than zero')

	local buffer = net.AccessReadBuffer()

	if bitsin == 8 then
		return buffer:ReadByte()
	elseif bitsin == 16 then
		return buffer:ReadInt16()
	elseif bitsin == 24 then
		local num = buffer:WriteInt16():lshift(8)

		if num >= 0 then
			return num + buffer:ReadUByte()
		else
			return num - buffer:ReadUByte()
		end
	elseif bitsin == 32 then
		return buffer:ReadInt32()
	elseif bitsin == 64 then
		return buffer:ReadInt64()
	end
end

function net.WriteBit(bitin)
	net.AccessWriteBuffer():WriteUByte(bitin:band(1))
end

function net.ReadBit()
	return net.AccessReadBuffer():ReadUByte()
end

function net.WriteBool(boolin)
	net.AccessWriteBuffer():WriteUByte(boolin and 1 or 0)
end

function net.ReadBool()
	return net.AccessReadBuffer():ReadUByte() >= 1
end

function net.WriteData(data, length)
	net.AccessWriteBuffer():WriteData(length and data:sub(1, length) or data)
end

function net.ReadData(length)
	return net.AccessReadBuffer():ReadData(length)
end

function net.WriteString(data)
	net.AccessWriteBuffer():WriteString(data)
end

function net.ReadString()
	return net.AccessReadBuffer():ReadString()
end

function net.WriteFloat(data)
	net.AccessWriteBuffer():WriteFloat(data)
end

function net.ReadFloat()
	return net.AccessReadBuffer():ReadFloat()
end

function net.WriteDouble(data)
	net.AccessWriteBuffer():WriteDouble(data)
end

function net.ReadDouble()
	return net.AccessReadBuffer():ReadDouble()
end

function net.WriteAngle(data)
	local buffer = net.AccessWriteBuffer()

	buffer:WriteFloat(data.p)
	buffer:WriteFloat(data.y)
	buffer:WriteFloat(data.r)
end

function net.ReadAngle()
	local buffer = net.AccessReadBuffer()

	return Angle(buffer:ReadFloat(), buffer:ReadFloat(), buffer:ReadFloat())
end

function net.WriteVector(data)
	local buffer = net.AccessWriteBuffer()

	buffer:WriteFloat(data.x)
	buffer:WriteFloat(data.y)
	buffer:WriteFloat(data.z)
end

function net.ReadVector()
	local buffer = net.AccessReadBuffer()
	return Vector(buffer:ReadFloat(), buffer:ReadFloat(), buffer:ReadFloat())
end

function net.WriteColor(data)
	local buffer = net.AccessWriteBuffer()

	buffer:WriteUByte(data.r)
	buffer:WriteUByte(data.g)
	buffer:WriteUByte(data.b)
end

function net.ReadColor()
	local buffer = net.AccessReadBuffer()
	return Color(buffer:ReadUByte(), buffer:ReadUByte(), buffer:ReadUByte())
end

function net.WriteNormal(data)
	local buffer = net.AccessWriteBuffer()

	buffer:WriteInt16(math.floor(data.x * 0x3fff):clamp(-0x3fff, 0x3fff))
	buffer:WriteInt16(math.floor(data.y * 0x3fff):clamp(-0x3fff, 0x3fff))
	buffer:WriteInt16(math.floor(data.z * 0x3fff):clamp(-0x3fff, 0x3fff))
end

function net.ReadNormal(data)
	local buffer = net.AccessReadBuffer()

	local x = buffer:ReadInt16() / 0x3fff
	local y = buffer:ReadInt16() / 0x3fff
	local z = buffer:ReadInt16() / 0x3fff

	return Vector(x, y, z)
end

function net.WriteEntity(data)
	net.AccessWriteBuffer():WriteUInt16(IsValid(data) and data:EntIndex() > 0 and data:EntIndex() or 0)
end

function net.ReadEntity(data)
	local int = net.AccessReadBuffer():ReadUInt16()

	if int <= 0 then
		return NULL
	end

	return Entity(int)
end

function net.WriteMatrix(data)
	local buffer = net.AccessWriteBuffer()

	for i, row in ipairs(data:ToTable()) do
		for i2 = 1, 4 do
			buffer:WriteDouble(row[i2])
		end
	end
end

function net.ReadMatrix(data)
	local buffer = net.AccessReadBuffer()
	local tab = {}

	for i = 1, 4 do
		local target = {}
		table.insert(tab, target)

		for i2 = 1, 4 do
			table.insert(target, buffer:ReadDouble())
		end
	end

	return Matrix(tab)
end

-- DLib extended functions
function net.WriteAngleDouble(data)
	local buffer = net.AccessWriteBuffer()

	buffer:WriteDouble(data.p)
	buffer:WriteDouble(data.y)
	buffer:WriteDouble(data.r)
end

function net.ReadAngleDouble()
	local buffer = net.AccessReadBuffer()
	return Angle(buffer:ReadDouble(), buffer:ReadDouble(), buffer:ReadDouble())
end

function net.WriteVectorDouble(data)
	local buffer = net.AccessWriteBuffer()

	buffer:WriteDouble(data.x)
	buffer:WriteDouble(data.y)
	buffer:WriteDouble(data.z)
end

function net.ReadVectorDouble()
	local buffer = net.AccessReadBuffer()
	return Vector(buffer:ReadDouble(), buffer:ReadDouble(), buffer:ReadDouble())
end

function net.Namespace(target)
	if type(target) == 'Player' then
		if target.dlib_net ~= nil then return target.dlib_net end
		target.dlib_net = {}
		return net.Namespace(target.dlib_net)
	end

	if CLIENT then return target end

	target.network_position = target.network_position or 0
	target.queued_buffers = target.queued_buffers or {}
	target.queued_chunks = target.queued_chunks or {}
	target.queued_datagrams = target.queued_datagrams or {}

	target.server_position = target.server_position or 0
	target.server_chunks = target.server_chunks or {}
	target.server_queued = target.server_queued or {}
	target.server_datagrams = target.server_datagrams or {}

	if target.server_datagram_ack == nil then
		target.server_datagram_ack = true
	end

	if target.server_chunk_ack == nil then
		target.server_chunk_ack = true
	end

	return target
end

_net.receive('dlib_net_chunk', function(_, ply)
	local chunkid = _net.ReadUInt32()
	local current_chunk = _net.ReadUInt32()
	local chunks = _net.ReadUInt16()
	local startpos = _net.ReadUInt32()
	local endpos = _net.ReadUInt32()
	local is_compressed = _net.ReadBool()
	local length = _net.ReadUInt16()
	local chunk = _net.ReadData(length)

	_net.Start('dlib_net_chunk_ack')
	_net.WriteUInt32(chunkid)
	_net.WriteUInt32(current_chunk)

	if CLIENT then
		_net.SendToServer()
	else
		_net.Send(ply)
	end

	local namespace = net.Namespace(CLIENT and net or ply)

	namespace.queued_chunks[chunkid] = namespace.queued_chunks[chunkid] or {
		chunks = {}
	}

	local data = namespace.queued_chunks[chunkid]
	data.is_compressed = is_compressed
	data.startpos = startpos
	data.endpos = endpos
	data.chunks[current_chunk] = chunk
	data.total_chunks = chunks

	if table.Count(data.chunks) == data.total_chunks then
		local stringdata = table.concat(data.chunks, '')

		if data.is_compressed then
			stringdata = util.Decompress(stringdata)
		end

		table.insert(namespace.queued_buffers, {
			startpos = startpos,
			endpos = endpos,
			buffer = DLib.BytesBuffer(stringdata ~= '' and stringdata or nil),
		})

		namespace.queued_chunks[chunkid] = nil

		net.ProcessIncomingQueue(namespace, ply)
	end
end)

_net.receive('dlib_net_datagram', function(_, ply)
	if SERVER and not IsValid(ply) then return end
	local readnetid = _net.ReadUInt16()

	local namespace = net.Namespace(CLIENT and net or ply)

	_net.Start('dlib_net_datagram_ack')

	while readnetid > 0 do
		local startpos = _net.ReadUInt32()
		local endpos = _net.ReadUInt32()
		local dgram_id = _net.ReadUInt32()
		_net.WriteUInt32(dgram_id)

		namespace.queued_datagrams[dgram_id] = {
			readnetid = readnetid,
			startpos = startpos,
			endpos = endpos,
			dgram_id = dgram_id,
		}

		readnetid = _net.ReadUInt16()
	end

	if CLIENT then
		_net.SendToServer()
	else
		_net.Send(ply)
	end

	net.ProcessIncomingQueue(namespace, SERVER and ply or NULL)
end)

function net.ProcessIncomingQueue(namespace, ply)
	local hit = true

	while hit do
		hit = false

		local fdgram, fdata

		for dgram_id, data in pairs(namespace.queued_datagrams) do
			if not fdgram or fdgram > dgram_id then
				fdgram = dgram_id
				fdata = data
			end
		end

		if not fdgram then return end

		local stop = false

		repeat
			stop = true

			for i, bdata in pairs(namespace.queued_buffers) do
				if bdata.endpos < fdata.startpos then
					stop = false
					namespace.queued_buffers[i] = nil
				end
			end
		until stop

		if fdata.startpos == fdata.endpos then
			namespace.queued_datagrams[fdgram] = nil
			hit = true
			net.TriggerEvent(fdata.readnetid, nil, ply)
		else
			for i, bdata in pairs(namespace.queued_buffers) do
				if bdata.startpos <= fdata.startpos and bdata.endpos >= fdata.endpos then
					hit = true
					namespace.queued_datagrams[fdgram] = nil
					namespace.network_position = fdata.endpos

					if fdata.endpos == bdata.endpos then
						namespace.queued_buffers[i] = nil
					end

					local len = fdata.endpos - fdata.startpos
					local start = fdata.startpos - bdata.startpos

					net.TriggerEvent(fdata.readnetid, DLib.BytesBufferView(start, start + len, bdata.buffer), ply)

					break
				end
			end
		end
	end
end

function net.Dispatch(ply)
	local namespace = net.Namespace(CLIENT and net or ply)

	local data = net.active_write_buffers[#net.active_write_buffers]

	if not data.string and data.buffer.length then
		data.string = data.buffer:ToString()
	end

	local namespace = net.Namespace(CLIENT and net or ply)

	local startpos = namespace.server_position
	local endpos = namespace.server_position + data.buffer.length

	if data.buffer.length ~= 0 then
		table.insert(namespace.server_queued, {
			buffer = data.buffer,
			string = data.string,
			startpos = startpos,
			endpos = endpos,
		})
	end

	namespace.server_position = endpos

	namespace.server_datagrams[data.dgram_id] = {
		id = data.id,
		startpos = startpos,
		endpos = endpos,
		dgram_id = data.dgram_id,
	}
end

function net.DispatchChunk(ply)
	local namespace = net.Namespace(CLIENT and net or ply)

	if #namespace.server_queued ~= 0 then
		local stringbuilder = {}
		local startpos, endpos = 0xFFFFFFFFF, 0

		for _, data in ipairs(namespace.server_queued) do
			if data.startpos < startpos then
				startpos = data.startpos
			end

			if data.endpos > endpos then
				endpos = data.endpos
			end

			table.insert(stringbuilder, data.string)
		end

		local build = table.concat(stringbuilder, '')
		local compressed

		if #build > net.message_size_limit then
			compressed = util.Compress(build)
		end

		local _next_chunk = net._next_chunk
		net._next_chunk = net._next_chunk + 1

		local data = {
			chunks = {},
			is_compressed = compressed ~= nil,
			startpos = startpos,
			endpos = endpos,
			chunkid = _next_chunk,
			current_chunk = 1,
		}

		table.insert(namespace.server_chunks, data)

		local writedata = compressed or build
		local written = 1

		repeat
			local length = math.min(#writedata - written + 1, net.message_chunk_limit)
			table.insert(data.chunks, writedata:sub(written, written + length))
			written = written + length + 1
		until written >= #writedata

		data.total_chunks = #data.chunks

		namespace.server_queued = {}
	end

	if #namespace.server_chunks == 0 then return end
	local data = namespace.server_chunks[1]
	local chunkNum, chunkData = next(data.chunks)

	if not chunkNum then
		table.remove(namespace.server_chunks, 1)
		return net.DispatchChunk(ply)
	end

	namespace.server_chunk_ack = false

	_net.Start('dlib_net_chunk')
	_net.WriteUInt32(data.chunkid)
	_net.WriteUInt32(chunkNum)
	_net.WriteUInt16(data.total_chunks)
	_net.WriteUInt32(data.startpos)
	_net.WriteUInt32(data.endpos)
	_net.WriteBool(data.is_compressed)
	_net.WriteUInt16(#chunkData)
	_net.WriteData(chunkData, #chunkData)

	if CLIENT then
		_net.SendToServer()
	else
		_net.Send(ply)
	end
end

_net.receive('dlib_net_chunk_ack', function(_, ply)
	if SERVER and not IsValid(ply) then return end
	local namespace = net.Namespace(CLIENT and net or ply)

	namespace.server_chunk_ack = true

	local chunkid = _net.ReadUInt32()
	local current_chunk = _net.ReadUInt32()

	for _, data in ipairs(namespace.server_chunks) do
		if data.chunkid == chunkid then
			data.chunks[current_chunk] = nil
		end
	end
end)

function net.DispatchDatagram(ply)
	if SERVER and not IsValid(ply) then return end
	local namespace = net.Namespace(CLIENT and net or ply)

	namespace.server_datagram_ack = false

	_net.Start('dlib_net_datagram')

	local lastkey

	for i = 0, net.message_datagram_limit - 1 do
		local index, data = next(namespace.server_datagrams, lastkey)

		if not index then
			_net.WriteUInt16(0)
			break
		end

		lastkey = index

		_net.WriteUInt16(data.id)
		_net.WriteUInt32(data.startpos)
		_net.WriteUInt32(data.endpos)
		_net.WriteUInt32(data.dgram_id)
	end

	if CLIENT then
		_net.SendToServer()
	else
		_net.Send(ply)
	end
end

_net.receive('dlib_net_datagram_ack', function(length, ply)
	if SERVER and not IsValid(ply) then return end
	local namespace = net.Namespace(CLIENT and net or ply)

	namespace.server_datagram_ack = true

	for i = 1, length / 32 do
		namespace.server_datagrams[_net.ReadUInt32()] = nil
	end
end)
