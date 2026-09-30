local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local function GetPromptPosition(prompt: ProximityPrompt): Vector3?
    local parent = prompt.Parent
    if parent and parent:IsA("BasePart") then
        return parent.Position
    end

    if parent and parent:IsA("Attachment") then
        return parent.WorldPosition
    end

    return nil
end

local function FindNearestSeat(prompt: ProximityPrompt): Seat?
    local promptPosition = GetPromptPosition(prompt)
    if not promptPosition then return nil end

    local nearestSeat: Seat? = nil
    local nearestDistance = math.huge

    for _, seat in ipairs(CollectionService:GetTagged("BenchPress")) do
        if seat:IsA("Seat") then
            local distance = (seat.Position - promptPosition).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestSeat = seat
            end
        end
    end

    return nearestSeat
end

local function Tagged(prompt: ProximityPrompt)
    if not prompt:IsA("ProximityPrompt") then return end

    prompt.Triggered:Connect(function()
        local seat = prompt:FindFirstAncestorOfClass("Seat") or FindNearestSeat(prompt)
        if not seat then
            warn("No seat")
            return
        end

        Packets.Upgrades.requestBenchPress.send({seat = seat})
    end)
end

for _, prompt in ipairs(CollectionService:GetTagged("SeatButton")) do
    Tagged(prompt)
end

CollectionService:GetInstanceAddedSignal("SeatButton"):Connect(Tagged)
