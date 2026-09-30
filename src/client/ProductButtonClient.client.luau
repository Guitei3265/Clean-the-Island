local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function Tagged(button: GuiButton)
    local id = button:GetAttribute("Id")
    if not id then
        warn("No id")
        return
    end

    (button :: GuiButton).Activated:Connect(function()
        MarketplaceService:PromptProductPurchase(player, id)
    end)
end

for _, button in ipairs(CollectionService:GetTagged("ProductButton")) do
    Tagged(button)
end

CollectionService:GetInstanceAddedSignal("ProductButton"):Connect(Tagged)
