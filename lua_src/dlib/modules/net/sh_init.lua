
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
local _net = net
local net = DLib.net

local function debug(str)
	--file.Append('dlib_net_debug.txt', str .. '\n')
end

net.Receivers = net.Receivers or {}
net.ReceiversAntispam = net.ReceiversAntispam or {}

function net.Receive(identifier, callback)
	net.Receivers[assert(isstring(identifier) and identifier:lower(), 'Bad identifier given. typeof ' .. type(identifier))] = assert(isfunction(callback) and callback, 'Bad callback given. typeof ' .. type(callback))
end

function net.ReceiveAntispam(identifier, cooldown, antispam_type)
	cooldown = cooldown or 1
	antispam_type = antispam_type == true

	net.ReceiversAntispam[assert(isstring(identifier) and identifier:lower(), 'Bad identifier given. typeof ' .. type(identifier))] = {
		cooldown = cooldown,
		antispam_type = antispam_type,
		func = antispam_type and CurTime or RealTime,
	}
end

net.receive = net.Receive
net.receiveAntispam = net.ReceiveAntispam
net.active_write_buffers = {}
net.message_size_limit = 0x4000
net.message_chunk_limit = 0x8000
net.message_datagram_limit = 0x400
net.datagram_queue_size_limit = 0x10000 -- idiot proofing from flooding server's memory with trash data
net.window_size_limit = 0x1000000 -- idiot proofing from flooding server's memory with trash data

function net.UpdateWindowProperties()
	net.window_size_limit = net.WINDOW_SIZE_LIMIT:GetInt(0x1000000)
	net.datagram_queue_size_limit = net.DGRAM_SIZE_LIMIT:GetInt(0x10000)
	net.message_size_limit = net.COMPRESSION_LIMIT:GetInt(0x4000)
end

