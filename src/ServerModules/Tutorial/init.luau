local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local DataManager = require(game.ServerStorage.ServerModules.DataManager)

local Tutorial = {}

function Tutorial.Init()
	Packets.Game.requestTutorial.listen(function(_, player)
		local profile = DataManager.WaitForProfile(player)
		if not profile then return end

		if not profile.cutscene then
			profile.cutscene = true
			Packets.Effects.playCutscene.sendTo({name = "Intro"}, player)
		end
	end)
end

return Tutorial
