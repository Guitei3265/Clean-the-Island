local character = script.Parent

local benchPressAnim = game.ReplicatedStorage:WaitForChild("Effects"):WaitForChild("BenchPressAnim") :: Animation

local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid
if not humanoid then return end

local animator = humanoid:WaitForChild("Animator", 3) :: Animator
if not animator then return end

local benchPressTrack = animator:LoadAnimation(benchPressAnim)

humanoid.Seated:Connect(function(active: boolean)
    if active then
        print("sentou")
        benchPressTrack:Play()
    else
        print("levantou")
        benchPressTrack:Stop()
    end
end)
