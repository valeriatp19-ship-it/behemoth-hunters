--!nonstrict
-- Animaciones hechas por código (no hace falta subir animaciones a Roblox).
-- Cazadores: se giran las articulaciones de hombros y cadera según el ataque que anuncia el servidor.
-- Sekhmaur: patas, cola, cabeza, mandíbula y anillos de la melena según su atributo "Anim".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Compartido").Config)
local AnimSelva = require(script.Parent.AnimSelva)

local S = Config.S
local Anim = {}
local base = setmetatable({}, { __mode = "k" }) -- marco original de cada articulación
local avisado = setmetatable({}, { __mode = "k" })
local locales = {} -- animación propia, sin esperar al servidor

-- Roblox tiene dos tipos de articulaciones: las clásicas (Motor6D, se mueven con C0) y las
-- nuevas de los avatares (AnimationConstraint, se mueven con su punto de unión Attachment0).
local function marcoActual(m: Instance): CFrame?
	if m:IsA("Motor6D") then
		return m.C0
	elseif m:IsA("AnimationConstraint") and m.Attachment0 then
		return m.Attachment0.CFrame
	end
	return nil
end

local function ponerMarco(m: Instance, cf: CFrame)
	if m:IsA("Motor6D") then
		m.C0 = cf
	elseif m:IsA("AnimationConstraint") and m.Attachment0 then
		m.Attachment0.CFrame = cf
	end
end

local function C0Base(m: Instance): CFrame
	local b = base[m]
	if not b then
		b = marcoActual(m) or CFrame.new()
		base[m] = b
	end
	return b
end

-- aplica una rotación expresada en el espacio de la pieza padre
local function girar(m: Instance?, r: CFrame, desplazar: Vector3?)
	if not m or not (m:IsA("Motor6D") or m:IsA("AnimationConstraint")) then
		return
	end
	local b = C0Base(m)
	ponerMarco(m, CFrame.new(b.Position + (desplazar or Vector3.zero)) * r * b.Rotation)
end

