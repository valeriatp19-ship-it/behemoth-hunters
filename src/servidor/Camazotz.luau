--!nonstrict
-- Camazotz, el Murciélago de Xibalbá (elemento Eco): vive en el Templo de Xibalbá.
-- Camina apoyado en las alas plegadas, como los murciélagos vampiro. Ataques: zarpazo con el ala,
-- mordida que lo cura, grito sónico en cono, onda en anillo, picada desde el aire y (en la Noche de
-- Xibalbá) un enjambre de murciélagos. Partes: orejas (sus gritos se debilitan), alas (ya no vuela)
-- y colmillos (la mordida ya no lo cura).
local Base = require(script.Parent.BehemothSelva)

local V, CF = Base.V, Base.CF
local S = Base.S
local plano = Base.plano
local rgb = Color3.fromRGB

local Poses = require(game:GetService("ReplicatedStorage").Compartido.PosesSelva)
local Remotos = require(game:GetService("ReplicatedStorage").Compartido.Remotos)

local PELO = rgb(34, 24, 48)
local PELO2 = rgb(60, 44, 82)
local MANTO = rgb(92, 66, 110)
local MEMBRANA = rgb(96, 18, 42) -- membranas rojo sangre: el murciélago de la muerte
local MEMBRANA2 = rgb(124, 28, 54)
local HUESO = rgb(30, 20, 36)
local HUESO2 = rgb(58, 40, 66)
local PIEL = rgb(92, 56, 78)
local PIEL2 = rgb(122, 72, 96)
local ORO2 = rgb(170, 118, 36)
local JADE = rgb(48, 220, 170)
local ORO = rgb(232, 178, 60)
local OJO = rgb(255, 50, 50)
local MARFIL = rgb(240, 232, 214)
local GLIFO = rgb(64, 230, 220)

local def = {
	nombre = "Camazotz", modelo = "Camazotz", zona = "xibalba", prefijo = "camazotz_",
	vidaBase = 9000, derriboMax = 250, velVagar = 3.4, velPerseguir = 6.6, distanciaCerca = 7,
	colorTexto = rgb(200, 140, 255), colorPolvo = rgb(70, 60, 80),
	textoFase2 = "¡Cae la Noche de Xibalbá! Sus glifos arden",
	ataques = {
		zarpazo = { prep = 0.75, activo = 0.3, rec = 0.8, danio = 22, empuje = 12 },
		mordida = { prep = 0.8, activo = 0.25, rec = 0.9, danio = 22, empuje = 8 },
		grito = { prep = 1.0, activo = 0.8, rec = 0.8, danio = 18, empuje = 10 },
		onda = { prep = 0.9, activo = 0.3, rec = 0.9, danio = 20, empuje = 18 },
		picada = { prep = 1.1, activo = 0.9, rec = 1.1, danio = 30, empuje = 16 },
		enjambre = { prep = 1.0, activo = 3.6, rec = 0.6, danio = 9, empuje = 6 },
	},
	partes = {
		orejas = { nombre = "Orejas", max = 260 },
		alas = { nombre = "Alas", max = 320 },
		colmillos = { nombre = "Colmillos", max = 260 },
	},
	ordenPartes = { "orejas", "alas", "colmillos" },
	zonas = {
		{ nombre = "hocico", tipo = "cabeza", parte = "colmillos", pos = Vector3.new(0, 3.6, -4.9), r = 1.3 },
		{ nombre = "cabeza", tipo = "cabeza", parte = "", pos = Vector3.new(0, 4.3, -2.9), r = 1.7 },
		{ nombre = "oreja_i", tipo = "cabeza", parte = "orejas", pos = Vector3.new(-1.9, 7.0, -2.6), r = 1.4 },
		{ nombre = "oreja_d", tipo = "cabeza", parte = "orejas", pos = Vector3.new(1.9, 7.0, -2.6), r = 1.4 },
		{ nombre = "torso", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 3.4, 0.4), r = 2.2 },
		{ nombre = "vientre", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.9, 0.6), r = 1.6 },
		{ nombre = "ala_i", tipo = "pata", parte = "alas", pos = Vector3.new(-3.0, 1.6, -1.7), r = 1.3 },
		{ nombre = "ala_d", tipo = "pata", parte = "alas", pos = Vector3.new(3.0, 1.6, -1.7), r = 1.3 },
		{ nombre = "membrana_i", tipo = "cuerpo", parte = "alas", pos = Vector3.new(-2.9, 3.2, 0.9), r = 1.8 },
		{ nombre = "membrana_d", tipo = "cuerpo", parte = "alas", pos = Vector3.new(2.9, 3.2, 0.9), r = 1.8 },
		{ nombre = "pata_i", tipo = "pata", parte = "", pos = Vector3.new(-1.3, 0.8, 1.1), r = 1.0 },
		{ nombre = "pata_d", tipo = "pata", parte = "", pos = Vector3.new(1.3, 0.8, 1.1), r = 1.0 },
		{ nombre = "cola", tipo = "cola", parte = "", pos = Vector3.new(0, 2.1, 3.2), r = 1.0 },
	},
	radioIsla = 92,
	evitar = { { 0, -88, 27 }, { -58, 5, 17 }, { 68, -48, 11 }, { -72, -52, 11 } }, -- la pirámide, la cancha y los templetes
	patrulla = { Vector2.new(0, -55), Vector2.new(45, -30), Vector2.new(-45, -25), Vector2.new(30, 30), Vector2.new(-35, 35), Vector2.new(0, 0), Vector2.new(50, -70), Vector2.new(-45, -75) },
	recompensa = {
		monedas = 360, base = "pelaje_xib", nombreBase = "Pelajes de Xibalbá",
		partes = { orejas = { "oreja_eco", "Orejas de eco" }, alas = { "membrana", "Membranas nocturnas" }, colmillos = { "colmillo_v", "Colmillos vampiro" } },
	},
}

