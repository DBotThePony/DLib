
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
		filer:RemovePlayer(data)
	elseif type(data) == 'table' then
		for _, ply in ipairs(data) do
			if IsValid(ply) then
				filter:RemovePlayer(ply)
			end
		end
	end

	net.Send(filer)
end

function net.Think()
	local time = RealTime()

	for _, ply in ipairs(player.GetHumans()) do
		local namespace = net.Namespace(ply)

		if (#namespace.server_queued ~= 0 or #namespace.server_chunks ~= 0) and namespace.server_chunk_ack then
			net.DispatchChunk(ply)
		end

		if next(namespace.server_datagrams) and namespace.server_datagram_ack then
			net.DispatchDatagram(ply)
		end

		if namespace.last_expected_ack ~= 0xFFFFFFFF and namespace.last_expected_ack < time then
			-- can you hear me?
			_net.Start('dlib_net_ack1')
			_net.Send(ply)

			namespace.last_expected_ack = time + 30
		end
	end
end

hook.Add('Think', 'DLib.Net.ThinkChunks', net.Think)
