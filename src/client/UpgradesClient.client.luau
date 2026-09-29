local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage.SharedModules.Packets)

local strength = 0
local speed = 0

Packets.Upgrades.update.listen(function(data)
    if data.strength > strength then
        print(`Strength increased by {data.strength - strength}`)
        strength = data.strength
    end

    if data.speed > speed then
        print(`Speed increased by {data.speed - speed}`)
        speed = data.speed
    end
end)
