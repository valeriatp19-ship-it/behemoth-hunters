--!nonstrict
-- Animaciones por código de los Behemoths de la Selva de Obsidiana (Camazotz, Xolotl, Balam y
-- Cipactli). El servidor solo anuncia qué hace cada uno (atributos Anim, AnimT0, Ritmo, Prep, Act,
-- Rec) y aquí se mueven sus articulaciones cada cuadro.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Compartido = ReplicatedStorage:WaitForChild("Compartido")
local Config = require(Compartido:WaitForChild("Config"))
local Poses = require(Compartido:WaitForChild("PosesSelva"))

local S = Config.S
local AnimSelva = {}

-- ---------- ayudas ----------
local base = setmetatable({}, { __mode = "k" }) -- C0 original de cada articulación
local cache = setmetatable({}, { __mode = "k" })

local function motoresDe(modelo: Model)
	local m = cache[modelo]
	if m then
		for _, x in m do
			if not x.Parent then
				m = nil
				break
			end
		end
	end
	if not m then
		m = {}
		for _, d in modelo:GetDescendants() do
			if d:IsA("Motor6D") then
				m[d.Name] = d
			end
		end
		cache[modelo] = m
	end
	return m
end

local function C0Base(m: any): CFrame
	local b = base[m]
	if not b then
		b = m.C0
		base[m] = b
	end
	return b
end

-- gira una articulación respecto a su pose original (en el espacio de la pieza padre)
local function girar(m: any, r: CFrame, desplazar: Vector3?)
	if not m then
		return
	end
	local b = C0Base(m)
	m.C0 = CFrame.new(b.Position + (desplazar or Vector3.zero)) * r * b.Rotation
end

local function poner(m: any, cf: CFrame)
	if not m then
		return
	end
	C0Base(m)
	m.C0 = cf
end

