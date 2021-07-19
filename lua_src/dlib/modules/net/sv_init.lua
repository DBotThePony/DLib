
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

Net.WINDOW_SIZE_LIMIT = CreateConVar('dlib_net_window_size', '16777216', {}, 'limit in bytes. Too high values weaken server\'s security, too low may impact addons depending on DLib.Net')
Net.DGRAM_SIZE_LIMIT = CreateConVar('dlib_net_dgram_size', '65536', {}, 'limit in messages count. Too high values weaken server\'s security, too low may impact addons depending on DLib.Net')
Net.USE_COMPRESSION = CreateConVar('dlib_net_compress', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'Use LZMA compression. Keep in mind source engine got one builtin serverside! Disable if DLib.Net performance is low.')
Net.COMPRESSION_LIMIT = CreateConVar('dlib_net_compress_size', '16384', {}, 'Size in bytes >= of single chunk to compress. Too low or too high values can impact performance.')

Net.UpdateWindowProperties()

cvars.AddChangeCallback('dlib_net_window_size', Net.UpdateWindowProperties, 'DLib.Net')
cvars.AddChangeCallback('dlib_net_dgram_size', Net.UpdateWindowProperties, 'DLib.Net')
cvars.AddChangeCallback('dlib_net_compress_size', Net.UpdateWindowProperties, 'DLib.Net')

Net.pool = _net.pool
Net.Pool = _net.pool
Net.pool('dlib_net_datagram')
Net.pool('dlib_net_datagram_ack')
Net.pool('dlib_net_ack1')
Net.pool('dlib_net_ack2')
Net.pool('dlib_net_chunk')
Net.pool('dlib_net_chunk_ack')

local error = error
local type = type
local istable = istable
local table_remove = table.remove
local pairs = pairs
local IsValid = IsValid

function Net.Send(target)
	if #Net.active_write_buffers == 0 then
		error('No network message active to be sent')
	end

	if target == nil then
		table_remove(Net.active_write_buffers)

		error('Target is nil')
	end

	if type(target) == 'Player' then
		if target:IsBot() then
			table.remove(Net.active_write_buffers)
			return
		end

		Net.Dispatch(target)
		table_remove(Net.active_write_buffers)
		return
	end

	if not istable(target) and type(target) ~= 'CRecipientFilter' then
		table_remove(Net.active_write_buffers)
		error('Target is not a table and is not a CRecipientFilter')
	end

	if istable(target) then
		for _, ply in pairs(target) do
			if IsValid(ply) and type(ply) == 'Player' and not ply:IsBot() then
				Net.Dispatch(ply)
			end
		end

		table_remove(Net.active_write_buffers)

		return
	elseif type(target) == 'CRecipientFilter' then
		for _, ply in pairs(target:GetPlayers()) do
			if IsValid(ply) and type(ply) == 'Player' and not ply:IsBot() then
				Net.Dispatch(ply)
			end
		end

		table_remove(Net.active_write_buffers)

		return
	end

	error('yo dude what the fuck')
end

local RecipientFilter = RecipientFilter

function Net.SendPVS(position)
	local filter = RecipientFilter()
	filter:AddPVS(position)
	Net.Send(filter)
end

function Net.SendPAS(position)
	local filter = RecipientFilter()
	filter:AddPAS(position)
	Net.Send(filter)
end

local player_GetHumans = player.GetHumans

function Net.Broadcast(position)
	Net.Send(player_GetHumans())
end

local ipairs = ipairs

function Net.SendOmit(data)
	local filter = RecipientFilter()
	filter:AddAllPlayers()

	if type(data) == 'Player' then
		filter:RemovePlayer(data)
	elseif type(data) == 'table' then
		for _, ply in ipairs(data) do
			if IsValid(ply) then
				filter:RemovePlayer(ply)
			end
		end
	end

	Net.Send(filter)
end

local isentity = isentity
local GetTable = FindMetaTable('Entity').GetTable

