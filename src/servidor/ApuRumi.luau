--!nonstrict
-- Apu Rumi, el Guardián de la Montaña (elemento Sol): un gorila de piedra de las Cumbres del Inti.
-- Ataques: puñetazo, carga a cuatro patas, lanzar una roca, salto, golpe de pecho y (con la piedra
-- agrietada) un rayo de sol desde el disco del pecho.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Compartido.Config)
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Estados = require(script.Parent.Estados)

local S = Config.S
local VIDA_BASE = 8600
local ATAQUES = {
	punetazo = { prep = 0.8, activo = 0.25, rec = 0.9, danio = 26, empuje = 11 },
	carga = { prep = 0.9, activo = 1.3, rec = 1.0, danio = 26, empuje = 18 },
	roca = { prep = 1.0, activo = 0.9, rec = 0.7, danio = 24, empuje = 12 },
	salto = { prep = 0.8, activo = 0.9, rec = 1.0, danio = 30, empuje = 14 },
	pecho = { prep = 0.7, activo = 0.3, rec = 0.9, danio = 12, empuje = 20 },
	rayo_sol = { prep = 1.1, activo = 0.7, rec = 1.0, danio = 28, empuje = 10 },
}
local DATOS_PARTES = {
	disco = { nombre = "Disco solar", max = 280 },
	punos = { nombre = "Puños", max = 300 },
	nieve = { nombre = "Nieve de los hombros", max = 240 },
}
local MULT_ZONA = { cuerpo = 1.0, cabeza = 1.3, pata = 0.9, cola = 1.0 }
local ZONAS = {
	{ nombre = "disco", tipo = "cabeza", parte = "disco", pos = Vector3.new(0, 4.2, -2.3), r = 1.6 },
	{ nombre = "cabeza", tipo = "cabeza", parte = "", pos = Vector3.new(0, 6.6, -1.9), r = 1.5 },
	{ nombre = "torso", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 4.4, 0), r = 2.5 },
	{ nombre = "nieve_i", tipo = "cuerpo", parte = "nieve", pos = Vector3.new(-2.2, 5.9, -0.4), r = 1.9 },
	{ nombre = "nieve_d", tipo = "cuerpo", parte = "nieve", pos = Vector3.new(2.2, 5.9, -0.4), r = 1.9 },
	{ nombre = "nieve_lomo", tipo = "cuerpo", parte = "nieve", pos = Vector3.new(0, 6.0, 0.6), r = 1.9 },
	{ nombre = "puno_i", tipo = "pata", parte = "punos", pos = Vector3.new(-3.2, 0.6, -1.2), r = 1.4 },
	{ nombre = "puno_d", tipo = "pata", parte = "punos", pos = Vector3.new(3.2, 0.6, -1.2), r = 1.4 },
	{ nombre = "brazo_i", tipo = "pata", parte = "", pos = Vector3.new(-3.2, 3.0, -0.8), r = 1.3 },
	{ nombre = "brazo_d", tipo = "pata", parte = "", pos = Vector3.new(3.2, 3.0, -0.8), r = 1.3 },
	{ nombre = "pierna_i", tipo = "pata", parte = "", pos = Vector3.new(-1.4, 1.2, 0.8), r = 1.2 },
	{ nombre = "pierna_d", tipo = "pata", parte = "", pos = Vector3.new(1.4, 1.2, 0.8), r = 1.2 },
}
local PATRULLA = { Vector2.new(30, -50), Vector2.new(60, -10), Vector2.new(40, 40), Vector2.new(-20, -80), Vector2.new(70, -60), Vector2.new(10, 20) }

local ApuRumi = {}
ApuRumi.__index = ApuRumi

local function V(x, y, z)
	return Vector3.new(x, y, z) * S
end
local function CF(x, y, z)
	return CFrame.new(x * S, y * S, z * S)
