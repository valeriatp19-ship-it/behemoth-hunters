--!nonstrict
-- Construye las armaduras en minivoxel (Compartido > ArteArmaduras) sobre el cuerpo de cada cazador.
-- El servidor solo marca qué piezas lleva cada uno (atributos "Lleva_<pieza>"). Tu propio cazador
-- siempre se ve con todo el detalle; los demás, solo cuando están cerca (para cuidar el rendimiento).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArteArmaduras = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ArteArmaduras"))
local Armas = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Armas"))

local ArmadurasPixel = {}
local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera
local CERCA, LEJOS = 120, 160
local puestas = setmetatable({}, { __mode = "k" }) -- personaje -> { pieza -> carpeta }

local function construirPieza(char: Model, id: string): Folder?
	local datos = ArteArmaduras.DATOS[id]
	if not datos then
		return nil
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Armadura_" .. id
	for _, b in datos.bloques do
		local parte = char:FindFirstChild(ArteArmaduras.PARTES[b[1]]) :: BasePart?
		if parte then
			local c = datos.colores[b[8]]
			local p = Instance.new("Part")
			p.Name = "Cubito"
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.Material = c[4] and Enum.Material.Neon or Enum.Material.SmoothPlastic
			p.Color = Color3.fromRGB(c[1], c[2], c[3])
			p.Size = Vector3.new(b[5], b[6], b[7])
			p.CFrame = parte.CFrame * CFrame.new(b[2], b[3], b[4])
			local w = Instance.new("WeldConstraint")
			w.Part0 = parte
			w.Part1 = p
			w.Parent = p
			p.Parent = carpeta
		end
	end
	carpeta.Parent = char
	return carpeta
end

-- Aura del set completo (las 4 piezas del mismo set): partículas alrededor del cazador
local AURAS = {
	guardian = { { Color3.fromRGB(255, 210, 80), 6, 0.25, 1.2, 3 }, { Color3.fromRGB(230, 190, 120), 14, 0.5, 1.4, 1.2 } }, -- chispas doradas y arena
	rodador = { { Color3.fromRGB(255, 110, 30), 12, 0.3, 1.0, 5 }, { Color3.fromRGB(255, 200, 80), 5, 0.2, 0.8, 7 } }, -- brasas
	eclipse = { { Color3.fromRGB(170, 70, 255), 10, 0.9, 1.6, 1.5 }, { Color3.fromRGB(230, 160, 255), 4, 0.2, 1.0, 3 } }, -- humo de sombra
	apu = { { Color3.fromRGB(120, 220, 255), 6, 0.25, 1.2, 2.5 }, { Color3.fromRGB(110, 112, 120), 3, 0.35, 2.2, 0.8 } }, -- destellos y rocas
	xibalba = { { Color3.fromRGB(70, 236, 204), 8, 0.22, 1.3, 2.5 }, { Color3.fromRGB(200, 30, 70), 6, 0.4, 1.4, 1.2 } }, -- jade y bruma rojo sangre
	tlaloc = { { Color3.fromRGB(255, 236, 90), 9, 0.18, 0.7, 6 }, { Color3.fromRGB(110, 200, 255), 6, 0.35, 1.2, 1.5 } }, -- chispas de rayo y rocío
	jaguar = { { Color3.fromRGB(40, 230, 150), 7, 0.22, 1.2, 2 }, { Color3.fromRGB(150, 96, 255), 5, 0.3, 1.2, 1.2 } }, -- jade y obsidiana
	cipactli = { { Color3.fromRGB(40, 230, 190), 7, 0.3, 1.5, 1.2 }, { Color3.fromRGB(60, 90, 70), 6, 0.5, 1.6, 0.8 } }, -- burbujas del abismo
}
local function aura(char: Model, set: string?)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local ya = hrp:FindFirstChild("AuraSet")
	if ya and ya:GetAttribute("Set") == set then
		return
	end
	if ya then
		ya:Destroy()
	end
	if not set or not AURAS[set] then
		return
	end
	local ancla = Instance.new("Attachment")
	ancla.Name = "AuraSet"
	ancla:SetAttribute("Set", set)
	ancla.Parent = hrp
	for _, c in AURAS[set] do
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(c[1])
		e.LightEmission = set == "apu" and c == AURAS.apu[2] and 0 or 1
		e.Rate = c[2]
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, c[3]), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(c[4] * 0.7, c[4])
		e.Speed = NumberRange.new(c[5] * 0.5, c[5])
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = Vector3.new(0, set == "rodador" and 6 or 2, 0)
		e.RotSpeed = NumberRange.new(-90, 90)
		e.Shape = Enum.ParticleEmitterShape.Cylinder
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.Parent = ancla
	end
	local luz = Instance.new("PointLight")
	luz.Color = AURAS[set][1][1]
	luz.Range = 9
	luz.Brightness = 0.8
	luz.Parent = ancla
