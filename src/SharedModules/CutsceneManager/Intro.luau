module = {}

local RS = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Packets = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local cutsceneFolder = game.ReplicatedStorage:WaitForChild("Cutscenes"):WaitForChild("Intro")
local introCharCFrame = cutsceneFolder:WaitForChild("IntroCharCFrame")

local camRig = cutsceneFolder:WaitForChild("CameraRig") :: Model

local trashFolder = game.ReplicatedStorage:WaitForChild("Trash")

local playEvent = game.ReplicatedStorage:WaitForChild("BindableEvents"):WaitForChild("Play") :: BindableEvent

local explodeForce = 170

local sounds = game.SoundService:WaitForChild("Intro")
local plopSound = sounds:WaitForChild("Plop") :: Sound

local camConnection
local trashConnection: RBXScriptConnection

local stopEmiting = false

local explodedBlocks = {}

local StarterGui = game:GetService("StarterGui")
local function setResetEnabled(enabled)
	local success = false
	while not success do
		success = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", enabled)
		end)
		if not success then task.wait(0.1) end
	end
end

local function explodeBlock(explodePart: BasePart)
    local trashChildren = trashFolder:GetChildren()
    local block = trashChildren[math.random(1, #trashChildren)]:Clone() :: Instance

    local blockPart = block:IsA("BasePart") and block or block:FindFirstChildWhichIsA("BasePart", true)
    if not blockPart then
        block:Destroy()
        return
    end

    local pivot = block:IsA("Model") and block:GetPivot() or blockPart.CFrame
    local spawnCFrame = CFrame.new(explodePart.Position + Vector3.new(0, explodePart.Size.Y / 2, 0)) * (pivot - pivot.Position)

    if block:IsA("Model") then
        block:PivotTo(spawnCFrame)
    else
        block.CFrame = spawnCFrame
    end

    block.Parent = workspace

    table.insert(explodedBlocks, block)

    plopSound:Play()

    blockPart.AssemblyLinearVelocity = Vector3.new(math.random(-30, 30), math.random(explodeForce * 0.8, explodeForce * 1.2), math.random(-30, 30))
    blockPart.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))

    task.delay(1, function()
        blockPart.CanCollide = true
        local clone = blockPart:Clone()
        table.insert(explodedBlocks, clone)
    end)

end

local function destroyBlocks()
    for _, block in explodedBlocks do
        block:Destroy()
    end
    table.clear(explodedBlocks)
end

