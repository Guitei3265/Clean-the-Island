local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stats = playerGui:WaitForChild("Stats")
local speedFrame = stats:WaitForChild("Speed")
local totalLabel = speedFrame:WaitForChild("Total") :: TextLabel
local walkSpeedLabel = speedFrame:WaitForChild("WalkSpeed") :: TextLabel

local strengthFrame = stats:WaitForChild("Strength")
local strengthTotalLabel = strengthFrame:WaitForChild("Total") :: TextLabel
local strengthCapacityLabel = strengthFrame:WaitForChild("Capacity") :: TextLabel

local upgradeSound = game:GetService("SoundService"):WaitForChild("Upgrade") :: Sound

local growthFactor = 1.1

local function GetBuff(x: number)
    local buff = math.log(1 + (x * (growthFactor - 1) / 20)) / math.log(growthFactor)
    return math.floor(buff)
end

local previousBuff = GetBuff(0)
local previousStrengthBuff = GetBuff(0)

Packets.Upgrades.updateSpeed.listen(function(data)
    --print(`Speed gained: {data.gained}`)

    totalLabel.Text = tostring(data.total)

    local buff = GetBuff(data.total)
    walkSpeedLabel.Text = "Walk Speed: "..tostring(16 + buff)

    if buff > previousBuff then
        upgradeSound:Play()
    end

    previousBuff = buff
end)

Packets.Upgrades.updateStrength.listen(function(data)
    --print(`Strength gained: {data.gained}`)

    strengthTotalLabel.Text = tostring(data.total)

    local buff = GetBuff(data.total)
    strengthCapacityLabel.Text = "Capacity: "..tostring(buff + 1)

    if buff > previousStrengthBuff then
        upgradeSound:Play()
    end

    previousStrengthBuff = buff
end)

Packets.Upgrades.request.send()
