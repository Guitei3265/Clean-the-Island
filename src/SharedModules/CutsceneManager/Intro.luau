module = {}

local RS = game:GetService("RunService")

local cutsceneFolder = game.ReplicatedStorage:WaitForChild("Cutscenes"):WaitForChild("Intro")
local humAnim = cutsceneFolder:WaitForChild("Hum")
local camAnim = cutsceneFolder:WaitForChild("Cam")
local camRig = cutsceneFolder:WaitForChild("CameraRig") :: Model

function module.Play(char: Model)
    local hum = char and char:FindFirstChild("Humanoid") :: Humanoid
    local animator = hum and hum:WaitForChild("Animator") :: Animator
    local hrp = char and char:WaitForChild("HumanoidRootPart") :: BasePart
    if not (char and hum and animator and hrp) then
        print("Return") --Only for tests, will be deleated later
        return
    end

    hum.WalkSpeed = 0
    hum.JumpHeight = 7.2
    hum.AutoRotate = false

    local camRig = camRig:Clone()
    local campPart = camRig:WaitForChild("Cam") :: BasePart
    local camHRP = camRig:WaitForChild("HumanoidRootPart") :: BasePart
    local animController = camRig:WaitForChild("AnimationController")
    local camAnimator = animController:WaitForChild("Animator") :: Animator
    camRig.Parent = workspace

    local humTrack = animator:LoadAnimation(humAnim)
    local camTrack = camAnimator:LoadAnimation(camAnim)

    camRig:PivotTo(hrp.CFrame)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = camHRP
    weld.Parent = camHRP

    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable

    local connection
    connection = RS.Stepped:Connect(function()
        cam.CFrame = campPart.CFrame
    end)

    humTrack:Play(0)
    camTrack:Play(0)

    task.wait(10)

    connection:Disconnect()
    camRig:Destroy()

    cam.CameraType = Enum.CameraType.Custom

    hum.WalkSpeed = 16
    hum.JumpHeight = 7.2
    hum.AutoRotate = true
end

return module