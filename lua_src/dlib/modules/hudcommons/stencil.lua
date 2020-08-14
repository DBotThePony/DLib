
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

-- idk

local HUDCommons = DLib.HUDCommons
local render = render
HUDCommons.Stencil = {}
local stencil = HUDCommons.Stencil
local error = error
local surface = surface
local draw = draw

local working = false
local STENCIL_ALWAYS = STENCIL_ALWAYS
local STENCIL_REPLACE = STENCIL_REPLACE
local STENCIL_KEEP = STENCIL_KEEP
local STENCIL_INCRSAT = STENCIL_INCRSAT
local STENCIL_EQUAL = STENCIL_EQUAL

local LastStencilCompareFunction
local PrevStencilCompareFunction

local function SetStencilCompareFunction(arg)
	PrevStencilCompareFunction = LastStencilCompareFunction or arg
	LastStencilCompareFunction = arg
	return render.SetStencilCompareFunction(arg)
end

local function GetStencilCompareFunction()
	return LastStencilCompareFunction
end

local function GetPreviousStencilCompareFunction()
	return PrevStencilCompareFunction
end

local function ReturnStencilCompareFunction()
	local b1, b2 = LastStencilCompareFunction, PrevStencilCompareFunction
	LastStencilCompareFunction = b2
	PrevStencilCompareFunction = b1
	return render.SetStencilCompareFunction(b2)
end

local LastStencilPassOperation
local PrevStencilPassOperation

local function SetStencilPassOperation(arg)
	PrevStencilPassOperation = LastStencilPassOperation or arg
	LastStencilPassOperation = arg
	return render.SetStencilPassOperation(arg)
end

local function GetStencilPassOperation()
	return LastStencilPassOperation
end

local function GetPreviousStencilPassOperation()
	return PrevStencilPassOperation
end

local function ReturnStencilPassOperation()
	local b1, b2 = LastStencilPassOperation, PrevStencilPassOperation
	LastStencilPassOperation = b2
	PrevStencilPassOperation = b1
	return render.SetStencilPassOperation(b2)
end

local LastStencilFailOperation
local PrevStencilFailOperation

local function SetStencilFailOperation(arg)
	PrevStencilFailOperation = LastStencilFailOperation or arg
	LastStencilFailOperation = arg
	return render.SetStencilFailOperation(arg)
end

local function GetStencilFailOperation()
	return LastStencilFailOperation
end

local function GetPreviousStencilFailOperation()
	return PrevStencilFailOperation
end

local function ReturnStencilFailOperation()
	local b1, b2 = LastStencilFailOperation, PrevStencilFailOperation
	LastStencilFailOperation = b2
	PrevStencilFailOperation = b1
	return render.SetStencilFailOperation(b2)
end

local LastStencilReferenceValue
local PrevStencilReferenceValue

local function SetStencilReferenceValue(arg)
	PrevStencilReferenceValue = LastStencilReferenceValue or arg
	LastStencilReferenceValue = arg
	return render.SetStencilReferenceValue(arg)
end

local function GetStencilReferenceValue()
	return LastStencilReferenceValue
end

local function GetPreviousStencilReferenceValue()
	return PrevStencilReferenceValue
end

local function ReturnStencilReferenceValue()
	local b1, b2 = LastStencilReferenceValue, PrevStencilReferenceValue
	LastStencilReferenceValue = b2
	PrevStencilReferenceValue = b1
	return render.SetStencilReferenceValue(b2)
end

local LastStencilTestMask
local PrevStencilTestMask

local function SetStencilTestMask(arg)
	PrevStencilTestMask = LastStencilTestMask or arg
	LastStencilTestMask = arg
	return render.SetStencilTestMask(arg)
end

local function GetStencilTestMask()
	return LastStencilTestMask
end

local function GetPreviousStencilTestMask()
	return PrevStencilTestMask
end

local function ReturnStencilTestMask()
	local b1, b2 = LastStencilTestMask, PrevStencilTestMask
	LastStencilTestMask = b2
	PrevStencilTestMask = b1
	return render.SetStencilTestMask(b2)
end

local LastStencilWriteMask
local PrevStencilWriteMask

local function SetStencilWriteMask(arg)
	PrevStencilWriteMask = LastStencilWriteMask or arg
	LastStencilWriteMask = arg
	return render.SetStencilWriteMask(arg)
end

local function GetStencilWriteMask()
	return LastStencilWriteMask
end

local function GetPreviousStencilWriteMask()
	return PrevStencilWriteMask
end

local function ReturnStencilWriteMask()
	local b1, b2 = LastStencilWriteMask, PrevStencilWriteMask
	LastStencilWriteMask = b2
	PrevStencilWriteMask = b1
	return render.SetStencilWriteMask(b2)
end

