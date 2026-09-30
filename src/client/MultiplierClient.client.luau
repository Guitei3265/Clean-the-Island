local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

type Config = {
    label: string,
    products: {{multiplier: number, id: number}},
    current: number?,
    buttons: {GuiButton},
}

local multipliers: {[string]: Config} = {
    SpeedMultiplier = {
        label = "Speed",
        products = {
            {multiplier = 15, id = 3715524573},
            {multiplier = 20, id = 3715524776},
            {multiplier = 30, id = 3715524820},
        },
        current = nil,
        buttons = {},
    },

    StrengthMultiplier = {
        label = "Strength",
        products = {
            {multiplier = 15, id = 3715626326},
            {multiplier = 20, id = 3715626362},
            {multiplier = 30, id = 3715626386},
        },
        current = nil,
        buttons = {},
    },
}

local function Setup(button: GuiButton, config: Config)
    local current = config.current
    if not current then
        return
    end

    local product = nil
    for _, candidate in ipairs(config.products) do
        if candidate.multiplier > current then
            product = candidate
            break
        end
    end

    if not product then
        button.Visible = false
        button.Active = false
        return
    end

    button:SetAttribute("Id", product.id)

    local label = button:FindFirstChild("Label")
    if label then
        label.Text = `{product.multiplier/10}x {config.label}`
    else
        print("Error")
    end
end

local function Update(config: Config, multiplier: number)
    config.current = multiplier

    for _, button in ipairs(config.buttons) do
        Setup(button, config)
    end
end

for tag, config in pairs(multipliers) do
    local function Tagged(button: GuiButton)
        table.insert(config.buttons, button)
        Setup(button, config)
    end

    for _, button in ipairs(CollectionService:GetTagged(tag)) do
        Tagged(button)
    end

    CollectionService:GetInstanceAddedSignal(tag):Connect(Tagged)

    CollectionService:GetInstanceRemovedSignal(tag):Connect(function(button)
        local index = table.find(config.buttons, button)
        if index then
            table.remove(config.buttons, index)
        end
    end)
end

Packets.Gui.speedMultiplierUpdate.listen(function(data)
    Update(multipliers.SpeedMultiplier, data.multiplier)
end)

Packets.Gui.strengthMultiplierUpdate.listen(function(data)
    Update(multipliers.StrengthMultiplier, data.multiplier)
end)

Packets.Gui.requestMultipliers.send()