end
local function plano(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude / S
end

-- ---------- modelo de bloques ----------
function ApuRumi:_parte(props): BasePart
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

function ApuRumi:_unir(p: BasePart, a: BasePart, c0: CFrame, c1: CFrame?, motor: string?)
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

function ApuRumi:_construir()
	local m = Instance.new("Model")
	m.Name = "ApuRumi"
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
	local piedra = Color3.fromRGB(142, 140, 133)
	local piedraOscura = Color3.fromRGB(110, 108, 102)
	local musgo = Color3.fromRGB(94, 138, 68)
	local oro = Color3.fromRGB(255, 204, 64)
	local blanco = Color3.fromRGB(245, 248, 252)
	-- cuerpo encorvado hacia adelante
	local torso = self:_parte({ Name = "Torso", Size = V(5.0, 4.4, 3.6), Color = piedra, CanCollide = true })
	self:_unir(torso, raiz, CF(0, 4.0, 0) * CFrame.Angles(-0.3, 0, 0), nil, "RaizCuerpo")
	self.grietas = {}
	for _, g in { { V(0.2, 1.6, 0.1), CF(-1.6, 0.6, -1.82) }, { V(1.2, 0.2, 0.1), CF(-1.1, -0.3, -1.82) }, { V(0.2, 1.4, 0.1), CF(1.7, -0.4, -1.82) }, { V(0.2, 2.0, 0.1), CF(2.52, 0.2, 0) }, { V(0.2, 2.0, 0.1), CF(-2.52, -0.4, 0.4) } } do
		local grieta = self:_parte({ Name = "Grieta", Size = g[1], Color = oro, Neon = true, Transparency = 0.7 })
		self:_unir(grieta, torso, g[2])
		table.insert(self.grietas, grieta)
	end
	-- el disco del Inti en el pecho, con su cara
	self.disco = {}
	local disco = self:_parte({ Name = "Disco", Size = V(2.3, 2.3, 0.3), Color = Color3.fromRGB(230, 176, 64) })
	self:_unir(disco, torso, CF(0, 0.2, -1.9))
	local centro = self:_parte({ Name = "DiscoCentro", Size = V(1.7, 1.7, 0.1), Color = oro, Neon = true })
	self:_unir(centro, disco, CF(0, 0, -0.18))
	for _, c in { { V(0.3, 0.3, 0.06), CF(-0.35, 0.25, -0.26) }, { V(0.3, 0.3, 0.06), CF(0.35, 0.25, -0.26) }, { V(0.9, 0.18, 0.06), CF(0, -0.35, -0.26) } } do
		local rasgo = self:_parte({ Name = "Cara", Size = c[1], Color = Color3.fromRGB(184, 134, 42) })
		self:_unir(rasgo, disco, c[2])
		table.insert(self.disco, rasgo)
	end
	table.insert(self.disco, disco)
	table.insert(self.disco, centro)
	self.discoCentro = centro
	-- nieve en los hombros y el lomo
	self.nieve = {}
	for _, n in { { V(1.8, 0.6, 2.0), CF(-2.0, 2.4, 0.2) }, { V(1.8, 0.6, 2.0), CF(2.0, 2.4, 0.2) }, { V(3.0, 0.5, 1.6), CF(0, 2.3, 1.0) } } do
		local copo = self:_parte({ Name = "Nieve", Size = n[1], Color = blanco })
		self:_unir(copo, torso, n[2])
		table.insert(self.nieve, copo)
	end
	-- cabeza de gorila: frente prominente, ojos dorados y boca
	local cabeza = self:_parte({ Name = "Cabeza", Size = V(2.2, 2.0, 2.0), Color = piedra })
	self:_unir(cabeza, torso, CF(0, 2.0, -1.4), CF(0, -0.6, 0.4), "Cuello")
	local frente = self:_parte({ Name = "Frente", Size = V(2.5, 0.5, 0.7), Color = piedraOscura })
	self:_unir(frente, cabeza, CF(0, 0.45, -1.0))
	for _, lado in { -1, 1 } do
		local ojo = self:_parte({ Name = "Ojo", Size = V(0.4, 0.25, 0.1), Color = oro, Neon = true })
		self:_unir(ojo, cabeza, CF(lado * 0.5, 0.1, -1.02))
	end
	local boca = self:_parte({ Name = "Boca", Size = V(1.2, 0.5, 0.4), Color = Color3.fromRGB(80, 78, 74) })
	self:_unir(boca, cabeza, CF(0, -0.55, -0.9))
	local copete = self:_parte({ Name = "Nieve", Size = V(1.6, 0.35, 1.4), Color = blanco })
	self:_unir(copete, cabeza, CF(0, 1.1, 0))
	table.insert(self.nieve, copete)
	-- brazos enormes con puños que llegan al suelo
	for _, lado in { -1, 1 } do
		local L = lado < 0 and "I" or "D"
		local brazo = self:_parte({ Name = "Brazo" .. L, Size = V(1.6, 2.8, 1.6), Color = piedra })
		self:_unir(brazo, torso, CF(lado * 3.0, 1.2, -0.4), CF(0, 1.2, 0), "Hombro" .. L)
		local ante = self:_parte({ Name = "Antebrazo" .. L, Size = V(1.8, 2.6, 1.8), Color = piedraOscura })
		self:_unir(ante, brazo, CF(0, -1.3, 0), CF(0, 1.1, 0), "Codo" .. L)
		local moho = self:_parte({ Name = "Musgo", Size = V(1.85, 0.6, 1.85), Color = musgo })
		self:_unir(moho, ante, CF(0, 0.2, 0))
		local puno = self:_parte({ Name = "Puno" .. L, Size = V(2.2, 1.4, 2.2), Color = piedraOscura, CanCollide = true })
		self:_unir(puno, ante, CF(0, -1.3, 0))
		local nudillos = self:_parte({ Name = "Nudillos", Size = V(2.25, 0.35, 0.4), Color = Color3.fromRGB(90, 88, 84) })
		self:_unir(nudillos, puno, CF(0, 0, -1.0))
		self.punos = self.punos or {}
		table.insert(self.punos, nudillos)
	end
	-- piernas cortas
	for _, lado in { -1, 1 } do
		local L = lado < 0 and "I" or "D"
		local pierna = self:_parte({ Name = "Pierna" .. L, Size = V(1.6, 2.4, 1.6), Color = piedraOscura })
		self:_unir(pierna, torso, CF(lado * 1.4, -2.0, 0.8), CF(0, 1.0, 0), "Cadera" .. L)
		local moho = self:_parte({ Name = "Musgo", Size = V(1.65, 0.5, 1.65), Color = musgo })
		self:_unir(moho, pierna, CF(0, 0.3, 0))
		local pie = self:_parte({ Name = "Pie", Size = V(1.9, 0.6, 2.3), Color = Color3.fromRGB(90, 88, 84) })
		self:_unir(pie, pierna, CF(0, -1.3, -0.3))
	end
	-- avisos rojos, el rayo de sol y la roca que lanza
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
	self.avisoCirculo = aviso("AvisoCirculoApu", Enum.PartType.Cylinder)
	self.avisoRect = aviso("AvisoRectApu", Enum.PartType.Block)
	self.rayo = aviso("RayoSol", Enum.PartType.Block)
	self.rayo.Color = Color3.fromRGB(255, 220, 120)
	self.roca = aviso("RocaApu", Enum.PartType.Block)
	self.roca.Material = Enum.Material.SmoothPlastic
	self.roca.Color = Color3.fromRGB(128, 122, 116)
	m:SetAttribute("Nombre", "Apu Rumi")
	m:SetAttribute("Mapa", "cumbres")
	m:SetAttribute("Partes", "disco:Disco solar;punos:Puños;nieve:Nieve de los hombros")
	-- con streaming activado, Roblox manda los modelos por partes: el Behemoth debe llegar
	-- completo a todos los jugadores para que su animación y sus partes funcionen
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m.Parent = workspace:FindFirstChild("Behemoths") or workspace
end

-- ---------- vida y estado ----------
function ApuRumi.nuevo(servicios)
	local self = setmetatable({}, ApuRumi)
	self.servicios = servicios
	self:_construir()
	self:reiniciar()
	return self
end

function ApuRumi:reiniciar()
	local n = math.max(1, #self.servicios.jugadores("cumbres"))
	self.vidaMax = VIDA_BASE * (1 + 0.6 * (n - 1))
	self.vida = self.vidaMax
	self.estado = "vagar"
	self.alerta, self.fase2, self.furioso, self.muerto, self.enterrado = false, false, false, false, false
	self.derribo, self.derriboMax = 0, 250
	self.heridas = {}
	self.t, self.reloj, self.cd, self.lejos, self.espera = 0, 0, 2, 0, 0
	self.tiempo = 0
	self.destino = nil
	self.caceria = { partes = {}, derribos = 0, desmayos = 0, terminada = false }
	self.participantes = {}
	Estados.iniciar(self)
	self.partes = {}
	for id, d in DATOS_PARTES do
		self.partes[id] = { nombre = d.nombre, max = d.max, vida = d.max, rota = false }
	end
	for _, x in self.nieve do
		x.Transparency = 0
	end
	for _, x in self.disco do
		x.Transparency = 0
	end
	for _, x in self.punos do
		x.Transparency = 0
	end
	for _, g in self.grietas do
		g.Transparency = 0.7
	end
	local p = PATRULLA[math.random(1, #PATRULLA)]
	self.pos = Config.sueloCumbres(p.X, p.Y)
	self.yVisual = self.pos.Y
	self.yaw = math.random() * math.pi * 2
	self:_ocultarAvisos()
	self:_anim("reposo")
	self:_publicar()
end

function ApuRumi:_anim(nombre: string, ritmo: number?)
	if self.modelo:GetAttribute("Anim") ~= nombre then
		self.modelo:SetAttribute("Anim", nombre)
		self.modelo:SetAttribute("AnimT0", workspace:GetServerTimeNow())
	end
	self.modelo:SetAttribute("Ritmo", ritmo or 1)
end

function ApuRumi:_publicar()
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

function ApuRumi:_adelante(): Vector3
	return CFrame.Angles(0, self.yaw, 0).LookVector
end

function ApuRumi:_yawHacia(p: Vector3): number
	local d = p - self.pos
	return math.atan2(-d.X, -d.Z)
end

function ApuRumi:_girarHacia(yaw: number, rapidez: number, dt: number)
	local dif = (yaw - self.yaw + math.pi) % (math.pi * 2) - math.pi
	self.yaw += math.clamp(dif, -rapidez * dt, rapidez * dt)
end

function ApuRumi:_angulo(p: Vector3): number
	return math.abs((self:_yawHacia(p) - self.yaw + math.pi) % (math.pi * 2) - math.pi)
end

function ApuRumi:_dist(p: Vector3): number
	return Vector2.new(p.X - self.pos.X, p.Z - self.pos.Z).Magnitude / S
end


function ApuRumi:_mover(dt: number, velocidad: number): boolean
	local nueva = self.pos + self:_adelante() * velocidad * Estados.freno(self) * S * dt
	local centro = Vector2.new(Config.CUMBRES.X, Config.CUMBRES.Z)
	local plano2 = Vector2.new(nueva.X, nueva.Z)
	local choco = false
	if (plano2 - centro).Magnitude > 100 * S then
		plano2 = centro + (plano2 - centro).Unit * 100 * S
		choco = true
		self.destino = nil
	end
	local camp = centro + Config.CUMBRES_CAMPAMENTO * S
	if (plano2 - camp).Magnitude < 26 * S then
		plano2 = camp + (plano2 - camp).Unit * 26 * S
		self.destino = nil
	end
	self.pos = Vector3.new(plano2.X, Config.alturaCumbres(plano2.X, plano2.Y), plano2.Y)
	return choco
end

function ApuRumi:_elegirObjetivo(dt: number)
	self.tObjetivo = (self.tObjetivo or 0) - dt
	local valido = false
	if self.objetivo then
		for _, j in self.servicios.jugadores("cumbres") do
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
	for _, j in self.servicios.jugadores("cumbres") do
		local d = self:_dist(j.hrp.Position)
		if j.atacable and d < mejorD then
			mejor, mejorD = j, d
		end
	end
	self.objetivo = mejor
end

function ApuRumi:_posObjetivo(): Vector3
	return self.objetivo and self.objetivo.hrp.Position or self.pos
end



-- ---------- ciclo principal ----------
function ApuRumi:paso(dt: number)
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
	if not self.muerto and not self.alerta and hay and self:_dist(self:_posObjetivo()) < 22 and self.estado == "vagar" then
		self:_alertar()
	end
	if self.alerta and not self.muerto and self.estado == "perseguir" then
		self.lejos = (not hay or self:_dist(self:_posObjetivo()) > 75) and self.lejos + dt or 0
		if self.lejos > 6 then
			self.alerta = false
			self.lejos = 0
			self:_cambiar("vagar")
		end
	end
	local e = self.estado
	local suaveY = true
	if e == "vagar" then
		self:_vagar(dt)
	elseif e == "rugir" then
		self:_anim("rugir")
		if self.t > 2.0 then
			self:_cambiar("perseguir")
			self.cd = 1
		end
	elseif e == "perseguir" then
		self:_perseguir(dt)
	elseif e == "ataque" then
		suaveY = self:_ataque(dt)
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
		if self.t > 1.4 then
			self:_cambiar("perseguir")
			self.cd = 0.5
		end
	elseif e == "muerto" then
		self:_anim("muerte")
		if self.t > 25 then
			self:reiniciar()
		end
	end
	if suaveY ~= false then
		self.yVisual += (self.pos.Y - self.yVisual) * math.min(1, dt * 8)
	end
	self.raiz.CFrame = CFrame.new(self.pos.X, self.yVisual, self.pos.Z) * CFrame.Angles(0, self.yaw, 0)
	for _, a in { self.avisoCirculo, self.avisoRect } do
		if a.Transparency < 1 then
			a.Transparency = 0.35 + 0.25 * math.sin(self.reloj * 14)
		end
	end
	if self.fase2 and not self.muerto and not self.partes.disco.rota then
		local k = 0.5 + 0.5 * math.sin(self.reloj * (self.furioso and 7 or 3))
		self.discoCentro.Color = Color3.fromRGB(255, 180 + 60 * k, 40 + 80 * k)
	end
	self:_publicar()
end

function ApuRumi:_cambiar(nuevo: string)
	self.estado = nuevo
	self.t = 0
end

function ApuRumi:_vagar(dt: number)
	if self.espera > 0 then
		self.espera -= dt
		self:_anim("reposo")
		return
	end
	if not self.destino then
		local p = PATRULLA[math.random(1, #PATRULLA)]
		self.destino = Config.sueloCumbres(p.X + math.random(-10, 10), p.Y + math.random(-10, 10))
	end
	if self:_dist(self.destino) < 4 then
		self.destino = nil
		self.espera = math.random(20, 50) / 10
		return
	end
	self:_girarHacia(self:_yawHacia(self.destino), 1.2, dt)
	if self:_mover(dt, 3.4) then
		self.destino = nil
	end
	self:_anim("caminar", 1)
end

function ApuRumi:_alertar()
	if self.alerta or self.muerto then
		return
	end
	self.alerta = true
	self.lejos = 0
	self:_cambiar("rugir")
	self.servicios.anunciar("¡Apu Rumi te ha detectado!", Color3.fromRGB(255, 214, 90))
end

function ApuRumi:_perseguir(dt: number)
	if not self.objetivo then
		self:_anim("reposo")
		return
	end
	local objetivo = self:_posObjetivo()
	local dist = self:_dist(objetivo)
	self:_girarHacia(self:_yawHacia(objetivo), self.furioso and 2.3 or 1.8, dt)
	if dist > 8 then
		local v = self.furioso and 7.4 or 6.0
		self:_mover(dt, v)
		self:_anim("correr", v / 6)
	else
		self:_anim("reposo")
	end
	self.cd -= dt
	if self.cd <= 0 then
		local ang = self:_angulo(objetivo)
		local op = {}
		local function o(n, w)
			table.insert(op, { n, w })
		end
		if dist < 8 and ang < 0.6 then
			o("punetazo", 3)
		end
		if dist < 12 then
			o("pecho", 1.5)
		end
		if dist > 10 and dist < 35 and ang < 0.5 then
			o("carga", 2)
		end
		if dist > 10 and dist < 40 then
			o("roca", 2.5)
		end
		if dist < 24 then
			o("salto", self.fase2 and 2.5 or 1.5)
		end
		if self.fase2 and not self.partes.disco.rota and dist > 8 and dist < 30 and ang < 0.6 then
			o("rayo_sol", 3)
		end
		if #op == 0 then
			self.cd = 0.3
			return
		end
		local total = 0
		for _, x in op do
			total += x[2]
		end
		local r = math.random() * total
		for _, x in op do
			r -= x[2]
			if r <= 0 then
				self:_iniciarAtaque(x[1])
				return
			end
		end
		self:_iniciarAtaque(op[1][1])
	end
end

function ApuRumi:_duraciones()
	local d = ATAQUES[self.ataque]
	local k = (self.furioso and 1.2 or 1) * (self.fase2 and 1.15 or 1)
	return d.prep / k, d.activo / k, d.rec / k
end

function ApuRumi:_iniciarAtaque(nombre: string)
	self:_cambiar("ataque")
	self.ataque = nombre
	self.fase = ""
	self.tFase = 0
	self.golpeados = {}
	self.hecho = false
	self:_anim(nombre)
end

function ApuRumi:_terminarAtaque()
	self:_ocultarAvisos()
	self:_cambiar("perseguir")
	self.cd = (math.random(5, 13) / 10) * (self.furioso and 0.6 or 1)
end

function ApuRumi:_golpear(prueba, origen: Vector3)
	local d = ATAQUES[self.ataque]
	local mult = (self.ataque == "punetazo" and self.partes.punos.rota) and 0.7 or 1
	for _, j in self.servicios.jugadores("cumbres") do
		if j.atacable and not self.golpeados[j.hrp] and prueba(j.hrp.Position) then
			self.golpeados[j.hrp] = true
			self.servicios.danio(j.jugador, d.danio * mult * (self.furioso and 1.15 or 1), origen, d.empuje, "apu_" .. self.ataque)
		end
	end
end



function ApuRumi:_ataque(dt: number): boolean
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
	end
	local tf = self.tFase - self.inicioFase
	local adelante = self:_adelante()
	local objetivo = self:_posObjetivo()
	local a = self.ataque
	if a == "punetazo" then
		local punto = self.pos + adelante * 5 * S
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 2.6, dt)
			self:_avisoCirculo(punto, 4)
		elseif self.fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(punto, 40)
			self:_golpear(function(p)
				return plano(p, punto) < 4
			end, punto)
		end
	elseif a == "carga" then
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 3.5, dt)
			self:_avisoRect(self.pos, self.yaw, 7, 28)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self:_anim("correr", 2.4)
			self:_girarHacia(self:_yawHacia(objetivo), 0.4, dt)
			local choco = self:_mover(dt, self.furioso and 20 or 17)
			self:_golpear(function(p)
				return plano(p, self.pos + adelante * 3 * S) < 3.5
			end, self.pos)
			if choco then
				self.servicios.anunciar("¡Apu Rumi chocó contra la montaña!", Color3.fromRGB(255, 224, 138))
				self:_polvo(self.pos, 40)
				self:_cambiar("estremecer")
			end
		else
			self:_anim("reposo")
		end
	elseif a == "roca" then
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 2.5, dt)
			if tf < prep - 0.2 then
				self.destinoRoca = Vector3.new(objetivo.X, Config.alturaCumbres(objetivo.X, objetivo.Z), objetivo.Z)
			end
			self:_avisoCirculo(self.destinoRoca or objetivo, 4.5)
			-- la roca sale del suelo entre sus manos
			self.roca.Transparency = 0
			self.roca.Size = V(2.6, 2.2, 2.4)
			self.roca.CFrame = CFrame.new(self.pos + adelante * 3 * S + Vector3.new(0, (2 + tf * 3) * S, 0)) * CFrame.Angles(tf, tf * 0.5, 0)
		elseif self.fase == "activo" then
			local k = math.clamp(tf / act, 0, 1)
			local desde = self.pos + adelante * 3 * S + Vector3.new(0, 5 * S, 0)
			local p = desde:Lerp(self.destinoRoca, k) + Vector3.new(0, math.sin(k * math.pi) * 8 * S, 0)
			self.roca.CFrame = CFrame.new(p) * CFrame.Angles(k * 6, k * 3, 0)
		elseif self.fase == "rec" and not self.hecho then
			self.hecho = true
			self.roca.Transparency = 1
			self:_ocultarAvisos()
			self:_polvo(self.destinoRoca, 50)
			self:_golpear(function(p)
				return plano(p, self.destinoRoca) < 4.5
			end, self.destinoRoca)
		end
	elseif a == "salto" then
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			if tf < prep - 0.25 then
				self.desde = self.pos
				self.hasta = Vector3.new(objetivo.X, 0, objetivo.Z)
			end
			self:_avisoCirculo(self.hasta or self.pos, 6)
		elseif self.fase == "activo" then
			local k = math.clamp(tf / act, 0, 1)
			local p = self.desde:Lerp(self.hasta, k)
			self.pos = Vector3.new(p.X, Config.alturaCumbres(p.X, p.Z), p.Z)
			self.yVisual = self.pos.Y + math.sin(k * math.pi) * 7 * S
			return false
		elseif self.fase == "rec" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(self.pos, 70)
			self:_golpear(function(p)
				return plano(p, self.pos) < 6
			end, self.pos)
		end
	elseif a == "pecho" then
		if self.fase == "prep" then
			self:_avisoCirculo(self.pos, 12)
		elseif self.fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(self.pos, 60)
			-- la onda empuja y aturde a todos los que estaban cerca
			self:_golpear(function(p)
				return plano(p, self.pos) < 12
			end, self.pos)
			for _, j in self.servicios.jugadores("cumbres") do
				if j.atacable and plano(j.hrp.Position, self.pos) < 12 then
					Remotos.Aturdir:FireClient(j.jugador, 1.0)
				end
			end
		end
	elseif a == "rayo_sol" then
		local desde = self.pos + adelante * 4 * S
		local largo = 30
		if self.fase == "prep" then
			if tf < prep - 0.3 then
				self:_girarHacia(self:_yawHacia(objetivo), 1.2, dt)
			end
			self:_avisoRect(desde, self.yaw, 5, largo)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			local medio = desde + adelante * largo * 0.5 * S
			self.rayo.Transparency = 0.1
			self.rayo.Size = Vector3.new(2 * S, 2 * S, largo * S)
			self.rayo.CFrame = CFrame.new(Vector3.new(medio.X, Config.alturaCumbres(medio.X, medio.Z) + 3 * S, medio.Z)) * CFrame.Angles(0, self.yaw, 0)
			self:_golpear(function(p)
				local rel = Vector3.new(p.X - desde.X, 0, p.Z - desde.Z) / S
				local aLoLargo = rel:Dot(adelante)
				local alLado = math.abs(rel:Cross(adelante).Y)
				return aLoLargo > -1 and aLoLargo < largo and alLado < 2.5
			end, desde)
		else
			self.rayo.Transparency = 1
		end
	end
	return true
end

-- ---------- efectos ----------
function ApuRumi:_polvo(pos: Vector3, cantidad: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = Vector3.new(pos.X, Config.alturaCumbres(pos.X, pos.Z) + 1, pos.Z)
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(150, 144, 136))
	e.Size = NumberSequence.new(1.2, 0)
	e.Lifetime = NumberRange.new(0.6, 1.3)
	e.Speed = NumberRange.new(10, 26)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -24, 0)
	e.Rate = 0
	e.Parent = p
	e:Emit(cantidad)
	Debris:AddItem(p, 3)
end

function ApuRumi:_avisoCirculo(centro: Vector3, radio: number)
	local c = self.avisoCirculo
	if c.Transparency >= 1 then
		c.Transparency = 0.4
	end
	c.Size = Vector3.new(0.3, radio * 2 * S, radio * 2 * S)
	c.CFrame = CFrame.new(centro.X, Config.alturaCumbres(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, 0, math.rad(90))
end

function ApuRumi:_avisoRect(inicio: Vector3, yaw: number, ancho: number, largo: number)
	local r = self.avisoRect
	if r.Transparency >= 1 then
		r.Transparency = 0.4
	end
	local dir = CFrame.Angles(0, yaw, 0).LookVector
	local centro = inicio + dir * largo * 0.5 * S
	r.Size = Vector3.new(ancho * S, 0.3, largo * S)
	r.CFrame = CFrame.new(centro.X, Config.alturaCumbres(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, yaw, 0)
end

function ApuRumi:_ocultarAvisos()
	self.avisoCirculo.Transparency = 1
	self.avisoRect.Transparency = 1
	self.rayo.Transparency = 1
	self.roca.Transparency = 1
end



-- ---------- recibir golpes ----------
function ApuRumi:zonas()
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

function ApuRumi:recibirGolpe(z, info, jugador: Player?)
	if self.muerto then
		return
	end
	if jugador then
		self.participantes[jugador] = true
	end
	local parte = z.parte
	local m = MULT_ZONA[z.tipo] or 1
	if parte ~= "" and self.partes[parte] and self.partes[parte].rota then
		m = 1.3
	end
	if self.estado == "derribado" then
		m *= 1.25
	end
	if z.nombre == "disco" and self.fase2 then
		m *= 1.5 -- el disco agrietado es su punto débil
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
		local factor = z.tipo == "cola" and 0.8 or (z.tipo == "cabeza" and 1.2 * (info.multCabeza or 1) or 0.45)
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

function ApuRumi:_danio(danio: number)
	if self.muerto then
		return
	end
	self.vida -= danio
	if not self.fase2 and self.vida < self.vidaMax * 0.5 and self.vida > 0 then
		self:_agrietar(false)
	end
	if not self.furioso and self.vida < self.vidaMax * 0.4 and self.vida > 0 then
		self.furioso = true
		self.servicios.anunciar("¡Apu Rumi está furioso!", Color3.fromRGB(192, 112, 255))
	end
	if self.vida <= 0 then
		self.vida = 0
		self:_morir()
	end
end



function ApuRumi:_romper(id: string)
	local p = self.partes[id]
	p.rota = true
	p.vida = 0
	table.insert(self.caceria.partes, id)
	self.servicios.anunciar("¡Rompiste: " .. p.nombre .. "!", Color3.fromRGB(255, 224, 138))
	if id == "disco" then
		for _, x in self.disco do
			x.Transparency = 0.6
		end
		self.discoCentro.Color = Color3.fromRGB(90, 70, 40)
	elseif id == "punos" then
		for _, x in self.punos do
			x.Transparency = 1
		end
	elseif id == "nieve" then
		for _, x in self.nieve do
			x.Transparency = 1
		end
		self:_agrietar(true)
		return
	end
	if self.estado ~= "derribado" and self.estado ~= "muerto" then
		self:_ocultarAvisos()
		self:_cambiar("estremecer")
	end
end

-- Segunda fase: la piedra se agrieta y la luz del sol sale por las grietas.
function ApuRumi:_agrietar(porRomper: boolean)
	if self.fase2 then
		return
	end
	self.fase2 = true
	for _, g in self.grietas do
		g.Transparency = 0
	end
	self:_polvo(self.pos, 60)
	self.servicios.anunciar(porRomper and "¡Cae la nieve y la luz escapa por sus grietas!" or "¡Apu Rumi se agrieta y arde con la luz del sol!", Color3.fromRGB(255, 214, 90))
	if not self.muerto and self.estado ~= "derribado" then
		self:_ocultarAvisos()
		self:_cambiar("rugir")
	end
end

function ApuRumi:_derribar()
	self.caceria.derribos += 1
	self:_ocultarAvisos()
	self.enterrado = false
	self.derribo = 0
	self.derriboMax *= 1.3
	self:_polvo(self.pos, 50)
	self.servicios.anunciar("¡Apu Rumi cayó! Aprovecha", Color3.fromRGB(63, 208, 200))
	self:_cambiar("derribado")
end

function ApuRumi:_morir()
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

function ApuRumi:desmayo(jugador: Player?)
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



function ApuRumi:_terminarCaceria(exito: boolean)
	if self.caceria.terminada then
		return
	end
	self.caceria.terminada = true
	local nombresMat = { disco = "Fragmento del disco solar", punos = "Nudillo de granito", nieve = "Hielo eterno" }
	local claves = { disco = "disco_solar", punos = "nudillo", nieve = "hielo" }
	local recompensas = exito and { "+ 320 monedas", "+ 6 Piedras del Inti", "+ 2 Núcleos del desierto" } or {}
	local premios = exito and { monedas = 320, piedra_inti = 6, nucleo = 2 } or {}
	local nombres = {}
	for _, id in self.caceria.partes do
		table.insert(nombres, DATOS_PARTES[id].nombre)
		table.insert(recompensas, "+ 2 " .. nombresMat[id])
		premios[claves[id]] = (premios[claves[id]] or 0) + 2
	end
	self.servicios.recompensar(premios, self.participantes)
	self.servicios.resultados(self.participantes, {
		behemoth = "Apu Rumi", exito = exito, tiempo = self.tiempo, partes = nombres,
		derribos = self.caceria.derribos, desmayos = self.caceria.desmayos, recompensas = recompensas,
	})
end

return ApuRumi