local function suave(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function mezcla(a: number, b: number, t: number): number
	return a + (b - a) * suave(t)
end

-- datos de la animación actual
local function estado(modelo: Model, ahora: number)
	local nombre = modelo:GetAttribute("Anim") or "reposo"
	local ritmo = tonumber(modelo:GetAttribute("Ritmo")) or 1
	local t = (ahora - (tonumber(modelo:GetAttribute("AnimT0")) or 0)) * ritmo
	return nombre, math.max(0, t), ritmo
end

-- en qué parte del ataque va: "prep", "act" o "rec", y cuánto lleva de esa parte (0..1)
local function fase(modelo: Model, t: number)
	local prep = tonumber(modelo:GetAttribute("Prep")) or 1
	local act = tonumber(modelo:GetAttribute("Act")) or 0.4
	local rec = tonumber(modelo:GetAttribute("Rec")) or 0.8
	if t < prep then
		return "prep", t / prep, t
	elseif t < prep + act then
		return "act", (t - prep) / act, t - prep
	end
	return "rec", math.min(1, (t - prep - act) / rec), t - prep - act
end

AnimSelva.suave, AnimSelva.mezcla, AnimSelva.girar, AnimSelva.poner = suave, mezcla, girar, poner

-- nombres y listas fijas: se arman una vez para no crear tablas ni textos en cada cuadro
local SIGNOS = { -1, 1 }
local LADOS = { "I", "D" }
local DEDOS = { "Dedo1", "Dedo2", "Dedo3" }
local COLA = { "Cola1", "Cola2", "Cola3", "Cola4", "Cola5" }
-- patas en diagonal: { motor, desfase, lado }
local PATAS4 = { { "PataDI", 0, -1 }, { "PataTD", 0, 1 }, { "PataDD", math.pi, 1 }, { "PataTI", math.pi, -1 } }
local BRANQUIA = { I = { "BranquiaI1", "BranquiaI2", "BranquiaI3" }, D = { "BranquiaD1", "BranquiaD2", "BranquiaD3" } }
local MIEMBRO = {
	I = { hombro = "HombroI", codo = "CodoI", cadera = "CaderaI", rodilla = "RodillaI" },
	D = { hombro = "HombroD", codo = "CodoD", cadera = "CaderaD", rodilla = "RodillaD" },
}
local MEM = {}
for _, dedo in DEDOS do
	MEM[dedo] = { I = {}, D = {} }
	for k in Poses.CAMAZOTZ.membranas[dedo] do
		MEM[dedo].I[k] = "Mem" .. dedo .. "I" .. k
		MEM[dedo].D[k] = "Mem" .. dedo .. "D" .. k
	end
end

-- ---------- Camazotz ----------
local v = Vector3.new
local function alas(motores, abrir, extraI, extraD)
	for _, lado in SIGNOS do
		local L = lado < 0 and "I" or "D"
		local extra = lado < 0 and extraI or extraD
		local a = type(abrir) == "table" and abrir[L] or abrir
		local c0 = Poses.alaCamazotz(lado, a, extra, S)
		for nombre, cf in c0 do
			poner(motores[nombre], cf)
		end
		for _, dedo in DEDOS do
			local largo = Poses.CAMAZOTZ.largos[dedo]
			local nombres = MEM[dedo][L]
			for k, m in Poses.CAMAZOTZ.membranas[dedo] do
				poner(motores[nombres[k]], Poses.membranaCamazotz(largo, m[1], a, S))
			end
		end
	end
end

local function animarCamazotz(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre, t = estado(modelo, ahora)
	local respira = math.sin(reloj * 1.7)
	-- valores por defecto: de pie sobre las muñecas, respirando
	local cuerpo = CFrame.Angles(respira * 0.02, 0, 0)
	local alto = respira * 0.06
	local adelante = 0
	local cuello, giroCuello, boca = -0.05 + respira * 0.03, math.sin(reloj * 0.6) * 0.25, 0.05
	local orejas = math.sin(reloj * 2.3) * 0.08
	local abrir = 0
	local extraI, extraD = {}, {}
	local caderaI, caderaD, rodilla = 0, 0, 0
	local cola = math.sin(reloj * 1.3) * 0.1
	local function paso(vel, amp)
		-- las muñecas se turnan como patas delanteras; las patas traseras van al revés
		local f = t * vel
		local sI, sD = math.sin(f), math.sin(f + math.pi)
		extraI.Antebrazo = v(0, math.max(0, sI) * 0.35, -sI * amp)
		extraD.Antebrazo = v(0, math.max(0, sD) * 0.35, -sD * amp)
		extraI.Brazo = v(0, 0, -sI * amp * 0.4)
		extraD.Brazo = v(0, 0, -sD * amp * 0.4)
		caderaI, caderaD = -sD * amp * 1.2, -sI * amp * 1.2
		alto += math.abs(math.cos(f)) * 0.18
		cuerpo = cuerpo * CFrame.Angles(0, 0, math.sin(f) * 0.05)
		giroCuello = math.sin(f) * 0.08
		orejas = math.sin(f * 2) * 0.06
	end
	if nombre == "caminar" then
		paso(4.2, 0.35)
	elseif nombre == "correr" then
		paso(7.5, 0.55)
		cuerpo = cuerpo * CFrame.Angles(-0.12, 0, 0)
		alto -= 0.25
		cuello = 0.1
		orejas = -0.35 -- orejas hacia atrás al correr
	elseif nombre == "rugir" then
		-- se levanta, abre las alas y chilla
		local k = suave(t / 0.5)
		cuerpo = CFrame.Angles(0.45 * k, 0, 0)
		alto = 1.2 * k
		abrir = 0.85 * k
		extraI.Brazo = v(0, math.sin(reloj * 9) * 0.15 * k, 0)
		extraD.Brazo = v(0, math.sin(reloj * 9) * 0.15 * k, 0)
		cuello = -0.35 * k
		boca = 0.7 * k
		orejas = 0.3 * k
		caderaI, caderaD = 0.4 * k, 0.4 * k
	elseif nombre == "zarpazo" then
		-- levanta el ala derecha y la descarga hacia delante
		local f, k = fase(modelo, t)
		local subir, bajar = 0, 0
		if f == "prep" then
			subir = suave(k)
		elseif f == "act" then
			subir, bajar = 1 - suave(k), suave(k)
		else
			bajar = 1 - suave(k)
		end
		abrir = { I = 0, D = 0.35 * subir + 0.15 * bajar }
		extraD.Brazo = v(0.2, 0.9, 0.5) * subir + v(0.3, -0.1, -0.9) * bajar
		extraD.Antebrazo = v(0.3, 1.4, 0.6) * subir + v(0.1, 0.2, -1.6) * bajar
		cuerpo = CFrame.Angles(0.12 * subir - 0.15 * bajar, 0.25 * subir - 0.3 * bajar, 0)
		adelante = 0.8 * bajar
		giroCuello = -0.2 * subir
		boca = 0.3 * subir
	elseif nombre == "mordida" then
		local f, k = fase(modelo, t)
		local atras, lanza = 0, 0
		if f == "prep" then
			atras = suave(k)
		elseif f == "act" then
			atras, lanza = 1 - suave(k * 2), suave(k * 2)
		else
			lanza = 1 - suave(k)
		end
		cuerpo = CFrame.Angles(0.2 * atras - 0.25 * lanza, 0, 0)
		adelante = -0.6 * atras + 1.6 * lanza
		alto = 0.3 * atras - 0.3 * lanza
		cuello = -0.3 * atras + 0.45 * lanza
		boca = f == "act" and (k < 0.5 and 0.9 or 0.1) or (0.8 * atras)
		orejas = -0.3 * lanza
		extraI.Antebrazo = v(0, 0, 0.3 * atras - 0.5 * lanza)
		extraD.Antebrazo = v(0, 0, 0.3 * atras - 0.5 * lanza)
	elseif nombre == "grito" then
		-- se yergue, abre las alas y lanza el grito con la boca muy abierta
		local f, k = fase(modelo, t)
		local erguir = f == "prep" and suave(k) or (f == "act" and 1 or 1 - suave(k))
		local gritar = f == "act" and 1 or 0
		cuerpo = CFrame.Angles(0.4 * erguir - 0.15 * gritar, 0, 0)
		alto = 1.0 * erguir
		abrir = 0.95 * erguir
		cuello = -0.35 * erguir + 0.1 * gritar
		boca = 0.4 * erguir + 0.6 * gritar
		orejas = 0.35 * erguir
		if gritar > 0 then
			-- todo el cuerpo vibra con el grito
			cuerpo = cuerpo * CFrame.Angles(math.sin(reloj * 40) * 0.02, math.sin(reloj * 33) * 0.02, 0)
			extraI.Dedo1 = v(0, math.sin(reloj * 30) * 0.1, 0)
			extraD.Dedo1 = v(0, math.sin(reloj * 30) * 0.1, 0)
		end
		caderaI, caderaD = 0.35 * erguir, 0.35 * erguir
	elseif nombre == "onda" then
		-- se envuelve en sus alas y las abre de golpe
		local f, k = fase(modelo, t)
		local envolver = f == "prep" and suave(k) or 0
		local abrirGolpe = f == "act" and 1 or (f == "rec" and 1 - suave(k) or 0)
		abrir = 0.95 * abrirGolpe
		-- (el lado izquierdo se refleja después: el mismo valor envuelve las dos alas hacia adentro)
		extraI.Brazo = v(-0.6, 0.2, -0.8) * envolver
		extraD.Brazo = v(-0.6, 0.2, -0.8) * envolver
		extraI.Antebrazo = v(-0.8, 0.4, -0.6) * envolver
		extraD.Antebrazo = v(-0.8, 0.4, -0.6) * envolver
		cuerpo = CFrame.Angles(-0.15 * envolver + 0.35 * abrirGolpe, 0, 0)
		alto = -0.4 * envolver + 0.8 * abrirGolpe
		cuello = 0.35 * envolver - 0.3 * abrirGolpe
		boca = 0.8 * abrirGolpe
		orejas = 0.4 * abrirGolpe
	elseif nombre == "picada" then
		-- aletea para subir, se lanza en picada y aterriza con las alas abiertas
		local f, k = fase(modelo, t)
		if f == "prep" then
			abrir = 1
			local aleteo = math.sin(reloj * 11)
			extraI.Brazo = v(0, aleteo * 0.7, 0)
			extraD.Brazo = v(0, aleteo * 0.7, 0)
			extraI.Antebrazo = v(0, aleteo * 0.5, 0)
			extraD.Antebrazo = v(0, aleteo * 0.5, 0)
			cuerpo = CFrame.Angles(0.3, 0, 0)
			cuello = -0.2
			caderaI, caderaD = 0.6, 0.6
		elseif f == "act" then
			-- alas plegadas hacia atrás, cabeza abajo
			abrir = 0.55
			extraI.Brazo = v(0, 0.3, 0.9)
			extraD.Brazo = v(0, 0.3, 0.9)
			extraI.Antebrazo = v(0, 0.4, 1.2)
			extraD.Antebrazo = v(0, 0.4, 1.2)
			cuerpo = CFrame.Angles(-0.55, 0, 0)
			cuello = 0.2
			boca = 0.8
			orejas = -0.5
			caderaI, caderaD = 0.9, 0.9
		else
			local q = 1 - suave(k)
			abrir = 0.9 * q
			cuerpo = CFrame.Angles(-0.25 * q, 0, 0)
			alto = -0.6 * q
			boca = 0.5 * q
		end
	elseif nombre == "enjambre" then
		-- alas abiertas en alto: los murciélagos salen de su pelaje
		local f, k = fase(modelo, t)
		local q = f == "prep" and suave(k) or (f == "act" and 1 or 1 - suave(k))
		abrir = q
		local aleteo = math.sin(reloj * 6) * 0.25 * q
		extraI.Brazo = v(0, 0.3 * q + aleteo, 0)
		extraD.Brazo = v(0, 0.3 * q + aleteo, 0)
		cuerpo = CFrame.Angles(0.4 * q, 0, 0)
		alto = 1.0 * q
		cuello = -0.35 * q
		boca = 0.6 * q
		orejas = 0.3 * q
		caderaI, caderaD = 0.35 * q, 0.35 * q
	elseif nombre == "estremecer" then
		local q = math.max(0, 1 - t / 1.4)
		cuerpo = CFrame.Angles(0, 0, math.sin(t * 22) * 0.07 * q)
		abrir = 0.25 * q
		cuello = 0.3 * q
		boca = 0.5 * q
		orejas = -0.4 * q
	elseif nombre == "derribado" or nombre == "muerte" then
		-- cae de lado con las alas desparramadas
		local k = suave(t / 0.7)
		cuerpo = CFrame.Angles(0.15 * k, 0, 1.25 * k)
		alto = -1.6 * k
		abrir = { I = 0.25 * k, D = 0.7 * k }
		extraD.Brazo = v(0, -0.5, 0) * k
		cuello = 0.3 * k
		giroCuello = 0
		boca = nombre == "muerte" and 0.6 * k or 0.3 + math.sin(reloj * 3) * 0.1
		orejas = -0.6 * k
		caderaI, caderaD = 0.5 * k, -0.3 * k
		if nombre == "derribado" then
			-- patalea intentando levantarse
			extraI.Antebrazo = v(0, math.sin(reloj * 7) * 0.3, 0) * k
			caderaI += math.sin(reloj * 8) * 0.3 * k
		end
	elseif nombre == "levantarse" then
		local q = 1 - suave(t / 1.4)
		cuerpo = CFrame.Angles(0.15 * q, 0, 1.25 * q)
		alto = -1.6 * q
		abrir = { I = 0.25 * q, D = 0.7 * q }
	end
	girar(motores.RaizCuerpo, cuerpo, v(0, alto * S, -adelante * S))
	girar(motores.Cuello, CFrame.Angles(cuello, giroCuello, 0))
	girar(motores.Mandibula, CFrame.Angles(-boca * 0.9, 0, 0))
	girar(motores.OrejaI, CFrame.Angles(-orejas, 0, -orejas * 0.3))
	girar(motores.OrejaD, CFrame.Angles(-orejas, 0, orejas * 0.3))
	girar(motores.CaderaI, CFrame.Angles(caderaI, 0, 0))
	girar(motores.CaderaD, CFrame.Angles(caderaD, 0, 0))
	girar(motores.RodillaI, CFrame.Angles(rodilla, 0, 0))
	girar(motores.RodillaD, CFrame.Angles(rodilla, 0, 0))
	girar(motores.Cola, CFrame.Angles(cola, 0, 0))
	alas(motores, abrir, extraI, extraD)
end

-- ---------- Xolotl ----------
local function animarXolotl(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre, t = estado(modelo, ahora)
	local respira = math.sin(reloj * 1.4)
	local cuerpo = CFrame.Angles(respira * 0.015, 0, 0)
	local alto, adelante = respira * 0.05, 0
	local cuello, giroCuello, boca = 0, math.sin(reloj * 0.5) * 0.15, 0.04 + math.max(0, respira) * 0.04
	local abrirBranquias, aleteo = 0, math.sin(reloj * 3) * 0.08
	local colaLado, colaOnda = 0, 0.12
	local fasePaso, ampPaso = reloj * 1.3, 0
	local inclina = 0 -- cuánto levanta el frente (la cola se queda abajo)
	local function nadar(vel, amp)
		fasePaso, ampPaso = t * vel, amp
		cuerpo = cuerpo * CFrame.Angles(0, math.sin(fasePaso) * amp * 0.35, 0)
		colaOnda = amp * 0.9
		giroCuello = -math.sin(fasePaso) * amp * 0.3
		alto += math.abs(math.sin(fasePaso)) * 0.08
	end
	if nombre == "caminar" then
		nadar(4.5, 0.5)
	elseif nombre == "correr" then
		nadar(8, 0.75)
		cuello = 0.1
	elseif nombre == "rugir" or nombre == "rayos" then
		-- se yergue, abre la boca y las branquias se abren como una corona
		local k = suave(t / 0.5)
		if nombre == "rayos" then
			local f, q = fase(modelo, t)
			k = f == "prep" and suave(q * 2) or (f == "act" and 1 or 1 - suave(q))
		end
		cuerpo = CFrame.Angles(0.35 * k, 0, math.sin(reloj * 25) * 0.02 * k)
		inclina = 0.35 * k
		alto = 0.9 * k
		cuello = -0.4 * k
		boca = 0.55 * k
		abrirBranquias = 0.7 * k
		aleteo = math.sin(reloj * 22) * 0.15 * k
	elseif nombre == "mordida" then
		local f, k = fase(modelo, t)
		local atras, lanza = 0, 0
		if f == "prep" then
			atras = suave(k)
		elseif f == "act" then
			atras, lanza = 1 - suave(k * 2), suave(k * 2)
		else
			lanza = 1 - suave(k)
		end
		cuerpo = CFrame.Angles(0.15 * atras - 0.12 * lanza, 0, 0)
		inclina = 0.15 * atras - 0.12 * lanza
		adelante = -0.5 * atras + 1.6 * lanza
		cuello = -0.35 * atras + 0.25 * lanza
		boca = f == "act" and (k < 0.5 and 0.8 or 0.05) or 0.7 * atras
		abrirBranquias = 0.3 * atras
	elseif nombre == "coletazo" then
		local f, k = fase(modelo, t)
		local carga, latigo = 0, 0
		if f == "prep" then
			carga = suave(k)
		elseif f == "act" then
			carga, latigo = 1 - suave(k), suave(k)
		else
			latigo = 1 - suave(k)
		end
		cuerpo = CFrame.Angles(0, 0.55 * carga - 0.9 * latigo, 0)
		colaLado = -0.5 * carga + 0.9 * latigo
		colaOnda = 0.05
		giroCuello = -0.3 * carga + 0.4 * latigo
	elseif nombre == "chorro" then
		local f, k = fase(modelo, t)
		local q = f == "prep" and suave(k) or (f == "act" and 1 or 1 - suave(k))
		cuerpo = CFrame.Angles(0.22 * q, 0, 0)
		inclina = 0.22 * q
		alto = 0.5 * q
		cuello = -0.15 * q
		boca = 0.85 * q
		abrirBranquias = 0.35 * q
		if f == "act" then
			cuerpo = cuerpo * CFrame.Angles(math.sin(reloj * 35) * 0.02, 0, 0)
		end
	elseif nombre == "sumergirse" then
		local f, k = fase(modelo, t)
		if f == "prep" then
			-- se zambulle de cabeza
			cuerpo = CFrame.Angles(-0.45 * suave(k), 0, 0)
			cuello = 0.3 * suave(k)
		elseif f == "act" then
			cuerpo = CFrame.Angles(-0.45, 0, 0)
			colaOnda = 0.6
			nadar(9, 0.8)
		else
			-- sale de golpe, erguido y con la boca abierta
			local q = 1 - suave(k)
			cuerpo = CFrame.Angles(0.55 * q, 0, 0)
			inclina = 0.55 * q
			alto = 1.4 * q
			cuello = -0.3 * q
			boca = 0.8 * q
			abrirBranquias = 0.6 * q
		end
	elseif nombre == "panzazo" then
		-- se levanta en las patas de atrás y se deja caer de panza
		local f, k = fase(modelo, t)
		local q = f == "prep" and suave(k) or (f == "act" and 1 - suave(k) or 0)
		cuerpo = CFrame.Angles(0.5 * q, 0, 0)
		inclina = 0.5 * q
		alto = 0.6 * q
		boca = 0.4 * q
		abrirBranquias = 0.5 * q
		if f == "rec" then
			cuerpo = CFrame.Angles(-0.08 * (1 - suave(k)), 0, 0)
			alto = -0.3 * (1 - suave(k))
		end
	elseif nombre == "estremecer" then
		local q = math.max(0, 1 - t / 1.4)
		cuerpo = CFrame.Angles(0, 0, math.sin(t * 22) * 0.08 * q)
		boca = 0.5 * q
		abrirBranquias = -0.3 * q
	elseif nombre == "derribado" or nombre == "muerte" then
		-- se voltea de lado, con la panza al aire
		local k = suave(t / 0.7)
		cuerpo = CFrame.Angles(0, 0, 1.35 * k)
		alto = 0.3 * k
		boca = nombre == "muerte" and 0.5 * k or 0.25 + math.sin(reloj * 3) * 0.1
		abrirBranquias = -0.4 * k
		colaOnda = nombre == "derribado" and 0.3 or 0
		ampPaso = nombre == "derribado" and 0.6 or 0
		fasePaso = reloj * 7
	elseif nombre == "levantarse" then
		local q = 1 - suave(t / 1.4)
		cuerpo = CFrame.Angles(0, 0, 1.35 * q)
		alto = 0.3 * q
	end
	girar(motores.RaizCuerpo, cuerpo, v(0, alto * S, -adelante * S))
	girar(motores.Cuello, CFrame.Angles(cuello, giroCuello, 0))
	girar(motores.Mandibula, CFrame.Angles(-boca * 0.75, 0, 0))
	-- branquias: se abren hacia afuera y aletean
	for _, L in LADOS do
		local lado = L == "I" and -1 or 1
		local nombres = BRANQUIA[L]
		for k = 1, 3 do
			local aleteoK = aleteo * math.sin(reloj * 6 + k * 1.3)
			girar(motores[nombres[k]], CFrame.Angles(aleteoK, 0, -lado * (abrirBranquias * 0.6 + aleteoK)))
		end
	end
	-- patas: van en diagonal (como una salamandra)
	for _, x in PATAS4 do
		local s1 = math.sin(fasePaso + x[2])
		local lado = x[3]
		girar(motores[x[1]], CFrame.Angles(0, -lado * s1 * ampPaso * 0.8, -lado * math.max(0, math.cos(fasePaso + x[2])) * ampPaso * 0.5))
	end
	-- la cola ondula (cada segmento un poco más tarde) y puede latiguear hacia un lado
	for i = 1, 4 do
		girar(motores[COLA[i]], CFrame.Angles(i == 1 and -inclina * 0.9 or 0, math.sin(reloj * 2.2 + fasePaso - i * 0.8) * colaOnda * (0.5 + i * 0.2) + colaLado * (i == 1 and 0.6 or 0.35), 0))
	end
end

-- ---------- Balam ----------
local camuflados = setmetatable({}, { __mode = "k" })
-- el camuflaje de jade: el pelaje casi desaparece y solo se ven las manchas que brillan
local function camuflar(modelo: Model, activo: boolean)
	if (camuflados[modelo] or false) == activo then
		return
	end
	camuflados[modelo] = activo
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = activo and (p.Material == Enum.Material.Neon and 0.15 or 0.78) or 0
		end
	end
end

local function animarBalam(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre, t = estado(modelo, ahora)
	camuflar(modelo, modelo:GetAttribute("Camuflaje") == true)
	local respira = math.sin(reloj * 1.8)
	local cuerpo = CFrame.Angles(respira * 0.015, 0, 0)
	local alto, adelante = respira * 0.05, 0
	local cuello, giroCuello, boca = 0, math.sin(reloj * 0.7) * 0.2, 0.03
	local hombro = { I = 0, D = 0 }
	local codo = { I = 0, D = 0 }
	local cadera = { I = 0, D = 0 }
	local rodilla = { I = 0, D = 0 }
	local colaArriba, colaLado = 0.1 + math.sin(reloj * 1.1) * 0.05, math.sin(reloj * 0.9) * 0.25
	local function andar(vel, amp, galope)
		local f = t * vel
		local a, b = math.sin(f), math.sin(f + math.pi)
		if galope then
			-- galope: las dos de adelante juntas y las de atrás juntas, con el lomo que se dobla
			hombro.I, hombro.D = a * amp, a * amp * 0.85
			cadera.I, cadera.D = -a * amp, -a * amp * 0.85
			cuerpo = cuerpo * CFrame.Angles(math.cos(f) * 0.08, 0, 0)
			alto += math.abs(math.cos(f)) * 0.35
		else
			hombro.I, hombro.D = a * amp, b * amp
			cadera.I, cadera.D = b * amp * 0.8, a * amp * 0.8
			alto += math.abs(math.sin(f)) * 0.1
		end
		codo.I, codo.D = -math.max(0, -hombro.I) * 0.9, -math.max(0, -hombro.D) * 0.9
		rodilla.I, rodilla.D = math.max(0, cadera.I) * 0.8, math.max(0, cadera.D) * 0.8
		colaLado = math.sin(f * 0.5) * 0.15
		giroCuello = 0
	end
	if nombre == "caminar" then
		andar(4.4, 0.4)
	elseif nombre == "correr" then
		andar(9, 0.75, true)
		cuello = -0.1
		colaArriba = -0.05
	elseif nombre == "rugir" or nombre == "rugido" then
		local k = suave(t / 0.4)
		if nombre == "rugido" then
			local f, q = fase(modelo, t)
			k = f == "prep" and suave(q) or (f == "act" and 1 or 1 - suave(q))
		end
		cuerpo = CFrame.Angles(0.18 * k, 0, math.sin(reloj * 30) * 0.015 * k)
		alto = 0.3 * k
		cuello = 0.35 * k
		boca = 0.85 * k
		hombro.I, hombro.D = 0.35 * k, 0.35 * k
		cadera.I, cadera.D = -0.2 * k, -0.2 * k
		colaArriba = 0.4 * k
	elseif nombre == "zarpazo" then
		local f, k = fase(modelo, t)
		local sube, baja = 0, 0
		if f == "prep" then
			sube = suave(k)
		elseif f == "act" then
			sube, baja = 1 - suave(k), suave(k)
		else
			baja = 1 - suave(k)
		end
		cuerpo = CFrame.Angles(0.22 * sube - 0.12 * baja, 0.2 * sube - 0.15 * baja, 0)
		alto = 0.4 * sube
		hombro.D = 1.5 * sube - 0.2 * baja
		codo.D = -0.6 * sube
		hombro.I = 0.2 * sube
		cadera.I, cadera.D = -0.3 * sube, -0.3 * sube
		boca = 0.4 * sube
		cuello = 0.15 * sube - 0.1 * baja
		adelante = 0.8 * baja
	elseif nombre == "mordida" then
		local f, k = fase(modelo, t)
		local atras, lanza = 0, 0
		if f == "prep" then
			atras = suave(k)
		elseif f == "act" then
			atras, lanza = 1 - suave(k * 2), suave(k * 2)
		else
			lanza = 1 - suave(k)
		end
		cuerpo = CFrame.Angles(0.1 * atras - 0.15 * lanza, 0, 0)
		adelante = -0.5 * atras + 1.8 * lanza
		alto = -0.3 * lanza
		cuello = 0.25 * atras - 0.2 * lanza
		boca = f == "act" and (k < 0.5 and 0.9 or 0.05) or 0.8 * atras
		hombro.I, hombro.D = 0.4 * lanza, 0.4 * lanza
		cadera.I, cadera.D = -0.4 * lanza, -0.4 * lanza
	elseif nombre == "salto" then
		local f, k = fase(modelo, t)
		if f == "prep" then
			-- se agacha, listo para saltar
			local q = suave(k)
			alto = -0.8 * q
			cuerpo = CFrame.Angles(-0.1 * q, 0, 0)
			cadera.I, cadera.D = 0.5 * q, 0.5 * q
			rodilla.I, rodilla.D = 0.6 * q, 0.6 * q
			codo.I, codo.D = -0.5 * q, -0.5 * q
			colaLado = math.sin(reloj * 14) * 0.25 -- mueve la punta de la cola
		elseif f == "act" then
			-- en el aire, estirado
			cuerpo = CFrame.Angles(0.15 - k * 0.35, 0, 0)
			hombro.I, hombro.D = 1.1, 1.1
			cadera.I, cadera.D = -0.9, -0.9
			boca = 0.8
			cuello = 0.1
			colaArriba = -0.2
		else
			local q = 1 - suave(k)
			alto = -0.6 * q
			cuerpo = CFrame.Angles(-0.12 * q, 0, 0)
			codo.I, codo.D = -0.6 * q, -0.6 * q
			boca = 0.4 * q
		end
	elseif nombre == "zigzag" then
		local f, k = fase(modelo, t)
		if f == "act" then
			andar(11, 0.8, true)
			local tramo = math.floor(k * 3)
			cuerpo = cuerpo * CFrame.Angles(0, 0, (tramo % 2 == 0 and 1 or -1) * 0.2)
			alto -= 0.3
			boca = 0.5
		elseif f == "prep" then
			local q = suave(k)
			alto = -0.5 * q
			cuello = -0.15 * q
			cadera.I, cadera.D = 0.4 * q, 0.4 * q
			rodilla.I, rodilla.D = 0.4 * q, 0.4 * q
		end
	elseif nombre == "coletazo" then
		local f, k = fase(modelo, t)
		local carga, latigo = 0, 0
		if f == "prep" then
			carga = suave(k)
		elseif f == "act" then
			carga, latigo = 1 - suave(k), suave(k)
		else
			latigo = 1 - suave(k)
		end
		cuerpo = CFrame.Angles(0, 0.4 * carga - 0.8 * latigo, 0)
		colaLado = -0.6 * carga + 1.1 * latigo
		colaArriba = 0.3 * carga
		giroCuello = -0.3 * carga
	elseif nombre == "estremecer" then
		local q = math.max(0, 1 - t / 1.4)
		cuerpo = CFrame.Angles(0, 0, math.sin(t * 22) * 0.07 * q)
		boca = 0.5 * q
		cuello = -0.2 * q
	elseif nombre == "derribado" or nombre == "muerte" then
		local k = suave(t / 0.6)
		cuerpo = CFrame.Angles(0, 0, 1.4 * k)
		alto = -1.0 * k
		hombro.I, hombro.D = 0.5 * k, 0.3 * k
		cadera.I, cadera.D = -0.4 * k, -0.2 * k
		boca = nombre == "muerte" and 0.6 * k or 0.3 + math.sin(reloj * 3) * 0.1
		if nombre == "derribado" then
			hombro.I += math.sin(reloj * 8) * 0.3 * k
			cadera.D += math.sin(reloj * 7) * 0.3 * k
		end
		colaArriba = -0.3 * k
	elseif nombre == "levantarse" then
		local q = 1 - suave(t / 1.4)
		cuerpo = CFrame.Angles(0, 0, 1.4 * q)
		alto = -1.0 * q
	end
	girar(motores.RaizCuerpo, cuerpo, v(0, alto * S, -adelante * S))
	girar(motores.Cuello, CFrame.Angles(cuello, giroCuello, 0))
	girar(motores.Mandibula, CFrame.Angles(-boca * 0.7, 0, 0))
	for _, L in LADOS do
		local n = MIEMBRO[L]
		girar(motores[n.hombro], CFrame.Angles(hombro[L], 0, 0))
		girar(motores[n.codo], CFrame.Angles(codo[L], 0, 0))
		girar(motores[n.cadera], CFrame.Angles(cadera[L], 0, 0))
		girar(motores[n.rodilla], CFrame.Angles(rodilla[L], 0, 0))
	end
	for i = 1, 5 do
		girar(motores[COLA[i]], CFrame.Angles(i == 1 and colaArriba or colaArriba * 0.3, colaLado * (0.4 + i * 0.12) + math.sin(reloj * 2 - i * 0.6) * 0.06, 0))
	end
end

-- ---------- Cipactli ----------
local function animarCipactli(modelo: Model, ahora: number, reloj: number)
	local motores = motoresDe(modelo)
	local nombre, t = estado(modelo, ahora)
	local respira = math.sin(reloj * 1.1)
	local cuerpo = CFrame.Angles(respira * 0.01, 0, 0)
	local alto, adelante = respira * 0.04, 0
	local cuello, giroCuello = 0, math.sin(reloj * 0.4) * 0.12
	local boca = 0.05 + math.max(0, math.sin(reloj * 0.35)) * 0.25 -- abre las fauces de vez en cuando, como los caimanes
	local colaLado, colaOnda = 0, 0.08
	local fasePaso, ampPaso = reloj, 0
	local inclina = 0
	local function andar(vel, amp)
		fasePaso, ampPaso = t * vel, amp
		cuerpo = cuerpo * CFrame.Angles(0, math.sin(fasePaso) * amp * 0.25, 0)
		colaOnda = amp * 0.7
		giroCuello = -math.sin(fasePaso) * amp * 0.2
		alto += 0.25 + math.abs(math.sin(fasePaso)) * 0.06 -- camina levantando la panza
		boca = 0.05
	end
	if nombre == "caminar" then
		andar(3.8, 0.45)
	elseif nombre == "correr" then
		andar(7, 0.65)
	elseif nombre == "rugir" or nombre == "geiseres" then
		-- levanta la cabeza con las fauces abiertas y el cuerpo tiembla
		local k = suave(t / 0.5)
		if nombre == "geiseres" then
			local f, q = fase(modelo, t)
			k = f == "prep" and suave(q * 1.5) or (f == "act" and 1 or 1 - suave(q))
		end
		cuerpo = CFrame.Angles(0.2 * k, 0, math.sin(reloj * 28) * 0.02 * k)
		inclina = 0.2 * k
		alto = 0.4 * k
		cuello = 0.3 * k
		boca = 0.9 * k
	elseif nombre == "embestida" then
		local f, k = fase(modelo, t)
		if f == "prep" then
			local q = suave(k)
			cuerpo = CFrame.Angles(-0.05 * q, 0, 0)
			adelante = -0.6 * q
			boca = 0.9 * q
			cuello = 0.15 * q
			colaLado = math.sin(reloj * 10) * 0.3 * q
		elseif f == "act" then
			adelante = 0.6
			alto = 0.3
			boca = k < 0.7 and 1 or 0.05
			ampPaso, fasePaso = 0.7, t * 14
		else
			boca = 0.05
			adelante = 0.6 * (1 - suave(k))
		end
	elseif nombre == "giro" then
		-- el giro de la muerte: rueda sobre sí mismo
		local f, k = fase(modelo, t)
		if f == "prep" then
			local q = suave(k)
			cuerpo = CFrame.Angles(0, 0, -0.35 * q)
			boca = 0.8 * q
			colaLado = -0.5 * q
		elseif f == "act" then
			cuerpo = CFrame.Angles(0, 0, -0.35 - k * math.pi * 4)
			alto = 0.5
			boca = 0.05
			colaOnda = 0
		else
			cuerpo = CFrame.Angles(0, 0, math.sin(t * 12) * 0.1 * (1 - k))
			giroCuello = math.sin(t * 6) * 0.25 * (1 - k) -- queda mareado
		end
	elseif nombre == "coletazo" then
		local f, k = fase(modelo, t)
		local carga, latigo = 0, 0
		if f == "prep" then
			carga = suave(k)
		elseif f == "act" then
			carga, latigo = 1 - suave(k), suave(k)
		else
			latigo = 1 - suave(k)
		end
		cuerpo = CFrame.Angles(0, 0.45 * carga - 0.8 * latigo, 0)
		colaLado = -0.4 * carga + 0.75 * latigo
		colaOnda = 0.03
		giroCuello = -0.25 * carga + 0.3 * latigo
	elseif nombre == "emboscada" then
		local f, k = fase(modelo, t)
		if f == "prep" then
			cuerpo = CFrame.Angles(-0.25 * suave(k), 0, 0)
		elseif f == "act" then
			cuerpo = CFrame.Angles(-0.25, 0, 0)
			andar(8, 0.7)
		else
			-- sale del barro con las fauces abiertas
			local q = 1 - suave(k)
			cuerpo = CFrame.Angles(0.5 * q, 0, 0)
			inclina = 0.5 * q
			alto = 1.0 * q
			boca = 1.0 * q
			cuello = 0.2 * q
		end
	elseif nombre == "fauces" then
		local f, k = fase(modelo, t)
		local q = f == "prep" and suave(k) or (f == "act" and 1 or 1 - suave(k))
		cuerpo = CFrame.Angles(0, 0, math.sin(reloj * 30) * 0.03 * q)
		alto = 0.3 * q
		ampPaso, fasePaso = 0.4 * q, 1.5 -- las patas se abren
		boca = 0.5 * q
	elseif nombre == "estremecer" then
		local q = math.max(0, 1 - t / 1.4)
		cuerpo = CFrame.Angles(0, 0, math.sin(t * 22) * 0.06 * q)
		boca = 0.6 * q
	elseif nombre == "derribado" or nombre == "muerte" then
		-- panza arriba
		local k = suave(t / 0.8)
		cuerpo = CFrame.Angles(0, 0, math.pi * 0.92 * k)
		alto = 0.2 * k
		boca = nombre == "muerte" and 0.6 * k or 0.3 + math.sin(reloj * 2.5) * 0.15
		if nombre == "derribado" then
			ampPaso, fasePaso = 0.5, reloj * 6
			colaOnda = 0.25
		end
	elseif nombre == "levantarse" then
		local q = 1 - suave(t / 1.4)
		cuerpo = CFrame.Angles(0, 0, math.pi * 0.92 * q)
		alto = 0.2 * q
	end
	girar(motores.RaizCuerpo, cuerpo, v(0, alto * S, -adelante * S))
	girar(motores.Cuello, CFrame.Angles(cuello, giroCuello, 0))
	girar(motores.Mandibula, CFrame.Angles(-boca * 0.6, 0, 0))
	for _, x in PATAS4 do
		local s1 = math.sin(fasePaso + x[2])
		local lado = x[3]
		girar(motores[x[1]], CFrame.Angles(0, -lado * s1 * ampPaso * 0.7, -lado * math.max(0, math.cos(fasePaso + x[2])) * ampPaso * 0.45))
	end
	for i = 1, 5 do
		girar(motores[COLA[i]], CFrame.Angles(i == 1 and -inclina * 0.9 or 0, math.sin(reloj * 1.8 + fasePaso - i * 0.7) * colaOnda * (0.4 + i * 0.15) + colaLado * (i == 1 and 0.5 or 0.3), 0))
	end
end

-- ---------- quién anima a quién ----------
AnimSelva.animadores = {
	Camazotz = animarCamazotz,
	Xolotl = animarXolotl,
	Balam = animarBalam,
	Cipactli = animarCipactli,
}

-- ¿vale la pena animarlo? (en Studio están todas las islas; solo se anima la de la jugadora)
function AnimSelva.visible(modelo: Model): boolean
	local jugador = game:GetService("Players").LocalPlayer
	local zona = jugador and jugador:GetAttribute("Zona")
	return zona == nil or modelo:GetAttribute("Mapa") == zona
end

function AnimSelva.animar(modelo: Model, ahora: number, reloj: number)
	local f = AnimSelva.animadores[modelo:GetAttribute("Nombre")]
	if f then
		f(modelo, ahora, reloj)
	end
end

-- murciélagos del enjambre: el servidor los mueve, aquí no hace falta nada más
return AnimSelva
