local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local DataManager = require(game.ServerStorage.ServerModules.DataManager)

local Tutorial = {}

function Tutorial.Stage1(player, profile)
	profile.cutscene = true
	Packets.Effects.playCutscene.sendTo({name = "Intro"}, player)
end

function Tutorial.Stage2(player, profile)
	Packets.Effects.tutorialText.sendTo({text = "Grab a block"}, player)
	Packets.Effects.trashBeam.sendTo(nil, player)
end

function Tutorial.Stage3(player, profile)
	Packets.Effects.tutorialText.sendTo({text = "Sell the block"}, player)
	Packets.Effects.sellBeam.sendTo(nil, player)
end

function Tutorial.Stage4(player, profile)
	Packets.Effects.tutorialText.sendTo({text = "Go to the gym"}, player)
	Packets.Effects.gymBeam.sendTo(nil, player)
end

function Tutorial.Stage5(player, profile)
	Packets.Effects.tutorialText.sendTo({text = "Tutorial Concluded!"}, player)

	task.delay(5, function()
		Packets.Effects.tutorialText.sendTo({text = ""}, player)
	end)
end

function Tutorial.StartTutorial(player, profile)
	local i = 1

	while true do
		local stage = Tutorial["Stage" .. tostring(i)]
		if not stage then break end

		stage(player, profile)

		i += 1

		task.wait()
		Packets.Game.requestTutorial.wait()
	end
end

function Tutorial.Init()
	Packets.Game.requestTutorial.listen(function(data, player)
		if data.number ~= 1 then return end

		local profile = DataManager.WaitForProfile(player)
		if not profile then return end

		if not profile.cutscene then
			Tutorial.StartTutorial(player, profile)
		end
	end)
end

return Tutorial
