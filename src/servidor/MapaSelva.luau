--!nonstrict
-- Las cuatro islas de la Selva de Obsidiana: terreno de bloques, ruinas mayas y mexicas, árboles
-- de la selva, luces y el campamento de cada una.
--   xibalba: el Templo de Xibalbá (Camazotz) · cenote: el Cenote Sagrado (Xolotl)
--   selva: la Selva de Obsidiana (Balam) · pantano: los Pantanos de Aztlán (Cipactli)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)
local Mundo = require(script.Parent.Mundo)
local Terreno = require(script.Parent.Terreno)

local S = Config.S
local V = Config.VOX
local rgb = Color3.fromRGB
local Mapa = {}

local NOMBRES = { xibalba = "TemploDeXibalba", cenote = "CenoteSagrado", selva = "SelvaDeObsidiana", pantano = "PantanosDeAztlan" }
Mapa.NOMBRES = NOMBRES

-- colores de la selva
local C = {
	musgo = rgb(52, 86, 50), musgo2 = rgb(40, 70, 42), hoja = rgb(46, 104, 52), hoja2 = rgb(34, 84, 44), hoja3 = rgb(62, 124, 60),
	tronco = rgb(78, 58, 44), tronco2 = rgb(64, 48, 38), ceiba = rgb(150, 150, 130), ceiba2 = rgb(128, 128, 112),
	piedra = rgb(118, 124, 110), piedra2 = rgb(98, 106, 94), piedraOscura = rgb(64, 70, 66), cal = rgb(184, 178, 156),
	jade = rgb(48, 220, 170), oro = rgb(232, 178, 60), fuego = rgb(255, 150, 60), fuegoMorado = rgb(190, 90, 255),
	tierra = rgb(70, 52, 38), liana = rgb(56, 92, 46), flor = rgb(230, 70, 110), hongo = rgb(120, 255, 200),
}
Mapa.C = C

local carpeta: Folder
local isla
local O: Vector3

local function b(pos: Vector3, tam: Vector3, color: Color3, props)
	local t = { Name = "Selva", Size = tam, Position = pos, Color = Mundo.matiz(color, 0.05), Parent = carpeta }
	for k, v in props or {} do
		t[k] = v
	end
	return Mundo.parte(t)
end

-- bloque orientado (cf en studs)
local function bc(cf: CFrame, tam: Vector3, color: Color3, props)
	local t = { Name = "Selva", Size = tam, CFrame = cf, Color = Mundo.matiz(color, 0.05), Parent = carpeta }
	for k, v in props or {} do
		t[k] = v
	end
	return Mundo.parte(t)
end

local function neon(p: BasePart)
	p.Material = Enum.Material.Neon
	p.CanCollide = false
	p.CastShadow = false
	return p
end

-- punto del suelo (metros relativos al centro de la isla)
local function suelo(xm: number, zm: number): Vector3
	local x, z = O.X + xm * S, O.Z + zm * S
	return Vector3.new(x, Config.alturaEn(x, z), z)
end

local function luz(padre: BasePart, color: Color3, rango: number, brillo: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = rango
	l.Brightness = brillo or 1.6
	l.Shadows = false
	l.Parent = padre
	return l
end

local function fuego(padre: BasePart, color: Color3, tam: number)
	local f = Instance.new("Fire")
	f.Size = tam
	f.Heat = tam * 1.2
	f.Color = color
	f.SecondaryColor = Color3.new(math.min(1, color.R * 1.2), math.min(1, color.G * 0.7), math.min(1, color.B * 0.6))
	f.Parent = padre
	return f
end

-- ---------- plantas ----------
-- árbol de la selva: tronco alto, ramas y copas en capas, con lianas colgando
local function arbol(p: Vector3, rng: Random, alto: number?)
	local h = (alto or rng:NextNumber(9, 15)) * S
	local g = rng:NextNumber(1.1, 1.6) * S
	b(p + Vector3.new(0, h / 2, 0), Vector3.new(g, h, g), C.tronco, { CanCollide = true })
	-- raíces
	for i = 0, 3 do
		local a = i * math.pi / 2 + rng:NextNumber(-0.3, 0.3)
		bc(CFrame.new(p + Vector3.new(math.cos(a) * g * 0.7, 1.2, math.sin(a) * g * 0.7)) * CFrame.Angles(0, -a, 0.4), Vector3.new(g * 0.9, 2.4, g * 0.4), C.tronco2)
	end
	-- copa en capas
	local copa = p + Vector3.new(0, h, 0)
	local verdes = { C.hoja, C.hoja2, C.hoja3 }
	for k = 0, 2 do
		local ancho = (4.8 - k * 1.2) * S * rng:NextNumber(0.85, 1.15)
		b(copa + Vector3.new(rng:NextNumber(-1, 1), k * 1.4 * S - 0.6 * S, rng:NextNumber(-1, 1)), Vector3.new(ancho, 1.4 * S, ancho * rng:NextNumber(0.8, 1.2)), verdes[k + 1], { CanCollide = false })
	end
	-- lianas
	for _ = 1, rng:NextInteger(1, 3) do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(2.4, 4) * S
		local largo = rng:NextNumber(3, 7) * S
		b(copa + Vector3.new(math.cos(a) * r, -0.8 * S - largo / 2, math.sin(a) * r), Vector3.new(0.35, largo, 0.35), C.liana, { CanCollide = false, CastShadow = false })
	end
end

-- ceiba sagrada: el árbol del mundo de los mayas, enorme, con raíces tablares y copa ancha
local function ceiba(p: Vector3, rng: Random, escala: number?)
	local k = escala or 1
	local h = 24 * S * k
	local g = 3.2 * S * k
	b(p + Vector3.new(0, h / 2, 0), Vector3.new(g, h, g), C.ceiba, { CanCollide = true })
	b(p + Vector3.new(0, h * 0.35, 0), Vector3.new(g * 1.15, h * 0.12, g * 1.15), C.ceiba2, { CanCollide = false })
	for i = 0, 5 do
		local a = i * math.pi / 3
		bc(CFrame.new(p + Vector3.new(math.cos(a) * g * 0.75, 2.2 * S * k, math.sin(a) * g * 0.75)) * CFrame.Angles(0, -a, 0), Vector3.new(g * 1.0, 4.4 * S * k, 0.6 * S), C.ceiba2, { CanCollide = true })
	end
	-- ramas en forma de paraguas
	local copa = p + Vector3.new(0, h, 0)
	for i = 0, 3 do
		local a = i * math.pi / 2 + 0.4
		bc(CFrame.new(copa + Vector3.new(math.cos(a) * 3 * S * k, -1 * S * k, math.sin(a) * 3 * S * k)) * CFrame.Angles(0, -a, 0.5), Vector3.new(7 * S * k, 1 * S * k, 1 * S * k), C.ceiba2, { CanCollide = false })
	end
	b(copa + Vector3.new(0, 0.6 * S * k, 0), Vector3.new(18 * S * k, 2 * S * k, 18 * S * k), C.hoja2, { CanCollide = false })
	b(copa + Vector3.new(0, 2.4 * S * k, 0), Vector3.new(13 * S * k, 1.8 * S * k, 13 * S * k), C.hoja, { CanCollide = false })
	b(copa + Vector3.new(rng:NextNumber(-2, 2) * S, 3.8 * S * k, 0), Vector3.new(7 * S * k, 1.4 * S * k, 8 * S * k), C.hoja3, { CanCollide = false })
	for _ = 1, 5 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(4, 8) * S * k
		local largo = rng:NextNumber(5, 12) * S * k
		b(copa + Vector3.new(math.cos(a) * r, -largo / 2, math.sin(a) * r), Vector3.new(0.45, largo, 0.45), C.liana, { CanCollide = false, CastShadow = false })
	end
end

local function helecho(p: Vector3, rng: Random)
	for i = 0, rng:NextInteger(3, 5) do
		local a = i * 1.3 + rng:NextNumber(0, 0.5)
		bc(CFrame.new(p + Vector3.new(math.cos(a) * 1.4, 1.0, math.sin(a) * 1.4)) * CFrame.Angles(0, -a, 0.55), Vector3.new(3.2, 0.25, 1.1), i % 2 == 0 and C.hoja3 or C.hoja, { CanCollide = false, CastShadow = false })
	end
end

local function arbusto(p: Vector3, rng: Random)
	local t = rng:NextNumber(1.2, 2.2) * S
	b(p + Vector3.new(0, t * 0.4, 0), Vector3.new(t, t * 0.8, t * rng:NextNumber(0.8, 1.2)), rng:NextNumber() < 0.5 and C.hoja2 or C.hoja, { CanCollide = false })
	if rng:NextNumber() < 0.45 then
		b(p + Vector3.new(rng:NextNumber(-1, 1), t * 0.85, rng:NextNumber(-1, 1)), Vector3.new(0.7, 0.7, 0.7), C.flor, { CanCollide = false, CastShadow = false })
	end
end

-- hongos que brillan en la oscuridad
local function hongos(p: Vector3, rng: Random, color: Color3?)
	for _ = 1, rng:NextInteger(2, 4) do
		local o = Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		local h = rng:NextNumber(0.6, 1.4)
		b(p + o + Vector3.new(0, h / 2, 0), Vector3.new(0.3, h, 0.3), C.cal, { CanCollide = false, CastShadow = false })
		neon(b(p + o + Vector3.new(0, h + 0.15, 0), Vector3.new(0.9, 0.3, 0.9), color or C.hongo))
	end
end

-- luciérnagas: una nube de puntitos que flotan
local function luciernagas(p: Vector3, color: Color3?)
	local a = b(p + Vector3.new(0, 4, 0), Vector3.new(12, 6, 12), C.hoja, { Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color or rgb(200, 255, 120))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.25), NumberSequenceKeypoint.new(0.7, 0.25), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(3, 6)
	e.Rate = 3
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 0.3, 0)
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Parent = a
end

