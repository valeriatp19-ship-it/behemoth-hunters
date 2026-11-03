--!nonstrict
-- Kheprak, el Rodador Solar (elemento Brasa). Todo lo decide el servidor.
-- Ataques: pinza, embestida, salto y su bola solar, que carga frente a él y luego persigue.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Compartido.Config)
local Estados = require(script.Parent.Estados)

local S = Config.S
local ISLA = Config.ISLAS.brasa -- Kheprak vive en el Desierto de Brasa
local O = ISLA.centro
local function sueloBrasa(xm: number, zm: number): Vector3
	local x, z = O.X + xm * S, O.Z + zm * S
	return Vector3.new(x, Config.alturaEn(x, z), z)
end
local C = Config.COLORES
local VIDA_BASE = 7400
local ATAQUES = {
	pinza = { prep = 0.7, activo = 0.25, rec = 0.8, danio = 22, empuje = 9 },
	embestida = { prep = 0.9, activo = 1.3, rec = 1.0, danio = 26, empuje = 18 },
	salto = { prep = 0.8, activo = 0.9, rec = 1.0, danio = 28, empuje = 13 },
	bola = { prep = 4.0, activo = 0.35, rec = 0.8, danio = 0, empuje = 0 },
}
local DATOS_PARTES = {
	cuerno = { nombre = "Cuerno mayor", max = 260 },
	elitros = { nombre = "Élitros", max = 320 },
	patas = { nombre = "Patas traseras", max = 230 },
}
local MULT_ZONA = { cuerpo = 1.0, cabeza = 1.3, pata = 0.9 }
local ZONAS = {
	{ nombre = "torax", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 3.2, -4.4), r = 2.1 },
	{ nombre = "abdomen", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 2.4, 1.0), r = 2.4 },
	{ nombre = "elitro_i", tipo = "cuerpo", parte = "elitros", pos = Vector3.new(-1.3, 3.8, 0), r = 2.0 },
	{ nombre = "elitro_d", tipo = "cuerpo", parte = "elitros", pos = Vector3.new(1.3, 3.8, 0), r = 2.0 },
	{ nombre = "cabeza", tipo = "cabeza", parte = "", pos = Vector3.new(0, 2.4, -6.3), r = 1.5 },
	{ nombre = "cuerno1", tipo = "cabeza", parte = "cuerno", pos = Vector3.new(0, 5.0, -5.6), r = 1.1 },
	{ nombre = "cuerno2", tipo = "cabeza", parte = "cuerno", pos = Vector3.new(0, 4.6, -7.8), r = 1.1 },
	{ nombre = "cuerno3", tipo = "cabeza", parte = "cuerno", pos = Vector3.new(0, 3.3, -8.6), r = 1.0 },
	{ nombre = "pata_fi", tipo = "pata", parte = "", pos = Vector3.new(-3.0, 1.0, -3.0), r = 1.0 },
	{ nombre = "pata_fd", tipo = "pata", parte = "", pos = Vector3.new(3.0, 1.0, -3.0), r = 1.0 },
	{ nombre = "pata_mi", tipo = "pata", parte = "", pos = Vector3.new(-3.0, 1.0, -0.5), r = 1.0 },
	{ nombre = "pata_md", tipo = "pata", parte = "", pos = Vector3.new(3.0, 1.0, -0.5), r = 1.0 },
	{ nombre = "pata_ti", tipo = "pata", parte = "patas", pos = Vector3.new(-3.0, 1.0, 2.2), r = 1.1 },
	{ nombre = "pata_td", tipo = "pata", parte = "patas", pos = Vector3.new(3.0, 1.0, 2.2), r = 1.1 },
}
local PATRULLA = { Vector2.new(60, -20), Vector2.new(95, -40), Vector2.new(40, -110), Vector2.new(-30, -40), Vector2.new(-95, 0), Vector2.new(20, 40) }

local Kheprak = {}
Kheprak.__index = Kheprak

local function V(x, y, z)
	return Vector3.new(x, y, z) * S
end
local function CF(x, y, z)
	return CFrame.new(x * S, y * S, z * S)
end

-- ---------- modelo de bloques ----------
function Kheprak:_parte(props): BasePart
	local p = Instance.new("Part")
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
	p.Material = props.Neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.Name = props.Name or "Pieza"
	p.Size = props.Size
	p.Color = props.Color
	p.Transparency = props.Transparency or 0
	p.Parent = self.modelo
	return p
end

function Kheprak:_unir(p: BasePart, a: BasePart, c0: CFrame, c1: CFrame?, motor: string?)
	local j = Instance.new(motor and "Motor6D" or "Weld")
	j.Part0 = a
	j.Part1 = p
	j.C0 = c0
	j.C1 = c1 or CFrame.new()
	if motor then
		j.Name = motor
	end
	j.Parent = p
end

