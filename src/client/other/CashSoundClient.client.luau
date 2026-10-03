local SoundService = game:GetService("SoundService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local cashSound = SoundService:WaitForChild("Cash") :: Sound

Packets.Economy.gotCash.listen(function(data)
    cashSound:Play()
    --print("Got cash: "..data.amount)
end)