-- ---------- ruinas mayas ----------
-- estela tallada con glifos que brillan
local function estela(p: Vector3, mira: Vector3, rng: Random)
	local cf = CFrame.lookAt(p, Vector3.new(mira.X, p.Y, mira.Z))
	bc(cf * CFrame.new(0, 0.4 * S, 0), Vector3.new(3.2 * S, 0.8 * S, 1.6 * S), C.piedra2, { CanCollide = true })
	bc(cf * CFrame.new(0, 3.2 * S, 0), Vector3.new(2.2 * S, 5 * S, 0.8 * S), C.piedra, { CanCollide = true })
	bc(cf * CFrame.new(0, 5.9 * S, 0), Vector3.new(2.5 * S, 0.5 * S, 1 * S), C.piedra2)
	bc(cf * CFrame.new(0, 6.25 * S, 0), Vector3.new(2.2 * S, 0.25 * S, 0.9 * S), C.musgo)
	-- rostro y glifos en la cara que mira a la plaza
	for i = 0, 2 do
		for k = -1, 1, 2 do
			neon(bc(cf * CFrame.new(k * 0.5 * S, (1.6 + i * 1.3) * S, -0.42 * S), Vector3.new(0.6 * S, 0.6 * S, 0.1), C.jade))
		end
	end
	if rng:NextNumber() < 0.6 then
		bc(cf * CFrame.new(0.9 * S, 2 * S, 0.45 * S) * CFrame.Angles(0, 0, 0.1), Vector3.new(0.3, 3.5 * S, 0.3), C.liana, { CanCollide = false, CastShadow = false })
	end
end

-- brasero de piedra con fuego (las antorchas del templo)
local function brasero(p: Vector3, color: Color3?)
	b(p + Vector3.new(0, 0.9 * S, 0), Vector3.new(1.4 * S, 1.8 * S, 1.4 * S), C.piedra2, { CanCollide = true })
	local cuenco = b(p + Vector3.new(0, 2.1 * S, 0), Vector3.new(2 * S, 0.6 * S, 2 * S), C.piedraOscura, { CanCollide = true })
	b(p + Vector3.new(0, 2.5 * S, 0), Vector3.new(1.4 * S, 0.3 * S, 1.4 * S), color or C.fuego, { Material = Enum.Material.Neon, CanCollide = false })
	fuego(cuenco, color or C.fuego, 6)
	luz(cuenco, color or C.fuego, 40, 2)
end

-- columna rota
local templete
local function columna(p: Vector3, rng: Random)
	local tramos = rng:NextInteger(1, 4)
	for i = 0, tramos - 1 do
		bc(CFrame.new(p + Vector3.new(0, (i + 0.5) * 1.6 * S, 0)) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Vector3.new(1.8 * S, 1.6 * S, 1.8 * S), i % 2 == 0 and C.piedra or C.piedra2, { CanCollide = true })
	end
	if rng:NextNumber() < 0.5 then
		-- un tramo caído al lado
		bc(CFrame.new(p + Vector3.new(2.4 * S, 0.8 * S, rng:NextNumber(-1, 1) * S)) * CFrame.Angles(0, rng:NextNumber(0, 3), math.pi / 2), Vector3.new(1.6 * S, 1.6 * S, 1.6 * S), C.piedra2, { CanCollide = true })
	end
	b(p + Vector3.new(0, tramos * 1.6 * S + 0.15 * S, 0), Vector3.new(1.9 * S, 0.3 * S, 1.9 * S), C.musgo, { CanCollide = false })
end

-- bloques de piedra caídos, con musgo
local function escombros(p: Vector3, rng: Random)
	for _ = 1, rng:NextInteger(2, 4) do
		local t = rng:NextNumber(1, 2.4) * S
		local o = Vector3.new(rng:NextNumber(-2, 2) * S, t * 0.4, rng:NextNumber(-2, 2) * S)
		bc(CFrame.new(p + o) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2)), Vector3.new(t, t * 0.8, t * 1.2), rng:NextNumber() < 0.5 and C.piedra or C.piedra2, { CanCollide = t > 1.8 * S })
	end
end

