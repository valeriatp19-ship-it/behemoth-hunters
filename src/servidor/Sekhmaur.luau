--!nonstrict
-- Sekhmaur, el León de las Dunas. Todo lo decide el servidor: se mueve, ataca y recibe daño aquí.
-- Las jugadoras solo animan sus patas, cola y mandíbula a partir de los atributos del modelo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Mundo = require(script.Parent.Mundo)
local Estados = require(script.Parent.Estados)

local S = Config.S
local C = Config.COLORES
local VIDA_BASE = 6300
local ALTO = 3.8

local ATAQUES = {
	mordida = { prep = 0.75, activo = 0.3, rec = 0.9, danio = 22, empuje = 9 },
	pisoton = { prep = 0.95, activo = 0.25, rec = 0.9, danio = 20, empuje = 11 },
	coletazo = { prep = 0.8, activo = 0.55, rec = 0.8, danio = 22, empuje = 13 },
	aguijonazo = { prep = 1.05, activo = 0.22, rec = 2.6, danio = 30, empuje = 8 },
	embestida = { prep = 0.9, activo = 1.5, rec = 1.0, danio = 26, empuje = 16 },
	enterrarse = { prep = 1.0, activo = 2.4, rec = 1.3, danio = 30, empuje = 15 },
	rayo_solar = { prep = 1.25, activo = 0.7, rec = 1.0, danio = 28, empuje = 10 },
}
local DATOS_PARTES = {
	melena = { nombre = "Melena de arena", max = 300 },
	tocado = { nombre = "Tocado del guardián", max = 260 },
	aguijon = { nombre = "Aguijón", max = 230 },
}
local MULT_ZONA = { cuerpo = 1.0, cabeza = 1.3, pata = 0.9, cola = 1.1 }
-- zonas golpeables, en metros relativos al centro (la cabeza mira hacia -Z)
local ZONAS = {
	{ nombre = "cabeza", tipo = "cabeza", parte = "tocado", pos = Vector3.new(0, 4.9, -5.4), r = 1.7 },
	{ nombre = "hocico", tipo = "cabeza", parte = "tocado", pos = Vector3.new(0, 4.2, -6.6), r = 1.2 },
	{ nombre = "melena", tipo = "cabeza", parte = "melena", pos = Vector3.new(0, 5.0, -3.0), r = 2.7 }, -- rodea la cabeza: aturde como ella
	{ nombre = "pecho", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 3.9, -2.2), r = 1.9 },
	{ nombre = "lomo", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 3.9, 0.3), r = 2.0 },
	{ nombre = "grupa", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 3.8, 2.5), r = 1.8 },
	{ nombre = "pata_di", tipo = "pata", parte = "", pos = Vector3.new(-1.3, 1.2, -2.3), r = 0.95 },
	{ nombre = "pata_dd", tipo = "pata", parte = "", pos = Vector3.new(1.3, 1.2, -2.3), r = 0.95 },
	{ nombre = "pata_ti", tipo = "pata", parte = "", pos = Vector3.new(-1.3, 1.2, 2.3), r = 0.95 },
	{ nombre = "pata_td", tipo = "pata", parte = "", pos = Vector3.new(1.3, 1.2, 2.3), r = 0.95 },
	-- toda la cola, que baja hasta el suelo, cuenta como aguijón
	{ nombre = "cola1", tipo = "cola", parte = "aguijon", pos = Vector3.new(0, 4.3, 3.6), r = 1.2 },
	{ nombre = "cola2", tipo = "cola", parte = "aguijon", pos = Vector3.new(0, 3.2, 4.5), r = 1.2 },
	{ nombre = "cola3", tipo = "cola", parte = "aguijon", pos = Vector3.new(0, 2.0, 5.2), r = 1.2 },
	{ nombre = "cola4", tipo = "cola", parte = "aguijon", pos = Vector3.new(0, 0.9, 5.9), r = 1.2 },
	{ nombre = "cola5", tipo = "cola", parte = "aguijon", pos = Vector3.new(0, 0.6, 7.1), r = 1.2 },
	{ nombre = "aguijon", tipo = "cola", parte = "aguijon", pos = Vector3.new(0, 1.0, 8.2), r = 1.2 },
}
-- puntos de patrulla (metros)
local PATRULLA = { Vector2.new(-60, -40), Vector2.new(-10, -80), Vector2.new(70, -60), Vector2.new(48, 22), Vector2.new(-50, 20), Vector2.new(30, -10) }

local Sekhmaur = {}
Sekhmaur.__index = Sekhmaur

-- ---------- construcción del modelo ----------
local function V(x, y, z)
	return Vector3.new(x, y, z) * S
end
local function CF(x, y, z)
	return CFrame.new(x * S, y * S, z * S)
end

function Sekhmaur:_parte(props): BasePart
	local p = Instance.new(props.Clase or "Part")
	p.Anchored = false
	p.CanCollide = false -- nada del Behemoth choca con la física (evita que salgas volando)
	if props.CanCollide then
		p:SetAttribute("Solido", true) -- el cliente empuja al cazador fuera de estas partes
	end
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material == Enum.Material.Neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.Name = props.Name or "Pieza"
	p.Size = props.Size
	p.Color = props.Color or C.arena
	p.Transparency = props.Transparency or 0
	-- estilo voxel: todo es un bloque (se ignoran esferas y cilindros)
	p.Parent = self.modelo
	return p
end

-- une una pieza a otra; si "motor" es true, queda articulada (las jugadoras la animan)
function Sekhmaur:_unir(p: BasePart, a: BasePart, c0: CFrame, c1: CFrame?, motor: string?)
	local j = Instance.new(motor and "Motor6D" or "Weld")
	j.Part0 = a
	j.Part1 = p
	j.C0 = c0
	j.C1 = c1 or CFrame.new()
	if motor then
		j.Name = motor
	end
	j.Parent = p
	return j
end

