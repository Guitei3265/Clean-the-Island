local CS = game:GetService("CollectionService")
local tagName = "ButtonClick"

local sounds = {
	S = game.SoundService:WaitForChild("ButtonClickS"),
	N = game.SoundService:WaitForChild("ButtonClickN"),
	F = game.SoundService:WaitForChild("ButtonClickF")
}

local function Button(button: GuiButton)
    if not button:IsA("GuiButton") then return end

    local soundAttribute = button:GetAttribute("Sound")
    if not soundAttribute then
        warn("Not sound attribute")
        return
    end

    local sound = sounds[soundAttribute] :: Sound

    if not sound then
        warn("No sound")
        return
    end

    button.Activated:Connect(function()
        sound:Play()
    end)
end

CS:GetInstanceAddedSignal(tagName):Connect(Button)

for _, label in pairs(CS:GetTagged(tagName)) do
    Button(label)
end