-- la gran pirámide escalonada del Templo de Xibalbá, con su escalinata y el templo arriba
local function piramide(xm: number, zm: number)
	local base = suelo(xm, zm)
	local escalones = 7
	local alto = 3 * S
	local ancho0 = 40 * S
	-- la escalinata mira a la plaza (+Z)
	for i = 0, escalones - 1 do
		local ancho = ancho0 - i * 4 * S
		local y = base.Y - 2 * S + (i + 0.5) * alto + (i == 0 and -S or 0)
		local h = alto + (i == 0 and 2 * S or 0)
		b(Vector3.new(base.X, y + (i == 0 and 0 or 0), base.Z), Vector3.new(ancho, h, ancho), i % 2 == 0 and C.piedra or C.piedra2, { CanCollide = true })
		-- cornisa más oscura en cada nivel
		b(Vector3.new(base.X, base.Y - 2 * S + (i + 1) * alto - 0.2 * S, base.Z), Vector3.new(ancho + 0.6 * S, 0.4 * S, ancho + 0.6 * S), C.piedraOscura, { CanCollide = true })
		-- musgo en las esquinas
		if i % 2 == 1 then
			b(Vector3.new(base.X - ancho / 2 + 1.5 * S, base.Y - 2 * S + (i + 1) * alto + 0.1 * S, base.Z + ancho / 2 - 1.5 * S), Vector3.new(3 * S, 0.3 * S, 3 * S), C.musgo, { CanCollide = false })
		end
	end
	-- escalinata central con franjas de jade
	local cimaY = base.Y - 2 * S + escalones * alto
	local largoEsc = ancho0 / 2
	local angulo = math.atan2(escalones * alto, largoEsc - 6 * S)
	for k = 0, 13 do
		local t = (k + 0.5) / 14
		local z = base.Z + ancho0 / 2 - t * (largoEsc - 6 * S)
		local y = base.Y - 2 * S + t * escalones * alto
		b(Vector3.new(base.X, y, z), Vector3.new(8 * S, alto / 2 + 0.4 * S, 2.6 * S), k % 2 == 0 and C.cal or C.piedra, { CanCollide = true })
	end
	for _, lado in { -1, 1 } do
		bc(CFrame.new(base.X + lado * 4.6 * S, base.Y - 2 * S + escalones * alto / 2, base.Z + ancho0 / 4 + 3 * S) * CFrame.Angles(angulo, 0, 0), Vector3.new(1.2 * S, 1.2 * S, (largoEsc - 4 * S) / math.cos(angulo)), C.piedraOscura, { CanCollide = true })
		neon(bc(CFrame.new(base.X + lado * 4.6 * S, base.Y - 2 * S + escalones * alto / 2 + 0.65 * S, base.Z + ancho0 / 4 + 3 * S) * CFrame.Angles(angulo, 0, 0), Vector3.new(0.5 * S, 0.1, (largoEsc - 4 * S) / math.cos(angulo)), C.jade))
	end
	-- el templo de arriba: cuarto con puerta oscura, friso y crestería
	local tc = Vector3.new(base.X, cimaY, base.Z)
	b(tc + Vector3.new(0, 3 * S, -1 * S), Vector3.new(12 * S, 6 * S, 9 * S), C.piedra, { CanCollide = true })
	b(tc + Vector3.new(0, 2.4 * S, 3.6 * S), Vector3.new(3.4 * S, 4.8 * S, 0.4 * S), rgb(10, 8, 14), { CanCollide = false })
	local brillo = neon(b(tc + Vector3.new(0, 2.2 * S, 3.4 * S), Vector3.new(2.6 * S, 4 * S, 0.2 * S), C.fuegoMorado))
	brillo.Transparency = 0.5
	luz(brillo, C.fuegoMorado, 50, 3)
	b(tc + Vector3.new(0, 6.4 * S, -1 * S), Vector3.new(13 * S, 0.8 * S, 10 * S), C.piedraOscura, { CanCollide = true })
	for i = -2, 2 do
		neon(b(tc + Vector3.new(i * 2.2 * S, 5.4 * S, 3.6 * S), Vector3.new(0.9 * S, 0.9 * S, 0.2 * S), C.jade))
	end
	-- crestería calada con el murciélago de Xibalbá
	b(tc + Vector3.new(0, 9.2 * S, -2 * S), Vector3.new(9 * S, 5 * S, 1.2 * S), C.piedra2, { CanCollide = true })
	b(tc + Vector3.new(0, 12.2 * S, -2 * S), Vector3.new(6 * S, 1 * S, 1.2 * S), C.piedra2, { CanCollide = true })
	for _, lado in { -1, 1 } do
		b(tc + Vector3.new(lado * 2.6 * S, 10 * S, -1.3 * S), Vector3.new(3 * S, 1.2 * S, 0.3 * S), rgb(110, 30, 50))
		b(tc + Vector3.new(lado * 1.2 * S, 11 * S, -1.3 * S), Vector3.new(0.6 * S, 1.6 * S, 0.3 * S), rgb(110, 30, 50))
		neon(b(tc + Vector3.new(lado * 0.6 * S, 9.6 * S, -1.25 * S), Vector3.new(0.6 * S, 0.4 * S, 0.2 * S), rgb(255, 50, 50)))
	end
	b(tc + Vector3.new(0, 9.4 * S, -1.3 * S), Vector3.new(2 * S, 2.6 * S, 0.3 * S), rgb(90, 24, 42))
	-- braseros a los lados de la puerta
	brasero(tc + Vector3.new(-5 * S, 0, 5.5 * S), C.fuegoMorado)
	brasero(tc + Vector3.new(5 * S, 0, 5.5 * S), C.fuegoMorado)
end

-- templete: una pirámide pequeña con su cuarto arriba
templete = function(xm: number, zm: number, rng: Random)
	local base = suelo(xm, zm)
	local mira = suelo(0, 0)
	local cf = CFrame.lookAt(base, Vector3.new(mira.X, base.Y, mira.Z))
	for i = 0, 3 do
		local ancho = (16 - i * 3.4) * S
		bc(cf * CFrame.new(0, (i + 0.5) * 2.4 * S - 1 * S, 0), Vector3.new(ancho, 2.4 * S, ancho), i % 2 == 0 and C.piedra or C.piedra2, { CanCollide = true })
	end
	for k = 0, 5 do
		local t = (k + 0.5) / 6
		bc(cf * CFrame.new(0, t * 4 * 2.4 * S - 1 * S, -8 * S + t * 4.5 * S), Vector3.new(4 * S, 1.4 * S, 1.6 * S), k % 2 == 0 and C.cal or C.piedra)
	end
	local cima = cf * CFrame.new(0, 4 * 2.4 * S - 1 * S, 0)
	bc(cima * CFrame.new(0, 2 * S, 0), Vector3.new(5 * S, 4 * S, 4.5 * S), C.piedra, { CanCollide = true })
	bc(cima * CFrame.new(0, 1.6 * S, -2.3 * S), Vector3.new(1.8 * S, 3 * S, 0.3 * S), rgb(10, 8, 14))
	bc(cima * CFrame.new(0, 4.3 * S, 0), Vector3.new(5.6 * S, 0.6 * S, 5 * S), C.piedraOscura, { CanCollide = true })
	bc(cima * CFrame.new(0, 6 * S, 0.8 * S), Vector3.new(4 * S, 2.8 * S, 0.8 * S), C.piedra2)
	for k = -1, 1 do
		neon(bc(cima * CFrame.new(k * 1.2 * S, 6 * S, 0.35 * S), Vector3.new(0.6 * S, 0.6 * S, 0.1), C.jade))
	end
	bc(cima * CFrame.new(rng:NextNumber(-2, 2) * S, 4.7 * S, 0), Vector3.new(2 * S, 0.3 * S, 2 * S), C.musgo, { CanCollide = false })
end

-- cancha del juego de pelota (el Popol Vuh: los héroes gemelos jugaron contra los señores de Xibalbá)
local function canchaPelota(xm: number, zm: number)
	local c = suelo(xm, zm)
	local largo = 30 * S
	for _, lado in { -1, 1 } do
		local x = c.X + lado * 7 * S
		b(Vector3.new(x + lado * 2 * S, c.Y + 2 * S, c.Z), Vector3.new(4 * S, 4 * S, largo), C.piedra, { CanCollide = true })
		b(Vector3.new(x + lado * 2 * S, c.Y + 4.2 * S, c.Z), Vector3.new(4.4 * S, 0.4 * S, largo + 0.4 * S), C.piedraOscura, { CanCollide = true })
		-- talud inclinado hacia la cancha
		bc(CFrame.new(x - lado * 0.6 * S, c.Y + 1 * S, c.Z) * CFrame.Angles(0, 0, lado * 0.5), Vector3.new(2.6 * S, 2.2 * S, largo), C.cal, { CanCollide = true })
		-- el aro de piedra
		local aro = CFrame.new(x, c.Y + 5.6 * S, c.Z) * CFrame.Angles(0, 0, math.pi / 2)
		for k = 0, 3 do
			local a = k * math.pi / 2
			bc(aro * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, 0.9 * S), Vector3.new(0.6 * S, 1.8 * S, 0.5 * S), C.piedra2, { CanCollide = true })
		end
		neon(bc(aro, Vector3.new(0.3 * S, 0.6 * S, 0.6 * S), C.jade))
		-- marcadores en el suelo
		neon(b(Vector3.new(c.X, c.Y + 0.05, c.Z + lado * 9 * S), Vector3.new(2 * S, 0.1, 2 * S), C.jade)).Transparency = 0.4
	end
	neon(b(Vector3.new(c.X, c.Y + 0.05, c.Z), Vector3.new(2.4 * S, 0.1, 2.4 * S), C.oro)).Transparency = 0.3
	-- una pelota de hule olvidada
	b(c + Vector3.new(2 * S, 0.7 * S, -4 * S), Vector3.new(1.4 * S, 1.4 * S, 1.4 * S), rgb(40, 32, 30), { Shape = Enum.PartType.Ball, CanCollide = true })
end