function Net.Namespace(target)
	if isentity(target) then
		local get_target = GetTable(target).dlib_net

		if get_target ~= nil then
			return get_target
		end

		target.dlib_net = {}
		return Net.Namespace(target.dlib_net)
	end

	if target.use_unreliable == nil then
		target.use_unreliable = true
	end

	target.total_traffic_in = target.total_traffic_in or 0
	target.total_traffic_out = target.total_traffic_out or 0

	target.reliable_score = target.reliable_score or 0
	target.reliable_score_dg = target.reliable_score_dg or 0
	target.network_position = target.network_position or 0
	target.accumulated_size = target.accumulated_size or 0
	target.queued_buffers = target.queued_buffers or {}
	target.queued_buffers_num = target.queued_buffers_num or 0
	target.queued_chunks = target.queued_chunks or {}
	target.queued_chunks_num = target.queued_chunks_num or 0
	target.queued_datagrams = target.queued_datagrams or {}
	target.queued_datagrams_num = target.queued_datagrams_num or 0

	target.server_position = target.server_position or 0
	target.server_chunks = target.server_chunks or {}
	target.server_chunks_num = target.server_chunks_num or 0
	target.server_queued = target.server_queued or {}
	target.server_queued_num = target.server_queued_num or 0
	target.server_queued_size = target.server_queued_size or 0
	target.server_datagrams = target.server_datagrams or {}
	target.server_datagrams_num = target.server_datagrams_num or 0
	target.next_expected_datagram = target.next_expected_datagram or 0
	target.next_expected_chunk = target.next_expected_chunk or 0

	target.next_datagram_id = target.next_datagram_id or 0
	target.next_chunk_id = target.next_chunk_id or 0

	if target.server_datagram_ack == nil then
		target.server_datagram_ack = true
	end

	if target.server_chunk_ack == nil then
		target.server_chunk_ack = true
	end

	return target
end

local SysTime = SysTime

function Net.Think()
	local time = SysTime()
	local iter = player_GetHumans()

	for i = 1, #iter do
		local ply = iter[i]
		local namespace = Net.Namespace(ply)

		if namespace.server_chunk_ack and (#namespace.server_queued ~= 0 or #namespace.server_chunks ~= 0) then
			Net.DispatchChunk(ply)
		end

		if namespace.server_datagram_ack and namespace.server_datagrams_num > 0 then
			Net.DispatchDatagram(ply)
		end

		if namespace.process_next and namespace.process_next < time then
			namespace.process_next = nil
			Net.ProcessIncomingQueue(namespace, ply)
		end

		if namespace.last_expected_ack and namespace.last_expected_ack < time then
			-- can ANYONE HEAR MEEEE?
			_net.Start('dlib_net_ack1', true)
			_net.Send(ply)

			namespace.last_expected_ack = time + Net.reliable_window
		end

		if namespace.last_expected_ack_chunks and namespace.last_expected_ack_chunks < time then
			-- can ANYONE HEAR MEEEE?
			_net.Start('dlib_net_ack1', true)
			_net.Send(ply)

			namespace.last_expected_ack_chunks = time + Net.reliable_window
		end

		if namespace.server_datagrams_num_warn ~= namespace.server_datagrams_num then
			namespace.server_datagrams_num_warn = namespace.server_datagrams_num

			if namespace.server_datagrams_num > 2001 and (namespace.datagram_last_warning or 0) < SysTime() then
				DLib.MessageWarning('DLib.Net: Queued ', namespace.server_datagrams_num, ' datagrams for ', ply, '!')
				namespace.datagram_last_warning = SysTime() + 4
			end
		end

		if namespace.server_queued_num_warn ~= namespace.server_queued_num then
			namespace.server_queued_num_warn = namespace.server_queued_num

			if namespace.server_queued_num > 2001 and (namespace.chunk_last_warning or 0) < SysTime() then
				DLib.MessageWarning('DLib.Net: Queued ', namespace.server_queued_num, ' message payloads for ', ply, '!')
				namespace.chunk_last_warning = SysTime() + 4
			end
		end
	end
end

hook.Add('Think', 'DLib.Net.ThinkChunks', Net.Think, 10)
