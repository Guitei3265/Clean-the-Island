local plr = game.Players.LocalPlayer

local Packets = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packets"))

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

function cutsceneModule.Init()
    Packets.Effects.playCutscene.listen(function(data)
        cutsceneModule.PlayCutscene(data.name)
    end)

    if true then return end
    print("Ready to play Intro")
    task.wait(6)
    cutsceneModule.PlayCutscene("Intro")
end

return cutsceneModule