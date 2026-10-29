local AS = game:GetService("AnalyticsService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local FunnelsModule = {}

FunnelsModule.TutorialSteps = {
	"Joined the game",
    "Pressed play",
    "Finished the cutscene",
    "Grabbed a block",
    "Sold the block",
    "Walked to the gym",
    "Bought gym upgrade",
}

function FunnelsModule.PlayerAdded(plr: Player)
    AS:LogOnboardingFunnelStepEvent(plr, 1, FunnelsModule.TutorialSteps[1])
end

function FunnelsModule.LogStep(player: Player, number: number)
    local step = FunnelsModule.TutorialSteps[number]
    if not step then
        warn(`No tutorial step for number {number}`)
        return
    end

    print(`step {number}: {step}`)

    AS:LogOnboardingFunnelStepEvent(player, number, step)
end

function FunnelsModule.SetupPackets()
    Packets.Funnels.onboarding.listen(function(data, player)
        FunnelsModule.LogStep(player, data.number)
    end)
end

function FunnelsModule.Init()
    local Players = game:GetService("Players")
    for _, player in Players:GetPlayers() do
        task.spawn(FunnelsModule.PlayerAdded, player)
    end
    Players.PlayerAdded:Connect(FunnelsModule.PlayerAdded)

    FunnelsModule.SetupPackets()
end

return FunnelsModule
