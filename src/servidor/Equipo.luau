--!nonstrict
-- Viste a cada avatar con el atuendo nómada inicial y le pone el arma en las manos.
-- Funciona con avatares R15 y R6.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)
local Armas = require(ReplicatedStorage.Compartido.Armas)
local ArteArmas = require(ReplicatedStorage.Compartido.ArteArmas)

local C = Config.COLORES
local Equipo = {}

local function pieza(padre: Instance, props: { [string]: any }): BasePart
	local p = Instance.new(props.Clase or "Part")
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material == Enum.Material.Neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.Name = props.Name or "Pieza"
	p.Size = props.Size
	p.Color = props.Color or C.lino
	-- estilo voxel: todas las piezas son bloques
	p.Parent = padre
	return p
end

local function soldar(p: BasePart, a: BasePart, cf: CFrame)
	local w = Instance.new("Weld")
	w.Part0 = a
	w.Part1 = p
	w.C0 = cf
	w.Parent = p
	p.CFrame = a.CFrame * cf
end

local function parteDelCuerpo(char: Model, r15: string, r6: string): BasePart?
	local p = char:FindFirstChild(r15) or char:FindFirstChild(r6)
	return if p and p:IsA("BasePart") then p else nil
end

-- ---------- partículas de las armas forjadas ----------
-- donde: "punta" (la pieza más alejada de la mano) o "medio"; subida: aceleración vertical.
local PARTICULAS = {
	colmillo = { { "medio", Color3.fromRGB(236, 206, 150), 6, 0.18, -6, 0.9 } },
	esfinge = { { "punta", Color3.fromRGB(214, 180, 120), 5, 0.3, -3, 1.2 } },
	remolino = { { "punta", Color3.fromRGB(236, 206, 150), 8, 0.15, 3, 0.8, true } },
	serket = { { "punta", Color3.fromRGB(120, 230, 110), 5, 0.14, -10, 0.8 } },
	sol_dorado = { { "punta", Color3.fromRGB(255, 214, 120), 10, 0.12, 4, 0.5 } },
	mandibula = { { "medio", Color3.fromRGB(255, 150, 60), 4, 0.14, 6, 0.9, false, "Brasas" } },
	sol_rodante = { { "punta", Color3.fromRGB(140, 128, 120), 6, 0.45, 4, 1.4 }, { "punta", Color3.fromRGB(255, 150, 60), 5, 0.12, 6, 0.7 } },
	pinzas = { { "punta", Color3.fromRGB(255, 190, 90), 7, 0.1, 5, 0.5 } },
	hercules = { { "punta", Color3.fromRGB(255, 150, 60), 7, 0.13, 6, 0.8 } },
	brasa = { { "punta", Color3.fromRGB(140, 128, 120), 6, 0.3, 4, 1.0 } },
	filo_eclipse = { { "medio", Color3.fromRGB(120, 50, 190), 6, 0.2, 3, 0.9 } },
	martillo_uku = { { "punta", Color3.fromRGB(60, 30, 90), 6, 0.45, 3, 1.3 } },
	alas_amaru = { { "punta", Color3.fromRGB(160, 76, 224), 6, 0.14, -2, 0.8 } },
	lanza_uku = { { "punta", Color3.fromRGB(190, 110, 255), 7, 0.13, 3, 0.8 } },
	blasteres_eclipse = { { "punta", Color3.fromRGB(60, 30, 90), 6, 0.3, 3, 1.0 } },
	filo_inti = { { "medio", Color3.fromRGB(255, 230, 150), 7, 0.15, 3, 0.8 } },
	puno_apu = { { "punta", Color3.fromRGB(150, 144, 136), 5, 0.35, -6, 1.0 } },
	hoces_granito = { { "punta", Color3.fromRGB(160, 154, 146), 6, 0.14, -5, 0.7 } },
	lanza_sol = { { "punta", Color3.fromRGB(255, 214, 90), 8, 0.14, 4, 0.8 } },
	blasteres_inti = { { "punta", Color3.fromRGB(255, 220, 120), 9, 0.12, 4, 0.5 } },
	-- Camazotz: chispas de jade y gotas rojo sangre
	colmillo_xib = { { "medio", Color3.fromRGB(70, 236, 204), 6, 0.16, 2, 0.8 }, { "medio", Color3.fromRGB(200, 30, 70), 3, 0.12, -8, 0.7 } },
	tambor_cam = { { "punta", Color3.fromRGB(120, 60, 160), 6, 0.4, 2, 1.1 } },
	alas_obs = { { "punta", Color3.fromRGB(70, 236, 204), 7, 0.12, -2, 0.7 } },
	aguijon_inf = { { "punta", Color3.fromRGB(200, 30, 70), 6, 0.12, -6, 0.8 } },
	blasteres_eco = { { "punta", Color3.fromRGB(110, 255, 226), 8, 0.12, 3, 0.5 } },
	garras_cam = { { "punta", Color3.fromRGB(200, 30, 70), 5, 0.12, -6, 0.7 } },
	-- Xolotl: chispas de rayo
	macuahuitl = { { "medio", Color3.fromRGB(255, 236, 90), 7, 0.14, 4, 0.5 } },
	mazo_tlaloc = { { "punta", Color3.fromRGB(110, 200, 255), 6, 0.3, -4, 0.9 } },
	branquias_ajo = { { "punta", Color3.fromRGB(255, 110, 160), 6, 0.14, 2, 0.7 } },
	atlatl = { { "punta", Color3.fromRGB(255, 236, 90), 8, 0.12, 4, 0.5 } },
	blasteres_cenote = { { "punta", Color3.fromRGB(255, 236, 90), 9, 0.12, 4, 0.4 } },
	punos_tormenta = { { "punta", Color3.fromRGB(255, 236, 90), 6, 0.12, 4, 0.4 } },
	-- Balam: jade y polvo de obsidiana
	filo_obs = { { "medio", Color3.fromRGB(170, 110, 255), 6, 0.14, -3, 0.7 } },
	mazo_jaguar = { { "punta", Color3.fromRGB(30, 24, 40), 6, 0.35, -3, 1.0 } },
	garras_balam = { { "punta", Color3.fromRGB(40, 230, 150), 7, 0.12, 2, 0.6 } },
	lanza_nocturna = { { "punta", Color3.fromRGB(170, 110, 255), 7, 0.12, 2, 0.7 } },
	blasteres_jade = { { "punta", Color3.fromRGB(40, 230, 150), 8, 0.12, 3, 0.5 } },
	zarpas_obs = { { "punta", Color3.fromRGB(170, 110, 255), 5, 0.12, -4, 0.6 } },
	-- Cipactli: burbujas del abismo
	diente_cip = { { "medio", Color3.fromRGB(40, 230, 190), 6, 0.16, 3, 0.8 } },
	mazo_pantano = { { "punta", Color3.fromRGB(96, 76, 52), 6, 0.4, -4, 1.0 } },
	hoces_creacion = { { "punta", Color3.fromRGB(110, 200, 210), 7, 0.14, 2, 0.7 } },
	arpon_abismo = { { "punta", Color3.fromRGB(40, 230, 190), 6, 0.14, 3, 0.8 } },
	blasteres_abismo = { { "punta", Color3.fromRGB(40, 230, 190), 8, 0.14, 3, 0.5 } },
	fauces_cip = { { "punta", Color3.fromRGB(255, 120, 60), 5, 0.12, 3, 0.6 } },
}

local function emisor(parte: BasePart, c): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = c[8] or "Particulas"
	e.Color = ColorSequence.new(c[2])
	e.LightEmission = 0.4
	e.Rate = c[3]
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, c[4]), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(c[6] * 0.6, c[6])
	e.Speed = NumberRange.new(0.3, 1.2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, c[5], 0)
	e.RotSpeed = NumberRange.new(-120, 120)
	if c[7] then
		e.VelocityInheritance = 0
		e.Speed = NumberRange.new(2, 3)
		e.SpreadAngle = Vector2.new(20, 180)
	end
	e.Parent = parte
	return e
end

-- ---------- Set del Guardián de las Dunas ----------
-- Cada pieza se pone sobre el cuerpo de bloques. Sin armadura, el cazador lleva su ropa.
local AZUL = Color3.fromRGB(40, 70, 150)
local ARENA_ORO = Color3.fromRGB(214, 176, 110)

