--!nonstrict
-- Amaru, la Serpiente Alada de Sombra (Cumbres del Inti). Todo lo decide el servidor.
-- Ataques: mordida, latigazo, enroscarse, planeo, rayo de sombra, lluvia de plumas,
-- nube de sombra (no deja ver) y hundirse en las sombras para salir por detrás.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Compartido.Config)
local Estados = require(script.Parent.Estados)

local S = Config.S
local function sueloCuevas(xm: number, zm: number): Vector3
	return Config.sueloMontana(Config.CUEVAS, xm, zm)
end
local VIDA_BASE = 8100
local ATAQUES = {
	mordida = { prep = 0.6, activo = 0.25, rec = 0.8, danio = 22, empuje = 9 },
	latigazo = { prep = 0.7, activo = 0.45, rec = 0.8, danio = 22, empuje = 13 },
	enroscarse = { prep = 1.2, activo = 0.4, rec = 1.0, danio = 26, empuje = 6 },
	planeo = { prep = 0.9, activo = 1.1, rec = 1.0, danio = 28, empuje = 14 },
	rayo = { prep = 1.1, activo = 0.7, rec = 1.0, danio = 26, empuje = 10 },
	plumas = { prep = 0.9, activo = 0.3, rec = 0.8, danio = 18, empuje = 5 },
	nube = { prep = 0.6, activo = 0.2, rec = 0.6, danio = 0, empuje = 0 },
	sombras = { prep = 0.5, activo = 0.7, rec = 0.9, danio = 24, empuje = 10 },
}
local DATOS_PARTES = {
	cuernos = { nombre = "Cuernos lunares", max = 260 },
	alas = { nombre = "Alas", max = 300 },
	cresta = { nombre = "Cresta", max = 260 },
}
local MULT_ZONA = { cuerpo = 1.0, cabeza = 1.3, pata = 0.9, cola = 1.0 }
local ZONAS = {
	{ nombre = "cabeza", tipo = "cabeza", parte = "", pos = Vector3.new(0, 1.9, -4.4), r = 1.7 },
	{ nombre = "cuernos", tipo = "cabeza", parte = "cuernos", pos = Vector3.new(0, 3.1, -3.8), r = 1.2 },
	{ nombre = "cresta", tipo = "cabeza", parte = "cresta", pos = Vector3.new(0, 3.0, -2.4), r = 1.3 },
	{ nombre = "ala_i", tipo = "cuerpo", parte = "alas", pos = Vector3.new(-3.4, 2.6, 0.8), r = 2.0 },
	{ nombre = "ala_d", tipo = "cuerpo", parte = "alas", pos = Vector3.new(3.4, 2.6, 0.8), r = 2.0 },
	{ nombre = "cuello", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.6, -1.2), r = 1.5 },
	{ nombre = "cuerpo1", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.4, 1.4), r = 1.5 },
	{ nombre = "cuerpo2", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.3, 4.0), r = 1.4 },
	{ nombre = "cuerpo3", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.2, 6.6), r = 1.3 },
	{ nombre = "cuerpo4", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.1, 9.2), r = 1.2 },
	{ nombre = "cola", tipo = "cola", parte = "", pos = Vector3.new(0, 1.0, 12.4), r = 1.2 },
}
local PATRULLA = { Vector2.new(-15, -60), Vector2.new(-60, 10), Vector2.new(20, -20), Vector2.new(50, 30), Vector2.new(-30, 40), Vector2.new(0, -30) }

local Amaru = {}
Amaru.__index = Amaru

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
function Amaru:_parte(props): BasePart
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

function Amaru:_unir(p: BasePart, a: BasePart, c0: CFrame, c1: CFrame?, motor: string?)
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

