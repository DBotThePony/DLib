
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
local Net = DLib.Net

Net.BUFFER_SIZE_LIMIT = CreateConVar('dlib_net_buffer_size', '16777216', {}, 'limit in bytes. Too low may impact addons depending on DLib.Net')
Net.DGRAM_SIZE_LIMIT = CreateConVar('dlib_net_dgram_size', '65536', {}, 'limit in messages count. Too low may impact addons depending on DLib.Net')
Net.USE_COMPRESSION = CreateConVar('dlib_net_compress_cl', '1', {}, 'Use LZMA compression. Disable if Net performance is low.')
Net.USE_COMPRESSION_SV = CreateConVar('dlib_net_compress', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'Whenever server accept LZMA compressed payloads.')
Net.COMPRESSION_LIMIT = CreateConVar('dlib_net_compress_size', '16384', {}, 'Size in bytes >= of single chunk to compress. Too low or too high values can impact performance.')

Net.USE_WINDOW = CreateConVar('dlib_net_use_window_cl', '1', {}, 'Use window to wildly improve network performance with high RTT')

Net.UpdateWindowProperties()

cvars.AddChangeCallback('dlib_net_buffer_size', Net.UpdateWindowProperties, 'DLib.Net')
cvars.AddChangeCallback('dlib_net_dgram_size', Net.UpdateWindowProperties, 'DLib.Net')
cvars.AddChangeCallback('dlib_net_compress_size', Net.UpdateWindowProperties, 'DLib.Net')

if Net.use_unreliable == nil then
	Net.use_unreliable = true
end

Net.use_unreliable_next_try = Net.use_unreliable_next_try or 0

Net.reliable_score = Net.reliable_score or 0
Net.reliable_score_dg = Net.reliable_score_dg or 0

Net.network_position = Net.network_position or 0
Net.accumulated_size = Net.accumulated_size or 0
Net.queued_buffers = Net.queued_buffers or {}
Net.queued_chunks = Net.queued_chunks or {}
Net.queued_datagrams = Net.queued_datagrams or {}

Net.server_position = Net.server_position or 0
Net.server_chunks = Net.server_chunks or {}
Net.server_queued = Net.server_queued or {}
Net.server_datagrams = Net.server_datagrams or {}
Net.server_datagrams_pending = Net.server_datagrams_pending or {}
Net.next_sensible_pending_dg_check = Net.next_sensible_pending_dg_check or 0

Net.queued_buffers_num = Net.queued_buffers_num or 0
Net.queued_chunks_num = Net.queued_chunks_num or 0
Net.queued_datagrams_num = Net.queued_datagrams_num or 0

Net.server_chunks_num = Net.server_chunks_num or 0
Net.server_queued_num = Net.server_queued_num or 0
Net.server_datagrams_num = Net.server_datagrams_num or 0

Net.next_expected_datagram = Net.next_expected_datagram or 0
Net.next_expected_chunk = Net.next_expected_chunk or 0

Net.server_queued_size = Net.server_queued_size or 0

Net.next_datagram_id = Net.next_datagram_id or 0
Net.next_chunk_id = Net.next_chunk_id or 0

Net.unacked_payload = Net.unacked_payload or 0
Net.unacked_datagrams = Net.unacked_datagrams or 0

if Net.server_datagram_ack == nil then
	Net.server_datagram_ack = true
end

if Net.server_chunk_ack == nil then
	Net.server_chunk_ack = true
end

local table_remove = table.remove

function Net.SendToServer()
	if #Net.active_write_buffers == 0 then
		error('No Net message active to be sent')
	end

	Net.Dispatch()
	table_remove(Net.active_write_buffers)
end

local SysTime = SysTime
local LocalPlayer = LocalPlayer
local IsValid = FindMetaTable('Entity').IsValid

function Net.Think()
	local time = SysTime()

	if Net.use_unreliable_next_try < time then
		Net.use_unreliable = true
	end

	if (Net.server_chunk_ack or Net.use_unreliable and Net.unacked_payload < Net.window_size_limit_payload and Net.USE_WINDOW:GetBool()) and (#Net.server_queued ~= 0 or #Net.server_chunks ~= 0) then
		Net.DispatchChunk()
	end

	if (Net.server_datagram_ack or Net.use_unreliable and Net.unacked_datagrams < Net.window_size_limit_datagram and Net.USE_WINDOW:GetBool()) and Net.server_datagrams_num > 0 then
		Net.DispatchDatagram()
	end

	if Net.last_expected_ack and Net.last_expected_ack < time then
		-- can ANYONE HEAR MEEEE?
		_net.Start('dlib_net_ack1', true)
		_net.SendToServer()

		Net.last_expected_ack = time + Net.reliable_window

		if Net.last_expected_ack_chunks then
			Net.last_expected_ack_chunks = time + Net.reliable_window
		end
	end

	if Net.last_expected_ack_chunks and Net.last_expected_ack_chunks < time then
		-- can ANYONE HEAR MEEEE?
		_net.Start('dlib_net_ack1', true)
		_net.SendToServer()

		if Net.last_expected_ack then
			Net.last_expected_ack = time + Net.reliable_window
		end

		Net.last_expected_ack_chunks = time + Net.reliable_window
	end

	if Net.process_next and Net.process_next < time and IsValid(LocalPlayer()) then
		Net.process_next = nil
		Net.ProcessIncomingQueue(DLib.Net)
	end
end

hook.Add('Think', 'DLib.Net.ThinkChunks', Net.Think)

function Net.Namespace()
	return Net
end
