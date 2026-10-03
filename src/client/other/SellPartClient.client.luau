local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local player = Players.LocalPlayer

local function Tagged(part: BasePart)
    part.Touched:Connect(function(otherPart: BasePart)
        local character = player.Character
        if not character then return end

        if otherPart:IsDescendantOf(character) then
            Packets.Economy.sellTrash.send()
        end
    end)
end

for _, part in ipairs(CollectionService:GetTagged("SellPart")) do
    Tagged(part)
end

CollectionService:GetInstanceAddedSignal("SellPart"):Connect(Tagged)
