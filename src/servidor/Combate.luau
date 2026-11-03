--!nonstrict
-- Combate de los cazadores: ataques, esquivas, pociones, desmayos y el muñeco de práctica.
-- Las jugadoras piden el ataque; el servidor revisa los tiempos y decide si alcanzó.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)
local Armas = require(ReplicatedStorage.Compartido.Armas)
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Equipo = require(script.Parent.Equipo)
local Mundo = require(script.Parent.Mundo)
local Perfil = require(script.Parent.Perfil)
local Records = require(script.Parent.Records)
local Misiones -- se carga al usarlo (Misiones necesita el Perfil ya listo)
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local S = Config.S
local POCIONES = 3
local AGUANTE_MAX = 100 -- igual que en el cliente
local Combate = {}
local estados = {} -- por jugadora
local objetivos = {} -- cosas que se pueden golpear (Sekhmaur y el muñeco)

function Combate.agregarObjetivo(o)
	table.insert(objetivos, o)
end

local function ahora(): number
	return workspace:GetServerTimeNow()
end

local bloqueEfecto -- (se define más abajo)

-- modificador de las piezas de la selva (atributo Mod_<clave>); 1 o 0 si no lleva ninguna
local function mod(char: Model?, clave: string): number
	local v = char and char:GetAttribute("Mod_" .. clave)
	if typeof(v) == "number" then
		return v
	end
	return Armas.MOD_SUMA[clave] and 0 or 1
end
Combate.mod = mod

local function datosDe(jugador: Player)
	local e = estados[jugador]
	if not e then
		e = { combo = 0, ultimo = 0, ocupadoHasta = 0, invulHasta = 0, pociones = POCIONES }
		-- un jugador que ya salió no vuelve a la tabla (tareas con retraso que llegan tarde)
		if jugador.Parent then
			estados[jugador] = e
		end
	end
	return e
end

function Combate.numero(pos: Vector3, texto: string, color: Color3, grande: boolean?)
	Remotos.Numero:FireAllClients(pos, texto, color, grande == true)
end

function Combate.anunciar(texto: string, color: Color3?)
	Remotos.Anuncio:FireAllClients(texto, color or Color3.fromRGB(243, 214, 160))
end

-- Lista de cazadores en el desierto, para Sekhmaur.
local ZONAS_CACERIA = {}
for zona in Config.ISLAS do
	ZONAS_CACERIA[zona] = true
end
Combate.ZONAS_CACERIA = ZONAS_CACERIA

function Combate.jugadores(mapa: string?)
	mapa = mapa or "desierto"
	local lista = {}
	for _, j in Players:GetPlayers() do
		local char = j.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 and j:GetAttribute("Zona") == mapa then
			table.insert(lista, { jugador = j, hrp = hrp, atacable = not Config.enCampamento(hrp.Position) })
		end
	end
	return lista
end

