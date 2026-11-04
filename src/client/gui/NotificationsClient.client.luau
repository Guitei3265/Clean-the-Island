local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local errorSound = SoundService:WaitForChild("Error") :: Sound

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local notifications = playerGui:WaitForChild("Notifications")
local template = notifications:WaitForChild("Templete") :: TextLabel

local notificationDuration = 5
local fadeTime = 0.5

local layoutOrder = 0

template.Visible = false

local function ErrorMessage(text: string)
    layoutOrder -= 1

    local notification = template:Clone()
    notification.Text = text
    notification.TextColor3 = Color3.fromRGB(255, 40, 40)
    notification.LayoutOrder = layoutOrder
    notification.Visible = true
    notification.Parent = notifications

    local uiStroke = notification:FindFirstChildOfClass("UIStroke")

    task.delay(notificationDuration, function()
        TweenService:Create(notification, TweenInfo.new(fadeTime, Enum.EasingStyle.Linear), {
            TextTransparency = 1,
        }):Play()

        if uiStroke then
            TweenService:Create(uiStroke, TweenInfo.new(fadeTime, Enum.EasingStyle.Linear), {
                Transparency = 1,
            }):Play()
        end

        task.delay(fadeTime, function()
            notification:Destroy()
        end)
    end)

    errorSound:Play()
end

Packets.Notifications.errorMessage.listen(function(data)
    ErrorMessage(data.text)
end)