-- ---------- cuerpo ----------
-- Pose de reposo: el torso se inclina hacia arriba y camina sobre las muñecas (como un murciélago
-- vampiro), con los codos asomando por encima de la espalda y las alas plegadas como una capa.
local TORSO_CF = CFrame.new(0, 3.3 * S, 0.4 * S) * CFrame.Angles(0.3, 0, 0)

local function construirAla(self, torso, lado: number)
	local L = lado < 0 and "I" or "D"
	local C = Poses.CAMAZOTZ
	local c0 = Poses.alaCamazotz(lado, 0, nil, S)
	local largos = C.largos
	-- huesos del ala
	local brazo = self:_parte({ Name = "Brazo" .. L, Size = V(0.95, largos.Brazo, 0.95), Color = HUESO })
	self:_unir(brazo, torso, c0["Hombro" .. L], CF(0, largos.Brazo / 2, 0), "Hombro" .. L)
	local ante = self:_parte({ Name = "Antebrazo" .. L, Size = V(0.75, largos.Antebrazo, 0.75), Color = HUESO })
	self:_unir(ante, brazo, c0["Codo" .. L], CF(0, largos.Antebrazo / 2, 0), "Codo" .. L)
	local mano = self:_parte({ Name = "Mano" .. L, Size = V(1.0, largos.Mano, 1.1), Color = HUESO, CanCollide = true })
	self:_unir(mano, ante, c0["Muneca" .. L], CF(0, largos.Mano / 2, 0), "Muneca" .. L)
	-- el codo: una púa de hueso que asoma sobre la espalda
	self:_pieza(ante, "Codo", V(1.05, 0.9, 1.05), HUESO, CF(0, largos.Antebrazo / 2 - 0.2, 0))
	self:_pieza(ante, "PuaCodo", V(0.5, 1.2, 0.5), MARFIL, CF(0, largos.Antebrazo / 2 + 0.6, 0.1) * CFrame.Angles(0.25, 0, 0))
	-- brazalete de oro con jade en la muñeca
	self:_pieza(ante, "Brazalete", V(1.0, 0.55, 1.0), ORO, CF(0, -largos.Antebrazo / 2 + 0.7, 0))
	self:_pieza(ante, "BrazaleteJade", V(1.05, 0.2, 1.05), JADE, CF(0, -largos.Antebrazo / 2 + 0.7, 0), { Neon = true })
	-- pulgar con garra (es el "pie" cuando camina)
	self:_pieza(mano, "Pulgar", V(0.45, 0.9, 0.45), HUESO, CF(0, -0.55, 0))
	self:_pieza(mano, "Garra", V(0.32, 0.55, 0.32), MARFIL, CF(0, -1.05, 0.12) * CFrame.Angles(-0.5, 0, 0))
	-- membrana del brazo y del antebrazo (borde de atrás = +Z)
	self:_grupo("alas", self:_pieza(brazo, "Membrana", V(0.14, largos.Brazo * 0.95, 2.6), MEMBRANA, CF(0, 0, 1.6)))
	self:_grupo("alas", self:_pieza(ante, "Membrana", V(0.14, 2.2, 3.6), MEMBRANA, CF(0, 2.1, 2.1)))
	self:_grupo("alas", self:_pieza(ante, "Membrana", V(0.14, 2.2, 3.2), MEMBRANA2, CF(0, 0, 1.9)))
	self:_grupo("alas", self:_pieza(ante, "Membrana", V(0.14, 2.2, 2.6), MEMBRANA, CF(0, -2.1, 1.6)))
	-- venas de la membrana (un poco más claras)
	self:_grupo("alas", self:_pieza(ante, "Vena", V(0.18, 0.18, 3.2), HUESO2, CF(0, 1.0, 2.0)))
	self:_grupo("alas", self:_pieza(ante, "Vena", V(0.18, 0.18, 2.8), HUESO2, CF(0, -1.1, 1.8)))
	-- los tres dedos largos con anillos de oro; sus membranas se pliegan con bisagras
	for _, nombre in { "Dedo1", "Dedo2", "Dedo3" } do
		local largo = largos[nombre]
		local dedo = self:_parte({ Name = nombre .. L, Size = V(0.42, largo, 0.42), Color = HUESO2 })
		self:_unir(dedo, mano, c0[nombre .. L], CF(0, largo / 2, 0), nombre .. L)
		self:_pieza(dedo, "Punta", V(0.3, 0.55, 0.3), MARFIL, CF(0, -largo / 2 - 0.22, 0))
		self:_pieza(dedo, "Anillo", V(0.55, 0.3, 0.55), ORO, CF(0, largo / 2 - 0.5, 0))
		for k, m in C.membranas[nombre] do
			local ancho = m[2]
			local color = k == 2 and MEMBRANA2 or MEMBRANA
			local placa = self:_parte({ Name = "Membrana", Size = V(0.12, largo / 3 + 0.1, ancho), Color = color })
			self:_unir(placa, dedo, Poses.membranaCamazotz(largo, m[1], 0, S), CF(0, 0, -ancho / 2), "Mem" .. nombre .. L .. k)
			self:_grupo("alas", placa)
			-- glifos de Xibalbá pintados en la cara de afuera (se encienden de noche)
			if k >= 2 and nombre ~= "Dedo3" then
				local glifo = self:_pieza(placa, "Glifo", V(0.05, 0.45, 0.45), GLIFO, CF(lado * 0.08, 0, ancho * 0.1), { Neon = true, Transparency = 0.6 })
				self:_grupo("glifosAlas", glifo)
				self:_grupo("alas", glifo)
			end
		end
	end
	return brazo, ante, mano
