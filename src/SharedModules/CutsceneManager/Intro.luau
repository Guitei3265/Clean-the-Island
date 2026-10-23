module = {}

local RS = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local cutsceneFolder = game.ReplicatedStorage:WaitForChild("Cutscenes"):WaitForChild("Intro")
local introCharCFrame = cutsceneFolder:WaitForChild("IntroCharCFrame")

local camRig = cutsceneFolder:WaitForChild("CameraRig") :: Model

local trashFolder = game.ReplicatedStorage:WaitForChild("Trash")

local playEvent = game.ReplicatedStorage:WaitForChild("BindableEvents"):WaitForChild("Play") :: BindableEvent

local explodeForce = 170

local sounds = game.SoundService:WaitForChild("Intro")
local plopSound = sounds:WaitForChild("Plop") :: Sound

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

    plopSound:Play()

    blockPart.AssemblyLinearVelocity = Vector3.new(math.random(-30, 30), math.random(explodeForce * 0.8, explodeForce * 1.2), math.random(-30, 30))
    blockPart.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))

    task.delay(5, function()
        block:Destroy()
    end)
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
    --[[campPart.CFrame = (camRig.PrimaryPart :: BasePart).CFrame

    camRig:PivotTo(camCFrame.Value)]]

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
            for i = 1, 100 do
                task.wait(0.1 * math.random(0.8, 1.2))
                explodeBlock(explodePart)
            end
        end
    end)
    
    task.wait(1)

    campPart.CFrame = camCFrame2.Value

    --PISCANDO AQUI
    local disableErrorFrame = false
    task.spawn(function()
        local errorFrame = CollectionService:GetTagged("ErrorFrame")[1] :: Frame
        if not errorFrame then
            return
        end

        local textLabel = errorFrame:FindFirstChildOfClass("TextLabel") :: TextLabel

        errorFrame.Visible = true

        local toggle = false
        for i = 1, 14 do
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
end

--[[
function module.SceneX(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
    local sceneFolder = cutsceneFolder:WaitForChild("SceneX")
    local humAnim = sceneFolder:WaitForChild("Hum") :: Animation
    local camCFrame = sceneFolder:WaitForChild("CamCFrame") :: CFrameValue

    local camRig = camRig:Clone()
    local campPart = camRig:WaitForChild("Cam") :: BasePart

    --local humTrack = animator:LoadAnimation(humAnim)
    --local camTrack = camAnimator:LoadAnimation(camAnim)
end
]]

function module.SetupCutscene(char: Model, hum: Humanoid, hrp: BasePart)
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

    return connection, cam, camRig
end

function module.Clean(connection: RBXScriptConnection, camRig: Model, cam: Camera, hum: Humanoid)
    connection:Disconnect()
    camRig:Destroy()

    cam.CameraType = Enum.CameraType.Custom

    hum.WalkSpeed = 16
    hum.JumpHeight = 7.2
    hum.AutoRotate = true
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
    
    module.Scene1(char, hum, animator, hrp, camRig)
    module.Scene2(char, hum, animator, hrp, camRig)
    module.Scene3(char, hum, animator, hrp, camRig)

    module.Clean(connection, camRig, cam, hum)
end

return module