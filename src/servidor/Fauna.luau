--!nonstrict
-- Animales de bloques que dan vida a las islas y al Refugio.
-- Cada uno se mueve de una de estas formas: "camina", "salta", "vuela" (en círculos) o "nada".
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Compartido.Config)

local S = Config.S
local Fauna = {}
local animales = {}

-- Diseños: lista de bloques { tamaño, posición, color } en studs, mirando hacia -Z.
local rgb = Color3.fromRGB
local DISENOS = {
	camello = { { Vector3.new(0.8, 4, 0.8), Vector3.new(-1, 2, -2), rgb(190, 140, 82) }, { Vector3.new(0.8, 4, 0.8), Vector3.new(1, 2, -2), rgb(190, 140, 82) },
		{ Vector3.new(0.8, 4, 0.8), Vector3.new(-1, 2, 2), rgb(190, 140, 82) }, { Vector3.new(0.8, 4, 0.8), Vector3.new(1, 2, 2), rgb(190, 140, 82) },
		{ Vector3.new(3, 2.5, 6), Vector3.new(0, 5, 0), rgb(200, 150, 90) }, { Vector3.new(2, 1.5, 2), Vector3.new(0, 6.8, 0.5), rgb(190, 140, 82) },
		{ Vector3.new(3.2, 0.4, 3), Vector3.new(0, 6.3, 1.8), rgb(180, 60, 50) }, { Vector3.new(1, 3.2, 1), Vector3.new(0, 6.4, -3.3), rgb(200, 150, 90) },
		{ Vector3.new(1.2, 1.2, 2), Vector3.new(0, 8, -4.1), rgb(206, 158, 98) } },
	jerbo = { { Vector3.new(1, 0.8, 1.4), Vector3.new(0, 0.5, 0), rgb(214, 176, 122) }, { Vector3.new(0.8, 0.7, 0.7), Vector3.new(0, 0.8, -0.9), rgb(222, 186, 132) },
		{ Vector3.new(0.2, 0.7, 0.2), Vector3.new(-0.25, 1.4, -0.8), rgb(222, 186, 132) }, { Vector3.new(0.2, 0.7, 0.2), Vector3.new(0.25, 1.4, -0.8), rgb(222, 186, 132) },
		{ Vector3.new(0.2, 0.2, 1.8), Vector3.new(0, 0.5, 1.5), rgb(200, 160, 110) }, { Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 0.6, 2.4), rgb(60, 40, 30) } },
	escorpion = { { Vector3.new(1.2, 0.4, 1.8), Vector3.new(0, 0.3, 0), rgb(50, 36, 30) }, { Vector3.new(0.4, 0.4, 0.8), Vector3.new(0, 0.5, 1.2), rgb(50, 36, 30) },
		{ Vector3.new(0.4, 0.8, 0.4), Vector3.new(0, 1.1, 1.5), rgb(50, 36, 30) }, { Vector3.new(0.4, 0.4, 0.6), Vector3.new(0, 1.6, 1.2), rgb(230, 150, 40) },
		{ Vector3.new(0.5, 0.3, 0.9), Vector3.new(-0.7, 0.3, -1.2), rgb(60, 44, 36) }, { Vector3.new(0.5, 0.3, 0.9), Vector3.new(0.7, 0.3, -1.2), rgb(60, 44, 36) } },
	lagartija = { { Vector3.new(0.6, 0.3, 1.6), Vector3.new(0, 0.2, 0), rgb(120, 130, 70) }, { Vector3.new(0.5, 0.3, 0.6), Vector3.new(0, 0.25, -1.1), rgb(130, 140, 80) },
		{ Vector3.new(0.25, 0.2, 1.4), Vector3.new(0, 0.15, 1.5), rgb(110, 120, 64) } },
	llama = { { Vector3.new(0.9, 3.3, 0.9), Vector3.new(-0.8, 1.65, -1.4), rgb(240, 236, 226) }, { Vector3.new(0.9, 3.3, 0.9), Vector3.new(0.8, 1.65, -1.4), rgb(240, 236, 226) },
		{ Vector3.new(0.9, 3.3, 0.9), Vector3.new(-0.8, 1.65, 1.4), rgb(240, 236, 226) }, { Vector3.new(0.9, 3.3, 0.9), Vector3.new(0.8, 1.65, 1.4), rgb(240, 236, 226) },
		{ Vector3.new(2.4, 2.2, 4), Vector3.new(0, 4.3, 0), rgb(245, 240, 230) }, { Vector3.new(2.6, 0.4, 2.4), Vector3.new(0, 5.5, 0.2), rgb(200, 50, 60) },
		{ Vector3.new(1, 3.4, 1), Vector3.new(0, 6.3, -1.6), rgb(245, 240, 230) }, { Vector3.new(1.2, 1.2, 1.8), Vector3.new(0, 8.3, -2), rgb(245, 240, 230) },
		{ Vector3.new(0.3, 0.8, 0.3), Vector3.new(-0.35, 9.3, -1.8), rgb(245, 240, 230) }, { Vector3.new(0.3, 0.8, 0.3), Vector3.new(0.35, 9.3, -1.8), rgb(245, 240, 230) } },
	llama_cafe = nil, -- se crea abajo cambiando el color
	vizcacha = { { Vector3.new(1.2, 1.1, 1.6), Vector3.new(0, 0.7, 0), rgb(150, 140, 130) }, { Vector3.new(0.9, 0.9, 0.9), Vector3.new(0, 1.3, -0.9), rgb(160, 150, 140) },
		{ Vector3.new(0.25, 0.9, 0.25), Vector3.new(-0.25, 2.1, -0.8), rgb(160, 150, 140) }, { Vector3.new(0.25, 0.9, 0.25), Vector3.new(0.25, 2.1, -0.8), rgb(160, 150, 140) },
		{ Vector3.new(0.3, 0.9, 0.3), Vector3.new(0, 1.2, 1.0), rgb(60, 56, 52) } },
	condor = { { Vector3.new(1.6, 1.2, 3), Vector3.new(0, 0, 0), rgb(26, 24, 28) }, { Vector3.new(1.4, 0.5, 0.6), Vector3.new(0, 0.2, -1.3), rgb(240, 240, 236) },
		{ Vector3.new(0.8, 0.8, 1), Vector3.new(0, 0.3, -2), rgb(190, 90, 80) }, { Vector3.new(6, 0.3, 2.2), Vector3.new(-3.6, 0.2, 0), rgb(26, 24, 28) },
		{ Vector3.new(6, 0.3, 2.2), Vector3.new(3.6, 0.2, 0), rgb(26, 24, 28) }, { Vector3.new(4, 0.32, 0.6), Vector3.new(-3.2, 0.22, 0.6), rgb(236, 236, 232) },
		{ Vector3.new(4, 0.32, 0.6), Vector3.new(3.2, 0.22, 0.6), rgb(236, 236, 232) } },
	gato = { { Vector3.new(1, 1, 2), Vector3.new(0, 1.3, 0), rgb(230, 140, 60) }, { Vector3.new(0.4, 0.9, 0.4), Vector3.new(-0.3, 0.45, -0.7), rgb(230, 140, 60) },
		{ Vector3.new(0.4, 0.9, 0.4), Vector3.new(0.3, 0.45, -0.7), rgb(230, 140, 60) }, { Vector3.new(0.4, 0.9, 0.4), Vector3.new(-0.3, 0.45, 0.7), rgb(230, 140, 60) },
		{ Vector3.new(0.4, 0.9, 0.4), Vector3.new(0.3, 0.45, 0.7), rgb(230, 140, 60) }, { Vector3.new(1, 0.9, 0.9), Vector3.new(0, 1.9, -1.2), rgb(236, 150, 70) },
		{ Vector3.new(0.25, 0.4, 0.2), Vector3.new(-0.3, 2.5, -1.2), rgb(236, 150, 70) }, { Vector3.new(0.25, 0.4, 0.2), Vector3.new(0.3, 2.5, -1.2), rgb(236, 150, 70) },
		{ Vector3.new(0.3, 1.4, 0.3), Vector3.new(0, 2.2, 1.1), rgb(210, 120, 50) } },
	paloma = { { Vector3.new(0.8, 0.7, 1.2), Vector3.new(0, 0.6, 0), rgb(200, 200, 210) }, { Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 1.1, -0.6), rgb(150, 160, 180) },
		{ Vector3.new(0.2, 0.15, 0.3), Vector3.new(0, 1.05, -0.95), rgb(230, 150, 60) }, { Vector3.new(0.6, 0.2, 0.6), Vector3.new(0, 0.5, 0.8), rgb(170, 170, 180) } },
	pez = { { Vector3.new(0.6, 0.5, 1.2), Vector3.new(0, 0, 0), rgb(255, 140, 40) }, { Vector3.new(0.1, 0.5, 0.5), Vector3.new(0, 0, 0.8), rgb(255, 200, 80) } },
}
-- murciélago pequeño de las cuevas (vuela en círculos)
DISENOS.murcielago = { { Vector3.new(0.8, 0.7, 1.0), Vector3.new(0, 0, 0), rgb(40, 26, 56) }, { Vector3.new(2.2, 0.15, 0.9), Vector3.new(-1.4, 0.1, 0), rgb(30, 20, 44) },
	{ Vector3.new(2.2, 0.15, 0.9), Vector3.new(1.4, 0.1, 0), rgb(30, 20, 44) }, { Vector3.new(0.18, 0.12, 0.08), Vector3.new(-0.2, 0.15, -0.52), rgb(255, 60, 60) },
	{ Vector3.new(0.18, 0.12, 0.08), Vector3.new(0.2, 0.15, -0.52), rgb(255, 60, 60) } }
