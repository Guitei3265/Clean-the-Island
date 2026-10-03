local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Packets = require(script.Parent.Packets)

local Upgrades = {}

function Upgrades.CalculateCost(x: number): number
    return 50 * 1.12 ^ (x - 1)
end

function Upgrades.BuyButton(button: Instance)
    if not button:IsA("GuiButton") then return end

    button.Activated:Connect(function()
        local upgrade = button:GetAttribute("Upgrade")
        
        if upgrade == "BulkPickup" then
            Packets.Upgrades.requestBulkPickup.send()
        elseif upgrade == "Range" then
            Packets.Upgrades.requestReach.send()
        end
    end)
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