function Equipo.vestir(char: Model, equipo: { string })
	local viejo = char:FindFirstChild("Atuendo")
	if viejo then
		viejo:Destroy()
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Atuendo"
	carpeta.Parent = char
	local lleva = {}
	for _, pieza in equipo do
		lleva[pieza] = true
	end
	local cabeza = char:FindFirstChild("Head") :: BasePart
	local torso = char:FindFirstChild("Torso") :: BasePart
	-- la armadura se ve en minivoxel: la construye cada jugador (cliente > ArmadurasPixel);
	-- aquí solo quedan los efectos, los atributos y la coraza del Caparazón Solar
	local function bloque(parte: BasePart?, tam: Vector3, pos: Vector3, color: Color3, brilla: boolean?)
		if true then
			return
		end
		if not parte then
			return
		end
		local p = pieza(carpeta, { Size = tam, Color = color, Material = brilla and Enum.Material.Neon or nil })
		soldar(p, parte, CFrame.new(pos))
	end
	-- el pelo se esconde bajo la capucha
	local apariencia = char:FindFirstChild("Apariencia")
	if apariencia then
		for _, x in apariencia:GetChildren() do
			if x:GetAttribute("Pelo") then
				x.Transparency = (lleva.capucha or lleva.yelmo or lleva.mascara or lleva.yelmo_xib or lleva.yelmo_jag or lleva.fauces_casco or lleva.penacho_tla) and 1 or 0 -- la corona deja ver el pelo
			end
		end
	end
	if lleva.capucha and cabeza then
		local h = cabeza.Size.Y
		bloque(cabeza, Vector3.new(h * 1.14, 0.45, h * 1.14), Vector3.new(0, h / 2 + 0.1, 0.02), C.oro)
		bloque(cabeza, Vector3.new(h * 1.14, h * 0.9, 0.22), Vector3.new(0, h * 0.05, h / 2 + 0.1), AZUL)
		for _, lado in { -1, 1 } do
			for k = 0, 3 do
				bloque(cabeza, Vector3.new(0.2, 0.32, h * 0.9), Vector3.new(lado * (h / 2 + 0.1), h * 0.3 - k * 0.34, 0.08), k % 2 == 0 and AZUL or C.oro)
			end
		end
		bloque(cabeza, Vector3.new(h * 1.1, 0.24, 0.14), Vector3.new(0, h * 0.38, -h / 2 - 0.06), C.oro)
		bloque(cabeza, Vector3.new(0.22, 0.4, 0.16), Vector3.new(0, h / 2 + 0.15, -h / 2 - 0.1), C.oro)
		bloque(cabeza, Vector3.new(0.16, 0.16, 0.16), Vector3.new(0, h / 2 + 0.32, -h / 2 - 0.14), C.turquesa, true)
	end
	if lleva.coraza and torso then
		bloque(torso, Vector3.new(2.14, 1.3, 1.14), Vector3.new(0, 0.3, 0), ARENA_ORO)
		bloque(torso, Vector3.new(2.2, 0.28, 1.18), Vector3.new(0, 0.98, 0), C.oro)
		bloque(torso, Vector3.new(2.16, 0.22, 1.16), Vector3.new(0, -0.42, 0), C.oro)
		for _, glifo in { { -0.5, 0.45, 0.3, 0.3 }, { 0, 0.3, 0.2, 0.5 }, { 0.5, 0.45, 0.3, 0.3 }, { -0.25, 0.0, 0.3, 0.15 }, { 0.25, 0.0, 0.3, 0.15 } } do
			bloque(torso, Vector3.new(glifo[3], glifo[4], 0.06), Vector3.new(glifo[1], glifo[2], -0.6), C.turquesa, true)
		end
		for _, n in { "Right Arm", "Left Arm" } do
			bloque(char:FindFirstChild(n) :: BasePart, Vector3.new(1.2, 0.45, 1.2), Vector3.new(0, 0.85, 0), C.oro)
			bloque(char:FindFirstChild(n) :: BasePart, Vector3.new(1.14, 0.3, 1.14), Vector3.new(0, 0.5, 0), ARENA_ORO)
		end
	end
	if lleva.garras then
		for _, n in { "Right Arm", "Left Arm" } do
			local brazo = char:FindFirstChild(n) :: BasePart
			bloque(brazo, Vector3.new(1.12, 0.8, 1.12), Vector3.new(0, -0.45, 0), ARENA_ORO)
			bloque(brazo, Vector3.new(1.16, 0.18, 1.16), Vector3.new(0, -0.05, 0), Color3.fromRGB(255, 176, 60), true)
			for u = -1, 1 do
				bloque(brazo, Vector3.new(0.18, 0.4, 0.18), Vector3.new(u * 0.32, -1.1, -0.35), Color3.fromRGB(245, 235, 210))
			end
		end
	end
	if lleva.grebas then
		for _, n in { "Right Leg", "Left Leg" } do
			local pierna = char:FindFirstChild(n) :: BasePart
			bloque(pierna, Vector3.new(1.12, 1.0, 1.12), Vector3.new(0, -0.5, 0), ARENA_ORO)
			bloque(pierna, Vector3.new(0.5, 0.4, 0.2), Vector3.new(0, 0.05, -0.58), C.oro)
			bloque(pierna, Vector3.new(0.16, 0.8, 0.06), Vector3.new(0, -0.55, -0.58), C.turquesa, true)
			bloque(pierna, Vector3.new(1.16, 0.25, 1.3), Vector3.new(0, -0.9, -0.08), Color3.fromRGB(110, 70, 40))
		end
	end
	-- ---------- Set del Rodador Solar ----------
	local QUITINA = Color3.fromRGB(46, 32, 22)
	local BRASA = Color3.fromRGB(255, 138, 58)
	if lleva.yelmo and cabeza then
		local h = cabeza.Size.Y
		bloque(cabeza, Vector3.new(h * 1.14, h * 0.62, h * 1.14), Vector3.new(0, h * 0.28, 0.02), QUITINA)
		bloque(cabeza, Vector3.new(h * 1.14, h * 0.5, 0.2), Vector3.new(0, -h * 0.05, h / 2 + 0.1), QUITINA)
		bloque(cabeza, Vector3.new(h * 0.85, 0.14, 0.08), Vector3.new(0, h * 0.08, -h / 2 - 0.05), C.turquesa, true)
		bloque(cabeza, Vector3.new(h * 1.16, 0.16, h * 1.16), Vector3.new(0, h * 0.02, 0.02), C.oro)
		for i, c in { { 0.32, 0.5, 0.35, -0.3 }, { 0.28, 0.45, 0.75, -0.45 }, { 0.24, 0.35, 1.05, -0.7 } } do
			bloque(cabeza, Vector3.new(c[1], c[2], c[1]), Vector3.new(0, h / 2 + c[3], c[4]), i == 3 and QUITINA or QUITINA)
		end
		bloque(cabeza, Vector3.new(0.2, 0.2, 0.2), Vector3.new(0, h / 2 + 1.2, -0.95), C.oro)
		for _, lado in { -1, 1 } do
			bloque(cabeza, Vector3.new(0.2, 0.36, 0.2), Vector3.new(lado * h * 0.58, h * 0.5, 0), QUITINA)
		end
	end
	if lleva.caparazon and torso then
		bloque(torso, Vector3.new(2.14, 1.5, 1.14), Vector3.new(0, 0.25, 0), QUITINA)
		bloque(torso, Vector3.new(0.12, 1.45, 0.06), Vector3.new(0, 0.25, -0.6), C.turquesa, true)
		for _, lado in { -1, 1 } do
			bloque(torso, Vector3.new(0.34, 0.34, 0.06), Vector3.new(lado * 0.5, 0.55, -0.6), C.oro)
			bloque(torso, Vector3.new(0.95, 2.0, 0.35), Vector3.new(lado * 0.5, -0.1, 0.72), QUITINA)
			bloque(torso, Vector3.new(0.1, 1.6, 0.05), Vector3.new(lado * 0.5, -0.1, 0.92), C.turquesa, true)
		end
		for _, n in { "Right Arm", "Left Arm" } do
			local brazo = char:FindFirstChild(n) :: BasePart
			bloque(brazo, Vector3.new(1.22, 0.5, 1.22), Vector3.new(0, 0.82, 0), QUITINA)
			bloque(brazo, Vector3.new(0.24, 0.36, 0.24), Vector3.new(0, 1.2, 0), QUITINA)
		end
	end
	if lleva.guanteletes then
		for _, n in { "Right Arm", "Left Arm" } do
			local brazo = char:FindFirstChild(n) :: BasePart
			bloque(brazo, Vector3.new(1.12, 0.85, 1.12), Vector3.new(0, -0.45, 0), QUITINA)
			bloque(brazo, Vector3.new(1.16, 0.16, 1.16), Vector3.new(0, -0.05, 0), C.oro)
			for u = -1, 1 do
				bloque(brazo, Vector3.new(0.2, 0.2, 0.12), Vector3.new(u * 0.3, -0.9, -0.55), BRASA, true)
			end
		end
	end
	if lleva.grebas_escarabajo then
		for _, n in { "Right Leg", "Left Leg" } do
			local pierna = char:FindFirstChild(n) :: BasePart
			for k = 0, 2 do
				bloque(pierna, Vector3.new(1.12, 0.3, 1.12), Vector3.new(0, -0.2 - k * 0.32, 0), k % 2 == 0 and QUITINA or Color3.fromRGB(90, 58, 34))
			end
			bloque(pierna, Vector3.new(0.45, 0.35, 0.2), Vector3.new(0, 0.1, -0.58), C.oro)
			bloque(pierna, Vector3.new(0.12, 0.8, 0.06), Vector3.new(0, -0.5, -0.58), C.turquesa, true)
		end
	end
	-- ---------- Set del Eclipse ----------
	local NOCHE = Color3.fromRGB(34, 22, 50)
	local MORADO = Color3.fromRGB(160, 76, 224)
	local PLATA = Color3.fromRGB(201, 198, 214)
	if lleva.mascara and cabeza then
		local h = cabeza.Size.Y
		bloque(cabeza, Vector3.new(h * 1.12, h * 1.02, h * 1.12), Vector3.new(0, 0.02, 0.02), NOCHE)
		for _, lado in { -1, 1 } do
			bloque(cabeza, Vector3.new(0.3, 0.1, 0.06), Vector3.new(lado * 0.28, 0.12, -h / 2 - 0.08), Color3.new(1, 1, 1), true)
			bloque(cabeza, Vector3.new(0.18, 0.5, 0.18), Vector3.new(lado * 0.42, h / 2 + 0.25, -0.1), PLATA)
			bloque(cabeza, Vector3.new(0.14, 0.3, 0.14), Vector3.new(lado * 0.52, h / 2 + 0.55, -0.25), PLATA)
		end
		for k = 0, 3 do
			bloque(cabeza, Vector3.new(0.18, 0.5 + (k % 2) * 0.2, 0.3), Vector3.new(0, h / 2 + 0.3, 0.05 + k * 0.25), k % 2 == 0 and MORADO or Color3.fromRGB(200, 120, 255), true)
		end
	end
	if lleva.manto and torso then
		bloque(torso, Vector3.new(2.14, 1.6, 1.14), Vector3.new(0, 0.2, 0), NOCHE)
		for fila = 0, 2 do
			for k = -2, 2 do
				bloque(torso, Vector3.new(0.4, 0.5, 0.12), Vector3.new(k * 0.42, 0.7 - fila * 0.55, 0.62), (k + fila) % 2 == 0 and NOCHE or Color3.fromRGB(56, 36, 80))
				bloque(torso, Vector3.new(0.3, 0.12, 0.13), Vector3.new(k * 0.42, 0.47 - fila * 0.55, 0.63), MORADO, true)
			end
		end
		bloque(torso, Vector3.new(0.4, 0.4, 0.06), Vector3.new(0, 0.55, -0.6), PLATA)
		for _, n in { "Right Arm", "Left Arm" } do
			local brazo = char:FindFirstChild(n) :: BasePart
			bloque(brazo, Vector3.new(1.2, 0.5, 1.2), Vector3.new(0, 0.82, 0), NOCHE)
			bloque(brazo, Vector3.new(1.22, 0.14, 1.22), Vector3.new(0, 0.55, 0), MORADO, true)
		end
	end
	if lleva.brazales then
		for _, n in { "Right Arm", "Left Arm" } do
			local brazo = char:FindFirstChild(n) :: BasePart
			bloque(brazo, Vector3.new(1.12, 0.85, 1.12), Vector3.new(0, -0.45, 0), NOCHE)
			bloque(brazo, Vector3.new(1.16, 0.14, 1.16), Vector3.new(0, -0.1, 0), PLATA)
			bloque(brazo, Vector3.new(1.16, 0.14, 1.16), Vector3.new(0, -0.75, 0), PLATA)
			bloque(brazo, Vector3.new(0.14, 0.5, 0.06), Vector3.new(0, -0.45, -0.58), MORADO, true)
		end
	end
	if lleva.botas_uku then
		for _, n in { "Right Leg", "Left Leg" } do
			local pierna = char:FindFirstChild(n) :: BasePart
			bloque(pierna, Vector3.new(1.12, 1.0, 1.12), Vector3.new(0, -0.5, 0), NOCHE)
			bloque(pierna, Vector3.new(1.16, 0.14, 1.16), Vector3.new(0, 0, 0), PLATA)
			bloque(pierna, Vector3.new(0.2, 0.5, 0.35), Vector3.new(0.6, -0.1, 0.1), MORADO, true)
		end
	end
	-- ---------- Set del Apu ----------
	local GRANITO = Color3.fromRGB(142, 140, 133)
	local GRANITO_OSCURO = Color3.fromRGB(110, 108, 102)
	local SOL = Color3.fromRGB(255, 204, 64)
	if lleva.corona and cabeza then
		local h = cabeza.Size.Y
		bloque(cabeza, Vector3.new(h * 1.14, 0.3, h * 1.14), Vector3.new(0, h * 0.42, 0), C.oro)
		for k = 0, 6 do
			local ang = k / 7 * math.pi * 2
			bloque(cabeza, Vector3.new(0.22, 0.45 + (k % 2) * 0.2, 0.22), Vector3.new(math.sin(ang) * h * 0.55, h * 0.72 + (k % 2) * 0.1, math.cos(ang) * h * 0.55), C.oro)
		end
		bloque(cabeza, Vector3.new(0.3, 0.3, 0.1), Vector3.new(0, h * 0.45, -h * 0.58), SOL, true)
	end
	if lleva.coraza_granito and torso then
		bloque(torso, Vector3.new(2.16, 1.7, 1.16), Vector3.new(0, 0.15, 0), GRANITO)
		bloque(torso, Vector3.new(0.8, 0.8, 0.08), Vector3.new(0, 0.35, -0.61), C.oro)
		bloque(torso, Vector3.new(0.5, 0.5, 0.1), Vector3.new(0, 0.35, -0.64), SOL, true)
		for _, g in { { -0.7, 0.1, 0.1, 0.8 }, { 0.75, -0.2, 0.1, 0.6 }, { -0.4, -0.5, 0.5, 0.1 } } do
			bloque(torso, Vector3.new(g[3], g[4], 0.06), Vector3.new(g[1], g[2], -0.61), SOL, true)
		end
		for _, n in { "Right Arm", "Left Arm" } do
			local brazo = char:FindFirstChild(n) :: BasePart
			bloque(brazo, Vector3.new(1.3, 0.6, 1.3), Vector3.new(0, 0.8, 0), GRANITO_OSCURO)
		end
	end
	if lleva.punos_piedra then
		for _, n in { "Right Arm", "Left Arm" } do
			local brazo = char:FindFirstChild(n) :: BasePart
			bloque(brazo, Vector3.new(1.14, 0.8, 1.14), Vector3.new(0, -0.45, 0), GRANITO)
			bloque(brazo, Vector3.new(1.3, 0.4, 1.3), Vector3.new(0, -0.95, 0), GRANITO_OSCURO)
			bloque(brazo, Vector3.new(1.16, 0.12, 1.16), Vector3.new(0, -0.1, 0), C.oro)
		end
	end
	if lleva.grebas_montana then
		for _, n in { "Right Leg", "Left Leg" } do
			local pierna = char:FindFirstChild(n) :: BasePart
			bloque(pierna, Vector3.new(1.14, 1.0, 1.14), Vector3.new(0, -0.5, 0), GRANITO)
			bloque(pierna, Vector3.new(1.18, 0.25, 1.18), Vector3.new(0, -0.05, 0), Color3.fromRGB(245, 248, 252))
			bloque(pierna, Vector3.new(0.4, 0.3, 0.1), Vector3.new(0, -0.45, -0.6), C.oro)
		end
	end
	-- efectos de las piezas, para el cliente y el servidor
	local cuenta = {}
	for _, pieza in Armas.TODA_ARMADURA do
		char:SetAttribute("Lleva_" .. pieza, lleva[pieza] == true)
		local set = lleva[pieza] and Armas.PIEZA_SET[pieza]
		if set then
			cuenta[set] = (cuenta[set] or 0) + 1
		end
	end
	for _, set in Armas.SETS do
		char:SetAttribute("Piezas_" .. set, cuenta[set] or 0)
	end
	local rodador = cuenta.rodador or 0
	-- modificadores de las piezas de la selva (Mod_vida, Mod_reduccion...)
	local mods = Armas.mods(lleva)
	for _, k in Armas.CLAVES_MODS do
		char:SetAttribute("Mod_" .. k, mods[k])
	end
	-- Caparazón Solar con las 4 piezas del Rodador
	char:SetAttribute("EscudoMax", rodador >= 4 and 30 or 0)
	char:SetAttribute("Escudo", rodador >= 4 and 30 or 0)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rodador >= 4 and hrp then
		local coraza = pieza(carpeta, { Name = "CorazaSolar", Size = Vector3.new(4.6, 6.2, 3.2), Color = Color3.fromRGB(255, 150, 50) })
		coraza.Material = Enum.Material.ForceField
		soldar(coraza, hrp, CFrame.new(0, 0.4, 0))
		local chispas = emisor(coraza, { "medio", Color3.fromRGB(255, 170, 70), 0, 0.35, 4, 0.8 })
		chispas.Speed = NumberRange.new(8, 16)
		local function actualizar()
			local max = char:GetAttribute("EscudoMax") or 0
			local valor = char:GetAttribute("Escudo") or 0
			local antes = coraza:GetAttribute("Antes") or max
			coraza.Transparency = (max <= 0 or valor <= 0) and 1 or (0.35 + 0.5 * (1 - valor / max))
			if antes > 0 and valor <= 0 then
				chispas:Emit(60) -- la coraza estalla en brasas
			end
			coraza:SetAttribute("Antes", valor)
		end
		char:GetAttributeChangedSignal("Escudo"):Connect(actualizar)
		actualizar()
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local antes = hum.MaxHealth
		local nivel = char:GetAttribute("Nivel") or 1
		hum.MaxHealth = (lleva.coraza and 120 or (lleva.coraza_granito and 115 or (lleva.manto and 110 or 100))) + (nivel - 1) * 2 + (mods.vida or 0)
		if hum.Health >= antes then
			hum.Health = hum.MaxHealth
		end
	end
