local SoundService = game:GetService("SoundService")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local cashSound = SoundService:WaitForChild("Cash") :: Sound

Packets.Economy.gotCash.listen(function(data)
    if data.amount > 0 then
        cashSound:Play()
    end
    --print("Got cash: "..data.amount)
end)
