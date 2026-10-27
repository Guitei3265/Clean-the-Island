local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

Packets.Effects.tutorialText.listen(function(data)
    for _, frame: Frame in ipairs(CollectionService:GetTagged("TutorialFrame")) do
        if data.text == "" then
            frame.Visible = false
        else
            frame.Visible = true
            (frame:FindFirstChildWhichIsA("TextLabel") :: TextLabel).Text = data.text
        end
    end
end)