function Sekhmaur:_construir()
	local m = Instance.new("Model")
	m.Name = "Sekhmaur"
	self.modelo = m
	local raiz = Instance.new("Part")
	raiz.Name = "Raiz"
	raiz.Anchored = true
	raiz.CanCollide = false
	raiz.CanQuery = false
	raiz.Transparency = 1
	raiz.Size = Vector3.new(1, 1, 1)
	raiz.Parent = m
	m.PrimaryPart = raiz
	self.raiz = raiz
	local pelaje = Color3.fromRGB(216, 160, 88)
	local oscuro = Color3.fromRGB(150, 100, 55)
	local cuerpo = self:_parte({ Name = "Cuerpo", Malla = Enum.MeshType.Sphere, Size = V(3.3, 3.0, 6.4), Color = pelaje, CanCollide = true })
	self:_unir(cuerpo, raiz, CF(0, ALTO, 0), nil, "RaizCuerpo")
	local pecho = self:_parte({ Name = "Pecho", Malla = Enum.MeshType.Sphere, Size = V(3.5, 3.4, 3.2), Color = pelaje, CanCollide = true })
	self:_unir(pecho, cuerpo, CF(0, 0.25, -2.3))
	-- jeroglíficos en los flancos (se encienden en la segunda fase)
	self.glifos = {}
	for lado = -1, 1, 2 do
		for i = 0, 3 do
			local g = self:_parte({ Name = "Glifo", Size = V(0.1, 0.55 + (i % 2) * 0.25, 0.4), Color = C.turquesa, Material = Enum.Material.Neon, Transparency = 0.55 })
			self:_unir(g, cuerpo, CF(lado * 1.6, 0.2 + (i % 2) * 0.35, -1.2 + i * 0.9))
			table.insert(self.glifos, g)
		end
	end
	-- cabeza articulada, hocico, mandíbula, orejas y ojos
	self.ojos = {}
	local cabeza = self:_parte({ Name = "Cabeza", Malla = Enum.MeshType.Sphere, Size = V(2.3, 2.1, 2.5), Color = pelaje })
	self:_unir(cabeza, cuerpo, CF(0, 1.0, -3.6), CF(0, -0.3, 1.0), "Cuello")
	local hocico = self:_parte({ Name = "Hocico", Malla = Enum.MeshType.Sphere, Size = V(1.5, 1.0, 1.3), Color = Color3.fromRGB(230, 190, 130) })
	self:_unir(hocico, cabeza, CF(0, -0.35, -1.25))
	local nariz = self:_parte({ Name = "Nariz", Size = V(0.5, 0.3, 0.2), Color = Color3.fromRGB(60, 40, 30) })
	self:_unir(nariz, cabeza, CF(0, -0.1, -1.9))
	local mandibula = self:_parte({ Name = "Mandibula", Malla = Enum.MeshType.Sphere, Size = V(1.3, 0.45, 1.4), Color = Color3.fromRGB(200, 150, 90) })
	self:_unir(mandibula, cabeza, CF(0, -0.75, -0.55), CF(0, 0, 0.6), "Mandibula")
	for lado = -1, 1, 2 do
		local ojo = self:_parte({ Name = "Ojo", Size = V(0.35, 0.22, 0.12), Color = Color3.fromRGB(255, 176, 60), Material = Enum.Material.Neon })
		self:_unir(ojo, cabeza, CF(lado * 0.62, 0.3, -1.05))
		table.insert(self.ojos, ojo)
		local oreja = self:_parte({ Name = "Oreja", Clase = "WedgePart", Size = V(0.2, 0.7, 0.6), Color = oscuro })
		self:_unir(oreja, cabeza, CF(lado * 0.85, 1.05, 0.1) * CFrame.Angles(0, 0, lado * -0.3))
	end
	-- melena de arena viva con dos anillos que giran
	self.melena = {}
	local melena = self:_parte({ Name = "Melena", Malla = Enum.MeshType.Sphere, Size = V(4.6, 4.3, 3.8), Color = Color3.fromRGB(226, 180, 105), Material = Enum.Material.Sand })
	self:_unir(melena, cuerpo, CF(0, 1.1, -3.0))
	table.insert(self.melena, melena)
	for i = 1, 2 do
		local anillo = self:_parte({ Name = "Anillo" .. i, Size = V(0.3, 5.2 - i * 0.6, 0.5), Color = Color3.fromRGB(240, 200, 130), Transparency = 0.2 })
		self:_unir(anillo, cuerpo, CF(0, 1.1, -3.0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(i * 30), 0, 0), nil, "Anillo" .. i)
		table.insert(self.melena, anillo)
	end
	local arena = Instance.new("ParticleEmitter")
	arena.Color = ColorSequence.new(Color3.fromRGB(235, 200, 140))
	arena.Size = NumberSequence.new(0.25)
	arena.Lifetime = NumberRange.new(1.2, 2)
	arena.Rate = 40
	arena.Speed = NumberRange.new(1, 3)
	arena.Acceleration = Vector3.new(0, -6, 0)
	arena.SpreadAngle = Vector2.new(180, 180)
	arena.Parent = melena
	self.particulasMelena = arena
	-- tocado del guardián (oculto hasta la segunda fase): franjas azules y doradas y la cobra
	self.tocado = {}
	local function tocado(props, c0)
		local p = self:_parte(props)
		p.Transparency = 1
		self:_unir(p, cabeza, c0)
		table.insert(self.tocado, p)
		return p
	end
	tocado({ Name = "Nemes", Malla = Enum.MeshType.Sphere, Size = V(2.55, 2.0, 2.6), Color = C.oro, Material = Enum.Material.Metal }, CF(0, 0.45, 0.15))
	for i = -1, 1 do
		tocado({ Name = "Franja", Size = V(2.6, 0.22, 2.2), Color = C.azul }, CF(0, 0.35 + i * 0.4, 0.3))
	end
	for lado = -1, 1, 2 do
		tocado({ Name = "Caida", Size = V(0.35, 2.4, 1.1), Color = C.azul }, CF(lado * 1.2, -0.7, 0.1))
		tocado({ Name = "CaidaOro", Size = V(0.37, 0.25, 1.12), Color = C.oro, Material = Enum.Material.Metal }, CF(lado * 1.2, -0.4, 0.1))
	end
	tocado({ Name = "Banda", Size = V(2.5, 0.3, 0.3), Color = C.oro, Material = Enum.Material.Metal }, CF(0, 0.55, -1.05))
	tocado({ Name = "Cobra", Shape = Enum.PartType.Cylinder, Size = V(0.8, 0.3, 0.3), Color = C.oro, Material = Enum.Material.Metal }, CF(0, 1.0, -1.1) * CFrame.Angles(0, 0, math.rad(90)))
	tocado({ Name = "Gema", Shape = Enum.PartType.Ball, Size = V(0.3, 0.3, 0.3), Color = C.turquesa, Material = Enum.Material.Neon }, CF(0, 1.15, -1.2))
	-- patas articuladas: cadera, muslo, rodilla, pierna y garra
	for _, p in { { "DI", -1, -2.3 }, { "DD", 1, -2.3 }, { "TI", -1, 2.3 }, { "TD", 1, 2.3 } } do
		local nombre, lado, z = p[1], p[2], p[3]
		local muslo = self:_parte({ Name = "Muslo" .. nombre, Malla = Enum.MeshType.Sphere, Size = V(1.2, 2.2, 1.4), Color = pelaje })
		self:_unir(muslo, cuerpo, CF(lado * 1.25, -0.6, z), CF(0, 0.8, 0), "Cadera" .. nombre)
		local pierna = self:_parte({ Name = "Pierna" .. nombre, Malla = Enum.MeshType.Sphere, Size = V(0.85, 1.7, 0.95), Color = pelaje })
		self:_unir(pierna, muslo, CF(0, -0.8, 0), CF(0, 0.65, 0), "Rodilla" .. nombre)
		local garra = self:_parte({ Name = "Garra" .. nombre, Malla = Enum.MeshType.Sphere, Size = V(1.15, 0.55, 1.45), Color = Color3.fromRGB(200, 150, 90) })
		self:_unir(garra, pierna, CF(0, -0.75, -0.2))
		for u = -1, 1 do
			local una = self:_parte({ Name = "Una", Clase = "WedgePart", Size = V(0.18, 0.3, 0.35), Color = Color3.fromRGB(245, 235, 210) })
			self:_unir(una, garra, CF(u * 0.35, -0.05, -0.72) * CFrame.Angles(0, math.pi, 0))
		end
	end
	-- cola de escorpión: cinco tramos articulados con anillos ámbar y el aguijón
	local anterior = cuerpo
	local c0 = CF(0, 0.8, 3.0)
	self.anillosCola = {}
	for i = 1, 5 do
		local ancho = 0.75 - i * 0.07
		local tramo = self:_parte({ Name = "Cola" .. i, Malla = Enum.MeshType.Sphere, Size = V(ancho, ancho, 1.5), Color = pelaje })
		self:_unir(tramo, anterior, c0, CF(0, 0, -0.7), "Cola" .. i)
		local anillo = self:_parte({ Name = "AnilloCola", Shape = Enum.PartType.Cylinder, Size = V(0.2, ancho * 1.12, ancho * 1.12), Color = Color3.fromRGB(255, 176, 60), Material = Enum.Material.Neon })
		self:_unir(anillo, tramo, CF(0, 0, -0.5) * CFrame.Angles(0, math.rad(90), 0))
		table.insert(self.anillosCola, anillo)
		anterior = tramo
		c0 = CF(0, 0, 0.7)
	end
	local aguijon = self:_parte({ Name = "Aguijon", Clase = "WedgePart", Size = V(0.4, 0.5, 1.4), Color = Color3.fromRGB(255, 190, 90), Material = Enum.Material.Neon })
	self:_unir(aguijon, anterior, CF(0, 0.2, 1.0) * CFrame.Angles(math.rad(-60), 0, 0))
	self.aguijon = aguijon
	-- avisos rojos en el suelo, el rayo de luz y el montículo cuando se entierra
	local function aviso(nombre, forma)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 70, 40)
		p.Transparency = 1
		p.Shape = forma
		p.Size = Vector3.new(0.3, 1, 1)
		p.Parent = workspace
		return p
	end
	self.avisoCirculo = aviso("AvisoCirculo", Enum.PartType.Cylinder)
	self.avisoRect = aviso("AvisoRect", Enum.PartType.Block)
	self.rayo = aviso("RayoSolar", Enum.PartType.Block)
	self.rayo.Color = Color3.fromRGB(255, 220, 120)
	self.monticulo = aviso("Monticulo", Enum.PartType.Block)
	self.monticulo.Material = Enum.Material.Sand
	self.monticulo.Color = C.arena
	local polvo = arena:Clone()
	polvo.Rate = 0
	polvo.Parent = self.monticulo
	self.polvoMonticulo = polvo
	m:SetAttribute("Nombre", "Sekhmaur")
	m:SetAttribute("Partes", "melena:Melena de arena;tocado:Tocado del guardián;aguijon:Aguijón")
	-- con streaming activado, Roblox manda los modelos por partes: el Behemoth debe llegar
	-- completo a todos los jugadores para que su animación y sus partes funcionen
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m.Parent = workspace:FindFirstChild("Behemoths") or workspace
	-- los buitres siempre vuelan sobre él
	self.buitres = {}
	for i = 1, 4 do
		local b = Instance.new("Model")
		b.Name = "Buitre"
		local cuerpoB = Instance.new("Part")
		cuerpoB.Anchored = true
		cuerpoB.CanCollide = false
		cuerpoB.CanQuery = false
		cuerpoB.Size = Vector3.new(1.2, 1.0, 2.4)
		cuerpoB.Color = Color3.fromRGB(50, 40, 36)
		cuerpoB.Parent = b
		local alas = Instance.new("Part")
		alas.Anchored = true
		alas.CanCollide = false
		alas.CanQuery = false
		alas.Size = Vector3.new(7, 0.2, 1.4)
		alas.Color = Color3.fromRGB(40, 32, 30)
		alas.Parent = b
		b.PrimaryPart = cuerpoB
		b.Parent = workspace
		self.buitres[i] = { b, cuerpoB, alas }
	end