function module.Scene1(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
    local sceneFolder = cutsceneFolder:WaitForChild("Scene1")
    local humAnim = sceneFolder:WaitForChild("Hum") :: Animation
    local camCFrame = sceneFolder:WaitForChild("CamCFrame") :: CFrameValue

    camRig:PivotTo(camCFrame.Value)

    --[[local camHRP = camRig:WaitForChild("HumanoidRootPart") :: BasePart
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = humHrp
    weld.Part1 = camHRP
    weld.Parent = camHRP]]

    local humTrack = humAnimator:LoadAnimation(humAnim)
    humTrack:Play(0)

    playEvent.Event:Wait()

    humTrack:Stop(0)
end

function module.Scene2(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
    local sceneFolder = cutsceneFolder:WaitForChild("Scene2")
    local humAnim = sceneFolder:WaitForChild("Hum") :: Animation
    local camAnim = sceneFolder:WaitForChild("Cam") :: Animation

    local camAnimator = camRig:FindFirstChild("Animator", true) :: Animator
    local camHRP = camRig:WaitForChild("HumanoidRootPart") :: BasePart

    camRig:PivotTo((char.PrimaryPart :: BasePart).CFrame)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = humHrp
    weld.Part1 = camHRP
    weld.Parent = camHRP

    local humTrack = humAnimator:LoadAnimation(humAnim)
    local camTrack = camAnimator:LoadAnimation(camAnim)

    humTrack:Play(0)
    camTrack:Play(0)

    task.delay(1.5, function()
        sounds.Tap2:Play()
    end)

    task.wait(humTrack.Length)

    humTrack:Stop(0)
    camTrack:Stop(0)

    weld:Destroy()
end

function module.Scene3(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
    local sceneFolder = cutsceneFolder:WaitForChild("Scene3")
    local camCFrame = sceneFolder:WaitForChild("CamCFrame") :: CFrameValue
    local camCFrame2 = sceneFolder:WaitForChild("CamCFrame2") :: CFrameValue

    local campPart = camRig:WaitForChild("Cam") :: BasePart
    campPart.CFrame = camCFrame.Value

    camConnection = RS.Stepped:Connect(function(_, deltaTime)
        campPart.CFrame = campPart.CFrame - campPart.CFrame.LookVector * 0.06 * deltaTime
    end)

    task.wait(0.1)

    local explodePart = CollectionService:GetTagged("ExplodePart")[1] :: BasePart
    explodeBlock(explodePart)

    task.wait(0.8)
    explodeBlock(explodePart)
    task.wait(0.1)
    explodeBlock(explodePart)

    task.wait(1.1)

    task.spawn(function()
        if explodePart then
            while not stopEmiting do
                task.wait(0.1 * math.random(0.8, 1.2))
                explodeBlock(explodePart)
            end
        end
    end)

    task.wait(1)
    
    campPart.CFrame = camCFrame2.Value

    --PISCANDO AQUI
    task.spawn(function()
        local errorFrame = CollectionService:GetTagged("ErrorFrame")[1] :: Frame
        if not errorFrame then
            return
        end

        local textLabel = errorFrame:FindFirstChildOfClass("TextLabel") :: TextLabel

        errorFrame.Visible = true

        local toggle = false
        while not stopEmiting do
            toggle = not toggle

            if toggle then
                sounds.Error:Play()
            end

            errorFrame.BackgroundColor3 = toggle and Color3.fromRGB(220, 0, 0) or Color3.fromRGB(220, 220, 220)
            if textLabel then
                textLabel.TextColor3 = toggle and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(220, 0, 0)
            end

            task.wait(0.2)
        end
        errorFrame.Visible = false
    end)

    task.wait(2)

    camConnection:Disconnect()
end

function module.Scene4(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
    local sceneFolder = cutsceneFolder:WaitForChild("Scene4")
    local humAnim = sceneFolder:WaitForChild("Hum") :: Animation
    local camAnim = sceneFolder:WaitForChild("Cam") :: Animation

    local camAnimator = camRig:FindFirstChild("Animator", true) :: Animator
    local camHRP = camRig:WaitForChild("HumanoidRootPart") :: BasePart

    camRig:PivotTo((char.PrimaryPart :: BasePart).CFrame)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = humHrp
    weld.Part1 = camHRP
    weld.Parent = camHRP

    local humTrack = humAnimator:LoadAnimation(humAnim)
    local camTrack = camAnimator:LoadAnimation(camAnim)

    humTrack:Play(0)
    camTrack:Play(0)
    
    task.wait(humTrack.Length)

    humTrack:Stop(0)
    camTrack:Stop(0)

    weld:Destroy()
end

function module.Scene5(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
    local sceneFolder = cutsceneFolder:WaitForChild("Scene5")
    local humAnim = sceneFolder:WaitForChild("Hum") :: Animation
    local camCFrame = sceneFolder:WaitForChild("CamCFrame") :: CFrameValue

    local campPart = camRig:WaitForChild("Cam") :: BasePart
    campPart.CFrame = camCFrame.Value

    camConnection = RS.Stepped:Connect(function(_, deltaTime)
        campPart.CFrame = campPart.CFrame - campPart.CFrame.LookVector * 0.2 * deltaTime
    end)

    local humTrack = humAnimator:LoadAnimation(humAnim)
    humTrack:Play(0)

    task.wait(3)
    task.spawn(function()
        local player = game.Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local blackFrame = playerGui:WaitForChild("Cutscene"):WaitForChild("BlackFrame") :: Frame

        local fadeIn = TweenService:Create(blackFrame, TweenInfo.new(0.5), { BackgroundTransparency = 0 })
        local fadeOut = TweenService:Create(blackFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 })

        fadeIn:Play()
        fadeIn.Completed:Wait()
        task.wait(2)

        fadeOut:Play()
    end)

    task.wait(1)
    stopEmiting = true
    camConnection:Disconnect()
    humTrack:Stop(0)
end

function module.SetupCutscene(char: Model, hum: Humanoid, hrp: BasePart)
    setResetEnabled(false)

    char:PivotTo(introCharCFrame.Value)

    hum.WalkSpeed = 0
    hum.JumpHeight = 7.2
    hum.AutoRotate = false

    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable

    local camRig = camRig:Clone()
    local campPart = camRig:WaitForChild("Cam") :: BasePart

    local connection
    connection = RS.Stepped:Connect(function()
        cam.CFrame = campPart.CFrame
    end)

    local animController = camRig:WaitForChild("AnimationController")
    local camAnimator = animController:WaitForChild("Animator") :: Animator
    camRig.Parent = workspace

    trashConnection = CollectionService:GetInstanceAddedSignal("Trash"):Connect(function(part)
        if part:IsA("BasePart") then
            part.Transparency = 1
        end
    end)

    for _, part in ipairs(CollectionService:GetTagged("Trash")) do
        if part:IsA("BasePart") and part.Transparency ~= 1 then
            part.Transparency = 1
        end
    end

    return connection, cam, camRig
end

function module.Clean(connection: RBXScriptConnection, camRig: Model, cam: Camera, hum: Humanoid, char: Model)
    connection:Disconnect()
    camRig:Destroy()

    trashConnection:Disconnect()
    for _, part in ipairs(CollectionService:GetTagged("Trash")) do
        if part:IsA("BasePart") then
            part.Transparency = 0
        end
    end

    destroyBlocks()

    local camEndCFrame = game.ReplicatedStorage.Cutscenes.Intro:WaitForChild("CamEndCFrame") :: CFrameValue
    cam.CFrame = camEndCFrame.Value

    cam.CameraType = Enum.CameraType.Custom

    hum.WalkSpeed = 16
    hum.JumpHeight = 7.2
    hum.AutoRotate = true

    char:PivotTo(CFrame.new(-12.13, 42.5, 2.42))

    setResetEnabled(true)

    Packets.Game.requestTutorial.send({number = 2})
end

function module.Play(char: Model)
    local hum = char and char:WaitForChild("Humanoid") :: Humanoid
    local animator = hum and hum:WaitForChild("Animator") :: Animator
    local hrp = char and char:WaitForChild("HumanoidRootPart") :: BasePart
    if not (char and hum and animator and hrp) then
        print("Return") --Only for tests, will be deleated later
        return
    end

    local connection, cam, camRig = module.SetupCutscene(char, hum, hrp)
    
    print("Scene1")
    module.Scene1(char, hum, animator, hrp, camRig)
    print("Scene2")
    module.Scene2(char, hum, animator, hrp, camRig)
    print("Scene3")
    module.Scene3(char, hum, animator, hrp, camRig)
    print("Scene4")
    module.Scene4(char, hum, animator, hrp, camRig)
    print("Scene5")
    module.Scene5(char, hum, animator, hrp, camRig)

    module.Clean(connection, camRig, cam, hum, char)
end

return module