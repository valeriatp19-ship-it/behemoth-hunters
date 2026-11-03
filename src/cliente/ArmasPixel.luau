--!nonstrict
-- Construye en 3D las armas dibujadas en pixel art (Compartido > ArteArmas).
-- El servidor solo pone un "mango" invisible en la mano; aquí se arma el arma completa a partir
-- del dibujo, uniendo los píxeles vecinos del mismo color para usar pocas piezas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArteArmas = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ArteArmas"))

local ArmasPixel = {}
local hechos = setmetatable({}, { __mode = "k" })
local rng = Random.new()

local function construir(mango: BasePart)
	if hechos[mango] then
		return
	end
	local arte = ArteArmas.DATOS[mango:GetAttribute("Sprite") or ""]
	if not arte then
		return
	end
	hechos[mango] = true
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Pixel"
	local px, ancX, ancY = arte.pixel, arte.ancla[1], arte.ancla[2]
	local filas = arte.filas
	local H, W = #filas, #filas[1]
	local function letra(x: number, y: number): string
		if y < 1 or y > H or x < 1 or x > W then
			return "."
		end
		return string.sub(filas[y], x, x)
	end
	-- distancia de cada píxel al borde de la figura (8 direcciones)
	local dist = table.create(H)
	local cola = {}
	for y = 1, H do
		dist[y] = table.create(W, 0)
		for x = 1, W do
			if letra(x, y) ~= "." then
				local borde = false
				for dy = -1, 1 do
					for dx = -1, 1 do
						if (dx ~= 0 or dy ~= 0) and letra(x + dx, y + dy) == "." then
							borde = true
						end
					end
				end
				if borde then
					dist[y][x] = 1
					table.insert(cola, { x, y })
				end
			end
		end
	end
	local i = 1
	while i <= #cola do
		local x, y = cola[i][1], cola[i][2]
		i += 1
		for dy = -1, 1 do
			for dx = -1, 1 do
				local nx, ny = x + dx, y + dy
				if letra(nx, ny) ~= "." and dist[ny][nx] == 0 then
					dist[ny][nx] = dist[y][x] + 1
					table.insert(cola, { nx, ny })
				end
			end
		end
	end
	-- grosor de cada píxel: bordes finos, centro grueso (limitado por su color);
	-- lo que brilla sobresale un poco de lo que lo rodea
	local prof = table.create(H)
	for y = 1, H do
		prof[y] = table.create(W, 0)
		for x = 1, W do
			local l = letra(x, y)
			if l ~= "." then
				local c = arte.paleta[l == "@" and "e" or l]
				prof[y][x] = c and math.max(1, math.min(c[4] * 2 - 1, 2 * dist[y][x] - 1)) or 1
			end
		end
	end
	local function grosorDe(x: number, y: number, c): number
		if c[6] == "borde" then
			return 1 -- el borde del arma: una línea fina
		end
		if c[6] == "sale" then -- lo que brilla en el centro (canal, gemas) sobresale un poco
			local vecino = 1
			for dy = -1, 1 do
				for dx = -1, 1 do
					if y + dy >= 1 and y + dy <= H and x + dx >= 1 and x + dx <= W then
						vecino = math.max(vecino, prof[y + dy][x + dx])
					end
				end
			end
			return math.min(vecino + 2, 7)
		end
		return prof[y][x]
	end
	for y = 1, H do
		local x = 1
		while x <= W do
			local l = letra(x, y)
			local c = arte.paleta[l == "@" and "e" or l]
			if l == "." or not c then
				x += 1
			else
				-- une los píxeles seguidos del mismo color y el mismo grosor
				local g = grosorDe(x, y, c)
				local fin = x
				while fin + 1 <= W do
					local l2 = letra(fin + 1, y)
					local c2 = arte.paleta[l2 == "@" and "e" or l2]
					if l2 == "." or c2 ~= c or grosorDe(fin + 1, y, c2) ~= g then
						break
					end
					fin += 1
				end
				local n = fin - x + 1
				local centroCol = (x + fin) / 2 - 1
				local h, v = (centroCol - ancX) * px, (ancY - (y - 1)) * px
				local tam, pos
				if arte.plano == "ZY" then
					tam, pos = Vector3.new(g * px, px, n * px), Vector3.new(0, v, -h)
				else
					tam, pos = Vector3.new(n * px, px, g * px), Vector3.new(h, v, 0)
				end
				local p = Instance.new("Part")
				p.Name = "Pixel"
				p.Anchored = false
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.Massless = true
				p.CastShadow = false
				p.TopSurface = Enum.SurfaceType.Smooth
				p.BottomSurface = Enum.SurfaceType.Smooth
				p.Size = tam
				if c[5] then
					p.Material = Enum.Material.Neon
					p.Color = Color3.fromRGB(c[1], c[2], c[3])
				else
					p.Material = Enum.Material.SmoothPlastic
					local k = 1 + (rng:NextNumber() - 0.5) * 0.1
					p.Color = Color3.fromRGB(math.clamp(c[1] * k, 0, 255), math.clamp(c[2] * k, 0, 255), math.clamp(c[3] * k, 0, 255))
				end
				p.CFrame = mango.CFrame * CFrame.new(pos)
				local w = Instance.new("WeldConstraint")
				w.Part0 = mango
				w.Part1 = p
				w.Parent = p
				p.Parent = carpeta
				x = fin + 1
			end
		end
	end
	carpeta.Parent = mango
	-- las armas de los Behemoths (borde que brilla) sueltan chispas de su color
	local borde = arte.paleta.k
	local ancla = mango:FindFirstChild("EstelaBase")
	if borde and borde[5] and ancla then
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(Color3.fromRGB(borde[1], borde[2], borde[3]))
		e.LightEmission = 1
		e.Rate = 7
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
		e.Lifetime = NumberRange.new(0.4, 0.8)
		e.Speed = NumberRange.new(0.5, 1.5)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Parent = ancla
	end
end

local function revisar(x: Instance)
	if x:IsA("BasePart") and x:GetAttribute("Sprite") then
		-- se espera un instante a que el mango quede en su lugar (soldado a la mano)
		task.delay(0.05, function()
			if x.Parent then
				construir(x)
			end
		end)
	end
end

function ArmasPixel.iniciar()
	for _, x in workspace:GetDescendants() do
		revisar(x)
	end
	workspace.DescendantAdded:Connect(revisar)
end

return ArmasPixel
