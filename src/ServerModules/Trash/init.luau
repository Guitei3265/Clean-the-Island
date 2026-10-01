local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local Trash = {}

Trash.configs = {
    totalTrash = 40000,
    islandRadius = 510,
    waitInterval = 150,
    orbitRadius = 3,
    collectDistance = 10,
}

Trash.PlayerTrash = {} :: {[Player]: {BasePart}}

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

local collectOverlapParams = OverlapParams.new()
collectOverlapParams.FilterType = Enum.RaycastFilterType.Include

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

    Packets.Economy.sellTrash.listen(function(_, player)
        print("Player selling trash")
    end)

    Packets.Game.gotTrash.listen(function(data, player)
        local rootPart = data.rootPart
        local character = player.Character

        if not (rootPart and rootPart:IsA("BasePart") and rootPart.Parent == character) then
            return
        end

        collectOverlapParams.FilterDescendantsInstances = {spawnedTrashFolder}
        local nearbyParts = workspace:GetPartBoundsInRadius(rootPart.Position, Trash.configs.collectDistance, collectOverlapParams)

        local closestTrash: BasePart? = nil
        local closestDistance = Trash.configs.collectDistance

        for _, trashPart in ipairs(nearbyParts) do
            if not trashPart:GetAttribute("Collected") then
                local distance = (trashPart.Position - rootPart.Position).Magnitude

                if distance <= closestDistance then
                    closestDistance = distance
                    closestTrash = trashPart
                end
            end
        end

        if not closestTrash then return end

        closestTrash:SetAttribute("Collected", true)

        Trash.PlayerTrash[player] = Trash.PlayerTrash[player] or {}
        table.insert(Trash.PlayerTrash[player], closestTrash)
    end)

    RunService.Heartbeat:Connect(function()
        for player, trashParts in pairs(Trash.PlayerTrash) do
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end

            for i, trashPart in ipairs(trashParts) do
                local angle = i * (2 * math.pi / #trashParts)

                local offset = Vector3.new(
                    math.cos(angle) * Trash.configs.orbitRadius,
                    2,
                    math.sin(angle) * Trash.configs.orbitRadius
                )

                trashPart.CFrame = CFrame.new(rootPart.Position + offset)
            end
        end
    end)
end

return Trash
