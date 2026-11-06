local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)
local Trash = require(game.ServerStorage.ServerModules.Trash)
local Upgrades = require(game.ServerStorage.ServerModules.Upgrades)

local Cleaned = {}

Cleaned.Configs = {
    rewardDelta = 0.25,
    totalRewardTime = 15,
    rewardMultiplier = 3,
}

local function CalculateIslandsMultiplier(player: Player): number
    local islands = DataMethods.ReturnKey(player, "Islands")
    return Upgrades.GetMultiplierForIslands(islands)
end

function Cleaned.RewardPlayers()
end

function Cleaned.Init()
    local totalTime = Cleaned.Configs.totalRewardTime
    local loopTime = 0

    local connection: RBXScriptConnection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        totalTime -= deltaTime
        loopTime += deltaTime

        if totalTime <= 0 then
            connection:Disconnect()
            return
        end

        if loopTime < Cleaned.Configs.rewardDelta then
            return
        end

        loopTime -= Cleaned.Configs.rewardDelta

        Cleaned.RewardPlayers()
    end)

    print("Everything clean!")

    task.wait(1)
    print("Reseting in")

    for i = 15, 0, -1 do
        task.wait(1)
        print(i)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        DataMethods.WaitForProfile(player)
        DataMethods.SetKey(player, "Islands", DataMethods.ReturnKey(player, "Islands") + 1)
    end

    local success, err = pcall(Trash.Spawn)
    if not success then
        warn("Trash.Spawn failed:", err)
    end
end

return Cleaned
