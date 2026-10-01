local ServerStorage = game:GetService("ServerStorage")

local Trash = {}

Trash.configs = {
    totalTrash = 40000,
    islandRadius = 510,
    waitInterval = 150,
}

Trash.Colors = {
    Color3.fromHex("cc8e69"),
    Color3.fromRGB(162, 163, 165),
    Color3.fromHex("264653"),
    Color3.fromHex("151e3f"),
    Color3.fromHex("030027"),
}

local trashFolder: Folder
local spawnedTrashFolder: Folder
local trashRemaining = 0

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {}

function Trash.Spawn()
    trashRemaining = Trash.configs.totalTrash

    local trashTemplates = trashFolder:GetChildren()

    local iterations = 0

    while trashRemaining > 0 do
        local angle = math.random(0, 36000) / 100
        local radians = math.rad(angle)

        local distance = 1 + (Trash.configs.islandRadius - 1) * math.sqrt(math.random())

        local x = math.cos(radians) * distance
        local z = math.sin(radians) * distance

        local origin = Vector3.new(x, 1000, z)
        local direction = Vector3.new(0, -2000, 0)

        local result = workspace:Raycast(origin, direction, raycastParams)

        if result and result.Instance == workspace.Terrain and (result.Material == Enum.Material.Grass or result.Material == Enum.Material.Sand) then
            local template = trashTemplates[math.random(1, #trashTemplates)]

            local randomRotation = math.rad(math.random(0, 36000) / 100)
            local randomScale = math.random(8, 12) / 10

            local trashPart: BasePart = template:Clone()
            trashPart.Size *= randomScale
            trashPart.Color = Trash.Colors[math.random(1, #Trash.Colors)]

            local heightOffset = trashPart.Size.Y / 4
            local spawnPosition = result.Position + Vector3.new(0, heightOffset, 0)

            trashPart.CFrame = CFrame.new(spawnPosition) * CFrame.Angles(0, randomRotation, 0)
            trashPart.Parent = spawnedTrashFolder

            trashRemaining -= 1

            iterations += 1
            if iterations % Trash.configs.waitInterval == 0 then
                task.wait()
            end
        end
    end
end

function Trash.Init()
    trashFolder = ServerStorage:WaitForChild("Trash")
    spawnedTrashFolder = workspace:WaitForChild("Trash")

    Trash.Spawn()
end

return Trash
