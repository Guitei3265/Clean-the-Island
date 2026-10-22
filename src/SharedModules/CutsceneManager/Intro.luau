module = {}

local RS = game:GetService("RunService")

local cutsceneFolder = game.ReplicatedStorage:WaitForChild("Cutscenes"):WaitForChild("Intro")
local introCharCFrame = cutsceneFolder:WaitForChild("IntroCharCFrame")

local camRig = cutsceneFolder:WaitForChild("CameraRig") :: Model

local playEvent = game.ReplicatedStorage:WaitForChild("BindableEvents"):WaitForChild("Play") :: BindableEvent

function module.Scene1(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
    local sceneFolder = cutsceneFolder:WaitForChild("Scene1")
    local humAnim = sceneFolder:WaitForChild("Hum") :: Animation
    local camCFrame = sceneFolder:WaitForChild("CamCFrame") :: CFrameValue

    camRig:PivotTo(camCFrame.Value)

    local camHRP = camRig:WaitForChild("HumanoidRootPart") :: BasePart
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = humHrp
    weld.Part1 = camHRP
    weld.Parent = camHRP

    local humTrack = humAnimator:LoadAnimation(humAnim)
    humTrack:Play(0)

    playEvent.Event:Wait()

    humTrack:Stop(0)
end

--[[
function module.SceneX(char: Model, hum: Humanoid, humAnimator: Animator, humHrp: BasePart, camRig: Model)
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
    local hum = char and char:FindFirstChild("Humanoid") :: Humanoid
    local animator = hum and hum:WaitForChild("Animator") :: Animator
    local hrp = char and char:WaitForChild("HumanoidRootPart") :: BasePart
    if not (char and hum and animator and hrp) then
        print("Return") --Only for tests, will be deleated later
        return
    end

    local connection, cam, camRig = module.SetupCutscene(char, hum, hrp)
    
    module.Scene1(char, hum, animator, hrp, camRig)

    module.Clean(connection, camRig, cam, hum)
end

return module