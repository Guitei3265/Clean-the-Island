local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local DataManager = require(game.ServerStorage.ServerModules.DataManager)

local Tutorial = {}

function Tutorial.Stage1(player, profile)
	profile.cutscene = true
	Packets.Effects.playCutscene.sendTo({name = "Intro"}, player)
end

function Tutorial.StartTutorial(player, profile)
	local i = 1

	while true do
		local stage = Tutorial["Stage" .. tostring(i)]
		if not stage then break end

		stage(player, profile)

		i += 1
	end
end

function Tutorial.Init()
	Packets.Game.requestTutorial.listen(function(_, player)
		local profile = DataManager.WaitForProfile(player)
		if not profile then return end

		if not profile.cutscene then
			Tutorial.StartTutorial(player, profile)
		end
	end)
end

return Tutorial
