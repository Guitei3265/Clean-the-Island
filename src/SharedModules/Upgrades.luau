local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Packets = require(script.Parent.Packets)

local Upgrades = {}

Upgrades.configs = {
    BaseCost = 150,
    Expo = 1.5,
}

function Upgrades.CalculateCost(x: number): number
    return math.floor(Upgrades.configs.BaseCost * Upgrades.configs.Expo ^ (x - 1))
end

function Upgrades.BuyButton(button: Instance)
    if not button:IsA("GuiButton") then return end

    local upgrade = button:GetAttribute("Upgrade")

    button.Activated:Connect(function()
        if upgrade == "BulkPickup" then
            Packets.Upgrades.requestBulkPickup.send()
        elseif upgrade == "Range" then
            Packets.Upgrades.requestReach.send()
        end
    end)

    local label = button:WaitForChild("TextLabel", 1) :: TextLabel?
    if not label then return end

    local levelLabel = button.Parent:WaitForChild("LevelLabel", 1) :: TextLabel?

    if upgrade == "BulkPickup" then
        Packets.Data.sendBulkPickup.listen(function(data)
            label.Text = tostring(Upgrades.CalculateCost(data.bulkPickup + 1))

            if levelLabel then
                levelLabel.Text = `Lvl. {data.bulkPickup} -> {data.bulkPickup + 1}`
            end
        end)

        Packets.Data.requestBulkPickup.send()
    elseif upgrade == "Range" then
        Packets.Data.sendReach.listen(function(data)
            label.Text = tostring(Upgrades.CalculateCost(data.reach + 1))

            if levelLabel then
                levelLabel.Text = `Lvl. {data.reach} -> {data.reach + 1}`
            end
        end)

        Packets.Data.requestReach.send()
    end
end

function Upgrades.UpgradePart(part: Instance)
    if not part:IsA("BasePart") then return end

    part.Touched:Connect(function(otherPart)
        local player = Players.LocalPlayer
        local character = player.Character

        if not (character and otherPart:IsDescendantOf(character)) then
            return
        end

        local playerGui = player:WaitForChild("PlayerGui")
        local mainFrame = playerGui:WaitForChild("Upgrades"):WaitForChild("MainFrame")
        mainFrame.Visible = true
    end)
end

function Upgrades.ClientInit()
    for _, button in ipairs(CollectionService:GetTagged("BuyUpgrade")) do
        Upgrades.BuyButton(button)
    end

    CollectionService:GetInstanceAddedSignal("BuyUpgrade"):Connect(Upgrades.BuyButton)

    for _, part in ipairs(CollectionService:GetTagged("UpgradePart")) do
        Upgrades.UpgradePart(part)
    end

    CollectionService:GetInstanceAddedSignal("UpgradePart"):Connect(Upgrades.UpgradePart)
end

return Upgrades
