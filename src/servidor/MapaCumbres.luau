--!nonstrict
-- Las Cumbres del Inti: terrazas de cultivo, ruinas incas, la cueva de Amaru y montañas nevadas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)
local Mundo = require(script.Parent.Mundo)

local S = Config.S
local C = Config.COLORES
local Mapa = {}
local carpeta: Folder
-- el mismo generador arma las Cumbres del Inti y las Cuevas del Uku Pacha (cada una con su centro)
local CENTRO = Config.CUMBRES
local ESTILO = "cumbres"
local CAMPAMENTO = Config.CUMBRES_CAMPAMENTO
local function alturaM_(x: number, z: number): number
	return Config.alturaMontana(CENTRO, x, z)
end
local function sueloM(xm: number, zm: number, sobre: number?): Vector3
	return Config.sueloMontana(CENTRO, xm, zm, sobre)
end

local function parte(props)
	props.Parent = props.Parent or carpeta
	return Mundo.parte(props)
end

-- un bloque medido en metros (esquina inferior en xm, ym, zm), relativo al centro de las Cumbres
local function bloqueM(xm, ym, zm, w, h, d, color, props)
	local t = {
		Name = "Cumbres",
		Size = Vector3.new(w * S, h * S, d * S),
		Position = CENTRO + Vector3.new((xm + w / 2) * S, (ym + h / 2) * S, (zm + d / 2) * S),
		Color = color,
	}
	for k, v in props or {} do
		t[k] = v
	end
	return parte(t)
end

local function alturaM(xm, zm)
	local p = sueloM(xm, zm)
	return p.Y / S
end

-- ---------- terreno de bloques ----------
local function terreno()
	local V = Config.VOX_CUMBRES
	local N = 130
	local ORIGEN = -N * V / 2
	local BASE = -30
	local VERDES = { Color3.fromRGB(104, 164, 76), Color3.fromRGB(88, 148, 64), Color3.fromRGB(120, 176, 84) }
	local ROCA = { Color3.fromRGB(128, 122, 116), Color3.fromRGB(112, 106, 100) }
	local NIEVE = Color3.fromRGB(240, 244, 248)
	if ESTILO == "cuevas" then
		VERDES = { Color3.fromRGB(72, 64, 86), Color3.fromRGB(60, 54, 72), Color3.fromRGB(84, 76, 98) }
		ROCA = { Color3.fromRGB(52, 46, 62), Color3.fromRGB(42, 38, 52) }
		NIEVE = Color3.fromRGB(34, 30, 44)
	end
	local alto, clave, colores = {}, {}, {}
	for i = 1, N do
		alto[i], clave[i], colores[i] = {}, {}, {}
		for k = 1, N do
			local x = CENTRO.X + ORIGEN + (i - 0.5) * V
			local z = CENTRO.Z + ORIGEN + (k - 0.5) * V
			local h = alturaM_(x, z)
			local nivel = h // V
			local tipo, color
			if h > 42 * S then
				tipo, color = "n", NIEVE
			elseif h > 16 * S then
				tipo, color = "r" .. (nivel % 2), ROCA[nivel % 2 + 1]
			else
				tipo, color = "v" .. (nivel % 3), VERDES[nivel % 3 + 1]
			end
			alto[i][k] = h
			clave[i][k] = h .. tipo
			colores[i][k] = color
		end
	end
	local usado = {}
	for i = 1, N do
		usado[i] = {}
	end
	for k = 1, N do
		for i = 1, N do
			if not usado[i][k] then
				local c = clave[i][k]
				local ancho = 1
				while i + ancho <= N and not usado[i + ancho][k] and clave[i + ancho][k] == c do
					ancho += 1
				end
				local largo = 1
				local sigue = true
				while sigue and k + largo <= N do
					for ii = i, i + ancho - 1 do
						if usado[ii][k + largo] or clave[ii][k + largo] ~= c then
							sigue = false
							break
						end
					end
					if sigue then
						largo += 1
					end
				end
				for ii = i, i + ancho - 1 do
					for kk = k, k + largo - 1 do
						usado[ii][kk] = true
					end
				end
				local h = alto[i][k]
				parte({
					Name = "Suelo", Size = Vector3.new(ancho * V, h - BASE, largo * V),
					Position = CENTRO + Vector3.new(ORIGEN + (i - 1 + ancho / 2) * V, (h + BASE) / 2, ORIGEN + (k - 1 + largo / 2) * V),
					Color = Mundo.matiz(colores[i][k]),
				})
			end
		end
	end
