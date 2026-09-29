local ByteNet = require(game.ReplicatedStorage.Packages.Bytenet)

local packets = {
    Example = ByteNet.defineNamespace("Example", function()
        return {
            example = ByteNet.definePacket({
                value = ByteNet.struct({
                    value = ByteNet.float32,
                })
            }),
        }
    end),

    Upgrades = ByteNet.defineNamespace("Upgrades", function()
        return {
            request = ByteNet.definePacket({
                value = ByteNet.nothing
            }),

            update = ByteNet.definePacket({
                value = ByteNet.struct({
                    strength = ByteNet.int32,
                    speed = ByteNet.int32,
                })
            }),
        }
    end)
}

return packets
