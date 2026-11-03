--!nonstrict
-- Construye el Mar de Dunas: terreno, oasis, pirámides, obeliscos, rocas, palmeras y campamento.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)

local S = Config.S
local C = Config.COLORES
local Mundo = {}
local carpeta: Folder

-- Un tono levemente más claro u oscuro, para que cada bloque se note (textura voxel).
local rngMatiz = Random.new(7)
local function matiz(c: Color3, fuerza: number?): Color3
	local k = 1 + (rngMatiz:NextNumber() - 0.5) * 2 * (fuerza or 0.07)
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

local function parte(props: { [string]: any }): BasePart
	local p = Instance.new(props.Clase or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.CastShadow = true
	for k, v in props do
		if k ~= "Clase" and k ~= "Material" and k ~= "Malla" then
			p[k] = v
		end
	end
	if props.Malla then
		local m = Instance.new("SpecialMesh")
		m.MeshType = props.Malla
		m.Parent = p
	end
	if not props.Parent and not carpeta then
		-- en el Lobby no se construye el desierto: las piezas van a una carpeta propia
		local nueva = Instance.new("Folder")
		nueva.Name = "Construcciones"
		nueva.Parent = workspace
		carpeta = nueva
	end
	p.Parent = props.Parent or carpeta
	return p
end
Mundo.parte = parte

-- ---------- terreno de bloques (estilo voxel) ----------
-- Cada columna es un cubo de 4 studs; las columnas vecinas con la misma altura y color
-- se juntan en un solo bloque grande para que Roblox tenga pocas piezas.
local function crearTerreno()
	workspace.Terrain:Clear()
	local V = Config.VOX
	local N = 228
	local ORIGEN = -N * V / 2
	local BASE = -32
	local oasis = Config.OASIS * S
	local nivelAgua = -V
	local ARENA = { Color3.fromRGB(228, 186, 120), Color3.fromRGB(214, 170, 104), Color3.fromRGB(236, 198, 136) }
	local CESPED = { Color3.fromRGB(112, 172, 82), Color3.fromRGB(96, 156, 70) }
	local alto, clave, colores = {}, {}, {}
	for i = 1, N do
		alto[i], clave[i], colores[i] = {}, {}, {}
		for k = 1, N do
			local x = ORIGEN + (i - 0.5) * V
			local z = ORIGEN + (k - 0.5) * V
			local h = Config.altura(x, z)
			local dOasis = (Vector2.new(x, z) - oasis).Magnitude / S
			local nivel = h // V
			local tipo, color
			if dOasis < Config.OASIS_RADIO + 5 then
				tipo = "c" .. (nivel % 2 + 1)
				color = CESPED[nivel % 2 + 1]
			else
				tipo = "a" .. (nivel % 3 + 1)
				color = ARENA[nivel % 3 + 1]
			end
			alto[i][k] = h
			clave[i][k] = h .. tipo
			colores[i][k] = color
		end
	end
	local usado = {}
	for i = 1, N do
		usado[i] = {}
	end
	local piezas = 0
	for k = 1, N do
		for i = 1, N do
			if not usado[i][k] then
				local c = clave[i][k]
				local ancho = 1
				while i + ancho <= N and not usado[i + ancho][k] and clave[i + ancho][k] == c do
					ancho += 1
				end
				local largo = 1
				local sigue = true
				while sigue and k + largo <= N do
					for ii = i, i + ancho - 1 do
						if usado[ii][k + largo] or clave[ii][k + largo] ~= c then
							sigue = false
							break
						end
					end
					if sigue then
						largo += 1
					end
				end
				for ii = i, i + ancho - 1 do
					for kk = k, k + largo - 1 do
						usado[ii][kk] = true
					end
				end
				local h = alto[i][k]
				local color = colores[i][k]
				local centroX = ORIGEN + (i - 1 + ancho / 2) * V
				local centroZ = ORIGEN + (k - 1 + largo / 2) * V
				parte({ Name = "Suelo", Size = Vector3.new(ancho * V, h - BASE, largo * V), Position = Vector3.new(centroX, (h + BASE) / 2, centroZ), Color = matiz(color) })
				piezas += 1
				if h < nivelAgua and (Vector2.new(centroX, centroZ) - oasis).Magnitude < (Config.OASIS_RADIO + 4) * S then
					parte({ Name = "Agua", Size = Vector3.new(ancho * V, nivelAgua - h, largo * V), Position = Vector3.new(centroX, (nivelAgua + h) / 2, centroZ), Color = Color3.fromRGB(50, 175, 190), Transparency = 0.35, CanCollide = false })
				end
			end
		end
	end
	print(("Mar de Dunas: %d bloques de terreno"):format(piezas))
end

-- ---------- construcciones ----------
local function piramide(xm: number, zm: number, tam: number)
	local V = Config.VOX
	local base = Config.suelo(xm, zm, -V)
	local capas = math.floor(tam * S / (2 * V))
	local tonos = { C.piedra, Color3.fromRGB(200, 164, 110) }
	for i = 0, capas - 1 do
		local ancho = (capas - i) * 2 * V
		parte({ Name = "Piramide", Size = Vector3.new(ancho, V, ancho), Position = base + Vector3.new(0, (i + 0.5) * V, 0), Color = tonos[i % 2 + 1] })
	end
	parte({ Name = "Punta", Size = Vector3.new(V, V, V), Position = base + Vector3.new(0, (capas + 0.5) * V, 0), Color = C.oro, Material = Enum.Material.Neon })
end

local function obelisco(xm: number, zm: number, alto: number)
	local base = Config.suelo(xm, zm, -0.3 * S)
	local ancho = 1.5 * S
	local tramos = 3
	for i = 0, tramos - 1 do
		local a = ancho * (1 - i * 0.12)
		local h = alto * S / tramos
		parte({ Name = "Obelisco", Size = Vector3.new(a, h, a), Position = base + Vector3.new(0, (i + 0.5) * h, 0), Color = i % 2 == 0 and C.piedra or Color3.fromRGB(200, 164, 110) })
	end
	parte({ Name = "Punta", Size = Vector3.new(ancho * 0.5, ancho * 0.5, ancho * 0.5), Position = base + Vector3.new(0, alto * S + ancho * 0.25, 0), Color = C.oro, Material = Enum.Material.Neon })
	for i = 1, 4 do
		for lado = 0, 3 do
			parte({ Name = "Jeroglifico", Size = Vector3.new(0.8, 0.8, 0.2), CFrame = CFrame.new(base + Vector3.new(0, alto * S * (0.25 + i * 0.13), 0)) * CFrame.Angles(0, lado * math.pi / 2, 0) * CFrame.new((i % 2) * 0.6 - 0.3, 0, -ancho * 0.45), Color = C.turquesa, Material = Enum.Material.Neon, CanCollide = false })
		end
	end
end

local function palmera(xm: number, zm: number, alto: number, rng: Random)
	local base = Config.suelo(xm, zm, -0.2 * S)
	local inclina = rng:NextNumber(-0.25, 0.25)
	local tramos = 6
	local pos = base
	local desvio = 0
	for i = 1, tramos do
		local h = alto * S / tramos
		desvio += inclina * 0.8
		local grosor = 1.6 - i * 0.1
		parte({ Name = "Tronco", Size = Vector3.new(grosor, h, grosor), Position = pos + Vector3.new(desvio, (i - 0.5) * h, 0), Color = i % 2 == 0 and Color3.fromRGB(140, 100, 60) or Color3.fromRGB(120, 84, 50) })
	end
	local copa = pos + Vector3.new(desvio, alto * S, 0)
	parte({ Name = "Copa", Size = Vector3.new(2.4, 1.6, 2.4), Position = copa, Color = Color3.fromRGB(80, 150, 64), CanCollide = false })
	for i = 0, 3 do
		local dir = CFrame.Angles(0, i * math.pi / 2 + 0.3, 0)
		for k = 1, 3 do
			local p = (CFrame.new(copa) * dir * CFrame.new(0, -k * 0.7 + 0.3, -1.2 - k * 1.6)).Position
			parte({ Name = "Hoja", Size = Vector3.new(1.6, 0.8, 1.8), CFrame = CFrame.new(p) * dir, Color = k % 2 == 0 and Color3.fromRGB(90, 164, 72) or Color3.fromRGB(70, 140, 58), CanCollide = false })
		end
	end
end

local function campamento(): SpawnLocation
	local c = Config.CAMPAMENTO
	local centro = Config.suelo(c.X, c.Y)
	local fogata = parte({ Name = "Fogata", Size = Vector3.new(2.4, 0.8, 2.4), Position = centro + Vector3.new(0, 0.4, 0), Color = Color3.fromRGB(70, 60, 55) })
	parte({ Name = "Brasas", Size = Vector3.new(1.4, 1.0, 1.4), Position = centro + Vector3.new(0, 1.0, 0), Color = Color3.fromRGB(255, 140, 50), Material = Enum.Material.Neon, CanCollide = false })
	local fuego = Instance.new("Fire")
	fuego.Size = 7
	fuego.Heat = 9
	fuego.Parent = fogata
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 170, 90)
	luz.Range = 30
	luz.Brightness = 2
	luz.Parent = fogata
	for i = 1, 3 do
		parte({ Name = "Tronco", Size = Vector3.new(3.2, 0.6, 0.6), CFrame = CFrame.new(centro + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, i * math.pi / 2, 0), Color = Color3.fromRGB(110, 75, 45) })
	end
	for lado = -1, 1, 2 do
		local base = centro + Vector3.new(lado * 18, 0, -6)
		for nivel = 0, 3 do
			parte({ Name = "Tienda", Size = Vector3.new(9, 1.8, 9 - nivel * 2.2), Position = base + Vector3.new(0, 0.9 + nivel * 1.8, 0), Color = nivel % 2 == 0 and C.lino or Color3.fromRGB(196, 58, 46) })
		end
	end
	for i = 1, 4 do
		parte({ Name = "Caja", Size = Vector3.new(2.5, 2.5, 2.5), Position = centro + Vector3.new(-10 + i * 5, 1.25, 12), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks })
	end
	local caravana = parte({ Name = "Caravana", Size = Vector3.new(3, 3, 6), Position = centro + Vector3.new(-10, 1.5, -12), Color = Color3.fromRGB(200, 150, 90) })
	parte({ Name = "Caravana", Size = Vector3.new(3.2, 1, 3), Position = centro + Vector3.new(-10, 3.4, -11), Color = C.rojo })
	local volver = Instance.new("ProximityPrompt")
	volver.Name = "VolverRefugio"
	volver.ActionText = "Volver al Refugio"
	volver.ObjectText = "Caravana"
	volver.MaxActivationDistance = 12
	volver.RequiresLineOfSight = false
	volver.GamepadKeyCode = Enum.KeyCode.ButtonL1 -- X es el ataque en la cacería
	volver.Parent = caravana
	local aparicion = Instance.new("SpawnLocation")
	aparicion.Name = "Campamento"
	aparicion.Anchored = true
	aparicion.Neutral = true
	aparicion.Size = Vector3.new(12, 1, 12)
	aparicion.Transparency = 1
	aparicion.CanCollide = false
	aparicion.Position = centro + Vector3.new(0, 0.5, 12)
	aparicion.Duration = 0
	aparicion.Parent = carpeta
	return aparicion
