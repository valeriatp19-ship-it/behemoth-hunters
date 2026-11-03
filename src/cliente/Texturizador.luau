--!nonstrict
-- Textura micro-voxel: cubre las piezas de armas, armaduras y Behemoths con muchos cubitos de
-- tonos distintos (arriba más claros, abajo más oscuros), como un mosaico con relieve.
-- Se arma en la pantalla de cada jugador: el servidor no recibe ni manda ninguna pieza extra.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Texturizador = {}
local camara = workspace.CurrentCamera
local cola = {} -- piezas esperando su textura
local hechas = setmetatable({}, { __mode = "k" }) -- pieza -> carpeta de cubitos
local rng = Random.new()

local AJUSTE = {
	equipo = { tam = 0.2, maximo = 90, ruido = 0.09 },
	behemoth = { tam = 1.0, maximo = 150, ruido = 0.1, desgaste = true },
}

local function sirve(p: BasePart): boolean
	if p.Material == Enum.Material.Neon or p.Material == Enum.Material.ForceField or p.Material == Enum.Material.Glass then
		return false -- lo que brilla o es de vidrio se queda liso (así su luz resalta)
	end
	if p:IsA("WedgePart") or p:IsA("MeshPart") or p:GetAttribute("SinTextura") then
		return false
	end
	if p.Name == "HumanoidRootPart" or p.Name == "Raiz" then
		return false
	end
	local menor = math.min(p.Size.X, p.Size.Y, p.Size.Z)
	return menor >= 0.08 and p.Size.Magnitude >= 0.35
end

local function forma(p: BasePart): string
	local malla = p:FindFirstChildOfClass("SpecialMesh")
	if malla then
		if malla.MeshType == Enum.MeshType.Sphere then
			return "esfera"
		elseif malla.MeshType == Enum.MeshType.Cylinder then
			return "cilindro"
		end
		return "otra"
	end
	if p:IsA("Part") and p.Shape == Enum.PartType.Ball then
		return "esfera"
	elseif p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
		return "cilindro_x"
	end
	return "caja"
end

-- ¿el centro de la celda está dentro de la forma?
local function dentro(f: string, x: number, y: number, z: number): boolean
	if f == "esfera" then
		return x * x + y * y + z * z <= 1
	elseif f == "cilindro" then -- SpecialMesh cilindro: eje Y
		return x * x + z * z <= 1
	elseif f == "cilindro_x" then
		return y * y + z * z <= 1
	end
	return true
end

local function tonoDe(base: Color3, k: number): Color3
	return Color3.new(math.clamp(base.R * k, 0, 1), math.clamp(base.G * k, 0, 1), math.clamp(base.B * k, 0, 1))
end

local function texturizar(p: BasePart, ajuste)
	if hechas[p] or not p.Parent then
		return 0
	end
	local f = forma(p)
	if f == "otra" then
		return 0
	end
	local tam = p.Size + Vector3.new(0.04, 0.04, 0.04) -- apenas por fuera, para tapar la pieza original
	-- tamaño del cubito: si saldrían demasiados, se agrandan un poco
	local lado = ajuste.tam
	local nx, ny, nz
	for _ = 1, 12 do
		nx = math.max(1, math.floor(tam.X / lado + 0.5))
		ny = math.max(1, math.floor(tam.Y / lado + 0.5))
		nz = math.max(1, math.floor(tam.Z / lado + 0.5))
		local total = nx * ny * nz - math.max(0, nx - 2) * math.max(0, ny - 2) * math.max(0, nz - 2)
		if total <= ajuste.maximo then
			break
		end
		lado *= 1.25
	end
	local celda = Vector3.new(tam.X / nx, tam.Y / ny, tam.Z / nz)
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Textura"
	carpeta.Archivable = false
	local creados = 0
	local base = p.Color
	for i = 0, nx - 1 do
		for j = 0, ny - 1 do
			for k = 0, nz - 1 do
				-- posición normalizada de la celda (-1 a 1)
				local ux = nx > 1 and ((i + 0.5) / nx * 2 - 1) or 0
				local uy = ny > 1 and ((j + 0.5) / ny * 2 - 1) or 0
				local uz = nz > 1 and ((k + 0.5) / nz * 2 - 1) or 0
				local borde
				if f == "caja" then
					borde = i == 0 or j == 0 or k == 0 or i == nx - 1 or j == ny - 1 or k == nz - 1
				else
					-- en esferas y cilindros: dentro de la forma pero cerca de su superficie
					local paso = 2.4 / math.max(nx, ny, nz)
					borde = dentro(f, ux, uy, uz) and not dentro(f, ux * (1 + paso), uy * (1 + paso), uz * (1 + paso))
				end
				if borde then
					local tono = 1 + (rng:NextNumber() - 0.5) * 2 * ajuste.ruido
					if j == ny - 1 then
						tono += 0.08 -- arriba más claro
					elseif j == 0 then
						tono -= 0.1 -- abajo más oscuro
					end
					if ajuste.desgaste and rng:NextNumber() < 0.07 then
						tono *= 0.72 -- manchas de desgaste
					end
					local c = Instance.new("Part")
					c.Name = "Cubito"
					c.Anchored = false
					c.CanCollide = false
					c.CanQuery = false
					c.CanTouch = false
					c.Massless = true
					c.CastShadow = false
					c.Material = Enum.Material.SmoothPlastic
					c.TopSurface = Enum.SurfaceType.Smooth
					c.BottomSurface = Enum.SurfaceType.Smooth
					c.Color = tonoDe(base, tono)
					c.Transparency = p.Transparency
					c.Size = celda
					c.CFrame = p.CFrame * CFrame.new((i + 0.5) * celda.X - tam.X / 2, (j + 0.5) * celda.Y - tam.Y / 2, (k + 0.5) * celda.Z - tam.Z / 2)
					local w = Instance.new("WeldConstraint")
					w.Part0 = p
					w.Part1 = c
					w.Parent = c
					c.Parent = carpeta
					creados += 1
				end
			end
		end
	end
	if creados == 0 then
		carpeta:Destroy()
		return 0
	end
	carpeta.Parent = p
	hechas[p] = carpeta
	-- si la pieza se esconde (por ejemplo, al romper una parte), sus cubitos también
	p:GetPropertyChangedSignal("Transparency"):Connect(function()
		for _, c in carpeta:GetChildren() do
			c.Transparency = p.Transparency
		end
	end)
	return creados
