local Players = game:GetService("Players")

local DataManager = require(game.ServerStorage.ServerModules.DataManager)

local upgrades = {}

function upgrades.GetBuff(x: number)
    local buff = math.log(1 + (x * 0.12 / 12)) / math.log(1.12)
    return math.floor(buff)
end

for x = 0, 1000 do
    print("X: "..x..", speed: "..(16 + upgrades.GetBuff(x)))
end

function upgrades.PlayerAdded(player: Player)
    local profile = DataManager.WaitForProfile(player)
    local buff = upgrades.GetBuff(profile.Speed)

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid

    humanoid.WalkSpeed = 16 + buff

    task.wait(5)

    
    --[[while task.wait(0.25) do
        x += 1
        buff = upgrades.GetBuff(x)

        if humanoid then
            humanoid.WalkSpeed = 16 + buff
        end
    end]]
end

function upgrades.Init()
    Players.PlayerAdded:Connect(upgrades.PlayerAdded)
end

return upgrades