end

function Mundo.construir()
	carpeta = Instance.new("Folder")
	carpeta.Name = "MarDeDunas"
	carpeta.Parent = workspace
	crearTerreno()
	for _, p in Config.PIRAMIDES do
		piramide(p.x, p.z, p.tam)
	end
	for _, o in Config.OBELISCOS do
		obelisco(o[1], o[2], o[3])
	end
	local rng = Random.new(7)
	for _ = 1, 28 do
		local x, z = rng:NextNumber(-130, 130), rng:NextNumber(-130, 110)
		local lejos = (Vector2.new(x, z) - Config.OASIS).Magnitude > Config.OASIS_RADIO + 6 and (Vector2.new(x, z) - Config.CAMPAMENTO).Magnitude > 20
		for _, p in Config.PIRAMIDES do
			if (Vector2.new(x, z) - Vector2.new(p.x, p.z)).Magnitude < p.tam * 0.75 then
				lejos = false
			end
		end
		if lejos then
			local tam = rng:NextNumber(1.5, 4.5) * S
			local base = Config.suelo(x, z)
			parte({ Name = "Roca", Size = Vector3.new(tam * 1.3, tam * 0.6, tam), Position = base + Vector3.new(0, tam * 0.3, 0), Color = Color3.fromRGB(196, 150, 100) })
			parte({ Name = "Roca", Size = Vector3.new(tam * 0.8, tam * 0.5, tam * 0.7), Position = base + Vector3.new(tam * 0.15, tam * 0.85, -tam * 0.1), Color = Color3.fromRGB(176, 132, 88) })
		end
	end
	for i = 1, 9 do
		local ang = i / 9 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local d = Config.OASIS_RADIO + rng:NextNumber(1, 5)
		palmera(Config.OASIS.X + math.cos(ang) * d, Config.OASIS.Y + math.sin(ang) * d, rng:NextNumber(6, 9), rng)
	end
	local aparicion = campamento()
	-- la luz y el cielo los pone cada jugador según dónde está (cliente > Ambiente)
	return aparicion
end

-- Cielo del atardecer cuando despierta el guardián: solo lo ven los que están en el desierto
function Mundo.cieloGuardian(activo: boolean)
	workspace:SetAttribute("CieloGuardian", activo)
end

Mundo.matiz = matiz

return Mundo