end

-- ---------- armas ----------
-- Cada arma se arma "de pie": el mango en el origen y la hoja hacia +Y.
-- Al soldarla a la mano se gira para que apunte hacia adelante.
-- Cómo se sostiene cada arma: el mango en la mano y el arma hacia adelante
-- (los blásteres siguen la línea del brazo, para apuntar al frente al estirarlo).
local function agarreDe(id: string, mano: BasePart, izquierda: boolean): CFrame
	local base = Armas.DATOS[id] and Armas.DATOS[id].base or id
	local agarre = CFrame.new(0, -mano.Size.Y * 0.45, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	if base == "pistolas" then
		agarre = CFrame.new(0, -mano.Size.Y * 0.45, 0) * CFrame.Angles(math.pi, 0, 0)
	elseif base == "punos" then
		-- el guantelete envuelve la mano: los nudillos siguen la línea del brazo
		agarre = CFrame.new(0, -mano.Size.Y * 0.42, 0) * CFrame.Angles(math.pi, 0, 0)
	end
	if izquierda then
		agarre = agarre * CFrame.Angles(0, math.pi, 0)
	end
	return agarre
end

-- Armas en pixel art: el servidor solo pone el mango invisible (con la estela y las partículas);
-- cada jugador construye el arma en 3D a partir de su dibujo.
local function construirPixel(id: string, carpeta: Folder, mano: BasePart, izquierda: boolean)
	local arte = ArteArmas.DATOS[id]
	local mango = pieza(carpeta, { Name = "Mango", Size = Vector3.new(0.2, 0.2, 0.2), Color = Color3.new(1, 1, 1) })
	mango.Transparency = 1
	mango:SetAttribute("Sprite", id)
	soldar(mango, mano, agarreDe(id, mano, izquierda))
	local px, ancX, ancY = arte.pixel, arte.ancla[1], arte.ancla[2]
	local function posicion(col: number, fila: number): Vector3
		local h, v = (col - ancX) * px, (ancY - fila) * px
		if arte.plano == "ZY" then
			return Vector3.new(0, v, -h)
		end
		return Vector3.new(h, v, 0)
	end
	-- la punta: la fila más alta del dibujo; la mitad: un poco más de la mitad entre la mano y la punta
	local filaPunta, colPunta = ancY, ancX
	for f, texto in arte.filas do
		local a, b = string.find(texto, "[^%.]+")
		if a then
			filaPunta, colPunta = f - 1, (a + b) / 2 - 1
			break
		end
	end
	local filaMedio = math.floor(ancY + (filaPunta - ancY) * 0.55)
	local function anclaje(nombre: string, pos: Vector3): Attachment
		local a = Instance.new("Attachment")
		a.Name = nombre
		a.Position = pos
		a.Parent = mango
		return a
	end
	local punta = anclaje("EstelaPunta", posicion(colPunta, filaPunta))
	local medio = anclaje("EstelaBase", posicion(ancX, filaMedio))
	for _, c in PARTICULAS[id] or {} do
		emisor((c[1] == "punta" and punta or medio) :: any, c)
	end
	if id == "colmillo" then
		local aura = emisor(medio :: any, { "medio", C.turquesa, 0, 0.3, 2, 0.6, false, "AuraFilo" })
		aura.LightEmission = 1
		aura.Enabled = false
	end
	-- estela de luz del color del filo (solo se ve al atacar)
	local base = Armas.DATOS[id] and Armas.DATOS[id].base or id
	if base ~= "pistolas" then
		local color = Color3.fromRGB(255, 230, 170)
		for _, c in arte.paleta do
			if c[5] then
				color = Color3.fromRGB(c[1], c[2], c[3])
				break
			end
		end
		local estela = Instance.new("Trail")
		estela.Name = "Estela"
		estela.Attachment0 = medio
		estela.Attachment1 = punta
		estela.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color)
		estela.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		estela.Lifetime = 0.2
		estela.MinLength = 0.05
		estela.LightEmission = 0.9
		estela.FaceCamera = true
		estela.Enabled = false
		estela.Parent = mango
	end
