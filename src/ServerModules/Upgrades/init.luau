local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local DataManager = require(game.ServerStorage.ServerModules.DataManager)
local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)
local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local upgrades = {}

local growthFactor = 1.06

local speedRemainders: {[Player]: number} = {}
local strengthRemainders: {[Player]: number} = {}
local gamepassPromptDebounce: {[Player]: number} = {}

local GAMEPASS_PROMPT_DEBOUNCE = 1

local Treadmills = {
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

function upgrades.Walked(player: Player, multiplier: number?)
    local profile = DataManager.WaitForProfile(player)

    local raw = (profile.SpeedMultiplier * profile.SpeedMultiplierProduct * (multiplier or 1)) + (speedRemainders[player] or 0)
    local gained = math.floor(raw)

    speedRemainders[player] = raw - gained

    if gained > 0 then
        DataManager.IncreaseSpeed(player, gained)
    end
end

function upgrades.Strengthed(player: Player)
    local profile = DataManager.WaitForProfile(player)

    local raw = (profile.StrengthMultiplier * profile.StrengthMultiplierProduct) + (strengthRemainders[player] or 0)
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
            timer += deltaTime

            if timer > 0.25 then
                timer -= 0.25

                local treadmill = upgrades.GetTreadmill(humanoidRootPart)
                local category = treadmill and treadmill:GetAttribute("Category")
                local treadmillInfo = treadmill and Treadmills[category]
                local treadmillData = treadmillInfo

                if treadmillData and DataMethods.ReturnKey(player, "Islands") < treadmillData.Island then
                    local unlockedGyms = DataMethods.ReturnKey(player, "UnlockedGyms")

                    if table.find(unlockedGyms, category) == nil then
                        treadmillData = nil

                        local now = os.clock()
                        if now - (gamepassPromptDebounce[player] or 0) >= GAMEPASS_PROMPT_DEBOUNCE then
                            gamepassPromptDebounce[player] = now
                            Packets.Robux.Gamepass.sendTo({id = treadmillInfo.GamepassId}, player)
                        end
                    end
                end

                if humanoid.MoveDirection.Magnitude > 0 or treadmillData then
                    upgrades.Walked(player, treadmillData and treadmillData.Multiplier)
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
    Players.PlayerAdded:Connect(upgrades.PlayerAdded)

    Players.PlayerRemoving:Connect(function(player: Player)
        speedRemainders[player] = nil
        strengthRemainders[player] = nil
        gamepassPromptDebounce[player] = nil
    end)

    Packets.Upgrades.request.listen(function(_, player)
        upgrades.Request(player)
    end)
end

return upgrades