function stencil.Start(referneceValue, testMask, writeMask)
	if working then
		error('Already in stencil buffer!')
	end

	working = true
	render.SetStencilEnable(true)
	referneceValue = referneceValue or 1
	testMask = testMask or referneceValue
	writeMask = writeMask or testMask
	SetStencilReferenceValue(referneceValue)
	SetStencilTestMask(testMask)
	SetStencilWriteMask(writeMask)

	stencil.StartDrawMask()
end

local fullyTransparent = CreateMaterial('dlib_stencil_mat', 'UnlitGeneric', {
	['$basetexture'] = 'models/debug/debugwhite',
	['$halflambert'] = '1',
	['$translucent'] = '1',
	['$alpha'] = '0'
})

function stencil.SetupSurface()
	surface.SetDrawColor(0, 0, 0, 0)
	surface.SetTextColor(0, 0, 0, 0)
	surface.SetMaterial(fullyTransparent)
	return fullyTransparent
end

function stencil.Reset()
	render.ClearStencil()
end

function stencil.PartialStop()
	render.SetStencilEnable(false)
	SetStencilCompareFunction(STENCIL_ALWAYS)
	SetStencilPassOperation(STENCIL_REPLACE)
	SetStencilFailOperation(STENCIL_KEEP)
	draw.NoTexture()
	working = false
end

function stencil.Stop()
	render.ClearStencil()
	stencil.PartialStop()
end

function stencil.StartDrawMask()
	SetStencilCompareFunction(STENCIL_ALWAYS)
	SetStencilPassOperation(STENCIL_REPLACE)
	SetStencilFailOperation(STENCIL_KEEP)
	stencil.SetupSurface()
end

function stencil.StopDrawMask()
	SetStencilCompareFunction(STENCIL_EQUAL)
	SetStencilPassOperation(STENCIL_REPLACE)
	SetStencilFailOperation(STENCIL_KEEP)
end

-- Will cut from stencil buffer but not draw any new rectangles
function stencil.Cut()
	SetStencilCompareFunction(STENCIL_EQUAL)
	SetStencilPassOperation(STENCIL_ZERO)
	SetStencilFailOperation(STENCIL_KEEP)
end

function stencil.Invertigo()
	SetStencilCompareFunction(STENCIL_NOTEQUAL)
	SetStencilPassOperation(STENCIL_REPLACE)
	SetStencilFailOperation(STENCIL_KEEP)
end

function stencil.Return()
	ReturnStencilCompareFunction()
	ReturnStencilPassOperation()
	ReturnStencilFailOperation()
end

function stencil.Additive()
	SetStencilPassOperation(STENCIL_INCRSAT)
	SetStencilFailOperation(STENCIL_KEEP)
end

function stencil.Fade()
	SetStencilPassOperation(STENCIL_DECRSAT)
	SetStencilFailOperation(STENCIL_KEEP)
end

function stencil.Ignore(status)
	if status then
		SetStencilCompareFunction(STENCIL_ALWAYS)
		SetStencilPassOperation(STENCIL_REPLACE)
		SetStencilFailOperation(STENCIL_REPLACE)
	else
		ReturnStencilCompareFunction()
		ReturnStencilPassOperation()
		ReturnStencilFailOperation()
	end
end

stencil.SetStencilCompareFunction = SetStencilCompareFunction
stencil.GetStencilCompareFunction = GetStencilCompareFunction
stencil.ReturnStencilCompareFunction = ReturnStencilCompareFunction
stencil.GetPreviousStencilCompareFunction = GetPreviousStencilCompareFunction
stencil.SetStencilPassOperation = SetStencilPassOperation
stencil.GetStencilPassOperation = GetStencilPassOperation
stencil.ReturnStencilPassOperation = ReturnStencilPassOperation
stencil.GetPreviousStencilPassOperation = GetPreviousStencilPassOperation
stencil.SetStencilFailOperation = SetStencilFailOperation
stencil.GetStencilFailOperation = GetStencilFailOperation
stencil.ReturnStencilFailOperation = ReturnStencilFailOperation
stencil.GetPreviousStencilFailOperation = GetPreviousStencilFailOperation
stencil.SetStencilReferenceValue = SetStencilReferenceValue
stencil.GetStencilReferenceValue = GetStencilReferenceValue
stencil.ReturnStencilReferenceValue = ReturnStencilReferenceValue
stencil.GetPreviousStencilReferenceValue = GetPreviousStencilReferenceValue
stencil.SetStencilTestMask = SetStencilTestMask
stencil.GetStencilTestMask = GetStencilTestMask
stencil.ReturnStencilTestMask = ReturnStencilTestMask
stencil.GetPreviousStencilTestMask = GetPreviousStencilTestMask
stencil.SetStencilWriteMask = SetStencilWriteMask
stencil.GetStencilWriteMask = GetStencilWriteMask
stencil.ReturnStencilWriteMask = ReturnStencilWriteMask
stencil.GetPreviousStencilWriteMask = GetPreviousStencilWriteMask
