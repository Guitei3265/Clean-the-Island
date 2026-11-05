local CollectionService = game:GetService("CollectionService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local function UpdateTrashCountFrame(frame: Frame, current: number, total: number)
    local textLabel = frame:FindFirstChild("TextLabel") :: TextLabel?
    if not textLabel then return end

    textLabel.Text = `Blocks: {current}/{total}`

    local bar = frame:FindFirstChild("Bar") :: GuiObject?
    if not bar then return end

    local percentage = total > 0 and (current / total) or 0
    local scale = 0.03 + (1 - 0.03) * math.clamp(percentage, 0, 1)

    bar.Size = UDim2.new(scale, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)
end

Packets.Effects.trashCount.listen(function(data)
    for _, frame in ipairs(CollectionService:GetTagged("TrashCountFrame")) do
        if frame:IsA("Frame") then
            UpdateTrashCountFrame(frame, data.current, data.total)
        end
    end
end)
