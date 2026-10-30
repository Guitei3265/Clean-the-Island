local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local character = script.Parent

local benchPressAnim = game.ReplicatedStorage:WaitForChild("Effects"):WaitForChild("BenchPressAnim") :: Animation

local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid
if not humanoid then return end

local animator = humanoid:WaitForChild("Animator", 3) :: Animator
if not animator then return end

local benchPressTrack = animator:LoadAnimation(benchPressAnim)

local currentBar: BasePart? = nil
local initialCFrame: CFrame? = nil
local barConnection: RBXScriptConnection? = nil

local function GetNearestBar(): BasePart?
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return nil end

    local nearestBar: BasePart? = nil
    local nearestDistance = math.huge

    for _, bar in ipairs(CollectionService:GetTagged("BPBar")) do
        if bar:IsA("BasePart") then
            local distance = (bar.Position - rootPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestBar = bar
            end
        end
    end

    return nearestBar
end

local function BenchPress()
    currentBar = GetNearestBar()
    initialCFrame = currentBar and currentBar.CFrame

    local leftHand = character:FindFirstChild("LeftHand") :: BasePart?
    local rightHand = character:FindFirstChild("RightHand") :: BasePart?

    barConnection = RunService.Stepped:Connect(function()
        if not currentBar or not leftHand or not rightHand then return end

        local averagePosition = (leftHand.Position + rightHand.Position) / 2
        currentBar.CFrame = currentBar.CFrame.Rotation + averagePosition
    end)

    benchPressTrack:Play()
end

local function Stop()
    if barConnection then
        barConnection:Disconnect()
        barConnection = nil
    end

    if initialCFrame and currentBar then
        currentBar.CFrame = initialCFrame
    end

    benchPressTrack:Stop()
end

humanoid.Seated:Connect(function(active: boolean)
    if not active then
        Stop()
    end
end)

Packets.Effects.BPBar.listen(function(data)
    local bar = data.bar
    if not (bar and bar:IsA("BasePart")) then return end

    bar:Destroy()

    BenchPress()
end)