-- lagartija de fuego del Desierto de Brasa
DISENOS.lagartija_fuego = { { Vector3.new(0.6, 0.3, 1.6), Vector3.new(0, 0.2, 0), rgb(150, 40, 30) }, { Vector3.new(0.5, 0.3, 0.6), Vector3.new(0, 0.25, -1.1), rgb(170, 50, 36) },
	{ Vector3.new(0.25, 0.2, 1.4), Vector3.new(0, 0.15, 1.5), rgb(255, 120, 40) } }
-- búho de Xibalbá (los mensajeros de los señores del inframundo)
DISENOS.buho = { { Vector3.new(1.2, 1.4, 1.1), Vector3.new(0, 0, 0), rgb(90, 70, 56) }, { Vector3.new(1.1, 0.9, 1.0), Vector3.new(0, 1.1, -0.1), rgb(110, 88, 70) },
	{ Vector3.new(0.3, 0.3, 0.1), Vector3.new(-0.25, 1.2, -0.62), rgb(255, 200, 40) }, { Vector3.new(0.3, 0.3, 0.1), Vector3.new(0.25, 1.2, -0.62), rgb(255, 200, 40) },
	{ Vector3.new(0.2, 0.4, 0.2), Vector3.new(-0.4, 1.7, -0.1), rgb(90, 70, 56) }, { Vector3.new(0.2, 0.4, 0.2), Vector3.new(0.4, 1.7, -0.1), rgb(90, 70, 56) },
	{ Vector3.new(2.6, 0.2, 1.0), Vector3.new(-1.7, 0.3, 0.1), rgb(80, 62, 50) }, { Vector3.new(2.6, 0.2, 1.0), Vector3.new(1.7, 0.3, 0.1), rgb(80, 62, 50) } }
