local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)

local clima = {}

local currentWeather = ""

local weatherStates = {
    Sunny = 7, --7
    LightRain = 2,
    HeavyRain = 1,
}

local weatherTime = 20

local trashFolder = game.Workspace:FindFirstChild("Trash")

local function gameEnded()
    local ended = false
    if #trashFolder:GetChildren() <= 1 then
        ended = true
    end
    return ended
end

function clima.Sorteio(): string
    if gameEnded() then
        return "Sunny"
    end

    local totalWeight = 0
    for _, weight in pairs(weatherStates) do
        totalWeight += weight
    end

    local roll = math.random(1, totalWeight)

    local accumulated = 0
    for weather, weight in pairs(weatherStates) do
        accumulated += weight
        if roll <= accumulated then
            return weather
        end
    end

    return assert(next(weatherStates))
end

function clima.Iteracao()
    local result = clima.Sorteio()
    currentWeather = result

    Packets.Clima.sendWeather.sendToAll({weather = currentWeather})
end

function clima.Init()
    Packets.Clima.requestWeather.listen(function(_, player)
        local profile = DataMethods.WaitForProfile(player)

        if not profile or not profile.cutscene then
            print("Cutscene")
            Packets.Clima.sendWeather.sendTo({weather = "Sunny"}, player)
            return
        end

        Packets.Clima.sendWeather.sendTo({weather = currentWeather}, player)
    end)

    task.spawn(function()
        while true do
            local success, err = pcall(clima.Iteracao)

            if not success then
                warn(err)
            end

            task.wait(weatherTime)
        end
    end)
end

return clima
