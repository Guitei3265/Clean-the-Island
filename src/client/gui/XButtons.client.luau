local CS = game:GetService("CollectionService")
local tagName = "XButton"

local function Tagged(tagged: GuiButton)
    if not tagged:IsA("GuiButton") then return end
    
    tagged.Activated:Connect(function()
        local frame = tagged.Parent
        if frame and frame.Visible then
            frame.Visible = false
        end
    end)
end

CS:GetInstanceAddedSignal(tagName):Connect(Tagged)

for _, v in pairs(CS:GetTagged(tagName)) do
    Tagged(v)
end
