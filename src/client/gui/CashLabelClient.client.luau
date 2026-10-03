local CollectionService = game:GetService("CollectionService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

Packets.Economy.updateCash.listen(function(data)
    for _, label in ipairs(CollectionService:GetTagged("Cash")) do
        if label:IsA("TextLabel") or label:IsA("TextButton") then
            label.Text = tostring(data.total)
        end
    end
end)

Packets.Economy.requestCash.send()
