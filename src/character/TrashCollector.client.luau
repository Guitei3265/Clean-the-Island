local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local character = script.Parent

local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart
if not humanoidRootPart then return end

local plopSound = SoundService:WaitForChild("Plop") :: Sound
local plopBaseVolume = plopSound.Volume

Packets.Game.trashGrabbed.listen(function()
    plopSound.PlaybackSpeed = (math.random(9, 11) / 10) * 1.1
    plopSound.Volume = plopBaseVolume * (math.random(9, 11) / 10)
    plopSound:Play()
end)

local COLLECT_RADIUS = 10
local SEND_INTERVAL = 0.12

local function hasNearbyTrash(): boolean
    local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, COLLECT_RADIUS)

    for _, part in ipairs(parts) do
        if CollectionService:HasTag(part, "Trash") then
            if part:GetAttribute("Collected") then
                continue
            end

            return true
        end
    end

    return false
end

-- Cada fonte (teclado, gamepad, cada botao 'Grab') registra sua propria chave aqui.
-- isHolding() fica true enquanto houver pelo menos uma fonte segurando.
local activeHolds: {[any]: boolean} = {}

local function setHolding(source: any, holding: boolean)
    if holding then
        activeHolds[source] = true
    else
        activeHolds[source] = nil
    end
end

local function isHolding(): boolean
    return next(activeHolds) ~= nil
end

local function getButtonLabel(button: GuiButton): (TextButton | TextLabel)?
    if button:IsA("TextButton") then
        return button
    end

    return button:FindFirstChildWhichIsA("TextLabel", true)
end

local grabButtons: {[GuiButton]: true} = {}

local function updateButtonLabels()
    local inputType = UserInputService:GetLastInputType()

    local text = "E"
    if inputType.Name:match("^Gamepad") then
        text = "X"
    elseif inputType == Enum.UserInputType.Touch then
        text = ""
    end

    for button in pairs(grabButtons) do
        local label = getButtonLabel(button)
        if label then
            label.Text = text
        end
    end
end

local function TaggedGrabButton(button: Instance)
    if not button:IsA("GuiButton") then return end

    grabButtons[button] = true
    updateButtonLabels()

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        setHolding(button, true)
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        setHolding(button, false)
    end)
end

for _, button in ipairs(CollectionService:GetTagged("GrabButton")) do
    TaggedGrabButton(button)
end

CollectionService:GetInstanceAddedSignal("GrabButton"):Connect(TaggedGrabButton)

UserInputService.LastInputTypeChanged:Connect(updateButtonLabels)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
        setHolding("Physical", true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
        setHolding("Physical", false)
    end
end)

task.spawn(function()
    while true do
        if isHolding() and hasNearbyTrash() then
            Packets.Game.gotTrash.send({rootPart = humanoidRootPart})
        end

        task.wait(SEND_INTERVAL)
    end
end)
