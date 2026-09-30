--Feito com IA
local GamepassService = {}

local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Packets = require(game.ReplicatedStorage.SharedModules.Packets)
local DataMethods = require(game.ServerStorage.ServerModules.DataManager.DataMethods)

local studioByPass = false
local studioRemoving = false

local PURCHASE_ID_CACHE_SIZE = 100

local connections: {[Player]: {[string]: RBXScriptConnection}} = {}

type GamepassConfig = {
	id: number,
	onEquip: (player: Player) -> (),
	onUnequip: ((player: Player) -> ())?,
}

local gamepasses: { [string]: GamepassConfig } = {
	--[[["Double Coins"] = {
		id = 1962132742,
		onEquip = function(player: Player)
			DataMethods.WaitForProfile(player)
			DataMethods.SetKey(player, "DoubleCoins", true)
		end,
		onUnequip = function(player: Player)
			DataMethods.WaitForProfile(player)
			DataMethods.SetKey(player, "DoubleCoins", false)
		end,
	},]]
}

local products = {
	[3715524573] = { --1.5x Speed
		onBuy = function(plr: Player)
			DataMethods.WaitForProfile(plr)
			DataMethods.SetKey(plr, "SpeedMultiplierProduct", math.max(DataMethods.ReturnKey(plr, "SpeedMultiplierProduct"), 1.5))
			Packets.Gui.speedMultiplierUpdate.sendTo({multiplier = DataMethods.ReturnKey(plr, "SpeedMultiplierProduct") * 10}, plr)
		end
	},
	[3715524776] = { --2x Speed
		onBuy = function(plr: Player)
			DataMethods.WaitForProfile(plr)
			DataMethods.SetKey(plr, "SpeedMultiplierProduct", math.max(DataMethods.ReturnKey(plr, "SpeedMultiplierProduct"), 2))
			Packets.Gui.speedMultiplierUpdate.sendTo({multiplier = DataMethods.ReturnKey(plr, "SpeedMultiplierProduct") * 10}, plr)
		end
	},
	[3715524820] = { --3x Speed
		onBuy = function(plr: Player)
			DataMethods.WaitForProfile(plr)
			DataMethods.SetKey(plr, "SpeedMultiplierProduct", math.max(DataMethods.ReturnKey(plr, "SpeedMultiplierProduct"), 3))
			Packets.Gui.speedMultiplierUpdate.sendTo({multiplier = DataMethods.ReturnKey(plr, "SpeedMultiplierProduct") * 10}, plr)
		end
	},
	[3715626326] = { --1.5x Strength
		onBuy = function(plr: Player)
			DataMethods.WaitForProfile(plr)
			DataMethods.SetKey(plr, "StrengthMultiplierProduct", math.max(DataMethods.ReturnKey(plr, "StrengthMultiplierProduct"), 1.5))
			Packets.Gui.strengthMultiplierUpdate.sendTo({multiplier = DataMethods.ReturnKey(plr, "StrengthMultiplierProduct") * 10}, plr)
		end
	},
	[3715626362] = { --2x Strength
		onBuy = function(plr: Player)
			DataMethods.WaitForProfile(plr)
			DataMethods.SetKey(plr, "StrengthMultiplierProduct", math.max(DataMethods.ReturnKey(plr, "StrengthMultiplierProduct"), 2))
			Packets.Gui.strengthMultiplierUpdate.sendTo({multiplier = DataMethods.ReturnKey(plr, "StrengthMultiplierProduct") * 10}, plr)
		end
	},
	[3715626386] = { --3x Strength
		onBuy = function(plr: Player)
			DataMethods.WaitForProfile(plr)
			DataMethods.SetKey(plr, "StrengthMultiplierProduct", math.max(DataMethods.ReturnKey(plr, "StrengthMultiplierProduct"), 3))
			Packets.Gui.strengthMultiplierUpdate.sendTo({multiplier = DataMethods.ReturnKey(plr, "StrengthMultiplierProduct") * 10}, plr)
		end
	},
}

local activeGamepasses: { [Player]: { [string]: boolean } } = {}

local function playerOwnsGamepass(player: Player, gamepassId: number): boolean
	if studioByPass and RunService:IsStudio() then return true end

	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	return success and result
end

local function applyGamepass(player: Player, name: string, config: GamepassConfig)
	if not activeGamepasses[player] then
		activeGamepasses[player] = {}
	end

	if activeGamepasses[player][name] then return end

	activeGamepasses[player][name] = true

	local applyOnSpawn
	applyOnSpawn = function(character: Model)
		character:WaitForChild("HumanoidRootPart")
		task.defer(config.onEquip, player)
	end

	connections[player] = connections[player] or {}
	connections[player][name] = player.CharacterAdded:Connect(applyOnSpawn)
	
	if player.Character then
		task.defer(config.onEquip, player)
	end
