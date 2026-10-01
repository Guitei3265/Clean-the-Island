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

local SEND_INTERVAL = 0.1

local isHolding = false

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.E or isHolding then return end

    isHolding = true

    while isHolding do
        if hasNearbyTrash() then
            Packets.Game.gotTrash.send({rootPart = humanoidRootPart})
        end

        task.wait(SEND_INTERVAL)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if input.KeyCode ~= Enum.KeyCode.E then return end

    isHolding = false
end)
