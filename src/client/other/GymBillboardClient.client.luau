local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local player = Players.LocalPlayer

local transparencyDistance = 20
local requirementInterval = 5

local function Billboard(billboard: BillboardGui)
    local part = billboard.Parent
    if not part or not part:IsA("BasePart") then return end

    local gym = billboard:GetAttribute("Category")
    local locked = billboard:FindFirstChild("Locked", true) :: TextLabel?
    
    if gym and locked then
        Packets.Effects.sendRequirement.listen(function(data)
            --print(data)
            if data.gym ~= gym then return end

            if data.enabled then
                locked.Text = "Unlocked"
            else
                locked.Text = `Requirement: {data.requirement} islands`
            end
            
        end)

        task.spawn(function()
            while billboard.Parent do
                Packets.Effects.requestRequirement.send({gym = gym})
                task.wait(requirementInterval)
            end
        end)
    end

    RunService.Stepped:Connect(function()
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local distance = (rootPart.Position - part.Position).Magnitude

        local transparency
        if distance >= (transparencyDistance + 5) then
            transparency = 1
        elseif distance <= transparencyDistance then
            transparency = 0
        else
            transparency = (distance - transparencyDistance) / 5
        end

        for _, descendant in ipairs(billboard:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                descendant.TextTransparency = transparency
            else
                pcall(function()
                    descendant.Transparency = transparency
                end)
            end
        end
    end)
end

for _, billboard in ipairs(CollectionService:GetTagged("GymBillboard")) do
    Billboard(billboard)
end

CollectionService:GetInstanceAddedSignal("GymBillboard"):Connect(Billboard)