end

local function construirArma(id: string, carpeta: Folder, mano: BasePart, izquierda: boolean)
	if ArteArmas.DATOS[id] then
		construirPixel(id, carpeta, mano, izquierda)
		return
	end
	local grupo = {}
	local function p(props)
		local x = pieza(carpeta, props)
		table.insert(grupo, { x, props.En or CFrame.new() })
		return x
	end
	-- estilo voxel: todo son bloques; "Neon" marca las piezas que brillan
	local function b(tam: Vector3, color: Color3, pos: Vector3, brilla: boolean?)
		return p({ Size = tam, Color = color, Material = brilla and Enum.Material.Neon or nil, En = CFrame.new(pos) })
	end
	-- bloque girado sobre el eje X (para seguir una curva en el plano Y-Z)
	local function bg(tam: Vector3, color: Color3, pos: Vector3, angulo: number, brilla: boolean?)
		return p({ Size = tam, Color = color, Material = brilla and Enum.Material.Neon or nil, En = CFrame.new(pos) * CFrame.Angles(angulo, 0, 0) })
	end
	-- una hoja curva: sigue una lista de puntos {y, z}, con su ancho en cada punto
	local function hojaCurva(puntos, anchos, grosor, colores, filo, espinas)
		for i = 1, #puntos - 1 do
			local a, c = puntos[i], puntos[i + 1]
			local dy, dz = c[1] - a[1], c[2] - a[2]
			local largo = math.sqrt(dy * dy + dz * dz)
			local ang = math.atan2(dz, dy)
			local medio = Vector3.new(0, (a[1] + c[1]) / 2, (a[2] + c[2]) / 2)
			local ancho = anchos[i]
			-- normal de la curva (hacia afuera de la medialuna)
			local nY, nZ = -dz / largo, dy / largo
			bg(Vector3.new(grosor, largo + 0.04, ancho * 0.55), colores[1], medio, ang)
			bg(Vector3.new(grosor * 0.9, largo + 0.04, ancho * 0.3), colores[2], medio - Vector3.new(0, nY, nZ) * ancho * 0.38, ang)
			bg(Vector3.new(grosor * 1.05, largo + 0.04, ancho * 0.16), filo, medio - Vector3.new(0, nY, nZ) * ancho * 0.56, ang, true)
			if espinas and i % 3 == 2 then
				bg(Vector3.new(grosor * 0.9, 0.18, 0.3), colores[3], medio + Vector3.new(0, nY, nZ) * (ancho * 0.4 + 0.12), ang)
			end
		end
	end
	local V3 = Vector3.new
	local acero = Color3.fromRGB(236, 232, 218)
	local aceroOscuro = Color3.fromRGB(190, 186, 176)
	local madera = Color3.fromRGB(120, 80, 46)
	local maderaClara = Color3.fromRGB(150, 104, 62)
	local piedra = C.piedra
	local piedraOscura = Color3.fromRGB(190, 152, 100)
	local alba = Color3.fromRGB(255, 160, 70)
	if id == "espada" then
		-- Espada del Alba: hoja ancha con biseles, canal dorado brillante y guarda de alas
		local claro, sombra = Color3.fromRGB(246, 248, 250), Color3.fromRGB(150, 160, 172)
		b(V3(0.34, 1.1, 0.34), C.cuero, V3(0, 0, 0))
		for _, y in { -0.32, 0, 0.32 } do
			b(V3(0.37, 0.08, 0.37), Color3.fromRGB(70, 44, 26), V3(0, y, 0))
		end
		b(V3(0.46, 0.3, 0.46), C.oro, V3(0, -0.72, 0))
		b(V3(0.26, 0.26, 0.5), alba, V3(0, -0.72, 0), true)
		-- guarda en forma de alas
		b(V3(0.8, 0.36, 0.46), C.oro, V3(0, 0.66, 0))
		for _, lado in { -1, 1 } do
			b(V3(0.4, 0.26, 0.36), C.oro, V3(lado * 0.56, 0.72, 0))
			b(V3(0.34, 0.22, 0.3), Color3.fromRGB(240, 196, 90), V3(lado * 0.9, 0.84, 0))
			b(V3(0.28, 0.2, 0.26), C.oro, V3(lado * 1.18, 0.98, 0))
			b(V3(0.18, 0.2, 0.2), Color3.fromRGB(250, 214, 120), V3(lado * 1.38, 1.16, 0))
		end
		b(V3(0.32, 0.32, 0.52), alba, V3(0, 0.66, 0), true)
		-- hoja en tramos: filo claro, centro y filo en sombra
		local anchos = { 1.0, 1.0, 0.98, 0.94, 0.86, 0.74, 0.58, 0.4 }
		for i, ancho in anchos do
			local y = 0.95 + (i - 0.5) * 0.46
			b(V3(ancho * 0.5, 0.47, 0.2), acero, V3(0, y, 0))
			b(V3(ancho * 0.26, 0.47, 0.13), claro, V3(-ancho * 0.37, y, 0))
			b(V3(ancho * 0.26, 0.47, 0.13), sombra, V3(ancho * 0.37, y, 0))
		end
		b(V3(0.26, 0.3, 0.15), acero, V3(0, 4.83, 0))
		b(V3(0.1, 0.2, 0.1), claro, V3(0, 5.05, 0))
		b(V3(0.1, 3.3, 0.22), Color3.fromRGB(255, 184, 64), V3(0, 2.55, 0), true)
	elseif id == "martillo" then
		-- Martillo del Obelisco: la cabeza es un obelisco acostado con jeroglíficos
		b(V3(0.32, 4.4, 0.32), madera, V3(0, 1.6, 0))
		for _, y in { -0.45, 1.9, 3.25 } do
			b(V3(0.4, 0.2, 0.4), C.oro, V3(0, y, 0))
		end
		b(V3(0.42, 0.3, 0.42), C.turquesa, V3(0, -0.7, 0), true)
		local y = 3.95
		b(V3(0.45, 1.5, 1.5), piedraOscura, V3(-0.95, y, 0))
		b(V3(1.4, 1.4, 1.4), piedra, V3(0, y, 0))
		b(V3(0.9, 1.15, 1.15), piedraOscura, V3(1.15, y, 0))
		b(V3(0.7, 0.85, 0.85), piedra, V3(1.95, y, 0))
		b(V3(0.45, 0.5, 0.5), C.oro, V3(2.5, y, 0), true)
		for _, lado in { -1, 1 } do
			b(V3(0.25, 0.25, 0.05), C.turquesa, V3(-0.25, y + 0.3, lado * 0.72), true)
			b(V3(0.25, 0.45, 0.05), C.turquesa, V3(0.25, y - 0.15, lado * 0.72), true)
			b(V3(0.2, 0.2, 0.05), C.turquesa, V3(1.15, y + 0.2, lado * 0.6), true)
		end
		b(V3(1.44, 0.18, 1.44), C.oro, V3(0, y - 0.62, 0))
	elseif id == "guadanas" then
		-- Guadañas del Nómada: grandes medialunas de acero azul con filo turquesa (una en cada mano)
		local rojo, rojoOscuro = Color3.fromRGB(154, 42, 42), Color3.fromRGB(100, 24, 24)
		b(V3(0.3, 1.1, 0.3), rojo, V3(0, 0, 0))
		for _, y in { -0.3, 0, 0.3 } do
			b(V3(0.33, 0.08, 0.33), rojoOscuro, V3(0, y, 0))
		end
		b(V3(0.4, 0.14, 0.4), C.oro, V3(0, 0.6, 0))
		b(V3(0.4, 0.14, 0.4), C.oro, V3(0, -0.6, 0))
		b(V3(0.34, 0.3, 0.34), C.oro, V3(0, -0.8, 0))
		b(V3(0.18, 0.4, 0.18), C.turquesa, V3(0, -1.1, 0), true)
		hojaCurva(
			{ { 0.7, 0 }, { 1.05, -0.2 }, { 1.35, -0.45 }, { 1.62, -0.78 }, { 1.84, -1.15 }, { 1.98, -1.56 }, { 2.02, -1.98 }, { 1.96, -2.38 }, { 1.8, -2.74 }, { 1.56, -3.02 }, { 1.26, -3.2 } },
			{ 0.55, 0.68, 0.78, 0.82, 0.8, 0.74, 0.64, 0.52, 0.4, 0.28 },
			0.13,
			{ Color3.fromRGB(34, 52, 88), Color3.fromRGB(56, 88, 140), Color3.fromRGB(20, 30, 52) },
			C.turquesa,
			true
		)
	elseif id == "lanza" then
		-- Lanza del Vigía: punta de hoja, anillo turquesa y banderín rojo
		b(V3(0.26, 6.6, 0.26), maderaClara, V3(0, 1.8, 0))
		b(V3(0.34, 0.2, 0.34), C.oro, V3(0, -1.45, 0))
		b(V3(0.34, 0.2, 0.34), C.oro, V3(0, 4.9, 0))
		b(V3(0.38, 0.22, 0.38), C.turquesa, V3(0, 5.15, 0), true)
		local hoja = { 0.3, 0.5, 0.62, 0.52, 0.38, 0.22 }
		for i, ancho in hoja do
			b(V3(ancho, 0.26, 0.12), i % 2 == 0 and acero or aceroOscuro, V3(0, 5.2 + i * 0.26, 0))
		end
		b(V3(0.08, 1.4, 0.16), C.oro, V3(0, 6.0, 0))
		b(V3(0.06, 0.7, 0.9), C.rojo, V3(0, 4.45, 0.55))
		b(V3(0.07, 0.12, 0.9), C.oro, V3(0, 4.15, 0.55))
	elseif id == "pistolas" then
		-- Blásteres del Explorador: latón y madera con un cristal turquesa
		b(V3(0.42, 0.45, 0.85), madera, V3(0, -0.05, -0.4))
		b(V3(0.5, 1.1, 0.56), C.oro, V3(0, 0.35, 0.05))
		b(V3(0.58, 0.32, 0.32), C.turquesa, V3(0, 0.35, 0.12), true)
		b(V3(0.36, 0.6, 0.36), aceroOscuro, V3(0, 1.1, 0.1))
		b(V3(0.46, 0.2, 0.46), C.oro, V3(0, 1.45, 0.1))
		b(V3(0.2, 0.08, 0.2), C.turquesa, V3(0, 1.56, 0.1), true)
		b(V3(0.14, 0.25, 0.14), C.oro, V3(0, 0.95, 0.38))
	elseif id == "mandibula" then
		-- Mandíbula del Rodador: hoja curva de quitina con el filo al rojo
		local negro = Color3.fromRGB(46, 32, 22)
		local rojo = Color3.fromRGB(255, 120, 40)
		b(V3(0.34, 1.0, 0.34), C.cuero, V3(0, 0, 0))
		b(V3(0.44, 0.3, 0.44), C.oro, V3(0, -0.62, 0))
		b(V3(0.2, 0.2, 0.46), rojo, V3(0, -0.62, 0), true)
		for _, lado in { -1, 1 } do
			b(V3(0.6, 0.25, 0.3), negro, V3(lado * 0.45, 0.62, 0))
		end
		for i = 1, 7 do
			local curva = (i * i) * 0.018
			b(V3(0.5 - i * 0.04, 0.5, 0.16), negro, V3(-curva, 0.75 + i * 0.5, 0))
			b(V3(0.1, 0.5, 0.18), rojo, V3(0.24 - i * 0.02 - curva, 0.75 + i * 0.5, 0), true)
		end
	elseif id == "sol_rodante" then
		-- Martillo del Sol Rodante: una bola solar enjaulada en quitina
		local negro = Color3.fromRGB(46, 32, 22)
		b(V3(0.34, 4.4, 0.34), negro, V3(0, 1.6, 0))
		b(V3(0.42, 0.22, 0.42), C.oro, V3(0, 1.9, 0))
		local y = 4.0
		b(V3(1.5, 1.5, 1.5), Color3.fromRGB(232, 120, 30), V3(0, y, 0), true)
		for _, x in { -0.78, 0.78 } do
			for _, z in { -0.78, 0.78 } do
				b(V3(0.22, 1.8, 0.22), negro, V3(x, y, z))
			end
		end
		b(V3(1.8, 0.22, 1.8), C.oro, V3(0, y + 0.9, 0))
		b(V3(1.8, 0.22, 1.8), C.oro, V3(0, y - 0.9, 0))
	elseif id == "pinzas" then
		-- Pinzas del Escarabajo: hoz de cuerno con la punta al rojo (una en cada mano)
		local negro = Color3.fromRGB(46, 32, 22)
		b(V3(0.3, 1.0, 0.3), C.cuero, V3(0, 0, 0))
		b(V3(0.38, 0.18, 0.38), C.oro, V3(0, 0.56, 0))
		local curva = { { 0.8, 0 }, { 1.1, 0.02 }, { 1.4, 0.1 }, { 1.66, 0.28 }, { 1.84, 0.52 }, { 1.9, 0.8 }, { 1.84, 1.06 } }
		for i, c in curva do
			b(V3(0.14, 0.32, 0.32), negro, V3(0, c[1], -c[2]))
		end
		b(V3(0.16, 0.24, 0.24), Color3.fromRGB(255, 120, 40), V3(0, 1.68, -1.28), true)
	elseif id == "hercules" then
		-- Cuerno de Hércules: la punta es un cuerno curvo con la punta encendida
		local negro = Color3.fromRGB(46, 32, 22)
		b(V3(0.28, 6.6, 0.28), negro, V3(0, 1.8, 0))
		for _, y in { -0.8, 1.6, 4.0 } do
			b(V3(0.36, 0.2, 0.36), C.turquesa, V3(0, y, 0), true)
		end
		b(V3(0.4, 0.24, 0.4), C.oro, V3(0, 5.0, 0))
		for i, c in { { 5.4, 0.0, 0.5 }, { 5.85, -0.08, 0.44 }, { 6.3, -0.2, 0.38 }, { 6.7, -0.38, 0.3 } } do
			b(V3(c[3], 0.5, c[3]), negro, V3(0, c[1], c[2]))
		end
		b(V3(0.2, 0.3, 0.2), Color3.fromRGB(255, 120, 40), V3(0, 7.05, -0.55), true)
		b(V3(0.28, 0.7, 0.28), negro, V3(0, 5.6, 0.45))
	elseif id == "brasa" then
		-- Blásteres de Brasa: quitina oscura con ventanas de brasas
		local negro = Color3.fromRGB(46, 32, 22)
		b(V3(0.42, 0.45, 0.85), C.cuero, V3(0, -0.05, -0.4))
		b(V3(0.52, 1.1, 0.58), negro, V3(0, 0.35, 0.05))
		b(V3(0.6, 0.22, 0.22), Color3.fromRGB(255, 120, 40), V3(0, 0.15, 0.12), true)
		b(V3(0.6, 0.22, 0.22), Color3.fromRGB(255, 120, 40), V3(0, 0.55, 0.12), true)
		b(V3(0.38, 0.6, 0.38), negro, V3(0, 1.1, 0.1))
		b(V3(0.46, 0.18, 0.46), C.oro, V3(0, 1.45, 0.1))
	elseif id == "filo_eclipse" then
		-- Filo del Eclipse: hoja negra con filo morado y guarda de media luna plateada
		local negro = Color3.fromRGB(20, 14, 32)
		local plata = Color3.fromRGB(201, 198, 214)
		b(V3(0.34, 1.0, 0.34), negro, V3(0, 0, 0))
		b(V3(0.4, 0.4, 0.4), Color3.new(1, 1, 1), V3(0, -0.62, 0), true)
		b(V3(1.5, 0.25, 0.3), plata, V3(0, 0.6, 0))
		for _, lado in { -1, 1 } do
			b(V3(0.25, 0.4, 0.3), plata, V3(lado * 0.8, 0.8, 0))
		end
		for i = 1, 7 do
			b(V3(0.52 - i * 0.05, 0.5, 0.14), negro, V3(0, 0.75 + i * 0.5, 0))
		end
		b(V3(0.1, 3.3, 0.18), Color3.fromRGB(160, 76, 224), V3(0.2, 2.3, 0), true)
	elseif id == "martillo_uku" then
		-- Martillo del Uku Pacha: piedra oscura con un ojo morado
		local plata = Color3.fromRGB(201, 198, 214)
		b(V3(0.34, 4.4, 0.34), Color3.fromRGB(34, 22, 50), V3(0, 1.6, 0))
		for _, y in { -0.45, 1.9, 3.1 } do
			b(V3(0.42, 0.22, 0.42), plata, V3(0, y, 0))
		end
		local y = 4.0
		b(V3(2.2, 1.5, 1.5), Color3.fromRGB(44, 36, 56), V3(0, y, 0))
		b(V3(2.3, 0.2, 1.56), plata, V3(0, y + 0.55, 0))
		b(V3(0.6, 0.4, 0.06), Color3.fromRGB(160, 76, 224), V3(0, y, -0.78), true)
		b(V3(0.2, 0.2, 0.08), Color3.new(1, 1, 1), V3(0, y, -0.8), true)
	elseif id == "alas_amaru" then
		-- Alas de Amaru: hojas con forma de pluma, oscuras con puntas moradas (una en cada mano)
		b(V3(0.28, 1.0, 0.28), Color3.fromRGB(34, 22, 50), V3(0, 0, 0))
		b(V3(0.36, 0.16, 0.36), Color3.fromRGB(201, 198, 214), V3(0, 0.56, 0))
		local curva = { { 0.8, 0 }, { 1.1, 0.04 }, { 1.4, 0.14 }, { 1.66, 0.32 }, { 1.84, 0.56 }, { 1.9, 0.84 }, { 1.84, 1.1 } }
		for i, c in curva do
			b(V3(0.1, 0.32, 0.34), i % 2 == 0 and Color3.fromRGB(34, 22, 50) or Color3.fromRGB(56, 36, 80), V3(0, c[1], -c[2]))
		end
		b(V3(0.12, 0.3, 0.3), Color3.fromRGB(160, 76, 224), V3(0, 1.7, -1.32), true)
	elseif id == "lanza_uku" then
		-- Lanza del Uku Pacha: la punta es un colmillo de serpiente plateado que brilla
		b(V3(0.28, 6.6, 0.28), Color3.fromRGB(34, 22, 50), V3(0, 1.8, 0))
		for _, y in { -0.8, 1.6, 4.0 } do
			b(V3(0.36, 0.2, 0.36), Color3.fromRGB(160, 76, 224), V3(0, y, 0), true)
		end
		for i, c in { { 5.3, 0.46 }, { 5.7, 0.38 }, { 6.1, 0.3 }, { 6.5, 0.22 }, { 6.85, 0.14 } } do
			b(V3(c[2], 0.42, c[2]), Color3.fromRGB(201, 198, 214), V3(0, c[1], -i * 0.03))
		end
		b(V3(0.1, 1.4, 0.1), Color3.fromRGB(190, 110, 255), V3(0, 6.0, -0.2), true)
	elseif id == "blasteres_eclipse" then
		-- Blásteres del Eclipse: negros con un núcleo morado y la boca como un sol negro
		b(V3(0.42, 0.45, 0.85), Color3.fromRGB(34, 22, 50), V3(0, -0.05, -0.4))
		b(V3(0.52, 1.1, 0.58), Color3.fromRGB(20, 14, 32), V3(0, 0.35, 0.05))
		b(V3(0.6, 0.32, 0.32), Color3.fromRGB(160, 76, 224), V3(0, 0.35, 0.12), true)
		b(V3(0.38, 0.6, 0.38), Color3.fromRGB(20, 14, 32), V3(0, 1.1, 0.1))
		b(V3(0.6, 0.12, 0.6), Color3.fromRGB(192, 112, 255), V3(0, 1.42, 0.1), true)
		b(V3(0.3, 0.1, 0.3), Color3.fromRGB(8, 4, 14), V3(0, 1.5, 0.1))
	elseif id == "filo_inti" then
		-- Filo del Inti: hoja dorada con un sol en la guarda
		local sol = Color3.fromRGB(255, 204, 64)
		b(V3(0.34, 1.0, 0.34), Color3.fromRGB(110, 108, 102), V3(0, 0, 0))
		b(V3(1.1, 1.1, 0.3), C.oro, V3(0, 0.65, 0))
		b(V3(0.6, 0.6, 0.34), sol, V3(0, 0.65, 0), true)
		for i = 1, 7 do
			b(V3(0.5 - i * 0.045, 0.5, 0.14), i % 2 == 0 and Color3.fromRGB(246, 228, 170) or C.oro, V3(0, 0.95 + i * 0.5, 0))
		end
		b(V3(0.1, 3.2, 0.18), sol, V3(0, 2.5, 0), true)
	elseif id == "puno_apu" then
		-- Puño del Apu: la cabeza es un puño de piedra con nudillos de oro
		b(V3(0.34, 4.4, 0.34), Color3.fromRGB(110, 108, 102), V3(0, 1.6, 0))
		for _, y in { -0.45, 1.9, 3.1 } do
			b(V3(0.42, 0.22, 0.42), C.oro, V3(0, y, 0))
		end
		local y = 4.0
		b(V3(1.8, 1.6, 1.6), Color3.fromRGB(142, 140, 133), V3(0, y, 0))
		for k = -1, 1 do
			b(V3(0.5, 0.45, 0.3), C.oro, V3(k * 0.55, y + 0.4, -0.85))
		end
		b(V3(0.4, 0.8, 0.1), Color3.fromRGB(255, 204, 64), V3(0.9, y, 0), true)
	elseif id == "hoces_granito" then
		-- Hoces de Granito: hojas de piedra con filo dorado (una en cada mano)
		b(V3(0.3, 1.0, 0.3), Color3.fromRGB(110, 108, 102), V3(0, 0, 0))
		b(V3(0.38, 0.18, 0.38), C.oro, V3(0, 0.56, 0))
		local curva = { { 0.8, 0 }, { 1.1, 0.04 }, { 1.4, 0.14 }, { 1.66, 0.32 }, { 1.84, 0.56 }, { 1.9, 0.84 } }
		for i, c in curva do
			b(V3(0.16, 0.34, 0.34), i % 2 == 0 and Color3.fromRGB(142, 140, 133) or Color3.fromRGB(122, 120, 114), V3(0, c[1], -c[2]))
		end
		b(V3(0.1, 0.9, 0.12), Color3.fromRGB(255, 204, 64), V3(0, 1.5, -0.35), true)
	elseif id == "lanza_sol" then
		-- Lanza del Sol Naciente: punta de oro con un disco solar
		b(V3(0.28, 6.6, 0.28), Color3.fromRGB(110, 108, 102), V3(0, 1.8, 0))
		b(V3(1.0, 1.0, 0.2), C.oro, V3(0, 5.2, 0))
		b(V3(0.5, 0.5, 0.24), Color3.fromRGB(255, 204, 64), V3(0, 5.2, 0), true)
		for i, a in { 0.36, 0.28, 0.2, 0.12 } do
			b(V3(a, 0.4, a), C.oro, V3(0, 5.6 + i * 0.4, 0))
		end
	elseif id == "blasteres_inti" then
		-- Blásteres del Inti: piedra y oro con un sol en la boca del cañón
		b(V3(0.42, 0.45, 0.85), Color3.fromRGB(110, 108, 102), V3(0, -0.05, -0.4))
		b(V3(0.52, 1.1, 0.58), Color3.fromRGB(142, 140, 133), V3(0, 0.35, 0.05))
		b(V3(0.6, 0.3, 0.3), Color3.fromRGB(255, 204, 64), V3(0, 0.35, 0.12), true)
		b(V3(0.38, 0.6, 0.38), C.oro, V3(0, 1.1, 0.1))
		b(V3(0.7, 0.14, 0.7), Color3.fromRGB(255, 220, 120), V3(0, 1.42, 0.1), true)
	elseif id == "colmillo" then
		-- Colmillo del Guardián: un colmillo de marfil con filo turquesa y pomo de león
		b(V3(0.36, 1.0, 0.36), C.cuero, V3(0, 0, 0))
		b(V3(0.5, 0.45, 0.5), C.oro, V3(0, -0.66, 0))
		b(V3(0.14, 0.14, 0.52), Color3.fromRGB(255, 176, 60), V3(0, -0.6, 0), true)
		b(V3(1.4, 0.32, 0.42), C.oro, V3(0, 0.62, 0))
		b(V3(0.3, 0.3, 0.46), C.turquesa, V3(0, 0.64, 0), true)
		local marfil = Color3.fromRGB(246, 236, 212)
		local curva = { { 0.6, 0 }, { 0.58, 0.05 }, { 0.54, 0.12 }, { 0.48, 0.2 }, { 0.4, 0.3 }, { 0.3, 0.42 }, { 0.2, 0.55 } }
		for i, c in curva do
			b(V3(c[1], 0.5, 0.16), i % 2 == 0 and marfil or Color3.fromRGB(226, 214, 186), V3(0, 0.78 + i * 0.5, -c[2]))
		end
		b(V3(0.1, 3.2, 0.2), C.turquesa, V3(0.28, 2.3, -0.2), true)
	elseif id == "esfinge" then
		-- Martillo de la Esfinge: la cabeza es una esfinge con su tocado azul y dorado
		b(V3(0.34, 4.4, 0.34), Color3.fromRGB(70, 50, 34), V3(0, 1.6, 0))
		for _, y in { -0.45, 1.9, 3.1 } do
			b(V3(0.42, 0.22, 0.42), C.oro, V3(0, y, 0))
		end
		local y = 4.0
		b(V3(1.6, 1.6, 1.6), C.oro, V3(0, y, 0))
		for k = -1, 1 do
			b(V3(1.66, 0.28, 1.66), AZUL, V3(0, y + k * 0.5, 0))
		end
		b(V3(0.9, 0.9, 0.2), ARENA_ORO, V3(0, y - 0.05, -0.85))
		b(V3(0.2, 0.14, 0.05), Color3.fromRGB(30, 30, 40), V3(-0.2, y + 0.1, -0.96))
		b(V3(0.2, 0.14, 0.05), Color3.fromRGB(30, 30, 40), V3(0.2, y + 0.1, -0.96))
		b(V3(0.2, 0.35, 0.2), C.turquesa, V3(0, y + 0.95, -0.7), true)
	elseif id == "remolino" then
		-- Hoces del Remolino: hoces de arena con espirales turquesa (una en cada mano)
		b(V3(0.3, 1.0, 0.3), Color3.fromRGB(70, 50, 34), V3(0, 0, 0))
		b(V3(0.38, 0.18, 0.38), C.oro, V3(0, 0.56, 0))
		local curva = { { 0.8, 0 }, { 1.08, 0 }, { 1.36, 0.06 }, { 1.62, 0.22 }, { 1.8, 0.46 }, { 1.88, 0.74 }, { 1.84, 1.02 }, { 1.7, 1.26 }, { 1.48, 1.42 } }
		for i, c in curva do
			b(V3(0.12, 0.32, 0.32), i % 2 == 0 and ARENA_ORO or C.oro, V3(0, c[1], -c[2]))
		end
		for _, c in { { 1.3, 0.35 }, { 1.5, 0.6 }, { 1.45, 0.85 } } do
			b(V3(0.14, 0.14, 0.14), C.turquesa, V3(0, c[1], -c[2]), true)
		end
	elseif id == "serket" then
		-- Lanza de Serket: la punta es el aguijón de un escorpión con una gota de veneno
		b(V3(0.28, 6.6, 0.28), Color3.fromRGB(60, 44, 30), V3(0, 1.8, 0))
		b(V3(0.36, 0.22, 0.36), C.oro, V3(0, -1.45, 0))
		for i = 0, 3 do
			b(V3(0.46 - i * 0.06, 0.34, 0.46 - i * 0.06), i % 2 == 0 and Color3.fromRGB(255, 176, 60) or Color3.fromRGB(200, 120, 40), V3(0, 5.2 + i * 0.34, i * 0.06))
		end
		b(V3(0.18, 0.7, 0.18), Color3.fromRGB(255, 190, 90), V3(0, 6.75, -0.1), true)
		b(V3(0.16, 0.16, 0.16), Color3.fromRGB(120, 230, 110), V3(0, 7.15, -0.2), true)
	elseif id == "sol_dorado" then
		-- Blásteres del Sol Dorado: oro con un disco solar en el cañón
		b(V3(0.42, 0.45, 0.85), Color3.fromRGB(70, 50, 34), V3(0, -0.05, -0.4))
		b(V3(0.52, 1.1, 0.58), C.oro, V3(0, 0.35, 0.05))
		b(V3(0.6, 0.34, 0.34), Color3.fromRGB(255, 176, 60), V3(0, 0.35, 0.12), true)
		b(V3(0.38, 0.6, 0.38), C.oro, V3(0, 1.1, 0.1))
		b(V3(0.7, 0.14, 0.7), Color3.fromRGB(255, 200, 90), V3(0, 1.42, 0.1), true)
		b(V3(0.2, 0.08, 0.2), Color3.fromRGB(255, 240, 180), V3(0, 1.52, 0.1), true)
	end
	-- la mano sostiene el mango; el arma apunta hacia adelante
	local agarre = CFrame.new(0, -mano.Size.Y * 0.45, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	if id == "pistolas" or id == "sol_dorado" or id == "brasa" or id == "blasteres_eclipse" or id == "blasteres_inti" then
		-- los blásteres siguen la línea del brazo: al estirarlo para disparar apuntan al frente
		agarre = CFrame.new(0, -mano.Size.Y * 0.45, 0) * CFrame.Angles(math.pi, 0, 0)
	end
	if izquierda then
		agarre = agarre * CFrame.Angles(0, math.pi, 0)
	end
	for _, par in grupo do
		soldar(par[1], mano, agarre * par[2])
	end
	-- partículas: en la punta del arma o a la mitad de la hoja
	local ordenado = table.clone(grupo)
	table.sort(ordenado, function(a, b)
		return a[2].Position.Y < b[2].Position.Y
	end)
	if #ordenado > 0 then
		for _, c in PARTICULAS[id] or {} do
			local parte = c[1] == "punta" and ordenado[#ordenado][1] or ordenado[math.max(1, math.floor(#ordenado * 0.7))][1]
			emisor(parte, c)
		end
		-- estela de luz entre la base y la punta de la hoja (solo se ve al atacar)
		local base = Armas.DATOS[id] and Armas.DATOS[id].base or id
		if base ~= "pistolas" and #ordenado >= 3 then
			local color = Color3.fromRGB(255, 230, 170)
			for _, par in grupo do
				if par[1].Material == Enum.Material.Neon then
					color = par[1].Color
					break
				end
			end
			local a0 = Instance.new("Attachment")
			a0.Name = "EstelaBase"
			a0.Parent = ordenado[math.max(1, math.floor(#ordenado * 0.45))][1]
			local a1 = Instance.new("Attachment")
			a1.Name = "EstelaPunta"
			a1.Parent = ordenado[#ordenado][1]
			local estela = Instance.new("Trail")
			estela.Name = "Estela"
			estela.Attachment0 = a0
			estela.Attachment1 = a1
			estela.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color)
			estela.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			estela.Lifetime = 0.18
			estela.MinLength = 0.05
			estela.LightEmission = 0.9
			estela.FaceCamera = true
			estela.Enabled = false
			estela.Parent = a1.Parent
		end
		-- el Colmillo guarda un aura turquesa para cuando el filo queda cargado
		if id == "colmillo" then
			local aura = emisor(ordenado[math.max(1, math.floor(#ordenado * 0.7))][1], { "medio", C.turquesa, 0, 0.3, 2, 0.6, false, "AuraFilo" })
			aura.LightEmission = 1
			aura.Enabled = false
		end
	end
end

function Equipo.armar(char: Model, id: string)
	local vieja = char:FindFirstChild("Arma")
	if vieja then
		vieja:Destroy()
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Arma"
	carpeta.Parent = char
	local derecha = parteDelCuerpo(char, "RightHand", "Right Arm")
	local izquierda = parteDelCuerpo(char, "LeftHand", "Left Arm")
	if derecha then
		construirArma(id, carpeta, derecha, false)
	end
	local base = Armas.DATOS[id] and Armas.DATOS[id].base or id
	local doble = Armas.DATOS[id] and Armas.DATOS[id].doble
	if izquierda and (doble or base == "guadanas" or base == "pistolas") then
		construirArma(id, carpeta, izquierda, true)
	end
	char:SetAttribute("Arma", id)
	char:SetAttribute("ArmaBase", base)
end

-- Muestra un arma sobre un soporte (para la armería del Refugio).
function Equipo.exhibir(id: string, soporte: BasePart)
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Exhibicion"
	carpeta.Parent = soporte
	construirArma(id, carpeta, soporte, false)
	for _, x in carpeta:GetDescendants() do
		if x:IsA("BasePart") then
			x.Anchored = true
		end
	end
end

function Equipo.desarmar(char: Model)
	local vieja = char:FindFirstChild("Arma")
	if vieja then
		vieja:Destroy()
	end
	char:SetAttribute("Arma", nil)
end

return Equipo
