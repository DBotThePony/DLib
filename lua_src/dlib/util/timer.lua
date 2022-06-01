
-- Copyright (C) 2022 DBotThePony

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

local isnumber = isnumber
local isfunction = isfunction
local error = error
local type = type
local ProtectedCall = ProtectedCall
local abs = math.abs

function DLib.MakeTimer(name, timerFunction, oldTable)
	local meta = {}
	local head, tail
	local paused = {}

	function meta.GetHead()
		if not head then return end

		return {
			id = head.id,
			delay = head.delay,
			ends = head.ends,
			repeats = head.repeats,
			callback = head.callback,
		}
	end

	function meta.GetTail()
		if not tail then return end

		return {
			id = tail.id,
			delay = tail.delay,
			ends = tail.ends,
			repeats = tail.repeats,
			callback = tail.callback,
		}
	end

	local hookId = 'DLib ' .. name .. ' Timer'

	local function find(id)
		local next = head

		while next do
			if next.id == id then return next end
			next = next.next
		end

		return
	end

	local iteratingTimer
	local removeIteratingTimer = false

	function meta.Pause(id)
		if not isstring(id) then
			error('Bad argument #1 to Pause (string expected, got ' .. type(id) .. ')', 2)
		end

		if paused[id] then return false end
		local found = find(id)
		if not found then return false end

		if iteratingTimer == id then
			removeIteratingTimer = true
		end

		paused[id] = found
		found.ends = found.ends - timerFunction()

		if found.next then
			found.next.prev = found.prev
		end

		if found.prev then
			found.prev.next = found.next
		end

		if found == head then
			head = found.next
		end

		if found == tail then
			tail = found.prev
		end

		found.prev = nil
		found.next = nil

		if not head then
			hook.DisableHook('Think', hookId)
		end

		return true
	end

	local function insertQueue(data)
		if paused[data.id] then
			paused[data.id] = nil
		end

		if not head then
			head = data
			tail = data
			hook.EnableHook('Think', hookId)
		elseif data.ends <= timerFunction() then
			head.prev = data
			data.next = head
			head = data
		elseif abs(head.ends - data.ends) <= abs(tail.ends - data.ends) then
			-- вставка с головы
			local prev
			local next = head
			local thisTime = timerFunction()
			local put = false

			while next ~= nil do
				if next.ends >= data.ends then
					next.prev = data

					if prev then
						prev.next = data
					end

					data.next = next
					data.prev = prev

					if next == head then
						head = data
					end

					put = true

					break
				else
					prev = next
					next = next.next
				end
			end

			-- вставка в самый конец списка
			if not put then
				prev.next = data
				data.prev = prev
				tail = data
			end
		else
			-- вставка с хвоста
			local prev = tail
			local next
			local thisTime = timerFunction()
			local put = false

			while prev ~= nil do
				if prev.ends <= data.ends then
					prev.next = data

					if next then
						next.prev = data
					end

					data.next = next
					data.prev = prev

					if prev == tail then
						tail = data
					end

					put = true
					break
				else
					next = prev
					prev = prev.prev
				end
			end

			-- вставка в начало списка невозможна в данном случае, ибо иначе мы бы вставляли с головы списка
			if not put then
				error(string.format('This piece of code should be unreachable, input number was: %f, head %f, tail %f', data.ends, head.ends, tail.ends))
			end
		end
	end

	function meta.UnPause(id)
		if not isstring(id) then
			error('Bad argument #1 to UnPause (string expected, got ' .. type(id) .. ')', 2)
		end

		if not paused[id] then return false end
		local found = paused[id]
		paused[id] = nil
		found.ends = found.ends + timerFunction()

		insertQueue(found)
		return true
	end

	function meta.Toggle(id)
		if not isstring(id) then
			error('Bad argument #1 to Toggle (string expected, got ' .. type(id) .. ')', 2)
		end

		if not paused[id] then
			meta.Pause(id)
			return false
		end

		meta.UnPause(id)
		return true
	end

	function meta.TimeLeft(id)
		if not isstring(id) then
			error('Bad argument #1 to TimeLeft (string expected, got ' .. type(id) .. ')', 2)
		end

		local found = paused[id]

		if found then
			return -paused.ends
		end

		found = find(id)

		if not found then return end
		return found.ends - timerFunction()
	end

	function meta.RepsLeft(id)
		if not isstring(id) then
			error('Bad argument #1 to RepsLeft (string expected, got ' .. type(id) .. ')', 2)
		end

		local found = paused[id] or find(id)

		if found then
			return paused.repeats
		end
	end

	function meta.Exists(id)
		if not isstring(id) then
			error('Bad argument #1 to Exists (string expected, got ' .. type(id) .. ')', 2)
		end

		return (paused[id] or find(id)) ~= nil
	end

	function meta.Simple(time, callback)
		if not isnumber(time) then
			error('Bad argument #1 to Simple (number expected, got ' .. type(time) .. ')', 2)
		end

		if not isfunction(callback) then
			error('Bad argument #2 to Simple (function expected, got ' .. type(callback) .. ')', 2)
		end

		local currentTime = timerFunction()

		local data = {
			id = currentTime + time,
			delay = time,
			ends = currentTime + time,
			repeats = 1,
			callback = callback
		}

		insertQueue(data)
	end

	function meta.Create(id, time, repeats, callback)
		if not isstring(id) then
			error('Bad argument #1 to Create (string expected, got ' .. type(id) .. ')', 2)
		end

		if not isnumber(time) then
			error('Bad argument #2 to Create (number expected, got ' .. type(time) .. ')', 2)
		end

		if not isnumber(repeats) then
			error('Bad argument #3 to Create (number expected, got ' .. type(repeats) .. ')', 2)
		end

		if not isfunction(callback) then
			error('Bad argument #4 to Simple (function expected, got ' .. type(callback) .. ')', 2)
		end

		meta.Remove(id)

		repeats = repeats:round()

		if repeats <= 0 then
			repeats = math.huge
		end

		local data = {
			id = id,
			delay = time,
			ends = timerFunction() + time,
			repeats = repeats,
			callback = callback
		}

		insertQueue(data)
	end

	function meta.Adjust(id, time, repeats, callback)
		if not isstring(id) then
			error('Bad argument #1 to Adjust (string expected, got ' .. type(id) .. ')', 2)
		end

		if not isnumber(time) then
			error('Bad argument #2 to Adjust (number expected, got ' .. type(time) .. ')', 2)
		end

		local found = paused[id]
		local isPaused = found ~= nil
		found = found or find(id)

		if not found then return false end

		if isPaused then
			found.ends = time
		else
			found.ends = timerFunction() + time
			local unbalanced = false

			if found.next and found.next.ends < found.ends then
				unbalanced = true
			end

			if not unbalanced and found.prev.ends > found.ends then
				unbalanced = true
			end

			if unbalanced then
				if found.prev then
					found.prev.next = found.next
				end

				if found.next then
					found.next.prev = found.prev
				end

				found.prev = nil
				found.next = nil
				insertQueue(data)
			end
		end

		found.delay = time

		if repeats ~= nil then
			if not isnumber(repeats) then
				error('Bad argument #3 to Adjust (number expected, got ' .. type(repeats) .. ')', 2)
			end

			repeats = repeats:round()

			if repeats <= 0 then
				repeats = math.huge
			end

			found.repeats = repeats
		end

		if callback ~= nil then
			if not isfunction(callback) then
				error('Bad argument #4 to Adjust (function expected, got ' .. type(callback) .. ')', 2)
			end

			found.callback = callback
		end

		return true
	end

	function meta.GetList()
		local result = {}
		local i = 1
		local next = head

		while next ~= nil do
			result[i] = {
				id = next.id,
				delay = next.delay,
				ends = next.ends,
				repeats = next.repeats,
				callback = next.callback,
			}

			i = i + 1
			next = next.next
		end

		for key, value in pairs(paused) do
			result[i] = {
				id = value.id,
				delay = value.delay,
				ends = value.ends,
				paused_at = value.paused_at,
				repeats = value.repeats,
				callback = value.callback,
			}

			i = i + 1
		end

		return result
	end

	if istable(oldTable) and isfunction(oldTable.GetList) then
		for i, data in ipairs(oldTable.GetList()) do
			if data.paused_at then
				paused[data.id] = data
			else
				insertQueue(data)
			end
		end
	end

	function meta.Remove(id)
		if not isstring(id) then
			error('Bad argument #1 to Remove (string expected, got ' .. type(id) .. ')', 2)
		end

		local found = paused[id]

		if found then
			paused[id] = nil
			return true, found
		end

		local prev
		local next = head

		while next do
			if next.id == id then
				if iteratingTimer == id then
					removeIteratingTimer = true
				end

				if prev then
					prev.next = next.next

					if prev.next then
						prev.next.prev = prev
					end
				end

				if next == head then
					head = next.next
				end

				if next == tail then
					tail = next.prev
				end

				return true, next
			end

			prev = next
			next = next.next
		end

		return false
	end

	local _protectedCallback

	local function protectedCallback()
		_protectedCallback()
	end

	hook.Add('Think', hookId, function()
		if not head then
			hook.DisableHook('Think', hookId)
			return
		end

		local time = timerFunction()
		local next = head

		while next and next.ends <= time do
			local _next = next.next

			_protectedCallback = next.callback
			iteratingTimer = next.id
			removeIteratingTimer = false
			ProtectedCall(protectedCallback)
			_protectedCallback = nil -- очистка gc handle

			next.repeats = next.repeats - 1

			if not removeIteratingTimer then
				if next.repeats <= 0 then
					if next.prev then
						next.prev.next = next.next
					end

					if next.next then
						next.next.prev = next.prev
					end

					if head == next then
						head = next.next
					end

					if tail == next then
						tail = next.prev
					end
				else
					next.ends = time + next.delay - (time - next.ends)

					if next.next and next.next.ends < next.ends then
						-- теперь нам надо "всплыть" по листу
						if next.next then
							next.next.prev = next.prev
						end

						if next.prev then
							next.prev.next = next.next
						end

						if head == next then
							head = next.next
						end

						if tail == next then
							tail = next.prev
						end

						next.next = nil
						next.prev = nil

						insertQueue(next)
					end
				end
			elseif next.repeats <= 0 and paused[iteratingTimer] then
				-- мы поставили на паузу "мёртвый" таймер...
				meta.Remove(iteratingTimer)
			else
				next.ends = time + next.delay - (time - next.ends)
			end

			next = _next
		end

		if head == nil then
			tail = nil
			hook.DisableHook('Think', hookId)
		end
	end)

	return meta
end

DLib.SysTimer = DLib.MakeTimer('SysTime', SysTime, DLib.SysTimer)
DLib.CurTimer = DLib.MakeTimer('CurTime', CurTime, DLib.CurTimer)
DLib.RealTimer = DLib.MakeTimer('RealTime', RealTime, DLib.RealTimer)
