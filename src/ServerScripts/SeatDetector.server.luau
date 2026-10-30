local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local benchPressAnim = game.ReplicatedStorage:WaitForChild("Effects"):WaitForChild("BenchPressAnim") :: Animation

local function PlayerAdded(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()

    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid
    if not humanoid then return end

    local animator = humanoid:WaitForChild("Animator", 3) :: Animator
    if not animator then return end

    local benchPressTrack = animator:LoadAnimation(benchPressAnim)

    local currentBar: BasePart? = nil
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
        local nearestBar = GetNearestBar()
        currentBar = nearestBar and nearestBar:Clone()
        if currentBar then
            currentBar.Transparency = 0.7
            currentBar.Parent = nearestBar.Parent
            
            player:RequestStreamAroundAsync(currentBar.Position) -- garante que a parte esteja carregada no cliente antes de enviar a referência
            task.wait()

            Packets.Effects.BPBar.sendTo({bar = currentBar}, player)
        end

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

        if currentBar then
            currentBar:Destroy()
            currentBar = nil
        end

        benchPressTrack:Stop()
    end

    humanoid.Seated:Connect(function(active: boolean)
        if active then
            BenchPress()
        else
            Stop()
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    PlayerAdded(player)
end

Players.PlayerAdded:Connect(PlayerAdded)
