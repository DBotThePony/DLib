
-- Copyright (C) 2019 Todd Howard

--[==[
  _____ _______        _ _    _  _____ _______  __          ______  _____  _  __ _____
 |_   _|__   __|      | | |  | |/ ____|__   __| \ \        / / __ \|  __ \| |/ // ____|
   | |    | |         | | |  | | (___    | |     \ \  /\  / / |  | | |__) | ' /| (___
   | |    | |     _   | | |  | |\___ \   | |      \ \/  \/ /| |  | |  _  /|  <  \___ \
  _| |_   | |    | |__| | |__| |____) |  | |       \  /\  / | |__| | | \ \| . \ ____) |
 |_____|  |_|     \____/ \____/|_____/   |_|        \/  \/   \____/|_|  \_\_|\_\_____/

]==]

local text = [[
    ____
   / __ )__  ____  __
  / __  / / / / / / /
 / /_/ / /_/ / /_/ /
/_____/\__,_/\__, /
    ______  /_______            __     __________
   / ____/___ _/ / /___  __  __/ /_   /__  / ___/
  / /_  / __ `/ / / __ \/ / / / __/     / / __ \
 / __/ / /_/ / / / /_/ / /_/ / /_      / / /_/ /
/_/    \__,_/_/_/\____/\__,_/\__/     /_/\____/
  ____ _____  ____/ /
 / __ `/ __ \/ __  /
/ /_/ / / / / /_/ /
\__,_/_/ /_/\__,_/
               __
   ____ ____  / /_
  / __ `/ _ \/ __/
 / /_/ /  __/ /_
 \__, /\___/\__/
/_________      ____            __     __________
   / ____/___ _/ / /___  __  __/ /_   /__  /__  /
  / /_  / __ `/ / / __ \/ / / / __/     / /  / /
 / __/ / /_/ / / / /_/ / /_/ / /_      / /  / /
/_/ ___\__,_/_/_/\____\\\\,_/\__/     /_/__/_/
   / __/___  _____   / __/_______  ___  / /
  / /_/ __ \/ ___/  / /_/ ___/ _ \/ _ \/ /
 / __/ /_/ / /     / __/ /  /  __/  __/_/
/_/  \____/_/     /_/ /_/   \___/\___(_)
]]

local function echoTood()
	for i, line in ipairs(text:split('\n')) do
		MsgC(line)
		MsgC('\n')
	end
end

local function echoToodSlow()
	for i, line in ipairs(text:split('\n')) do
		timer.Simple(i * 0.1, function()
			MsgC(line)
			MsgC('\n')
		end)
	end
end

echoTood()

timer.Simple(0, function()
	timer.Simple(0, function()
		timer.Simple(0, function()
			echoToodSlow()

			if math.random() > 0.7 then
				if not PPM2 and math.random() > 0.5 then
					Derma_Query('As of 31 March 2019, DLib now requires PPM/2 to run.\nThat means you need to notinstall PPM/2 from Workshop!',
					'PPM/2 Is now required to run DLib!', 'Got it!', function() gui.OpenURL('https://steamcommunity.com/sharedfiles/filedetails/?id=933203381') end)
					return
				end

				Derma_Message(
				[[A European Union law called "Article 13" is going to fully take
				effect very soon: that means DLib became illegal.
				We don't want our church to fall against a few people over 60
				who have no idea how to "Internet". We need your help!
				We need your credit card number and the expiration date,
				three digits from the back of the card, and your first and
				last name. But you need to act quickly! There is not much
				time left until Article 13 takes effect and we are unable to
				do anything anymore!]], 'ATTENTION ALL DLIB USERS', 'Ill do so!')
			end
		end)
	end)
end)

hook.Add('VGUIPanelCreated', 'plz halp', function(self)
	if self:GetName() ~= 'AvatarImage' and self.ThisClass ~= 'AvatarImage' and self.ThisClass ~= 'DScoreBoard2_Avatar' and self.ThisClass ~= 'DLib_Avatar' then return end
	self.__FoolSetSteamID = self.SetSteamID
	self.__FoolSetPlayer = self.SetPlayer

	function self:SetSteamID(steamid, size)
		return self:__FoolSetSteamID('76561198077439269', size)
	end

	function self:SetPlayer(ply, size)
		return self:__FoolSetSteamID('76561198077439269', size)
	end
end)

hook.Add('Think', 'GachiPls DETH', function()
	for i, ply in ipairs(player.GetAll()) do
		if ply._lalive == nil then
			ply._lalive = ply:Alive()
		end

		local old = ply._lalive
		local new = ply:Alive()
		ply._lalive = new

		if old ~= new and not new and ply:GetPos():Distance(LocalPlayer():GetPos()) <= 256 and system.HasFocus() then
			sound.PlayURL('https://i.dbotthepony.ru/2018/11/Left%204%20Dead%202%20Soundtrack%20-%20%27Left%20for%20Death%27.ogg', '', function() end)
		end
	end
end)
