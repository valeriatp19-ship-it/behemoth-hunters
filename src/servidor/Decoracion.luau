--!nonstrict
-- Flora y detalles del suelo, todo en bloques: cactus, arbustos, piedras, ondas de arena y
-- esqueletos en el Mar de Dunas; ichu, cantutas y puyas en las Cumbres; macetas, flores y
-- enredaderas en el Refugio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)
local Mundo = require(script.Parent.Mundo)

local S = Config.S
local Decoracion = {}
local carpeta: Folder

local function b(pos: Vector3, tam: Vector3, color: Color3, props: { [string]: any }?)
	local t = { Name = "Deco", Size = tam, Position = pos, Color = Mundo.matiz(color, 0.06), CanCollide = false, CanQuery = false, CastShadow = tam.Magnitude > 3, Parent = carpeta }
	if props then
		for k, v in props do
			t[k] = v
		end
	end
	return Mundo.parte(t)
end

-- ---------- plantas y objetos (pos = punto del suelo, en studs) ----------
local function cactus(p: Vector3, rng: Random)
	local alto = rng:NextInteger(8, 13)
	local verde = Color3.fromRGB(86, 140, 70)
	b(p + Vector3.new(0, alto / 2, 0), Vector3.new(1.6, alto, 1.6), verde, { CanCollide = true })
	for _, lado in { -1, 1 } do
		if rng:NextNumber() < 0.8 then
			local h = rng:NextNumber(alto * 0.35, alto * 0.6)
			b(p + Vector3.new(lado * 1.4, h, 0), Vector3.new(1.4, 1.2, 1.2), verde)
			b(p + Vector3.new(lado * 1.9, h + 1.8, 0), Vector3.new(1.2, 3.6, 1.2), Color3.fromRGB(96, 150, 78))
		end
	end
	if rng:NextNumber() < 0.4 then
		b(p + Vector3.new(0, alto + 0.4, 0), Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(240, 120, 170))
	end
end

local function arbustoSeco(p: Vector3, rng: Random)
	for _ = 1, rng:NextInteger(3, 5) do
		local o = Vector3.new(rng:NextNumber(-1.2, 1.2), 0, rng:NextNumber(-1.2, 1.2))
		local h = rng:NextNumber(0.8, 1.8)
		b(p + o + Vector3.new(0, h / 2, 0), Vector3.new(0.9, h, 0.9), rng:NextNumber() < 0.5 and Color3.fromRGB(140, 120, 70) or Color3.fromRGB(120, 110, 64))
	end
end

local function piedra(p: Vector3, rng: Random, gris: Color3)
	local t = rng:NextNumber(1, 3)
	b(p + Vector3.new(0, t * 0.35, 0), Vector3.new(t, t * 0.7, t * rng:NextNumber(0.8, 1.3)), gris, { CanCollide = t > 2 })
	if rng:NextNumber() < 0.5 then
		b(p + Vector3.new(t * 0.6, t * 0.2, 0.3), Vector3.new(t * 0.5, t * 0.4, t * 0.5), gris)
	end
end

local function onda(p: Vector3, rng: Random)
	b(p + Vector3.new(0, 0.12, 0), Vector3.new(rng:NextNumber(4, 9), 0.25, 0.8), Color3.fromRGB(200, 160, 100))
end

local function esqueleto(p: Vector3, rng: Random)
	local hueso = Color3.fromRGB(236, 228, 210)
	local giro = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local function h(off: Vector3, tam: Vector3)
		local x = b(p, tam, hueso)
		x.CFrame = CFrame.new(p) * giro * CFrame.new(off)
	end
	h(Vector3.new(0, 0.6, 0), Vector3.new(0.8, 0.8, 16)) -- columna
	for k = -3, 3 do
		for _, lado in { -1, 1 } do
			h(Vector3.new(lado * 2.2, 2.2, k * 2), Vector3.new(0.6, 4.4, 0.6))
			h(Vector3.new(lado * 1.3, 4.3, k * 2), Vector3.new(1.8, 0.6, 0.6))
		end
	end
	h(Vector3.new(0, 1.6, -10), Vector3.new(3.4, 3, 3.6)) -- cráneo
	h(Vector3.new(-0.8, 1.9, -11.85), Vector3.new(0.8, 0.8, 0.2))
	h(Vector3.new(0.8, 1.9, -11.85), Vector3.new(0.8, 0.8, 0.2))
end