function Kheprak:_construir()
	local m = Instance.new("Model")
	m.Name = "Kheprak"
	self.modelo = m
	local raiz = Instance.new("Part")
	raiz.Name = "Raiz"
	raiz.Anchored = true
	raiz.CanCollide = false
	raiz.CanQuery = false
	raiz.Transparency = 1
	raiz.Size = Vector3.one
	raiz.Parent = m
	m.PrimaryPart = raiz
	self.raiz = raiz
	local caparazon = Color3.fromRGB(58, 42, 30)
	local oscuro = Color3.fromRGB(42, 29, 20)
	local turquesa = C.turquesa
	local cuerpo = self:_parte({ Name = "Cuerpo", Size = V(4.4, 2.2, 7.0), Color = Color3.fromRGB(90, 58, 34), CanCollide = true })
	self:_unir(cuerpo, raiz, CF(0, 2.3, 0.8), nil, "RaizCuerpo")
	-- élitros (se abren y se pueden romper)
	self.elitros = {}
	for _, lado in { -1, 1 } do
		local nombre = lado < 0 and "ElitroI" or "ElitroD"
		local e = self:_parte({ Name = nombre, Size = V(2.4, 1.6, 7.2), Color = caparazon, CanCollide = true })
		self:_unir(e, cuerpo, CF(lado * 0.1, 1.1, 0), CF(-lado * 1.2, -0.3, 0), nombre)
		local franja = self:_parte({ Name = "Franja", Size = V(0.3, 0.2, 5.6), Color = turquesa, Neon = true })
		self:_unir(franja, e, CF(lado * 0.3, 0.8, 0))
		local borde = self:_parte({ Name = "Borde", Size = V(0.2, 0.3, 7.3), Color = C.oro })
		self:_unir(borde, e, CF(lado * 1.2, -0.6, 0))
		local sol = self:_parte({ Name = "Sol", Size = V(0.9, 0.2, 0.9), Color = C.oro })
		self:_unir(sol, e, CF(lado * 0.4, 0.82, 1.5))
		table.insert(self.elitros, e)
		table.insert(self.elitros, franja)
		table.insert(self.elitros, borde)
		table.insert(self.elitros, sol)
	end
	-- alas (se ven al perder los élitros)
	self.alas = {}
	for _, lado in { -1, 1 } do
		local a = self:_parte({ Name = "Ala", Size = V(2.8, 0.1, 5.4), Color = Color3.fromRGB(220, 140, 40), Transparency = 1 })
		self:_unir(a, cuerpo, CF(lado * 2.2, 1.4, 0.8) * CFrame.Angles(0, 0, lado * 0.3), nil, lado < 0 and "AlaI" or "AlaD")
		a:SetAttribute("SinTextura", true)
		table.insert(self.alas, a)
	end
	-- tórax con cuernos laterales
	local torax = self:_parte({ Name = "Torax", Size = V(4.2, 2.6, 3.0), Color = oscuro, CanCollide = true })
	self:_unir(torax, cuerpo, CF(0, 0.6, -5.0))
	self.torax = torax
	torax:SetAttribute("SinTextura", true) -- se pone al rojo en la segunda fase: queda liso
	local cresta = self:_parte({ Name = "Cresta", Size = V(3.6, 0.2, 2.4), Color = turquesa, Neon = true })
	self:_unir(cresta, torax, CF(0, 1.35, 0))
	for _, lado in { -1, 1 } do
		local c = self:_parte({ Name = "CuernoLado", Size = V(0.5, 1.2, 0.5), Color = oscuro })
		self:_unir(c, torax, CF(lado * 1.8, 1.6, -0.4) * CFrame.Angles(0.3, 0, -lado * 0.4))
	end
	-- cuerno mayor: nace del tórax y se curva por encima de la cabeza
	local base = self:_parte({ Name = "CuernoMayor", Size = V(1.0, 1.0, 1.4), Color = oscuro })
	self:_unir(base, torax, CF(0, 1.5, -0.6), CF(0, -0.3, 0.5), "Cuerno")
	self.cuerno = { base }
	for _, t in { { V(0.85, 0.85, 1.4), CF(0, 0.6, -1.2) }, { V(0.7, 0.7, 1.4), CF(0, 0.7, -2.5) }, { V(0.55, 1.1, 0.55), CF(0, 0.1, -3.4) }, { V(0.4, 0.8, 0.4), CF(0, -0.7, -3.6) } } do
		local seg = self:_parte({ Name = "CuernoTramo", Size = t[1], Color = oscuro })
		self:_unir(seg, base, t[2])
		table.insert(self.cuerno, seg)
	end
	local anillo = self:_parte({ Name = "AnilloCuerno", Size = V(1.1, 0.25, 1.1), Color = C.oro })
	self:_unir(anillo, base, CF(0, 0.2, -0.6))
	table.insert(self.cuerno, anillo)
	-- cabeza con ojos, mandíbulas y el cuerno menor (la pinza)
	local cabeza = self:_parte({ Name = "Cabeza", Size = V(2.4, 1.7, 1.8), Color = oscuro })
	self:_unir(cabeza, torax, CF(0, -0.5, -1.6), CF(0, 0, 0.9), "Cuello")
	for _, lado in { -1, 1 } do
		local ojo = self:_parte({ Name = "Ojo", Size = V(0.4, 0.3, 0.2), Color = Color3.fromRGB(255, 138, 42), Neon = true })
		self:_unir(ojo, cabeza, CF(lado * 0.85, 0.3, -0.9))
		local mand = self:_parte({ Name = "Mandibula", Size = V(0.3, 0.3, 1.0), Color = C.oro })
		self:_unir(mand, cabeza, CF(lado * 0.5, -0.6, -1.1) * CFrame.Angles(0, -lado * 0.4, 0))
	end
	for _, t in { { V(0.5, 1.2, 0.5), CF(0, 1.0, -0.6) }, { V(0.4, 0.7, 0.4), CF(0, 1.8, -0.9) } } do
		local c = self:_parte({ Name = "CuernoMenor", Size = t[1], Color = oscuro })
		self:_unir(c, cabeza, t[2])
	end
	-- seis patas articuladas
	for _, p in { { "FI", -1, -3.0 }, { "FD", 1, -3.0 }, { "MI", -1, -0.5 }, { "MD", 1, -0.5 }, { "TI", -1, 2.2 }, { "TD", 1, 2.2 } } do
		local n, lado, z = p[1], p[2], p[3]
		local muslo = self:_parte({ Name = "Muslo" .. n, Size = V(1.8, 0.6, 0.6), Color = oscuro, CanCollide = true })
		self:_unir(muslo, cuerpo, CF(lado * 2.1, -0.2, z - 0.8), CF(-lado * 0.9, 0, 0), "Cadera" .. n)
		local pierna = self:_parte({ Name = "Pierna" .. n, Size = V(0.5, 2.3, 0.5), Color = caparazon })
		self:_unir(pierna, muslo, CF(lado * 0.9, 0, 0), CF(0, 1.1, 0), "Rodilla" .. n)
		local pie = self:_parte({ Name = "Pie", Size = V(0.6, 0.3, 0.8), Color = C.oro })
		self:_unir(pie, pierna, CF(0, -1.2, -0.1))
	end
	-- avisos rojos
	local function aviso(nombre, forma)
		local a = Instance.new("Part")
		a.Name = nombre
		a.Anchored = true
		a.CanCollide = false
		a.CanQuery = false
		a.CanTouch = false
		a.Material = Enum.Material.Neon
		a.Color = Color3.fromRGB(255, 70, 40)
		a.Transparency = 1
		a.Shape = forma
		a.Size = Vector3.new(0.3, 1, 1)
		a.Parent = workspace
		return a
	end
	self.avisoCirculo = aviso("AvisoCirculoK", Enum.PartType.Cylinder)
	self.avisoRect = aviso("AvisoRectK", Enum.PartType.Block)
	m:SetAttribute("Nombre", "Kheprak")
	m:SetAttribute("Mapa", "brasa")
	m:SetAttribute("Partes", "cuerno:Cuerno mayor;elitros:Élitros;patas:Patas traseras")
	-- con streaming activado, Roblox manda los modelos por partes: el Behemoth debe llegar
	-- completo a todos los jugadores para que su animación y sus partes funcionen
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m.Parent = workspace:FindFirstChild("Behemoths") or workspace
end

