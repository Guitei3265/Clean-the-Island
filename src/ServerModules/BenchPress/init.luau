local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local Upgrades = require(game.ServerStorage.ServerModules.Upgrades)

local benchPress = {}

function benchPress.Connect(player: Player, seat: Seat, humanoid: Humanoid)
    if seat.Occupant ~= humanoid then return end

    local connection: RBXScriptConnection? = nil
    local timer = 0

    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if seat.Occupant ~= humanoid or player.Parent == nil then
            if connection then
                connection:Disconnect()
            end
            return
        end

        timer += deltaTime

        if timer > 0.25 then
            timer -= 0.25

            local category = seat:GetAttribute("Category")
            local multiplier = Upgrades.GetStationMultiplier(player, category)

            Upgrades.Strengthed(player, multiplier)
        end
    end)
end

function benchPress.RequestBenchPress(data, player: Player)
    local seat = data.seat

    if not (seat and seat:IsA("Seat")) then
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local seatsFolder = seat.Parent
    if not seatsFolder then return end

    for _, otherSeat in seatsFolder:GetChildren() do
        if otherSeat:IsA("Seat") and not otherSeat.Occupant then
            local category = otherSeat:GetAttribute("Category")

            if Upgrades.CanUseStation(player, category) then
                otherSeat:Sit(humanoid)

                break
            end
        end
    end
end

function benchPress.Tagged(seat: Seat)
    if not seat:IsA("Seat") then return end

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local humanoid = seat.Occupant
        if not humanoid then return end

        local player = Players:GetPlayerFromCharacter(humanoid.Parent)
        if not player then return end

        benchPress.Connect(player, seat, humanoid)
    end)
end

function benchPress.Init()
    for _, seat in ipairs(CollectionService:GetTagged("BenchPress")) do
        benchPress.Tagged(seat)
    end

    CollectionService:GetInstanceAddedSignal("BenchPress"):Connect(benchPress.Tagged)

    Packets.Upgrades.requestBenchPress.listen(function(data, player)
        benchPress.RequestBenchPress(data, player)
    end)
end

return benchPress
