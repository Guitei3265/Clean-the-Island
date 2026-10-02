local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local DataManager = require(game.ServerStorage.ServerModules.DataManager)
local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)
local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local SharedUpgrades = require(game.ReplicatedStorage.SharedModules.Upgrades)

local upgrades = {}

local growthFactor = 1.06

local speedRemainders: {[Player]: number} = {}
local strengthRemainders: {[Player]: number} = {}
local gamepassPromptDebounce: {[Player]: number} = {}

local GAMEPASS_PROMPT_DEBOUNCE = 1

local Stations = {
    [1] = {Multiplier = 1, Island = 0, GamepassId = 0},
    [2] = {Multiplier = 2, Island = 1, GamepassId = 2005844396},
    [3] = {Multiplier = 5, Island = 3, GamepassId = 2006120380},
    [4] = {Multiplier = 15, Island = 10, GamepassId = 2006948393},
}

function upgrades.GetBuff(x: number)
    local buff = math.log(1 + (x * (growthFactor - 1) / 20)) / math.log(growthFactor)
    return math.floor(buff)
end

function upgrades.GetTreadmill(humanoidRootPart: BasePart): BasePart?
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = CollectionService:GetTagged("Treadmill")

    local result = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -5, 0), params)

    return result and (result.Instance :: BasePart)
end

function upgrades.CanUseStation(player: Player, category): boolean
    local info = category and Stations[category]
    if not info then return false end

    if DataMethods.ReturnKey(player, "Islands") >= info.Island then
        return true
    end

    local unlockedGyms = DataMethods.ReturnKey(player, "UnlockedGyms")
    return table.find(unlockedGyms, category) ~= nil
end

function upgrades.GetStationMultiplier(player: Player, category): number?
    local info = category and Stations[category]
    if not info then return nil end

    if not upgrades.CanUseStation(player, category) then
        local now = os.clock()
        if now - (gamepassPromptDebounce[player] or 0) >= GAMEPASS_PROMPT_DEBOUNCE then
            gamepassPromptDebounce[player] = now
            Packets.Robux.Gamepass.sendTo({id = info.GamepassId}, player)
        end

        return nil
    end

    return info.Multiplier
end

function upgrades.Walked(player: Player, multiplier: number?)
    local profile = DataManager.WaitForProfile(player)

    local raw = (profile.SpeedMultiplier * profile.SpeedMultiplierProduct * (multiplier or 1)) + (speedRemainders[player] or 0)
    local gained = math.floor(raw)

    speedRemainders[player] = raw - gained

    if gained > 0 then
        DataManager.IncreaseSpeed(player, gained)
    end
end

function upgrades.Strengthed(player: Player, multiplier: number?)
    local profile = DataManager.WaitForProfile(player)

    local raw = (profile.StrengthMultiplier * profile.StrengthMultiplierProduct * (multiplier or 1)) + (strengthRemainders[player] or 0)
    local gained = math.floor(raw)

    strengthRemainders[player] = raw - gained

    if gained > 0 then
        DataManager.IncreaseStrength(player, gained)
    end
end

function upgrades.PlayerAdded(player: Player)
    local profile = DataManager.WaitForProfile(player)

    local connection: RBXScriptConnection? = nil
    local timer = 0

    local function onCharacterAdded(character: Model)
        if connection then
            connection:Disconnect()
        end

        local humanoid = character:WaitForChild("Humanoid", 3) :: Humanoid
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 3) :: BasePart
        if not (humanoid and humanoidRootPart) then return end

        humanoid.WalkSpeed = 16 + upgrades.GetBuff(profile.Speed)

        connection = RunService.Heartbeat:Connect(function(deltaTime)
            if player.Parent == nil or humanoidRootPart.Parent == nil then
                if connection then
                    connection:Disconnect()
                end
                return
            end

            timer += deltaTime

            if timer > 0.25 then
                timer -= 0.25

                local treadmill = upgrades.GetTreadmill(humanoidRootPart)
                local category = treadmill and treadmill:GetAttribute("Category")
                local multiplier = upgrades.GetStationMultiplier(player, category)

                if humanoid.MoveDirection.Magnitude > 0 or multiplier then
                    upgrades.Walked(player, multiplier)
                end
            end

            humanoid.WalkSpeed = 16 + upgrades.GetBuff(profile.Speed)
        end)
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end

    player.CharacterAdded:Connect(onCharacterAdded)
end

function upgrades.Request(player: Player)
    local profile = DataManager.WaitForProfile(player)

    Packets.Upgrades.updateSpeed.sendTo({total = profile.Speed, gained = 0}, player)
    Packets.Upgrades.updateStrength.sendTo({total = profile.Strength, gained = 0}, player)
end

function upgrades.Init()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(upgrades.PlayerAdded, player)
    end

    Players.PlayerAdded:Connect(upgrades.PlayerAdded)

    Players.PlayerRemoving:Connect(function(player: Player)
        speedRemainders[player] = nil
        strengthRemainders[player] = nil
        gamepassPromptDebounce[player] = nil
    end)

    Packets.Upgrades.request.listen(function(_, player)
        upgrades.Request(player)
    end)

    Packets.Upgrades.requestBulkPickup.listen(function(_, player)
        local nextLevel = DataMethods.ReturnKey(player, "BulkPickup") + 1
        local cost = SharedUpgrades.CalculateCost(nextLevel)

        local cash = DataMethods.ReturnKey(player, "Cash")
        if cash < cost then return end

        DataMethods.SetKey(player, "Cash", cash - cost)
        DataMethods.SetKey(player, "BulkPickup", nextLevel)
    end)

    Packets.Upgrades.requestReach.listen(function(_, player)
        local nextLevel = DataMethods.ReturnKey(player, "Reach") + 1
        local cost = SharedUpgrades.CalculateCost(nextLevel)

        local cash = DataMethods.ReturnKey(player, "Cash")
        if cash < cost then return end

        DataMethods.SetKey(player, "Cash", cash - cost)
        DataMethods.SetKey(player, "Reach", nextLevel)
    end)
end

return upgrades
