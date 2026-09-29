local Terrain = workspace.Terrain

local TOTAL_SIZE      = 3000
local ISLAND_RADIUS   = 960
local CENTER_HEIGHT   = 40
local EDGE_HEIGHT     = -40
local WATER_LEVEL     = 0
local SEABED_Y        = -30

local SAND_HEIGHT     = 20

local SEED            = math.random(1, 100000)

local isEnabled = false
if not isEnabled then
	return
end

local NOISE_LAYERS = {
	{ scale = 150, strength = 8 },
	{ scale = 40,  strength = 4 },
	{ scale = 15,  strength = 1 },
}

local RESOLUTION      = 4

local half = TOTAL_SIZE / 2

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function islandHeight(x: number, z: number): number?
	local dist = math.sqrt(x * x + z * z)
	if dist > ISLAND_RADIUS then
		return nil
	end

	local t = 1 - (dist / ISLAND_RADIUS)
	local base = EDGE_HEIGHT + (CENTER_HEIGHT - EDGE_HEIGHT) * smoothstep(t)

	local noise = 0
	for i, layer in ipairs(NOISE_LAYERS) do
		local offset = SEED + i * 137
		noise += math.noise(
			(x / layer.scale) + offset,
			(z / layer.scale) + offset
		) * layer.strength
	end

	return base + noise * t
end

local HALF_RES = RESOLUTION / 2

local function groundMaterial(wy: number): Enum.Material
	if wy <= SAND_HEIGHT then
		return Enum.Material.Sand
	end
	return Enum.Material.Grass
end

local function computeVoxel(wx: number, wy: number, wz: number): (Enum.Material, number)
	local h = islandHeight(wx, wz)
	if h == nil then
		return Enum.Material.Air, 0
	end

	local y0 = wy - HALF_RES
	local y1 = wy + HALF_RES

	if y1 <= h then
		return groundMaterial(wy), 1
	elseif y0 < h then
		if y1 <= WATER_LEVEL then
			return Enum.Material.Sand, 1
		end
		return groundMaterial(wy), math.clamp((h - y0) / RESOLUTION, 0, 1)
	end

	if h < WATER_LEVEL and y0 < WATER_LEVEL then
		if y1 <= WATER_LEVEL then
			return Enum.Material.Water, 1
		end
		return Enum.Material.Water, math.clamp((WATER_LEVEL - y0) / RESOLUTION, 0, 1)
	end

	return Enum.Material.Air, 0
end

local CHUNK = 128

local function generate()
	Terrain:Clear()

	local maxNoise = 0
	for _, layer in ipairs(NOISE_LAYERS) do
		maxNoise += layer.strength
	end

	local maxY = math.max(CENTER_HEIGHT + maxNoise, WATER_LEVEL)
	local air = Enum.Material.Air

	local count = 0
	for cx = -half, half - 1, CHUNK do
		for cz = -half, half - 1, CHUNK do
			local region = Region3.new(
				Vector3.new(cx, SEABED_Y, cz),
				Vector3.new(math.min(cx + CHUNK, half), maxY, math.min(cz + CHUNK, half))
			):ExpandToGrid(RESOLUTION)

			local min = region.CFrame.Position - region.Size / 2
			local nx = math.floor(region.Size.X / RESOLUTION + 0.5)
			local ny = math.floor(region.Size.Y / RESOLUTION + 0.5)
			local nz = math.floor(region.Size.Z / RESOLUTION + 0.5)

			local materials = table.create(nx)
			local occupancies = table.create(nx)

			for ix = 1, nx do
				local matX = table.create(ny)
				local occX = table.create(ny)
				local wx = min.X + (ix - 0.5) * RESOLUTION

				for iy = 1, ny do
					local matY = table.create(nz)
					local occY = table.create(nz)
					local wy = min.Y + (iy - 0.5) * RESOLUTION

					for iz = 1, nz do
						local wz = min.Z + (iz - 0.5) * RESOLUTION
						local mat, occ = computeVoxel(wx, wy, wz)
						if occ <= 0 then
							mat = air
						end
						matY[iz] = mat
						occY[iz] = occ
					end

					matX[iy] = matY
					occX[iy] = occY
				end

				materials[ix] = matX
				occupancies[ix] = occX
			end

			Terrain:WriteVoxels(region, RESOLUTION, materials, occupancies)

			count += 1
			if count % 8 == 0 then
				task.wait()
			end
		end
	end

	print(string.format(
		"[IslandGenerator] Ilha gerada. Raio=%d, centro Y=%d, borda Y=%d, seed=%d",
		ISLAND_RADIUS, CENTER_HEIGHT, EDGE_HEIGHT, SEED
	))
end

generate()