end

function def.construir(self)
	local raiz = self.raiz
	local torso = self:_parte({ Name = "Torso", Size = V(3.0, 2.6, 4.2), Color = PELO, CanCollide = true })
	self:_unir(torso, raiz, TORSO_CF, nil, "RaizCuerpo")
	-- pelaje: lomo más claro, manto en el pecho y vientre
	self:_pieza(torso, "Lomo", V(2.6, 0.6, 3.6), PELO2, CF(0, 1.35, 0.2))
	self:_pieza(torso, "Manto", V(3.3, 2.3, 1.4), MANTO, CF(0, 0.05, -1.75))
	self:_pieza(torso, "MantoBajo", V(2.5, 0.9, 1.0), MANTO, CF(0, -1.3, -1.6))
	self:_pieza(torso, "Vientre", V(2.3, 0.5, 3.2), rgb(70, 44, 68), CF(0, -1.38, 0.5))
	for i, z in { -0.6, 0.6, 1.7 } do
		self:_pieza(torso, "Mechon", V(0.5, 0.5, 0.7), PELO2, CF((i % 2 == 0 and 0.5 or -0.5), 1.75, z))
	end
	-- collar de oro y cuentas de jade
	self:_pieza(torso, "Collar", V(3.4, 0.55, 0.6), ORO, CF(0, 0.85, -2.35))
	self:_pieza(torso, "CollarLado", V(0.5, 0.55, 1.5), ORO2, CF(-1.6, 0.85, -1.75))
	self:_pieza(torso, "CollarLado", V(0.5, 0.55, 1.5), ORO2, CF(1.6, 0.85, -1.75))
	for i = -2, 2 do
		self:_pieza(torso, "Cuenta", V(0.42, 0.42, 0.3), JADE, CF(i * 0.62, 0.35 - math.abs(i) * 0.12, -2.55), { Neon = i == 0 })
	end
	self:_pieza(torso, "Pectoral", V(0.9, 0.9, 0.2), ORO, CF(0, -0.35, -2.55))
	self:_pieza(torso, "PectoralJade", V(0.45, 0.45, 0.1), JADE, CF(0, -0.35, -2.68), { Neon = true })
	-- glifos de la espalda (se encienden en la Noche de Xibalbá)
	for _, g in { { -0.7, -0.5 }, { 0.7, 0.3 }, { 0, 1.1 }, { -0.6, 1.8 }, { 0.6, 1.8 } } do
		self:_grupo("glifos", self:_pieza(torso, "Glifo", V(0.45, 0.1, 0.45), GLIFO, CF(g[1], 1.68, g[2]), { Neon = true, Transparency = 0.6 }))
	end
	-- ---------- cabeza ----------
	local K = 1.25 -- la cabeza es grande: es lo primero que ve el cazador
	local function HV(x, y, z)
		return V(x * K, y * K, z * K)
	end
	local function HCF(x, y, z)
		return CF(x * K, y * K, z * K)
	end
	local cabeza = self:_parte({ Name = "Cabeza", Size = HV(2.5, 2.2, 2.3), Color = PELO })
	self:_unir(cabeza, torso, CF(0, 0.5, -2.2) * CFrame.Angles(-0.2, 0, 0), HCF(0, 0.2, 1.0), "Cuello")
	self:_pieza(cabeza, "Frente", HV(2.3, 0.5, 2.0), PELO2, HCF(0, 1.2, 0.1))
	self:_pieza(cabeza, "Mejilla", HV(0.4, 1.2, 1.4), MANTO, HCF(-1.35, -0.35, -0.2))
	self:_pieza(cabeza, "Mejilla", HV(0.4, 1.2, 1.4), MANTO, HCF(1.35, -0.35, -0.2))
	local hocico = self:_pieza(cabeza, "Hocico", HV(1.6, 1.15, 1.2), PIEL, HCF(0, -0.4, -1.6))
	-- la hoja nasal: la marca de Camazotz, el murciélago de la muerte
	self:_pieza(hocico, "Herradura", HV(1.15, 0.3, 0.3), PIEL2, HCF(0, 0.3, -0.62))
	self:_pieza(hocico, "HojaNasal", HV(0.85, 0.75, 0.2), PIEL2, HCF(0, 0.8, -0.58) * CFrame.Angles(0.15, 0, 0))
	self:_pieza(hocico, "HojaPunta", HV(0.45, 0.45, 0.18), PIEL2, HCF(0, 1.3, -0.5) * CFrame.Angles(0.15, 0, 0))
	for _, lado in { -1, 1 } do
		self:_pieza(hocico, "Fosa", HV(0.25, 0.2, 0.1), rgb(20, 10, 16), HCF(lado * 0.28, 0.0, -0.62))
	end
	local mandibula = self:_parte({ Name = "Mandibula", Size = HV(1.4, 0.45, 1.3), Color = PIEL })
	self:_unir(mandibula, cabeza, HCF(0, -1.2, -0.6), HCF(0, 0, 0.65), "Mandibula") -- bisagra atrás
	self:_pieza(mandibula, "Lengua", HV(0.8, 0.12, 0.9), rgb(150, 40, 60), HCF(0, 0.25, -0.1))
	for _, lado in { -1, 1 } do
		-- ojos rojos con ceño
		self:_pieza(cabeza, "Ojo", HV(0.52, 0.34, 0.12), OJO, HCF(lado * 0.62, 0.3, -1.17), { Neon = true })
		self:_pieza(cabeza, "Ceno", HV(0.75, 0.25, 0.3), PELO2, HCF(lado * 0.6, 0.6, -1.12) * CFrame.Angles(0, 0, lado * 0.3))
		-- colmillos
		self:_grupo("colmillos", self:_pieza(hocico, "Colmillo", HV(0.3, 0.95, 0.3), MARFIL, HCF(lado * 0.42, -0.85, -0.38)))
		self:_grupo("colmillos", self:_pieza(hocico, "Diente", HV(0.18, 0.4, 0.18), MARFIL, HCF(lado * 0.16, -0.65, -0.5)))
		self:_grupo("colmillos", self:_pieza(mandibula, "Colmillo", HV(0.24, 0.55, 0.24), MARFIL, HCF(lado * 0.3, 0.45, -0.45)))
		-- orejas enormes y puntiagudas con jade por dentro y orejeras de oro
		local oreja = self:_parte({ Name = "Oreja", Size = HV(0.42, 1.2, 1.8), Color = PELO })
		self:_unir(oreja, cabeza, HCF(lado * 1.0, 1.15, 0.15) * CFrame.Angles(-0.12, 0, -lado * 0.32), HCF(0, -0.6, 0), "Oreja" .. (lado < 0 and "I" or "D"))
		self:_grupo("orejas", oreja)
		self:_grupo("orejas", self:_pieza(oreja, "Medio", HV(0.38, 1.1, 1.5), PELO, HCF(0, 1.1, 0.08)))
		self:_grupo("orejas", self:_pieza(oreja, "Alto", HV(0.34, 0.9, 1.0), PELO2, HCF(0, 2.05, 0.15)))
		self:_grupo("orejas", self:_pieza(oreja, "Punta", HV(0.3, 0.7, 0.4), PELO2, HCF(0, 2.8, 0.2)))
		self:_grupo("orejas", self:_pieza(oreja, "Interior", HV(0.1, 2.4, 0.5), JADE, HCF(-lado * 0.2, 1.1, -0.15), { Neon = true }))
		self:_grupo("orejas", self:_pieza(oreja, "Orejera", HV(0.25, 0.85, 0.85), ORO, HCF(lado * 0.3, 0.1, 0.1), { Forma = Enum.PartType.Cylinder }))
		self:_grupo("orejas", self:_pieza(oreja, "OrejeraJade", HV(0.28, 0.4, 0.4), JADE, HCF(lado * 0.32, 0.1, 0.1), { Forma = Enum.PartType.Cylinder, Neon = true }))
	end
	-- diadema de oro con el glifo del murciélago
	self:_pieza(cabeza, "Diadema", HV(2.6, 0.4, 0.3), ORO, HCF(0, 0.85, -1.15))
	self:_pieza(cabeza, "DiademaPlaca", HV(0.9, 0.9, 0.18), ORO, HCF(0, 1.25, -1.22))
	self:_pieza(cabeza, "DiademaGlifo", HV(0.45, 0.45, 0.08), JADE, HCF(0, 1.25, -1.33), { Neon = true })
	-- ---------- alas ----------
	construirAla(self, torso, -1)
	construirAla(self, torso, 1)
	-- ---------- patas traseras y cola ----------
	for _, lado in { -1, 1 } do
		local L = lado < 0 and "I" or "D"
		local muslo = self:_parte({ Name = "Muslo" .. L, Size = V(0.9, 1.2, 1.0), Color = PELO })
		self:_unir(muslo, torso, CF(lado * 1.05, -1.0, 1.6) * CFrame.Angles(0.5, 0, lado * 0.3), CF(0, 0.55, 0), "Cadera" .. L)
		local pierna = self:_parte({ Name = "Pierna" .. L, Size = V(0.6, 1.0, 0.7), Color = PELO2 })
		self:_unir(pierna, muslo, CF(0, -0.55, 0) * CFrame.Angles(-1.1, 0, -lado * 0.25), CF(0, 0.45, 0), "Rodilla" .. L)
		local pie = self:_pieza(pierna, "Pie", V(0.9, 0.35, 1.0), HUESO, CF(0, -0.55, -0.2) * CFrame.Angles(0.3, 0, 0))
		for k = -1, 1 do
			self:_pieza(pie, "Garra", V(0.16, 0.2, 0.45), MARFIL, CF(k * 0.3, -0.05, -0.65))
		end
	end
	local cola = self:_parte({ Name = "Cola", Size = V(0.5, 0.5, 1.6), Color = PELO })
	self:_unir(cola, torso, CF(0, -0.6, 2.4) * CFrame.Angles(-0.5, 0, 0), CF(0, 0, -0.7), "Cola")
	self:_grupo("alas", self:_pieza(cola, "Uropatagio", V(2.4, 0.12, 1.3), MEMBRANA, CF(0, 0, -0.1)))
	-- el enjambre: murciélagos pequeños que salen en la Noche de Xibalbá
	self.murcielagos = {}
	for i = 1, 6 do
		local b = Instance.new("Model")
		b.Name = "Murcielago"
		local function pieza(nombre, tam, color, neon)
			local p = Instance.new("Part")
			p.Name = nombre
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Color = color
			p.Size = tam
			p.Transparency = 1
			if neon then
				p.Material = Enum.Material.Neon
			end
			p.Parent = b
			return p
		end
		local cuerpo = pieza("Cuerpo", V(0.55, 0.45, 0.7), PELO)
		for _, lado in { -1, 1 } do
			pieza("Ala", V(1.2, 0.08, 0.6), MEMBRANA):SetAttribute("Lado", lado)
		end
		pieza("Ojo", V(0.32, 0.1, 0.1), OJO, true)
		b.PrimaryPart = cuerpo
		b.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		b.Parent = workspace
		self.murcielagos[i] = { modelo = b, pos = Vector3.zero, vel = Vector3.zero, golpes = {} }
	end
