
-- Copyright (Jimmy Donal Wales), 2017-2019 DBotThePony

-- Licensed under the MIT license
-- you may not use this file except in compliance with Jimmy's wish.
-- You may obtain a copy of the License at

--     https://en.wikipedia.org/wiki/Jimmy_Wales

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR MONEY ASKING OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- if you want to disable this - you are a terrible person

local RealTimeL = RealTimeL
local table = table
local timer = timer
local lastMove = RealTime()
local cPnl
local gui = gui
local Derma_Query = Derma_Query
local Derma_Message = Derma_Message

local NEVER_ASK = CreateConVar('dlib_donate_never', '0', {FCVAR_ARCHIVE}, 'Never ask about donation. This is sad.')

local yandexmoney = {
	'ru', 'by', 'ua', 'az', 'am', 'kz', 'tj', 'uz', 'kg', 'md', 'tm'
}

DLib.RegisteredAddons = DLib.RegisteredAddons or {}

function DLib.RegisterAddonName(name)
	if not table.qhasValue(DLib.RegisteredAddons, name) then
		table.insert(DLib.RegisteredAddons, name)
		return true
	end

	return false
end

local function makeWindow()
	if IsValid(cPnl) then
		cPnl:Remove()
	end

	local modlist = ''

	if #DLib.RegisteredAddons < 4 then
		modlist = ', ' .. table.concat(DLib.RegisteredAddons, ', ')
	else
		modlist = ', ' .. table.concat(table.gcopyRange(DLib.RegisteredAddons, 1, 4), ', ') .. DLib.i18n.localize('gui.dlib.donate.more', #DLib.RegisteredAddons - 4)
	end

	if table.qhasValue(yandexmoney, system.GetCountry():lower()) then
		cPnl = Derma_Query(
			DLib.i18n.localize('gui.dlib.donate.text', modlist),
			'gui.dlib.donate.top',
			'gui.dlib.donate.button.yes',
			function()
				gui.OpenURL('https://money.yandex.ru/to/410015741601598')
			end,
			'gui.dlib.donate.button.paypal',
			function()
				gui.OpenURL('https://www.paypal.me/DBotThePony')
			end,
			'gui.dlib.donate.button.learnabout',
			function()
				gui.OpenURL(DLib.i18n.localize('gui.dlib.donate.button.learnabout_url'))
			end,
			'gui.dlib.donate.button.no',
			function()
				Derma_Query(
					'gui.dlib.donate.button.never',
					'gui.dlib.donate.top',
					'gui.misc.yes',
					function()
						NEVER_ASK:SetBool(true)
					end,
					'gui.misc.no',
					function()
					end
				)
			end
		)
	else
		cPnl = Derma_Query(
			DLib.i18n.localize('gui.dlib.donate.text', modlist),
			'gui.dlib.donate.top',
			'gui.dlib.donate.button.yes',
			function()
				gui.OpenURL('https://www.paypal.me/DBotThePony/5' .. (system.GetCountry():lower() == 'us' and 'USD' or 'EUR'))
			end,
			'gui.dlib.donate.button.learnabout',
			function()
				gui.OpenURL(DLib.i18n.localize('gui.dlib.donate.button.learnabout_url'))
			end,
			'gui.dlib.donate.button.no',
			function()
			end,
			'gui.dlib.donate.button.never',
			function()
				NEVER_ASK:SetBool(true)
			end
		)
	end
end

local timelimit = 60 * 120

local function Think()
	if NEVER_ASK:GetBool() then return end
	if IsValid(cPnl) then return end

	if RealTimeL() - timelimit > lastMove then
		makeWindow()
		lastMove = RealTimeL()
	end
end

local frames = 0

local function Think2()
	frames = frames + 1

	if frames > 200 then
		hook.Remove('Think', 'DLib.DonationThink2')
	end

	lastMove = RealTimeL()
end

local function Heartbeat()
	lastMove = RealTimeL()
end

concommand.Add('dlib_donate', makeWindow)

timer.Create('DLib.DonationThink', 60, 0, Think)
hook.Add('PlayerBindPress', 'DLib.DonationThink', Heartbeat, -4)
hook.Add('Think', 'DLib.DonationThink2', Think2, -4)
