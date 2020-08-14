
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

net.WINDOW_SIZE_LIMIT = CreateConVar('dlib_net_window_size', '16777216', {}, 'limit in bytes. Too low may impact addons depending on DLib.net')
net.DGRAM_SIZE_LIMIT = CreateConVar('dlib_net_dgram_size', '65536', {}, 'limit in messages count. Too low may impact addons depending on DLib.net')
net.USE_COMPRESSION = CreateConVar('dlib_net_compress_cl', '1', {}, 'Use LZMA compression. Disable if net performance is low.')
net.USE_COMPRESSION_SV = CreateConVar('dlib_net_compress', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'Whenever server accept LZMA compressed payloads.')
net.COMPRESSION_LIMIT = CreateConVar('dlib_net_compress_size', '16384', {}, 'Size in bytes >= of single chunk to compress. Too low or too high values can impact performance.')

net.UpdateWindowProperties()

cvars.AddChangeCallback('dlib_net_window_size', net.UpdateWindowProperties, 'DLib.net')
cvars.AddChangeCallback('dlib_net_dgram_size', net.UpdateWindowProperties, 'DLib.net')
cvars.AddChangeCallback('dlib_net_compress_size', net.UpdateWindowProperties, 'DLib.net')

net.network_position = net.network_position or 0
net.accumulated_size = net.accumulated_size or 0
net.queued_buffers = net.queued_buffers or {}
net.queued_chunks = net.queued_chunks or {}
net.queued_datagrams = net.queued_datagrams or {}

net.server_position = net.server_position or 0
net.server_chunks = net.server_chunks or {}
net.server_queued = net.server_queued or {}
net.server_datagrams = net.server_datagrams or {}

net.queued_buffers_num = net.queued_buffers_num or 0
net.queued_chunks_num = net.queued_chunks_num or 0
net.queued_datagrams_num = net.queued_datagrams_num or 0

net.server_chunks_num = net.server_chunks_num or 0
net.server_queued_num = net.server_queued_num or 0
net.server_datagrams_num = net.server_datagrams_num or 0

net.next_expected_datagram = net.next_expected_datagram or -1
net.last_expected_ack = net.last_expected_ack or 0xFFFFFFFF
net.server_queued_size = net.server_queued_size or 0

net.next_datagram_id = net.next_datagram_id or 0

if net.server_datagram_ack == nil then
	net.server_datagram_ack = true
end

if net.server_chunk_ack == nil then
	net.server_chunk_ack = true
end

function net.SendToServer()
	if #net.active_write_buffers == 0 then
		error('No net message active to be sent')
	end

	net.Dispatch()
	table.remove(net.active_write_buffers)
end

local RealTime = RealTime

function net.Think()
	if net.server_chunk_ack and (#net.server_queued ~= 0 or #net.server_chunks ~= 0) then
		net.DispatchChunk()
	end

	if net.server_datagram_ack and net.server_datagrams_num > 0 then
		net.DispatchDatagram()
	end

	local time = RealTime()

	if net.last_expected_ack ~= 0xFFFFFFFF and net.last_expected_ack < time then
		-- can you hear me?
		_net.Start('dlib_net_ack1')
		_net.SendToServer()

		net.last_expected_ack = time + 30
	end
end

hook.Add('Think', 'DLib.Net.ThinkChunks', net.Think)
