local sessionData = require(script.Parent.Profiles :: ModuleScript)
local Packets = require(game.ReplicatedStorage.SharedModules.Packets)

local dataMethods = {}
dataMethods.__index = dataMethods

function dataMethods.WaitForProfile(plr: Player)
	local Time = 20
	local profile = nil

	while not profile and Time > 0 do
		profile = dataMethods.Return(plr)

		if not profile then
			Time -= 0.1
			task.wait(0.1)
		end
	end

	return profile
end

--Retorna o profile em si (e não o .Data), necessário para :IsActive(), :Save() e .LastSavedData
function dataMethods.WaitForProfileObject(plr: Player)
	local Time = 10
	local profile = sessionData[plr]

	while not profile and Time > 0 do
		Time -= 0.1
		task.wait(0.1)

		profile = sessionData[plr]
	end

	return profile or false
end

function dataMethods.Return(plr: Player)
	local profile = sessionData[plr]
	
	if not profile then return nil end

	return profile.Data
end

function dataMethods.IncreaseSpeed(plr: Player, gained: number)
	local profile = sessionData[plr]
	
	profile.Data.Speed += gained

	Packets.Upgrades.updateSpeed.sendTo({total = profile.Data.Speed, gained = gained}, plr)
end

function dataMethods.IncreaseStrength(plr: Player, gained: number)
	local profile = sessionData[plr]

	profile.Data.Strength += gained

	Packets.Upgrades.updateStrength.sendTo({total = profile.Data.Strength, gained = gained}, plr)
end

function dataMethods.GotCash(plr: Player, amount: number)
	local profile = sessionData[plr]

	profile.Data.Cash += amount

	Packets.Economy.gotCash.sendTo({amount = amount}, plr)
	Packets.Economy.updateCash.sendTo({total = profile.Data.Cash}, plr)
end

function dataMethods.ReturnKey(plr: Player, key: string)
	return sessionData[plr].Data[key]
end

function dataMethods.SetKey(plr: Player, key: string, value)
	sessionData[plr].Data[key] = value
end

return dataMethods