-- ---------- campamento ----------
local function campamento(): CFrame
	local c = isla.campamento
	local p = suelo(c.X, c.Y)
	-- fogata
	local fogata = b(p + Vector3.new(0, 0.6, 0), Vector3.new(6, 1.2, 6), C.piedraOscura)
	b(p + Vector3.new(0, 1.8, 0), Vector3.new(3, 1.2, 3), C.fuego, { Material = Enum.Material.Neon, CanCollide = false })
	fuego(fogata, C.fuego, 7)
	luz(fogata, rgb(255, 170, 90), 34, 2)
	-- dos chozas de palma
	for _, lado in { -1, 1 } do
		local base = p + Vector3.new(lado * 20, 0, -8)
		for _, x in { -4, 4 } do
			for _, z in { -4, 4 } do
				b(base + Vector3.new(x, 2.5, z), Vector3.new(0.8, 5, 0.8), C.tronco, { CanCollide = true })
			end
		end
		for n = 0, 3 do
			b(base + Vector3.new(0, 5.4 + n * 1.3, 0), Vector3.new(12 - n * 3, 1.3, 12 - n * 3), n % 2 == 0 and rgb(170, 140, 70) or rgb(150, 120, 60))
		end
		-- hamaca
		b(base + Vector3.new(0, 2.2, 0), Vector3.new(7, 0.3, 1.6), lado < 0 and rgb(200, 60, 60) or rgb(60, 140, 200), { CanCollide = false })
	end
	-- antorchas
	for _, o in { Vector3.new(-12, 0, 12), Vector3.new(12, 0, 12), Vector3.new(-14, 0, -18), Vector3.new(14, 0, -18) } do
		local t = b(p + o + Vector3.new(0, 3, 0), Vector3.new(0.6, 6, 0.6), C.tronco)
		local llama = b(p + o + Vector3.new(0, 6.4, 0), Vector3.new(1, 1, 1), C.fuego, { Material = Enum.Material.Neon, CanCollide = false })
		fuego(llama, C.fuego, 3)
		luz(t, C.fuego, 20, 1.2)
	end
	-- carreta con provisiones: lleva de vuelta al Refugio
	local carreta = b(p + Vector3.new(-9, 2.2, 13), Vector3.new(5, 2.4, 8), rgb(130, 92, 56))
	carreta.Name = "Carreta"
	b(p + Vector3.new(-9, 4.6, 13), Vector3.new(5.4, 2.4, 7), rgb(220, 200, 150))
	for _, x in { -2.8, 2.8 } do
		for _, z in { -2.6, 2.6 } do
			b(p + Vector3.new(-9 + x, 1.2, 13 + z), Vector3.new(0.5, 2.4, 2.4), C.tronco2, { Shape = Enum.PartType.Cylinder })
		end
	end
	local volver = Instance.new("ProximityPrompt")
	volver.Name = "VolverRefugio"
	volver.ActionText = "Volver al Refugio"
	volver.ObjectText = "Carreta"
	volver.MaxActivationDistance = 12
	volver.RequiresLineOfSight = false
	volver.GamepadKeyCode = Enum.KeyCode.ButtonL1
	volver.Parent = carreta
	for i = 1, 3 do
		b(p + Vector3.new(4 + i * 3, 1.25, 14), Vector3.new(2.5, 2.5, 2.5), rgb(150, 110, 70), { Material = Enum.Material.WoodPlanks })
	end
	return CFrame.new(suelo(c.X, c.Y + 3) + Vector3.new(0, 4, 0))
end

-- ---------- terreno ----------
local function colorTerreno(variante: string)
	return function(h, x, z)
		local nivel = math.floor(h / V)
		local lx, lz = (x - O.X) / S, (z - O.Z) / S
		local d = math.sqrt(lx * lx + lz * lz)
		if h > 14 * S then
			-- montañas de la selva: roca con vegetación
			return "m" .. (nivel % 3), ({ rgb(44, 58, 46), rgb(36, 48, 40), rgb(52, 70, 50) })[nivel % 3 + 1]
		end
		if variante == "xibalba" then
			if d < 27 then
				-- la plaza empedrada del templo
				return "p", rgb(92, 100, 88)
			end
			if math.abs(lx) < 4.5 and lz > 20 and lz < 86 then
				-- el sacbé: el camino blanco de los mayas, del campamento a la plaza
				return "s", C.cal
			end
			if math.abs(lx) < 6 and lz < -24 and lz > -64 then
				return "s", C.cal
			end
		end
		if variante == "cenote" then
			local dc = (Vector2.new(lx, lz) - Config.CENOTE.centro).Magnitude
			if dc < Config.CENOTE.radio - 2 then
				return "f" .. (nivel % 2), nivel % 2 == 0 and rgb(70, 96, 92) or rgb(60, 86, 84) -- el fondo del cenote
			elseif dc < Config.CENOTE.radio + 9 then
				return "r" .. (nivel % 2), nivel % 2 == 0 and C.cal or rgb(166, 162, 140) -- el borde de piedra caliza
			end
		elseif variante == "pantano" then
			if h <= 0 then
				return "l" .. (nivel % 2), nivel % 2 == 0 and rgb(66, 58, 40) or rgb(58, 52, 36) -- lodo bajo el agua
			end
			local tonosP = { rgb(64, 78, 44), rgb(56, 70, 40), rgb(72, 84, 48) }
			return "p" .. (nivel % 3), tonosP[nivel % 3 + 1]
		elseif variante == "jungla" then
			if d < 22 then
				return "c", rgb(70, 92, 52) -- el claro de la selva
			end
			if math.abs(lx) < 4.5 and lz > 20 and lz < 86 then
				return "s", rgb(120, 96, 66) -- sendero de tierra
			end
		end
		local tonos = { rgb(46, 70, 44), rgb(40, 62, 40), rgb(54, 78, 48) }
		return "j" .. (nivel % 3), tonos[nivel % 3 + 1]
	end
end

-- ¿se puede poner algo aquí? (no en la plaza, los caminos ni el campamento)
local function libre(variante: string, xm: number, zm: number): boolean
	local d = math.sqrt(xm * xm + zm * zm)
	if d < 32 or d > 138 or math.max(math.abs(xm), math.abs(zm)) > 131 then -- (el terreno llega a ±133 m)
		return false
	end
	if (Vector2.new(xm, zm) - isla.campamento).Magnitude < 24 then
		return false
	end
	if variante == "xibalba" then
		if math.abs(xm) < 8 and zm > 20 then
			return false
		end
		if math.abs(xm) < 26 and zm < -60 and zm > -112 then
			return false -- la pirámide
		end
		if math.abs(xm + 58) < 14 and math.abs(zm - 5) < 22 then
			return false -- la cancha
		end
		if (Vector2.new(xm, zm) - Vector2.new(68, -48)).Magnitude < 14 or (Vector2.new(xm, zm) - Vector2.new(-72, -52)).Magnitude < 14 then
			return false -- los templetes
		end
	end
	if variante == "cenote" then
		local dc = (Vector2.new(xm, zm) - Config.CENOTE.centro).Magnitude
		if dc < Config.CENOTE.radio + 8 or (Vector2.new(xm, zm) - Vector2.new(0, -48)).Magnitude < 18 then
			return false -- el cenote y el risco de las cascadas
		end
		if (Vector2.new(xm, zm) - Vector2.new(36, -36)).Magnitude < 9 or (Vector2.new(xm, zm) - Vector2.new(-38, -30)).Magnitude < 9 then
			return false -- los altares
		end
		if math.abs(xm) < 6 and zm > 10 and zm < 86 then
			return false -- el camino
		end
	elseif variante == "jungla" then
		if math.abs(xm) < 24 and zm < -62 and zm > -108 then
			return false -- el templo del jaguar
		end
		if math.abs(xm) < 6 and zm > 20 then
			return false
		end
	elseif variante == "pantano" then
		if math.abs(xm) < 22 and zm < -64 and zm > -102 then
			return false -- el templo doble
		end
		if math.abs(xm) < 6 and zm > 20 then
			return false
		end
	end
	return true
end

-- ¿hay agua aquí? (pantano)
local function bajoAgua(xm: number, zm: number): boolean
	local x, z = O.X + xm * S, O.Z + zm * S
	return isla.agua ~= nil and Config.alturaEn(x, z) < isla.agua * S
end

