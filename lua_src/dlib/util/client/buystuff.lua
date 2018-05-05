
-- Copyright (C) 2016-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

surface.CreateFont('BuyCSSFont', {
	font = 'Comic Sans MS',
	size = 32
})

surface.CreateFont('BuyCSSFont2', {
	font = 'Comic Sans MS',
	size = 24
})

surface.CreateFont('BuyDLibPremium', {
	font = 'PT Serif',
	size = 32
})

surface.CreateFont('BuyRTFont', {
	font = 'Roboto',
	size = 48
})

surface.CreateFont('BuyFontsFont', {
	font = 'Times New Roman',
	size = 32
})

local buy_rt = GetRenderTargetEx('buy_counter_strike', 128, 128, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SHARED, 0, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGB888)

local Textings = {
	{'buy\ncounter\nstrike', 'BuyCSSFont'},
	{'buy\ndlib\npremium', 'BuyDLibPremium'},
	{'install\ndlib\nv3', 'BuyDLibPremium'},
	{'go play\nvalve idiot', 'BuyDLibPremium'},
	{'hl2.exe\nis\ndumb', 'Default'},
	{'F U C K\nBY CSS\nF U C K', 'BuyCSSFont'},
	{'here, buy\nyourself some\ncounter-strike', 'BuyCSSFont2'},
	{':RT:', 'BuyRTFont'},
	{'Times\nNew\nRumanian', 'BuyFontsFont'},
	{'install\nnew\nfonts', 'BuyFontsFont'},
	{'use\ncomic sans', 'BuyFontsFont'},
}

local Backgrounds = {
	Color(),
	Color(77, 202, 233),
	Color(20, 246, 227),
	Color(67, 216, 92),
	Color(169, 67, 216),
	Color(204, 227, 75),
	Color(227, 172, 75),
	Color(210, 110, 50),
	Color(221, 75, 181),
	Color(216, 51, 82),
	Color(123, 28, 196),
}

local draw = draw
local surface = surface
local render = render
local cam = cam
local Material = Material
local RealTimeL = RealTimeL
local LerpQuintic = LerpQuintic
local errormat

local BackgroundIndex = 1
local BackgroundStart = 0
local BackgroundNext = 0
local BackgroundColorCurrent, BackgroundColorState, BackgroundColorNext

local CurrentText, CurrentFont
local NextText = 0
local LocalPlayer = LocalPlayer
local nextTraceCheck = 0

local function RedrawRT()
	local compute = false

	if not errormat then
		errormat = Material('__error')
		DLib.ErrorTexture = DLib.ErrorTexture or errormat:GetTexture('$basetexture')
		compute = true
	end

	local time = RealTimeL()

	if time > BackgroundNext then
		BackgroundIndex = BackgroundIndex + 1

		if BackgroundIndex > #Backgrounds then
			BackgroundIndex = 1
			BackgroundColorCurrent = Backgrounds[1]
			BackgroundColorNext = Backgrounds[2]
		elseif BackgroundIndex == #Backgrounds then
			BackgroundColorCurrent = Backgrounds[BackgroundIndex]
			BackgroundColorNext = Backgrounds[1]
		else
			BackgroundColorCurrent = Backgrounds[BackgroundIndex]
			BackgroundColorNext = Backgrounds[BackgroundIndex + 1]
		end

		BackgroundStart = time
		BackgroundNext = time + 20
	end

	if time > NextText then
		local data = table.frandom(Textings)
		CurrentText, CurrentFont = data[1], data[2]
		NextText = time + math.random(60, 120)
	end

	BackgroundColorState = BackgroundColorCurrent:Lerp(time:progression(BackgroundStart, BackgroundNext), BackgroundColorNext)

	render.PushRenderTarget(buy_rt)
	cam.Start2D()

	draw.NoTexture()
	surface.SetDrawColor(BackgroundColorState)
	surface.DrawRect(0, 0, 128, 128)
	draw.DrawText(CurrentText, CurrentFont, 64, 18, BackgroundColorState:Invert(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	render.CopyRenderTargetToTexture(DLib.ErrorTexture)

	cam.End2D()
	render.PopRenderTarget()

	if compute then
		errormat:SetTexture('$basetexture', buy_rt)
		errormat:Recompute()
	end

	if time > nextTraceCheck then
		local tr = LocalPlayer():GetEyeTrace()
		local HitTexture = tr.HitTexture

		if HitTexture then
			local mat = Material(HitTexture)

			if mat then
				local tex = mat:GetTexture('$basetexture')
				local tex2 = mat:GetTexture('$refracttexture')
				local check1 = not tex or tex:GetName() == '__error' or tex:GetName() == 'error'
				local check2 = not tex2 or tex2:GetName() == '__error' or tex2:GetName() == 'error'

				if check1 and check2 then
					mat:SetTexture('$basetexture', buy_rt)
					mat:Recompute()
				end
			end
		end

		nextTraceCheck = time + 1
	end
end

hook.Add('PostRender', 'DLib.BuyCounterStrike', RedrawRT)
