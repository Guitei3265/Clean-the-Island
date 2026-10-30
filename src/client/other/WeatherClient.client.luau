local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local player = Players.LocalPlayer

local TWEEN_TIME = 2

local clouds = game.Workspace.Terrain.Clouds

local currentWeather: string? = nil
local currentSound: Sound? = nil
local rainPart: BasePart? = nil
local rainConnection: RBXScriptConnection? = nil

local function CreateRainPart(rate: number)
    if not rainPart then
        local newRainPart = ReplicatedStorage.Effects.RainPart:Clone() :: BasePart
        newRainPart.Parent = workspace
        rainPart = newRainPart
    end

    for _, child in ipairs((rainPart :: BasePart):GetChildren()) do
        if child.Name == "Rain" and child:IsA("ParticleEmitter") then
            child.Rate = rate
        end
    end
end

local function ConnectRain()
    rainConnection = RunService.Stepped:Connect(function()
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

        if not (rainPart and rootPart) then return end

        rainPart.Position = Vector3.new(rootPart.Position.X, rootPart.Position.Y + 50, rootPart.Position.Z)
    end)
end

local function Sunny()
    TweenService:Create(clouds, TweenInfo.new(TWEEN_TIME), {
        Density = 0,
        Cover = 0,
    }):Play()

    TweenService:Create(Lighting, TweenInfo.new(TWEEN_TIME), {
        Brightness = 3.5,
    }):Play()

    if rainConnection then
        rainConnection:Disconnect()
        rainConnection = nil
    end

    if rainPart then
        rainPart:Destroy()
        rainPart = nil
    end
end

local function LightRain()
    TweenService:Create(clouds, TweenInfo.new(TWEEN_TIME), {
        Density = 0.5,
        Cover = 1,
    }):Play()

    TweenService:Create(Lighting, TweenInfo.new(TWEEN_TIME), {
        Brightness = 3,
    }):Play()

    CreateRainPart(170)
    ConnectRain()
end

local function HeavyRain()
    TweenService:Create(clouds, TweenInfo.new(TWEEN_TIME), {
        Density = 0.5,
        Cover = 1,
    }):Play()

    TweenService:Create(Lighting, TweenInfo.new(TWEEN_TIME), {
        Brightness = 0,
    }):Play()

    CreateRainPart(500)
    ConnectRain()
end

Packets.Clima.sendWeather.listen(function(data)
    if data.weather == currentWeather then return end
    currentWeather = data.weather

    if currentSound then
        local sound = currentSound
        local originalVolume = sound.Volume

        local fadeOutTween = TweenService:Create(sound, TweenInfo.new(TWEEN_TIME), {
            Volume = 0,
        })

        fadeOutTween.Completed:Connect(function()
            sound:Stop()
            sound.Volume = originalVolume
        end)

        fadeOutTween:Play()
    end

    local sound = game.SoundService.Clima:FindFirstChild(data.weather) :: Sound?
    if sound then
        local targetVolume = sound.Volume
        sound.Volume = 0
        sound:Play()

        TweenService:Create(sound, TweenInfo.new(TWEEN_TIME), {
            Volume = targetVolume,
        }):Play()
    end
    currentSound = sound
    
    if data.weather == "Sunny" then
        Sunny()
    elseif data.weather == "LightRain" then
        LightRain()
    elseif data.weather == "HeavyRain" then
        HeavyRain()
    end
end)

Packets.Clima.requestWeather.send()