end

local function mostrarMurcielago(m, visible: boolean, cf: CFrame?, aleteo: number?)
	for _, p in m.modelo:GetChildren() do
		if p:IsA("BasePart") then
			p.Transparency = visible and 0 or 1
			if visible and cf then
				if p.Name == "Cuerpo" then
					p.CFrame = cf
				elseif p.Name == "Ojo" then
					p.CFrame = cf * CFrame.new(0, 0.1 * S, -0.3 * S)
				else
					local lado = p:GetAttribute("Lado") or 1
					p.CFrame = cf * CFrame.new(lado * 0.7 * S, 0, 0) * CFrame.Angles(0, 0, lado * math.sin(aleteo or 0) * 0.8)
				end
			end
		end
	end
end

function def.ocultarExtras(self)
	for _, m in self.murcielagos or {} do
		mostrarMurcielago(m, false)
	end
end

-- ---------- qué ataque elegir ----------
function def.elegir(self, dist, ang, o)
	local orejas = not self.partes.orejas.rota
	if dist < 8 and ang < 0.7 then
		o("zarpazo", 3)
		o("mordida", self.partes.colmillos.rota and 1 or 2.2)
	end
	if dist < 12 then
		o("onda", 1.6)
	end
	if dist > 6 and dist < 24 and ang < 0.5 then
		o("grito", orejas and 2.4 or 1.2)
	end
	if not self.partes.alas.rota and dist > 10 and dist < 40 and self:_hace("picada") > 6 then
		o("picada", 2)
	end
	if self.fase2 and dist < 35 and self:_hace("enjambre") > 14 then
		o("enjambre", 1.6)
	end