-- ---------- agua ----------
-- Cubre con agua los bloques del terreno que quedan por debajo del nivel del agua, uniendo los
-- vecinos en rectángulos (pocas piezas).
local function agua(nivelM: number, color: Color3, transparencia: number, dentro: ((number, number) -> boolean)?)
	local N = 200
	local ORIGEN = -N * V / 2
	local nivel = nivelM * S
	local lleno = {}
	for i = 1, N do
		lleno[i] = {}
		for k = 1, N do
			local x = O.X + ORIGEN + (i - 0.5) * V
			local z = O.Z + ORIGEN + (k - 0.5) * V
			lleno[i][k] = Config.alturaEn(x, z) < nivel and (not dentro or dentro((x - O.X) / S, (z - O.Z) / S))
		end
	end
	local usado = {}
	for i = 1, N do
		usado[i] = {}
	end
	local partes = 0
	for k = 1, N do
		for i = 1, N do
			if lleno[i][k] and not usado[i][k] then
				local ancho = 1
				while i + ancho <= N and lleno[i + ancho][k] and not usado[i + ancho][k] do
					ancho += 1
				end
				local largo = 1
				local sigue = true
				while sigue and k + largo <= N do
					for ii = i, i + ancho - 1 do
						if not lleno[ii][k + largo] or usado[ii][k + largo] then
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
				local p = Mundo.parte({
					Name = "Agua", Size = Vector3.new(ancho * V, 0.6, largo * V),
					Position = Vector3.new(O.X + ORIGEN + (i - 1 + ancho / 2) * V, nivel - 0.3, O.Z + ORIGEN + (k - 1 + largo / 2) * V),
					Color = color, Transparency = transparencia, CanCollide = false, CanQuery = false, CastShadow = false,
					Material = Enum.Material.Glass, Reflectance = 0.15, Parent = carpeta,
				})
				p:SetAttribute("Agua", true)
				partes += 1
			end
		end
	end
	return partes
end

-- lluvia sobre la isla (partículas de gotas que caen)
local function lluvia(radioM: number, densidad: number)
	local nube = b(O + Vector3.new(0, 45 * S, 0), Vector3.new(radioM * 2 * S, 1, radioM * 2 * S), C.cal, { Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false })
	local e = Instance.new("ParticleEmitter")
	e.Name = "Lluvia"
	e.Color = ColorSequence.new(rgb(190, 220, 235))
	e.Transparency = NumberSequence.new(0.35)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.12) })
	e.Lifetime = NumberRange.new(2.2, 2.6)
	e.Speed = NumberRange.new(55, 65)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Rate = densidad
	e.LightEmission = 0.3
	e.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
	e.Squash = NumberSequence.new(3)
	e.Shape = Enum.ParticleEmitterShape.Box
	e.Parent = nube
end

-- ---------- piezas de las otras islas ----------
-- cascada: una cortina de agua que cae y salpica abajo
local function cascada(arriba: Vector3, abajo: Vector3, ancho: number)
	local alto = arriba.Y - abajo.Y
	local cortina = b(Vector3.new(arriba.X, (arriba.Y + abajo.Y) / 2, arriba.Z), Vector3.new(ancho, alto, 1.2), rgb(170, 225, 240), { CanCollide = false, CastShadow = false, Transparency = 0.35, Material = Enum.Material.Neon })
	b(Vector3.new(arriba.X, (arriba.Y + abajo.Y) / 2, arriba.Z + 0.7), Vector3.new(ancho * 0.6, alto, 0.6), rgb(230, 250, 255), { CanCollide = false, CastShadow = false, Transparency = 0.5, Material = Enum.Material.Neon })
	local espuma = b(abajo + Vector3.new(0, 0.6, 1.5), Vector3.new(ancho * 1.4, 1.2, 4), rgb(235, 250, 255), { CanCollide = false, CastShadow = false, Transparency = 0.3 })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(rgb(235, 250, 255))
	e.Size = NumberSequence.new(1.6, 0)
	e.Transparency = NumberSequence.new(0.3, 1)
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(6, 12)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(0, -10, 0)
	e.Rate = 25
	e.Parent = espuma
	return cortina
end

-- el risco del cenote: roca caliza con raíces colgando y dos cascadas
local function riscoCenote(xm: number, zm: number, rng: Random)
	local base = suelo(xm, zm)
	local alto = 16 * S
	for i = -3, 3 do
		local h = alto * (1 - math.abs(i) * 0.12) * rng:NextNumber(0.9, 1.05)
		local ancho = 4.6 * S
		b(base + Vector3.new(i * ancho, h / 2 - 2 * S, -math.abs(i) * 1.2 * S), Vector3.new(ancho + 0.2, h, 10 * S), i % 2 == 0 and C.cal or rgb(166, 162, 140), { CanCollide = true })
		b(base + Vector3.new(i * ancho, h - 2 * S + 0.6 * S, -math.abs(i) * 1.2 * S), Vector3.new(ancho + 0.6, 1.2 * S, 10.4 * S), C.musgo, { CanCollide = true })
		-- raíces que cuelgan por la cara del risco
		for _ = 1, 2 do
			local largo = rng:NextNumber(4, 10) * S
			b(base + Vector3.new(i * ancho + rng:NextNumber(-1.5, 1.5) * S, h - 2 * S - largo / 2, 5.1 * S - math.abs(i) * 1.2 * S), Vector3.new(0.4, largo, 0.4), C.liana, { CanCollide = false, CastShadow = false })
		end
	end
	local nivel = (isla.agua or 0) * S
	for _, x in { -5, 5 } do
		cascada(base + Vector3.new(x * S, alto - 2.5 * S, 5.4 * S), Vector3.new(base.X + x * S, nivel, base.Z + 5.4 * S), 3.2 * S)
	end
	for _, x in { -12, 0, 12 } do
		arbol(base + Vector3.new(x * S, alto - 2 * S, -2 * S), rng, rng:NextNumber(7, 11))
	end
end

-- la cabeza de piedra de Tláloc (o de un jaguar): una gran escultura con ojos que brillan
local function cabezaPiedra(xm: number, zm: number, estilo: string)
	local p = suelo(xm, zm)
	local mira = suelo(0, 0)
	local cf = CFrame.lookAt(p, Vector3.new(mira.X, p.Y, mira.Z))
	bc(cf * CFrame.new(0, 1 * S, 0), Vector3.new(7 * S, 2 * S, 6 * S), C.piedra2, { CanCollide = true })
	bc(cf * CFrame.new(0, 4.5 * S, 0), Vector3.new(5.5 * S, 5 * S, 4.5 * S), C.piedra, { CanCollide = true })
	if estilo == "tlaloc" then
		-- las anteojeras y los colmillos de Tláloc, dios de la lluvia
		for _, lado in { -1, 1 } do
			bc(cf * CFrame.new(lado * 1.3 * S, 5.4 * S, -2.3 * S), Vector3.new(1.8 * S, 1.8 * S, 0.4 * S), rgb(40, 150, 170), { CanCollide = false })
			neon(bc(cf * CFrame.new(lado * 1.3 * S, 5.4 * S, -2.5 * S), Vector3.new(0.8 * S, 0.8 * S, 0.1), rgb(110, 240, 255)))
			bc(cf * CFrame.new(lado * 0.6 * S, 3.0 * S, -2.4 * S), Vector3.new(0.4 * S, 1.0 * S, 0.3 * S), C.cal)
		end
		bc(cf * CFrame.new(0, 3.6 * S, -2.35 * S), Vector3.new(3.2 * S, 0.5 * S, 0.3 * S), rgb(40, 150, 170))
		bc(cf * CFrame.new(0, 7.4 * S, 0), Vector3.new(6.5 * S, 0.8 * S, 5 * S), rgb(40, 150, 170), { CanCollide = true })
	else
		-- jaguar: orejas, ojos de jade y obsidiana
		for _, lado in { -1, 1 } do
			bc(cf * CFrame.new(lado * 2 * S, 7.6 * S, 0.5 * S), Vector3.new(1.4 * S, 1.4 * S, 1 * S), C.piedra, { CanCollide = true })
			neon(bc(cf * CFrame.new(lado * 1.2 * S, 5.6 * S, -2.3 * S), Vector3.new(1.0 * S, 0.5 * S, 0.1), C.jade))
			bc(cf * CFrame.new(lado * 0.7 * S, 2.9 * S, -2.4 * S), Vector3.new(0.4 * S, 1.2 * S, 0.3 * S), rgb(20, 16, 26))
		end
		bc(cf * CFrame.new(0, 3.9 * S, -2.5 * S), Vector3.new(2.6 * S, 1.6 * S, 0.8 * S), C.piedra2)
		bc(cf * CFrame.new(0, 4.4 * S, -2.95 * S), Vector3.new(1.0 * S, 0.6 * S, 0.2 * S), rgb(20, 16, 26))
	end