-- Un ataque de un Behemoth alcanzó a un cazador. Devuelve true si el golpe llegó a hacer daño
-- (false si lo esquivó o lo absorbió el escudo). "continuo" = daño por segundo (sangrado):
-- no se esquiva rodando ni da los premios de la esquiva perfecta.
function Combate.danio(jugador: Player, danio: number, origen: Vector3, empuje: number, ataque: string, continuo: boolean?): boolean
	local e = datosDe(jugador)
	local char = jugador.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return false
	end
	if not continuo and ahora() < e.invulHasta then
		Combate.numero(hrp.Position + Vector3.new(0, 4, 0), "¡Esquiva perfecta!", Color3.fromRGB(63, 208, 200))
		if Armas.DATOS[char:GetAttribute("Arma") or ""] and Armas.DATOS[char:GetAttribute("Arma")].poderId == "ola" then
			e.olaLista = true
			Combate.auraFilo(char, true)
			Remotos.Anuncio:FireClient(jugador, "¡Filo cargado de arena!", Color3.fromRGB(230, 200, 130))
		end
		if (char:GetAttribute("Piezas_eclipse") or 0) >= 4 then
			e.invulHasta = ahora() + 1.0
			e.sombraLista = true
			Combate.pasoSombra(char)
			Remotos.Anuncio:FireClient(jugador, "¡Paso de Sombra!", Color3.fromRGB(192, 112, 255))
		end
		if (char:GetAttribute("Piezas_guardian") or 0) >= 4 then
			char:SetAttribute("DespertarHasta", ahora() + 6)
			Combate.despertar(char)
			Remotos.Anuncio:FireClient(jugador, "¡Despertar del Guardián! +15% de daño", Color3.fromRGB(63, 208, 200))
		end
		if Armas.DATOS[char:GetAttribute("Arma") or ""] and Armas.DATOS[char:GetAttribute("Arma")].poderId == "acecho" then
			e.acechoListo = true
			Remotos.Anuncio:FireClient(jugador, "¡Al acecho! Tu siguiente golpe hace el doble", Color3.fromRGB(80, 230, 160))
		end
		-- Vuelo de Xibalbá: la esquiva perfecta te cura
		if (char:GetAttribute("Piezas_xibalba") or 0) >= 4 and ahora() > (e.vueloCd or 0) then
			e.vueloCd = ahora() + 8
			hum.Health = math.min(hum.MaxHealth, hum.Health + 12)
			Combate.numero(hrp.Position + Vector3.new(0, 6, 0), "+12", Color3.fromRGB(120, 255, 140))
			Remotos.Anuncio:FireClient(jugador, "¡Vuelo de Xibalbá!", Color3.fromRGB(200, 140, 255))
		end
		-- Instinto del Jaguar: +20% de daño durante 5 s
		if (char:GetAttribute("Piezas_jaguar") or 0) >= 4 then
			e.instintoHasta = ahora() + 5
			Remotos.Anuncio:FireClient(jugador, "¡Instinto del Jaguar! +20% de daño", Color3.fromRGB(80, 230, 160))
		end
		return false
	end
	danio *= 1.15 -- los Behemoths pegan un poco más fuerte
	if (char:GetAttribute("Piezas_guardian") or 0) >= 2 and (ataque == "pisoton" or ataque == "embestida" or ataque == "enterrarse") then
		danio *= 0.8
	end
	if (char:GetAttribute("Piezas_rodador") or 0) >= 2 and (ataque == "bola" or ataque == "fuego") then
		danio *= 0.5
	end
	if char:GetAttribute("Lleva_caparazon") then
		danio *= 0.93
	end
	if char:GetAttribute("Lleva_manto") then
		danio *= 0.97
	end
	if (char:GetAttribute("Piezas_eclipse") or 0) >= 2 and string.sub(ataque or "", 1, 6) == "amaru_" then
		danio *= 0.8
	end
	-- sets de la selva: 2 piezas = 20% menos daño de su Behemoth
	for _, f in Armas.FAMILIAS do
		if f.prefijo and (char:GetAttribute("Piezas_" .. f.set) or 0) >= 2 and string.sub(ataque or "", 1, #f.prefijo) == f.prefijo then
			danio *= 0.8
		end
	end
	danio *= mod(char, "reduccion")
	-- Caparazón Solar: absorbe el daño antes que la vida
	e.ultimoDanio = ahora()
	local escudo = char:GetAttribute("Escudo") or 0
	if escudo > 0 then
		local absorbe = math.min(escudo, danio)
		char:SetAttribute("Escudo", escudo - absorbe)
		danio -= absorbe
		if escudo - absorbe <= 0 then
			Remotos.Anuncio:FireClient(jugador, "¡Se rompió el Caparazón Solar!", Color3.fromRGB(255, 154, 46))
		end
		if danio <= 0 then
			Combate.numero(hrp.Position + Vector3.new(0, 4, 0), "Bloqueado", Color3.fromRGB(255, 176, 80))
			return false
		end
	end
	if (e.pielHasta or 0) > ahora() then
		danio *= 0.5 -- Piel de Piedra
	end
	hum:TakeDamage(danio)
	Combate.numero(hrp.Position + Vector3.new(0, 4, 0), "-" .. math.floor(danio + 0.5), Color3.fromRGB(255, 106, 90))
	if (char:GetAttribute("Piezas_apu") or 0) >= 4 and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.4 and ahora() > (e.pielCd or 0) then
		e.pielHasta = ahora() + 4
		e.pielCd = ahora() + 60
		Combate.pielDePiedra(char)
		Remotos.Anuncio:FireClient(jugador, "¡Piel de Piedra!", Color3.fromRGB(200, 196, 188))
	end
	-- Escamas de la Creación: al bajar del 30% te curas 35 (una vez por minuto)
	if (char:GetAttribute("Piezas_cipactli") or 0) >= 4 and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.3 and ahora() > (e.escamasCd or 0) then
		e.escamasCd = ahora() + 60
		hum.Health = math.min(hum.MaxHealth, hum.Health + 35)
		Combate.numero(hrp.Position + Vector3.new(0, 6, 0), "+35", Color3.fromRGB(120, 255, 140))
		Remotos.Anuncio:FireClient(jugador, "¡Escamas de la Creación!", Color3.fromRGB(110, 200, 150))
	end
	if char:GetAttribute("Lleva_coraza_granito") then
		empuje *= 0.5
	end
	empuje *= mod(char, "empuje")
	local lejos = Vector3.new(hrp.Position.X - origen.X, 0, hrp.Position.Z - origen.Z)
	lejos = lejos.Magnitude > 0.01 and lejos.Unit or -hrp.CFrame.LookVector
	if empuje > 0 then
		Remotos.Empuje:FireClient(jugador, lejos * empuje * S, 0.5)
	end
	return true
end

-- ---------- golpes de los cazadores ----------
-- Distancia de un golpe a una parte: la altura cuenta menos que la distancia horizontal,
-- así el arma alcanza las partes altas (hombros, cabezas levantadas) si estás debajo.
local function distanciaAZona(centro: Vector3, z): number
	local d = z.pos - centro
	return math.sqrt(d.X * d.X + d.Z * d.Z + (d.Y * 0.35) ^ 2) - z.r
end

-- Cuando un golpe alcanza varias zonas, se prefieren las partes rompibles (si no están rotas)
-- y después patas, cabeza y cola, antes que el cuerpo: así el golpe va a lo que apuntas.
local function prioridad(o, zona): number
	local p = 0
	local parte = zona.parte
	if parte and parte ~= "" and parte ~= "bola" then
		local datos = o.partes and o.partes[parte]
		if not datos or not datos.rota then
			p += 1.5 * S
		end
	end
	if zona.tipo == "pata" or zona.tipo == "cabeza" or zona.tipo == "cola" then
		p += 0.6 * S
	end
	return p
end

local function aplicar(jugador: Player, zonaInfo, objetivo, arma, mult: number, fuerte: boolean, herida: boolean?, extra: { [string]: any }?)
	if not jugador.Parent then
		return -- el cazador ya salió (golpes con retraso, zonas que siguen activas)
	end
	local e = datosDe(jugador)
	local char = jugador.Character
	local despierta = char and (char:GetAttribute("DespertarHasta") or 0) > ahora()
	local info = {
		danio = arma.danio * mult * (despierta and 1.15 or 1),
		partes = arma.partes,
		aturdir = arma.aturdir,
		fuerte = fuerte,
		herida = herida or arma.herida == true,
		duracionHerida = herida and 20 or 12,
		multCabeza = (char and char:GetAttribute("Lleva_yelmo")) and 1.3 or 1,
	}
	if arma.poderId == "veneno" and info.herida then
		info.veneno = 6
	end
	if arma.poderId == "bola_fuego" then
		info.quemadura = 3
	end
	if arma.poderId == "sangrado" then
		info.sangrado = 4 -- Filo de Obsidiana: cada golpe lo hace sangrar
	end
	if arma.poderId == "acecho" and e.acechoListo then
		-- Lanza del Cazador Nocturno: después de una esquiva perfecta, golpe doble con herida
		e.acechoListo = false
		info.danio *= 2
		info.herida = true
		info.duracionHerida = 20
	end
	if extra then
		for k, v in extra do
			info[k] = v
		end
	end
	if e.sombraLista then
		e.sombraLista = false
		info.danio *= 1.2
	end
	if char and char:GetAttribute("Lleva_corona") and zonaInfo.zona.tipo == "cabeza" then
		info.danio *= 1.1
	end
	if char and char:GetAttribute("Lleva_punos_piedra") and fuerte then
		info.danio *= 1.1
	end
	if char and (char:GetAttribute("Piezas_apu") or 0) >= 2 then
		info.partes *= 1.15
	end
	-- piezas y sets de la selva
	if char then
		if zonaInfo.zona.tipo == "cabeza" then
			info.danio *= mod(char, "danioCabeza")
		end
		if fuerte then
			info.danio *= mod(char, "danioFuerte")
		end
		info.partes *= mod(char, "partes")
		info.aturdir *= mod(char, "aturdir")
		if (e.instintoHasta or 0) > ahora() then
			info.danio *= 1.2
		end
	end
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		local cura = (char:GetAttribute("Lleva_brazales") and 0.5 or 0) + ((arma.poderId == "vampiro" and info.herida) and 2 or 0) + mod(char, "curaGolpe")
		if cura > 0 then
			hum.Health = math.min(hum.MaxHealth, hum.Health + cura)
		end
	end
	objetivo:recibirGolpe(zonaInfo.zona, info, jugador)
	-- Furia de la Tormenta (4 piezas de Tláloc): cada 10 golpes cae un rayo
	-- (solo cuentan tus golpes, no los de charcos, remolinos y otras zonas que siguen dañando)
	if char and not info.secundario and (char:GetAttribute("Piezas_tlaloc") or 0) >= 4 and objetivo.modelo then
		e.golpesTormenta = (e.golpesTormenta or 0) + 1
		if e.golpesTormenta >= 10 then
			e.golpesTormenta = 0
			local p = zonaInfo.pos
			local rayo = bloqueEfecto(Vector3.new(1.4, 40, 1.4), Color3.fromRGB(150, 220, 255), true, 0.1)
			rayo.CFrame = CFrame.new(p + Vector3.new(0, 20, 0))
			Debris:AddItem(rayo, 0.25)
			objetivo:recibirGolpe(zonaInfo.zona, { danio = 60, partes = 1, aturdir = 2, fuerte = true, herida = false, duracionHerida = 12, multCabeza = 1 }, jugador)
		end
	end
	if objetivo.modelo then
		jugador:SetAttribute("Enfrentando", objetivo.modelo.Name)
	end
	e.ultimoGolpe = ahora()
end

-- ---------- efectos visuales de los bonos ----------
function Combate.auraFilo(char: Model, activa: boolean)
	local arma = char:FindFirstChild("Arma")
	for _, d in (arma and arma:GetDescendants() or {}) do
		if d:IsA("ParticleEmitter") and d.Name == "AuraFilo" then
			d.Enabled = activa
			d.Rate = activa and 25 or 0
		end
	end
end

-- Piel de Piedra: el cazador se cubre de piedra gris durante 4 segundos
function Combate.pielDePiedra(char: Model)
	local piel = Instance.new("Highlight")
	piel.Name = "PielDePiedra"
	piel.FillColor = Color3.fromRGB(140, 136, 128)
	piel.FillTransparency = 0.3
	piel.OutlineColor = Color3.fromRGB(255, 214, 90)
	piel.Parent = char
	Debris:AddItem(piel, 4)
end

-- Paso de Sombra: el cazador se vuelve una sombra morada durante 1 segundo
function Combate.pasoSombra(char: Model)
	local viejo = char:FindFirstChild("PasoSombra")
	if viejo then
		viejo:Destroy()
	end
	local sombra = Instance.new("Highlight")
	sombra.Name = "PasoSombra"
	sombra.FillColor = Color3.fromRGB(30, 10, 50)
	sombra.FillTransparency = 0.2
	sombra.OutlineColor = Color3.fromRGB(192, 112, 255)
	sombra.Parent = char
	Debris:AddItem(sombra, 1.0)
end

-- Despertar del Guardián: contorno turquesa y destellos durante 6 segundos
function Combate.despertar(char: Model)
	local viejo = char:FindFirstChild("Despertar")
	if viejo then
		viejo:Destroy()
	end
	local brillo = Instance.new("Highlight")
	brillo.Name = "Despertar"
	brillo.FillColor = Color3.fromRGB(63, 208, 200)
	brillo.FillTransparency = 0.75
	brillo.OutlineColor = Color3.fromRGB(127, 255, 244)
	brillo.OutlineTransparency = 0
	brillo.Parent = char
	local torso = char:FindFirstChild("Torso")
	if torso then
		local destellos = Instance.new("ParticleEmitter")
		destellos.Name = "DestellosDespertar"
		destellos.Color = ColorSequence.new(Color3.fromRGB(127, 255, 244))
		destellos.LightEmission = 1
		destellos.Rate = 30
		destellos.Size = NumberSequence.new(0.25, 0)
		destellos.Lifetime = NumberRange.new(0.5, 1)
		destellos.Speed = NumberRange.new(1, 3)
		destellos.SpreadAngle = Vector2.new(180, 180)
		destellos.Acceleration = Vector3.new(0, 4, 0)
		destellos.Parent = torso
		Debris:AddItem(destellos, 6)
	end
	Debris:AddItem(brillo, 6)
end

-- ---------- poderes de las armas ----------
local function zonasCerca(centro: Vector3, radio: number, maximo: number)
	local encontrados = {}
	for _, o in objetivos do
		for _, z in o:zonas() do
			local d = distanciaAZona(centro, z)
			if d < radio then
				table.insert(encontrados, { z = z, o = o, d = d - prioridad(o, z.zona) })
			end
		end
	end
	table.sort(encontrados, function(a, b)
		return a.d < b.d
	end)
	local lista, usados = {}, {}
	for _, f in encontrados do
		if #lista >= maximo then
			break
		end
		if not usados[f.z.zona] then
			usados[f.z.zona] = true
			table.insert(lista, f)
		end
	end
	return lista
end

local function efecto(pos: Vector3, tam: Vector3, color: Color3, duracion: number, forma: Enum.PartType?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.35
	p.Size = tam
	if forma then
		p.Shape = forma
	end
	p.CFrame = CFrame.new(pos) * (forma == Enum.PartType.Cylinder and CFrame.Angles(0, 0, math.rad(90)) or CFrame.new())
	p.Parent = workspace
	Debris:AddItem(p, duracion)
	return p
end

-- Altura del suelo en ese punto (el Mar de Dunas y las Cumbres del Inti tienen terrenos distintos)
local function alturaSuelo(x: number, z: number): number
	return Config.alturaEn(x, z)
end

local function suelo(pos: Vector3): Vector3
	return Vector3.new(pos.X, alturaSuelo(pos.X, pos.Z) + 0.3, pos.Z)
end

-- ---------- efectos visuales de los poderes que se quedan en el suelo ----------
function bloqueEfecto(tam: Vector3, color: Color3, neon: boolean?, transparencia: number?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.Color = color
	p.Transparency = transparencia or 0
	p.Size = tam
	p.Parent = workspace
	return p
end

local function polvo(padre: BasePart, color: Color3, cantidad: number, subida: number)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.8, 1.5)
	e.Rate = cantidad
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(180, 30)
	e.Acceleration = Vector3.new(0, subida, 0)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.Parent = padre
	return e
end

-- Tornado de bloques: anillos que se ensanchan hacia arriba y giran.
local function tornado(base: Vector3, radio: number, duracion: number, colores)
	local anillos = {}
	local ARENA = colores and colores.tonos or { Color3.fromRGB(200, 146, 70), Color3.fromRGB(170, 112, 50), Color3.fromRGB(230, 176, 74) }
	local BRILLO = colores and colores.brillo or Color3.fromRGB(48, 240, 220)
	for n = 0, 6 do
		local r = radio * (0.25 + n * 0.14)
		local cantidad = 6 + n * 2
		local anillo = { bloques = {}, r = r, alto = n * radio * 0.18, vel = 7 - n * 0.6 }
		for i = 1, cantidad do
			local tam = radio * (0.18 + n * 0.03)
			-- cada tercer bloque es una franja turquesa brillante (los jeroglíficos de Sekhmaur)
			local brilla = i % 3 == 0
			local b = bloqueEfecto(Vector3.new(tam, radio * 0.2, tam), brilla and BRILLO or ARENA[(i + n) % 3 + 1], brilla, 0.1 + n * 0.035)
			table.insert(anillo.bloques, { b, (i / cantidad) * math.pi * 2 })
		end
		table.insert(anillos, anillo)
	end
	local nucleo = bloqueEfecto(Vector3.new(radio * 0.25, radio * 1.2, radio * 0.25), BRILLO, true, 0.45)
	local luzTornado = Instance.new("PointLight")
	luzTornado.Color = BRILLO
	luzTornado.Range = radio * 2.5
	luzTornado.Brightness = 2.5
	luzTornado.Parent = nucleo
	local pie = bloqueEfecto(Vector3.new(radio * 1.8, 0.4, radio * 1.8), colores and colores.pie or Color3.fromRGB(214, 180, 120), false, 0.6)
	polvo(pie, ARENA[1], 70, 10)
	local inicio = os.clock()
	local conexion
	conexion = RunService.Heartbeat:Connect(function()
		local t = os.clock() - inicio
		if t > duracion then
			conexion:Disconnect()
			for _, a in anillos do
				for _, b in a.bloques do
					b[1]:Destroy()
				end
			end
			nucleo:Destroy()
			pie:Destroy()
			return
		end
		-- crece al aparecer y se deshace al final
		local escala = math.min(1, t * 3) * math.min(1, (duracion - t) * 2)
		for k, a in anillos do
			local oscila = Vector3.new(math.sin(t * 3 + k) * radio * 0.08 * k, 0, math.cos(t * 2.5 + k) * radio * 0.08 * k)
			for _, b in a.bloques do
				local ang = b[2] + t * a.vel
				local pos = base + oscila + Vector3.new(math.cos(ang) * a.r * escala, a.alto * escala + radio * 0.1, math.sin(ang) * a.r * escala)
				b[1].CFrame = CFrame.new(pos) * CFrame.Angles(0, -ang, 0.3)
			end
		end
		nucleo.CFrame = CFrame.new(base + Vector3.new(0, radio * 0.6 * escala, 0)) * CFrame.Angles(0, t * 9, 0)
		pie.CFrame = CFrame.new(base + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, -t * 5, 0)
	end)
end

-- Arenas movedizas: un remolino de arena que se hunde en el suelo.
local function arenasMovedizas(base: Vector3, radio: number, duracion: number, colores)
	local bloques = {}
	local tonos = colores and colores.tonos or { Color3.fromRGB(150, 104, 56), Color3.fromRGB(120, 80, 42), Color3.fromRGB(90, 60, 32) }
	local BRILLO = colores and colores.brillo or Color3.fromRGB(48, 240, 220)
	for anillo = 1, 3 do
		local cantidad = 4 + anillo * 4
		for i = 1, cantidad do
			local brilla = anillo == 3 and i % 2 == 0 -- el anillo de afuera: jeroglíficos turquesa
			local b = bloqueEfecto(Vector3.new(radio * 0.28, 0.5, radio * 0.28), brilla and BRILLO or tonos[anillo], brilla, 0)
			table.insert(bloques, { b, (i / cantidad) * math.pi * 2, radio * anillo / 3.3, anillo })
		end
	end
	local centro = bloqueEfecto(Vector3.new(radio * 0.5, 0.4, radio * 0.5), Color3.fromRGB(110, 80, 46), false, 0)
	polvo(centro, Color3.fromRGB(200, 160, 100), 25, -4)
	local inicio = os.clock()
	local conexion
	conexion = RunService.Heartbeat:Connect(function()
		local t = os.clock() - inicio
		if t > duracion then
			conexion:Disconnect()
			for _, b in bloques do
				b[1]:Destroy()
			end
			centro:Destroy()
			return
		end
		for _, b in bloques do
			local ang = b[2] + t * (2.4 / b[4])
			local r = b[3] * (1 - (t * 0.15) % 0.3)
			b[1].CFrame = CFrame.new(base + Vector3.new(math.cos(ang) * r, 0.1 - (3 - b[4]) * 0.15, math.sin(ang) * r)) * CFrame.Angles(0, -ang, 0)
		end
		centro.CFrame = CFrame.new(base + Vector3.new(0, -0.1, 0)) * CFrame.Angles(0, t * 3, 0)
	end)
end

-- Pozo de sombra: bloques oscuros que giran hundiéndose, con humo morado.
local function pozoSombra(base: Vector3, radio: number, duracion: number)
	local bloques = {}
	for anillo = 1, 2 do
		local cantidad = 5 + anillo * 4
		for i = 1, cantidad do
			local b = bloqueEfecto(Vector3.new(radio * 0.3, 0.4, radio * 0.3), anillo == 1 and Color3.fromRGB(26, 16, 38) or Color3.fromRGB(60, 30, 90), anillo == 2, 0.1)
			table.insert(bloques, { b, (i / cantidad) * math.pi * 2, radio * anillo / 2.4, anillo })
		end
	end
	local centro = bloqueEfecto(Vector3.new(radio * 0.7, 0.3, radio * 0.7), Color3.fromRGB(8, 4, 14), false, 0)
	polvo(centro, Color3.fromRGB(120, 60, 180), 30, 5)
	local inicio = os.clock()
	local conexion
	conexion = RunService.Heartbeat:Connect(function()
		local t = os.clock() - inicio
		if t > duracion then
			conexion:Disconnect()
			for _, b in bloques do
				b[1]:Destroy()
			end
			centro:Destroy()
			return
		end
		for _, b in bloques do
			local ang = b[2] - t * (3 / b[4])
			b[1].CFrame = CFrame.new(base + Vector3.new(math.cos(ang) * b[3], 0.1, math.sin(ang) * b[3])) * CFrame.Angles(0, -ang, 0)
		end
		centro.CFrame = CFrame.new(base) * CFrame.Angles(0, t * 4, 0)
	end)
end

-- Charco electrificado: agua azul con chispas amarillas que saltan.
local function charco(base: Vector3, radio: number, duracion: number)
	local agua = bloqueEfecto(Vector3.new(0.3, radio * 2, radio * 2), Color3.fromRGB(70, 170, 220), false, 0.35)
	agua.Shape = Enum.PartType.Cylinder
	agua.CFrame = CFrame.new(base + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local luzCharco = Instance.new("PointLight")
	luzCharco.Color = Color3.fromRGB(255, 236, 90)
	luzCharco.Range = radio * 2.5
	luzCharco.Brightness = 2
	luzCharco.Parent = agua
	local chispas = {}
	for i = 1, 8 do
		chispas[i] = bloqueEfecto(Vector3.new(0.3, 1.6, 0.3), Color3.fromRGB(255, 236, 90), true, 0)
	end
	local inicio = os.clock()
	local conexion
	conexion = RunService.Heartbeat:Connect(function()
		local t = os.clock() - inicio
		if t > duracion then
			conexion:Disconnect()
			agua:Destroy()
			for _, c in chispas do
				c:Destroy()
			end
			return
		end
		for i, c in chispas do
			-- cada chispa salta a otro lugar del charco
			if math.random() < 0.25 then
				local a, r = math.random() * math.pi * 2, math.random() * radio * 0.9
				c.CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r, 0.8, math.sin(a) * r)) * CFrame.Angles(math.random() - 0.5, math.random() * 3, math.random() - 0.5)
				c.Transparency = math.random() < 0.3 and 1 or 0
			end
		end
	end)
end

-- Llama de bloques para la línea de fuego.
local function llama(base: Vector3, radio: number, duracion: number)
	local brasa = bloqueEfecto(Vector3.new(radio * 1.4, 0.4, radio * 1.4), Color3.fromRGB(255, 106, 26), true, 0.2)
	brasa.CFrame = CFrame.new(base)
	local fuego = Instance.new("Fire")
	fuego.Size = radio * 1.6
	fuego.Heat = 12
	fuego.Color = Color3.fromRGB(255, 140, 40)
	fuego.SecondaryColor = Color3.fromRGB(255, 60, 20)
	fuego.Parent = brasa
	for k = 0, 2 do
		local b = bloqueEfecto(Vector3.one * radio * (0.5 - k * 0.12), k == 2 and Color3.fromRGB(255, 220, 120) or Color3.fromRGB(255, 150, 40), true, 0.1)
		b.CFrame = CFrame.new(base + Vector3.new((k - 1) * radio * 0.3, radio * (0.3 + k * 0.35), 0)) * CFrame.Angles(0, k, 0)
		Debris:AddItem(b, duracion)
	end
	Debris:AddItem(brasa, duracion)
end

-- Algo que se queda en el suelo y sigue golpeando (remolino, línea de fuego, arenas movedizas).
local function zonaPersistente(jugador: Player, arma, puntos: { Vector3 }, radio: number, duracion: number, cada: number, mult: number, extra, visual: string)
	for _, p in puntos do
		local base = suelo(p)
		if visual == "tornado" then
			tornado(base, radio, duracion)
		elseif visual == "remolinoAgua" then
			tornado(base, radio, duracion, { tonos = { Color3.fromRGB(60, 150, 170), Color3.fromRGB(40, 110, 130), Color3.fromRGB(110, 200, 210) }, brillo = Color3.fromRGB(40, 230, 190), pie = Color3.fromRGB(70, 120, 110) })
		elseif visual == "charco" then
			charco(base, radio, duracion)
		elseif visual == "lodo" then
			arenasMovedizas(base, radio, duracion, { tonos = { Color3.fromRGB(96, 76, 52), Color3.fromRGB(74, 58, 40), Color3.fromRGB(56, 44, 32) }, brillo = Color3.fromRGB(40, 230, 190) })
		elseif visual == "sombra" then
			pozoSombra(base, radio, duracion)
		elseif visual == "arenas" then
			arenasMovedizas(base, radio, duracion)
		else
			llama(base, radio, duracion)
		end
	end
	local extraZona = table.clone(extra or {})
	extraZona.secundario = true
	task.spawn(function()
		local fin = ahora() + duracion
		while ahora() < fin and jugador.Parent do
			task.wait(cada)
			local tocados = {}
			for _, p in puntos do
				for _, f in zonasCerca(p + Vector3.new(0, 3, 0), radio, 4) do
					if not tocados[f.o] then
						tocados[f.o] = true
						if mult > 0 then
							aplicar(jugador, f.z, f.o, arma, mult, false, false, extraZona)
						elseif f.o.lentitud ~= nil then
							-- las arenas movedizas solo frenan
							f.o.lentitud = math.max(f.o.lentitud, 1)
						end
					end
				end
			end
		end
	end)
end

-- un rayo que cae del cielo en ese punto (armas de Xolotl)
local function rayoSobre(p: Vector3)
	local base = suelo(p)
	for k = 0, 3 do
		local x = (math.random() - 0.5) * 2
		local b = efecto(base + Vector3.new(x, 12 + k * 24, x * 0.5), Vector3.new(1.4, 24, 1.4), Color3.fromRGB(255, 236, 90), 0.22)
		b.CFrame = b.CFrame * CFrame.Angles(0, 0, math.rad(math.random(-12, 12)))
	end
	efecto(base + Vector3.new(0, 0.3, 0), Vector3.new(0.4, 9, 9), Color3.fromRGB(170, 230, 255), 0.3, Enum.PartType.Cylinder)
end

local function usarPoder(jugador: Player, arma, ataque, fuerte: boolean, alcanzo)
	if not jugador.Parent then
		return
	end
	local e = datosDe(jugador)
	local char = jugador.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local adelante = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
	local poder = arma.poderId
	if poder == "ola" and e.olaLista and alcanzo then
		-- Colmillo: ola de arena en línea recta
		e.olaLista = false
		Combate.auraFilo(char, false)
		local tocados = {}
		for k = 1, 3 do
			local p = hrp.Position + adelante * (k * 3) * S
			efecto(suelo(p), Vector3.new(2.5 * S, 1.2 * S, 2.5 * S), Color3.fromRGB(230, 200, 130), 0.6)
			for _, f in zonasCerca(p, 1.8 * S, 3) do
				if not tocados[f.z.zona] then
					tocados[f.z.zona] = true
					aplicar(jugador, f.z, f.o, arma, 1.5, true)
				end
			end
		end
		Remotos.Anuncio:FireClient(jugador, "¡Ola de arena!", Color3.fromRGB(230, 200, 130))
	elseif poder == "arenas" and fuerte then
		-- Martillo de la Esfinge: arenas movedizas que frenan al Behemoth
		zonaPersistente(jugador, arma, { hrp.Position + adelante * 3 * S }, 4.5 * S, 5, 0.5, 0, nil, "arenas")
	elseif poder == "remolino" and ataque.anim == "giro" then
		zonaPersistente(jugador, arma, { hrp.Position }, 3.5 * S, 3, 0.5, 0.3, nil, "tornado")
	elseif poder == "calor" and alcanzo then
		-- Mandíbula del Rodador: el calor se acumula y el golpe fuerte estalla
		local calor = (char:GetAttribute("Calor") or 0)
		if fuerte and calor >= 100 then
			char:SetAttribute("Calor", 0)
			local armaModelo = char:FindFirstChild("Arma")
			for _, d in (armaModelo and armaModelo:GetDescendants() or {}) do
				if d:IsA("ParticleEmitter") and d.Name == "Brasas" then
					d.Rate = 4
					d:Emit(40)
				end
			end
			efecto(alcanzo.pos, Vector3.one * 4 * S, Color3.fromRGB(255, 154, 46), 0.4)
			aplicar(jugador, alcanzo, alcanzo.objetivo, arma, 1.5, true, false, { quemadura = 10 })
			Remotos.Anuncio:FireClient(jugador, "¡Estallido de brasas!", Color3.fromRGB(255, 154, 46))
		else
			calor = math.min(100, calor + (fuerte and 35 or 20))
			char:SetAttribute("Calor", calor)
			local armaModelo = char:FindFirstChild("Arma")
			for _, d in (armaModelo and armaModelo:GetDescendants() or {}) do
				if d:IsA("ParticleEmitter") and d.Name == "Brasas" then
					d.Rate = 4 + calor * 0.35 -- más calor, más brasas
				end
			end
			if calor >= 100 then
				Remotos.Anuncio:FireClient(jugador, "¡Hoja al rojo! Usa un golpe fuerte", Color3.fromRGB(255, 154, 46))
			end
		end
	elseif poder == "mini_bola" and fuerte then
		-- Martillo del Sol Rodante: una mini bola solar rueda hacia adelante
		task.spawn(function()
			local pos = hrp.Position + adelante * 1.5 * S
			local bola = efecto(suelo(pos), Vector3.one * 1.4 * S, Color3.fromRGB(232, 120, 30), 3, Enum.PartType.Ball)
			local fin = ahora() + 2.2
			while ahora() < fin do
				local dt = task.wait(0.05)
				pos += adelante * 13 * S * dt
				bola.Position = suelo(pos) + Vector3.new(0, 0.7 * S, 0)
				local f = zonasCerca(bola.Position, 1.1 * S, 1)[1]
				if f then
					aplicar(jugador, f.z, f.o, arma, 2, true, false, { quemadura = 8 })
					efecto(bola.Position, Vector3.one * 3.5 * S, Color3.fromRGB(255, 154, 46), 0.4, Enum.PartType.Ball)
					break
				end
			end
			bola:Destroy()
		end)
	elseif poder == "linea_fuego" and ataque.anim == "giro" then
		local puntos = {}
		for k = 0, 4 do
			table.insert(puntos, hrp.Position + adelante * (1.5 + k * 1.4) * S)
		end
		zonaPersistente(jugador, arma, puntos, 1.4 * S, 4, 0.5, 0.3, { quemadura = 4 }, "fuego")
	elseif poder == "marca" and alcanzo then
		-- Filo del Eclipse: marcas de sombra que el golpe fuerte consume
		local marcas = char:GetAttribute("Marcas") or 0
		if fuerte and marcas > 0 then
			char:SetAttribute("Marcas", 0)
			efecto(alcanzo.pos, Vector3.one * (2 + marcas) * S, Color3.fromRGB(120, 50, 190), 0.4)
			aplicar(jugador, alcanzo, alcanzo.objetivo, arma, 0.4 * marcas, true)
			Remotos.Anuncio:FireClient(jugador, ("¡Corte de sombra x%d!"):format(marcas), Color3.fromRGB(192, 112, 255))
		elseif not fuerte then
			char:SetAttribute("Marcas", math.min(5, marcas + 1))
		end
	elseif poder == "pozo" and fuerte then
		zonaPersistente(jugador, arma, { hrp.Position + adelante * 3 * S }, 3.5 * S, 4, 0.5, 0.25, nil, "sombra")
	elseif poder == "plumas" and ataque.anim == "giro" then
		-- Alas de Amaru: plumas oscuras en círculo
		local tocados = {}
		for k = 0, 7 do
			local dir = CFrame.Angles(0, k * math.pi / 4, 0).LookVector
			local p = hrp.Position + dir * 4 * S
			local pluma = efecto(p, Vector3.new(0.5, 0.5, 2.4), Color3.fromRGB(160, 76, 224), 0.35)
			pluma.CFrame = CFrame.lookAt(p, p + dir)
			for _, f in zonasCerca(p, 2.5 * S, 2) do
				if not tocados[f.z.zona] and #tocados < 4 then
					tocados[f.z.zona] = true
					table.insert(tocados, f)
					aplicar(jugador, f.z, f.o, arma, 0.6, false)
				end
			end
		end
	elseif poder == "destello" and alcanzo then
		-- Filo del Inti: acumula luz; con 4, el golpe fuerte lanza un destello que casi lo derriba
		local luz = char:GetAttribute("Luz") or 0
		if fuerte and luz >= 4 then
			char:SetAttribute("Luz", 0)
			efecto(alcanzo.pos, Vector3.one * 8 * S, Color3.fromRGB(255, 240, 180), 0.25, Enum.PartType.Ball)
			aplicar(jugador, alcanzo, alcanzo.objetivo, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 8, poderId = "" }, 1.3, true)
			Remotos.Anuncio:FireClient(jugador, "¡Destello del Inti!", Color3.fromRGB(255, 240, 180))
		elseif not fuerte then
			char:SetAttribute("Luz", math.min(4, luz + 1))
		end
	elseif poder == "terremoto" and fuerte then
		-- Puño del Apu: el suelo se parte alrededor del golpe
		local centro = hrp.Position + adelante * 3 * S
		for k = 0, 7 do
			local dir = CFrame.Angles(0, k * math.pi / 4, 0).LookVector
			local roca = efecto(suelo(centro + dir * 3.5 * S), Vector3.new(2, 2.5, 2) * S * 0.6, Color3.fromRGB(128, 122, 116), 0.8)
			roca.Material = Enum.Material.SmoothPlastic
		end
		for _, f in zonasCerca(centro, 5 * S, 4) do
			aplicar(jugador, f.z, f.o, arma, 0.8, true)
		end
	elseif poder == "esquirlas" and ataque.anim == "giro" then
		-- Hoces de Granito: esquirlas de roca hacia adelante
		local tocados = {}
		for k = -2, 2 do
			local dir = (CFrame.Angles(0, k * 0.25, 0) * CFrame.new(adelante)).Position.Unit
			local p = hrp.Position + dir * 5 * S
			local piedra = efecto(p, Vector3.new(0.8, 0.8, 1.6), Color3.fromRGB(150, 144, 136), 0.3)
			piedra.Material = Enum.Material.SmoothPlastic
			piedra.CFrame = CFrame.lookAt(p, p + dir)
			for _, f in zonasCerca(p, 2.5 * S, 1) do
				if not tocados[f.z.zona] and #tocados < 3 then
					tocados[f.z.zona] = true
					table.insert(tocados, f)
					aplicar(jugador, f.z, f.o, arma, 0.7, false)
				end
			end
		end
	elseif poder == "pilar" and fuerte and alcanzo then
		-- Lanza del Sol Naciente: un pilar de piedra sale bajo el Behemoth
		local base = suelo(alcanzo.pos)
		local pilar = efecto(base + Vector3.new(0, 2 * S, 0), Vector3.new(2.5, 4, 2.5) * S, Color3.fromRGB(150, 144, 136), 1.0)
		pilar.Material = Enum.Material.SmoothPlastic
		efecto(base + Vector3.new(0, 4.2 * S, 0), Vector3.new(2.7, 0.4, 2.7) * S, Color3.fromRGB(255, 214, 90), 1.0)
		aplicar(jugador, alcanzo, alcanzo.objetivo, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 5, poderId = "" }, 1.6, true)
	elseif poder == "embestida" and fuerte then
		-- Cuerno de Hércules: embestida que atraviesa y abre heridas ardientes
		local tocados = {}
		for k = 0, 2 do
			for _, f in zonasCerca(hrp.Position + adelante * (2 + k * 2.2) * S + Vector3.new(0, 1.3 * S, 0), 1.7 * S, 3) do
				if not tocados[f.z.zona] then
					tocados[f.z.zona] = true
					aplicar(jugador, f.z, f.o, arma, 1.2, true, true, { quemadura = 6 })
				end
			end
		end
	-- ---------- armas de Camazotz (Eco) ----------
	elseif poder == "grito" and fuerte then
		-- Colmillo de Xibalbá: onda sónica en cono que aturde hasta 3 partes
		local tocados = 0
		for k = 1, 3 do
			local p = hrp.Position + adelante * (2 + k * 2.2) * S
			local onda = efecto(p + Vector3.new(0, 1 * S, 0), Vector3.new(0.4, (1.6 + k * 1.2) * S, (1.6 + k * 1.2) * S), Color3.fromRGB(170, 240, 255), 0.25, Enum.PartType.Cylinder)
			onda.CFrame = CFrame.lookAt(onda.Position, onda.Position + adelante) * CFrame.Angles(0, math.rad(90), 0)
		end
		local vistos = {}
		for k = 1, 4 do
			for _, f in zonasCerca(hrp.Position + adelante * (2 + k * 2) * S + Vector3.new(0, 1.5 * S, 0), (1 + k * 0.6) * S, 3) do
				if not vistos[f.z.zona] and tocados < 3 then
					vistos[f.z.zona] = true
					tocados += 1
					aplicar(jugador, f.z, f.o, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 3, poderId = "" }, 1.1, true)
				end
			end
		end
	elseif poder == "tambor" and fuerte then
		-- Tambor de Camazotz: el golpe retumba y llena el derribo de hasta 4 partes
		local centro = hrp.Position + adelante * 3 * S
		local aro = efecto(suelo(centro) + Vector3.new(0, 0.3, 0), Vector3.new(0.4, 2, 2), Color3.fromRGB(200, 140, 255), 0.45, Enum.PartType.Cylinder)
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 0.4 and aro.Parent do
				local k = (os.clock() - t0) / 0.4
				aro.Size = Vector3.new(0.4, 10 * S * k, 10 * S * k)
				aro.Transparency = 0.3 + 0.7 * k
				task.wait()
			end
		end)
		for _, f in zonasCerca(centro, 5 * S, 4) do
			aplicar(jugador, f.z, f.o, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 6, poderId = "" }, 0.5, true)
		end
	elseif poder == "murcielagos" and ataque.anim == "giro" then
		-- Alas de Obsidiana: tres murciélagos que vuelan a morder las partes cercanas
		local metas = zonasCerca(hrp.Position, 9 * S, 3)
		for i = 1, 3 do
			local f = metas[i] or metas[1]
			task.spawn(function()
				local desde = hrp.Position + Vector3.new(0, 2 * S, 0)
				local hasta = f and f.z.pos or (desde + CFrame.Angles(0, i * 2.1, 0).LookVector * 6 * S)
				local bat = efecto(desde, Vector3.new(1.4, 0.3, 0.8), Color3.fromRGB(40, 24, 60), 0.9)
				bat.Material = Enum.Material.SmoothPlastic
				bat.Transparency = 0
				local ojo = efecto(desde, Vector3.new(0.4, 0.15, 0.15), Color3.fromRGB(255, 50, 50), 0.9)
				local t0 = os.clock()
				while os.clock() - t0 < 0.55 and bat.Parent do
					local k = (os.clock() - t0) / 0.55
					local p = desde:Lerp(hasta, k) + Vector3.new(math.sin(k * 9 + i) * 1.5, math.sin(k * math.pi) * 3, 0)
					bat.CFrame = CFrame.lookAt(p, hasta) * CFrame.Angles(0, 0, math.sin(os.clock() * 40) * 0.6)
					ojo.CFrame = bat.CFrame * CFrame.new(0, 0.1, -0.45)
					task.wait()
				end
				bat:Destroy()
				ojo:Destroy()
				if f then
					aplicar(jugador, f.z, f.o, arma, 0.6, false)
				end
			end)
		end
	elseif poder == "atraviesa" and fuerte then
		-- Aguijón del Inframundo: la estocada atraviesa en línea hasta 3 partes
		local tocados, n = {}, 0
		local rayo = efecto(hrp.Position + adelante * 4.5 * S + Vector3.new(0, 1 * S, 0), Vector3.new(0.5, 0.5, 9 * S), Color3.fromRGB(200, 140, 255), 0.25)
		rayo.CFrame = CFrame.lookAt(rayo.Position, rayo.Position + adelante)
		for k = 0, 3 do
			for _, f in zonasCerca(hrp.Position + adelante * (1.5 + k * 2.2) * S + Vector3.new(0, 1.3 * S, 0), 1.8 * S, 3) do
				if not tocados[f.z.zona] and n < 3 then
					tocados[f.z.zona] = true
					n += 1
					aplicar(jugador, f.z, f.o, arma, 1.0, true, true)
				end
			end
		end
	elseif poder == "chupasangre" and alcanzo then
		-- Garras de Camazotz: cada golpe que acierta te devuelve vida
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local cura = fuerte and 3 or 1
			hum.Health = math.min(hum.MaxHealth, hum.Health + cura)
			Combate.numero(hrp.Position + Vector3.new(0, 5, 0), "+" .. cura, Color3.fromRGB(120, 255, 140))
		end
	-- ---------- armas de Xolotl (Tormenta) ----------
	elseif poder == "trueno" and fuerte and alcanzo then
		-- Macuahuitl del Trueno: un rayo cae sobre la parte golpeada
		rayoSobre(alcanzo.pos)
		aplicar(jugador, alcanzo, alcanzo.objetivo, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 3, poderId = "" }, 1.0, true)
	elseif poder == "charco" and fuerte then
		-- Mazo de Tláloc: un charco electrificado que sigue dañando
		zonaPersistente(jugador, arma, { hrp.Position + adelante * 3 * S }, 3.5 * S, 5, 0.5, 0.22, nil, "charco")
	elseif poder == "regenera" and ataque.anim == "giro" then
		-- Branquias del Ajolote: cada giro te regenera
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
			hum.Health = math.min(hum.MaxHealth, hum.Health + 4)
			Combate.numero(hrp.Position + Vector3.new(0, 5, 0), "+4", Color3.fromRGB(120, 255, 140))
		end
	elseif poder == "jabalina" and fuerte then
		-- Atlatl de Tormenta: una jabalina eléctrica que vuela y atraviesa dos partes
		task.spawn(function()
			local pos = hrp.Position + Vector3.new(0, 1.5 * S, 0)
			local jab = efecto(pos, Vector3.new(0.4, 0.4, 3 * S), Color3.fromRGB(255, 236, 90), 1.2)
			local tocados, n = {}, 0
			local fin = ahora() + 0.9
			while ahora() < fin and n < 2 do
				local dt = task.wait(0.03)
				pos += adelante * 32 * S * dt
				jab.CFrame = CFrame.lookAt(pos, pos + adelante)
				for _, f in zonasCerca(pos, 1.4 * S, 2) do
					if not tocados[f.z.zona] and n < 2 then
						tocados[f.z.zona] = true
						n += 1
						aplicar(jugador, f.z, f.o, arma, 1.3, true)
						rayoSobre(f.z.pos)
					end
				end
			end
			jab:Destroy()
		end)
	elseif poder == "estatica" and alcanzo then
		-- Puños de Tormenta: cada golpe carga estática; con 6, el golpe fuerte la suelta
		local cargas = char:GetAttribute("Estatica") or 0
		if fuerte and cargas >= 6 then
			char:SetAttribute("Estatica", 0)
			rayoSobre(alcanzo.pos)
			efecto(alcanzo.pos, Vector3.one * 6 * S, Color3.fromRGB(255, 236, 90), 0.3, Enum.PartType.Ball)
			for _, f in zonasCerca(alcanzo.pos, 4 * S, 3) do
				aplicar(jugador, f.z, f.o, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 4, poderId = "" }, 1.2, true)
			end
			Remotos.Anuncio:FireClient(jugador, "¡Descarga de tormenta!", Color3.fromRGB(255, 236, 90))
		elseif not fuerte then
			char:SetAttribute("Estatica", math.min(6, cargas + 1))
			if cargas + 1 == 6 then
				Remotos.Anuncio:FireClient(jugador, "¡Estática al máximo! Usa un golpe fuerte", Color3.fromRGB(255, 236, 90))
			end
		end
	-- ---------- armas de Balam (Obsidiana) ----------
	elseif poder == "puas" and fuerte then
		-- Mazo del Jaguar: púas de obsidiana brotan del suelo
		local centro = hrp.Position + adelante * 3.5 * S
		for k = 0, 6 do
			local a = k / 7 * math.pi * 2
			local p = suelo(centro + Vector3.new(math.cos(a), 0, math.sin(a)) * 2.4 * S)
			local pua = efecto(p + Vector3.new(0, 1.5 * S, 0), Vector3.new(0.9 * S, 3 * S, 0.9 * S), Color3.fromRGB(20, 14, 28), 0.9)
			pua.Material = Enum.Material.SmoothPlastic
			pua.Transparency = 0
			pua.CFrame = CFrame.new(pua.Position) * CFrame.Angles(math.sin(a) * 0.4, 0, math.cos(a) * 0.4)
			local filo = efecto(pua.Position, Vector3.new(0.25, 3 * S, 0.5), Color3.fromRGB(160, 96, 255), 0.9)
			filo.CFrame = pua.CFrame
		end
		for _, f in zonasCerca(centro, 4.5 * S, 3) do
			aplicar(jugador, f.z, f.o, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 3, poderId = "" }, 0.9, true, true)
		end
	elseif poder == "cortes" and ataque.anim == "giro" then
		-- Garras de Balam: tres cortes de jade en abanico que abren heridas
		local tocados = {}
		for k = -1, 1 do
			local dir = (CFrame.Angles(0, k * 0.4, 0) * CFrame.new(adelante)).Position.Unit
			local p = hrp.Position + dir * 4.5 * S
			local corte = efecto(p, Vector3.new(2.6 * S, 0.3, 0.5), Color3.fromRGB(40, 230, 150), 0.3)
			corte.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0, math.rad(90), 0)
			local f = zonasCerca(p, 2.4 * S, 1)[1]
			if f and not tocados[f.z.zona] then
				tocados[f.z.zona] = true
				aplicar(jugador, f.z, f.o, arma, 0.7, false, true)
			end
		end
	elseif poder == "desgarro" and fuerte and alcanzo then
		-- Zarpas de Obsidiana: el golpe fuerte desgarra y hace sangrar
		aplicar(jugador, alcanzo, alcanzo.objetivo, arma, 0.5, true, true, { sangrado = 6 })
	-- ---------- armas de Cipactli (Abismo) ----------
	elseif poder == "mordida" and fuerte and alcanzo then
		-- Diente de Cipactli: el golpe fuerte muerde dos veces
		task.delay(0.22, function()
			-- la segunda mordida busca la parte otra vez: si el Behemoth se sumergió o se alejó
			-- (o el cazador cayó), no muerde
			local h = char:FindFirstChildOfClass("Humanoid")
			if not h or h.Health <= 0 then
				return
			end
			for _, z in alcanzo.objetivo:zonas() do
				if z.zona.nombre == alcanzo.zona.nombre then
					efecto(z.pos, Vector3.new(2.5, 0.6, 2.5) * S, Color3.fromRGB(40, 230, 190), 0.2)
					aplicar(jugador, z, alcanzo.objetivo, arma, 1.2, true)
					break
				end
			end
		end)
	elseif poder == "lodo" and fuerte then
		-- Mazo del Pantano: un lodazal que frena al Behemoth
		zonaPersistente(jugador, arma, { hrp.Position + adelante * 3 * S }, 4.5 * S, 6, 0.5, 0, nil, "lodo")
	elseif poder == "remolino_agua" and ataque.anim == "giro" then
		-- Hoces de la Creación: un remolino de agua que sigue golpeando
		zonaPersistente(jugador, arma, { hrp.Position }, 3.5 * S, 3, 0.5, 0.3, nil, "remolinoAgua")
	elseif poder == "arpon" and fuerte and alcanzo then
		-- Arpón del Abismo: herida profunda y lo frena 3 segundos
		aplicar(jugador, alcanzo, alcanzo.objetivo, arma, 0.4, true, true, { lentitud = 3 })
		efecto(alcanzo.pos, Vector3.new(0.4, 0.4, 3 * S), Color3.fromRGB(40, 230, 190), 0.4).CFrame = CFrame.lookAt(alcanzo.pos, alcanzo.pos + adelante)
	elseif poder == "fauces" and alcanzo and not fuerte then
		-- Fauces del Caimán: cada cuarto golpe muerde
		local n = (e.faucesN or 0) + 1
		e.faucesN = n % 4
		if n >= 4 then
			efecto(alcanzo.pos, Vector3.new(3, 0.8, 3) * S, Color3.fromRGB(40, 230, 190), 0.25)
			aplicar(jugador, alcanzo, alcanzo.objetivo, arma, 1.6, true, true)
		end
	end