-- guacamaya roja de la selva
DISENOS.guacamaya = { { Vector3.new(0.8, 0.8, 1.4), Vector3.new(0, 0, 0), rgb(220, 40, 40) }, { Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, 0.4, -0.9), rgb(230, 50, 44) },
	{ Vector3.new(0.3, 0.4, 0.3), Vector3.new(0, 0.25, -1.35), rgb(240, 236, 220) }, { Vector3.new(0.4, 0.15, 1.8), Vector3.new(0, -0.1, 1.5), rgb(40, 90, 220) },
	{ Vector3.new(2.4, 0.15, 0.9), Vector3.new(-1.5, 0.15, 0), rgb(250, 210, 40) }, { Vector3.new(2.4, 0.15, 0.9), Vector3.new(1.5, 0.15, 0), rgb(250, 210, 40) },
	{ Vector3.new(1.2, 0.17, 0.5), Vector3.new(-2.2, 0.17, 0.3), rgb(40, 90, 220) }, { Vector3.new(1.2, 0.17, 0.5), Vector3.new(2.2, 0.17, 0.3), rgb(40, 90, 220) } }
-- rana de la selva (salta)
DISENOS.rana = { { Vector3.new(0.9, 0.5, 1.0), Vector3.new(0, 0.35, 0), rgb(60, 200, 90) }, { Vector3.new(0.25, 0.25, 0.1), Vector3.new(-0.25, 0.7, -0.45), rgb(255, 60, 30) },
	{ Vector3.new(0.25, 0.25, 0.1), Vector3.new(0.25, 0.7, -0.45), rgb(255, 60, 30) }, { Vector3.new(0.3, 0.2, 0.7), Vector3.new(-0.5, 0.15, 0.3), rgb(40, 120, 220) },
	{ Vector3.new(0.3, 0.2, 0.7), Vector3.new(0.5, 0.15, 0.3), rgb(40, 120, 220) } }
