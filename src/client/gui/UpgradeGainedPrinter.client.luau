local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gainedGui = playerGui:WaitForChild("Gained")
local mainFrame = gainedGui:WaitForChild("MainFrame")

local templates = {
    Speed = mainFrame:WaitForChild("TempleteSpeed"),
    Strength = mainFrame:WaitForChild("TempleteStrength"),
}

local GROW_TIME = 0.2
local SPIN_TIME = 0.15
local HOLD_TIME = 0.3
local FADE_TIME = 0.2

local function popupGained(templateName: string, gained: number)
    if gained == 0 then
        return
    end

    local template = templates[templateName]
    if not template then
        return
    end

    local popup = template:Clone()
    popup.Visible = true
    popup.Rotation = 0
    popup.Position = UDim2.fromScale(math.random(), math.random())

    local imageLabel = popup:FindFirstChildOfClass("ImageLabel")
    local textLabel = popup:FindFirstChildOfClass("TextLabel") :: TextLabel
    local uiStroke = textLabel and textLabel:FindFirstChildOfClass("UIStroke")

    if textLabel then
        textLabel.Text = "+" .. tostring(gained)
    end

    local originalSize = template.Size
    popup.Size = UDim2.new(originalSize.X.Scale * 0.1, 0, originalSize.Y.Scale * 0.1, 0)

    popup.Parent = mainFrame

    local growTween = TweenService:Create(popup, TweenInfo.new(GROW_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = originalSize,
    })

    growTween:Play()
    growTween.Completed:Wait()

    local spinTween = TweenService:Create(popup, TweenInfo.new(SPIN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Rotation = 12,
    })
    spinTween:Play()
    spinTween.Completed:Wait()

    local spinBackTween = TweenService:Create(popup, TweenInfo.new(SPIN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        Rotation = 0,
    })
    spinBackTween:Play()
    spinBackTween.Completed:Wait()

    task.wait(HOLD_TIME)

    local fadeGoal = {}
    if imageLabel then
        fadeGoal.ImageTransparency = 1
    end

    local imageFadeTween = imageLabel and TweenService:Create(imageLabel, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {
        ImageTransparency = 1,
    })

    local textFadeTween = textLabel and TweenService:Create(textLabel, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {
        TextTransparency = 1,
    })

    local strokeFadeTween = uiStroke and TweenService:Create(uiStroke, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {
        Transparency = 1,
    })

    if imageFadeTween then
        imageFadeTween:Play()
    end
    if textFadeTween then
        textFadeTween:Play()
    end
    if strokeFadeTween then
        strokeFadeTween:Play()
    end

    task.wait(FADE_TIME)

    popup:Destroy()
end

Packets.Upgrades.updateSpeed.listen(function(data)
    task.spawn(popupGained, "Speed", data.gained)
end)

Packets.Upgrades.updateStrength.listen(function(data)
    task.spawn(popupGained, "Strength", data.gained)
end)