end

-- Busca las zonas que alcanzó un golpe cuerpo a cuerpo (la más cercana, o varias en los giros).
local function golpeCuerpoACuerpo(jugador: Player, arma, ataque, fuerte: boolean)
	local char = jugador.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local alcance = ataque.alcance * S
	local centro = hrp.Position + hrp.CFrame.LookVector * alcance * 0.55
	local radio = alcance * 0.62
	local encontrados = {}
	for _, o in objetivos do
		for _, z in o:zonas() do
			local d = distanciaAZona(centro, z)
			if d < radio then
				table.insert(encontrados, { z = z, o = o, d = d - prioridad(o, z.zona) })
			end
		end
	end
	table.sort(encontrados, function(a, b)
		return a.d < b.d
	end)
	local maximo = ataque.golpes and 3 or 1
	local usados = {}
	local n = 0
	local primero = nil
	for _, f in encontrados do
		if n >= maximo then
			break
		end
		if not usados[f.z.zona] then
			usados[f.z.zona] = true
			n += 1
			aplicar(jugador, f.z, f.o, arma, ataque.danio, fuerte, ataque.herida_profunda)
			if not primero then
				primero = { zona = f.z.zona, pos = f.z.pos, objetivo = f.o }
			end
		end
	end
	return primero
end