end

-- ---------- vida y estado ----------
function Sekhmaur.nuevo(servicios)
	local self = setmetatable({}, Sekhmaur)
	self.servicios = servicios
	self:_construir()
	self:reiniciar()
	return self
end

function Sekhmaur:reiniciar()
	local n = math.max(1, #self.servicios.jugadores())
	self.vidaMax = VIDA_BASE * (1 + 0.6 * (n - 1))
	self.vida = self.vidaMax
	self.estado = "vagar"
	self.alerta = false
	self.fase2 = false
	self.furioso = false
	self.muerto = false
	self.enterrado = false
	self.derribo = 0
	self.derriboMax = 230
	self.heridas = {}
	self.cdEnterrar = 8
	self.t = 0
	self.reloj = 0
	self.cd = 2
	self.lejos = 0
	self.destino = nil
	self.espera = 0
	self.tiempo = 0
	self.caceria = { partes = {}, derribos = 0, desmayos = 0, terminada = false }
	self.participantes = {}
	Estados.iniciar(self)
	self.partes = {}
	for id, d in DATOS_PARTES do
		self.partes[id] = { nombre = d.nombre, max = d.max, vida = d.max, rota = false }
	end
	for _, p in self.melena do
		p.Transparency = p.Name == "Melena" and 0 or 0.35
	end
	self.particulasMelena.Enabled = true
	for _, p in self.tocado do
		p.Transparency = 1
	end
	for _, g in self.glifos do
		g.Transparency = 0.55
	end
	for _, o in self.ojos do
		o.Color = Color3.fromRGB(255, 176, 60)
	end
	self.aguijon.Color = Color3.fromRGB(255, 190, 90)
	Mundo.cieloGuardian(false)
	local p = PATRULLA[math.random(1, #PATRULLA)]
	self.pos = Config.suelo(p.X, p.Y)
	self.yaw = math.random() * math.pi * 2
	self:_ocultarAvisos()
	self:_anim("reposo")
	self:_publicar()
end

function Sekhmaur:_anim(nombre: string, ritmo: number?)
	if self.modelo:GetAttribute("Anim") ~= nombre then
		self.modelo:SetAttribute("Anim", nombre)
		self.modelo:SetAttribute("AnimT0", workspace:GetServerTimeNow())
	end
	self.modelo:SetAttribute("Ritmo", ritmo or 1)
end

function Sekhmaur:_publicar()
	local m = self.modelo
	m:SetAttribute("Vida", self.vida)
	m:SetAttribute("VidaMax", self.vidaMax)
	m:SetAttribute("Fase2", self.fase2)
	m:SetAttribute("Furioso", self.furioso)
	m:SetAttribute("Muerto", self.muerto)
	m:SetAttribute("Alerta", self.alerta)
	m:SetAttribute("Derribo", self.derribo / self.derriboMax)
	m:SetAttribute("Estado", self.estado)
	m:SetAttribute("Herido", next(self.heridas) ~= nil)
	for id, p in self.partes do
		local valor = p.rota and -1 or p.vida / p.max
		if id == "tocado" and not self.fase2 then
			valor = -2
		end
		m:SetAttribute("P_" .. id, valor)
	end
end

function Sekhmaur:_adelante(): Vector3
	return CFrame.Angles(0, self.yaw, 0).LookVector
end

function Sekhmaur:_yawHacia(p: Vector3): number
	local d = p - self.pos
	return math.atan2(-d.X, -d.Z)
end

function Sekhmaur:_girarHacia(yaw: number, rapidez: number, dt: number)
	local dif = (yaw - self.yaw + math.pi) % (math.pi * 2) - math.pi
	self.yaw += math.clamp(dif, -rapidez * dt, rapidez * dt)
end

function Sekhmaur:_angulo(p: Vector3): number
	return math.abs((self:_yawHacia(p) - self.yaw + math.pi) % (math.pi * 2) - math.pi)
end

function Sekhmaur:_dist(p: Vector3): number
	return Vector2.new(p.X - self.pos.X, p.Z - self.pos.Z).Magnitude / S
end

-- ¿Ese punto (studs) choca con una pirámide u obelisco? Devuelve el punto corregido.
local function fueraDeObstaculos(pos: Vector3, margen: number): (Vector3, boolean)
	local choco = false
	for _, p in Config.PIRAMIDES do
		local c = Vector3.new(p.x * S, 0, p.z * S)
		local medio = (p.tam * 0.5 + margen) * S
		local d = pos - c
		if math.abs(d.X) < medio and math.abs(d.Z) < medio then
			choco = true
			if math.abs(d.X) > math.abs(d.Z) then
				pos = Vector3.new(c.X + math.sign(d.X) * medio, pos.Y, pos.Z)
			else
				pos = Vector3.new(pos.X, pos.Y, c.Z + math.sign(d.Z) * medio)
			end
		end
	end
	for _, o in Config.OBELISCOS do
		local c = Vector2.new(o[1] * S, o[2] * S)
		local d = Vector2.new(pos.X, pos.Z) - c
		local r = (1.2 + margen) * S
		if d.Magnitude < r then
			choco = true
			local n = d.Magnitude > 0.01 and d.Unit or Vector2.new(1, 0)
			local q = c + n * r
			pos = Vector3.new(q.X, pos.Y, q.Y)
		end
	end
	return pos, choco
end

function Sekhmaur:_mover(dt: number, velocidad: number): boolean
	local nueva = self.pos + self:_adelante() * velocidad * Estados.freno(self) * S * dt
	local choco
	nueva, choco = fueraDeObstaculos(nueva, 2.2)
	local plano = Vector2.new(nueva.X, nueva.Z)
	if plano.Magnitude > 130 * S then
		plano = plano.Unit * 130 * S
		choco = true
	end
	local camp = Config.CAMPAMENTO * S
	local alCamp = plano - camp
	if alCamp.Magnitude < 26 * S then
		plano = camp + alCamp.Unit * 26 * S
		self.destino = nil
	end
	self.pos = Vector3.new(plano.X, Config.altura(plano.X, plano.Y), plano.Y)
	return choco
end

-- ---------- objetivo: el cazador más cercana que se pueda atacar ----------
function Sekhmaur:_elegirObjetivo(dt: number)
	self.tObjetivo = (self.tObjetivo or 0) - dt
	local actual = self.objetivo
	local valido = false
	if actual then
		for _, j in self.servicios.jugadores() do
			if j.hrp == actual.hrp and j.atacable then
				valido = true
				self.objetivo = j
			end
		end
	end
	if valido and self.tObjetivo > 0 then
		return
	end
	self.tObjetivo = 2.5
	local mejor, mejorD = nil, math.huge
	for _, j in self.servicios.jugadores() do
		local d = self:_dist(j.hrp.Position)
		if j.atacable and d < mejorD then
			mejor, mejorD = j, d
		end
	end
	self.objetivo = mejor
end

function Sekhmaur:_posObjetivo(): Vector3
	return self.objetivo and self.objetivo.hrp.Position or self.pos
end

-- ---------- ciclo principal ----------
function Sekhmaur:paso(dt: number)
	self.reloj += dt
	self.t += dt
	self:_elegirObjetivo(dt)
	-- si su presa se refugia en el campamento (y no queda nadie más), pierde interés y vuelve a su ruta
	if self.alerta and not self.muerto and not self.objetivo and self.estado == "perseguir" then
		self.sinPresa = (self.sinPresa or 0) + dt
		if self.sinPresa > 3 then
			self.sinPresa = 0
			self.alerta = false
			self.destino = nil
			self:_cambiar("vagar")
		end
	else
		self.sinPresa = 0
	end
	for nombre, h in self.heridas do
		h.t -= dt
		if h.t <= 0 then
			h.marca:Destroy()
			self.heridas[nombre] = nil
		else
			h.marca.CFrame = self.raiz.CFrame * CFrame.new(h.zona.pos * S)
		end
	end
	self.cdEnterrar -= dt
	Estados.paso(self, dt)
	if self.alerta and not self.muerto then
		self.tiempo += dt
	end
	local hayObjetivo = self.objetivo ~= nil
	if not self.muerto and not self.alerta and hayObjetivo and self:_dist(self:_posObjetivo()) < 22 and (self.estado == "vagar" or self.estado == "beber") then
		self:_alertar()
	end
	if self.alerta and not self.muerto and self.estado == "perseguir" then
		self.lejos = (not hayObjetivo or self:_dist(self:_posObjetivo()) > 75) and self.lejos + dt or 0
		if self.lejos > 6 then
			self.alerta = false
			self.lejos = 0
			self:_cambiar("vagar")
		end
	end
	local e = self.estado
	if e == "vagar" then
		self:_vagar(dt)
	elseif e == "beber" then
		self:_anim("beber")
		if self.t > 4 then
			self:_cambiar("vagar")
		end
	elseif e == "rugir" then
		self:_anim("rugir")
		if not self.rugio and self.t > 0.45 then
			self.rugio = true
			for _, j in self.servicios.jugadores() do
				local char = j.hrp.Parent
				if self:_dist(j.hrp.Position) < 20 and not Config.enCampamento(j.hrp.Position) and not (char and char:GetAttribute("Lleva_capucha")) then
					Remotos.Aturdir:FireClient(j.jugador, 1.1)
				end
			end
		end
		if self.t > 2 then
			self:_cambiar("perseguir")
			self.cd = 1
		end
	elseif e == "perseguir" then
		self:_perseguir(dt)
	elseif e == "ataque" then
		self:_ataque(dt)
	elseif e == "estremecer" then
		self:_anim("estremecer")
		if self.t > 1.4 then
			self:_cambiar(self.alerta and "perseguir" or "vagar")
			self.cd = 0.6
		end
	elseif e == "derribado" then
		self:_anim("derribado")
		if self.t > 6 then
			self:_cambiar("levantarse")
		end
	elseif e == "levantarse" then
		self:_anim("levantarse")
		if self.t > 1.2 then
			self:_cambiar("perseguir")
			self.cd = 0.5
		end
	elseif e == "muerto" then
		self:_anim("muerte")
		if self.t > 25 then
			self:reiniciar()
		end
	end
	-- colocar el modelo (bajo la arena si está enterrado)
	-- sube y baja los escalones de arena con suavidad
	self.yVisual = self.yVisual or self.pos.Y
	self.yVisual += (self.pos.Y - self.yVisual) * math.min(1, dt * 8)
	local hundido = self.enterrado and -40 or 0
	self.raiz.CFrame = CFrame.new(self.pos.X, self.yVisual + hundido, self.pos.Z) * CFrame.Angles(0, self.yaw, 0)
	if self.avisoCirculo.Transparency < 1 or self.avisoRect.Transparency < 1 then
		local a = 0.35 + 0.25 * math.sin(self.reloj * 14)
		if self.avisoCirculo.Transparency < 1 then
			self.avisoCirculo.Transparency = a
		end
		if self.avisoRect.Transparency < 1 then
			self.avisoRect.Transparency = a
		end
	end
	-- buitres en círculo sobre él
	for i, b in self.buitres do
		local ang = self.reloj * 0.35 + i * math.pi / 2
		local centro = self.pos + Vector3.new(math.cos(ang) * (12 + i * 2) * S, (20 + i * 1.5) * S, math.sin(ang) * (12 + i * 2) * S)
		local cf = CFrame.lookAt(centro, centro + Vector3.new(-math.sin(ang), -0.05, math.cos(ang)))
		b[2].CFrame = cf
		b[3].CFrame = cf * CFrame.Angles(0, 0, math.sin(self.reloj * 3 + i) * 0.25)
	end
	self:_publicar()
end

function Sekhmaur:_cambiar(nuevo: string)
	self.estado = nuevo
	self.t = 0
end

function Sekhmaur:_vagar(dt: number)
	if self.espera > 0 then
		self.espera -= dt
		self:_anim("reposo")
		return
	end
	if not self.destino then
		local p = PATRULLA[math.random(1, #PATRULLA)]
		self.destino = Config.suelo(p.X + math.random(-10, 10), p.Y + math.random(-10, 10))
	end
	if self:_dist(self.destino) < 4 then
		local enOasis = (Vector2.new(self.pos.X, self.pos.Z) / S - Config.OASIS).Magnitude < Config.OASIS_RADIO + 8
		self.destino = nil
		if enOasis then
			self:_cambiar("beber")
		else
			self.espera = math.random(15, 40) / 10
		end
		return
	end
	self:_girarHacia(self:_yawHacia(self.destino), 1.3, dt)
	if self:_mover(dt, 3.5) then
		self.destino = nil
	end
	self:_anim("caminar", 1)
end

function Sekhmaur:_alertar()
	if self.alerta or self.muerto then
		return
	end
	self.alerta = true
	self.lejos = 0
	self.rugio = false
	self:_cambiar("rugir")
	self.servicios.anunciar("¡Sekhmaur te ha detectado!", Color3.fromRGB(255, 138, 106))
end

function Sekhmaur:_perseguir(dt: number)
	if not self.objetivo then
		self:_anim("reposo")
		return
	end
	local objetivo = self:_posObjetivo()
	local dist = self:_dist(objetivo)
	self:_girarHacia(self:_yawHacia(objetivo), self.furioso and 2.6 or 2.0, dt)
	if dist > 7 then
		local v = self.furioso and 7.8 or 6.5
		self:_mover(dt, v)
		self:_anim("correr", v / 6.5)
	else
		self:_anim("reposo")
	end
	self.cd -= dt
	if self.cd <= 0 then
		local nombre = self:_elegirAtaque(dist, self:_angulo(objetivo))
		if nombre then
			self:_iniciarAtaque(nombre)
		else
			self.cd = 0.3
		end
	end
end

function Sekhmaur:_elegirAtaque(dist: number, ang: number): string?
	local opciones = {}
	local function op(n, peso)
		table.insert(opciones, { n, peso })
	end
	if dist < 7 and ang < 0.5 then
		op("mordida", 3)
	end
	if dist < 7.5 then
		op("pisoton", 2)
	end
	if dist < 14 and ang > 1.2 then
		op("coletazo", 3)
	elseif dist < 12 then
		op("coletazo", 1)
	end
	if dist > 6 and dist < 13 and ang < 0.8 then
		op("aguijonazo", 2)
	end
	if dist > 12 and dist < 40 and ang < 0.5 then
		op("embestida", 2)
	end
	if dist > 14 and self.cdEnterrar <= 0 then
		op("enterrarse", 1.2)
	end
	if self.fase2 and dist > 8 and dist < 30 and ang < 0.6 then
		op("rayo_solar", 2.5)
	end
	if #opciones == 0 then
		return nil
	end
	local total = 0
	for _, o in opciones do
		total += o[2]
	end
	local r = math.random() * total
	for _, o in opciones do
		r -= o[2]
		if r <= 0 then
			return o[1]
		end
	end
	return opciones[1][1]
end

function Sekhmaur:_duraciones(): (number, number, number)
	local d = ATAQUES[self.ataque]
	local k = (self.furioso and 1.2 or 1) * (self.fase2 and 1.15 or 1)
	return d.prep / k, d.activo / k, d.rec / k
end

function Sekhmaur:_iniciarAtaque(nombre: string)
	self:_cambiar("ataque")
	self.ataque = nombre
	self.fase = ""
	self.tFase = 0
	self.golpeados = {}
	self.hecho = false
	self.dirGiro = math.random() < 0.5 and -1 or 1
	self:_anim(nombre, (self.furioso and 1.2 or 1) * (self.fase2 and 1.15 or 1))
	if nombre == "enterrarse" then
		self.cdEnterrar = 14
	end
end

function Sekhmaur:_terminarAtaque()
	self:_ocultarAvisos()
	self.enterrado = false
	self:_cambiar("perseguir")
	self.cd = (math.random(5, 13) / 10) * (self.furioso and 0.6 or 1)
end

-- Daña a todos los cazadores para las que "prueba(posición)" es verdad (cada una una sola vez).
function Sekhmaur:_golpear(prueba, origen: Vector3)
	local d = ATAQUES[self.ataque]
	for _, j in self.servicios.jugadores() do
		if j.atacable and not self.golpeados[j.hrp] and prueba(j.hrp.Position) then
			self.golpeados[j.hrp] = true
			self.servicios.danio(j.jugador, d.danio * (self.furioso and 1.15 or 1), origen, d.empuje, self.ataque)
		end
	end
end

local function plano(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude / S
end

function Sekhmaur:_ataque(dt: number)
	local prep, act, rec = self:_duraciones()
	self.tFase += dt
	local nueva, inicio = "prep", 0
	if self.tFase >= prep + act + rec then
		self:_terminarAtaque()
		return
	elseif self.tFase >= prep + act then
		nueva, inicio = "rec", prep + act
	elseif self.tFase >= prep then
		nueva, inicio = "activo", prep
	end
	if nueva ~= self.fase then
		self.fase = nueva
		self.hecho = false
		self.inicioFase = inicio
	end
	local tf = self.tFase - self.inicioFase
	local adelante = self:_adelante()
	local objetivo = self:_posObjetivo()
	local a = self.ataque
	if a == "mordida" then
		local punto = self.pos + adelante * 5.5 * S
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			self:_avisoCirculo(punto, 3)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self:_mover(dt, 6)
			self:_golpear(function(p)
				return plano(p, self.pos + adelante * 5.5 * S) < 3
			end, punto)
		end
	elseif a == "pisoton" then
		local punto = self.pos + adelante * 3 * S
		if self.fase == "prep" then
			self:_avisoCirculo(punto, 6)
		elseif self.fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(punto, 30)
			self:_golpear(function(p)
				return plano(p, punto) < 6
			end, punto)
		end
	elseif a == "coletazo" then
		if self.fase == "prep" then
			self:_avisoCirculo(self.pos, 15.5)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self.yaw += self.dirGiro * (math.pi * 1.5 / act) * dt
			local cola = -self:_adelante()
			self:_golpear(function(p)
				local d = Vector3.new(p.X - self.pos.X, 0, p.Z - self.pos.Z)
				local m = d.Magnitude / S
				return m > 2.5 and m < 15.8 and d.Unit:Dot(cola) > math.cos(0.38)
			end, self.pos)
		end
	elseif a == "aguijonazo" then
		local punto = self.pos + adelante * 9 * S
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 2.2, dt)
			self:_avisoCirculo(punto, 3.8)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self:_golpear(function(p)
				return plano(p, punto) < 3.8
			end, punto)
		end
	elseif a == "embestida" then
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 4, dt)
			self:_avisoRect(self.pos, self.yaw, 6, 30)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self:_anim("correr", 2.2)
			self:_girarHacia(self:_yawHacia(objetivo), 0.5, dt)
			local choco = self:_mover(dt, self.furioso and 24 or 20)
			self:_golpear(function(p)
				return plano(p, self.pos + adelante * 5 * S) < 3.2 or plano(p, self.pos) < 4
			end, self.pos)
			if choco then
				self:_ocultarAvisos()
				self.servicios.anunciar("¡Sekhmaur se estrelló!", Color3.fromRGB(255, 224, 138))
				self:_polvo(self.pos + adelante * 5 * S, 40)
				self:_cambiar("estremecer")
				return
			end
		else
			self:_anim("reposo")
			self:_mover(dt, math.max(0, 14 * (1 - tf / rec)))
		end
	elseif a == "enterrarse" then
		if self.fase == "activo" then
			if not self.hecho then
				self.hecho = true
				self.enterrado = true
				self.montPos = self.pos
				self.polvoMonticulo.Rate = 60
				self.monticulo.Transparency = 0
				self.monticulo.Size = V(4, 1.6, 4)
			end
			if tf < act - 0.6 then
				local hacia = Vector3.new(objetivo.X - self.montPos.X, 0, objetivo.Z - self.montPos.Z)
				if hacia.Magnitude > 1 then
					local nuevo = self.montPos + hacia.Unit * math.min(hacia.Magnitude, 9 * S * dt)
					self.montPos = Vector3.new(nuevo.X, Config.altura(nuevo.X, nuevo.Z), nuevo.Z)
				end
			end
			self.monticulo.CFrame = CFrame.new(self.montPos + Vector3.new(0, 0.4 * S, 0))
			if tf > act - 0.8 then
				self:_avisoCirculo(self.montPos, 5.5)
			end
		elseif self.fase == "rec" and not self.hecho then
			self.hecho = true
			self.enterrado = false
			self.pos = self.montPos
			self.monticulo.Transparency = 1
			self.polvoMonticulo.Rate = 0
			self:_ocultarAvisos()
			self:_polvo(self.pos, 50)
			self:_golpear(function(p)
				return plano(p, self.pos) < 5.5
			end, self.pos)
		end
	elseif a == "rayo_solar" then
		local desde = self.pos + adelante * 5 * S
		local largo = 30
		if self.fase == "prep" then
			if tf < prep - 0.35 then
				self:_girarHacia(self:_yawHacia(objetivo), 1.3, dt)
			end
			self:_avisoRect(desde, self.yaw, 4.6, largo)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			local medio = desde + adelante * largo * 0.5 * S
			self.rayo.Transparency = 0.15
			self.rayo.Size = Vector3.new(1.6 * S * (1 + math.sin(self.reloj * 40) * 0.15), 1.6 * S, largo * S)
			self.rayo.CFrame = CFrame.new(Vector3.new(medio.X, Config.altura(medio.X, medio.Z) + 1.4 * S, medio.Z)) * CFrame.Angles(0, self.yaw, 0)
			self:_golpear(function(p)
				local rel = Vector3.new(p.X - desde.X, 0, p.Z - desde.Z) / S
				local aLoLargo = rel:Dot(adelante)
				local alLado = math.abs(rel:Cross(adelante).Y)
				return aLoLargo > -1 and aLoLargo < largo and alLado < 2.4
			end, desde)
		else
			self.rayo.Transparency = 1
		end
	end
end

-- ---------- avisos y efectos ----------
function Sekhmaur:_avisoCirculo(centro: Vector3, radio: number)
	local c = self.avisoCirculo
	if c.Transparency >= 1 then
		c.Transparency = 0.4
	end
	c.Size = Vector3.new(0.3, radio * 2 * S, radio * 2 * S)
	c.CFrame = CFrame.new(centro.X, Config.altura(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, 0, math.rad(90))
end

function Sekhmaur:_avisoRect(inicio: Vector3, yaw: number, ancho: number, largo: number)
	local r = self.avisoRect
	if r.Transparency >= 1 then
		r.Transparency = 0.4
	end
	local dir = CFrame.Angles(0, yaw, 0).LookVector
	local centro = inicio + dir * largo * 0.5 * S
	r.Size = Vector3.new(ancho * S, 0.3, largo * S)
	r.CFrame = CFrame.new(centro.X, Config.altura(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, yaw, 0)
end

function Sekhmaur:_ocultarAvisos()
	self.avisoCirculo.Transparency = 1
	self.avisoRect.Transparency = 1
	self.rayo.Transparency = 1
	self.monticulo.Transparency = 1
	self.polvoMonticulo.Rate = 0
end

function Sekhmaur:_polvo(pos: Vector3, cantidad: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = Vector3.new(pos.X, Config.altura(pos.X, pos.Z) + 1, pos.Z)
	p.Parent = workspace
	local e = self.particulasMelena:Clone()
	e.Rate = 0
	e.Speed = NumberRange.new(10, 25)
	e.Size = NumberSequence.new(0.8, 0)
	e.Acceleration = Vector3.new(0, -20, 0)
	e.Parent = p
	e:Emit(cantidad)
	game:GetService("Debris"):AddItem(p, 3)
end

-- ---------- recibir golpes ----------
function Sekhmaur:zonas()
	if self.muerto or self.enterrado then
		return {}
	end
	local lista = {}
	local cf = self.raiz.CFrame
	for _, z in ZONAS do
		table.insert(lista, { zona = z, pos = (cf * CFrame.new(z.pos * S)).Position, r = z.r * S })
	end
	return lista
end

function Sekhmaur:recibirGolpe(z, info, jugador: Player?)
	if self.muerto then
		return
	end
	local parte = z.parte
	if parte == "melena" and self.fase2 then
		parte = ""
	end
	if parte == "tocado" and not self.fase2 then
		parte = "melena" -- antes de despertar, toda la cabeza cuenta como la melena
	end
	if jugador then
		self.participantes[jugador] = true
	end
	local m = MULT_ZONA[z.tipo] or 1
	if parte ~= "" and self.partes[parte] and self.partes[parte].rota then
		m = 1.3
	end
	if self.estado == "derribado" then
		m *= 1.25
	end
	local herida = self.heridas[z.nombre] ~= nil
	if herida then
		m *= 1.25
	end
	local danio = math.max(1, math.floor(info.danio * m * (0.92 + math.random() * 0.16) + 0.5))
	-- colores del número: cian = herida, amarillo = parte, verde = aturdimiento, blanco = normal
	local rompiendo = parte ~= "" and self.partes[parte] ~= nil and not self.partes[parte].rota
	local factorAturdir = z.tipo == "pata" and 1 or (z.tipo == "cabeza" and 1.2 or 0.4)
	local color
	if herida then
		color = Color3.fromRGB(80, 230, 255)
	elseif rompiendo then
		color = Color3.fromRGB(255, 220, 60)
	elseif (info.aturdir or 0) * factorAturdir >= 1 then
		color = Color3.fromRGB(90, 230, 110)
	else
		color = Color3.new(1, 1, 1)
	end
	local pos = (self.raiz.CFrame * CFrame.new(z.pos * S)).Position
	self.servicios.numero(pos + Vector3.new(0, z.r * S * 0.6, 0), tostring(danio), color, info.fuerte)
	if not self.alerta then
		self:_alertar()
	end
	if parte ~= "" and self.partes[parte] and not self.partes[parte].rota then
		local p = self.partes[parte]
		p.vida -= danio * info.partes
		if p.vida <= 0 then
			self:_romper(parte)
		end
	end
	if self.estado ~= "derribado" and self.estado ~= "levantarse" and self.estado ~= "muerto" then
		local factor = z.tipo == "pata" and 1 or (z.tipo == "cabeza" and 1.2 * (info.multCabeza or 1) or 0.35)
		self.derribo += danio * info.aturdir * factor * (self.lentitud > 0 and 1.5 or 1)
		if self.derribo >= self.derriboMax then
			self:_derribar()
		end
	end
	if info.herida then
		self:_abrirHerida(z, info.duracionHerida or 12)
	end
	Estados.aplicar(self, info)
	self:_danio(danio)
end

function Sekhmaur:_abrirHerida(z, duracion: number)
	local h = self.heridas[z.nombre]
	if h then
		h.t = math.max(h.t, duracion)
		return
	end
	local marca = Instance.new("Part")
	marca.Anchored = true
	marca.CanCollide = false
	marca.CanQuery = false
	marca.Material = Enum.Material.Neon
	marca.Color = Color3.fromRGB(255, 60, 50)
	marca.Transparency = 0.7
	marca.Size = Vector3.one * z.r * S * 2.1
	marca.Parent = workspace
	self.heridas[z.nombre] = { t = duracion, marca = marca, zona = z }
end

function Sekhmaur:_danio(danio: number)
	if self.muerto then
		return
	end
	self.vida -= danio
	if not self.fase2 and self.vida < self.vidaMax * 0.5 and self.vida > 0 then
		self:_despertar(false)
	end
	if not self.furioso and self.vida < self.vidaMax * 0.4 and self.vida > 0 then
		self.furioso = true
		self.servicios.anunciar("¡Sekhmaur está furioso!", Color3.fromRGB(255, 138, 106))
	end
	if self.vida <= 0 then
		self.vida = 0
		self:_morir()
	end
end

function Sekhmaur:_romper(id: string)
	local p = self.partes[id]
	p.rota = true
	p.vida = 0
	table.insert(self.caceria.partes, id)
	self.servicios.anunciar("¡Rompiste: " .. p.nombre .. "!", Color3.fromRGB(255, 224, 138))
	if id == "melena" then
		self:_despertar(true)
		return
	elseif id == "aguijon" then
		self.aguijon.Transparency = 1
	elseif id == "tocado" then
		for _, t in self.tocado do
			if t.Name == "Cobra" or t.Name == "Gema" or t.Name == "Banda" then
				t.Transparency = 1
			end
		end
	end
	if self.estado ~= "derribado" and self.estado ~= "muerto" then
		self:_ocultarAvisos()
		self.enterrado = false
		self:_cambiar("estremecer")
	end
end

-- Segunda fase: cae la arena de la melena y despierta el guardián.
function Sekhmaur:_despertar(porRomper: boolean)
	if self.fase2 then
		return
	end
	self.fase2 = true
	for _, p in self.melena do
		p.Transparency = 1
	end
	self.particulasMelena.Enabled = false
	for i = 1, 3 do
		local monton = Instance.new("Part")
		monton.Anchored = true
		monton.CanCollide = false
		monton.Material = Enum.Material.Sand
		monton.Color = C.arena
		monton.Size = V(2.5, 2.5, 2.5)
		local p = self.pos + Vector3.new(math.random(-4, 4) * S, 0, math.random(-4, 4) * S)
		monton.Position = Vector3.new(p.X, Config.altura(p.X, p.Z) - 1.5, p.Z)
		monton.Parent = workspace
		game:GetService("Debris"):AddItem(monton, 40)
	end
	for _, t in self.tocado do
		t.Transparency = 0
	end
	for _, g in self.glifos do
		g.Transparency = 0
	end
	for _, o in self.ojos do
		o.Color = C.turquesa
	end
	self.aguijon.Color = C.oro
	Mundo.cieloGuardian(true)
	self.servicios.anunciar(porRomper and "¡La melena se deshace! Despierta el guardián" or "¡Despierta el guardián de las dunas!", Color3.fromRGB(63, 208, 200))
	if not self.muerto and self.estado ~= "derribado" then
		self:_ocultarAvisos()
		self.enterrado = false
		self.rugio = false
		self:_cambiar("rugir")
	end
end

function Sekhmaur:_derribar()
	self.caceria.derribos += 1
	self:_ocultarAvisos()
	self.enterrado = false
	self.derribo = 0
	self.derriboMax *= 1.3
	self:_polvo(self.pos, 60)
	self.servicios.anunciar("¡Sekhmaur cayó! Aprovecha", Color3.fromRGB(63, 208, 200))
	self:_cambiar("derribado")
end

function Sekhmaur:_morir()
	self.muerto = true
	self:_ocultarAvisos()
	self.enterrado = false
	for nombre, h in self.heridas do
		h.marca:Destroy()
		self.heridas[nombre] = nil
	end
	self:_cambiar("muerto")
	self:_terminarCaceria(true)
end

-- Un cazador se desmayó. Con tres, la cacería fracasa.
function Sekhmaur:desmayo(jugador: Player?)
	if jugador and not self.participantes[jugador] then
		return
	end
	if self.caceria.terminada then
		return
	end
	self.caceria.desmayos += 1
	self.servicios.anunciar(("Desmayos del grupo: %d/3"):format(self.caceria.desmayos), Color3.fromRGB(255, 138, 106))
	if self.caceria.desmayos >= 3 then
		self:_terminarCaceria(false)
		task.delay(8, function()
			if not self.muerto then
				self:reiniciar()
			end
		end)
	end
end

function Sekhmaur:_terminarCaceria(exito: boolean)
	if self.caceria.terminada then
		return
	end
	self.caceria.terminada = true
	local recompensas = {}
	if exito then
		table.insert(recompensas, "+ 200 monedas")
		table.insert(recompensas, "+ 6 Escamas de duna")
		table.insert(recompensas, "+ 2 Núcleos del desierto")
	end
	local materiales = { melena = "Arena viva", tocado = "Oro del guardián", aguijon = "Aguijón solar" }
	local claves = { melena = "arena", tocado = "oro", aguijon = "aguijon" }
	local nombres = {}
	local premios = exito and { monedas = 200, escama = 6, nucleo = 2 } or {}
	for _, id in self.caceria.partes do
		table.insert(nombres, DATOS_PARTES[id].nombre)
		table.insert(recompensas, "+ 2 " .. materiales[id])
		premios[claves[id]] = (premios[claves[id]] or 0) + 2
	end
	if self.servicios.recompensar then
		self.servicios.recompensar(premios, self.participantes)
	end
	self.servicios.resultados(self.participantes, {
		behemoth = "Sekhmaur",
		exito = exito,
		tiempo = self.tiempo,
		partes = nombres,
		derribos = self.caceria.derribos,
		desmayos = self.caceria.desmayos,
		recompensas = recompensas,
	})
end

return Sekhmaur