local function suave(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function mezcla(a: number, b: number, t: number): number
	return a + (b - a) * suave(t)
end

-- ---------- animaciones de los cazadores ----------
-- Las 15 animaciones están guardadas en ReplicatedStorage > Animaciones (R6 y R15) como
-- KeyframeSequences. Este reproductor las lee pose por pose y mueve las articulaciones del
-- avatar justo después del animador de Roblox, así no hace falta publicarlas.
local Animaciones = ReplicatedStorage:WaitForChild("Animaciones")
local secuencias: { [string]: any } = {}
local mapas = setmetatable({}, { __mode = "k" })
local activas = setmetatable({}, { __mode = "k" })

local function secuencia(tipo: string, nombre: string)
	local clave = tipo .. "/" .. nombre
	local s = secuencias[clave]
	if s ~= nil then
		return s or nil
	end
	local carpeta = Animaciones:FindFirstChild(tipo)
	local kfs = carpeta and carpeta:FindFirstChild(nombre)
	if not kfs then
		secuencias[clave] = false
		return nil
	end
	local claves = {}
	for _, kf in kfs:GetChildren() do
		if kf:IsA("Keyframe") then
			local poses = {}
			for _, p in kf:GetDescendants() do
				if p:IsA("Pose") then
					poses[p.Name] = p.CFrame
				end
			end
			table.insert(claves, { t = kf.Time, poses = poses })
		end
	end
	table.sort(claves, function(x, y)
		return x.t < y.t
	end)
	if #claves == 0 then
		secuencias[clave] = false
		return nil
	end
	s = { claves = claves, largo = math.max(claves[#claves].t, 0.01) }
	secuencias[clave] = s
	return s
end

-- nombre de la pieza que mueve cada articulación -> articulación (clásicas y nuevas)
local function articulacionesPorPieza(char: Model)
	local m = mapas[char]
	if m and m.muestra and m.muestra.Parent then
		return m.juntas
	end
	local juntas = {}
	local muestra
	for _, d in char:GetDescendants() do
		if d:IsA("Motor6D") and d.Part1 then
			juntas[d.Part1.Name] = d
			muestra = d
		elseif d:IsA("AnimationConstraint") and d.Attachment1 and d.Attachment1.Parent then
			juntas[d.Attachment1.Parent.Name] = d
			muestra = d
		end
	end
	mapas[char] = { juntas = juntas, muestra = muestra }
	return juntas
end

-- Estelas de luz de las armas: encendidas solo mientras el cazador ataca.
local estelasPorArma = setmetatable({}, { __mode = "k" })
local function estelas(char: Model, encendidas: boolean)
	local arma = char:FindFirstChild("Arma")
	if not arma then
		return
	end
	local lista = estelasPorArma[arma]
	if not lista then
		lista = {}
		for _, d in arma:GetDescendants() do
			if d:IsA("Trail") then
				table.insert(lista, d)
			end
		end
		estelasPorArma[arma] = lista
	end
	for _, e in lista do
		if e.Enabled ~= encendidas then
			e.Enabled = encendidas
		end
	end
end
Anim.estelas = estelas

local function soltar(char: Model)
	estelas(char, false)
	local usadas = activas[char]
	if usadas then
		for j in usadas do
			(j :: any).Transform = CFrame.new()
		end
		activas[char] = nil
	end
end

local function animarCazador(char: Model, ahora: number)
	local nombre, t0, dur
	local propia = locales[char]
	if propia and os.clock() - propia.t0 < propia.dur then
		nombre, dur = propia.nombre, propia.dur
		t0 = ahora - (os.clock() - (propia.t0 :: number))
	else
		nombre, t0, dur = char:GetAttribute("Anim"), tonumber(char:GetAttribute("AnimT0")) or 0, tonumber(char:GetAttribute("AnimDur")) or 0.5
		-- El aviso del servidor llega un poco tarde: si es el mismo ataque que ya se animó aquí
		-- al presionar el botón, no se repite (antes se veía un tirón en el propio personaje).
		if propia and nombre == propia.nombre and math.abs(t0 - propia.t0Servidor) < 1.0 then
			soltar(char)
			return
		end
	end
	local t = (ahora - t0) / math.max(dur, 0.05)
	if type(nombre) ~= "string" or t < 0 or t >= 1 then
		soltar(char)
		return
	end
	local tipo = char:FindFirstChild("UpperTorso") and "R15" or "R6"
	local arma = char:GetAttribute("ArmaBase") or char:GetAttribute("Arma") or "espada"
	local sec = secuencia(tipo, arma .. "_" .. nombre) or secuencia(tipo, nombre)
	if not sec then
		soltar(char)
		return
	end
	estelas(char, nombre ~= "rueda" and nombre ~= "golpeado")
	-- buscar entre qué dos poses clave estamos
	local tt = t * sec.largo
	local claves = sec.claves
	local i = 1
	while i < #claves and claves[i + 1].t <= tt do
		i += 1
	end
	local a = claves[i]
	local b = claves[math.min(i + 1, #claves)]
	local alfa = (b.t > a.t) and math.clamp((tt - a.t) / (b.t - a.t), 0, 1) or 0
	alfa = alfa * alfa * (3 - 2 * alfa)
	local usadas = {}
	for pieza, j in articulacionesPorPieza(char) do
		local ca, cb = a.poses[pieza], b.poses[pieza]
		if ca or cb then
			(j :: any).Transform = (ca or CFrame.new()):Lerp(cb or CFrame.new(), alfa)
			usadas[j] = true
		end
	end
	local antes = activas[char]
	if antes then
		for j in antes do
			if not usadas[j] then
				(j :: any).Transform = CFrame.new()
			end
		end
	end
	activas[char] = usadas
end

function Anim.local_(char: Model, nombre: string, duracion: number)
	locales[char] = { nombre = nombre, t0 = os.clock(), t0Servidor = workspace:GetServerTimeNow(), dur = duracion }
end

-- ---------- Sekhmaur ----------
local FASES = { -- prep y activo de cada ataque (para saber en qué momento va)
	mordida = { 0.75, 0.3 }, pisoton = { 0.95, 0.25 }, coletazo = { 0.8, 0.55 }, aguijonazo = { 1.05, 0.22 },
	embestida = { 0.9, 1.5 }, enterrarse = { 1.0, 2.4 }, rayo_solar = { 1.25, 0.7 },
}
local motoresPorModelo = setmetatable({}, { __mode = "k" })

local vigilados = setmetatable({}, { __mode = "k" })

local function motoresDe(modelo: Model)
	local m = motoresPorModelo[modelo]
	if not vigilados[modelo] then
		-- si llegan (o se van) articulaciones después, se vuelve a armar la lista
		vigilados[modelo] = true
		local function revisar(d: Instance)
			if d:IsA("Motor6D") or d:IsA("AnimationConstraint") or d:IsA("BasePart") then
				motoresPorModelo[modelo] = nil
			end
		end
		modelo.DescendantAdded:Connect(revisar)
		modelo.DescendantRemoving:Connect(revisar)
	end
	if not m then
		m = {}
		for _, d in modelo:GetDescendants() do
			if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
				m[d.Name] = d
			end
		end
		motoresPorModelo[modelo] = m
	end
	return m
end

local function animarSekhmaur(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre = modelo:GetAttribute("Anim") or "reposo"
	local ritmo = tonumber(modelo:GetAttribute("Ritmo")) or 1
	local t = (ahora - (tonumber(modelo:GetAttribute("AnimT0")) or 0)) * ritmo
	local cuerpoR, cuerpoY = CFrame.new(), 0
	local cuello, mandibula = 0, 0
	local cadera = { DI = 0, DD = 0, TI = 0, TD = 0 }
	local rodilla = { DI = 0, DD = 0, TI = 0, TD = 0 }
	local colaCurva, colaLado = 0, math.sin(reloj * 1.5) * 0.12
	local COLA_REPOSO = { 0.6, 0.4, 0.2, -0.4, -0.5 } -- baja hasta el suelo y el aguijón queda arriba
	local respira = math.sin(reloj * 2) * 0.04
	-- paso: patas diagonales juntas
	local function andar(velocidad, amplitud)
		local f = t * velocidad
		for n, fase in { DI = 0, TD = 0, DD = math.pi, TI = math.pi } do
			local s = math.sin(f + fase)
			cadera[n] = s * amplitud
			rodilla[n] = -math.max(0, math.cos(f + fase)) * amplitud * 1.1
		end
		cuerpoY = math.abs(math.sin(f)) * 0.12
	end
	local fases = FASES[nombre]
	local prep = fases and fases[1] or 0
	local enPrep = fases and t < prep
	if nombre == "caminar" then
		andar(5.5, 0.45)
	elseif nombre == "correr" then
		andar(9, 0.7)
		cuello = 0.15
	elseif nombre == "beber" then
		cuello = 0.65
		mandibula = -0.2 * (1 + math.sin(reloj * 6)) * 0.5
		cadera.DI, cadera.DD = -0.2, -0.2
	elseif nombre == "rugir" then
		cuello = -0.5
		mandibula = -0.75
		cuerpoY = 0.15
	elseif nombre == "mordida" then
		if enPrep then
			cuello, mandibula = -0.35, -0.7
		else
			cuello, mandibula = 0.35, 0
		end
	elseif nombre == "pisoton" then
		local lado = "DI"
		if enPrep then
			cadera[lado] = mezcla(0, 1.1, t / prep)
			rodilla[lado] = -0.9 * suave(t / prep)
			cuerpoR = CFrame.Angles(-0.12, 0, 0)
		else
			cadera[lado] = mezcla(1.1, 0, (t - prep) / 0.12)
		end
	elseif nombre == "coletazo" then
		if enPrep then
			colaLado = mezcla(0, -0.6, t / prep)
		else
			colaLado = mezcla(-0.6, 0.9, (t - prep) / 0.3)
		end
	elseif nombre == "aguijonazo" then
		if enPrep then
			colaCurva = mezcla(0, -0.95, t / prep)
		else
			colaCurva = mezcla(-0.95, -0.2, (t - prep) / 0.15)
		end
		cuello = 0.1
	elseif nombre == "enterrarse" then
		if enPrep then
			andar(12, 0.35)
			cuello = 0.5
			cuerpoY = -mezcla(0, 1.5, t / prep)
		end
	elseif nombre == "rayo_solar" then
		if enPrep then
			cuello = mezcla(0, -0.7, t / prep)
		else
			cuello = -0.05
			mandibula = -0.8
		end
	elseif nombre == "estremecer" then
		cuerpoR = CFrame.Angles(0, 0, math.sin(t * 22) * 0.08 * math.max(0, 1 - t / 1.4))
		cuello = 0.3
	elseif nombre == "derribado" or nombre == "muerte" then
		local k = suave(t / 0.5)
		cuerpoR = CFrame.Angles(0, 0, 1.45 * k)
		cuerpoY = -1.6 * k
		mandibula = nombre == "muerte" and -0.4 or -0.25
		if nombre == "derribado" then
			for n in cadera do
				cadera[n] = math.sin(reloj * 7 + #n) * 0.4
			end
		end
	elseif nombre == "levantarse" then
		local k = 1 - suave(t / 1.2)
		cuerpoR = CFrame.Angles(0, 0, 1.45 * k)
		cuerpoY = -1.6 * k
	end
	girar(motores.RaizCuerpo, cuerpoR, Vector3.new(0, (cuerpoY + respira) * S, 0))
	girar(motores.Cuello, CFrame.Angles(cuello, 0, 0))
	girar(motores.Mandibula, CFrame.Angles(mandibula, 0, 0))
	for n in cadera do
		girar(motores["Cadera" .. n], CFrame.Angles(cadera[n], 0, 0))
		girar(motores["Rodilla" .. n], CFrame.Angles(rodilla[n], 0, 0))
	end
	for i = 1, 5 do
		girar(motores["Cola" .. i], CFrame.Angles(COLA_REPOSO[i] + colaCurva, i == 1 and colaLado or colaLado * 0.3, 0))
	end
	for i = 1, 2 do
		local m = motores["Anillo" .. i]
		if m then
			ponerMarco(m, C0Base(m) * CFrame.Angles(reloj * (1.2 + i * 0.6) * (i == 1 and 1 or -1), 0, 0))
		end
	end
end

-- ---------- Kheprak ----------
local TRIPODE = { FI = 0, MD = 0, TI = 0, FD = math.pi, MI = math.pi, TD = math.pi }
local LADO = { FI = -1, MI = -1, TI = -1, FD = 1, MD = 1, TD = 1 }

local function animarKheprak(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre = modelo:GetAttribute("Anim") or "reposo"
	local ritmo = tonumber(modelo:GetAttribute("Ritmo")) or 1
	local t = (ahora - (tonumber(modelo:GetAttribute("AnimT0")) or 0)) * ritmo
	local cuerpo, alto = CFrame.new(), math.sin(reloj * 2) * 0.03
	local cuello, cuerno, elitros, alas = 0, 0, 0, 0
	local giro, subir = {}, {}
	for n in TRIPODE do
		giro[n], subir[n] = 0, 0
	end
	local function andar(vel, amp)
		for n, fase in TRIPODE do
			giro[n] = math.sin(t * vel + fase) * amp
			subir[n] = math.max(0, math.cos(t * vel + fase)) * amp * 0.8
		end
		alto += math.abs(math.sin(t * vel * 2)) * 0.05
	end
	if nombre == "caminar" then
		andar(6, 0.35)
	elseif nombre == "correr" then
		andar(11, 0.5)
		cuerpo = CFrame.Angles(-0.06, 0, 0)
	elseif nombre == "escarbar" then
		giro.FI, giro.FD = math.sin(t * 10) * 0.8, -math.sin(t * 10) * 0.8
		cuello = 0.35
		cuerpo = CFrame.Angles(-0.15, 0, 0)
	elseif nombre == "rugir" then
		cuerpo = CFrame.Angles(0.35, 0, 0)
		alto = 0.7
		elitros = 0.55
		alas = math.sin(reloj * 30) * 0.4
		cuerno = -0.3
		subir.FI, subir.FD = 0.8, 0.8
	elseif nombre == "pinza" then
		if t < 0.65 then
			cuerno, cuello = -0.35, -0.3
		else
			cuerno, cuello = 0.25, 0.25
			cuerpo = CFrame.Angles(-0.12, 0, 0)
		end
	elseif nombre == "embestida_carga" then
		cuello, cuerno = 0.35, 0.2
		cuerpo = CFrame.Angles(-0.12, 0, 0)
		giro.FI, giro.FD = math.sin(t * 14) * 0.7, -math.sin(t * 14) * 0.7
	elseif nombre == "salto" then
		if t < 0.75 then
			alto = -0.6
		elseif t < 1.7 then
			elitros = 1.0
			alas = math.sin(reloj * 35) * 0.5
			for n in subir do
				subir[n] = 0.6
			end
		else
			alto = -0.6
		end
	elseif nombre == "bola_carga" then
		cuello, cuerno = 0.45, 0.3
		cuerpo = CFrame.Angles(-0.18, 0, math.sin(t * 20) * 0.03)
		giro.FI, giro.FD = math.sin(t * 16) * 0.9, -math.sin(t * 16) * 0.9
		subir.FI, subir.FD = math.max(0, math.sin(t * 16)) * 0.4, math.max(0, -math.sin(t * 16)) * 0.4
	elseif nombre == "lanzar_bola" then
		cuerpo = CFrame.Angles(-0.25, 0, 0)
		giro.FI, giro.FD = 1.0, 1.0
	elseif nombre == "estremecer" then
		cuerpo = CFrame.Angles(-0.12, 0, math.sin(t * 22) * 0.08 * math.max(0, 1 - t / 1.4))
		cuello = 0.3
	elseif nombre == "derribado" or nombre == "muerte" then
		-- queda boca arriba agitando las patas
		local k = suave(t / 0.5)
		cuerpo = CFrame.Angles(0, 0, math.pi * k)
		alto = -0.4 * k -- el caparazón queda apoyado en la arena
		if nombre == "derribado" then
			for n, fase in TRIPODE do
				giro[n] = math.sin(reloj * 8 + fase) * 0.6
				subir[n] = 0.5
			end
		else
			for n in subir do
				subir[n] = 0.9
			end
		end
	elseif nombre == "levantarse" then
		local k = 1 - suave(t / 1.2)
		cuerpo = CFrame.Angles(0, 0, math.pi * k)
		alto = -0.4 * k
	end
	girar(motores.RaizCuerpo, cuerpo, Vector3.new(0, alto * S, 0))
	girar(motores.Cuello, CFrame.Angles(cuello, 0, 0))
	girar(motores.Cuerno, CFrame.Angles(cuerno, 0, 0))
	girar(motores.ElitroI, CFrame.Angles(0, 0, -elitros))
	girar(motores.ElitroD, CFrame.Angles(0, 0, elitros))
	girar(motores.AlaI, CFrame.Angles(0, 0, -alas))
	girar(motores.AlaD, CFrame.Angles(0, 0, alas))
	for n, lado in LADO do
		girar(motores["Cadera" .. n], CFrame.Angles(0, giro[n] * lado, subir[n] * -lado))
	end
end

-- ---------- Amaru ----------
local function animarAmaru(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre = modelo:GetAttribute("Anim") or "reposo"
	local ritmo = tonumber(modelo:GetAttribute("Ritmo")) or 1
	local t = (ahora - (tonumber(modelo:GetAttribute("AnimT0")) or 0)) * ritmo
	local onda, velOnda = 0.12, 2
	local cabeza, mandibula, alas, cuerpoR, alto = 0, 0, math.sin(reloj * 1.5) * 0.1, CFrame.new(), 0
	local enrosque = 0
	if nombre == "reptar" then
		onda, velOnda = 0.35, 6 * ritmo
	elseif nombre == "rugir" then
		cabeza, mandibula = -0.6, -0.8
		alas = 0.6 + math.sin(reloj * 20) * 0.2
		alto = 1.2
	elseif nombre == "mordida" then
		if t < 0.6 then
			cabeza, mandibula = -0.5, -0.9
		else
			cabeza, mandibula = 0.35, 0
		end
	elseif nombre == "latigazo" then
		onda, velOnda = 0.6, 14
	elseif nombre == "enroscarse" then
		enrosque = math.min(1, t / 1.2)
		cabeza = -0.3
	elseif nombre == "planeo" then
		alas = 0.9 + math.sin(reloj * 18) * 0.4
		cabeza = 0.2
		onda = 0.15
	elseif nombre == "rayo" then
		if t < 1.1 then
			cabeza = -0.5 + t * 0.4
		end
		mandibula = t > 1.1 and -0.9 or -0.3
	elseif nombre == "plumas" then
		alas = 1.0 + math.sin(reloj * 25) * 0.3
		cabeza = -0.4
	elseif nombre == "nube" then
		alas = 0.7
		cabeza, mandibula = -0.4, -0.6
	elseif nombre == "estremecer" then
		cuerpoR = CFrame.Angles(0, 0, math.sin(t * 22) * 0.1 * math.max(0, 1 - t / 1.4))
		onda = 0.4
	elseif nombre == "derribado" or nombre == "muerte" then
		local k = suave(t / 0.5)
		cuerpoR = CFrame.Angles(0, 0, math.pi * 0.9 * k)
		onda = nombre == "derribado" and 0.3 or 0
		velOnda = 9
		mandibula = -0.5
	elseif nombre == "levantarse" then
		cuerpoR = CFrame.Angles(0, 0, math.pi * 0.9 * (1 - suave(t / 1.2)))
	end
	girar(motores.RaizCuerpo, cuerpoR, Vector3.new(0, alto * S, 0))
	girar(motores.CuelloCabeza, CFrame.Angles(cabeza, 0, 0))
	girar(motores.Mandibula, CFrame.Angles(mandibula, 0, 0))
	girar(motores.AlaI, CFrame.Angles(0, 0, -alas))
	girar(motores.AlaD, CFrame.Angles(0, 0, alas))
	-- el cuerpo ondula de lado a lado como una serpiente (o se enrosca)
	for i = 1, 10 do
		local lado = math.sin(reloj * velOnda - i * 0.7) * onda
		girar(motores["Seg" .. i], CFrame.Angles(0, lado + enrosque * 0.55, 0))
	end
end

-- ---------- Apu Rumi ----------
local function animarApu(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre = modelo:GetAttribute("Anim") or "reposo"
	local ritmo = tonumber(modelo:GetAttribute("Ritmo")) or 1
	local t = (ahora - (tonumber(modelo:GetAttribute("AnimT0")) or 0)) * ritmo
	local hombro = { I = 0, D = 0 }
	local codo = { I = 0, D = 0 }
	local cadera = { I = 0, D = 0 }
	local cuerpo, alto, cuello = CFrame.new(), math.sin(reloj * 1.6) * 0.05, 0
	local function andar(vel, amp)
		hombro.I = math.sin(t * vel) * amp
		hombro.D = -math.sin(t * vel) * amp
		cadera.I = -math.sin(t * vel) * amp * 0.7
		cadera.D = math.sin(t * vel) * amp * 0.7
		alto += math.abs(math.sin(t * vel)) * 0.15
	end
	if nombre == "caminar" then
		andar(4, 0.4)
	elseif nombre == "correr" then
		andar(8, 0.7)
		cuerpo = CFrame.Angles(0.15, 0, 0)
	elseif nombre == "punetazo" then
		if t < 0.8 then
			local k = suave(t / 0.8)
			hombro.I, hombro.D = -2.4 * k, -2.4 * k
			cuerpo = CFrame.Angles(-0.25 * k, 0, 0)
			alto = 0.5 * k
		else
			hombro.I, hombro.D = 0.6, 0.6
			cuerpo = CFrame.Angles(0.25, 0, 0)
		end
	elseif nombre == "pecho" or nombre == "rugir" then
		-- se golpea el pecho alternando los brazos
		local golpe = math.sin(reloj * 14)
		hombro.I, hombro.D = -1.3 + math.max(0, golpe) * 0.5, -1.3 + math.max(0, -golpe) * 0.5
		codo.I, codo.D = -1.4, -1.4
		cuerpo = CFrame.Angles(-0.35, 0, 0)
		alto = 0.8
		cuello = -0.4
	elseif nombre == "roca" then
		if t < 1.0 then
			local k = suave(t / 1.0)
			hombro.I, hombro.D = -2.8 * k, -2.8 * k
			cuerpo = CFrame.Angles(-0.3 * k, 0, 0)
		else
			hombro.I, hombro.D = -0.8, -0.8
			cuerpo = CFrame.Angles(0.2, 0, 0)
		end
	elseif nombre == "salto" then
		if t < 0.8 then
			alto = -0.6
			hombro.I, hombro.D = 0.5, 0.5
		elseif t < 1.7 then
			hombro.I, hombro.D = -2.6, -2.6
			cadera.I, cadera.D = -0.6, -0.6
		else
			alto = -0.6
			hombro.I, hombro.D = 0.7, 0.7
		end
	elseif nombre == "rayo_sol" then
		cuerpo = CFrame.Angles(-0.45, 0, 0)
		hombro.I, hombro.D = 0.9, 0.9
		cuello = -0.3
	elseif nombre == "estremecer" then
		cuerpo = CFrame.Angles(0, 0, math.sin(t * 20) * 0.08 * math.max(0, 1 - t / 1.4))
		cuello = 0.3
	elseif nombre == "derribado" or nombre == "muerte" then
		-- cae de espaldas
		local k = suave(t / 0.6)
		cuerpo = CFrame.Angles(-1.3 * k, 0, 0)
		alto = -2.2 * k
		hombro.I, hombro.D = -1.4 * k, -1.4 * k
		if nombre == "derribado" then
			hombro.I += math.sin(reloj * 6) * 0.3
			hombro.D -= math.sin(reloj * 6) * 0.3
		end
	elseif nombre == "levantarse" then
		local k = 1 - suave(t / 1.4)
		cuerpo = CFrame.Angles(-1.3 * k, 0, 0)
		alto = -2.2 * k
	end
	girar(motores.RaizCuerpo, cuerpo, Vector3.new(0, alto * S, 0))
	girar(motores.Cuello, CFrame.Angles(cuello, 0, 0))
	for _, L in { "I", "D" } do
		girar(motores["Hombro" .. L], CFrame.Angles(hombro[L], 0, 0))
		girar(motores["Codo" .. L], CFrame.Angles(codo[L], 0, 0))
		girar(motores["Cadera" .. L], CFrame.Angles(cadera[L], 0, 0))
	end
end

function Anim.iniciar()
	RunService.PreSimulation:Connect(function()
		local ahora = workspace:GetServerTimeNow()
		local reloj = os.clock()
		for _, j in Players:GetPlayers() do
			local char = j.Character
			if char and char.Parent then
				local ok, err = pcall(animarCazador, char, ahora)
				if not ok and not avisado[char] then
					avisado[char] = true
					warn("Animación de " .. j.Name .. ": " .. tostring(err))
				end
			end
		end
		local carpeta = workspace:FindFirstChild("Behemoths")
		if carpeta then
			for _, bestia in carpeta:GetChildren() do
				local cual = bestia:GetAttribute("Nombre")
				local animar = AnimSelva.animadores[cual] or (cual == "Kheprak" and animarKheprak or (cual == "Amaru" and animarAmaru or (cual == "Apu Rumi" and animarApu or animarSekhmaur)))
				if AnimSelva.animadores[cual] and not AnimSelva.visible(bestia) then
					continue -- un Behemoth de otra isla: no hace falta moverlo
				end
				local ok, err = pcall(animar, bestia, ahora, reloj)
				if not ok and not avisado[bestia] then
					avisado[bestia] = true
					warn("Animación de " .. bestia.Name .. ": " .. tostring(err))
				end
			end
		end
	end)
end

return Anim