end

local function encolar(p: Instance, tipo: string)
	if p:IsA("BasePart") and p.Name ~= "Cubito" and not hechas[p] and sirve(p) then
		table.insert(cola, { p, AJUSTE[tipo] })
	end
end

-- armas y armaduras de un cazador (y lo que se le agregue después)
local function vigilarPersonaje(char: Model)
	for _, nombre in {} do -- armas y armaduras ya son minivoxel (ArmasPixel y ArmadurasPixel)
		local function carpeta(c: Instance)
			if c.Name == nombre then
				for _, d in c:GetDescendants() do
					encolar(d, "equipo")
				end
				c.DescendantAdded:Connect(function(d)
					task.defer(encolar, d, "equipo")
				end)
			end
		end
		local ya = char:FindFirstChild(nombre)
		if ya then
			carpeta(ya)
		end
		char.ChildAdded:Connect(carpeta)
	end
end

-- los Behemoths cercanos se texturizan; a los lejanos se les quita (para cuidar el rendimiento)
local texturizados = setmetatable({}, { __mode = "k" })
local function revisarBehemoths()
	local carpeta = workspace:FindFirstChild("Behemoths")
	if not carpeta then
		return
	end
	local pos = camara.CFrame.Position
	for _, b in carpeta:GetChildren() do
		local raiz = b:IsA("Model") and b.PrimaryPart
		if raiz then
			local d = (raiz.Position - pos).Magnitude
			if d < 700 and not texturizados[b] then
				texturizados[b] = true
				for _, x in b:GetDescendants() do
					encolar(x, "behemoth")
				end
			elseif d > 1000 and texturizados[b] then
				texturizados[b] = nil
				for _, x in b:GetDescendants() do
					if x:IsA("BasePart") and hechas[x] then
						hechas[x]:Destroy()
						hechas[x] = nil
					end
				end
			end
		end
	end
end

function Texturizador.iniciar()
	local function conectar(j: Player)
		j.CharacterAdded:Connect(vigilarPersonaje)
		if j.Character then
			vigilarPersonaje(j.Character)
		end
	end
	Players.PlayerAdded:Connect(conectar)
	for _, j in Players:GetPlayers() do
		conectar(j)
	end
	-- se trabaja un poco en cada cuadro, para que el juego no se trabe
	local tRevision = 0
	RunService.Heartbeat:Connect(function(dt)
		tRevision -= dt
		if tRevision <= 0 then
			tRevision = 2
			revisarBehemoths()
		end
		local presupuesto = 350
		while presupuesto > 0 and #cola > 0 do
			local item = table.remove(cola, 1)
			presupuesto -= math.max(1, texturizar(item[1], item[2]))
		end
	end)
end

return Texturizador
