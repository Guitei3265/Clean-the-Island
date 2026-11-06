local Cleaned = require(script.Cleaned)

local Events = {}

function Events.Init()
    local trashFolder = workspace:WaitForChild("Trash")

    task.spawn(function()
        while task.wait(2) do
            if #trashFolder:GetChildren() == 0 and not Cleaned.Running then
                Cleaned.Init()
            end
        end
    end)
end

return Events
