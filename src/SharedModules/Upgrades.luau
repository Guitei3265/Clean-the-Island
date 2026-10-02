local Upgrades = {}

function Upgrades.CalculateCost(x: number): number
    return 50 * 1.12 ^ (x - 1)
end

return Upgrades
