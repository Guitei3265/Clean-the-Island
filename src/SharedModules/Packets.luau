local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(game.ReplicatedStorage.Packages.Bytenet)

local packets = {
    Data = ByteNet.defineNamespace("Economia", function()
        return {
            updateAirResistanceMultiplier = ByteNet.definePacket({
                value = ByteNet.struct({
                    value = ByteNet.float32,
                })
            }),
        }
    end)
}

return packets