local function ichu(p: Vector3, rng: Random)
	for _ = 1, rng:NextInteger(4, 7) do
		local o = Vector3.new(rng:NextNumber(-0.9, 0.9), 0, rng:NextNumber(-0.9, 0.9))
		local h = rng:NextNumber(1.4, 2.8)
		b(p + o + Vector3.new(0, h / 2, 0), Vector3.new(0.3, h, 0.3), rng:NextNumber() < 0.5 and Color3.fromRGB(214, 196, 110) or Color3.fromRGB(190, 176, 96))
	end
end

local function cantuta(p: Vector3, rng: Random)
	local tallo = Color3.fromRGB(70, 120, 60)
	b(p + Vector3.new(0, 1.2, 0), Vector3.new(0.35, 2.4, 0.35), tallo)
	local flor = rng:NextNumber() < 0.5 and Color3.fromRGB(220, 40, 80) or Color3.fromRGB(230, 70, 170)
	for k = 0, rng:NextInteger(2, 4) do
		local lado = (k % 2 == 0) and 1 or -1
		b(p + Vector3.new(lado * 0.5, 2.4 - k * 0.45, (k - 1) * 0.3), Vector3.new(0.5, 0.7, 0.5), flor)
		b(p + Vector3.new(lado * 0.5, 2.8 - k * 0.45, (k - 1) * 0.3), Vector3.new(0.25, 0.2, 0.25), Color3.fromRGB(250, 220, 90))
	end
end

local function puya(p: Vector3, rng: Random)
	local verde = Color3.fromRGB(100, 140, 96)
	for k = 0, 2 do
		b(p + Vector3.new(0, 1 + k * 2, 0), Vector3.new(4 - k, 2, 4 - k), verde, { CanCollide = true })
	end
	local alto = rng:NextInteger(12, 18)
	b(p + Vector3.new(0, 6 + alto / 2, 0), Vector3.new(1.6, alto, 1.6), Color3.fromRGB(226, 220, 170))
	for k = 0, 6 do
		b(p + Vector3.new(((k % 2) - 0.5) * 1.8, 7 + k * (alto / 7), 0), Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(150, 180, 110))
	end
end

local function maceta(p: Vector3, rng: Random)
	b(p + Vector3.new(0, 0.7, 0), Vector3.new(1.6, 1.4, 1.6), Color3.fromRGB(184, 96, 60), { CanCollide = true })
	b(p + Vector3.new(0, 1.45, 0), Vector3.new(1.8, 0.2, 1.8), Color3.fromRGB(160, 80, 50))
	if rng:NextNumber() < 0.5 then
		for _ = 1, 4 do
			local o = Vector3.new(rng:NextNumber(-0.5, 0.5), 0, rng:NextNumber(-0.5, 0.5))
			b(p + o + Vector3.new(0, 2.2, 0), Vector3.new(0.7, 1.4, 0.7), Color3.fromRGB(80, 150, 70))
		end
	else
		local flor = ({ Color3.fromRGB(240, 90, 120), Color3.fromRGB(250, 210, 80), Color3.fromRGB(150, 100, 230) })[rng:NextInteger(1, 3)]
		b(p + Vector3.new(0, 2.0, 0), Vector3.new(1.3, 0.9, 1.3), Color3.fromRGB(80, 150, 70))
		for _ = 1, 3 do
			b(p + Vector3.new(rng:NextNumber(-0.5, 0.5), 2.6, rng:NextNumber(-0.5, 0.5)), Vector3.new(0.5, 0.5, 0.5), flor)
		end
	end
end

local function florecitas(p: Vector3, rng: Random)
	local flor = ({ Color3.fromRGB(240, 90, 120), Color3.fromRGB(250, 210, 80), Color3.fromRGB(150, 100, 230), Color3.new(1, 1, 1) })[rng:NextInteger(1, 4)]
	for _ = 1, rng:NextInteger(3, 6) do
		local o = Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		b(p + o + Vector3.new(0, 0.5, 0), Vector3.new(0.25, 1, 0.25), Color3.fromRGB(80, 150, 70))
		b(p + o + Vector3.new(0, 1.1, 0), Vector3.new(0.55, 0.45, 0.55), flor)
	end
end