end

-- ---------- ataques ----------
function def.atacar(self, a, c)
	local fase, tf, dt = self.fase, c.tf, c.dt
	local adelante, objetivo = c.adelante, c.objetivo
	local orejas = not self.partes.orejas.rota
	if a == "zarpazo" then
		local punto = self.pos + adelante * 4.5 * S
		if fase == "prep" then
			if tf < c.prep - 0.4 then
				self:_girarHacia(self:_yawHacia(objetivo), 2.8, dt)
			end
			self:_avisoCirculo(punto, 4.2)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(punto, 30)
			self:_golpear(function(p)
				return plano(p, punto) < 4.2
			end, punto)
		end
	elseif a == "mordida" then
		local punto = self.pos + adelante * 5 * S
		if fase == "prep" then
			if tf < c.prep - 0.4 then
				self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			end
			self:_avisoCirculo(punto, 3)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			local colmillos = not self.partes.colmillos.rota
			local alcanzados = self:_golpear(function(p)
				return plano(p, punto) < 3
			end, punto, colmillos and 1 or 0.75)
			if alcanzados and colmillos then
				-- la mordida vampira: se cura un poco por cada cazador mordido
				self:_curar(self.vidaMax * 0.02 * #alcanzados)
				self.servicios.numero(self.raiz.Position + Vector3.new(0, 20, 0), "+" .. math.floor(self.vidaMax * 0.02 * #alcanzados), rgb(120, 255, 140))
			end
		end
	elseif a == "grito" then
		local largo = orejas and 22 or 14
		local desde = self.pos + adelante * 3 * S
		if fase == "prep" then
			if tf < c.prep - 0.55 then
				self:_girarHacia(self:_yawHacia(objetivo), 1.6, dt)
			end
			self:_avisoRect(desde, self.yaw, orejas and 8 or 6, largo)
		elseif fase == "activo" then
			-- dentro del rectángulo rojo: lo mismo que se mostró es lo que golpea y aturde
			local function dentro(p)
				local rel = Vector3.new(p.X - desde.X, 0, p.Z - desde.Z) / S
				local aLoLargo = rel:Dot(adelante)
				local alLado = math.abs(rel:Cross(adelante).Y)
				return aLoLargo > -1 and aLoLargo < largo and alLado < (orejas and 4 or 3)
			end
			if not self.hecho then
				self.hecho = true
				self:_ocultarAvisos()
				-- ondas sónicas: aros que salen de la boca y crecen hacia adelante
				local boca = self.pos + adelante * 4.5 * S + Vector3.new(0, 3.6 * S, 0)
				for k = 1, 5 do
					task.delay(k * 0.1, function()
						local centro = boca + adelante * (k * largo / 5) * S - Vector3.new(0, k * 0.5 * S, 0)
						local tam = (2 + k * (orejas and 1.3 or 0.9)) * S
						local aro = self:_efecto(CFrame.lookAt(centro, centro + adelante) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.3 * S, tam, tam), rgb(170, 240, 255), 0.3, Enum.PartType.Cylinder)
						aro.Transparency = 0.55
					end)
				end
				if orejas then
					for _, j in self:jugadores() do
						local char = j.jugador.Character
						if j.atacable and dentro(j.hrp.Position) and not (char and (char:GetAttribute("Mod_sinAturdir") or 0) > 0) then
							Remotos.Aturdir:FireClient(j.jugador, 0.9)
						end
					end
				end
			end
			self:_golpear(dentro, desde, orejas and 1 or 0.7)
		end
	elseif a == "onda" then
		local radio = orejas and 11 or 7
		if fase == "prep" then
			self:_avisoCirculo(self.pos, radio)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_anillo(self.pos, radio, rgb(170, 240, 255), 0.45)
			self:_golpear(function(p)
				return plano(p, self.pos) < radio
			end, self.pos)
			if orejas then
				self:_aturdir(self.pos, radio, 0.6)
			end
		end
	elseif a == "picada" then
		if fase == "prep" then
			-- se eleva con las alas abiertas mientras sigue a su presa
			self.altoExtra = math.min(1, tf / c.prep) * 9 * S
			self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			if tf < c.prep - 0.25 then
				self.datosAtaque.desde = self.pos
				self.datosAtaque.hasta = self:_limitar(objetivo)
			end
			self:_avisoCirculo(self.datosAtaque.hasta or self.pos, 5)
		elseif fase == "activo" then
			local d = self.datosAtaque
			local k = math.clamp(tf / c.act, 0, 1)
			local p = d.desde:Lerp(d.hasta, k)
			self:_ponerEn(p)
			self.altoExtra = (1 - k * k) * 9 * S
			self.yVisual = self.pos.Y + self.altoExtra
			return false
		elseif fase == "rec" and not self.hecho then
			self.hecho = true
			self.altoExtra = 0
			self:_ocultarAvisos()
			self:_polvo(self.pos, 60)
			self:_anillo(self.pos, 5, rgb(120, 100, 140), 0.35)
			self:_golpear(function(p)
				return plano(p, self.pos) < 5
			end, self.pos)
		end
	elseif a == "enjambre" then
		-- los murciélagos salen, rodean a Camazotz y se lanzan en picada de uno en uno sobre los
		-- cazadores; cada picada marca antes su círculo rojo (se esquiva saliendo de él o rodando)
		local ms = self.murcielagos
		local function orbita(i)
			local ang = self.reloj * 2.2 + i / #ms * math.pi * 2
			return self.pos + Vector3.new(math.cos(ang) * 4 * S, (6.5 + math.sin(self.reloj * 3 + i) * 0.6) * S, math.sin(ang) * 4 * S)
		end
		if fase == "prep" then
			if not self.hecho then
				self.hecho = true
				for i, m in ms do
					m.pos = self.pos + Vector3.new(0, 4 * S, 0)
					m.estado = "orbita"
					m.golpes = {}
				end
			end
			for i, m in ms do
				local k = math.min(1, tf / c.prep)
				m.pos = m.pos:Lerp(orbita(i), math.min(1, dt * 6))
				mostrarMurcielago(m, true, CFrame.new(m.pos) * CFrame.Angles(0, -self.reloj * 2.2 - i, 0), self.reloj * 22 + i + k)
			end
		elseif fase == "activo" then
			local js = self:jugadores()
			for i, m in ms do
				local salida = 0.15 + (i - 1) * (c.act - 0.9) / math.max(1, #ms - 1)
				if m.estado == "orbita" and tf >= salida then
					-- elige al cazador más cercano y marca dónde va a caer
					local mejor, mejorD = nil, math.huge
					for _, j in js do
						if j.atacable then
							local dd = plano(j.hrp.Position, m.pos)
							if dd < mejorD then
								mejor, mejorD = j, dd
							end
						end
					end
					if mejor then
						m.estado = "picada"
						m.t = 0
						m.desde = m.pos
						m.hasta = self:suelo(mejor.hrp.Position) + Vector3.new(0, 1.5 * S, 0)
						local aviso = self.avisosExtra[i]
						aviso.Transparency = 0.4
						aviso.Size = Vector3.new(0.3, 2.4 * 2 * S, 2.4 * 2 * S)
						aviso.CFrame = CFrame.new(m.hasta.X, self:altura(m.hasta.X, m.hasta.Z) + 0.35, m.hasta.Z) * CFrame.Angles(0, 0, math.rad(90))
					else
						m.estado = "vuelta"
					end
				end
				if m.estado == "orbita" then
					m.pos = m.pos:Lerp(orbita(i), math.min(1, dt * 6))
					mostrarMurcielago(m, true, CFrame.new(m.pos) * CFrame.Angles(0, -self.reloj * 2.2 - i, 0), self.reloj * 22 + i)
				elseif m.estado == "picada" then
					-- vuela en arco hasta el círculo y muerde al llegar
					m.t += dt
					local k = math.clamp(m.t / 0.6, 0, 1)
					local p = m.desde:Lerp(m.hasta, k) + Vector3.new(0, math.sin(k * math.pi) * 2 * S, 0)
					local dir = p - m.pos
					m.pos = p
					mostrarMurcielago(m, true, CFrame.lookAt(p, p + (dir.Magnitude > 0.01 and dir or Vector3.new(0, -1, 0))), self.reloj * 30 + i)
					if k >= 1 then
						m.estado = "vuelta"
						m.t = 0
						self.avisosExtra[i].Transparency = 1
						self:_polvo(m.hasta, 10, rgb(90, 60, 110))
						for _, j in js do
							if j.atacable and not m.golpes[j.hrp] and plano(j.hrp.Position, m.hasta) < 2.4 then
								m.golpes[j.hrp] = true
								self.servicios.danio(j.jugador, def.ataques.enjambre.danio * (self.furioso and 1.15 or 1), m.hasta, def.ataques.enjambre.empuje, "camazotz_enjambre")
							end
						end
					end
				elseif m.estado == "vuelta" then
					-- vuelve a rodear a Camazotz
					m.pos = m.pos:Lerp(orbita(i), math.min(1, dt * 3))
					mostrarMurcielago(m, true, CFrame.new(m.pos) * CFrame.Angles(0, -self.reloj * 2.2 - i, 0), self.reloj * 22 + i)
				end
			end
		else
			-- los murciélagos se dispersan hacia el cielo
			for i, m in ms do
				m.pos += Vector3.new(math.cos(i) * 0.4, 1.2, math.sin(i) * 0.4) * S * dt * 8
				mostrarMurcielago(m, tf < c.rec - 0.1, CFrame.new(m.pos), self.reloj * 26 + i)
			end
		end
	end
	return true
end

-- ---------- fases y partes ----------
function def.alFase2(self)
	for _, x in self.grupos.glifos or {} do
		x[1].Transparency = 0
		x[1].Color = rgb(120, 255, 240)
	end
	if not self.partes.alas.rota then
		for _, x in self.grupos.glifosAlas or {} do
			x[1].Transparency = 0
			x[1].Color = rgb(120, 255, 240)
		end
	end
	workspace:SetAttribute("NocheXibalba", true)
end

function def.alReiniciar(self)
	workspace:SetAttribute("NocheXibalba", false)
end

function def.alRomper(self, id)
	if id == "alas" then
		self.servicios.anunciar("¡Camazotz ya no puede volar!", rgb(200, 140, 255))
	elseif id == "orejas" then
		self.servicios.anunciar("¡Sus gritos pierden fuerza!", rgb(200, 140, 255))
	end
end

-- la cabeza es su punto débil mientras grita
function def.debil(self, z)
	return z.tipo == "cabeza" and self.estado == "ataque" and self.ataque == "grito" and self.fase == "activo"
end

local Camazotz = {}
function Camazotz.nuevo(servicios)
	return Base.nuevo(def, servicios)
end
Camazotz.def = def
return Camazotz