function Amaru:_construir()
	local m = Instance.new("Model")
	m.Name = "Amaru"
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
	local escama = Color3.fromRGB(42, 29, 60)
	local oscura = Color3.fromRGB(26, 16, 38)
	local pluma = Color3.fromRGB(160, 76, 224)
	local plata = Color3.fromRGB(201, 198, 214)
	-- el cuello, pegado a la raíz, y diez segmentos hacia la cola
	local cuello = self:_parte({ Name = "Cuello", Size = V(2.4, 2.2, 2.6), Color = escama, CanCollide = true })
	self:_unir(cuello, raiz, CF(0, 1.5, -1.2), nil, "RaizCuerpo")
	self.plumasBrillo = {}
	local anterior = cuello
	for i = 1, 10 do
		local ancho = 2.3 - i * 0.13
		local seg = self:_parte({ Name = "Seg" .. i, Size = V(ancho, ancho * 0.9, 2.5), Color = i % 2 == 0 and escama or oscura, CanCollide = i < 4 })
		self:_unir(seg, anterior, CF(0, 0, 1.25), CF(0, 0, -1.25), "Seg" .. i)
		local mechon = self:_parte({ Name = "Pluma", Size = V(ancho * 0.5, 0.35, 1.2), Color = pluma, Neon = true })
		self:_unir(mechon, seg, CF(0, ancho * 0.45 + 0.1, 0))
		table.insert(self.plumasBrillo, mechon)
		anterior = seg
	end
	-- cabeza, mandíbula, ojos, cuernos y cresta
	local cabeza = self:_parte({ Name = "Cabeza", Size = V(2.2, 1.8, 3.0), Color = Color3.fromRGB(31, 21, 48) })
	self:_unir(cabeza, cuello, CF(0, 0.3, -1.3), CF(0, -0.1, 1.5), "CuelloCabeza")
	local mandibula = self:_parte({ Name = "Mandibula", Size = V(1.9, 0.5, 2.4), Color = Color3.fromRGB(20, 14, 32) })
	self:_unir(mandibula, cabeza, CF(0, -0.9, 0.3), CF(0, 0, 1.0), "Mandibula")
	for _, lado in { -1, 1 } do
		local ojo = self:_parte({ Name = "Ojo", Size = V(0.4, 0.3, 0.2), Color = Color3.new(1, 1, 1), Neon = true })
		self:_unir(ojo, cabeza, CF(lado * 0.8, 0.35, -1.1))
		for k, t in { { V(0.35, 0.9, 0.35), CF(lado * 0.6, 1.2, 0.2) * CFrame.Angles(0.4, 0, -lado * 0.3) }, { V(0.28, 0.7, 0.28), CF(lado * 0.8, 1.8, 0.6) * CFrame.Angles(0.8, 0, -lado * 0.4) } } do
			local c = self:_parte({ Name = "Cuerno", Size = t[1], Color = plata })
			self:_unir(c, cabeza, t[2])
			self.cuernos = self.cuernos or {}
			table.insert(self.cuernos, c)
			local _ = k
		end
	end
	self.cresta = {}
	for i = 0, 4 do
		local f = self:_parte({ Name = "Cresta", Size = V(0.3, 1.0 + (i % 2) * 0.4, 0.5), Color = i % 2 == 0 and pluma or Color3.fromRGB(200, 120, 255), Neon = true })
		self:_unir(f, cabeza, CF(0, 1.0 + (i % 2) * 0.2, 0.3 + i * 0.4) * CFrame.Angles(-0.5, 0, 0))
		table.insert(self.cresta, f)
	end
	-- el eclipse (se ve en la segunda fase): un sol negro con un halo morado
	self.eclipse = {}
	local disco = self:_parte({ Name = "Eclipse", Size = V(4.2, 4.2, 0.3), Color = Color3.fromRGB(8, 4, 14), Transparency = 1 })
	self:_unir(disco, cabeza, CF(0, 1.6, 1.8))
	table.insert(self.eclipse, disco)
	for _, marco in { { V(4.8, 0.4, 0.2), CF(0, 2.2, 0) }, { V(4.8, 0.4, 0.2), CF(0, -2.2, 0) }, { V(0.4, 4.8, 0.2), CF(2.2, 0, 0) }, { V(0.4, 4.8, 0.2), CF(-2.2, 0, 0) } } do
		local h = self:_parte({ Name = "Halo", Size = marco[1], Color = Color3.fromRGB(192, 112, 255), Neon = true, Transparency = 1 })
		self:_unir(h, disco, marco[2])
		table.insert(self.eclipse, h)
	end
	-- alas en el primer segmento
	self.alas = {}
	local seg1 = self.modelo:FindFirstChild("Seg1") :: BasePart
	for _, lado in { -1, 1 } do
		local nombre = lado < 0 and "AlaI" or "AlaD"
		local ala = self:_parte({ Name = nombre, Size = V(4.6, 0.3, 3.2), Color = escama })
		self:_unir(ala, seg1, CF(lado * 1.1, 1.0, 0), CF(-lado * 2.3, 0, 0), nombre)
		table.insert(self.alas, ala)
		for k = 0, 3 do
			local borde = self:_parte({ Name = "PlumaAla", Size = V(1.0, 0.25, 1.4), Color = pluma, Neon = true })
			self:_unir(borde, ala, CF(lado * (-1.8 + k * 1.2), 0, 1.8 + (k % 2) * 0.3))
			table.insert(self.alas, borde)
		end
	end
	-- avisos rojos, el rayo de sombra y el humo
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
	self.avisoCirculo = aviso("AvisoCirculoA", Enum.PartType.Cylinder)
	self.avisoRect = aviso("AvisoRectA", Enum.PartType.Block)
	self.rayo = aviso("RayoSombra", Enum.PartType.Block)
	self.rayo.Color = Color3.fromRGB(90, 30, 140)
	self.avisosPlumas = {}
	for i = 1, 7 do
		self.avisosPlumas[i] = aviso("AvisoPluma" .. i, Enum.PartType.Cylinder)
	end
	local humo = Instance.new("ParticleEmitter")
	humo.Color = ColorSequence.new(Color3.fromRGB(40, 20, 60))
	humo.Size = NumberSequence.new(1.5, 0)
	humo.Lifetime = NumberRange.new(1, 2)
	humo.Speed = NumberRange.new(1, 3)
	humo.Rate = 0
	humo.Acceleration = Vector3.new(0, 4, 0)
	humo.SpreadAngle = Vector2.new(180, 180)
	humo.Parent = cuello
	self.humo = humo
	m:SetAttribute("Nombre", "Amaru")
	m:SetAttribute("Mapa", "cuevas")
	m:SetAttribute("Partes", "cuernos:Cuernos lunares;alas:Alas;cresta:Cresta")
	-- con streaming activado, Roblox manda los modelos por partes: el Behemoth debe llegar
	-- completo a todos los jugadores para que su animación y sus partes funcionen
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m.Parent = workspace:FindFirstChild("Behemoths") or workspace
end

