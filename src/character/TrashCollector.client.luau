local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local SharedUpgrades = require(game.ReplicatedStorage.SharedModules.Upgrades)

local character = script.Parent

local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart
if not humanoidRootPart then return end

local plopSound = SoundService:WaitForChild("Plop") :: Sound
local plopBaseVolume = plopSound.Volume

local COLLECT_RADIUS = 10
local SEND_INTERVAL = 0.12
local CHECK_INTERVAL = 0.05

local BUTTON_ORIGINAL_SIZE = UDim2.new(0.2, 0, 0.12, 0)
local BUTTON_PRESS_SCALE = 0.7

Packets.Data.sendReach.listen(function(data)
    COLLECT_RADIUS = data.reach
end)

local capacityMax = 1
local capacityUse = 0

local function hasFreeCapacity(): boolean
    return capacityUse < capacityMax
end

Packets.Game.trashGrabbed.listen(function(data)
    capacityUse = data.count
end)

Packets.Upgrades.updateStrength.listen(function(data)
    capacityMax = SharedUpgrades.GetBuff(data.total) + 1
end)

Packets.Upgrades.request.send()

local function isOnTreadmill(): boolean
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = CollectionService:GetTagged("GymGround")

    local result = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -5, 0), params)

    return result ~= nil
end

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

local function playPressEffect(button: GuiObject)
    local shrinkTween = TweenService:Create(
        button,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(
            BUTTON_ORIGINAL_SIZE.X.Scale * BUTTON_PRESS_SCALE,
            BUTTON_ORIGINAL_SIZE.X.Offset * BUTTON_PRESS_SCALE,
            BUTTON_ORIGINAL_SIZE.Y.Scale * BUTTON_PRESS_SCALE,
            BUTTON_ORIGINAL_SIZE.Y.Offset * BUTTON_PRESS_SCALE
        )}
    )

    local bounceTween = TweenService:Create(
        button,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = BUTTON_ORIGINAL_SIZE}
    )

    shrinkTween.Completed:Connect(function()
        bounceTween:Play()
    end)

    shrinkTween:Play()
end

local function setHolding(source: any, holding: boolean)
    if holding then
        activeHolds[source] = true

        if hasNearbyTrash() then
            Packets.Game.gotTrash.send({rootPart = humanoidRootPart})

            if typeof(source) == "Instance" and source:IsA("GuiObject") then
                playPressEffect(source)
            else
                for _, button in ipairs(CollectionService:GetTagged("GrabButton")) do
                    if button:IsA("GuiObject") then
                        playPressEffect(button)
                    end
                end
            end
        end
    else
        activeHolds[source] = nil
    end
end

local function isHolding(): boolean
    return next(activeHolds) ~= nil
end

local function setButtonsVisible(visible: boolean)
    for _, button in ipairs(CollectionService:GetTagged("GrabButton")) do
        if button:IsA("GuiObject") then
            button.Visible = visible
        end
    end
end

local grabButtons: {[GuiButton]: true} = {}

local function updateButtonLabels()
    local inputType = UserInputService:GetLastInputType()

    local isGamepad = inputType.Name:match("^Gamepad") ~= nil
    local isTouch = inputType == Enum.UserInputType.Touch
    local visible = not isTouch

    local text = isGamepad and "X" or "E"

    for _, button in ipairs(CollectionService:GetTagged("GrabButton")) do
        local inputLabel = button:FindFirstChild("InputLabel")
        if inputLabel and inputLabel:IsA("TextLabel") then
            inputLabel.Visible = visible
            inputLabel.Text = text
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

Packets.Game.trashGrabbed.listen(function()
    plopSound.PlaybackSpeed = (math.random(9, 11) / 10) * 1.1
    plopSound.Volume = plopBaseVolume * (math.random(9, 11) / 10)
    plopSound:Play()

    for _, button in ipairs(CollectionService:GetTagged("GrabButton")) do
        if button:IsA("GuiObject") then
            playPressEffect(button)
        end
    end
end)

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

task.spawn(function()
    while true do
        setButtonsVisible(hasFreeCapacity() and hasNearbyTrash() and not isOnTreadmill())
        task.wait(CHECK_INTERVAL)
    end
end)

Packets.Data.requestReach.send()
