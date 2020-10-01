
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

net.WINDOW_SIZE_LIMIT = CreateConVar('dlib_net_window_size', '16777216', {}, 'limit in bytes. Too high values weaken server\'s security, too low may impact addons depending on DLib.net')
net.DGRAM_SIZE_LIMIT = CreateConVar('dlib_net_dgram_size', '65536', {}, 'limit in messages count. Too high values weaken server\'s security, too low may impact addons depending on DLib.net')
net.USE_COMPRESSION = CreateConVar('dlib_net_compress', '1', {FCVAR_REPLICATED, FCVAR_NOTIFY}, 'Use LZMA compression. Keep in mind source engine got one builtin serverside! Disable if net performance is low.')
net.COMPRESSION_LIMIT = CreateConVar('dlib_net_compress_size', '16384', {}, 'Size in bytes >= of single chunk to compress. Too low or too high values can impact performance.')

net.UpdateWindowProperties()

cvars.AddChangeCallback('dlib_net_window_size', net.UpdateWindowProperties, 'DLib.net')
cvars.AddChangeCallback('dlib_net_dgram_size', net.UpdateWindowProperties, 'DLib.net')
cvars.AddChangeCallback('dlib_net_compress_size', net.UpdateWindowProperties, 'DLib.net')

net.pool = _net.pool
net.pool('dlib_net_datagram')
net.pool('dlib_net_datagram_ack')
net.pool('dlib_net_ack1')
net.pool('dlib_net_ack2')
net.pool('dlib_net_chunk')
net.pool('dlib_net_chunk_ack')

function net.Send(target)
	if #net.active_write_buffers == 0 then
		error('No net message active to be sent')
	end

	if target == nil then
		table.remove(net.active_write_buffers)

		error('Target is nil')
	end

	if type(target) == 'Player' then
		if target:IsBot() then
			table.remove(net.active_write_buffers)
			return
		end

		net.Dispatch(target)
		table.remove(net.active_write_buffers)
		return
	end

	if not istable(target) and type(target) ~= 'CRecipientFilter' then
		table.remove(net.active_write_buffers)
		error('Target is not a table and is not a CRecipientFilter')
	end

	if istable(target) then
		for _, ply in pairs(target) do
			if IsValid(ply) and type(ply) == 'Player' and not ply:IsBot() then
				net.Dispatch(ply)
			end
		end

		table.remove(net.active_write_buffers)

		return
	elseif type(target) == 'CRecipientFilter' then
		for _, ply in pairs(target:GetPlayers()) do
			if IsValid(ply) and type(ply) == 'Player' and not ply:IsBot() then
				net.Dispatch(ply)
			end
		end

		table.remove(net.active_write_buffers)

		return
	end

	error('yo dude what the fuck')
end

function net.SendPVS(position)
	local filter = RecipientFilter()
	filter:AddPVS(position)
	net.Send(filter)
end

function net.SendPAS(position)
	local filter = RecipientFilter()
	filter:AddPAS(position)
	net.Send(filter)
end

function net.Broadcast(position)
	net.Send(player.GetHumans())
end

function net.SendOmit(data)
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

	net.Send(filter)
end

local GetHumans = player.GetHumans
local ipairs = ipairs
local next = next

function net.Namespace(target)
	if type(target) == 'Player' then
		if target.dlib_net ~= nil then return target.dlib_net end
		target.dlib_net = {}
		return net.Namespace(target.dlib_net)
	end

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

	target.last_expected_ack = target.last_expected_ack or 0xFFFFFFFF

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

function net.Think()
	local time = RealTime()
	local iter = GetHumans()

	for i = 1, #iter do
		local ply = iter[i]
		local namespace = net.Namespace(ply)

		if namespace.server_chunk_ack and (#namespace.server_queued ~= 0 or #namespace.server_chunks ~= 0) then
			net.DispatchChunk(ply)
		end

		if namespace.server_datagram_ack and namespace.server_datagrams_num > 0 then
			net.DispatchDatagram(ply)
		end

		if namespace.process_next and namespace.process_next < RealTime() then
			namespace.process_next = nil
			net.ProcessIncomingQueue(namespace, ply)
		end

		if namespace.last_expected_ack ~= 0xFFFFFFFF and namespace.last_expected_ack < time then
			-- can you hear me?
			_net.Start('dlib_net_ack1')
			_net.Send(ply)

			namespace.last_expected_ack = time + 10
		end

		if namespace.server_datagrams_num_warn ~= namespace.server_datagrams_num then
			namespace.server_datagrams_num_warn = namespace.server_datagrams_num

			if namespace.server_datagrams_num > 2001 then
				DLib.MessageWarning('DLib.net: Queued ', namespace.server_datagrams_num, ' datagrams for ', ply, '!')
			end
		end

		if namespace.server_queued_num_warn ~= namespace.server_queued_num then
			namespace.server_queued_num_warn = namespace.server_queued_num

			if namespace.server_queued_num > 2001 then
				DLib.MessageWarning('DLib.net: Queued ', namespace.server_queued_num, ' message payloads for ', ply, '!')
			end
		end
	end
end

hook.Add('Think', 'DLib.Net.ThinkChunks', net.Think)