end

local function removeGamepass(player: Player, name: string, config: GamepassConfig)
	if not activeGamepasses[player] or not activeGamepasses[player][name] then return end

	activeGamepasses[player][name] = false

	if connections[player] and connections[player][name] then
		connections[player][name]:Disconnect()
		connections[player][name] = nil
	end

	if config.onUnequip then
		config.onUnequip(player)
	end
end

local function loadGamepassesForPlayer(player: Player)
	for name, config in pairs(gamepasses) do
		if playerOwnsGamepass(player, config.id) then
			if studioRemoving then
				removeGamepass(player, name, config)
				continue
			end

			applyGamepass(player, name, config)
		end
	end
end

local function onPromptGamepassPurchaseFinished(player: Player, gamepassId: number, purchased: boolean)
	if not purchased then return end

	for name, config in pairs(gamepasses) do
		if config.id == gamepassId then
			applyGamepass(player, name, config)
			break
		end
	end
end

local function isPurchaseSaved(profile, purchaseId: string): boolean
	local savedCache = profile.LastSavedData.PurchaseIdCache
	return if savedCache ~= nil then table.find(savedCache, purchaseId) ~= nil else false
end

--Só devolve PurchaseGranted depois que o PurchaseId estiver confirmado no DataStore.
--O cache de PurchaseId evita entregar duas vezes caso a Roblox reenvie o mesmo recibo.
local function purchaseIdCheckAsync(profile, purchaseId: string, grantProduct: () -> ()): Enum.ProductPurchaseDecision
	if profile:IsActive() ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseIdCache = profile.Data.PurchaseIdCache

	if purchaseIdCache == nil then
		purchaseIdCache = {}
		profile.Data.PurchaseIdCache = purchaseIdCache
	end

	if table.find(purchaseIdCache, purchaseId) == nil then
		local success, result = pcall(grantProduct)
		if not success then
			warn("Failed to process receipt:", profile.Key, purchaseId, result)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		while #purchaseIdCache >= PURCHASE_ID_CACHE_SIZE do
			table.remove(purchaseIdCache, 1)
		end

		table.insert(purchaseIdCache, purchaseId)
	end

	if isPurchaseSaved(profile, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	while profile:IsActive() == true do
		local lastSavedData = profile.LastSavedData

		profile:Save()

		if profile.LastSavedData == lastSavedData then
			local onAfterSave = profile.OnAfterSave :: any
			onAfterSave:Wait()
		end

		if isPurchaseSaved(profile, purchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if profile:IsActive() == true then
			task.wait(10)
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function onPromptProductPurchaseFinished(receiptInfo)
	local plr = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not plr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local product = products[receiptInfo.ProductId]
	if not product then
		warn("NO PRODUCT!", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = DataMethods.WaitForProfileObject(plr)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return purchaseIdCheckAsync(profile, receiptInfo.PurchaseId, function()
		product.onBuy(plr)
	end)
end

local function onPlayerRemoving(player: Player)
	activeGamepasses[player] = nil
	
	if connections[player] then
		for name, connection in pairs(connections[player]) do
			connection:Disconnect()
			connections[player][name] = nil
		end

		connections[player] = nil
	end
end

function GamepassService.registerGamepass(name: string, config: GamepassConfig)
	assert(type(name) == "string" and #name > 0, "Gamepass name must be a non-empty string")
	assert(type(config.id) == "number", "Gamepass id must be a number")
	assert(type(config.onEquip) == "function", "Gamepass onEquip must be a function")
	gamepasses[name] = config
end

function GamepassService.revokeGamepass(player: Player, name: string)
	local config = gamepasses[name]
	if config then
		removeGamepass(player, name, config)
	end
end

function GamepassService.playerHasGamepass(player: Player, name: string): boolean
	return activeGamepasses[player] ~= nil and activeGamepasses[player][name] == true
end

function GamepassService.promptPurchase(player: Player, name: string)
	local config = gamepasses[name]
	if not config then return end
	MarketplaceService:PromptGamePassPurchase(player, config.id)
end

function GamepassService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadGamepassesForPlayer, player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(loadGamepassesForPlayer, player)
	end)

	Players.PlayerRemoving:Connect(onPlayerRemoving)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPromptGamepassPurchaseFinished)

	MarketplaceService.ProcessReceipt = onPromptProductPurchaseFinished
end

return GamepassService