-- mono araña
DISENOS.mono = { { Vector3.new(1.0, 1.2, 0.8), Vector3.new(0, 1.6, 0), rgb(70, 50, 36) }, { Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 2.6, -0.1), rgb(70, 50, 36) },
	{ Vector3.new(0.6, 0.5, 0.2), Vector3.new(0, 2.5, -0.5), rgb(180, 140, 110) }, { Vector3.new(0.3, 1.6, 0.3), Vector3.new(-0.7, 1.4, 0), rgb(60, 44, 32) },
	{ Vector3.new(0.3, 1.6, 0.3), Vector3.new(0.7, 1.4, 0), rgb(60, 44, 32) }, { Vector3.new(0.3, 1.0, 0.3), Vector3.new(-0.3, 0.5, 0), rgb(60, 44, 32) },
	{ Vector3.new(0.3, 1.0, 0.3), Vector3.new(0.3, 0.5, 0), rgb(60, 44, 32) }, { Vector3.new(0.25, 0.25, 2.2), Vector3.new(0, 1.4, 1.4), rgb(60, 44, 32) } }
-- una llama café (misma forma, otro color)
DISENOS.llama_cafe = {}
for _, p in DISENOS.llama do
	local color = p[3] == rgb(200, 50, 60) and rgb(40, 110, 170) or rgb(150, 110, 76)
	table.insert(DISENOS.llama_cafe, { p[1], p[2], color })
end
-- el gato gris
DISENOS.gato_gris = {}
for _, p in DISENOS.gato do
	table.insert(DISENOS.gato_gris, { p[1], p[2], rgb(140, 140, 150) })
end

local function construir(nombre: string, carpeta: Folder): BasePart
	local m = Instance.new("Model")
	m.Name = nombre
	local raiz = Instance.new("Part")
	raiz.Name = "Raiz"
	raiz.Anchored = true
	raiz.CanCollide = false
	raiz.CanQuery = false
	raiz.Transparency = 1
	raiz.Size = Vector3.one
	raiz.Parent = m
	for _, pieza in DISENOS[nombre] do
		local p = Instance.new("Part")
		p.Size = pieza[1]
		p.Color = pieza[3]
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = raiz.CFrame * CFrame.new(pieza[2])
		local w = Instance.new("Weld")
		w.Part0 = raiz
		w.Part1 = p
		w.C0 = CFrame.new(pieza[2])
		w.Parent = p
		p.Parent = m
	end
	m.PrimaryPart = raiz
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = carpeta
	return raiz
end

-- tipo: "camina" | "salta" | "vuela" | "nada"
-- casa: centro de su zona (studs); radio en studs; altura(x, z) devuelve el suelo en studs
function Fauna.agregar(carpeta: Folder, nombre: string, tipo: string, casa: Vector3, radio: number, altura: (number, number) -> number, velocidad: number?)
	local raiz = construir(nombre, carpeta)
	local a = {
		raiz = raiz, tipo = tipo, casa = casa, radio = radio, altura = altura, vel = velocidad or 4,
		pos = casa, destino = casa, espera = math.random() * 3, yaw = math.random() * math.pi * 2, t = math.random() * 10, y = altura(casa.X, casa.Z),
	}
	table.insert(animales, a)
	return a
end

