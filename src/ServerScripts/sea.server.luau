local Players = game:GetService("Players")
local Terrain = workspace.Terrain

local RES = 4
local RAIO = 960                       -- raio do círculo do mar
local CENTRO = Vector3.new(0, 0, 0)    -- centro do círculo (mude se o mar não estiver centrado na origem)
local FUNDO = -64
local TOPO = 200
local FATIA = 128

local function processarFatia(x1, z1, x2, z2, level)
	local region = Region3.new(
		Vector3.new(x1, FUNDO, z1),
		Vector3.new(x2, TOPO, z2)
	):ExpandToGrid(RES)

	local materials, occupancy = Terrain:ReadVoxels(region, RES)
	local size = materials.Size
	local startPos = region.CFrame.Position - region.Size / 2
	local raio2 = RAIO * RAIO

	for x = 1, size.X do
		local worldX = startPos.X + (x - 0.5) * RES - CENTRO.X
		for z = 1, size.Z do
			local worldZ = startPos.Z + (z - 0.5) * RES - CENTRO.Z

			-- só mexe se o voxel estiver dentro do círculo
			if worldX * worldX + worldZ * worldZ <= raio2 then
				for y = 1, size.Y do
					local worldY = startPos.Y + (y - 0.5) * RES
					local mat = materials[x][y][z]
					if worldY <= level then
						if mat == Enum.Material.Air then
							materials[x][y][z] = Enum.Material.Water
							occupancy[x][y][z] = 1
						end
					else
						if mat == Enum.Material.Water then
							materials[x][y][z] = Enum.Material.Air
							occupancy[x][y][z] = 0
						end
					end
				end
			end
		end
	end

	Terrain:WriteVoxels(region, RES, materials, occupancy)
end

local function setSeaLevel(level)
	level = math.clamp(level, FUNDO, TOPO)
	local inicio = -math.ceil(RAIO / FATIA) * FATIA
	local fim = math.ceil(RAIO / FATIA) * FATIA

	for x = inicio, fim - FATIA, FATIA do
		for z = inicio, fim - FATIA, FATIA do
			-- pula fatias totalmente fora do círculo (mais rápido)
			local cx = math.clamp(CENTRO.X, x, x + FATIA)
			local cz = math.clamp(CENTRO.Z, z, z + FATIA)
			local dx, dz = cx - CENTRO.X, cz - CENTRO.Z
			if dx * dx + dz * dz <= RAIO * RAIO then
				processarFatia(x, z, x + FATIA, z + FATIA, level)
				task.wait()
			end
		end
	end
	print("Nível do mar ajustado para", level)
end

-- Chat: /sea 10
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		local valor = msg:match("^/sea%s+(-?%d+%.?%d*)$")
		if valor then
			setSeaLevel(tonumber(valor))
		end
	end)
end)

-- Para testar sem chat, descomente a linha abaixo e dê Play:
--setSeaLevel(5)