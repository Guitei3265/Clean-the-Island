local Players = game:GetService("Players")

local function SetCollisionGroup(character: Model)
    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = "Player"
        end
    end)

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "Player"
        end
    end
end

local function PlayerAdded(player: Player)
    if player.Character then
        SetCollisionGroup(player.Character)
    end

    player.CharacterAdded:Connect(SetCollisionGroup)
end

Players.PlayerAdded:Connect(PlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    PlayerAdded(player)
end