end

-- ---------- decoración ----------
local PIEDRA = { Color3.fromRGB(150, 140, 126), Color3.fromRGB(136, 126, 112), Color3.fromRGB(164, 154, 138) }

local function muroInca(xm, zm, largo, alto, girado)
	local base = alturaM(xm, zm)
	for f = 0, alto - 1 do
		local x = 0
		while x < largo do
			local ancho = math.min(largo - x, 1.2 + ((x * 7 + f * 3) % 3) * 0.5)
			if girado then
				bloqueM(xm, base + f * 1.1, zm + x, 1.4, 1.05, ancho - 0.05, PIEDRA[(f + math.floor(x)) % 3 + 1])
			else
				bloqueM(xm + x, base + f * 1.1, zm, ancho - 0.05, 1.05, 1.4, PIEDRA[(f + math.floor(x)) % 3 + 1])
			end
			x += ancho
		end
	end
end

local function quenua(xm, zm)
	local base = alturaM(xm, zm)
	for i = 0, 3 do
		bloqueM(xm + (i % 2) * 0.2, base + i, zm, 0.7, 1, 0.7, i % 2 == 0 and Color3.fromRGB(170, 80, 50) or Color3.fromRGB(150, 66, 40))
	end
	for _, o in { { 0, 0 }, { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 }, { 0.5, 0.5 } } do
		bloqueM(xm - 0.6 + o[1] * 1.1, base + 4 + math.abs(o[1] * o[2]) * 0.6, zm - 0.6 + o[2] * 1.1, 1.6, 1.1, 1.6, Color3.fromRGB(80, 120, 60), { CanCollide = false })
	end
end

local function campamento(): CFrame
	local c = CAMPAMENTO
	local base = alturaM(c.X, c.Y)
	local fogata = bloqueM(c.X - 1, base, c.Y - 1, 2, 0.4, 2, Color3.fromRGB(70, 60, 55))
	bloqueM(c.X - 0.5, base + 0.4, c.Y - 0.5, 1, 0.6, 1, Color3.fromRGB(255, 140, 50), { Material = Enum.Material.Neon, CanCollide = false })
	local fuego = Instance.new("Fire")
	fuego.Size = 7
	fuego.Parent = fogata
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 170, 90)
	luz.Range = 30
	luz.Parent = fogata
	for _, lado in { -1, 1 } do
		for n = 0, 3 do
			bloqueM(c.X + lado * 7 - 1.8 + n * 0.4, base + n * 0.6, c.Y - 3, 3.6 - n * 0.8, 0.6, 3.6, n % 2 == 0 and Color3.fromRGB(180, 60, 50) or Color3.fromRGB(230, 200, 120))
		end
	end
	local caravana = bloqueM(c.X - 3, base, c.Y + 4, 1.2, 1.2, 2.4, Color3.fromRGB(200, 150, 90))
	caravana.Name = "Caravana"
	local volver = Instance.new("ProximityPrompt")
	volver.Name = "VolverRefugio"
	volver.ActionText = "Volver al Refugio"
	volver.ObjectText = "Caravana"
	volver.MaxActivationDistance = 12
	volver.RequiresLineOfSight = false
	volver.GamepadKeyCode = Enum.KeyCode.ButtonL1 -- X es el ataque en la cacería
	volver.Parent = caravana
	return CFrame.new(sueloM(c.X, c.Y + 3, 4))
end

local function cristal(xm, zm, rng)
	local base = alturaM(xm, zm)
	local col = rng:NextNumber() < 0.5 and Color3.fromRGB(170, 90, 255) or Color3.fromRGB(60, 230, 220)
	for k = 0, rng:NextInteger(2, 4) do
		local alto = rng:NextNumber(1.5, 4)
		local p = bloqueM(xm + rng:NextNumber(-1, 1), base, zm + rng:NextNumber(-1, 1), 0.6, alto, 0.6, col, { Material = Enum.Material.Neon, CanCollide = false })
		p.CFrame = p.CFrame * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4))
		local _ = k
	end
end