-- Los blásteres disparan desde el cazador hacia donde apunta su cámara.
local function disparo(jugador: Player, arma, ataque, fuerte: boolean, apunto: Vector3?)
	local char = jugador.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or typeof(apunto) ~= "Vector3" then
		return
	end
	-- un punto con NaN o infinito no se acepta (llegaría a todos los clientes)
	local ap = apunto :: Vector3
	if ap.X ~= ap.X or ap.Y ~= ap.Y or ap.Z ~= ap.Z or math.abs(ap.X) + math.abs(ap.Y) + math.abs(ap.Z) == math.huge then
		return
	end
	-- el rayo sale de la pistola que dispara (derecha o izquierda); el cargado, del centro
	local lado = ataque.lado or 0
	local desde = (hrp.CFrame * CFrame.new(lado * 1.3, 1.2, -1.6)).Position
	local dir = apunto - desde
	if dir.Magnitude < 0.1 then
		return
	end
	dir = dir.Unit
	local mejor, mejorT = nil, ataque.alcance * S
	for _, o in objetivos do
		for _, z in o:zonas() do
			-- intersección del rayo con la esfera de la zona
			local l = z.pos - desde
			local tca = l:Dot(dir)
			if tca > 0 then
				local d2 = l:Dot(l) - tca * tca
				if d2 < z.r * z.r then
					local t = tca - math.sqrt(z.r * z.r - d2)
					if t < mejorT then
						mejor, mejorT = { z = z, o = o }, t
					end
				end
			end
		end
	end
	if fuerte and arma.poderId == "rayo" then
		-- Blásteres del Sol Dorado: rayo solar que atraviesa hasta 3 partes
		local largo = ataque.alcance * S
		local tocados = {}
		for k = 1, 12 do
			local p = desde + dir * (largo * k / 12)
			for _, f in zonasCerca(p, 0.8 * S, 3) do
				if not tocados[f.z.zona] and #tocados < 3 then
					tocados[f.z.zona] = true
					table.insert(tocados, f)
					aplicar(jugador, f.z, f.o, arma, ataque.danio * 1.4, true)
				end
			end
		end
		local rayo = efecto((desde + desde + dir * largo) / 2, Vector3.new(1.2, 1.2, largo), Color3.fromRGB(255, 220, 120), 0.25)
		rayo.CFrame = CFrame.lookAt((desde + desde + dir * largo) / 2, desde + dir * largo)
		return
	end
	local hasta = desde + dir * mejorT
	Remotos.Disparo:FireAllClients(desde, hasta, fuerte)
	if fuerte and arma.poderId == "abanico" then
		-- Blásteres del Inti: tres rayos de sol en abanico
		for k = -1, 1 do
			local d = (CFrame.fromAxisAngle(Vector3.yAxis, k * 0.18) * CFrame.new(dir)).Position.Unit
			local largo = ataque.alcance * S
			local rayo = efecto(desde + d * largo / 2, Vector3.new(0.6, 0.6, largo), Color3.fromRGB(255, 220, 120), 0.2)
			rayo.CFrame = CFrame.lookAt(desde + d * largo / 2, desde + d * largo)
			for paso = 1, 10 do
				local f = zonasCerca(desde + d * (largo * paso / 10), 0.8 * S, 1)[1]
				if f then
					aplicar(jugador, f.z, f.o, arma, ataque.danio, true)
					break
				end
			end
		end
		return
	end
	if fuerte and arma.poderId == "orbe" then
		-- Blásteres del Eclipse: un orbe negro que estalla un instante después
		local orbe = efecto(hasta, Vector3.one * 2 * S, Color3.fromRGB(10, 4, 18), 1.2, Enum.PartType.Ball)
		orbe.Material = Enum.Material.SmoothPlastic
		task.delay(0.8, function()
			efecto(hasta, Vector3.one * 7 * S, Color3.fromRGB(120, 50, 190), 0.35, Enum.PartType.Ball)
			for _, f in zonasCerca(hasta, 3.5 * S, 3) do
				aplicar(jugador, f.z, f.o, arma, ataque.danio * 1.8, true)
			end
		end)
		return
	end
	if fuerte and arma.poderId == "cadena" and mejor then
		-- Blásteres del Cenote: rayo en cadena que salta a 3 partes
		local actual, vistos = mejor, { [mejor.z.zona] = true }
		aplicar(jugador, mejor.z, mejor.o, arma, ataque.danio, true)
		for _ = 1, 2 do
			local sig = nil
			for _, f in zonasCerca(actual.z.pos, 6 * S, 6) do
				if not vistos[f.z.zona] then
					sig = f
					break
				end
			end
			if not sig then
				break
			end
			vistos[sig.z.zona] = true
			Remotos.Disparo:FireAllClients(actual.z.pos, sig.z.pos, true)
			aplicar(jugador, sig.z, sig.o, arma, ataque.danio * 0.8, true)
			actual = sig
		end
		rayoSobre(hasta)
		return
	end
	if fuerte and arma.poderId == "astillas" then
		-- Blásteres de Jade: el disparo se parte en astillas que hieren hasta 4 partes
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			local p = hasta + Vector3.new(math.cos(a), 0.3, math.sin(a)) * 2 * S
			local astilla = efecto(p, Vector3.new(0.3, 0.3, 1.4), Color3.fromRGB(40, 230, 150), 0.25)
			astilla.CFrame = CFrame.lookAt(hasta, p)
		end
		for _, f in zonasCerca(hasta, 4 * S, 4) do
			aplicar(jugador, f.z, f.o, arma, ataque.danio * 0.6, true, true)
		end
		return
	end
	if fuerte and arma.poderId == "geiser" then
		-- Blásteres del Abismo: un géiser brota bajo el Behemoth
		local base = suelo(hasta)
		efecto(base + Vector3.new(0, 4 * S, 0), Vector3.new(2.4 * S, 8 * S, 2.4 * S), Color3.fromRGB(40, 230, 190), 0.4)
		efecto(base + Vector3.new(0, 0.3, 0), Vector3.new(0.4, 8 * S, 8 * S), Color3.fromRGB(96, 76, 52), 0.5, Enum.PartType.Cylinder)
		for _, f in zonasCerca(hasta, 3 * S, 3) do
			aplicar(jugador, f.z, f.o, { danio = arma.danio, partes = arma.partes, aturdir = arma.aturdir * 3, poderId = "" }, ataque.danio * 1.4, true)
		end
		return
	end
	if fuerte and arma.poderId == "bola_fuego" then
		-- Blásteres de Brasa: bola de fuego que explota en un área
		efecto(hasta, Vector3.one * 6.4 * S, Color3.fromRGB(255, 120, 30), 0.35, Enum.PartType.Ball)
		for _, f in zonasCerca(hasta, 3.2 * S, 3) do
			aplicar(jugador, f.z, f.o, arma, ataque.danio * 1.6, true, false, { quemadura = 8 })
		end
		return
	end
	if mejor then
		aplicar(jugador, mejor.z, mejor.o, arma, ataque.danio, fuerte)
		if arma.poderId == "rebote" then
			-- Blásteres de Eco: el disparo rebota a otra parte cercana
			for _, f in zonasCerca(hasta, 4 * S, 3) do
				if f.z.zona ~= mejor.z.zona then
					Remotos.Disparo:FireAllClients(hasta, f.z.pos, false)
					aplicar(jugador, f.z, f.o, arma, ataque.danio * 0.5, false)
					break
				end
			end
		end
	end