-- ---------- vida y estado ----------
function Amaru.nuevo(servicios)
	local self = setmetatable({}, Amaru)
	self.servicios = servicios
	self:_construir()
	self:reiniciar()
	return self
end

function Amaru:reiniciar()
	local n = math.max(1, #self.servicios.jugadores("cuevas"))
	self.vidaMax = VIDA_BASE * (1 + 0.6 * (n - 1))
	self.vida = self.vidaMax
	self.estado = "vagar"
	self.alerta, self.fase2, self.furioso, self.muerto, self.enterrado = false, false, false, false, false
	self.derribo, self.derriboMax = 0, 230
	self.heridas = {}
	self.t, self.reloj, self.cd, self.lejos, self.espera = 0, 0, 2, 0, 0
	self.cdNube, self.cdSombras = 10, 8
	self.tiempo = 0
	self.destino = nil
	self.caceria = { partes = {}, derribos = 0, desmayos = 0, terminada = false }
	self.participantes = {}
	Estados.iniciar(self)
	self.partes = {}
	for id, d in DATOS_PARTES do
		self.partes[id] = { nombre = d.nombre, max = d.max, vida = d.max, rota = false }
	end
	for _, c in self.cuernos do
		c.Transparency = 0
	end
	for _, f in self.cresta do
		f.Transparency = 0
	end
	for _, a in self.alas do
		a.Transparency = 0
	end
	for _, e in self.eclipse do
		e.Transparency = 1
	end
	self.humo.Rate = 0
	local p = PATRULLA[math.random(1, #PATRULLA)]
	self.pos = sueloCuevas(p.X, p.Y)
	self.yVisual = self.pos.Y
	self.yaw = math.random() * math.pi * 2
	self:_ocultarAvisos()
	self:_anim("reposo")
	self:_publicar()
end

function Amaru:_anim(nombre: string, ritmo: number?)
	if self.modelo:GetAttribute("Anim") ~= nombre then
		self.modelo:SetAttribute("Anim", nombre)
		self.modelo:SetAttribute("AnimT0", workspace:GetServerTimeNow())
	end
	self.modelo:SetAttribute("Ritmo", ritmo or 1)
end

function Amaru:_publicar()
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

function Amaru:_adelante(): Vector3
	return CFrame.Angles(0, self.yaw, 0).LookVector
end

function Amaru:_yawHacia(p: Vector3): number
	local d = p - self.pos
	return math.atan2(-d.X, -d.Z)
end

function Amaru:_girarHacia(yaw: number, rapidez: number, dt: number)
	local dif = (yaw - self.yaw + math.pi) % (math.pi * 2) - math.pi
	self.yaw += math.clamp(dif, -rapidez * dt, rapidez * dt)
end

function Amaru:_angulo(p: Vector3): number
	return math.abs((self:_yawHacia(p) - self.yaw + math.pi) % (math.pi * 2) - math.pi)
end

function Amaru:_dist(p: Vector3): number
	return Vector2.new(p.X - self.pos.X, p.Z - self.pos.Z).Magnitude / S
end


function Amaru:_mover(dt: number, velocidad: number): boolean
	local nueva = self.pos + self:_adelante() * velocidad * Estados.freno(self) * S * dt
	local centro = Vector2.new(Config.CUEVAS.X, Config.CUEVAS.Z)
	local plano2 = Vector2.new(nueva.X, nueva.Z)
	local choco = false
	if (plano2 - centro).Magnitude > 100 * S then
		plano2 = centro + (plano2 - centro).Unit * 100 * S
		choco = true
		self.destino = nil
	end
	local camp = centro + Config.ISLAS.cuevas.campamento * S
	if (plano2 - camp).Magnitude < 26 * S then
		plano2 = camp + (plano2 - camp).Unit * 26 * S
		self.destino = nil
	end
	self.pos = Vector3.new(plano2.X, Config.alturaEn(plano2.X, plano2.Y), plano2.Y)
	return choco
end

function Amaru:_elegirObjetivo(dt: number)
	self.tObjetivo = (self.tObjetivo or 0) - dt
	local valido = false
	if self.objetivo then
		for _, j in self.servicios.jugadores("cuevas") do
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
	for _, j in self.servicios.jugadores("cuevas") do
		local d = self:_dist(j.hrp.Position)
		if j.atacable and d < mejorD then
			mejor, mejorD = j, d
		end
	end
	self.objetivo = mejor
end

function Amaru:_posObjetivo(): Vector3
	return self.objetivo and self.objetivo.hrp.Position or self.pos
end


-- ---------- ciclo principal ----------
function Amaru:paso(dt: number)
	self.reloj += dt
	self.t += dt
	self.cdNube -= dt
	self.cdSombras -= dt
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
		if self.t > 1.8 then
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
	if suaveY ~= false then
		self.yVisual += (self.pos.Y - self.yVisual) * math.min(1, dt * 8)
	end
	local hundido = self.enterrado and -60 or 0
	self.raiz.CFrame = CFrame.new(self.pos.X, self.yVisual + hundido, self.pos.Z) * CFrame.Angles(0, self.yaw, 0)
	for _, a in { self.avisoCirculo, self.avisoRect, table.unpack(self.avisosPlumas) } do
		if a.Transparency < 1 then
			a.Transparency = 0.35 + 0.25 * math.sin(self.reloj * 14)
		end
	end
	if self.fase2 and not self.muerto then
		local k = 0.5 + 0.5 * math.sin(self.reloj * (self.furioso and 6 or 2.5))
		for _, f in self.plumasBrillo do
			f.Color = Color3.fromRGB(120 + 80 * k, 50 + 40 * k, 200 + 55 * k)
		end
	end
	self:_publicar()
end

function Amaru:_cambiar(nuevo: string)
	self.estado = nuevo
	self.t = 0
end

function Amaru:_vagar(dt: number)
	if self.espera > 0 then
		self.espera -= dt
		self:_anim("reposo")
		return
	end
	if not self.destino then
		local p = PATRULLA[math.random(1, #PATRULLA)]
		self.destino = sueloCuevas(p.X + math.random(-10, 10), p.Y + math.random(-10, 10))
	end
	if self:_dist(self.destino) < 4 then
		self.destino = nil
		self.espera = math.random(15, 40) / 10
		return
	end
	self:_girarHacia(self:_yawHacia(self.destino), 1.5, dt)
	if self:_mover(dt, 4.2) then
		self.destino = nil
	end
	self:_anim("reptar", 1)
end

function Amaru:_alertar()
	if self.alerta or self.muerto then
		return
	end
	self.alerta = true
	self.lejos = 0
	self:_cambiar("rugir")
	self.servicios.anunciar("¡Amaru te ha detectado!", Color3.fromRGB(192, 112, 255))
end

function Amaru:_perseguir(dt: number)
	if not self.objetivo then
		self:_anim("reposo")
		return
	end
	local objetivo = self:_posObjetivo()
	local dist = self:_dist(objetivo)
	self:_girarHacia(self:_yawHacia(objetivo), self.furioso and 2.8 or 2.2, dt)
	if dist > 8 then
		local v = self.furioso and 8.2 or 6.8
		self:_mover(dt, v)
		self:_anim("reptar", 1.8)
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
			o("mordida", 3)
		end
		if dist < 14 and ang > 1.3 then
			o("latigazo", 3)
		end
		if dist < 16 then
			o("enroscarse", 1.5)
		end
		if dist > 8 and dist < 26 then
			o("planeo", 2)
		end
		if dist > 8 and dist < 30 and ang < 0.6 then
			o("rayo", self.fase2 and 3 or 2)
		end
		if dist < 24 then
			o("plumas", 2)
		end
		if self.cdNube <= 0 then
			o("nube", 1.5)
		end
		if dist > 6 and self.cdSombras <= 0 then
			o("sombras", 2)
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

function Amaru:_duraciones()
	local d = ATAQUES[self.ataque]
	local k = (self.furioso and 1.2 or 1) * (self.fase2 and 1.15 or 1)
	return d.prep / k, d.activo / k, d.rec / k
end

function Amaru:_iniciarAtaque(nombre: string)
	self:_cambiar("ataque")
	self.ataque = nombre
	self.fase = ""
	self.tFase = 0
	self.golpeados = {}
	self.hecho = false
	self.dirGiro = math.random() < 0.5 and -1 or 1
	self:_anim(nombre)
	if nombre == "nube" then
		self.cdNube = 18
	elseif nombre == "sombras" then
		self.cdSombras = 10
	elseif nombre == "plumas" then
		-- los puntos donde caerán las plumas se eligen al empezar
		self.puntosPlumas = {}
		local centro = self:_posObjetivo()
		for i = 1, self.fase2 and 7 or 5 do
			local ang = math.random() * math.pi * 2
			local d = (i == 1) and 0 or math.random(3, 9)
			table.insert(self.puntosPlumas, centro + Vector3.new(math.cos(ang) * d * S, 0, math.sin(ang) * d * S))
		end
	end
end

function Amaru:_terminarAtaque()
	self:_ocultarAvisos()
	self.enterrado = false
	self:_cambiar("perseguir")
	self.cd = (math.random(5, 12) / 10) * (self.furioso and 0.6 or 1)
end

function Amaru:_golpear(prueba, origen: Vector3)
	local d = ATAQUES[self.ataque]
	local mult = 1
	for _, j in self.servicios.jugadores("cuevas") do
		if j.atacable and not self.golpeados[j.hrp] and prueba(j.hrp.Position) then
			self.golpeados[j.hrp] = true
			self.servicios.danio(j.jugador, d.danio * mult * (self.furioso and 1.15 or 1), origen, d.empuje, "amaru_" .. self.ataque)
		end
	end
end


function Amaru:_ataque(dt: number): boolean
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
	if a == "mordida" then
		local punto = self.pos + adelante * 6 * S
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 3.2, dt)
			self:_avisoCirculo(punto, 3)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self:_mover(dt, 7)
			self:_golpear(function(p)
				return plano(p, self.pos + adelante * 6 * S) < 3
			end, punto)
		end
	elseif a == "latigazo" then
		if self.fase == "prep" then
			self:_avisoCirculo(self.pos, 16)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			self.yaw += self.dirGiro * (math.pi * 1.3 / act) * dt
			local cola = -self:_adelante()
			self:_golpear(function(p)
				local d = Vector3.new(p.X - self.pos.X, 0, p.Z - self.pos.Z)
				local m = d.Magnitude / S
				return m > 3 and m < 16 and d.Unit:Dot(cola) > math.cos(0.5)
			end, self.pos)
		end
	elseif a == "enroscarse" then
		if self.fase == "prep" then
			if tf < prep - 0.3 then
				self.centroEnrosque = Vector3.new(objetivo.X, 0, objetivo.Z)
			end
			self:_avisoCirculo(self.centroEnrosque, 7)
		elseif self.fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			local c = self.centroEnrosque
			self.pos = Vector3.new(c.X, Config.alturaEn(c.X, c.Z), c.Z)
			self:_golpear(function(p)
				return plano(p, c) < 7
			end, c)
		end
	elseif a == "planeo" then
		if self.fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			if tf < prep - 0.25 then
				self.desde = self.pos
				self.hasta = Vector3.new(objetivo.X, 0, objetivo.Z)
			end
			self:_avisoCirculo(self.hasta or self.pos, 5)
		elseif self.fase == "activo" then
			local k = math.clamp(tf / act, 0, 1)
			local p = self.desde:Lerp(self.hasta, k)
			self.pos = Vector3.new(p.X, Config.alturaEn(p.X, p.Z), p.Z)
			self.yVisual = self.pos.Y + math.sin(k * math.pi) * 10 * S
			return false
		elseif self.fase == "rec" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_golpear(function(p)
				return plano(p, self.pos) < 5
			end, self.pos)
		end
	elseif a == "rayo" then
		local desde = self.pos + adelante * 5 * S
		local ancho = self.fase2 and 6.5 or 4.6
		local largo = 28
		if self.fase == "prep" then
			if tf < prep - 0.3 then
				self:_girarHacia(self:_yawHacia(objetivo), 1.4, dt)
			end
			self:_avisoRect(desde, self.yaw, ancho, largo)
		elseif self.fase == "activo" then
			self:_ocultarAvisos()
			local medio = desde + adelante * largo * 0.5 * S
			self.rayo.Transparency = 0.1
			self.rayo.Size = Vector3.new(ancho * 0.6 * S, 1.6 * S, largo * S)
			self.rayo.CFrame = CFrame.new(Vector3.new(medio.X, Config.alturaEn(medio.X, medio.Z) + 2 * S, medio.Z)) * CFrame.Angles(0, self.yaw, 0)
			self:_golpear(function(p)
				local rel = Vector3.new(p.X - desde.X, 0, p.Z - desde.Z) / S
				local aLoLargo = rel:Dot(adelante)
				local alLado = math.abs(rel:Cross(adelante).Y)
				return aLoLargo > -1 and aLoLargo < largo and alLado < ancho / 2
			end, desde)
		else
			self.rayo.Transparency = 1
		end
	elseif a == "plumas" then
		if self.fase == "prep" then
			for i, p in self.puntosPlumas do
				local av = self.avisosPlumas[i]
				if av.Transparency >= 1 then
					av.Transparency = 0.4
				end
				av.Size = Vector3.new(0.3, 6 * S, 6 * S)
				av.CFrame = CFrame.new(p.X, Config.alturaEn(p.X, p.Z) + 0.35, p.Z) * CFrame.Angles(0, 0, math.rad(90))
			end
		elseif self.fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			for _, p in self.puntosPlumas do
				self:_caerPlumas(p)
			end
			self:_golpear(function(pj)
				for _, p in self.puntosPlumas do
					if plano(pj, p) < 3 then
						return true
					end
				end
				return false
			end, self.pos)
		end
	elseif a == "nube" then
		if self.fase == "activo" and not self.hecho then
			self.hecho = true
			self:_nube()
		end
	elseif a == "sombras" then
		if self.fase == "prep" then
			if tf > prep * 0.6 then
				self.enterrado = true
			end
		elseif self.fase == "activo" then
			self.enterrado = true
			if self.objetivo and not self.hecho then
				local hrp = self.objetivo.hrp
				local atras = hrp.Position - hrp.CFrame.LookVector * 6 * S
				self.pos = Vector3.new(atras.X, Config.alturaEn(atras.X, atras.Z), atras.Z)
				self.yaw = self:_yawHacia(hrp.Position)
				self:_avisoCirculo(self.pos + self:_adelante() * 3 * S, 3.5)
			end
		elseif self.fase == "rec" and not self.hecho then
			self.hecho = true
			self.enterrado = false
			self:_ocultarAvisos()
			local punto = self.pos + self:_adelante() * 3 * S
			self:_humo(self.pos, 40)
			self:_golpear(function(p)
				return plano(p, punto) < 3.5
			end, punto)
		end
	end
	return true
end

-- ---------- efectos de sombra ----------
function Amaru:_humo(pos: Vector3, cantidad: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = pos + Vector3.new(0, 2, 0)
	p.Parent = workspace
	local e = self.humo:Clone()
	e.Rate = 0
	e.Speed = NumberRange.new(6, 14)
	e.Size = NumberSequence.new(2.5, 0)
	e.Parent = p
	e:Emit(cantidad)
	Debris:AddItem(p, 3)
end

function Amaru:_caerPlumas(p: Vector3)
	for k = 1, 3 do
		local pluma = Instance.new("Part")
		pluma.Anchored = true
		pluma.CanCollide = false
		pluma.CanQuery = false
		pluma.Material = Enum.Material.Neon
		pluma.Color = Color3.fromRGB(160, 76, 224)
		pluma.Size = Vector3.new(0.5, 3, 1.2)
		local suelo = Config.alturaEn(p.X, p.Z)
		pluma.CFrame = CFrame.new(p.X + (k - 2) * 2, suelo + 2, p.Z + (k % 2) * 2) * CFrame.Angles(0.3 * k, k, 0)
		pluma.Parent = workspace
		Debris:AddItem(pluma, 2.5)
	end
	self:_humo(p, 12)
end

-- Nube de sombra: una esfera oscura que no deja ver a quienes están adentro.
function Amaru:_nube()
	local nube = Instance.new("Part")
	nube.Name = "NubeSombra"
	nube.Shape = Enum.PartType.Ball
	nube.Anchored = true
	nube.CanCollide = false
	nube.CanQuery = false
	nube.Material = Enum.Material.SmoothPlastic
	nube.Color = Color3.fromRGB(20, 10, 30)
	nube.Transparency = 0.35
	nube.Size = Vector3.one * 36 * S
	nube.Position = self.pos
	nube:SetAttribute("Radio", 18 * S)
	nube.Parent = workspace
	local humo = self.humo:Clone()
	humo.Rate = 60
	humo.Size = NumberSequence.new(4, 0)
	humo.Parent = nube
	self.servicios.anunciar("¡Amaru envuelve todo en sombras!", Color3.fromRGB(192, 112, 255))
	Debris:AddItem(nube, 8)
end

-- ---------- avisos y efectos ----------
function Amaru:_avisoCirculo(centro: Vector3, radio: number)
	local c = self.avisoCirculo
	if c.Transparency >= 1 then
		c.Transparency = 0.4
	end
	c.Size = Vector3.new(0.3, radio * 2 * S, radio * 2 * S)
	c.CFrame = CFrame.new(centro.X, Config.alturaEn(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, 0, math.rad(90))
end

function Amaru:_avisoRect(inicio: Vector3, yaw: number, ancho: number, largo: number)
	local r = self.avisoRect
	if r.Transparency >= 1 then
		r.Transparency = 0.4
	end
	local dir = CFrame.Angles(0, yaw, 0).LookVector
	local centro = inicio + dir * largo * 0.5 * S
	r.Size = Vector3.new(ancho * S, 0.3, largo * S)
	r.CFrame = CFrame.new(centro.X, Config.alturaEn(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, yaw, 0)
end

function Amaru:_ocultarAvisos()
	self.avisoCirculo.Transparency = 1
	self.avisoRect.Transparency = 1
	self.rayo.Transparency = 1
	for _, a in self.avisosPlumas do
		a.Transparency = 1
	end
end

function Amaru:_polvo(pos: Vector3, cantidad: number, color: Color3?)
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
function Amaru:zonas()
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

function Amaru:recibirGolpe(z, info, jugador: Player?)
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

function Amaru:_danio(danio: number)
	if self.muerto then
		return
	end
	self.vida -= danio
	if not self.fase2 and self.vida < self.vidaMax * 0.5 and self.vida > 0 then
		self:_eclipsar(false)
	end
	if not self.furioso and self.vida < self.vidaMax * 0.4 and self.vida > 0 then
		self.furioso = true
		self.servicios.anunciar("¡Amaru está furioso!", Color3.fromRGB(192, 112, 255))
	end
	if self.vida <= 0 then
		self.vida = 0
		self:_morir()
	end
end


function Amaru:_romper(id: string)
	local p = self.partes[id]
	p.rota = true
	p.vida = 0
	table.insert(self.caceria.partes, id)
	self.servicios.anunciar("¡Rompiste: " .. p.nombre .. "!", Color3.fromRGB(255, 224, 138))
	if id == "cuernos" then
		for _, c in self.cuernos do
			c.Transparency = 1
		end
	elseif id == "alas" then
		for _, a in self.alas do
			a.Transparency = 0.7
		end
	elseif id == "cresta" then
		for _, f in self.cresta do
			f.Transparency = 1
		end
		self:_eclipsar(true)
		return
	end
	if self.estado ~= "derribado" and self.estado ~= "muerto" then
		self:_ocultarAvisos()
		self.enterrado = false
		self:_cambiar("estremecer")
	end
end

-- Segunda fase: se abre el eclipse detrás de su cabeza y suelta humo oscuro.
function Amaru:_eclipsar(porRomper: boolean)
	if self.fase2 then
		return
	end
	self.fase2 = true
	for _, e in self.eclipse do
		e.Transparency = 0
	end
	self.humo.Rate = 20
	self:_humo(self.pos, 60)
	self.servicios.anunciar(porRomper and "¡La cresta se abre en un eclipse!" or "¡Amaru despierta el eclipse!", Color3.fromRGB(192, 112, 255))
	if not self.muerto and self.estado ~= "derribado" then
		self:_ocultarAvisos()
		self.enterrado = false
		self:_cambiar("rugir")
	end
end

function Amaru:_derribar()
	self.caceria.derribos += 1
	self:_ocultarAvisos()
	self.enterrado = false
	self.derribo = 0
	self.derriboMax *= 1.3
	self:_humo(self.pos, 40)
	self.servicios.anunciar("¡Amaru cayó! Aprovecha", Color3.fromRGB(63, 208, 200))
	self:_cambiar("derribado")
end

function Amaru:_morir()
	self.muerto = true
	self:_ocultarAvisos()
	self.enterrado = false
	self.humo.Rate = 0
	for nombre, h in self.heridas do
		h.marca:Destroy()
		self.heridas[nombre] = nil
	end
	self:_cambiar("muerto")
	self:_terminarCaceria(true)
end

function Amaru:desmayo(jugador: Player?)
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


function Amaru:_terminarCaceria(exito: boolean)
	if self.caceria.terminada then
		return
	end
	self.caceria.terminada = true
	local nombresMat = { cuernos = "Cuerno lunar", alas = "Pluma nocturna", cresta = "Fragmento de eclipse" }
	local claves = { cuernos = "cuerno_luna", alas = "pluma", cresta = "eclipse" }
	local recompensas = exito and { "+ 300 monedas", "+ 6 Escamas de sombra", "+ 2 Núcleos del desierto" } or {}
	local premios = exito and { monedas = 300, sombra = 6, nucleo = 2 } or {}
	local nombres = {}
	for _, id in self.caceria.partes do
		table.insert(nombres, DATOS_PARTES[id].nombre)
		table.insert(recompensas, "+ 2 " .. nombresMat[id])
		premios[claves[id]] = (premios[claves[id]] or 0) + 2
	end
	self.servicios.recompensar(premios, self.participantes)
	self.servicios.resultados(self.participantes, {
		behemoth = "Amaru", exito = exito, tiempo = self.tiempo, partes = nombres,
		derribos = self.caceria.derribos, desmayos = self.caceria.desmayos, recompensas = recompensas,
	})
end

return Amaru
