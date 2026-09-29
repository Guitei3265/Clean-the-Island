local ProfileStore = require(game.ServerStorage.ServerPackages.ProfileStore :: ModuleScript)

local profileTemplate = {
    Cash = 0,
    Speed = 0,
    SpeedMultiplier = 1,
	SpeedMultiplierProduct = 1,
    Strength = 0,
    StrengthMultiplier = 1,
	StrengthMultiplierProduct = 1,
    MaxSpeed = 1000,
}

local configs = {
	printing = false,
	reseting = true,
}

if configs.reseting then
	warn("RESETING DATA!!!")
end


local Players = game:GetService("Players")

local PlayerStore = ProfileStore.New("PlayerStore", profileTemplate)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = require(game.ServerStorage.ServerModules.DataManager.Profiles :: ModuleScript)
local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local dataMethods = require(script.DataMethods :: ModuleScript)
local dataManager = {}
setmetatable(dataManager, dataMethods)

local function SetupOnAdded(plr: Player, profile: typeof(profileTemplate))
    
end

function dataManager.PlayerAdded(player)
	-- Start a profile session for this player's data:

	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Handling new profile session or failure to start it:

	if profile ~= nil then

	profile:AddUserId(player.UserId) -- GDPR compliance
	profile:Reconcile() -- Fill in missing variables from profileTemplate (optional)

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick(`Profile session end - Please rejoin`)
	end)

	if player.Parent == Players then
		Profiles[player] = profile

		if configs.reseting then
			Profiles[player].Data = table.clone(profileTemplate)
		end

		if configs.printing then
			task.spawn(function()
				print(`Profile loaded for {player.DisplayName}!`)
				print(profile.Data)
			end)
		end
		
		SetupOnAdded(player, profile.Data)
	else
		-- The player has left before the profile session started
		profile:EndSession()
	end

	else
		-- This condition should only happen when the Roblox server is shutting down
		player:Kick(`Profile load fail - Please rejoin`)
	end
end

function dataManager.Init()
	-- In case Players have joined the server earlier than this script ran:
	for _, player in Players:GetPlayers() do
		task.spawn(dataManager.PlayerAdded, player)
	end

	Players.PlayerAdded:Connect(dataManager.PlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]
		if profile ~= nil then
			profile:EndSession()
		end
	end)
end

return dataManager