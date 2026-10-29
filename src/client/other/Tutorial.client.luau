local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Packets = require(ReplicatedStorage.SharedModules.Packets)

local player = Players.LocalPlayer

local upgradeSound = game.SoundService:WaitForChild("Upgrade")

local arrowsBeamTemplate = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("ArrowsBeam") :: Beam

local beams = {}
local trackingConnection: RBXScriptConnection?

local ringStartRadius = 16
local ringMaxRadius = 4096

local function getNearestTagged(tag: string, position: Vector3): BasePart?
    local taggedParts = CollectionService:GetTagged(tag)
    if #taggedParts == 0 then return end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = taggedParts

    local radius = ringStartRadius
    while radius <= ringMaxRadius do
        local nearest: BasePart
        local nearestDistance: number

        for _, part: BasePart in ipairs(workspace:GetPartBoundsInRadius(position, radius, overlapParams)) do
            if part:GetAttribute("Collected") then continue end

            local distance = (part.Position - position).Magnitude
            if not nearestDistance or distance < nearestDistance then
                nearest = part
                nearestDistance = distance
            end
        end

        if nearest then
            return nearest
        end

        radius *= 2
    end

    return nil
end

local function destroyBeams()
    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end

    for _, beam: Beam in ipairs(beams) do
        if beam.Attachment0 then
            beam.Attachment0:Destroy()
        end
        if beam.Attachment1 then
            beam.Attachment1:Destroy()
        end
        beam:Destroy()
    end
    table.clear(beams)
end

local function Stage2()
    destroyBeams()

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
    if not rootPart then return end

    local trash = getNearestTagged("Trash", rootPart.Position)
    if not trash then return end

    local beam = arrowsBeamTemplate:Clone()
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 140, 0))

    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = trash

    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = rootPart

    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Parent = rootPart

    table.insert(beams, beam)

    local currentTrash = trash
    local elapsed = 0

    trackingConnection = RunService.Stepped:Connect(function(_, deltaTime)
        elapsed += deltaTime
        if elapsed < 0.1 then return end
        elapsed = 0

        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
        if not root then return end

        local nearest = getNearestTagged("Trash", root.Position)
        if nearest and nearest ~= currentTrash then
            currentTrash = nearest
            attachment0.Parent = nearest
        end
    end)
end

local function Stage3()
    upgradeSound:Play()
    destroyBeams()

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
    if not rootPart then return end

    local sellBeamPart = getNearestTagged("SellBeam", rootPart.Position)
    if not sellBeamPart then return end

    local beam = arrowsBeamTemplate:Clone()
    beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))

    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = sellBeamPart

    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = rootPart

    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Parent = rootPart

    table.insert(beams, beam)
end

local function Stage4()
    destroyBeams()

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
    if not rootPart then return end

    local gymBeamPart = getNearestTagged("GymBeam", rootPart.Position)
    if not gymBeamPart then return end

    local beam = arrowsBeamTemplate:Clone()
    beam.Color = ColorSequence.new(Color3.fromRGB(135, 206, 250))

    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = gymBeamPart

    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = rootPart

    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Parent = rootPart

    table.insert(beams, beam)
end

local STAGE5_STROKE_TWEEN_TIME = 1

local requestedStage5 = false
local function Stage5(data)
    if requestedStage5 or data.gained <= 0 then return end
    requestedStage5 = true

    upgradeSound:Play()
    Packets.Game.requestTutorial.send({number = 5})

    for _, stroke: UIStroke in ipairs(CollectionService:GetTagged("Stage5Stroke")) do
        stroke.Enabled = true

        TweenService:Create(stroke, TweenInfo.new(STAGE5_STROKE_TWEEN_TIME), {
            BorderOffset = UDim.new(0.2, 0),
            Transparency = 0.1,
        }):Play()
    end
end

local function Stage6(data)
    if data.workoutMultiplier == 1 then return end

    destroyBeams()
    Packets.Game.requestTutorial.send({number = 6})

    for _, stroke: UIStroke in ipairs(CollectionService:GetTagged("Stage5Stroke")) do
        local tween = TweenService:Create(stroke, TweenInfo.new(STAGE5_STROKE_TWEEN_TIME / 4), {
            BorderOffset = UDim.new(10, 0),
            Transparency = 1,
        })

        tween.Completed:Once(function()
            stroke.Enabled = false
        end)

        tween:Play()
    end
end

Packets.Effects.trashBeam.listen(Stage2)

Packets.Effects.sellBeam.listen(Stage3)

Packets.Effects.gymBeam.listen(Stage4)

Packets.Upgrades.updateSpeed.listen(Stage5)
Packets.Upgrades.updateStrength.listen(Stage5)

Packets.Data.sendWorkoutMultiplier.listen(Stage6)

local requestedStage3 = false

Packets.Game.trashGrabbed.listen(function(data)
    if requestedStage3 or data.count <= 0 then return end
    requestedStage3 = true

    Packets.Game.requestTutorial.send({number = 3})
end)

local requestedStage4 = false

Packets.Economy.gotCash.listen(function()
    if requestedStage4 then return end
    requestedStage4 = true

    destroyBeams()
    Packets.Game.requestTutorial.send({number = 4})
end)
