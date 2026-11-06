local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)
local Trash = require(game.ServerStorage.ServerModules.Trash)
local Upgrades = require(game.ServerStorage.ServerModules.Upgrades)

local Cleaned = {}

Cleaned.Running = false

Cleaned.Configs = {
    rewardDelta = 0.25,
    totalRewardTime = 30,
    rewardMultiplier = 5,
    flowerCount = 240,
    flowerSpawnWait = 0.02, --0.02,
    flowerTweenTime = 2,
    eventSaturation = 0.25,
    eventBrightness = 0.05,
}

local flowerTemplates: Folder
local flowersFolder: Folder?

local flowerRaycastParams = RaycastParams.new()
flowerRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
flowerRaycastParams.FilterDescendantsInstances = {}

local function CalculateIslandsMultiplier(player: Player): number
    local islands = DataMethods.ReturnKey(player, "Islands")
    return Upgrades.GetMultiplierForIslands(islands)
end

function Cleaned.SpawnFlowers()
    local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if colorCorrection then
        local saturationTweenInfo = TweenInfo.new(Cleaned.Configs.flowerTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(colorCorrection, saturationTweenInfo, {
            Saturation = Cleaned.Configs.eventSaturation,
            Brightness = Cleaned.Configs.eventBrightness,
        }):Play()
    end

    flowerTemplates = flowerTemplates or game.ServerStorage.Assets.Flowers

    local folder = Instance.new("Folder")
    folder.Name = "Flowers"
    folder.Parent = workspace
    flowersFolder = folder

    local templates = flowerTemplates:GetChildren()

    local flowersSpawned = 0

    local waitI = 1
    while flowersSpawned < Cleaned.Configs.flowerCount do
        if waitI > 5 then
            waitI = 1
            task.wait(Cleaned.Configs.flowerSpawnWait)
        else
            waitI += 1
        end
        
        local angle = math.random(0, 36000) / 100
        local radians = math.rad(angle)

        local distance = 1 + (350 --[[island radius]] - 1) * math.sqrt(math.random())

        local x = math.cos(radians) * distance
        local z = math.sin(radians) * distance

        local origin = Vector3.new(x, 1000, z)
        local direction = Vector3.new(0, -2000, 0)

        local result = workspace:Raycast(origin, direction, flowerRaycastParams)

        if result and result.Instance == workspace.Terrain and (result.Material == Enum.Material.Grass) then
            local template = templates[math.random(1, #templates)] :: Model
            local flower = template:Clone()

            local randomRotation = math.rad(math.random(0, 36000) / 100)
            local _, size = flower:GetBoundingBox()
            local heightOffset = size.Y * -0.75
            local targetPosition = result.Position + Vector3.new(0, heightOffset, 0)

            local right = Vector3.new(1, 0, 0):Cross(result.Normal).Unit
            local look = result.Normal:Cross(right).Unit

            local targetCFrame = CFrame.fromMatrix(targetPosition, right, result.Normal, look) * CFrame.Angles(0, randomRotation, 0)
            local startCFrame = targetCFrame + Vector3.new(0, 2, 0)

            local targetScale = flower:GetScale()

            flower.Parent = folder
            flower:ScaleTo(targetScale / 10)
            flower:PivotTo(startCFrame)

            local tweenInfo = TweenInfo.new(Cleaned.Configs.flowerTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            local scaleValue = Instance.new("NumberValue")
            scaleValue.Value = targetScale / 4
            scaleValue.Changed:Connect(function(value)
                flower:ScaleTo(value)
            end)

            TweenService:Create(flower, tweenInfo, {WorldPivot = targetCFrame}):Play()

            task.delay(tweenInfo.Time / 2, function()
                local scaleTween = TweenService:Create(scaleValue, tweenInfo, {Value = targetScale})
                scaleTween.Completed:Once(function()
                    scaleValue:Destroy()
                end)
                scaleTween:Play()
            end)

            flowersSpawned += 1
        end
    end
end

function Cleaned.VFX()
    print("Everything clean!")

    Cleaned.SpawnFlowers()
end

function Cleaned.RewardPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local multiplier = CalculateIslandsMultiplier(player) * Cleaned.Configs.rewardMultiplier
        Upgrades.Walked(player, multiplier, true)
        Upgrades.Strengthed(player, multiplier, true)
    end
end

function Cleaned.Init()
    Cleaned.Running = true

    for _, player in ipairs(Players:GetPlayers()) do
        DataMethods.WaitForProfile(player)
        DataMethods.SetKey(player, "Islands", DataMethods.ReturnKey(player, "Islands") + 1)
    end

    local totalTime = Cleaned.Configs.totalRewardTime
    local loopTime = 0

    local connection: RBXScriptConnection
    local function close()
        connection:Disconnect()

        if flowersFolder then
            for _, flower in ipairs(flowersFolder:GetChildren()) do
                flower:Destroy()
                task.wait(Cleaned.Configs.flowerSpawnWait)
            end

            flowersFolder:Destroy()
            flowersFolder = nil
        end

        local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if colorCorrection then
            TweenService:Create(colorCorrection, TweenInfo.new(Cleaned.Configs.flowerTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Saturation = 0.15,
                Brightness = 0,
            }):Play()
        end

        local success, err = pcall(Trash.Spawn)
        if not success then
            warn("Trash.Spawn failed:", err)
        end
        Cleaned.Running = false
    end
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        totalTime -= deltaTime
        loopTime += deltaTime

        if totalTime <= 0 then
            close()
            return
        end

        if loopTime < Cleaned.Configs.rewardDelta then
            return
        end

        loopTime -= Cleaned.Configs.rewardDelta

        Cleaned.RewardPlayers()
    end)

    task.spawn(Cleaned.VFX)
end

return Cleaned
