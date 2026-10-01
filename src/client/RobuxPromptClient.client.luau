local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local player = Players.LocalPlayer

Packets.Robux.Gamepass.listen(function(data)
    MarketplaceService:PromptGamePassPurchase(player, data.id)
end)

Packets.Robux.Product.listen(function(data)
    MarketplaceService:PromptProductPurchase(player, data.id)
end)
