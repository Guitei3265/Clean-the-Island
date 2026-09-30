local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local productIds = {
    [1] = 3715524573,
    [2] = 3715524776,
    [3] = 3715524820,
}

local taggedButtons: {GuiButton} = {}

local function Tagged(button: GuiButton)
    table.insert(taggedButtons, button)
end

for _, button in ipairs(CollectionService:GetTagged("SpeedMultiplier")) do
    Tagged(button)
end

CollectionService:GetInstanceAddedSignal("SpeedMultiplier"):Connect(Tagged)

Packets.Gui.speedProductBought.listen(function(data)
    if data.multiplier == 0 then
        for _, button in ipairs(taggedButtons) do
            button.Visible = false
            button.Active = false
        end

        return
    end

    local id = productIds[data.multiplier/10]
    if not id then
        warn("No product id for multiplier", data.multiplier)
        return
    end

    for _, button in ipairs(taggedButtons) do
        button:SetAttribute("Id", id)

        local label = button:FindFirstChild("Label")
        if label then
            label.Text = `{data.multiplier/10}x Speed`
        else
            print("Error")
        end
    end
end)