function Mapa.construir(centro: Vector3?, estilo: string?): CFrame
	CENTRO = centro or Config.CUMBRES
	ESTILO = estilo or "cumbres"
	CAMPAMENTO = Config.ISLAS[ESTILO].campamento
	carpeta = Instance.new("Folder")
	carpeta.Name = ESTILO == "cuevas" and "CuevasDelUkuPacha" or "CumbresDelInti"
	carpeta.Parent = workspace
	terreno()
	-- ruinas incas al norte: muros, un templo escalonado y la Puerta del Sol
	muroInca(-30, -40, 22, 3, false)
	muroInca(-30, -40, 14, 3, true)
	muroInca(8, -52, 18, 2, false)
	local tb = alturaM(-15, -70)
	for e = 0, 4 do
		bloqueM(-15 - (8 - e * 1.5), tb + e * 1.2, -70 - (6 - e * 1.1), 16 - e * 3, 1.2, 12 - e * 2.2, PIEDRA[e % 3 + 1])
	end
	bloqueM(-17, tb + 6, -71.5, 4, 3, 3, PIEDRA[1])
	bloqueM(-16, tb + 6.8, -71.7, 2, 1.4, 0.3, C.oro, { Material = Enum.Material.Neon })
	local pb = alturaM(10, -20)
	bloqueM(6, pb, -21, 1.6, 6, 1.6, PIEDRA[2])
	bloqueM(12.4, pb, -21, 1.6, 6, 1.6, PIEDRA[2])
	bloqueM(6, pb + 6, -21, 8, 1.6, 1.6, PIEDRA[1])
	bloqueM(9.2, pb + 6.2, -21.2, 1.6, 1.2, 0.2, C.oro, { Material = Enum.Material.Neon })
	-- la cueva de Amaru (una boca oscura en la montaña, al oeste)
	local cb = alturaM(-88, 10)
	bloqueM(-96, cb - 1, 2, 10, 12, 16, Color3.fromRGB(96, 90, 86))
	bloqueM(-90, cb, 5, 4.5, 8, 10, Color3.fromRGB(18, 14, 26))
	for g = 0, 3 do
		bloqueM(-85.6, cb + 1 + g * 1.8, 4.8 + (g % 2) * 8.5, 0.2, 0.8, 0.6, Color3.fromRGB(160, 76, 224), { Material = Enum.Material.Neon })
	end
	if ESTILO == "cuevas" then
		local rngC = Random.new(73)
		for _, p in { { 70, -20 }, { -40, -85 }, { 30, 80 } } do
			local cb2 = alturaM(p[1], p[2])
			bloqueM(p[1] - 5, cb2 - 1, p[2] - 3, 10, 12, 8, Color3.fromRGB(60, 54, 70))
			bloqueM(p[1] - 2, cb2, p[2] - 3.2, 4.5, 8, 0.4, Color3.fromRGB(14, 10, 22))
		end
		for _ = 1, 30 do
			cristal(rngC:NextNumber(-95, 95), rngC:NextNumber(-95, 80), rngC)
		end
		return campamento()
	end
	-- puente colgante entre dos torres de piedra
	local b1, b2 = alturaM(40, -30), alturaM(62, -30)
	local alto = math.max(b1, b2) + 5
	bloqueM(38, b1, -31, 2, alto - b1, 2, PIEDRA[1])
	bloqueM(62, b2, -31, 2, alto - b2, 2, PIEDRA[1])
	for t = 0, 11 do
		local caida = math.sin(t / 11 * math.pi) * 1.2
		bloqueM(40 + t * 1.85, alto - 0.3 - caida, -30.8, 1.7, 0.25, 1.6, t % 2 == 0 and Color3.fromRGB(150, 110, 70) or Color3.fromRGB(130, 94, 60))
	end
	bloqueM(40, alto + 0.7, -31.1, 22, 0.12, 0.12, Color3.fromRGB(200, 170, 110))
	bloqueM(40, alto + 0.7, -29.1, 22, 0.12, 0.12, Color3.fromRGB(200, 170, 110))
	-- árboles quenua, llamas y siembras de colores en las terrazas
	local rng = Random.new(21)
	for _ = 1, 14 do
		local x, z = rng:NextNumber(-90, 90), rng:NextNumber(-90, 70)
		if (Vector2.new(x, z) - CAMPAMENTO).Magnitude > 20 then
			quenua(x, z)
		end
	end
	for _ = 1, 40 do
		local x, z = rng:NextNumber(-80, 80), rng:NextNumber(-60, 80)
		local b = alturaM(x, z)
		if b < 16 then
			bloqueM(x, b, z, 1.2, 0.5, 1.2, ({ Color3.fromRGB(230, 140, 40), Color3.fromRGB(200, 60, 60), Color3.fromRGB(230, 200, 70) })[rng:NextInteger(1, 3)], { CanCollide = false })
		end
	end
	return campamento()
end

return Mapa
