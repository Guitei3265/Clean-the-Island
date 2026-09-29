local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataManager = require(game.ServerStorage.ServerModules.DataManager)
local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local upgrades = {}

local growthFactor = 1.1
local segundos = 6

function upgrades.GetBuff(x: number)
    local buff = math.log(1 + (x * (growthFactor - 1) / 20)) / math.log(growthFactor)
    return math.floor(buff)
end

function upgrades.Walked(player: Player)
    DataManager.IncreaseSpeed(player)
end

function upgrades.PlayerAdded(player: Player)
    local profile = DataManager.WaitForProfile(player)

    local connection: RBXScriptConnection? = nil
    local timer = 0

    local function onCharacterAdded(character: Model)
        if connection then
            connection:Disconnect()
        end

        local humanoid = character:WaitForChild("Humanoid") :: Humanoid

        humanoid.WalkSpeed = 16 + upgrades.GetBuff(profile.Speed)

        connection = RunService.Heartbeat:Connect(function(deltaTime)
            timer += deltaTime

            if timer > 0.25 then
                timer -= 0.25

                if humanoid.MoveDirection.Magnitude > 0 then
                    upgrades.Walked(player)
                end
            end

            humanoid.WalkSpeed = 16 + upgrades.GetBuff(profile.Speed)
        end)
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end

    player.CharacterAdded:Connect(onCharacterAdded)
end

function upgrades.Request(player: Player)
    local profile = DataManager.WaitForProfile(player)

    Packets.Upgrades.updateSpeed.sendTo({total = profile.Speed, gained = 0}, player)
    Packets.Upgrades.updateStrength.sendTo({total = profile.Strength, gained = 0}, player)
end

function upgrades.Init()
    Players.PlayerAdded:Connect(upgrades.PlayerAdded)

    Packets.Upgrades.request.listen(function(_, player)
        upgrades.Request(player)
    end)
end

return upgrades
