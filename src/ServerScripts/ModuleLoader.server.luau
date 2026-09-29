local modulesFolder = game.ServerStorage.ServerModules

local dataModule = require(modulesFolder:WaitForChild("DataManager"))
dataModule.Init()

local skip = {"DataManager"}

for _, module: ModuleScript in pairs(modulesFolder:GetChildren()) do
    if module:IsA("ModuleScript") and not table.find(skip, module.Name) then
        local success, err = pcall(function()
            local requiredModule = require(module)

            if requiredModule.Init then
                requiredModule.Init()
            end
        end)

        if not success and err then
            warn(err)
        end
    end
end