local function paso(a, dt: number)
	a.t += dt
	if a.tipo == "vuela" or a.tipo == "nada" then
		local ang = a.t * a.vel / math.max(a.radio, 1)
		local x, z = a.casa.X + math.cos(ang) * a.radio, a.casa.Z + math.sin(ang) * a.radio
		local dir = Vector3.new(-math.sin(ang), 0, math.cos(ang))
		local y = a.tipo == "vuela" and a.casa.Y + math.sin(a.t * 0.7) * 3 or a.altura(x, z) + math.sin(a.t * 3) * 0.1
		local inclinacion = a.tipo == "vuela" and CFrame.Angles(0, 0, 0.35) or CFrame.new()
		a.raiz.CFrame = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x, y, z) + dir) * inclinacion
		return
	end
	if a.espera > 0 then
		a.espera -= dt
	else
		local hacia = Vector3.new(a.destino.X - a.pos.X, 0, a.destino.Z - a.pos.Z)
		if hacia.Magnitude < 1 then
			-- llegó: descansa un rato y elige otro lugar cerca de su casa
			a.espera = math.random(15, 50) / 10
			local ang, d = math.random() * math.pi * 2, math.random() * a.radio
			a.destino = a.casa + Vector3.new(math.cos(ang) * d, 0, math.sin(ang) * d)
		else
			local deseado = math.atan2(-hacia.X, -hacia.Z)
			local dif = (deseado - a.yaw + math.pi) % (math.pi * 2) - math.pi
			a.yaw += math.clamp(dif, -3 * dt, 3 * dt)
			a.pos += hacia.Unit * math.min(hacia.Magnitude, a.vel * dt)
		end
	end
	local suelo = a.altura(a.pos.X, a.pos.Z)
	a.y += (suelo - a.y) * math.min(1, dt * 6)
	local extra = 0
	local moviendose = a.espera <= 0
	if moviendose and a.tipo == "salta" then
		extra = math.abs(math.sin(a.t * 7)) * 1.2
	elseif moviendose then
		extra = math.abs(math.sin(a.t * 6)) * 0.12
	end
	a.raiz.CFrame = CFrame.new(a.pos.X, a.y + extra, a.pos.Z) * CFrame.Angles(0, a.yaw, 0)
end

local iniciado = false
local function iniciar()
	if iniciado then
		return
	end
	iniciado = true
	local acumulado = 0
	RunService.Heartbeat:Connect(function(dt)
		acumulado += dt
		if acumulado < 1 / 30 then
			return -- 30 veces por segundo es suficiente para los animales
		end
		for _, a in animales do
			paso(a, acumulado)
		end
		acumulado = 0
	end)
end

-- ---------- poblar cada lugar ----------
function Fauna.dunas()
	iniciar()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "FaunaDunas"
	carpeta.Parent = workspace
	local function suelo(x, z)
		return Config.altura(x, z)
	end
	local function lugar(xm, zm)
		return Vector3.new(xm * S, 0, zm * S)
	end
	for _, c in { { -60, 40 }, { 80, 60 }, { 0, -75 } } do
		Fauna.agregar(carpeta, "camello", "camina", lugar(c[1], c[2]), 40, suelo, 5)
	end
	for _, c in { { 30, 50 }, { -70, -20 }, { 60, -80 }, { -100, 60 }, { 100, 10 } } do
		Fauna.agregar(carpeta, "jerbo", "salta", lugar(c[1], c[2]), 24, suelo, 8)
	end
	for _, c in { { -40, -60 }, { 90, -30 }, { -90, 20 }, { 20, 100 } } do
		Fauna.agregar(carpeta, "escorpion", "camina", lugar(c[1], c[2]), 14, suelo, 3)
	end
	for _, c in { { 72, 42 }, { -30, 80 }, { 10, -60 } } do
		Fauna.agregar(carpeta, "lagartija", "camina", lugar(c[1], c[2]), 18, suelo, 7)
	end
end

function Fauna.cumbres()
	iniciar()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "FaunaCumbres"
	carpeta.Parent = workspace
	local function suelo(x, z)
		return Config.alturaCumbres(x, z)
	end
	local function lugar(xm, zm)
		return Config.CUMBRES + Vector3.new(xm * S, 0, zm * S)
	end
	for i, c in { { 20, 40 }, { 26, 50 }, { -40, 50 }, { -34, 60 }, { 55, 10 }, { 60, 0 } } do
		Fauna.agregar(carpeta, i % 2 == 0 and "llama" or "llama_cafe", "camina", lugar(c[1], c[2]), 30, suelo, 3.5)
	end
	for _, c in { { -60, -20 }, { 40, -60 }, { -20, 30 }, { 70, 40 } } do
		Fauna.agregar(carpeta, "vizcacha", "salta", lugar(c[1], c[2]), 20, suelo, 7)
	end
	for _, c in { { 0, -20, 160 }, { -40, 30, 190 } } do
		local centro = lugar(c[1], c[2]) + Vector3.new(0, c[3], 0)
		Fauna.agregar(carpeta, "condor", "vuela", centro, 90, suelo, 22)
	end
end

