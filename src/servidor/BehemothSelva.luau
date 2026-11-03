--!nonstrict
-- Base común de los Behemoths de la Selva de Obsidiana (Camazotz, Xolotl, Balam y Cipactli).
-- Hace todo lo que comparten: vida, persecución, avisos rojos, golpes a los cazadores, partes
-- rompibles, derribo, segunda fase, furia, desmayos y recompensas. Cada Behemoth solo define su
-- cuerpo (construir), qué ataque elegir (elegir) y qué hace cada ataque (atacar).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Compartido.Config)
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Estados = require(script.Parent.Estados)

local S = Config.S
local MULT_ZONA = { cuerpo = 1.0, cabeza = 1.3, pata = 0.9, cola = 1.0 }

local Base = {}
Base.__index = Base
Base.S = S

-- ---------- ayudas de geometría ----------
function Base.V(x, y, z)
	return Vector3.new(x, y, z) * S
end
function Base.CF(x, y, z)
	return CFrame.new(x * S, y * S, z * S)
end
local function plano(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude / S
end
Base.plano = plano

-- Crea un Behemoth a partir de su definición (ver Camazotz.luau como ejemplo).
function Base.nuevo(def, servicios)
	local self = setmetatable({}, Base)
	self.def = def
	self.servicios = servicios
	self.isla = Config.ISLAS[def.zona]
	self:_construirBase()
	def.construir(self)
	self:_terminarModelo()
	self:reiniciar()
	return self
end

-- ---------- modelo de bloques ----------
function Base:_parte(props): BasePart
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
	if props.Forma then
		p.Shape = props.Forma
	end
	p.Parent = self.modelo
	return p
end

function Base:_unir(p: BasePart, a: BasePart, c0: CFrame, c1: CFrame?, motor: string?)
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

-- Pieza unida a otra en un solo paso: self:_pieza(padre, nombre, tam, color, cf, extra)
function Base:_pieza(padre: BasePart, nombre: string, tam: Vector3, color: Color3, cf: CFrame, extra)
	local props = { Name = nombre, Size = tam, Color = color }
	for k, v in extra or {} do
		props[k] = v
	end
	local p = self:_parte(props)
	self:_unir(p, padre, cf)
	return p
end

-- Guarda una pieza en un grupo (para esconderla al romper esa parte o encenderla en la fase 2)
function Base:_grupo(nombre: string, p: BasePart)
	self.grupos[nombre] = self.grupos[nombre] or {}
	table.insert(self.grupos[nombre], { p, p.Transparency, p.Color })
	return p
end

function Base:_construirBase()
	local def = self.def
	local m = Instance.new("Model")
	m.Name = def.modelo
	self.modelo = m
	self.grupos = {}
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
	-- avisos rojos en el suelo: un círculo, un rectángulo y varios círculos más (lluvias de ataques)
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
	self.avisoCirculo = aviso("AvisoCirculo" .. def.modelo, Enum.PartType.Cylinder)
	self.avisoRect = aviso("AvisoRect" .. def.modelo, Enum.PartType.Block)
	self.avisosExtra = {}
	for i = 1, 8 do
		self.avisosExtra[i] = aviso("AvisoExtra" .. def.modelo, Enum.PartType.Cylinder)
	end
end

function Base:_terminarModelo()
	local def = self.def
	local m = self.modelo
	m:SetAttribute("Nombre", def.nombre)
	m:SetAttribute("Mapa", def.zona)
	local partes = {}
	for _, id in def.ordenPartes do
		table.insert(partes, id .. ":" .. def.partes[id].nombre)
	end
	m:SetAttribute("Partes", table.concat(partes, ";"))
	-- con streaming activado, el Behemoth debe llegar completo a todos los jugadores
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m.Parent = workspace:FindFirstChild("Behemoths") or workspace
end

-- ---------- suelo y movimiento ----------
function Base:altura(x: number, z: number): number
	return Config.alturaEn(x, z)
end

-- punto del suelo a partir de metros relativos al centro de la isla
function Base:sueloM(xm: number, zm: number): Vector3
	local c = self.isla.centro
	local x, z = c.X + xm * S, c.Z + zm * S
	return Vector3.new(x, self:altura(x, z), z)
end

function Base:suelo(p: Vector3): Vector3
	return Vector3.new(p.X, self:altura(p.X, p.Z), p.Z)
end

function Base:_adelante(): Vector3
	return CFrame.Angles(0, self.yaw, 0).LookVector
end

function Base:_yawHacia(p: Vector3): number
	local d = p - self.pos
	return math.atan2(-d.X, -d.Z)
end

function Base:_girarHacia(yaw: number, rapidez: number, dt: number)
	local dif = (yaw - self.yaw + math.pi) % (math.pi * 2) - math.pi
	self.yaw += math.clamp(dif, -rapidez * dt, rapidez * dt)
end

function Base:_angulo(p: Vector3): number
	return math.abs((self:_yawHacia(p) - self.yaw + math.pi) % (math.pi * 2) - math.pi)
end

function Base:_dist(p: Vector3): number
	return Vector2.new(p.X - self.pos.X, p.Z - self.pos.Z).Magnitude / S
end

-- Mueve hacia adelante; devuelve true si chocó con el borde de la isla.
function Base:_mover(dt: number, velocidad: number, direccion: Vector3?): boolean
	local dir = direccion or self:_adelante()
	local nueva = self.pos + dir * velocidad * Estados.freno(self) * S * dt
	return self:_ponerEn(nueva)
end

-- El punto más cercano a "p" donde puede estar el Behemoth (sin moverlo): para apuntar ataques.
function Base:_limitar(p: Vector3): Vector3
	local centro = Vector2.new(self.isla.centro.X, self.isla.centro.Z)
	local plano2 = Vector2.new(p.X, p.Z)
	local radio = (self.def.radioIsla or 100) * S
	if (plano2 - centro).Magnitude > radio then
		plano2 = centro + (plano2 - centro).Unit * radio
	end
	local camp = centro + self.isla.campamento * S
	if (plano2 - camp).Magnitude < 26 * S then
		plano2 = camp + (plano2 - camp).Unit * 26 * S
	end
	for _, o in self.def.evitar or {} do
		local c = centro + Vector2.new(o[1], o[2]) * S
		if (plano2 - c).Magnitude < o[3] * S then
			plano2 = c + (plano2 - c).Unit * o[3] * S
		end
	end
	return Vector3.new(plano2.X, self:altura(plano2.X, plano2.Y), plano2.Y)
end

-- Coloca al Behemoth en un punto (respetando el borde de la isla y el campamento).
function Base:_ponerEn(nueva: Vector3): boolean
	local centro = Vector2.new(self.isla.centro.X, self.isla.centro.Z)
	local plano2 = Vector2.new(nueva.X, nueva.Z)
	local choco = false
	local radio = (self.def.radioIsla or 100) * S
	if (plano2 - centro).Magnitude > radio then
		plano2 = centro + (plano2 - centro).Unit * radio
		choco = true
		self.destino = nil
	end
	local camp = centro + self.isla.campamento * S
	if (plano2 - camp).Magnitude < 26 * S then
		plano2 = camp + (plano2 - camp).Unit * 26 * S
		self.destino = nil
	end
	-- construcciones grandes que rodea (pirámides, canchas...): { x, z, radio } en metros
	for _, o in self.def.evitar or {} do
		local c = centro + Vector2.new(o[1], o[2]) * S
		if (plano2 - c).Magnitude < o[3] * S then
			plano2 = c + (plano2 - c).Unit * o[3] * S
			self.destino = nil
		end
	end
	self.pos = Vector3.new(plano2.X, self:altura(plano2.X, plano2.Y), plano2.Y)
	return choco
end

-- ---------- vida y estado ----------
function Base:jugadores()
	return self.servicios.jugadores(self.def.zona)
end

function Base:reiniciar()
	local def = self.def
	local n = math.max(1, #self:jugadores())
	self.vidaMax = def.vidaBase * (1 + 0.6 * (n - 1))
	self.vida = self.vidaMax
	self.estado = "vagar"
	self.alerta, self.fase2, self.furioso, self.muerto, self.enterrado = false, false, false, false, false
	self.derribo, self.derriboMax = 0, def.derriboMax or 240
	for _, h in self.heridas or {} do
		h.marca:Destroy() -- las marcas de heridas de la cacería anterior
	end
	self.heridas = {}
	self.usos = {}
	self.t, self.reloj, self.cd, self.lejos, self.espera = 0, 0, 2, 0, 0
	self.tiempo = 0
	self.tSinGolpes = 0
	self.altoExtra = 0
	self.destino = nil
	self.caceria = { partes = {}, derribos = 0, desmayos = 0, terminada = false }
	self.participantes = {}
	Estados.iniciar(self)
	self.partes = {}
	for id, d in def.partes do
		self.partes[id] = { nombre = d.nombre, max = d.max, vida = d.max, rota = false }
	end
	-- todas las piezas vuelven a su aspecto original
	for _, lista in self.grupos do
		for _, x in lista do
			x[1].Transparency = x[2]
			x[1].Color = x[3]
		end
	end
	local p = def.patrulla[math.random(1, #def.patrulla)]
	self.pos = self:sueloM(p.X, p.Y)
	self.yVisual = self.pos.Y
	self.yaw = math.random() * math.pi * 2
	self:_ocultarAvisos()
	if def.alReiniciar then
		def.alReiniciar(self)
	end
	self:_anim("reposo")
	self:_publicar()
end

function Base:_anim(nombre: string, ritmo: number?)
	if self.modelo:GetAttribute("Anim") ~= nombre then
		self.modelo:SetAttribute("Anim", nombre)
		self.modelo:SetAttribute("AnimT0", workspace:GetServerTimeNow())
	end
	self.modelo:SetAttribute("Ritmo", ritmo or 1)
end

function Base:_publicar()
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

function Base:_elegirObjetivo(dt: number)
	self.tObjetivo = (self.tObjetivo or 0) - dt
	local valido = false
	if self.objetivo then
		for _, j in self:jugadores() do
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
	for _, j in self:jugadores() do
		local d = self:_dist(j.hrp.Position)
		if j.atacable and d < mejorD then
			mejor, mejorD = j, d
		end
	end
	self.objetivo = mejor
end

function Base:_posObjetivo(): Vector3
	return self.objetivo and self.objetivo.hrp.Position or self.pos
end

-- ---------- ciclo principal ----------
function Base:paso(dt: number)
	local def = self.def
	self.reloj += dt
	self.t += dt
	self.tSinGolpes += dt
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
	if not self.muerto and not self.alerta and hay and self:_dist(self:_posObjetivo()) < (def.distanciaAlerta or 22) and self.estado == "vagar" then
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
	if def.paso then
		def.paso(self, dt)
	end
	if suaveY ~= false then
		self.yVisual += (self.pos.Y + (self.altoExtra or 0) - self.yVisual) * math.min(1, dt * 8)
	end
	self.raiz.CFrame = CFrame.new(self.pos.X, self.yVisual, self.pos.Z) * CFrame.Angles(0, self.yaw, 0)
	local brillo = 0.35 + 0.25 * math.sin(self.reloj * 14)
	if self.avisoCirculo.Transparency < 1 then
		self.avisoCirculo.Transparency = brillo
	end
	if self.avisoRect.Transparency < 1 then
		self.avisoRect.Transparency = brillo
	end
	for _, a in self.avisosExtra do
		if a.Transparency < 1 then
			a.Transparency = brillo
		end
	end
	self:_publicar()
end

function Base:_cambiar(nuevo: string)
	self.estado = nuevo
	self.t = 0
end

function Base:_vagar(dt: number)
	local def = self.def
	if self.espera > 0 then
		self.espera -= dt
		self:_anim("reposo")
		return
	end
	if not self.destino then
		local p = def.patrulla[math.random(1, #def.patrulla)]
		self.destino = self:sueloM(p.X + math.random(-10, 10), p.Y + math.random(-10, 10))
	end
	if self:_dist(self.destino) < 4 then
		self.destino = nil
		self.espera = math.random(20, 50) / 10
		return
	end
	self:_girarHacia(self:_yawHacia(self.destino), 1.4, dt)
	if self:_mover(dt, def.velVagar or 3.6) then
		self.destino = nil
	end
	self:_anim("caminar", 1)
end

function Base:_alertar()
	if self.alerta or self.muerto then
		return
	end
	self.alerta = true
	self.lejos = 0
	self:_cambiar("rugir")
	self.servicios.anunciar("¡" .. self.def.nombre .. " te ha detectado!", self.def.colorTexto)
end

function Base:_perseguir(dt: number)
	local def = self.def
	if not self.objetivo then
		self:_anim("reposo")
		return
	end
	local objetivo = self:_posObjetivo()
	local dist = self:_dist(objetivo)
	self:_girarHacia(self:_yawHacia(objetivo), self.furioso and 2.4 or 1.9, dt)
	if dist > (def.distanciaCerca or 8) then
		local v = self.furioso and (def.velPerseguir or 6.2) * 1.25 or (def.velPerseguir or 6.2)
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
		def.elegir(self, dist, ang, o)
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

function Base:_duraciones()
	local d = self.def.ataques[self.ataque]
	local k = (self.furioso and 1.2 or 1) * (self.fase2 and 1.12 or 1)
	return d.prep / k, d.activo / k, d.rec / k
end

-- segundos desde la última vez que usó ese ataque (para no repetir los especiales)
function Base:_hace(nombre: string): number
	return self.reloj - ((self.usos or {})[nombre] or -999)
end

function Base:_iniciarAtaque(nombre: string)
	self:_cambiar("ataque")
	self.usos = self.usos or {}
	self.usos[nombre] = self.reloj
	self.ataque = nombre
	self.fase = ""
	self.tFase = 0
	self.golpeados = {}
	self.hecho = false
	self.datosAtaque = {}
	-- el cliente anima el ataque con sus tiempos (y más rápido si está furioso o en la fase 2)
	local d = self.def.ataques[nombre]
	self.modelo:SetAttribute("Prep", d.prep)
	self.modelo:SetAttribute("Act", d.activo)
	self.modelo:SetAttribute("Rec", d.rec)
	self.modelo:SetAttribute("AnimT0", workspace:GetServerTimeNow())
	self.modelo:SetAttribute("Anim", nombre)
	self.modelo:SetAttribute("Ritmo", (self.furioso and 1.2 or 1) * (self.fase2 and 1.12 or 1))
end

function Base:_terminarAtaque()
	self:_ocultarAvisos()
	self.altoExtra = 0
	if self.def.alTerminarAtaque then
		self.def.alTerminarAtaque(self)
	end
	self:_cambiar("perseguir")
	self.cd = (math.random(5, 13) / 10) * (self.furioso and 0.6 or 1)
end

function Base:_ataque(dt: number): boolean
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
	local ctx = {
		prep = prep, act = act, rec = rec, tf = self.tFase - self.inicioFase, dt = dt,
		adelante = self:_adelante(), objetivo = self:_posObjetivo(),
	}
	local r = self.def.atacar(self, self.ataque, ctx)
	return r ~= false
end

-- Daña a los cazadores que cumplen la prueba (una vez por ataque). mult opcional.
-- Devuelve la lista de cazadores a los que el golpe sí les hizo daño (nil si a nadie): los que
-- lo esquivaron o lo bloquearon no cuentan, así no sangran ni se frenan por un golpe que no llegó.
function Base:_golpear(prueba, origen: Vector3, mult: number?, nombreAtaque: string?)
	local nombre = nombreAtaque or self.ataque
	local d = self.def.ataques[nombre] or self.def.ataques[self.ataque]
	local alcanzados
	for _, j in self:jugadores() do
		if j.atacable and not self.golpeados[j.hrp] and prueba(j.hrp.Position) then
			self.golpeados[j.hrp] = true
			if self.servicios.danio(j.jugador, d.danio * (mult or 1) * (self.furioso and 1.15 or 1), origen, d.empuje, self.def.prefijo .. nombre) then
				alcanzados = alcanzados or {}
				table.insert(alcanzados, j)
			end
		end
	end
	return alcanzados
end

-- Aturde a los cazadores cerca (salvo los que llevan el Yelmo del Murciélago u otra pieza que lo evite).
function Base:_aturdir(centro: Vector3, radio: number, segundos: number)
	for _, j in self:jugadores() do
		local char = j.jugador.Character
		if j.atacable and plano(j.hrp.Position, centro) < radio and not (char and (char:GetAttribute("Mod_sinAturdir") or 0) > 0) then
			Remotos.Aturdir:FireClient(j.jugador, segundos)
		end
	end
end

-- Frena a un cazador (el cliente baja su velocidad hasta ese momento).
function Base:_frenarCazador(j, segundos: number)
	local char = j.jugador.Character
	if char then
		char:SetAttribute("LentoHasta", workspace:GetServerTimeNow() + segundos)
	end
end

-- Sangrado: daño por segundo durante unos segundos. Cada tic pasa por el daño normal (armaduras
-- y escudos cuentan; rodar no lo esquiva) y se corta si el cazador deja la isla.
function Base:_sangrar(j, dps: number, segundos: number)
	local char = j.jugador.Character
	if not char or (char:GetAttribute("Sangrando") or 0) > workspace:GetServerTimeNow() then
		return
	end
	char:SetAttribute("Sangrando", workspace:GetServerTimeNow() + segundos)
	task.spawn(function()
		for _ = 1, segundos do
			task.wait(1)
			local hum = char.Parent and char:FindFirstChildOfClass("Humanoid")
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hum or hum.Health <= 0 or not hrp or j.jugador:GetAttribute("Zona") ~= self.def.zona then
				break
			end
			self.servicios.danio(j.jugador, dps, hrp.Position, 0, self.def.prefijo .. "sangrado", true)
		end
		char:SetAttribute("Sangrando", 0)
	end)
end

-- ---------- ataques comunes ----------
-- Se hunde (en el agua o el barro), viaja bajo tierra hasta su presa y sale de golpe.
-- o: { hundir (metros), velocidad (m/s), radio (metros), color, alSalir(self) }
function Base:_ataqueSumergido(c, o)
	local fase, tf = self.fase, c.tf
	local d = self.datosAtaque
	if fase == "prep" then
		self.altoExtra = -o.hundir * S * math.clamp(tf / c.prep, 0, 1)
		if not d.salpico then
			d.salpico = true
			self:_polvo(self.pos, 40, o.color)
		end
		if tf > c.prep * 0.8 then
			self.enterrado = true
		end
	elseif fase == "activo" then
		self.enterrado = true
		self.altoExtra = -o.hundir * S
		-- sigue a su presa hasta poco antes de salir; el círculo rojo marca dónde va a salir
		if tf < c.act - 0.7 then
			local meta = self:_limitar(c.objetivo)
			local hacia = Vector3.new(meta.X - self.pos.X, 0, meta.Z - self.pos.Z)
			if hacia.Magnitude > 1 then
				self.yaw = math.atan2(-hacia.X, -hacia.Z)
				self:_ponerEn(self.pos + hacia.Unit * math.min(hacia.Magnitude, o.velocidad * S * c.dt))
			end
			d.ondas = (d.ondas or 0) - c.dt
			if d.ondas <= 0 then
				d.ondas = 0.25
				self:_anillo(self.pos, 3, o.color, 0.4)
			end
		end
		self:_avisoCirculo(self.pos, o.radio)
	elseif not self.hecho then
		self.hecho = true
		self.enterrado = false
		self.altoExtra = 0
		self:_ocultarAvisos()
		self:_polvo(self.pos, 70, o.color)
		self:_anillo(self.pos, o.radio, o.color, 0.4)
		self:_golpear(function(p)
			return plano(p, self.pos) < o.radio
		end, self.pos, o.mult)
		if o.alSalir then
			o.alSalir(self)
		end
	end
end

-- Varios golpes que caen a la vez (rayos, géiseres): primero los círculos rojos, luego el golpe.
-- o: { cuantos, radio, color, alto (del efecto, metros), alGolpear(self, j) }
function Base:_lluvia(c, o)
	local d = self.datosAtaque
	if self.fase == "prep" then
		if not d.puntos then
			-- uno sobre cada cazador y el resto cerca de ellos
			d.puntos = {}
			local js = {}
			for _, j in self:jugadores() do
				if j.atacable then
					table.insert(js, j)
					table.insert(d.puntos, self:suelo(j.hrp.Position))
				end
			end
			while #d.puntos < math.min(o.cuantos, #self.avisosExtra) do
				local base = #js > 0 and js[math.random(1, #js)].hrp.Position or self.pos
				local a = math.random() * math.pi * 2
				local r = math.random(4, 11) * S
				table.insert(d.puntos, self:suelo(base + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)))
			end
			local lista = {}
			for _, p in d.puntos do
				table.insert(lista, { p, o.radio })
			end
			self:_avisosVarios(lista)
		end
	elseif self.fase == "activo" and not self.hecho then
		self.hecho = true
		self:_ocultarAvisos()
		for _, p in d.puntos or {} do
			self:_efecto(CFrame.new(p + Vector3.new(0, o.alto * S / 2, 0)), Vector3.new(1.2 * S, o.alto * S, 1.2 * S), o.color, 0.3)
			self:_anillo(p, o.radio, o.color, 0.35)
		end
		local alcanzados = self:_golpear(function(p)
			for _, x in d.puntos or {} do
				if plano(p, x) < o.radio then
					return true
				end
			end
			return false
		end, self.pos)
		if o.alGolpear and alcanzados then
			for _, j in alcanzados do
				o.alGolpear(self, j)
			end
		end
	end
end

-- ---------- efectos ----------
function Base:_polvo(pos: Vector3, cantidad: number, color: Color3?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = Vector3.new(pos.X, self:altura(pos.X, pos.Z) + 1, pos.Z)
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color or self.def.colorPolvo or Color3.fromRGB(120, 110, 90))
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

-- Un bloque temporal (rayos, ondas, proyectiles): desaparece solo.
function Base:_efecto(cf: CFrame, tam: Vector3, color: Color3, duracion: number, forma: Enum.PartType?, neon: boolean?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = neon == false and Enum.Material.SmoothPlastic or Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.25
	p.Size = tam
	if forma then
		p.Shape = forma
	end
	p.CFrame = cf
	p.Parent = workspace
	Debris:AddItem(p, duracion)
	return p
end

-- Un anillo que se expande (ondas, golpes contra el suelo)
function Base:_anillo(centro: Vector3, radio: number, color: Color3, duracion: number?)
	local base = self:suelo(centro) + Vector3.new(0, 0.4, 0)
	local p = self:_efecto(CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.4, 2, 2), color, (duracion or 0.4) + 0.05, Enum.PartType.Cylinder)
	p.Transparency = 0.2
	task.spawn(function()
		local t0 = os.clock()
		local dur = duracion or 0.4
		while os.clock() - t0 < dur and p.Parent do
			local k = (os.clock() - t0) / dur
			p.Size = Vector3.new(0.4, radio * 2 * S * k, radio * 2 * S * k)
			p.Transparency = 0.2 + 0.8 * k
			task.wait()
		end
	end)
end

function Base:_avisoCirculo(centro: Vector3, radio: number)
	local c = self.avisoCirculo
	if c.Transparency >= 1 then
		c.Transparency = 0.4
	end
	c.Size = Vector3.new(0.3, radio * 2 * S, radio * 2 * S)
	c.CFrame = CFrame.new(centro.X, self:altura(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, 0, math.rad(90))
end

function Base:_avisoRect(inicio: Vector3, yaw: number, ancho: number, largo: number)
	local r = self.avisoRect
	if r.Transparency >= 1 then
		r.Transparency = 0.4
	end
	local dir = CFrame.Angles(0, yaw, 0).LookVector
	local centro = inicio + dir * largo * 0.5 * S
	r.Size = Vector3.new(ancho * S, 0.3, largo * S)
	r.CFrame = CFrame.new(centro.X, self:altura(centro.X, centro.Z) + 0.35, centro.Z) * CFrame.Angles(0, yaw, 0)
end

-- Varios círculos a la vez: lista de { pos, radio }
function Base:_avisosVarios(lista)
	for i, a in self.avisosExtra do
		local x = lista[i]
		if x then
			if a.Transparency >= 1 then
				a.Transparency = 0.4
			end
			a.Size = Vector3.new(0.3, x[2] * 2 * S, x[2] * 2 * S)
			a.CFrame = CFrame.new(x[1].X, self:altura(x[1].X, x[1].Z) + 0.35, x[1].Z) * CFrame.Angles(0, 0, math.rad(90))
		else
			a.Transparency = 1
		end
	end
end

function Base:_ocultarAvisos()
	self.avisoCirculo.Transparency = 1
	self.avisoRect.Transparency = 1
	for _, a in self.avisosExtra do
		a.Transparency = 1
	end
	if self.def.ocultarExtras then
		self.def.ocultarExtras(self)
	end
end

-- ---------- recibir golpes ----------
function Base:zonas()
	if self.muerto or self.enterrado then
		return {}
	end
	local lista = {}
	local cf = self.raiz.CFrame
	for _, z in self.def.zonas do
		table.insert(lista, { zona = z, pos = (cf * CFrame.new(z.pos * S)).Position, r = z.r * S })
	end
	return lista
end

function Base:recibirGolpe(z, info, jugador: Player?)
	if self.muerto then
		return
	end
	if jugador then
		self.participantes[jugador] = true
	end
	self.tSinGolpes = 0
	local parte = z.parte
	local m = MULT_ZONA[z.tipo] or 1
	if parte ~= "" and self.partes[parte] and self.partes[parte].rota then
		m = 1.3
	end
	if self.estado == "derribado" then
		m *= 1.25
	end
	if self.def.debil and self.def.debil(self, z) then
		m *= 1.5
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

function Base:_danio(danio: number)
	if self.muerto then
		return
	end
	self.vida -= danio
	if not self.fase2 and self.vida < self.vidaMax * 0.5 and self.vida > 0 then
		self:_entrarFase2()
	end
	if not self.furioso and self.vida < self.vidaMax * 0.35 and self.vida > 0 then
		self.furioso = true
		self.servicios.anunciar("¡" .. self.def.nombre .. " está furioso!", Color3.fromRGB(255, 100, 80))
	end
	if self.vida <= 0 then
		self.vida = 0
		self:_morir()
	end
end

-- cura al Behemoth (regeneración de Xolotl, mordida de Camazotz)
function Base:_curar(cantidad: number)
	if self.muerto then
		return
	end
	self.vida = math.min(self.vidaMax, self.vida + cantidad)
end

function Base:_entrarFase2()
	if self.fase2 then
		return
	end
	self.fase2 = true
	if self.def.alFase2 then
		self.def.alFase2(self)
	end
	self.servicios.anunciar(self.def.textoFase2, self.def.colorTexto)
	if not self.muerto and self.estado ~= "derribado" then
		self:_ocultarAvisos()
		self.altoExtra = 0
		self.enterrado = false
		if self.alerta then
			self:_cambiar("rugir")
		else
			self:_alertar() -- (el veneno pudo bajarle la vida sin que viera a nadie)
		end
	end
end

function Base:_romper(id: string)
	local p = self.partes[id]
	p.rota = true
	p.vida = 0
	table.insert(self.caceria.partes, id)
	self.servicios.anunciar("¡Rompiste: " .. p.nombre .. "!", Color3.fromRGB(255, 224, 138))
	for _, x in self.grupos[id] or {} do
		x[1].Transparency = 1
	end
	if self.def.alRomper then
		self.def.alRomper(self, id)
	end
	if self.estado ~= "derribado" and self.estado ~= "muerto" then
		self:_ocultarAvisos()
		self.altoExtra = 0
		self.enterrado = false
		self:_cambiar("estremecer")
	end
end

function Base:_derribar()
	self.caceria.derribos += 1
	self:_ocultarAvisos()
	self.enterrado = false
	self.altoExtra = 0
	self.derribo = 0
	self.derriboMax *= 1.3
	self:_polvo(self.pos, 50)
	self.servicios.anunciar("¡" .. self.def.nombre .. " cayó! Aprovecha", Color3.fromRGB(63, 208, 200))
	self:_cambiar("derribado")
end

function Base:_morir()
	self.muerto = true
	if self.def.alMorir then
		self.def.alMorir(self)
	end
	self:_ocultarAvisos()
	self.enterrado = false
	self.altoExtra = 0
	for nombre, h in self.heridas do
		h.marca:Destroy()
		self.heridas[nombre] = nil
	end
	self:_cambiar("muerto")
	self:_terminarCaceria(true)
end

function Base:desmayo(jugador: Player?)
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

function Base:_terminarCaceria(exito: boolean)
	if self.caceria.terminada then
		return
	end
	self.caceria.terminada = true
	local def = self.def
	local r = def.recompensa
	local recompensas = exito and { ("+ %d monedas"):format(r.monedas), ("+ 6 %s"):format(r.nombreBase), "+ 2 Núcleos del desierto" } or {}
	local premios = exito and { monedas = r.monedas, [r.base] = 6, nucleo = 2 } or {}
	local nombres = {}
	for _, id in self.caceria.partes do
		local mat = r.partes[id]
		table.insert(nombres, def.partes[id].nombre)
		table.insert(recompensas, "+ 2 " .. mat[2])
		premios[mat[1]] = (premios[mat[1]] or 0) + 2
	end
	self.servicios.recompensar(premios, self.participantes)
	self.servicios.resultados(self.participantes, {
		behemoth = def.nombre, exito = exito, tiempo = self.tiempo, partes = nombres,
		derribos = self.caceria.derribos, desmayos = self.caceria.desmayos, recompensas = recompensas,
	})
end

return Base