-- ---------- vida y estado ----------
function Kheprak.nuevo(servicios)
	local self = setmetatable({}, Kheprak)
	self.servicios = servicios
	self:_construir()
	self:reiniciar()
	return self
end

function Kheprak:reiniciar()
	local n = math.max(1, #self.servicios.jugadores("brasa"))
	self.vidaMax = VIDA_BASE * (1 + 0.6 * (n - 1))
	self.vida = self.vidaMax
	self.estado = "vagar"
	self.alerta, self.fase2, self.furioso, self.muerto = false, false, false, false
	self.enterrado = false
	self.derribo, self.derriboMax = 0, 230
	self.heridas = {}
	self.t, self.reloj, self.cd, self.cdBola, self.lejos, self.espera = 0, 0, 2, 6, 0, 0
	self.tiempo = 0
	self.destino = nil
	self.caceria = { partes = {}, derribos = 0, desmayos = 0, terminada = false }
	self.participantes = {}
	Estados.iniciar(self)
	self.partes = {}
	for id, d in DATOS_PARTES do
		self.partes[id] = { nombre = d.nombre, max = d.max, vida = d.max, rota = false }
	end
	for _, p in self.elitros do
		p.Transparency = 0
	end
	for _, a in self.alas do
		a.Transparency = 1
	end
	for _, c in self.cuerno do
		c.Transparency = 0
	end
	self.torax.Material = Enum.Material.SmoothPlastic
	self.torax.Color = Color3.fromRGB(42, 29, 20)
	self:_quitarBola()
	local p = PATRULLA[math.random(1, #PATRULLA)]
	self.pos = sueloBrasa(p.X, p.Y)
	self.yVisual = self.pos.Y
	self.yaw = math.random() * math.pi * 2
	self:_ocultarAvisos()
	self:_anim("reposo")
	self:_publicar()
end

function Kheprak:_anim(nombre: string, ritmo: number?)
	if self.modelo:GetAttribute("Anim") ~= nombre then
		self.modelo:SetAttribute("Anim", nombre)
		self.modelo:SetAttribute("AnimT0", workspace:GetServerTimeNow())
	end
	self.modelo:SetAttribute("Ritmo", ritmo or 1)
end

function Kheprak:_publicar()
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
		m:SetAttribute("P_" .. id, p.rota and -1 or p.vida / p.max)
	end
end

function Kheprak:_adelante(): Vector3
	return CFrame.Angles(0, self.yaw, 0).LookVector
end

function Kheprak:_yawHacia(p: Vector3): number
	local d = p - self.pos
	return math.atan2(-d.X, -d.Z)
end

function Kheprak:_girarHacia(yaw: number, rapidez: number, dt: number)
	local dif = (yaw - self.yaw + math.pi) % (math.pi * 2) - math.pi
	self.yaw += math.clamp(dif, -rapidez * dt, rapidez * dt)
end

function Kheprak:_angulo(p: Vector3): number
	return math.abs((self:_yawHacia(p) - self.yaw + math.pi) % (math.pi * 2) - math.pi)
end

function Kheprak:_dist(p: Vector3): number
	return Vector2.new(p.X - self.pos.X, p.Z - self.pos.Z).Magnitude / S
end

local function fueraDeObstaculos(pos: Vector3, margen: number): (Vector3, boolean)
	-- las agujas de obsidiana del Desierto de Brasa
	local choco = false
	for _, o in Config.OBSTACULOS_BRASA do
		local c = Vector2.new(O.X + o[1] * S, O.Z + o[2] * S)
		local d = Vector2.new(pos.X, pos.Z) - c
		local r = (o[3] + margen) * S
		if d.Magnitude < r then
			choco = true
			local n = d.Magnitude > 0.01 and d.Unit or Vector2.new(1, 0)
			local q = c + n * r
			pos = Vector3.new(q.X, pos.Y, q.Y)
		end
	end
	return pos, choco
end
Kheprak.fueraDeObstaculos = fueraDeObstaculos

function Kheprak:_mover(dt: number, velocidad: number): boolean
	local nueva = self.pos + self:_adelante() * velocidad * Estados.freno(self) * S * dt
	local choco
	nueva, choco = fueraDeObstaculos(nueva, 2.6)
	local centro = Vector2.new(O.X, O.Z)
	local plano = Vector2.new(nueva.X, nueva.Z)
	if (plano - centro).Magnitude > 130 * S then
		plano = centro + (plano - centro).Unit * 130 * S
		choco = true
	end
	local camp = centro + ISLA.campamento * S
	local alCamp = plano - camp
	if alCamp.Magnitude < 26 * S then
		plano = camp + alCamp.Unit * 26 * S
		self.destino = nil
	end
	self.pos = Vector3.new(plano.X, Config.alturaEn(plano.X, plano.Y), plano.Y)
	return choco
end

function Kheprak:_elegirObjetivo(dt: number)
	self.tObjetivo = (self.tObjetivo or 0) - dt
	local valido = false
	if self.objetivo then
		for _, j in self.servicios.jugadores("brasa") do
			if j.hrp == self.objetivo.hrp and j.atacable then
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
	for _, j in self.servicios.jugadores("brasa") do
		local d = self:_dist(j.hrp.Position)
		if j.atacable and d < mejorD then
			mejor, mejorD = j, d
		end
	end
	self.objetivo = mejor
end

function Kheprak:_posObjetivo(): Vector3
	return self.objetivo and self.objetivo.hrp.Position or self.pos
end

-- ---------- ciclo principal ----------
function Kheprak:paso(dt: number)
	self.reloj += dt
	self.t += dt
	self.cdBola -= dt
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
	Estados.paso(self, dt)
	for nombre, h in self.heridas do
		h.t -= dt
		if h.t <= 0 then
			h.marca:Destroy()
			self.heridas[nombre] = nil
		else
			h.marca.CFrame = self.raiz.CFrame * CFrame.new(h.zona.pos * S)
		end
	end
	if self.alerta and not self.muerto then
		self.tiempo += dt
	end
	local hay = self.objetivo ~= nil
	if not self.muerto and not self.alerta and hay and self:_dist(self:_posObjetivo()) < 20 and (self.estado == "vagar" or self.estado == "escarbar") then
		self:_alertar()
	end
	if self.alerta and not self.muerto and self.estado == "perseguir" then
		self.lejos = (not hay or self:_dist(self:_posObjetivo()) > 70) and self.lejos + dt or 0
		if self.lejos > 6 then
			self.alerta = false
			self.lejos = 0
			self:_cambiar("vagar")
		end
	end
	local e = self.estado
	local mueveSolo = true
	if e == "vagar" then
		self:_vagar(dt)
	elseif e == "escarbar" then
		self:_anim("escarbar")
		if self.t > 4 then
			self:_cambiar("vagar")
		end
	elseif e == "rugir" then
		self:_anim("rugir")
		if self.t > 2 then
			self:_cambiar("perseguir")
			self.cd = 1
		end
	elseif e == "perseguir" then
		self:_perseguir(dt)
	elseif e == "ataque" then
		mueveSolo = self:_ataque(dt)
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
	if mueveSolo ~= false then
		self.yVisual += (self.pos.Y - self.yVisual) * math.min(1, dt * 8)
	end
	self.raiz.CFrame = CFrame.new(self.pos.X, self.yVisual, self.pos.Z) * CFrame.Angles(0, self.yaw, 0)
	if self.avisoCirculo.Transparency < 1 then
		self.avisoCirculo.Transparency = 0.35 + 0.25 * math.sin(self.reloj * 14)
	end
	if self.avisoRect.Transparency < 1 then
		self.avisoRect.Transparency = 0.35 + 0.25 * math.sin(self.reloj * 14)
	end
	if self.fase2 and not self.muerto then
		local k = 0.5 + 0.5 * math.sin(self.reloj * (self.furioso and 8 or 3))
		self.torax.Color = Color3.fromRGB(120 + 135 * k, 50 + 40 * k, 20)
	end
	self:_pasoBola(dt)
	self:_publicar()
end

function Kheprak:_cambiar(nuevo: string)
	self.estado = nuevo
	self.t = 0
end

function Kheprak:_vagar(dt: number)
	if self.espera > 0 then
		self.espera -= dt
		self:_anim("reposo")
		return
	end
	if not self.destino then
		local p = PATRULLA[math.random(1, #PATRULLA)]
		self.destino = sueloBrasa(p.X + math.random(-12, 12), p.Y + math.random(-12, 12))
	end
	if self:_dist(self.destino) < 4 then
		self.destino = nil
		if math.random() < 0.5 then
			self:_cambiar("escarbar")
		else
			self.espera = math.random(15, 40) / 10
		end
		return
	end
	self:_girarHacia(self:_yawHacia(self.destino), 1.4, dt)
	if self:_mover(dt, 3.8) then
		self.destino = nil
	end
	self:_anim("caminar", 1.1)
end

function Kheprak:_alertar()
	if self.alerta or self.muerto then
		return
	end
	self.alerta = true
	self.lejos = 0
	self:_cambiar("rugir")
	self.servicios.anunciar("¡Kheprak te ha detectado!", Color3.fromRGB(255, 138, 106))
end

function Kheprak:_perseguir(dt: number)
	if not self.objetivo then
		self:_anim("reposo")
		return
	end
	local objetivo = self:_posObjetivo()
	local dist = self:_dist(objetivo)
	self:_girarHacia(self:_yawHacia(objetivo), self.furioso and 2.4 or 1.9, dt)
	if dist > 7 then
		local v = self.furioso and 7 or 5.8
		self:_mover(dt, v)
		self:_anim("correr", v / 5.8)
	else
		self:_anim("reposo")
	end
	self.cd -= dt
	if self.cd <= 0 then
		local ang = self:_angulo(objetivo)
		local op = {}
		if dist < 9 and ang < 0.6 then
			table.insert(op, { "pinza", 3 })
		end
		if dist > 10 and dist < 40 and ang < 0.5 then
			table.insert(op, { "embestida", 2 })
		end
		if dist < 24 then
			table.insert(op, { "salto", self.fase2 and 3 or 1.8 })
		end
		if dist > 5 and self.cdBola <= 0 and not self.bola then
			table.insert(op, { "bola", 5 })
		end
		if #op == 0 then
			self.cd = 0.3
			return
		end
		local total = 0
		for _, o in op do
			total += o[2]
		end
		local r = math.random() * total
		for _, o in op do
			r -= o[2]
			if r <= 0 then
				self:_iniciarAtaque(o[1])
				return
			end
		end
		self:_iniciarAtaque(op[1][1])
	end
end

function Kheprak:_duraciones()
	local d = ATAQUES[self.ataque]
	local k = (self.furioso and 1.2 or 1) * (self.fase2 and 1.15 or 1)
	local prep = d.prep / k
	if self.ataque == "bola" then
		prep = (self.fase2 and 2.8 or 4.0) / (self.furioso and 1.2 or 1)
	end
	return prep, d.activo / k, d.rec / k
end

function Kheprak:_iniciarAtaque(nombre: string)
	self:_cambiar("ataque")
	self.ataque = nombre
	self.fase = ""
	self.tFase = 0
	self.golpeados = {}
	self.hecho = false
	self:_anim(nombre == "bola" and "bola_carga" or (nombre == "embestida" and "embestida_carga" or nombre))
	if nombre == "bola" then
		self:_crearBola()
		self.servicios.anunciar("¡Kheprak está cargando su bola solar!", Color3.fromRGB(255, 179, 71))
	end
end

function Kheprak:_terminarAtaque()
	self:_ocultarAvisos()
	if self.ataque == "bola" then
		self.cdBola = self.fase2 and 9 or 12
	end
	self:_cambiar("perseguir")
	self.cd = (math.random(5, 13) / 10) * (self.furioso and 0.6 or 1)
end

function Kheprak:_golpear(prueba, origen: Vector3)
	local d = ATAQUES[self.ataque]
	local mult = (self.ataque == "embestida" and self.partes.cuerno.rota) and 0.7 or 1
	for _, j in self.servicios.jugadores("brasa") do
		if j.atacable and not self.golpeados[j.hrp] and prueba(j.hrp.Position) then
			self.golpeados[j.hrp] = true
			self.servicios.danio(j.jugador, d.danio * mult * (self.furioso and 1.15 or 1), origen, d.empuje, self.ataque)
		end
	end
end

local function plano(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude / S
end

function Kheprak:_ataque(dt: number): boolean
	local prep, act, rec = self:_duraciones()
	self.tFase += dt
	local nueva, inicio = "prep", 0
	if self.tFase >= prep + act + rec then
		self:_terminarAtaque()
		return true
	elseif self.tFase >= prep + act then
		nueva, inicio = "rec", prep + act
	elseif self.tFase >= prep then
		nueva, inicio = "activo", prep
	end
	if nueva ~= self.fase then
		self.fase = nueva
		self.hecho = false
		self.inicioFase = inicio
		if self.ataque == "embestida" and nueva == "activo" then
			self:_anim("correr", 2.2)
		elseif self.ataque == "bola" and nueva == "activo" then
			self:_anim("lanzar_bola")
		elseif nueva == "rec" and self.ataque ~= "salto" then
			self:_anim("reposo")
		end
	end
	local tf = self.tFase - self.inicioFase
	local adelante = self:_adelante()
	local objetivo = self:_posObjetivo()
	local a = self.ataque
	if a == "pinza" then
		local punto = self.pos + adelante * 7.5 * S
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			self:_avisoCirculo(punto, 3.4)
		elseif self.fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(punto, 20)
			self:_golpear(function(p)
				return plano(p, punto) < 3.4
			end, punto)
		end
	elseif a == "embestida" then
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 4, dt)
			self:_avisoRect(self.pos, self.yaw, 6, 30)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self:_girarHacia(self:_yawHacia(objetivo), 0.5, dt)
			local v = (self.furioso and 22 or 18) * (self.partes.cuerno.rota and 0.75 or 1)
			local choco = self:_mover(dt, v)
			self:_golpear(function(p)
				return plano(p, self.pos + adelante * 6.5 * S) < 3.2 or plano(p, self.pos) < 3.8
			end, self.pos)
			if choco then
				self.servicios.anunciar("¡Kheprak se estrelló!", Color3.fromRGB(255, 224, 138))
				self:_polvo(self.pos + adelante * 6 * S, 30)
				self:_cambiar("estremecer")
			end
		else
			self:_mover(dt, math.max(0, 14 * (1 - tf / rec)))
		end
	elseif a == "salto" then
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			if tf < prep - 0.25 then
				self.saltoDesde = self.pos
				self.saltoHasta = Vector3.new(objetivo.X, 0, objetivo.Z)
			end
			self:_avisoCirculo(self.saltoHasta or self.pos, 5.5)
		elseif self.fase == "activo" then
			local k = math.clamp(tf / act, 0, 1)
			local p = self.saltoDesde:Lerp(self.saltoHasta, k)
			local nuevo = fueraDeObstaculos(Vector3.new(p.X, 0, p.Z), 2.6)
			self.pos = Vector3.new(nuevo.X, Config.alturaEn(nuevo.X, nuevo.Z), nuevo.Z)
			self.yVisual = self.pos.Y + math.sin(k * math.pi) * 7 * S
			return false
		elseif self.fase == "rec" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(self.pos, 60)
			self:_golpear(function(p)
				return plano(p, self.pos) < 5.5
			end, self.pos)
		end
	elseif a == "bola" then
		if self.fase == "prep" and self.bola then
			self:_girarHacia(self:_yawHacia(objetivo), 1.2, dt)
			local r = 0.6 + (2.3 - 0.6) * math.clamp(tf / prep, 0, 1)
			self.bola.radio = r
			local frente = self.pos + adelante * (9.5 + r) * S
			self.bola.pos = Vector3.new(frente.X, Config.alturaEn(frente.X, frente.Z) + r * S, frente.Z)
		elseif self.fase == "activo" and not self.hecho and self.bola then
			self.hecho = true
			self.bola.rodando = true
			self.bola.t = 0
			local d = objetivo - self.bola.pos
			self.bola.dir = Vector3.new(d.X, 0, d.Z).Magnitude > 0.1 and Vector3.new(d.X, 0, d.Z).Unit or adelante
		end
	end
	return true
end

-- ---------- la bola solar ----------
function Kheprak:_crearBola()
	local parte = Instance.new("Part")
	parte.Name = "BolaSolar"
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanQuery = false
	parte.Material = Enum.Material.Neon
	parte.Color = Color3.fromRGB(232, 120, 30)
	parte.Size = Vector3.one * 2
	parte.Parent = workspace
	local costra = {}
	for i = 1, 6 do
		local c = Instance.new("Part")
		c.Anchored = true
		c.CanCollide = false
		c.CanQuery = false
		c.Color = Color3.fromRGB(130, 50, 16)
		c.Size = Vector3.one
		c.Parent = parte
		costra[i] = { c, Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit }
	end
	local fuego = Instance.new("Fire")
	fuego.Heat = 6
	fuego.Size = 6
	fuego.Parent = parte
	self.bola = { parte = parte, costra = costra, radio = 0.6, pos = self.pos, vida = 140, rodando = false, t = 0, dir = self:_adelante(), tRastro = 0, giro = 0 }
end

function Kheprak:_quitarBola()
	if self.bola then
		self.bola.parte:Destroy()
		self.bola = nil
	end
end

function Kheprak:_pasoBola(dt: number)
	local b = self.bola
	if not b then
		return
	end
	if b.rodando then
		b.t += dt
		-- persigue al cazador más cercano
		local cazador, mejor = nil, math.huge
		for _, j in self.servicios.jugadores("brasa") do
			local d = (j.hrp.Position - b.pos).Magnitude
			if j.atacable and d < mejor then
				cazador, mejor = j, d
			end
		end
		local rapidez = (self.furioso and 7.8 or 6.8) * S
		if cazador then
			local hacia = cazador.hrp.Position - b.pos
			hacia = Vector3.new(hacia.X, 0, hacia.Z)
			if hacia.Magnitude > 0.1 then
				local actual = math.atan2(b.dir.X, b.dir.Z)
				local desea = math.atan2(hacia.X, hacia.Z)
				local dif = (desea - actual + math.pi) % (math.pi * 2) - math.pi
				local ang = actual + math.clamp(dif, -1.3 * dt, 1.3 * dt)
				b.dir = Vector3.new(math.sin(ang), 0, math.cos(ang))
			end
			if plano(cazador.hrp.Position, b.pos) < b.radio + 1.0 then
				self.servicios.danio(cazador.jugador, 18 + b.radio * 9, b.pos, 14, "bola")
				self:_estallarBola(false, true)
				return
			end
		end
		local siguiente = b.pos + b.dir * rapidez * dt
		local corregida, choco = fueraDeObstaculos(Vector3.new(siguiente.X, 0, siguiente.Z), b.radio)
		if choco then
			self:_estallarBola(false)
			return
		end
		b.pos = Vector3.new(corregida.X, Config.alturaEn(corregida.X, corregida.Z) + b.radio * S, corregida.Z)
		b.giro += rapidez * dt / (b.radio * S)
		b.tRastro -= dt
		if b.tRastro <= 0 then
			b.tRastro = 0.3
			self:_rastro(b.pos)
		end
		if b.t > 7 then
			self:_estallarBola(false)
			return
		end
	end
	local tam = b.radio * 2 * S
	b.parte.Size = Vector3.one * tam
	local cf = CFrame.new(b.pos) * CFrame.fromAxisAngle(Vector3.new(b.dir.Z, 0, -b.dir.X), -b.giro)
	b.parte.CFrame = cf
	for _, c in b.costra do
		c[1].Size = Vector3.one * tam * 0.3
		c[1].CFrame = cf * CFrame.new(c[2] * tam * 0.48)
	end
end

function Kheprak:_rastro(pos: Vector3)
	local mancha = Instance.new("Part")
	mancha.Anchored = true
	mancha.CanCollide = false
	mancha.CanQuery = false
	mancha.Material = Enum.Material.Neon
	mancha.Color = Color3.fromRGB(255, 106, 26)
	mancha.Transparency = 0.3
	mancha.Size = Vector3.new(2.4 * S, 0.3, 2.4 * S)
	mancha.Position = Vector3.new(pos.X, Config.alturaEn(pos.X, pos.Z) + 0.2, pos.Z)
	mancha.Parent = workspace
	local fuego = Instance.new("Fire")
	fuego.Size = 3
	fuego.Heat = 4
	fuego.Parent = mancha
	Debris:AddItem(mancha, 3)
	task.spawn(function()
		local golpeado = {}
		for _ = 1, 5 do
			for _, j in self.servicios.jugadores("brasa") do
				if j.atacable and plano(j.hrp.Position, mancha.Position) < 1.3 and not golpeado[j.hrp] then
					self.servicios.danio(j.jugador, 5, mancha.Position, 0, "fuego")
					golpeado[j.hrp] = true
				end
			end
			task.wait(0.6)
			table.clear(golpeado)
		end
	end)
end

function Kheprak:_estallarBola(interrumpida: boolean, yaGolpeo: boolean?)
	local b = self.bola
	if not b then
		return
	end
	self:_polvo(b.pos, 50, Color3.fromRGB(255, 154, 46))
	if not interrumpida and not yaGolpeo then
		for _, j in self.servicios.jugadores("brasa") do
			if j.atacable and plano(j.hrp.Position, b.pos) < b.radio * 2 + 2.5 then
				self.servicios.danio(j.jugador, 14 + b.radio * 6, b.pos, 12, "bola")
			end
		end
	end
	self:_quitarBola()
	if interrumpida and not self.muerto then
		self.servicios.anunciar("¡Rompiste la bola solar! Kheprak cae", Color3.fromRGB(63, 208, 200))
		self:_derribar()
	end
end

-- ---------- avisos y efectos ----------
function Kheprak:_avisoCirculo(centro: Vector3, radio: number)
	local c = self.avisoCirculo
	if c.Transparency >= 1 then
		c.Transparency = 0.4
	end
	c.Size = Vector3.new(0.3, radio * 2 * S, radio * 2 * S)
	c.CFrame = CFrame.new(centro.X, Config.alturaEn(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, 0, math.rad(90))
end

function Kheprak:_avisoRect(inicio: Vector3, yaw: number, ancho: number, largo: number)
	local r = self.avisoRect
	if r.Transparency >= 1 then
		r.Transparency = 0.4
	end
	local dir = CFrame.Angles(0, yaw, 0).LookVector
	local centro = inicio + dir * largo * 0.5 * S
	r.Size = Vector3.new(ancho * S, 0.3, largo * S)
	r.CFrame = CFrame.new(centro.X, Config.alturaEn(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, yaw, 0)
end

function Kheprak:_ocultarAvisos()
	self.avisoCirculo.Transparency = 1
	self.avisoRect.Transparency = 1
end

function Kheprak:_polvo(pos: Vector3, cantidad: number, color: Color3?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = Vector3.new(pos.X, Config.alturaEn(pos.X, pos.Z) + 1, pos.Z)
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color or Color3.fromRGB(217, 178, 122))
	e.Size = NumberSequence.new(0.9, 0)
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(10, 25)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -20, 0)
	e.Rate = 0
	e.Parent = p
	e:Emit(cantidad)
	Debris:AddItem(p, 3)
end

-- ---------- recibir golpes ----------
function Kheprak:zonas()
	if self.muerto then
		return {}
	end
	local lista = {}
	local cf = self.raiz.CFrame
	for _, z in ZONAS do
		table.insert(lista, { zona = z, pos = (cf * CFrame.new(z.pos * S)).Position, r = z.r * S })
	end
	-- la bola solar también se puede golpear
	if self.bola then
		table.insert(lista, { zona = { nombre = "bola", tipo = "cuerpo", parte = "bola" }, pos = self.bola.pos, r = (self.bola.radio + 0.4) * S })
	end
	return lista
end

function Kheprak:recibirGolpe(z, info, jugador: Player?)
	if self.muerto then
		return
	end
	if jugador then
		self.participantes[jugador] = true
	end
	if z.parte == "bola" then
		self:_golpearBola(info)
		return
	end
	-- golpear las patas mientras carga la bola también la debilita
	if z.tipo == "pata" and self.bola and not self.bola.rodando then
		self:_golpearBola(info)
	end
	local parte = z.parte
	if parte == "elitros" and self.fase2 then
		parte = ""
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
		local h = self.heridas[z.nombre]
		if h then
			h.t = math.max(h.t, info.duracionHerida or 12)
		else
			local marca = Instance.new("Part")
			marca.Anchored = true
			marca.CanCollide = false
			marca.CanQuery = false
			marca.Material = Enum.Material.Neon
			marca.Color = Color3.fromRGB(255, 60, 50)
			marca.Transparency = 0.7
			marca.Size = Vector3.one * z.r * S * 2
			marca.Parent = workspace
			self.heridas[z.nombre] = { t = info.duracionHerida or 12, marca = marca, zona = z }
		end
	end
	Estados.aplicar(self, info)
	self:_danio(danio)
end

function Kheprak:_golpearBola(info)
	local b = self.bola
	if not b then
		return
	end
	local danio = info.danio * (info.fuerte and 1.5 or 1)
	b.vida -= danio
	self.servicios.numero(b.pos + Vector3.new(0, b.radio * S + 2, 0), tostring(math.floor(danio + 0.5)), Color3.fromRGB(255, 179, 71), info.fuerte)
	if b.vida <= 0 then
		self:_estallarBola(not b.rodando)
	end
end

function Kheprak:_danio(danio: number)
	if self.muerto then
		return
	end
	self.vida -= danio
	if not self.fase2 and self.vida < self.vidaMax * 0.5 and self.vida > 0 then
		self:_calentarse(false)
	end
	if not self.furioso and self.vida < self.vidaMax * 0.4 and self.vida > 0 then
		self.furioso = true
		self.servicios.anunciar("¡Kheprak está furioso!", Color3.fromRGB(255, 138, 106))
	end
	if self.vida <= 0 then
		self.vida = 0
		self:_morir()
	end
end

function Kheprak:_romper(id: string)
	local p = self.partes[id]
	p.rota = true
	p.vida = 0
	table.insert(self.caceria.partes, id)
	self.servicios.anunciar("¡Rompiste: " .. p.nombre .. "!", Color3.fromRGB(255, 224, 138))
	if id == "cuerno" then
		for _, c in self.cuerno do
			c.Transparency = 1
		end
	elseif id == "elitros" then
		self:_calentarse(true)
		return
	elseif id == "patas" then
		self.cdBola = math.max(self.cdBola, 18)
	end
	if self.estado ~= "derribado" and self.estado ~= "muerto" then
		self:_ocultarAvisos()
		if self.bola and not self.bola.rodando then
			self:_quitarBola()
		end
		self:_cambiar("estremecer")
	end
end

-- Segunda fase: pierde los élitros, se le ven las alas y el tórax se pone al rojo.
function Kheprak:_calentarse(porRomper: boolean)
	if self.fase2 then
		return
	end
	self.fase2 = true
	for _, p in self.elitros do
		p.Transparency = 1
	end
	for _, a in self.alas do
		a.Transparency = 0.45
	end
	self.torax.Material = Enum.Material.Neon
	self:_polvo(self.pos, 60, Color3.fromRGB(255, 154, 46))
	self.servicios.anunciar(porRomper and "¡Kheprak pierde los élitros y se calienta!" or "¡El caparazón de Kheprak se pone al rojo!", Color3.fromRGB(255, 138, 106))
	if not self.muerto and self.estado ~= "derribado" then
		self:_ocultarAvisos()
		if self.bola and not self.bola.rodando then
			self:_quitarBola()
		end
		self:_cambiar("rugir")
	end
end

function Kheprak:_derribar()
	self.caceria.derribos += 1
	self:_ocultarAvisos()
	if self.bola and not self.bola.rodando then
		self:_quitarBola()
	end
	self.derribo = 0
	self.derriboMax *= 1.3
	self:_polvo(self.pos, 60)
	self.servicios.anunciar("¡Kheprak quedó boca arriba! Ataca su vientre", Color3.fromRGB(63, 208, 200))
	self:_cambiar("derribado")
end

function Kheprak:_morir()
	self.muerto = true
	self:_ocultarAvisos()
	self:_quitarBola()
	for nombre, h in self.heridas do
		h.marca:Destroy()
		self.heridas[nombre] = nil
	end
	self:_cambiar("muerto")
	self:_terminarCaceria(true)
end

function Kheprak:desmayo(jugador: Player?)
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

function Kheprak:_terminarCaceria(exito: boolean)
	if self.caceria.terminada then
		return
	end
	self.caceria.terminada = true
	local nombresMat = { cuerno = "Cuerno de Kheprak", elitros = "Élitro solar", patas = "Quitina ardiente" }
	local claves = { cuerno = "cuerno", elitros = "elitro", patas = "quitina" }
	local recompensas = exito and { "+ 250 monedas", "+ 6 Escamas de duna", "+ 2 Núcleos del desierto" } or {}
	local premios = exito and { monedas = 250, escama = 6, nucleo = 2 } or {}
	local nombres = {}
	for _, id in self.caceria.partes do
		table.insert(nombres, DATOS_PARTES[id].nombre)
		table.insert(recompensas, "+ 2 " .. nombresMat[id])
		premios[claves[id]] = (premios[claves[id]] or 0) + 2
	end
	self.servicios.recompensar(premios, self.participantes)
	self.servicios.resultados(self.participantes, {
		behemoth = "Kheprak",
		exito = exito,
		tiempo = self.tiempo,
		partes = nombres,
		derribos = self.caceria.derribos,
		desmayos = self.caceria.desmayos,
		recompensas = recompensas,
	})
end

return Kheprak
