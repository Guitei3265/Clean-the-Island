local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)
local Trash = require(game.ServerStorage.ServerModules.Trash)
local Upgrades = require(game.ServerStorage.ServerModules.Upgrades)

local Cleaned = {}

Cleaned.Running = false

Cleaned.Configs = {
    rewardDelta = 0.25,
    totalRewardTime = 30,
    rewardMultiplier = 5,
}

local function CalculateIslandsMultiplier(player: Player): number
    local islands = DataMethods.ReturnKey(player, "Islands")
    return Upgrades.GetMultiplierForIslands(islands)
end

function Cleaned.SpawnFlowers()
    print("Flowers!")
end

function Cleaned.VFX()
    print("Everything clean!")

    Cleaned.SpawnFlowers()
end

function Cleaned.RewardPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local multiplier = CalculateIslandsMultiplier(player) * Cleaned.Configs.rewardMultiplier
        Upgrades.Walked(player, multiplier, true)
        Upgrades.Strengthed(player, multiplier, true)
    end
end

function Cleaned.Init()
    Cleaned.Running = true

    for _, player in ipairs(Players:GetPlayers()) do
        DataMethods.WaitForProfile(player)
        DataMethods.SetKey(player, "Islands", DataMethods.ReturnKey(player, "Islands") + 1)
    end

    local totalTime = Cleaned.Configs.totalRewardTime
    local loopTime = 0

    local connection: RBXScriptConnection
    local function close()
        connection:Disconnect()
        local success, err = pcall(Trash.Spawn)
        if not success then
            warn("Trash.Spawn failed:", err)
        end
        Cleaned.Running = false
    end
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        totalTime -= deltaTime
        loopTime += deltaTime

        if totalTime <= 0 then
            close()
            return
        end

        if loopTime < Cleaned.Configs.rewardDelta then
            return
        end

        loopTime -= Cleaned.Configs.rewardDelta

        Cleaned.RewardPlayers()
    end)

    task.spawn(Cleaned.VFX)
end

return Cleaned