end

-- grupo de cristales de obsidiana con el filo violeta
local function obsidiana(p: Vector3, rng: Random)
	for _ = 1, rng:NextInteger(3, 6) do
		local alto = rng:NextNumber(2, 7) * S
		local ancho = rng:NextNumber(0.7, 1.4) * S
		local o = Vector3.new(rng:NextNumber(-2.5, 2.5) * S, 0, rng:NextNumber(-2.5, 2.5) * S)
		local cf = CFrame.new(p + o + Vector3.new(0, alto / 2 - 0.5 * S, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3))
		bc(cf, Vector3.new(ancho, alto, ancho), rgb(14, 12, 20), { CanCollide = alto > 3 * S, Reflectance = 0.2 })
		neon(bc(cf * CFrame.new(ancho / 2, 0, 0), Vector3.new(0.15, alto * 0.95, ancho * 0.4), rgb(160, 96, 255)))
	end
end

-- el templo del jaguar: pirámide con la cabeza del jaguar en la fachada
local function temploJaguar(xm: number, zm: number)
	local base = suelo(xm, zm)
	local escalones = 5
	local alto = 3 * S
	local ancho0 = 34 * S
	for i = 0, escalones - 1 do
		local ancho = ancho0 - i * 5 * S
		b(Vector3.new(base.X, base.Y - 2 * S + (i + 0.5) * alto + (i == 0 and -S or 0), base.Z), Vector3.new(ancho, alto + (i == 0 and 2 * S or 0), ancho), i % 2 == 0 and C.piedra or C.piedra2, { CanCollide = true })
		b(Vector3.new(base.X, base.Y - 2 * S + (i + 1) * alto - 0.2 * S, base.Z), Vector3.new(ancho + 0.6 * S, 0.4 * S, ancho + 0.6 * S), rgb(20, 16, 26), { CanCollide = true })
	end
	for k = 0, 9 do
		local t = (k + 0.5) / 10
		b(Vector3.new(base.X, base.Y - 2 * S + t * escalones * alto, base.Z + ancho0 / 2 - t * (ancho0 / 2 - 5 * S)), Vector3.new(7 * S, alto / 2 + 0.4 * S, 2.4 * S), k % 2 == 0 and C.cal or C.piedra, { CanCollide = true })
	end
	local cima = Vector3.new(base.X, base.Y - 2 * S + escalones * alto, base.Z)
	b(cima + Vector3.new(0, 3 * S, -1 * S), Vector3.new(11 * S, 6 * S, 8 * S), C.piedra, { CanCollide = true })
	b(cima + Vector3.new(0, 2.4 * S, 3.1 * S), Vector3.new(3 * S, 4.6 * S, 0.4 * S), rgb(10, 8, 14))
	-- la fachada: la cabeza del jaguar sobre la puerta
	b(cima + Vector3.new(0, 7.2 * S, 2.8 * S), Vector3.new(7 * S, 3.4 * S, 1.2 * S), rgb(20, 16, 26), { CanCollide = true, Reflectance = 0.15 })
	for _, lado in { -1, 1 } do
		b(cima + Vector3.new(lado * 2.6 * S, 9.4 * S, 2.8 * S), Vector3.new(1.4 * S, 1.4 * S, 1 * S), rgb(20, 16, 26))
		neon(b(cima + Vector3.new(lado * 1.4 * S, 7.6 * S, 3.45 * S), Vector3.new(1.2 * S, 0.5 * S, 0.1), C.jade))
		brasero(cima + Vector3.new(lado * 4.6 * S, 0, 5 * S), C.jade)
	end
	b(cima + Vector3.new(0, 6.3 * S, 3.45 * S), Vector3.new(3 * S, 0.5 * S, 0.1), C.oro)
end

-- templo doble de Aztlán: una plataforma con el santuario rojo de Huitzilopochtli y el azul de Tláloc
local function temploDoble(xm: number, zm: number)
	local base = suelo(xm, zm)
	local escalones = 4
	local alto = 3 * S
	for i = 0, escalones - 1 do
		local ancho = (36 - i * 5) * S
		local fondo = (28 - i * 4) * S
		b(Vector3.new(base.X, base.Y - 2 * S + (i + 0.5) * alto + (i == 0 and -S or 0), base.Z), Vector3.new(ancho, alto + (i == 0 and 2 * S or 0), fondo), i % 2 == 0 and C.piedra or C.piedra2, { CanCollide = true })
	end
	local cima = Vector3.new(base.X, base.Y - 2 * S + escalones * alto, base.Z)
	for _, lado in { -1, 1 } do
		-- dos escalinatas paralelas
		for k = 0, 7 do
			local t = (k + 0.5) / 8
			b(Vector3.new(base.X + lado * 5.5 * S, base.Y - 2 * S + t * escalones * alto, base.Z + 14 * S - t * 8 * S), Vector3.new(5 * S, alto / 2 + 0.4 * S, 1.6 * S), k % 2 == 0 and C.cal or C.piedra, { CanCollide = true })
		end
		local color = lado < 0 and rgb(170, 40, 36) or rgb(40, 110, 190)
		local s0 = cima + Vector3.new(lado * 5.5 * S, 0, -1 * S)
		b(s0 + Vector3.new(0, 3 * S, 0), Vector3.new(7 * S, 6 * S, 7 * S), C.cal, { CanCollide = true })
		b(s0 + Vector3.new(0, 2.4 * S, 3.6 * S), Vector3.new(2.4 * S, 4.4 * S, 0.3 * S), rgb(10, 8, 14))
		b(s0 + Vector3.new(0, 6.6 * S, 0), Vector3.new(7.4 * S, 1.2 * S, 7.4 * S), color, { CanCollide = true })
		b(s0 + Vector3.new(0, 7.8 * S, 0), Vector3.new(5.6 * S, 1.2 * S, 5.6 * S), color, { CanCollide = true })
		local fuegoP = b(s0 + Vector3.new(0, 0.6 * S, 5 * S), Vector3.new(1.6 * S, 1.2 * S, 1.6 * S), C.piedraOscura)
		fuego(fuegoP, lado < 0 and C.fuego or rgb(90, 200, 255), 5)
		luz(fuegoP, lado < 0 and C.fuego or rgb(90, 200, 255), 35, 1.8)
	end
	-- cabezas de serpiente al pie de las escalinatas
	for _, lado in { -1, 1 } do
		local cabeza = b(base + Vector3.new(lado * 9 * S, 1 * S, 15.5 * S), Vector3.new(2.4 * S, 2 * S, 3 * S), C.piedra, { CanCollide = true })
		neon(b(cabeza.Position + Vector3.new(0, 0.4 * S, 1.55 * S), Vector3.new(1.6 * S, 0.3 * S, 0.1), C.jade))
	end
end

-- mangle: tronco sobre raíces en arco que salen del agua, copa ancha
local function mangle(p: Vector3, rng: Random)
	local alto = rng:NextNumber(6, 10) * S
	local tronco = b(p + Vector3.new(0, 2 * S + alto / 2, 0), Vector3.new(1 * S, alto, 1 * S), C.tronco2, { CanCollide = true })
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		bc(CFrame.lookAt(p + dir * 1.8 * S + Vector3.new(0, 1.3 * S, 0), p + dir * 3 * S) * CFrame.Angles(-0.9, 0, 0), Vector3.new(0.4 * S, 0.4 * S, 3.2 * S), C.tronco, { CanCollide = false })
	end
	local copa = tronco.Position + Vector3.new(0, alto / 2, 0)
	b(copa, Vector3.new(9 * S, 2 * S, 9 * S), C.hoja2, { CanCollide = false })
	b(copa + Vector3.new(rng:NextNumber(-1, 1) * S, 1.6 * S, 0), Vector3.new(6 * S, 1.6 * S, 6.5 * S), rgb(70, 110, 56), { CanCollide = false })
	for _ = 1, 3 do
		local largo = rng:NextNumber(2, 5) * S
		b(copa + Vector3.new(rng:NextNumber(-3, 3) * S, -largo / 2 - 0.8 * S, rng:NextNumber(-3, 3) * S), Vector3.new(0.3, largo, 0.3), rgb(110, 120, 80), { CanCollide = false, CastShadow = false })
	end
