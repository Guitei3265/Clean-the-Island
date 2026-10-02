local Players = game:GetService("Players")

local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)

local Events = {}

function Events.Cleaned()
    print("Everything clean!")

    for _, player in ipairs(Players:GetPlayers()) do
        DataMethods.WaitForProfile(player)
        DataMethods.SetKey(player, "Islands", DataMethods.ReturnKey(player, "Islands") + 1)
    end
end

function Events.Init()
    local trashFolder = workspace:WaitForChild("Trash")

    task.spawn(function()
        while task.wait(2) do
            if #trashFolder:GetChildren() == 0 then
                Events.Cleaned()
            end
        end
    end)
end

return Events
