local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local character = script.Parent

local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart
if not (humanoid and humanoidRootPart) then return end

local animateScript = character:WaitForChild("Animate", 3)
local runFolder = animateScript and animateScript:WaitForChild("run", 3)
local runAnimation = runFolder and runFolder:FindFirstChildOfClass("Animation") :: Animation
if not runAnimation then
    return
end

local animator = humanoid:WaitForChild("Animator", 3) :: Animator
if not animator then return end

local runTrack = animator:LoadAnimation(runAnimation)
runTrack.Priority = Enum.AnimationPriority.Movement

local function IsOnTreadmill()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = CollectionService:GetTagged("Treadmill")

    local result = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -5, 0), params)
    
    return result ~= nil
end

local isPlaying = false

RunService.Heartbeat:Connect(function()
    local onTreadmill = humanoid.MoveDirection.Magnitude <= 0 and IsOnTreadmill()

    if onTreadmill and not isPlaying then
        runTrack:Play()
        isPlaying = true
    elseif not onTreadmill and isPlaying then
        runTrack:Stop()
        isPlaying = false
    end

    if isPlaying then
        runTrack:AdjustSpeed(humanoid.WalkSpeed / 16)
    end
end)
