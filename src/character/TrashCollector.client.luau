local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local character = script.Parent

local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart
if not humanoidRootPart then return end

local COLLECT_RADIUS = 4

local function hasNearbyTrash(): boolean
    local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, COLLECT_RADIUS)

    for _, part in ipairs(parts) do
        if CollectionService:HasTag(part, "Trash") then
            print("Has trash")
            return true
        end
    end

    return false
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.E then return end

    if hasNearbyTrash() then
        Packets.Game.gotTrash.send({rootPart = humanoidRootPart})
    end
end)