end

local function alAtacar(jugador: Player, tipo: string, apunto: Vector3?)
	local e = datosDe(jugador)
	local char = jugador.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or (tipo ~= "ligero" and tipo ~= "fuerte") or not ZONAS_CACERIA[jugador:GetAttribute("Zona")] then
		return
	end
	local t = ahora()
	if t < e.ocupadoHasta - 0.12 then
		return
	end
	local arma = Armas.DATOS[char:GetAttribute("Arma") or ""]
	if not arma then
		return
	end
	local ataque
	if tipo == "fuerte" then
		ataque = arma.fuerte
		e.combo = 0
	else
		local seguido = arma.distancia and 2.0 or 1.2 -- los blásteres siguen alternando mano
		e.combo = (t - e.ultimo < seguido) and (e.combo % #arma.combo) + 1 or 1
		ataque = arma.combo[e.combo]
	end
	e.ultimo = t
	e.ocupadoHasta = t + ataque.duracion * 0.85
	char:SetAttribute("Anim", ataque.anim)
	char:SetAttribute("AnimT0", t)
	char:SetAttribute("AnimDur", ataque.duracion)
	local fuerte = tipo == "fuerte"
	if arma.distancia then
		disparo(jugador, arma, ataque, fuerte, apunto)
		return
	end
	local golpes = ataque.golpes or 1
	for i = 0, golpes - 1 do
		task.delay(ataque.golpe + i * 0.13, function()
			if hum.Health > 0 then
				local alcanzo = golpeCuerpoACuerpo(jugador, arma, ataque, fuerte)
				if i == 0 then
					usarPoder(jugador, arma, ataque, fuerte, alcanzo)
				end
			end
		end)
	end
end

local function alEsquivar(jugador: Player)
	local e = datosDe(jugador)
	local char = jugador.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	-- El servidor lleva su propia cuenta del aguante de la esquiva (con la recuperación más
	-- rápida posible y sin descontar correr ni atacar, para no rechazar nunca una esquiva
	-- legítima) y una espera mínima entre esquivas, igual que el cliente. Así nadie puede
	-- rodar sin parar para ser invulnerable.
	local t = ahora()
	if t < (e.esquivaLista or 0) then
		return
	end
	local regen = 30 * (char:GetAttribute("Lleva_garras") and 1.35 or 1) * mod(char, "aguanteRegen")
	e.aguanteEsq = math.min(AGUANTE_MAX, (e.aguanteEsq or AGUANTE_MAX) + (t - (e.tAguanteEsq or t)) * regen)
	e.tAguanteEsq = t
	local costo = (char:GetAttribute("Lleva_grebas") and 14 or 25) * mod(char, "esquivaCosto")
	if e.aguanteEsq < costo * 0.9 then
		return
	end
	e.aguanteEsq = math.max(0, e.aguanteEsq - costo)
	e.esquivaLista = t + 0.15
	e.invulHasta = t + ((char:GetAttribute("Lleva_mascara")) and 0.45 or 0.3) * mod(char, "ventanaEsquiva")
	-- la rueda corta la recuperación del ataque, pero no deja atacar en mitad de la rueda
	e.ocupadoHasta = t + 0.2
	e.combo = 0
	char:SetAttribute("Anim", "rueda")
	char:SetAttribute("AnimT0", ahora())
	char:SetAttribute("AnimDur", 0.45)
end

local function alTomarPocion(jugador: Player)
	local e = datosDe(jugador)
	local char = jugador.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or e.pociones <= 0 or e.curando then
		return
	end
	e.pociones -= 1
	e.curando = true
	jugador:SetAttribute("Pociones", e.pociones)
	task.spawn(function()
		for _ = 1, 10 do
			if hum.Health <= 0 then
				break
			end
			hum.Health = math.min(hum.MaxHealth, hum.Health + 4.5)
			task.wait(0.1)
		end
		e.curando = false
	end)
end


-- ---------- muñeco de práctica junto al campamento ----------
local Muneco = {}
Muneco.__index = Muneco

function Muneco.nuevo()
	local self = setmetatable({}, Muneco)
	local base = Config.suelo(Config.CAMPAMENTO.X + 10, Config.CAMPAMENTO.Y - 12)
	self.centro = base
	Mundo.parte({ Name = "Poste", Size = Vector3.new(0.6, 7, 0.6), Position = base + Vector3.new(0, 3.5, 0), Color = Color3.fromRGB(120, 85, 50), Material = Enum.Material.Wood })
	Mundo.parte({ Name = "Paja", Size = Vector3.new(3, 3.6, 2.2), Position = base + Vector3.new(0, 4.6, 0), Color = Color3.fromRGB(220, 190, 120), Material = Enum.Material.Fabric })
	Mundo.parte({ Name = "Cabeza", Size = Vector3.new(1.8, 1.8, 1.8), Position = base + Vector3.new(0, 7.3, 0), Color = Color3.fromRGB(220, 190, 120), Material = Enum.Material.Fabric })
	Mundo.parte({ Name = "Brazos", Size = Vector3.new(6, 0.5, 0.5), Position = base + Vector3.new(0, 5.4, 0), Color = Color3.fromRGB(120, 85, 50), Material = Enum.Material.Wood })
	self.lista = {
		{ zona = { nombre = "cuerpo", tipo = "cuerpo", parte = "" }, pos = base + Vector3.new(0, 4.6, 0), r = 2 },
		{ zona = { nombre = "cabeza", tipo = "cabeza", parte = "" }, pos = base + Vector3.new(0, 7.3, 0), r = 1.1 },
	}
	return self
end

function Muneco:zonas()
	return self.lista
end

function Muneco:recibirGolpe(zona, info)
	local danio = math.floor(info.danio * (zona.tipo == "cabeza" and 1.3 or 1) + 0.5)
	local z = zona.tipo == "cabeza" and self.lista[2] or self.lista[1]
	local aturde = (info.aturdir or 0) * (zona.tipo == "cabeza" and 1.2 or 0.4) >= 1
	Combate.numero(z.pos + Vector3.new(0, 1.5, 0), tostring(danio), aturde and Color3.fromRGB(90, 230, 110) or Color3.new(1, 1, 1), info.fuerte)
end

-- Pone la armadura forjada y, en el desierto, el arma elegida en la armería.
function Combate.equipar(jugador: Player, char: Model, conArma: boolean)
	local p = Perfil.de(jugador)
	char:SetAttribute("Nivel", p.nivel)
	Equipo.vestir(char, p.equipo)
	if conArma then
		Equipo.armar(char, p.arma)
	else
		Equipo.desarmar(char)
	end
end

-- Recompensas para todos los cazadores que estaban en el desierto.
function Combate.recompensar(premios, participantes)
	for j in participantes do
		if j.Parent then
			Perfil.dar(j, premios)
			Perfil.de(j).cazas += 1
		end
	end
end

local ESTRELLAS = {}
for _, f in Armas.BESTIARIO do
	ESTRELLAS[f.nombre] = f.estrellas
end

function Combate.resultados(participantes, datos)
	for j in participantes do
		if j.Parent then
			local ej = datosDe(j)
			ej.recargaUsada, ej.avisoRecarga = false, false -- la próxima cacería tiene su recarga
			local propios = table.clone(datos)
			propios.recompensas = table.clone(datos.recompensas)
			local xp = datos.exito and (40 + 20 * (ESTRELLAS[datos.behemoth] or 2)) + 15 * #datos.partes or 15
			local subio = Perfil.darXP(j, xp)
			table.insert(propios.recompensas, ("+ %d de experiencia"):format(xp))
			if datos.exito then
				if Perfil.registrarTiempo(j, datos.behemoth, datos.tiempo) then
					table.insert(propios.recompensas, "¡Nuevo récord personal!")
				end
				Records.registrar(j, datos.behemoth, datos.tiempo)
			end
			Misiones = Misiones or require(script.Parent.Misiones)
			for _, linea in Misiones.evaluar(j, datos) do
				table.insert(propios.recompensas, linea)
			end
			local p = Perfil.de(j)
			if subio > 0 then
				table.insert(propios.recompensas, ("¡Subiste al nivel %d! (+%d de vida máxima)"):format(p.nivel, 2 * subio))
				Remotos.Anuncio:FireClient(j, ("¡NIVEL %d!"):format(p.nivel), Color3.fromRGB(127, 255, 244))
				if j.Character then
					j.Character:SetAttribute("Nivel", p.nivel)
					Equipo.vestir(j.Character, p.equipo)
				end
			end
			Remotos.Resultados:FireClient(j, propios)
		end
	end
end

-- El bestiario: récords personales, cazas y el récord global de cada Behemoth.
function Combate.bestiario(jugador: Player)
	local p = Perfil.de(jugador)
	local globales = {}
	for _, b in Armas.BESTIARIO do
		if not b.proximamente then
			globales[b.nombre] = Records.consultar(b.nombre)
		end
	end
	return { tiempos = p.tiempos, cazasPor = p.cazasPor, globales = globales, nivel = p.nivel, xp = p.xp }
end

-- ---------- conexión de cada jugadora ----------
function Combate.iniciar(alDesmayo)
	Combate.agregarObjetivo(Muneco.nuevo())
	Remotos.Ataque.OnServerEvent:Connect(alAtacar)
	Remotos.PedirBestiario.OnServerInvoke = Combate.bestiario
	Remotos.Esquivar.OnServerEvent:Connect(alEsquivar)
	Remotos.Pocion.OnServerEvent:Connect(alTomarPocion)
	local function alAparecer(jugador: Player, char: Model)
		local e = datosDe(jugador)
		if not jugador:GetAttribute("VigilaZona") then
			jugador:SetAttribute("VigilaZona", true)
			local antes = jugador:GetAttribute("Zona")
			jugador:GetAttributeChangedSignal("Zona"):Connect(function()
				local ahora_ = jugador:GetAttribute("Zona")
				if ZONAS_CACERIA[ahora_] and not ZONAS_CACERIA[antes] then
					e.recargaUsada, e.avisoRecarga = false, false -- empieza una cacería nueva
				end
				antes = ahora_
			end)
		end
		e.pociones = POCIONES
		e.combo = 0
		e.ocupadoHasta = 0
		jugador:SetAttribute("Pociones", e.pociones)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		hum.MaxHealth = 100
		hum.Health = 100
		hum.UseJumpPower = false
		hum.JumpHeight = 7.2
		hum.Died:Connect(function()
			alDesmayo(jugador)
		end)
	end
	local function conectar(jugador: Player)
		jugador.CharacterAdded:Connect(function(char)
			alAparecer(jugador, char)
		end)
		if jugador.Character then
			task.spawn(alAparecer, jugador, jugador.Character)
		end
	end
	Players.PlayerAdded:Connect(conectar)
	for _, j in Players:GetPlayers() do
		conectar(j)
	end
	Players.PlayerRemoving:Connect(function(jugador)
		estados[jugador] = nil
	end)
	-- el Caparazón Solar se vuelve a formar tras 8 segundos sin recibir golpes
	task.spawn(function()
		while true do
			task.wait(0.25)
			for j, e in estados do
				local char = j.Character
				local max = char and char:GetAttribute("EscudoMax") or 0
				if char and max > 0 and ahora() - (e.ultimoDanio or 0) > 10 then
					local antes = char:GetAttribute("Escudo") or 0
					if antes < max then
						char:SetAttribute("Escudo", math.min(max, antes + 3))
						if antes <= 0 then
							Remotos.Anuncio:FireClient(j, "El Caparazón Solar se vuelve a formar", Color3.fromRGB(255, 200, 120))
						end
					end
				end
			end
		end
	end)
	-- la fogata del campamento repone las pociones
	task.spawn(function()
		while true do
			task.wait(1)
			for j, e in estados do
				local hrp = j.Character and j.Character:FindFirstChild("HumanoidRootPart")
				-- la fogata repone las pociones UNA sola vez por cacería
				if hrp and ZONAS_CACERIA[j:GetAttribute("Zona")] and Config.enCampamento(hrp.Position) and e.pociones < POCIONES then
					if not e.recargaUsada then
						e.recargaUsada = true
						e.pociones = POCIONES
						j:SetAttribute("Pociones", e.pociones)
						Remotos.Anuncio:FireClient(j, "La fogata repuso tus pociones (solo una vez por cacería)", Color3.fromRGB(243, 214, 160))
					elseif not e.avisoRecarga then
						e.avisoRecarga = true
						Remotos.Anuncio:FireClient(j, "Ya usaste la recarga de la fogata en esta cacería", Color3.fromRGB(255, 160, 120))
					end
				end
			end
		end
	end)
end

return Combate