function Fauna.brasa()
	iniciar()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "FaunaBrasa"
	carpeta.Parent = workspace
	local O = Config.ISLAS.brasa.centro
	local function suelo(x, z)
		return Config.alturaEn(x, z)
	end
	for _, c in { { -40, -60 }, { 90, -30 }, { -90, 20 }, { 20, 100 }, { 60, 60 } } do
		Fauna.agregar(carpeta, "escorpion", "camina", O + Vector3.new(c[1] * S, 0, c[2] * S), 14, suelo, 3)
	end
	for _, c in { { 50, -10 }, { -30, 80 }, { 10, -60 }, { -80, -40 } } do
		Fauna.agregar(carpeta, "lagartija_fuego", "camina", O + Vector3.new(c[1] * S, 0, c[2] * S), 18, suelo, 7)
	end
end

function Fauna.cuevas()
	iniciar()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "FaunaCuevas"
	carpeta.Parent = workspace
	local O = Config.ISLAS.cuevas.centro
	local function suelo(x, z)
		return Config.alturaEn(x, z)
	end
	for _, c in { { -60, -20 }, { 40, -60 }, { -20, 30 } } do
		Fauna.agregar(carpeta, "vizcacha", "salta", O + Vector3.new(c[1] * S, 0, c[2] * S), 20, suelo, 7)
	end
	for _, c in { { -40, -60, 60 }, { 50, 10, 70 }, { 0, 40, 55 }, { -70, 30, 80 } } do
		Fauna.agregar(carpeta, "murcielago", "vuela", O + Vector3.new(c[1] * S, c[3], c[2] * S), 35, suelo, 26)
	end
end

-- las islas de la selva
function Fauna.selva(zona: string)
	iniciar()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "FaunaSelva"
	carpeta.Parent = workspace
	local O = Config.ISLAS[zona].centro
	local function suelo(x, z)
		return Config.alturaEn(x, z)
	end
	local function lugar(xm, zm, y)
		return O + Vector3.new(xm * S, y or 0, zm * S)
	end
	if zona == "xibalba" then
		-- de noche: búhos y murciélagos rondando el templo
		for _, c in { { -60, -60, 80 }, { 60, -40, 95 }, { 0, 60, 70 } } do
			Fauna.agregar(carpeta, "buho", "vuela", lugar(c[1], c[2], c[3]), 45, suelo, 18)
		end
		for _, c in { { -30, -90, 120 }, { 40, -80, 110 }, { -80, 20, 75 }, { 70, 30, 80 }, { 0, -20, 100 } } do
			Fauna.agregar(carpeta, "murcielago", "vuela", lugar(c[1], c[2], c[3]), 30, suelo, 26)
		end
		for _, c in { { -80, 60 }, { 80, -10 }, { -40, 80 } } do
			Fauna.agregar(carpeta, "rana", "salta", lugar(c[1], c[2]), 12, suelo, 5)
		end
	else
		for _, c in { { -60, -60, 90 }, { 60, -40, 100 }, { 0, 60, 85 }, { -70, 40, 95 } } do
			Fauna.agregar(carpeta, "guacamaya", "vuela", lugar(c[1], c[2], c[3]), 50, suelo, 22)
		end
		for _, c in { { -90, 10 }, { 85, 40 }, { 30, -95 } } do
			Fauna.agregar(carpeta, "mono", "camina", lugar(c[1], c[2]), 16, suelo, 6)
		end
		for _, c in { { -80, 60 }, { 80, -10 }, { -40, 80 }, { 50, 70 } } do
			Fauna.agregar(carpeta, "rana", "salta", lugar(c[1], c[2]), 12, suelo, 5)
		end
	end
end

function Fauna.refugio(centro: Vector3)
	iniciar()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "FaunaRefugio"
	carpeta.Parent = workspace
	local function piso()
		return centro.Y
	end
	local V = 4
	for i, c in { { -10, 12 }, { 12, -12 } } do
		Fauna.agregar(carpeta, i == 1 and "gato" or "gato_gris", "camina", centro + Vector3.new(c[1] * V, 0, c[2] * V), 24, piso, 4)
	end
	for _, c in { { -6, 10 }, { 8, 12 }, { 0, -12 }, { -12, -2 } } do
		Fauna.agregar(carpeta, "paloma", "salta", centro + Vector3.new(c[1] * V, 0, c[2] * V), 12, piso, 5)
	end
	-- peces en el oasis (el agua está un poco por debajo del piso)
	for k = 1, 4 do
		Fauna.agregar(carpeta, "pez", "nada", centro + Vector3.new(0, 0, 0), 4 + k * 2.5, function()
			return centro.Y - 1.5
		end, 3 + k)
	end
end

return Fauna