local function pasto(p: Vector3, rng: Random)
	for _ = 1, rng:NextInteger(3, 5) do
		local o = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		local h = rng:NextNumber(0.6, 1.4)
		b(p + o + Vector3.new(0, h / 2, 0), Vector3.new(0.3, h, 0.3), rng:NextNumber() < 0.5 and Color3.fromRGB(96, 164, 72) or Color3.fromRGB(80, 146, 60))
	end
end

-- ---------- dónde se puede decorar ----------
local function libreDunas(xm: number, zm: number): boolean
	for _, p in Config.PIRAMIDES do
		if math.abs(xm - p.x) < p.tam * 0.5 + 4 and math.abs(zm - p.z) < p.tam * 0.5 + 4 then
			return false
		end
	end
	for _, o in Config.OBELISCOS do
		if (Vector2.new(xm, zm) - Vector2.new(o[1], o[2])).Magnitude < 5 then
			return false
		end
	end
	if (Vector2.new(xm, zm) - Config.CAMPAMENTO).Magnitude < 22 then
		return false
	end
	return (Vector2.new(xm, zm) - Config.OASIS).Magnitude > Config.OASIS_RADIO + 2
end

function Decoracion.dunas()
	carpeta = Instance.new("Folder")
	carpeta.Name = "FloraDunas"
	carpeta.Parent = workspace
	local rng = Random.new(31)
	local function lugar(radio)
		for _ = 1, 20 do
			local xm, zm = rng:NextNumber(-radio, radio), rng:NextNumber(-radio, radio)
			if Vector2.new(xm, zm).Magnitude < radio and libreDunas(xm, zm) then
				return Vector3.new(xm * S, Config.altura(xm * S, zm * S), zm * S), xm, zm
			end
		end
		return nil
	end
	local arena = Color3.fromRGB(150, 140, 128)
	for _ = 1, 28 do
		local p = lugar(125)
		if p then
			cactus(p, rng)
		end
	end
	for _ = 1, 40 do
		local p = lugar(130)
		if p then
			arbustoSeco(p, rng)
		end
	end
	for _ = 1, 45 do
		local p = lugar(130)
		if p then
			piedra(p, rng, arena)
		end
	end
	for _ = 1, 90 do
		local p = lugar(130)
		if p then
			onda(p, rng)
		end
	end
	for _ = 1, 4 do
		local p = lugar(110)
		if p then
			esqueleto(p, rng)
		end
	end
	-- flores y pasto junto al oasis
	for _ = 1, 30 do
		local ang, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(Config.OASIS_RADIO + 1, Config.OASIS_RADIO + 7)
		local xm, zm = Config.OASIS.X + math.cos(ang) * d, Config.OASIS.Y + math.sin(ang) * d
		local p = Vector3.new(xm * S, Config.altura(xm * S, zm * S), zm * S)
		if rng:NextNumber() < 0.5 then
			florecitas(p, rng)
		else
			pasto(p, rng)
		end
	end
end

function Decoracion.cumbres()
	carpeta = Instance.new("Folder")
	carpeta.Name = "FloraCumbres"
	carpeta.Parent = workspace
	local rng = Random.new(47)
	local function lugar(radio)
		for _ = 1, 20 do
			local xm, zm = rng:NextNumber(-radio, radio), rng:NextNumber(-radio, radio)
			if Vector2.new(xm, zm).Magnitude < radio and (Vector2.new(xm, zm) - Config.CUMBRES_CAMPAMENTO).Magnitude > 20 then
				return Config.sueloCumbres(xm, zm)
			end
		end
		return nil
	end
	for _ = 1, 110 do
		local p = lugar(100)
		if p then
			ichu(p, rng)
		end
	end
	for _ = 1, 50 do
		local p = lugar(95)
		if p then
			cantuta(p, rng)
		end
	end
	for _ = 1, 6 do
		local p = lugar(85)
		if p then
			puya(p, rng)
		end
	end
	for _ = 1, 40 do
		local p = lugar(100)
		if p then
			piedra(p, rng, Color3.fromRGB(132, 126, 118))
		end
	end
	for _ = 1, 30 do
		local p = lugar(100)
		if p then
			pasto(p, rng)
		end
	end
end

local function hongo(p: Vector3, rng: Random)
	local col = rng:NextNumber() < 0.5 and Color3.fromRGB(170, 90, 255) or Color3.fromRGB(60, 230, 220)
	local alto = rng:NextNumber(0.8, 2)
	b(p + Vector3.new(0, alto / 2, 0), Vector3.new(0.35, alto, 0.35), Color3.fromRGB(200, 196, 210))
	b(p + Vector3.new(0, alto + 0.2, 0), Vector3.new(1.3, 0.45, 1.3), col, { Material = Enum.Material.Neon })
