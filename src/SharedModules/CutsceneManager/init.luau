local plr = game.Players.LocalPlayer

local ContentProvider = game:GetService("ContentProvider")

local Packets = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

local cutscenesFolder = game.ReplicatedStorage:WaitForChild("Cutscenes")

local cutsceneModule = {}

function cutsceneModule.PlayCutscene(cutscene: string)
    local cutsceneModule = script:FindFirstChild(cutscene) :: ModuleScript
    if not cutsceneModule then
        warn("No cutscene \""..tostring(cutscene).."\"")
        return
    end
    cutsceneModule = require(cutsceneModule)

    cutsceneModule.Play(plr.Character)
end

function cutsceneModule.Preload()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    local assets = {}
    for _, inst in ipairs(cutscenesFolder:GetDescendants()) do
        if inst:IsA("Animation") or inst:IsA("Sound") or inst:IsA("Decal") or inst:IsA("Texture") or inst:IsA("MeshPart") then
            table.insert(assets, inst)
        end
    end
    ContentProvider:PreloadAsync(assets)

    if not plr.Character then
        plr.CharacterAdded:Wait()
    end

    task.wait()
end

function cutsceneModule.Init()
    Packets.Effects.playCutscene.listen(function(data)
        cutsceneModule.PlayCutscene(data.name)
    end)

    cutsceneModule.Preload()

    Packets.Game.requestTutorial.send()
end

return cutsceneModule