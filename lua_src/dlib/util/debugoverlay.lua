
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

local _debugoverlay = debugoverlay
DLib.debugoverlay = DLib.debugoverlay or {}
DLib.debugoverlay2 = DLib.debugoverlay2 or {}
local debugoverlay = DLib.debugoverlay
local debugoverlay2 = DLib.debugoverlay2

local DLib = DLib
local net = DLib.net

local funcs = {
	Axis = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteAngleDouble, net.ReadAngleDouble},
		{nil, net.WriteDouble, net.ReadDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{false, net.WriteBool, net.ReadBool}, -- ignoreZ
	},

	Box = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
	},

	BoxAngles = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteAngleDouble, net.ReadAngleDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
	},

	Cross = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteDouble, net.ReadDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
		{false, net.WriteBool, net.ReadBool}, -- ignoreZ
	},

	EntityTextAtPosition = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteUInt16, net.ReadUInt16},
		{nil, net.WriteString, net.ReadString},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
	},

	Grid = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
	},

	Line = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
		{false, net.WriteBool, net.ReadBool}, -- ignoreZ
	},

	ScreenText = {
		{nil, net.WriteUInt16, net.ReadUInt16},
		{nil, net.WriteUInt16, net.ReadUInt16},
		{nil, net.WriteString, net.ReadString},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
	},

	Sphere = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteDouble, net.ReadDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
		{false, net.WriteBool, net.ReadBool}, -- ignoreZ
	},

	SweptBox = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteAngleDouble, net.ReadAngleDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
	},

	Text = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteString, net.ReadString},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{false, net.WriteBool, net.ReadBool}, -- color
	},

	Triangle = {
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{nil, net.WriteVectorDouble, net.ReadVectorDouble},
		{1, net.WriteDouble, net.ReadDouble}, -- lifetime
		{color_white, net.WriteColor, net.ReadColor}, -- color
		{false, net.WriteBool, net.ReadBool}, -- ignoreZ
	},
}

local developer = ConVar('developer')

for funcname, funcargs in pairs(funcs) do
	local bakeread, bakewrite, bakeargs, bakeargs2, bakeargs3, bakeargs4 = {}, {}, {}, {}, {}, {}

	for argpos, argdata in ipairs(funcargs) do
		table.insert(bakewrite, argdata[2])
		table.insert(bakeread, argdata[3])
		table.insert(bakeargs, 'func' .. argpos)
		table.insert(bakeargs4, 'val' .. argpos)
		table.insert(bakeargs2, 'func' .. argpos .. '()')
		table.insert(bakeargs3, 'func' .. argpos .. '(val' .. argpos .. ')')
	end

	local readfunc = CompileString('return function(' .. table.concat(bakeargs, ', ') .. ') return function() return ' .. table.concat(bakeargs2, ', ') .. ' end end', 'DLib.debugoverlay')()(unpack(bakeread))
	local writefunc = CompileString('return function(' .. table.concat(bakeargs, ', ') .. ') return function(' .. table.concat(bakeargs4, ', ') .. ') return ' .. table.concat(bakeargs3, ', ') .. ' end end', 'DLib.debugoverlay')()(unpack(bakewrite))
	local upvalue = _debugoverlay[funcname]
	local nwname = 'dlib_debugoverlay_' .. funcname:lower()

	if SERVER then
		net.pool(nwname)
	else
		net.receive(nwname, function()
			upvalue(readfunc())
		end)
	end

	local function debugfunc(...)
		if CLIENT or game.SinglePlayer() then
			upvalue(...)
			return
		end

		local lastarg = select(#funcargs + 1, ...)

		if lastarg == true or isentity(lastarg) or (game.IsDedicated() or player.GetCount() ~= 1) and developer:GetBool() then
			net.Start(nwname)
			writefunc(...)

			if isentity(lastarg) then
				net.Send(lastarg)
			elseif game.IsDedicated() then
				net.Broadcast()
			else
				net.SendOmit(Entity(1))
				upvalue(...)
			end
		end
	end

	local function debugfunc2(...)
		if CLIENT then
			upvalue(...)
			return
		end

		local lastarg = select(#funcargs + 1, ...)

		net.Start(nwname)
		writefunc(...)

		if isentity(lastarg) then
			net.Send(lastarg)
		else
			net.Broadcast()
		end
	end

	debugoverlay[funcname] = debugfunc
	debugoverlay2[funcname] = debugfunc
end

function debugoverlay.BoxAABB(mins, maxs, lifetime, color)
	lifetime = lifetime or 1
	color = color or color_white

	local origin = DLib.vector.Centre(mins, maxs)
	mins = origin - mins
	maxs = origin - maxs

	return debugoverlay.Box(origin, mins, maxs, lifetime, color)
end

function debugoverlay.BoxAnglesAABB(mins, maxs, ang, lifetime, color)
	lifetime = lifetime or 1
	color = color or color_white

	local origin = DLib.vector.Centre(mins, maxs)
	mins = origin - mins
	maxs = origin - maxs

	return debugoverlay.BoxAngles(origin, mins, maxs, ang, lifetime, color)
end

function debugoverlay2.BoxAABB(mins, maxs, lifetime, color)
	lifetime = lifetime or 1
	color = color or color_white

	local origin = DLib.vector.Centre(mins, maxs)
	mins = origin - mins
	maxs = origin - maxs

	return debugoverlay2.Box(origin, mins, maxs, lifetime, color)
end

function debugoverlay2.BoxAnglesAABB(mins, maxs, ang, lifetime, color)
	lifetime = lifetime or 1
	color = color or color_white

	local origin = DLib.vector.Centre(mins, maxs)
	mins = origin - mins
	maxs = origin - maxs

	return debugoverlay2.BoxAngles(origin, mins, maxs, ang, lifetime, color)
end