end

-- Desierto de Brasa: piedras volcánicas, arbustos secos y esqueletos
function Decoracion.brasa()
	carpeta = Instance.new("Folder")
	carpeta.Name = "FloraBrasa"
	carpeta.Parent = workspace
	local isla = Config.ISLAS.brasa
	local rng = Random.new(83)
	local function lugar()
		local xm, zm = rng:NextNumber(-120, 120), rng:NextNumber(-120, 80)
		if (Vector2.new(xm, zm) - isla.campamento).Magnitude < 22 then
			return nil
		end
		local x, z = isla.centro.X + xm * S, isla.centro.Z + zm * S
		return Vector3.new(x, Config.alturaEn(x, z), z)
	end
	for _ = 1, 50 do
		local p = lugar()
		if p then
			piedra(p, rng, Color3.fromRGB(44, 34, 36))
		end
	end
	for _ = 1, 30 do
		local p = lugar()
		if p then
			arbustoSeco(p, rng)
		end
	end
	for _ = 1, 3 do
		local p = lugar()
		if p then
			esqueleto(p, rng)
		end
	end
end

-- Cuevas del Uku Pacha: hongos que brillan, piedras y huesos
function Decoracion.cuevas()
	carpeta = Instance.new("Folder")
	carpeta.Name = "FloraCuevas"
	carpeta.Parent = workspace
	local isla = Config.ISLAS.cuevas
	local rng = Random.new(91)
	local function lugar()
		local xm, zm = rng:NextNumber(-100, 100), rng:NextNumber(-100, 80)
		if (Vector2.new(xm, zm) - isla.campamento).Magnitude < 20 then
			return nil
		end
		return Config.sueloMontana(isla.centro, xm, zm)
	end
	for _ = 1, 70 do
		local p = lugar()
		if p then
			hongo(p, rng)
		end
	end
	for _ = 1, 40 do
		local p = lugar()
		if p then
			piedra(p, rng, Color3.fromRGB(70, 64, 80))
		end
	end
	for _ = 1, 2 do
		local p = lugar()
		if p then
			esqueleto(p, rng)
		end
	end
end

-- El Refugio: centro del pueblo y tamaño de un bloque (4 studs); el pueblo va de -22 a 22 bloques.
function Decoracion.refugio(centro: Vector3)
	carpeta = Instance.new("Folder")
	carpeta.Name = "FloraRefugio"
	carpeta.Parent = workspace
	local rng = Random.new(53)
	local V = 4
	local function enBloques(x, z)
		return centro + Vector3.new(x * V, 0, z * V)
	end
	-- macetas junto a las calles y las casas
	for _, p in { { -3.5, 6 }, { 3.5, 6 }, { -3.5, -7 }, { 3.5, -7 }, { -9, 3.5 }, { 9, 3.5 }, { -9, -3.5 }, { 9, -3.5 }, { -19, -15 }, { -19, 10 }, { 13, 10 }, { 20, 10 }, { 10, -15 }, { -12, -15 }, { 16, 5 }, { -17, 9.5 } } do
		maceta(enBloques(p[1], p[2]), rng)
	end
	-- flores y pasto alrededor del oasis
	for _ = 1, 26 do
		local ang, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(5.6, 7.5)
		local p = enBloques(math.cos(ang) * d, math.sin(ang) * d)
		if rng:NextNumber() < 0.5 then
			florecitas(p, rng)
		else
			pasto(p, rng)
		end
	end
	-- enredaderas que cuelgan por dentro de la muralla
	for _ = 1, 16 do
		local lado = rng:NextInteger(1, 3)
		local t = rng:NextNumber(-20, 20)
		local pos = lado == 1 and enBloques(t, -21.9) or (lado == 2 and enBloques(-21.9, t) or enBloques(21.9, t))
		local largo = rng:NextNumber(4, 10)
		b(pos + Vector3.new(0, 12 - largo / 2, 0), Vector3.new(lado == 1 and 2.5 or 0.4, largo, lado == 1 and 0.4 or 2.5), Color3.fromRGB(70, 130, 60))
		for k = 0, 2 do
			b(pos + Vector3.new(0, 12 - largo * (0.2 + k * 0.3), 0), Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(240, 110, 150))
		end
	end
end

return Decoracion