end

-- juncos (tules) junto al agua
local function juncos(p: Vector3, rng: Random)
	for _ = 1, rng:NextInteger(4, 8) do
		local h = rng:NextNumber(1.5, 3.5) * S
		local o = Vector3.new(rng:NextNumber(-1.5, 1.5) * S, 0, rng:NextNumber(-1.5, 1.5) * S)
		b(p + o + Vector3.new(0, h / 2, 0), Vector3.new(0.3, h, 0.3), rgb(120, 140, 70), { CanCollide = false, CastShadow = false })
		if rng:NextNumber() < 0.4 then
			b(p + o + Vector3.new(0, h + 0.4, 0), Vector3.new(0.5, 1, 0.5), rgb(110, 76, 46), { CanCollide = false, CastShadow = false })
		end
	end
end

-- chinampa: una parcela flotante con estacas, flores y maíz
local function chinampa(p: Vector3, rng: Random)
	local ancho, largo = rng:NextNumber(5, 7) * S, rng:NextNumber(9, 13) * S
	local giro = rng:NextNumber(0, math.pi)
	local cf = CFrame.new(p) * CFrame.Angles(0, giro, 0)
	bc(cf * CFrame.new(0, 0.5 * S, 0), Vector3.new(ancho, 1.2 * S, largo), rgb(74, 58, 40), { CanCollide = true })
	bc(cf * CFrame.new(0, 1.15 * S, 0), Vector3.new(ancho - 1, 0.2 * S, largo - 1), rgb(70, 110, 50), { CanCollide = false })
	for k = -1, 1, 2 do
		for t = -2, 2 do
			bc(cf * CFrame.new(k * ancho / 2, 1 * S, t * largo / 5), Vector3.new(0.35 * S, 2.2 * S, 0.35 * S), C.tronco, { CanCollide = false })
		end
	end
	for t = -2, 2 do
		local planta = rng:NextNumber() < 0.5
		bc(cf * CFrame.new(rng:NextNumber(-1, 1) * S, (planta and 2.4 or 1.6) * S, t * largo / 6), Vector3.new(0.8 * S, (planta and 2.4 or 0.8) * S, 0.8 * S), planta and rgb(120, 170, 60) or (rng:NextNumber() < 0.5 and rgb(250, 170, 40) or C.flor), { CanCollide = false })
	end
end

-- nenúfares sobre el agua
local function nenufares(p: Vector3, rng: Random)
	for _ = 1, rng:NextInteger(3, 6) do
		local o = Vector3.new(rng:NextNumber(-4, 4) * S, 0, rng:NextNumber(-4, 4) * S)
		local t = rng:NextNumber(0.8, 1.6) * S
		b(p + o + Vector3.new(0, 0.1, 0), Vector3.new(t, 0.2, t), rgb(60, 140, 70), { CanCollide = false, CastShadow = false })
		if rng:NextNumber() < 0.35 then
			b(p + o + Vector3.new(0, 0.5, 0), Vector3.new(0.6 * S, 0.5 * S, 0.6 * S), rgb(250, 190, 220), { CanCollide = false, CastShadow = false })
		end
	end
end

-- ---------- cada isla ----------
local function xibalba(rng: Random)
	piramide(0, -88)
	canchaPelota(-58, 5)
	-- altar en el centro de la plaza
	local c = suelo(0, 0)
	b(c + Vector3.new(0, 0.3 * S, 0), Vector3.new(8 * S, 0.6 * S, 8 * S), C.piedra2, { CanCollide = true })
	b(c + Vector3.new(0, 0.65 * S, 0), Vector3.new(5 * S, 0.1 * S, 5 * S), C.piedraOscura, { CanCollide = true })
	neon(b(c + Vector3.new(0, 0.72 * S, 0), Vector3.new(2 * S, 0.05 * S, 2 * S), C.jade)).Transparency = 0.2
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		neon(b(c + Vector3.new(math.cos(a) * 2.2 * S, 0.72 * S, math.sin(a) * 2.2 * S), Vector3.new(0.6 * S, 0.05 * S, 0.6 * S), C.jade)).Transparency = 0.3
	end
	-- estelas y braseros alrededor de la plaza
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + math.pi / 8
		local xm, zm = math.cos(a) * 31, math.sin(a) * 31
		if not (math.abs(xm) < 10 and zm > 0) and not (math.abs(xm) < 10 and zm < 0) then
			estela(suelo(xm, zm), suelo(0, 0), rng)
		end
		local a2 = i / 8 * math.pi * 2
		local bx, bz = math.cos(a2) * 34, math.sin(a2) * 34
		if not (math.abs(bx) < 8) then
			brasero(suelo(bx, bz))
		end
	end
	-- braseros que marcan los caminos
	for _, z in { 30, 50, 70 } do
		brasero(suelo(-7, z))
		brasero(suelo(7, z))
	end
	-- ruinas
	for _ = 1, 26 do
		local xm, zm = rng:NextNumber(-105, 105), rng:NextNumber(-105, 85)
		if libre("xibalba", xm, zm) then
			if rng:NextNumber() < 0.55 then
				columna(suelo(xm, zm), rng)
			else
				escombros(suelo(xm, zm), rng)
			end
		end
	end
	-- la selva alrededor
	for _, p in { { -95, -40 }, { 92, -70 }, { 80, 55 }, { -88, 70 } } do
		ceiba(suelo(p[1], p[2]), rng, 1)
	end
	-- templetes a los lados de la plaza
	templete(68, -48, rng)
	templete(-72, -52, rng)
	local n = 0
	for _ = 1, 900 do
		if n >= 130 then
			break
		end
		local xm, zm = rng:NextNumber(-138, 138), rng:NextNumber(-138, 138)
		local d = math.sqrt(xm * xm + zm * zm)
		-- más denso hacia las orillas: la selva rodea la ciudad
		if libre("xibalba", xm, zm) and d > 48 and rng:NextNumber() < (d - 40) / 70 then
			arbol(suelo(xm, zm), rng, d > 108 and rng:NextNumber(11, 18) or nil)
			n += 1
		end
	end
	for _ = 1, 140 do
		local xm, zm = rng:NextNumber(-118, 118), rng:NextNumber(-118, 100)
		if libre("xibalba", xm, zm) then
			local r = rng:NextNumber()
			if r < 0.45 then
				helecho(suelo(xm, zm), rng)
			elseif r < 0.8 then
				arbusto(suelo(xm, zm), rng)
			else
				hongos(suelo(xm, zm), rng)
			end
		end
	end
	for _ = 1, 10 do
		local xm, zm = rng:NextNumber(-90, 90), rng:NextNumber(-90, 80)
		if math.sqrt(xm * xm + zm * zm) > 30 then
			luciernagas(suelo(xm, zm), rgb(120, 255, 210))
		end
	end
end

-- puebla la selva: árboles (más densos hacia la orilla), plantas, hongos y luciérnagas
local function selvaAlrededor(variante: string, rng: Random, arboles: number, extra)
	local n = 0
	for _ = 1, arboles * 8 do
		if n >= arboles then
			break
		end
		local xm, zm = rng:NextNumber(-138, 138), rng:NextNumber(-138, 138)
		local d = math.sqrt(xm * xm + zm * zm)
		if libre(variante, xm, zm) and not bajoAgua(xm, zm) and d > 42 and rng:NextNumber() < (d - 34) / 70 then
			arbol(suelo(xm, zm), rng, d > 108 and rng:NextNumber(11, 18) or nil)
			n += 1
		end
	end
	for _ = 1, 150 do
		local xm, zm = rng:NextNumber(-118, 118), rng:NextNumber(-118, 100)
		if libre(variante, xm, zm) and not bajoAgua(xm, zm) then
			local r = rng:NextNumber()
			if r < 0.45 then
				helecho(suelo(xm, zm), rng)
			elseif r < 0.82 then
				arbusto(suelo(xm, zm), rng)
			elseif extra then
				extra(suelo(xm, zm), rng)
			else
				hongos(suelo(xm, zm), rng)
			end
		end
	end
end

