local CollectionService = game:GetService("CollectionService")

local character = script.Parent

local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart
if not humanoidRootPart then return end

local RADIUS = 6
local CHECK_INTERVAL = 0.05

local function hasNearbyTrash(): boolean
    local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, RADIUS)

    for _, part in ipairs(parts) do
        if CollectionService:HasTag(part, "Trash") then
            return true
        end
    end

    return false
end

local function setButtonsVisible(visible: boolean)
    for _, button in ipairs(CollectionService:GetTagged("GrabButton")) do
        if button:IsA("GuiObject") then
            button.Visible = visible
        end
    end
end

while true do
    setButtonsVisible(hasNearbyTrash())
    task.wait(CHECK_INTERVAL)
end
