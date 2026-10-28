local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packets = require(ReplicatedStorage.SharedModules.Packets)

local player = Players.LocalPlayer

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

Packets.Effects.trashBeam.listen(function()
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
end)

Packets.Effects.sellBeam.listen(function()
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
end)

Packets.Effects.gymBeam.listen(function()
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
end)

local requestedStage5 = false

local function onReachedGym(data)
    if requestedStage5 or data.gained <= 0 then return end
    requestedStage5 = true

    destroyBeams()
    Packets.Game.requestTutorial.send({number = 5})
end

Packets.Upgrades.updateSpeed.listen(onReachedGym)
Packets.Upgrades.updateStrength.listen(onReachedGym)

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
