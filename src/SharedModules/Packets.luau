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

            updateSpeed = ByteNet.definePacket({
                value = ByteNet.struct({
                    total = ByteNet.int32,
                    gained = ByteNet.int32,
                })
            }),

            updateStrength = ByteNet.definePacket({
                value = ByteNet.struct({
                    total = ByteNet.int32,
                    gained = ByteNet.int32,
                })
            }),

            requestBenchPress = ByteNet.definePacket({
                value = ByteNet.struct({
                    seat = ByteNet.inst,
                })
            }),
        }
    end),

    Economy = ByteNet.defineNamespace("Economy", function()
        return {
            sellTrash = ByteNet.definePacket({
                value = ByteNet.nothing
            }),

            gotCash = ByteNet.definePacket({
                value = ByteNet.struct({
                    amount = ByteNet.float64,
                })
            }),
        }
    end),

    Game = ByteNet.defineNamespace("Game", function()
        return {
            gotTrash = ByteNet.definePacket({
                value = ByteNet.struct({
                    rootPart = ByteNet.inst,
                })
            }),

            trashGrabbed = ByteNet.definePacket({
                value = ByteNet.nothing
            }),
        }
    end),

    Robux = ByteNet.defineNamespace("Robux", function()
        return {
            Gamepass = ByteNet.definePacket({
                value = ByteNet.struct({
                    id = ByteNet.float64,
                })
            }),

            Product = ByteNet.definePacket({
                value = ByteNet.struct({
                    id = ByteNet.float64,
                })
            }),
        }
    end),

    Gui = ByteNet.defineNamespace("Gui", function()
        return {
            requestMultipliers = ByteNet.definePacket({
                value = ByteNet.nothing
            }),

            speedMultiplierUpdate = ByteNet.definePacket({
                value = ByteNet.struct({
                    multiplier = ByteNet.int32,
                })
            }),

            strengthMultiplierUpdate = ByteNet.definePacket({
                value = ByteNet.struct({
                    multiplier = ByteNet.int32,
                })
            }),
        }
    end)
}

return packets