function net.Start(identifier)
	local id = util.NetworkStringToID(assert(isstring(identifier) and identifier, 'Bad identifier given. typeof ' .. type(identifier)))
	assert(id > 0, 'Identifier ' .. identifier .. ' is not pooled by net.pool/util.AddNetworkString!')

	table.insert(net.active_write_buffers, {
		identifier = identifier,
		id = id,
		buffer = DLib.BytesBuffer(),
	})

	if #net.active_write_buffers > 20 then
		DLib.MessageWarning('Net message send queue might got leaked. Currently ', #net.active_write_buffers, ' net messages are awaiting send.')
	end
end

function net.TriggerEvent(network_id, buffer, ply)
	local string_id = util.NetworkIDToString(network_id)

	if not string_id then
		ErrorNoHalt('DLib.net: Trying to trigger network event with ID ' .. network_id .. ' but util.NetworkIDToString returned nothing. Is this newly added network string?\n')
		return
	end

	string_id = string_id:lower()

	local net_event_listener = net.Receivers[string_id]

	if net_event_listener then
		local antispam = net.ReceiversAntispam[string_id]

		if antispam then
			local target
			local index = 'antispam_' .. string_id

			if IsValid(ply) then
				target = ply:GetTable()
			else
				target = net
			end

			local time = antispam.func()

			if not target[index] then
				target[index] = 0
			end

			if target[index] > time then
				return
			end

			target[index] = time + antispam.cooldown
		end

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
			ErrorNoHalt('DLib.net: Listener on network message ' .. string_id .. ' has failed!\n')
		end
	elseif CLIENT then
		ErrorNoHalt('DLib.net: No network listener attached on network message ' .. string_id .. '\n')
	else
		ErrorNoHalt('DLib.net: No network listener attached on network message ' .. string_id .. '\n. Message sent by: ' .. string.format('%s<%s>\n', ply:Nick(), ply:SteamID()))
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
	return assert(net.AccessReadData().buffer, 'Message is zero length')
end

function net.BytesWritten()
	return net.AccessWriteBuffer().length
end

function net.Discard()
	table.remove(net.active_write_buffers)
end

_net.receive('dlib_net_ack1', function(_, ply)
	local namespace = net.Namespace(CLIENT and net or ply)
	namespace.last_expected_ack = RealTime() + 10

	namespace.server_chunk_ack = true
	namespace.server_datagram_ack = true

	debug('Ask 1')

	_net.Start('dlib_net_ack2')

	if CLIENT then
		_net.SendToServer()
	else
		_net.Send(ply)
	end
end)

_net.receive('dlib_net_ack2', function(_, ply)
	debug('Ask 2')

	local namespace = net.Namespace(CLIENT and net or ply)
	namespace.last_expected_ack = RealTime() + 10
	namespace.server_chunk_ack = true
	namespace.server_datagram_ack = true
end)

_net.receive('dlib_net_chunk', function(_, ply)
	local chunkid = _net.ReadUInt32()
	local current_chunk = _net.ReadUInt16()
	local chunks = _net.ReadUInt16()
	local startpos = _net.ReadUInt32()
	local endpos = _net.ReadUInt32()
	local is_compressed = _net.ReadBool()
	local length = _net.ReadUInt16()
	local chunk = _net.ReadData(length)

	debug(
		string.format('Received chunk: Chunkid %d, current chunk number %d, total chunks %d, position: %d->%d, compressed: %s, lenght: %s',
		chunkid, current_chunk, chunks, startpos, endpos, is_compressed and 'Yes' or 'No', length))

	_net.Start('dlib_net_chunk_ack')
	_net.WriteUInt32(chunkid)
	_net.WriteUInt16(current_chunk)

	if CLIENT then
		_net.SendToServer()
	else
		_net.Send(ply)
	end

	local namespace = net.Namespace(CLIENT and net or ply)

	if namespace.next_expected_chunk > chunkid then return end

	local data = namespace.queued_chunks[chunkid]

	if not data then
		data = {
			chunks = {}
		}

		namespace.queued_chunks[chunkid] = data
		namespace.queued_chunks_num = namespace.queued_chunks_num + 1

		if namespace.queued_chunks_num > 21 and namespace.queued_chunks_num % 20 == 0 then
			if CLIENT then
				DLib.MessageWarning('DLib.net: Queued ', namespace.queued_chunks_num, ' chunks from server!')
			else
				DLib.MessageWarning('DLib.net: Queued ', namespace.queued_chunks_num, ' chunks from ', ply, '!')
			end
		end
	end

	data.is_compressed = is_compressed
	data.startpos = startpos
	data.endpos = endpos
	data.chunks[current_chunk] = chunk
	data.total_chunks = chunks
	namespace.accumulated_size = namespace.accumulated_size + #chunk

	if table.Count(data.chunks) == data.total_chunks then
		if namespace.next_expected_chunk == chunkid then
			namespace.next_expected_chunk = chunkid + 1
		end

		local stringdata = table.concat(data.chunks, '')

		debug(
			string.format('Built up chunks! Chunkid %d, total chunks %d, position: %d->%d, compressed: %s, lenght: %s',
			chunkid, current_chunk, chunks, startpos, endpos, is_compressed and 'Yes' or 'No', length))

		namespace.accumulated_size = namespace.accumulated_size - #stringdata

		if data.is_compressed then
			if CLIENT or net.USE_COMPRESSION:GetBool() then
				stringdata = util.Decompress(stringdata, net.window_size_limit - namespace.accumulated_size)

				if not stringdata then
					namespace.queued_chunks[chunkid] = nil
					return
				end
			else
				stringdata = ''
			end
		end

		namespace.accumulated_size = namespace.accumulated_size + #stringdata

		table.insert(namespace.queued_buffers, {
			startpos = startpos,
			endpos = endpos,
			buffer = DLib.BytesBuffer(stringdata ~= '' and stringdata or nil),
		})

		namespace.queued_chunks[chunkid] = nil
		namespace.queued_chunks_num = namespace.queued_chunks_num - 1
		namespace.queued_buffers_num = namespace.queued_buffers_num + 1

		net.ProcessIncomingQueue(namespace, ply)
	end
end)

_net.receive('dlib_net_datagram', function(_, ply)
	-- TODO: Too many datagrams at once can create unordered execution, causing undefined behvaior
	-- such as removing buffers too early (before every datagram belonging to that buffer execute)
	if SERVER and not IsValid(ply) then return end
	local readnetid = _net.ReadUInt16()

	local namespace = net.Namespace(CLIENT and net or ply)

	_net.Start('dlib_net_datagram_ack')

	while readnetid > 0 do
		local startpos = _net.ReadUInt32()
		local endpos = _net.ReadUInt32()
		local dgram_id = _net.ReadUInt32()
		_net.WriteUInt32(dgram_id)

		debug(
			string.format('Received datagram: ID: %d position: %d->%d, network string id: %d',
			dgram_id, startpos, endpos, readnetid))

		if dgram_id >= namespace.next_expected_datagram then
			namespace.queued_datagrams[dgram_id] = {
				readnetid = readnetid,
				startpos = startpos,
				endpos = endpos,
				dgram_id = dgram_id,
			}

			namespace.queued_datagrams_num = namespace.queued_datagrams_num + 1

			if namespace.queued_datagrams_num > 101 and namespace.queued_datagrams_num % 100 == 0 then
				if CLIENT then
					DLib.MessageWarning('DLib.net: Queued ', namespace.queued_datagrams_num, ' datagrams from server!')
				else
					DLib.MessageWarning('DLib.net: Queued ', namespace.queued_datagrams_num, ' datagrams from ', ply, '!')
				end
			end
		end

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

		if namespace.next_expected_datagram == -1 then
			namespace.next_expected_datagram = fdgram
			return
		end

		if fdgram ~= namespace.next_expected_datagram then return end

		local stop = false

		repeat
			stop = true

			for i, bdata in pairs(namespace.queued_buffers) do
				if bdata.endpos < fdata.startpos then
					stop = false

					debug(
						string.format('[!] Discarding buffer %d position %d->%d because of datagram %d being at %d->%d',
						i, bdata.startpos, bdata.endpos, fdgram, fdata.startpos, fdata.endpos))

					namespace.accumulated_size = namespace.accumulated_size - bdata.buffer.length
					namespace.queued_buffers[i] = nil
					namespace.queued_buffers_num = namespace.queued_buffers_num - 1
				end
			end
		until stop

		if fdata.startpos == fdata.endpos then
			namespace.queued_datagrams[fdgram] = nil
			namespace.queued_datagrams_num = namespace.queued_datagrams_num - 1
			namespace.next_expected_datagram = namespace.next_expected_datagram + 1
			hit = true

			debug(
				string.format('Processed empty payload datagram %d',
				fdgram))

			net.TriggerEvent(fdata.readnetid, nil, ply)
		else
			for i, bdata in pairs(namespace.queued_buffers) do
				if bdata.startpos <= fdata.startpos and bdata.endpos >= fdata.endpos then
					hit = true
					namespace.queued_datagrams[fdgram] = nil
					namespace.queued_datagrams_num = namespace.queued_datagrams_num - 1
					namespace.network_position = fdata.endpos

					if fdata.endpos == bdata.endpos then
						debug(
							string.format('Removing buffer %d because it\'s bounds are finished %d->%d for datagram %d (%d->%d)',
							i, fdata.startpos, fdata.endpos, fdgram, fdata.startpos, fdata.endpos))

						namespace.accumulated_size = namespace.accumulated_size - bdata.buffer.length
						namespace.queued_buffers[i] = nil
						namespace.queued_buffers_num = namespace.queued_buffers_num - 1
					end

					local len = fdata.endpos - fdata.startpos
					local start = fdata.startpos - bdata.startpos

					debug(
						string.format('Processed datagram %d with position %d->%d and network id %d',
						fdgram, fdata.startpos, fdata.endpos, fdata.readnetid))

					net.TriggerEvent(fdata.readnetid, DLib.BytesBufferView(start, start + len, bdata.buffer), ply)

					namespace.next_expected_datagram = namespace.next_expected_datagram + 1

					break
				end
			end
		end
	end
end

function net.DiscardAndFire(namespace)
	namespace = CLIENT and net or namespace
	local discarded_num, discarded_bytes = 0, 0

	local minimal = 0xFFFFFFFFF

	for i, buffdata in ipairs(namespace.queued_buffers) do
		if buffdata.startpos < minimal then
			minimal = buffdata.startpos
		end
	end

	for dgram_id, data in pairs(namespace.queued_datagrams) do
		if data.startpos < minimal then
			namespace.queued_datagrams[dgram_id] = nil
		end
	end

	namespace.queued_datagrams_num = table.Count(namespace.queued_datagrams)

	namespace.next_expected_datagram = -1
	namespace.last_expected_ack = 0xFFFFFFFF

	net.ProcessIncomingQueue(namespace)
end

function net.Dispatch(ply)
	local namespace = net.Namespace(CLIENT and net or ply)

	local data = net.active_write_buffers[#net.active_write_buffers]

	if not data.string and data.buffer.length then
		data.string = data.buffer:ToString()
	end

	local namespace = net.Namespace(CLIENT and net or ply)

	if SERVER and (namespace.server_datagrams_num > net.datagram_queue_size_limit or namespace.server_queued_size > net.window_size_limit) then
		return
	end

	local startpos = namespace.server_position
	local endpos = namespace.server_position + data.buffer.length

	namespace.server_queued_size = namespace.server_queued_size + data.buffer.length

	local dgram_id = namespace.next_datagram_id
	namespace.next_datagram_id = namespace.next_datagram_id + 1

	if data.buffer.length ~= 0 then
		table.insert(namespace.server_queued, {
			buffer = data.buffer,
			string = data.string,
			startpos = startpos,
			endpos = endpos,
		})

		debug(
			string.format('Queueing message payload for %d with position %d->%d',
			dgram_id, startpos, endpos))

		namespace.server_queued_num = namespace.server_queued_num + 1

		if CLIENT and namespace.server_queued_num > 101 and namespace.server_queued_num % 100 == 0 then
			DLib.MessageWarning('DLib.net: Queued ', namespace.server_queued_num, ' message payloads for server!')
		end
	end

	namespace.server_position = endpos

	namespace.server_datagrams[dgram_id] = {
		id = data.id,
		startpos = startpos,
		endpos = endpos,
		dgram_id = dgram_id,
	}

	debug(
		string.format('Queueing datagram %d with position %d->%d',
		dgram_id, startpos, endpos))

	namespace.server_datagrams_num = namespace.server_datagrams_num + 1

	if CLIENT and namespace.server_datagrams_num > 101 and namespace.server_datagrams_num % 100 == 0 then
		DLib.MessageWarning('DLib.net: Queued ', namespace.server_datagrams_num, ' datagrams for server!')
	end

	if namespace.last_expected_ack == 0xFFFFFFFF then
		namespace.last_expected_ack = RealTime() + 10
	end
end

function net.DispatchChunk(ply)
	local namespace = net.Namespace(CLIENT and net or ply)

	if #namespace.server_queued ~= 0 and #namespace.server_chunks == 0 then
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

		if #build > net.message_size_limit and net.USE_COMPRESSION:GetBool() and (SERVER or net.USE_COMPRESSION_SV:GetBool()) then
			compressed = util.Compress(build)
		end

		local next_chunk_id = namespace.next_chunk_id
		namespace.next_chunk_id = namespace.next_chunk_id + 1

		local data = {
			chunks = {},
			is_compressed = compressed ~= nil,
			startpos = startpos,
			endpos = endpos,
			length = endpos - startpos,
			chunkid = next_chunk_id,
			current_chunk = 1,
		}

		table.insert(namespace.server_chunks, data)
		namespace.server_chunks_num = namespace.server_chunks_num + 1

		local writedata = compressed or build
		local written = 1

		repeat
			local length = math.min(#writedata - written + 1, net.message_chunk_limit)
			table.insert(data.chunks, writedata:sub(written, written + length))
			written = written + length + 1
		until written >= #writedata

		data.total_chunks = #data.chunks

		namespace.server_queued = {}
		namespace.server_queued_num = 0
	end

	if #namespace.server_chunks == 0 then return end
	local data = namespace.server_chunks[1]
	local chunkNum, chunkData = next(data.chunks)

	if not chunkNum then
		debug(
			string.format('Chunk %d is fully dispatched to target!',
			data.chunkid))

		table.remove(namespace.server_chunks, 1)
		namespace.server_chunks_num = namespace.server_chunks_num - 1
		namespace.server_queued_size = namespace.server_queued_size - data.length

		if namespace.server_chunks_num == 0 and namespace.server_datagrams_num == 0 then
			namespace.last_expected_ack = 0xFFFFFFFF
		end

		return net.DispatchChunk(ply)
	end

	namespace.server_chunk_ack = false

	if namespace.last_expected_ack == 0xFFFFFFFF then
		namespace.last_expected_ack = RealTime() + 10
	end

	_net.Start('dlib_net_chunk')
	_net.WriteUInt32(data.chunkid)
	_net.WriteUInt16(chunkNum)
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
	local current_chunk = _net.ReadUInt16()

	debug(
		string.format('ACKed chunk %d with position %d',
		chunkid, current_chunk))

	for _, data in ipairs(namespace.server_chunks) do
		if data.chunkid == chunkid then
			data.chunks[current_chunk] = nil
		end
	end

	if namespace.server_chunks_num == 0 and namespace.server_datagrams_num == 0 then
		namespace.last_expected_ack = 0xFFFFFFFF
	else
		namespace.last_expected_ack = RealTime() + 10
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
		local readid = _net.ReadUInt32()

		if namespace.server_datagrams[readid] then
			namespace.server_datagrams[readid] = nil
			namespace.server_datagrams_num = namespace.server_datagrams_num - 1
		end
	end

	if namespace.server_datagrams_num > 101 and namespace.server_datagrams_num % 100 == 0 then
		if CLIENT then
			DLib.MessageWarning('DLib.net: STILL have queued ', namespace.server_datagrams_num, ' datagrams for server!')
		else
			DLib.MessageWarning('DLib.net: STILL have queued ', namespace.server_datagrams_num, ' datagrams for ', ply, '!')
		end
	end

	if namespace.server_chunks_num == 0 and namespace.server_datagrams_num == 0 then
		namespace.last_expected_ack = 0xFFFFFFFF
	else
		namespace.last_expected_ack = RealTime() + 10
	end
end)

local function round_bits(bitsin)
	if not isnumber(bitsin) then return end

	if bitsin <= 0 then
		error('Bit amount is lower than zero')
	end

	if bitsin > 64 then
		error('Bit amount overflow')
	end

	local round = math.ceil(bitsin / 8)

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
	else
		error('Can\'t write UInt with ' .. bitsin .. ' bits')
	end
end

function net.ReadUInt(bitsin)
	bitsin = assert(round_bits(bitsin), 'Bit amount is not a number')

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
	else
		error('Can\'t read UInt with ' .. bitsin .. ' bits')
	end
end

function net.WriteInt(numberin, bitsin)
	bitsin = assert(round_bits(bitsin), 'Bit amount is not a number')
	assert(isnumber(numberin), 'Input is not a number')

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
	else
		error('Can\'t write Int with ' .. bitsin .. ' bits')
	end
end

function net.ReadInt(bitsin)
	bitsin = assert(round_bits(bitsin), 'Bit amount is not a number')

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
	else
		error('Can\'t read Int with ' .. bitsin .. ' bits')
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
	buffer:WriteUByte(data.a)
end

function net.ReadColor()
	local buffer = net.AccessReadBuffer()
	return Color(buffer:ReadUByte(), buffer:ReadUByte(), buffer:ReadUByte(), buffer:ReadUByte())
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

-- copy pasted from gmod code LULW
function net.WriteTable(tab)
	for k, v in pairs(tab) do
		net.WriteType(k)
		net.WriteType(v)
	end

	-- End of table
	net.WriteType()
end

function net.ReadTable()
	local tab = {}

	while true do
		local k = net.ReadType()
		if k == nil then return tab end

		tab[k] = net.ReadType()
	end
end

local TYPE_NSHORT = 93
local TYPE_USHORT = TYPE_NSHORT + 1
local TYPE_NBYTE = TYPE_NSHORT + 2
local TYPE_UBYTE = TYPE_NSHORT + 3
local TYPE_NINT = TYPE_NSHORT + 4
local TYPE_UINT = TYPE_NSHORT + 5
local TYPE_FLOAT = TYPE_NSHORT + 6
local TYPE_ULONG = TYPE_NSHORT + 7
local TYPE_NLONG = TYPE_NSHORT + 8

net.WriteVars = {
	[TYPE_NIL]			= function(typeid, value) end,
	[TYPE_STRING]		= function(typeid, value) net.WriteString(value)	end,
	[TYPE_NUMBER]		= function(typeid, value) net.WriteDouble(value)	end,
	[TYPE_TABLE]		= function(typeid, value) net.WriteTable(value)		end,
	[TYPE_BOOL]			= function(typeid, value) net.WriteBool(value)		end,
	[TYPE_ENTITY]		= function(typeid, value) net.WriteEntity(value)	end,
	[TYPE_VECTOR]		= function(typeid, value) net.WriteVector(value)	end,
	[TYPE_ANGLE]		= function(typeid, value) net.WriteAngle(value)		end,
	[TYPE_MATRIX]		= function(typeid, value) net.WriteMatrix(value)	end,
	[TYPE_COLOR]		= function(typeid, value) net.WriteColor(value)		end,

	[TYPE_NSHORT]		= function(typeid, value) net.AccessWriteBuffer():WriteUShort(value:abs())		end,
	[TYPE_USHORT]		= function(typeid, value) net.AccessWriteBuffer():WriteUShort(value)		end,

	[TYPE_NBYTE]		= function(typeid, value) net.AccessWriteBuffer():WriteUByte(value:abs())		end,
	[TYPE_UBYTE]		= function(typeid, value) net.AccessWriteBuffer():WriteUByte(value)		end,

	[TYPE_NINT]		= function(typeid, value) net.AccessWriteBuffer():WriteUInt(value:abs())		end,
	[TYPE_UINT]		= function(typeid, value) net.AccessWriteBuffer():WriteUInt(value)		end,

	[TYPE_NINT]		= function(typeid, value) net.AccessWriteBuffer():WriteUInt(value:abs())		end,
	[TYPE_UINT]		= function(typeid, value) net.AccessWriteBuffer():WriteUInt(value)		end,

	[TYPE_NLONG]		= function(typeid, value) net.AccessWriteBuffer():WriteULong(value:abs())		end,
	[TYPE_ULONG]		= function(typeid, value) net.AccessWriteBuffer():WriteULong(value)		end,

	[TYPE_FLOAT]		= function(typeid, value) net.WriteFloat(value)		end,
}

function net.WriteType(v)
	local typeid

	if IsColor(v) then
		typeid = TYPE_COLOR
	else
		typeid = TypeID(v)
	end

	if typeid == TYPE_NUMBER then
		if v % 1 == 0 then
			if v >= 0 then
				if v < 0xFF then
					typeid = TYPE_UBYTE
				elseif v < 0xFFFF then
					typeid = TYPE_USHORT
				elseif v < 0xFFFFFFFF then
					typeid = TYPE_UINT
				else
					typeid = TYPE_ULONG
				end
			else
				local abs = math.abs(v)

				if abs < 0xFF then
					typeid = TYPE_NBYTE
				elseif abs < 0xFFFF then
					typeid = TYPE_NSHORT
				elseif abs < 0xFFFFFFFF then
					typeid = TYPE_NINT
				else
					typeid = TYPE_NLONG
				end
			end
		else
			typeid = math.abs(v) <= 262144 and TYPE_FLOAT or TYPE_NUMBER
		end
	end

	local writecallback = net.WriteVars[typeid]

	if writecallback then
		net.AccessWriteBuffer():WriteUByte(typeid)
		return writecallback(typeid, v)
	end

	error('net.WriteType: Can\'t write ' .. type( v ) .. ' (type ' .. typeid .. ') because there is no function assigned to that type')
end

net.ReadVars = {
	[TYPE_NIL]		= function ()	return nil end,
	[TYPE_STRING]	= function ()	return net.ReadString() end,
	[TYPE_NUMBER]	= function ()	return net.ReadDouble() end,
	[TYPE_TABLE]	= function ()	return net.ReadTable() end,
	[TYPE_BOOL]		= function ()	return net.ReadBool() end,
	[TYPE_ENTITY]	= function ()	return net.ReadEntity() end,
	[TYPE_VECTOR]	= function ()	return net.ReadVector() end,
	[TYPE_ANGLE]	= function ()	return net.ReadAngle() end,
	[TYPE_MATRIX]	= function ()	return net.ReadMatrix() end,
	[TYPE_COLOR]	= function ()	return net.ReadColor() end,

	[TYPE_NSHORT]		= function() return -net.AccessReadBuffer():ReadUShort()		end,
	[TYPE_USHORT]		= function() return net.AccessReadBuffer():ReadUShort()		end,

	[TYPE_NBYTE]		= function() return -net.AccessReadBuffer():ReadUByte()		end,
	[TYPE_UBYTE]		= function() return net.AccessReadBuffer():ReadUByte()		end,

	[TYPE_NINT]		= function() return -net.AccessReadBuffer():ReadUInt()		end,
	[TYPE_UINT]		= function() return net.AccessReadBuffer():ReadUInt()		end,

	[TYPE_NINT]		= function() return -net.AccessReadBuffer():ReadUInt()		end,
	[TYPE_UINT]		= function() return net.AccessReadBuffer():ReadUInt()		end,

	[TYPE_NLONG]		= function() return -net.AccessReadBuffer():ReadULong()		end,
	[TYPE_ULONG]		= function() return net.AccessReadBuffer():ReadULong()		end,

	[TYPE_FLOAT]		= function() return net.ReadFloat()		end,
}

function net.ReadType(typeid)
	typeid = typeid or net.AccessReadBuffer():ReadUByte()

	local readcallback = net.ReadVars[typeid]

	if readcallback then
		return readcallback()
	end

	error('net.ReadType: Can\'t read type ' .. typeid .. ' since it has no function assigned to that type')
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

function net.WriteBigInt(value)
	net.AccessWriteBuffer():WriteInt64(value)
end

function net.ReadBigInt()
	return net.AccessReadBuffer():ReadInt64()
end

function net.WriteBigUInt(value)
	net.AccessWriteBuffer():WriteUInt64(value)
end

function net.ReadBigUInt()
	return net.AccessReadBuffer():ReadUInt64()
end

net.WriteUInt64 = net.WriteBigUInt
net.WriteInt64 = net.WriteBigInt

net.ReadUInt64 = net.ReadBigUInt
net.ReadInt64 = net.ReadBigInt
