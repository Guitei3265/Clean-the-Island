local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local playEvent = ReplicatedStorage.BindableEvents.Play

local function Tagged(button: GuiButton)
    (button :: GuiButton).Activated:Connect(function()
        playEvent:Fire()
        button.Visible = false
    end)
end

for _, button in ipairs(CollectionService:GetTagged("Play")) do
    Tagged(button)
end

CollectionService:GetInstanceAddedSignal("Play"):Connect(Tagged)

Packets.Effects.playCutscene.listen(function()
    for _, button: GuiButton in ipairs(CollectionService:GetTagged("Play")) do
        print("Visible")
        button.Visible = true
    end
end)