local function cenote(rng: Random)
	local nivel = isla.agua
	agua(nivel, rgb(40, 150, 160), 0.35, function(xm, zm)
		return (Vector2.new(xm, zm) - Config.CENOTE.centro).Magnitude < Config.CENOTE.radio + 3
	end)
	riscoCenote(0, -48, rng)
	-- nenúfares en el cenote y escalinata que baja al agua
	for _ = 1, 6 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(4, Config.CENOTE.radio - 4)
		nenufares(Vector3.new(O.X + (Config.CENOTE.centro.X + math.cos(a) * r) * S, nivel * S, O.Z + (Config.CENOTE.centro.Y + math.sin(a) * r) * S), rng)
	end
	for k = 0, 5 do
		local zm = Config.CENOTE.centro.Y + Config.CENOTE.radio + 6 - k * 2
		local p = suelo(0, zm)
		b(Vector3.new(p.X, p.Y + 0.3 * S, p.Z), Vector3.new(8 * S, 0.6 * S, 2.2 * S), k % 2 == 0 and C.cal or C.piedra, { CanCollide = true })
	end
	-- altares de Tláloc y estelas alrededor del cenote
	cabezaPiedra(36, -36, "tlaloc")
	cabezaPiedra(-38, -30, "tlaloc")
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.5
		local xm, zm = Config.CENOTE.centro.X + math.cos(a) * (Config.CENOTE.radio + 6), Config.CENOTE.centro.Y + math.sin(a) * (Config.CENOTE.radio + 6)
		if zm > -30 and math.abs(xm) > 6 then
			estela(suelo(xm, zm), suelo(Config.CENOTE.centro.X, Config.CENOTE.centro.Y), rng)
		end
	end
	for _, p in { { -14, 22 }, { 14, 22 }, { -7, 40 }, { 7, 40 }, { -7, 60 }, { 7, 60 } } do
		brasero(suelo(p[1], p[2]), rgb(90, 200, 255))
	end
	for _ = 1, 16 do
		local xm, zm = rng:NextNumber(-100, 100), rng:NextNumber(-100, 80)
		if libre("cenote", xm, zm) then
			if rng:NextNumber() < 0.5 then
				columna(suelo(xm, zm), rng)
			else
				escombros(suelo(xm, zm), rng)
			end
		end
	end
	for _, p in { { -92, -50 }, { 88, -60 }, { 84, 50 }, { -90, 60 } } do
		ceiba(suelo(p[1], p[2]), rng, 1)
	end
	selvaAlrededor("cenote", rng, 120)
	lluvia(110, 500)
	for _ = 1, 6 do
		local xm, zm = rng:NextNumber(-80, 80), rng:NextNumber(-80, 70)
		if libre("cenote", xm, zm) then
			luciernagas(suelo(xm, zm), rgb(180, 255, 140))
		end
	end
end

local function jungla(rng: Random)
	temploJaguar(0, -84)
	-- el claro: un círculo de piedras con un altar de jade
	local c = suelo(0, 0)
	b(c + Vector3.new(0, 0.4 * S, 0), Vector3.new(6 * S, 0.8 * S, 6 * S), C.piedra2, { CanCollide = true })
	neon(b(c + Vector3.new(0, 0.85 * S, 0), Vector3.new(2 * S, 0.1 * S, 2 * S), C.jade)).Transparency = 0.2
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local p = suelo(math.cos(a) * 24, math.sin(a) * 24)
		if not (math.abs(math.cos(a) * 24) < 6 and math.sin(a) > 0) then
			b(p + Vector3.new(0, 1.5 * S, 0), Vector3.new(1.6 * S, 3 * S, 1.6 * S), i % 2 == 0 and C.piedra or C.piedra2, { CanCollide = true })
			b(p + Vector3.new(0, 3.1 * S, 0), Vector3.new(1.8 * S, 0.3 * S, 1.8 * S), C.musgo)
		end
	end
	-- jaguares de piedra que vigilan el sendero y cristales de obsidiana por la selva
	cabezaPiedra(-12, 34, "jaguar")
	cabezaPiedra(12, 34, "jaguar")
	for _ = 1, 22 do
		local xm, zm = rng:NextNumber(-100, 100), rng:NextNumber(-100, 90)
		if libre("jungla", xm, zm) and math.sqrt(xm * xm + zm * zm) > 30 then
			obsidiana(suelo(xm, zm), rng)
			if rng:NextNumber() < 0.5 then
				obsidiana(suelo(xm + rng:NextNumber(-4, 4), zm + rng:NextNumber(-4, 4)), rng)
			end
		end
	end
	for _ = 1, 10 do
		local xm, zm = rng:NextNumber(-100, 100), rng:NextNumber(-100, 80)
		if libre("jungla", xm, zm) then
			columna(suelo(xm, zm), rng)
		end
	end
	for _, p in { { -95, -40 }, { 92, -70 }, { 80, 55 }, { -88, 70 }, { 40, -100 }, { -55, 95 } } do
		ceiba(suelo(p[1], p[2]), rng, 1.1)
	end
	selvaAlrededor("jungla", rng, 190, function(p, r)
		if r:NextNumber() < 0.5 then
			hongos(p, r, rgb(160, 120, 255))
		else
			arbusto(p, r)
		end
	end)
	for _ = 1, 8 do
		local xm, zm = rng:NextNumber(-80, 80), rng:NextNumber(-80, 70)
		if libre("jungla", xm, zm) then
			luciernagas(suelo(xm, zm), rgb(255, 230, 130))
		end
	end
end

local function pantano(rng: Random)
	local nivel = isla.agua
	agua(nivel, rgb(60, 92, 72), 0.3)
	temploDoble(0, -82)
	-- chinampas, mangles, juncos y nenúfares en los canales
	local n = 0
	for _ = 1, 300 do
		if n >= 14 then
			break
		end
		local xm, zm = rng:NextNumber(-100, 100), rng:NextNumber(-100, 80)
		if bajoAgua(xm, zm) and libre("pantano", xm, zm) and math.sqrt(xm * xm + zm * zm) > 26 then
			chinampa(Vector3.new(O.X + xm * S, nivel * S, O.Z + zm * S), rng)
			n += 1
		end
	end
	local m = 0
	for _ = 1, 600 do
		if m >= 40 then
			break
		end
		local xm, zm = rng:NextNumber(-125, 125), rng:NextNumber(-125, 125)
		if libre("pantano", xm, zm) and math.sqrt(xm * xm + zm * zm) > 40 then
			mangle(suelo(xm, zm), rng)
			m += 1
		end
	end
	for _ = 1, 120 do
		local xm, zm = rng:NextNumber(-110, 110), rng:NextNumber(-110, 90)
		if libre("pantano", xm, zm) then
			if bajoAgua(xm, zm) then
				nenufares(Vector3.new(O.X + xm * S, nivel * S, O.Z + zm * S), rng)
			else
				juncos(suelo(xm, zm), rng)
			end
		end
	end
	for _, p in { { -95, -40 }, { 92, -70 }, { 84, 60 } } do
		ceiba(suelo(p[1], p[2]), rng, 0.9)
	end
	selvaAlrededor("pantano", rng, 70)
	for _, p in { { -7, 30 }, { 7, 30 }, { -7, 55 }, { 7, 55 } } do
		brasero(suelo(p[1], p[2]))
	end
	for _ = 1, 10 do
		local xm, zm = rng:NextNumber(-90, 90), rng:NextNumber(-90, 70)
		luciernagas(Vector3.new(O.X + xm * S, nivel * S + 2, O.Z + zm * S), rgb(200, 255, 120))
	end
end

local CONSTRUIR = {
	xibalba = xibalba,
	cenote = cenote,
	selva = jungla,
	pantano = pantano,
}

-- Construye la isla y devuelve dónde aparecen los cazadores.
function Mapa.construir(zona: string): CFrame
	isla = Config.ISLAS[zona]
	O = isla.centro
	carpeta = Instance.new("Folder")
	carpeta.Name = NOMBRES[zona] or zona
	carpeta.Parent = workspace
	Terreno.construir(carpeta, O, V, 200, function(x, z)
		return Config.alturaEn(x, z)
	end, colorTerreno(isla.variante))
	local rng = Random.new(#zona * 97 + 11)
	if CONSTRUIR[zona] then
		CONSTRUIR[zona](rng)
	end
	return campamento()
end

return Mapa