end

-- Oculta (solo en esta pantalla) las partes del cuerpo que quedan dentro de la armadura,
-- junto con lo que llevan pegado (pelo, cara, mangas), para que no se asomen entre las placas.
local CUBRE = {
	cabeza = { "Head" },
	torso = { "Torso" },
	piernas = { "Right Leg", "Left Leg" },
}
local function ocultarCuerpo(char: Model, ranuras: { [string]: boolean })
	local ocultas = {}
	for ranura, partes in CUBRE do
		for _, n in partes do
			ocultas[n] = ranuras[ranura] == true
		end
	end
	-- los brazos quedan cubiertos solo con el pecho (hombreras) y los brazales juntos
	local brazos = ranuras.torso == true and ranuras.brazos == true
	ocultas["Right Arm"], ocultas["Left Arm"] = brazos, brazos
	for nombre, ocultar in ocultas do
		local p = char:FindFirstChild(nombre)
		if p and p:IsA("BasePart") then
			p.LocalTransparencyModifier = ocultar and 1 or 0
			for _, d in p:GetChildren() do
				if d:IsA("Decal") then
					d.LocalTransparencyModifier = ocultar and 1 or 0
				end
			end
		end
	end
	local apariencia = char:FindFirstChild("Apariencia")
	if apariencia then
		for _, x in apariencia:GetDescendants() do
			if x:IsA("BasePart") then
				local w = x:FindFirstChildWhichIsA("JointInstance") or x:FindFirstChildWhichIsA("WeldConstraint")
				local base = w and (w :: any).Part0
				if base and ocultas[base.Name] ~= nil then
					x.LocalTransparencyModifier = ocultas[base.Name] and 1 or 0
				end
			end
		end
	end
end

-- pone o quita las piezas según lo que lleva y lo cerca que está
local function actualizar(char: Model)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local mio = Players:GetPlayerFromCharacter(char) == jugador
	local distancia = (hrp.Position - camara.CFrame.Position).Magnitude
	local mostrar = mio or distancia < CERCA
	local lista = puestas[char] or {}
	puestas[char] = lista
	-- ¿lleva las 4 piezas de un mismo set? entonces lleva su aura
	local cuenta = {}
	for id, set in ArteArmaduras.SET do
		if char:GetAttribute("Lleva_" .. id) == true then
			cuenta[set] = (cuenta[set] or 0) + 1
		end
	end
	local setCompleto = nil
	for set, n in cuenta do
		if n >= 4 then
			setCompleto = set
		end
	end
	aura(char, mostrar and setCompleto or nil)
	local ranuras = {}
	if mostrar then
		for id in ArteArmaduras.DATOS do
			if char:GetAttribute("Lleva_" .. id) == true and Armas.RANURA[id] then
				ranuras[Armas.RANURA[id]] = true
			end
		end
	end
	ocultarCuerpo(char, ranuras)
	for id in ArteArmaduras.DATOS do
		local lleva = char:GetAttribute("Lleva_" .. id) == true
		local ya = lista[id]
		if lleva and mostrar and not ya then
			lista[id] = construirPieza(char, id)
		elseif ya and (not lleva or (not mio and distancia > LEJOS)) then
			ya:Destroy()
			lista[id] = nil
		end
	end
end

function ArmadurasPixel.iniciar()
	local function vigilar(char: Model)
		char.AttributeChanged:Connect(function(nombre)
			if string.sub(nombre, 1, 6) == "Lleva_" then
				task.defer(actualizar, char)
			end
		end)
		task.delay(0.3, actualizar, char)
	end
	local function conectar(j: Player)
		j.CharacterAdded:Connect(vigilar)
		if j.Character then
			vigilar(j.Character)
		end
	end
	Players.PlayerAdded:Connect(conectar)
	for _, j in Players:GetPlayers() do
		conectar(j)
	end
	-- cada segundo revisa quién está cerca
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t -= dt
		if t > 0 then
			return
		end
		t = 1
		for _, j in Players:GetPlayers() do
			if j.Character then
				actualizar(j.Character)
			end
		end
	end)
end

return ArmadurasPixel
