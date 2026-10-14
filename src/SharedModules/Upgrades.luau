local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Packets = require(script.Parent.Packets)

local Upgrades = {}

Upgrades.configs = {
    BaseCost = 150,
    Expo = 1.5,
    growthFactor = 1.08,
    WorkoutExpo = 1.5,
}

function Upgrades.CalculateCost(x: number): number
    return math.floor(Upgrades.configs.BaseCost * Upgrades.configs.Expo ^ (x - 1))
end

function Upgrades.WorkoutMultiplier(workoutMultiplier: number, x: number): number
    return workoutMultiplier * Upgrades.configs.WorkoutExpo ^ (x - 1)
end

function Upgrades.GetBuff(x: number): number
    local growthFactor = Upgrades.configs.growthFactor
    local buff = math.log(1 + (x * (growthFactor - 1) / 20)) / math.log(growthFactor)
    return math.floor(buff)
end

function Upgrades.BuyButton(button: Instance)
    if not button:IsA("GuiButton") then return end

    local upgrade = button:GetAttribute("Upgrade")

    button.Activated:Connect(function()
        if upgrade == "BulkPickup" then
            Packets.Upgrades.requestBulkPickup.send()
        elseif upgrade == "Range" then
            Packets.Upgrades.requestReach.send()
        elseif upgrade == "WorkoutMultiplier" then
            Packets.Upgrades.requestWorkoutMultiplier.send()
        end
    end)

    local label = button:WaitForChild("TextLabel", 5) :: TextLabel?
    if not label then return end

    local parent = button.Parent
    local levelLabel = parent and parent:IsA("Frame") and parent:WaitForChild("LevelLabel", 1) :: TextLabel?

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
            label.Text = tostring(Upgrades.CalculateCost(data.reach + 1 - 4))

            if levelLabel then
                levelLabel.Text = `Lvl. {data.reach} -> {data.reach + 1}`
            end
        end)

        Packets.Data.requestReach.send()
    elseif upgrade == "WorkoutMultiplier" then
        Packets.Data.sendWorkoutMultiplier.listen(function(data)
            label.Text = tostring(Upgrades.CalculateCost(data.workoutMultiplier + 1))

            if levelLabel then
                levelLabel.Text = `Lvl. {data.workoutMultiplier} -> {data.workoutMultiplier + 1}`
            end
        end)

        Packets.Data.requestWorkoutMultiplier.send()
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

function Upgrades.UpgradeGym()
    local player = Players.LocalPlayer

    while true do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

        local isSeated = humanoid ~= nil and humanoid.Sit

        local isOnTreadmill = false
        if humanoidRootPart then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = CollectionService:GetTagged("Treadmill")

            local result = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -5, 0), params)
            isOnTreadmill = result ~= nil
        end

        local visible = isSeated or isOnTreadmill

        for _, button in ipairs(CollectionService:GetTagged("UpgradeGym")) do
            if button:IsA("GuiObject") then
                button.Visible = visible
            end
        end

        task.wait(0.1)
    end
end

function Upgrades.ClientInit()
    task.spawn(Upgrades.UpgradeGym)

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
