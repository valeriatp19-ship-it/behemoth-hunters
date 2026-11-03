--!nonstrict
-- El Refugio de Qamar: el pueblo donde se elige el arma, se forja y se parte a cazar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Compartido.Config)
local Armas = require(ReplicatedStorage.Compartido.Armas)
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Mundo = require(script.Parent.Mundo)
local Equipo = require(script.Parent.Equipo)
local Perfil = require(script.Parent.Perfil)

local C = Config.COLORES
local Refugio = {}
Refugio.CENTRO = Vector3.new(0, 900, 0)
local V = 4

local function bloque(tam: Vector3, pos: Vector3, color: Color3, props: { [string]: any }?)
	local t = { Name = "Refugio", Size = tam, Position = Refugio.CENTRO + pos, Color = color }
	if props then
		for k, v in props do
			t[k] = v
		end
	end
	return Mundo.parte(t)
end

-- ---------- personajes de bloques ----------
local function personaje(nombre: string, titulo: string, pos: Vector3, mira: number, piel: Color3, ropa: Color3, sombrero: Color3?, accion: string)
	local modelo = Instance.new("Model")
	modelo.Name = nombre
	local base = CFrame.new(Refugio.CENTRO + pos) * CFrame.Angles(0, mira, 0)
	local function p(tam, off, color, brilla)
		local x = Mundo.parte({ Name = "NPC", Size = tam, CFrame = base * CFrame.new(off), Color = color, Material = brilla and Enum.Material.Neon or nil, Parent = modelo })
		return x
	end
	-- mismas proporciones que los cazadores: piernas de 2,6 y brazos de 2,4
	p(Vector3.new(1, 2.6, 1), Vector3.new(-0.5, 1.3, 0), Color3.fromRGB(90, 70, 50))
	p(Vector3.new(1, 2.6, 1), Vector3.new(0.5, 1.3, 0), Color3.fromRGB(90, 70, 50))
	local torso = p(Vector3.new(2, 2, 1), Vector3.new(0, 3.6, 0), ropa)
	p(Vector3.new(1, 2.4, 1), Vector3.new(-1.5, 3.4, 0), piel)
	p(Vector3.new(1, 2.4, 1), Vector3.new(1.5, 3.4, 0), piel)
	p(Vector3.new(1.04, 0.9, 1.04), Vector3.new(-1.5, 4.15, 0), ropa)
	p(Vector3.new(1.04, 0.9, 1.04), Vector3.new(1.5, 4.15, 0), ropa)
	local cabeza = p(Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 5.3, 0), piel)
	p(Vector3.new(0.2, 0.2, 0.05), Vector3.new(-0.28, 5.35, -0.72), Color3.fromRGB(30, 24, 22))
	p(Vector3.new(0.2, 0.2, 0.05), Vector3.new(0.28, 5.35, -0.72), Color3.fromRGB(30, 24, 22))
	p(Vector3.new(0.4, 0.08, 0.05), Vector3.new(0, 5.0, -0.72), Color3.fromRGB(120, 40, 40))
	if sombrero then
		p(Vector3.new(1.55, 0.5, 1.55), Vector3.new(0, 6.1, 0), sombrero)
	end
	modelo.PrimaryPart = torso
	modelo.Parent = workspace
	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.fromOffset(220, 50)
	cartel.StudsOffset = Vector3.new(0, 3.2, 0)
	cartel.Adornee = cabeza
	cartel.MaxDistance = 60
	cartel.Parent = cabeza
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Arcade
	t.TextSize = 20
	t.TextColor3 = Color3.fromRGB(255, 230, 150)
	t.TextStrokeTransparency = 0
	t.Text = nombre .. "\n" .. titulo
	t.Parent = cartel
	local aviso = Instance.new("ProximityPrompt")
	aviso.ActionText = "Hablar"
	aviso.ObjectText = nombre
	aviso.MaxActivationDistance = 12
	aviso.RequiresLineOfSight = false
	aviso.Parent = torso
	aviso.Triggered:Connect(function(jugador)
		Refugio.hablar(jugador, accion)
	end)
end

-- ---------- construcción del pueblo ----------
local ADOBE = { Color3.fromRGB(214, 170, 118), Color3.fromRGB(200, 156, 104) }
local PIEDRA = { C.piedra, Color3.fromRGB(196, 160, 108), Color3.fromRGB(184, 150, 100) }
local TELAS = { C.rojo, Color3.fromRGB(40, 90, 160), Color3.fromRGB(47, 160, 150), Color3.fromRGB(120, 40, 50), Color3.fromRGB(230, 176, 74), Color3.fromRGB(100, 60, 140) }
local MADERA = Color3.fromRGB(120, 84, 50)
local HOJA = { Color3.fromRGB(90, 164, 72), Color3.fromRGB(70, 140, 58) }

-- un bloque con su esquina inferior en (x, y, z), medido en bloques de 4 studs
local function caja(x, y, z, w, h, d, color, props)
	return bloque(Vector3.new(w * V, h * V, d * V), Vector3.new((x + w / 2) * V, (y + h / 2) * V, (z + d / 2) * V), color, props)
end

local function luz(parte: BasePart, color: Color3, alcance: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = alcance
	l.Brightness = 1.6
	l.Parent = parte
end

local function farol(x, z, alto)
	caja(x + 0.35, 0, z + 0.35, 0.3, alto, 0.3, MADERA)
	local f = caja(x + 0.2, alto, z + 0.2, 0.6, 0.6, 0.6, Color3.fromRGB(255, 190, 90), { Material = Enum.Material.Neon })
	caja(x + 0.15, alto + 0.6, z + 0.15, 0.7, 0.15, 0.7, C.oro)
	luz(f, Color3.fromRGB(255, 180, 100), 26)
end

local function palmera(x, z, alto)
	for i = 0, alto - 1 do
		caja(x + (i % 2) * 0.08, i, z, 0.45, 1, 0.45, i % 2 == 0 and Color3.fromRGB(140, 100, 60) or Color3.fromRGB(120, 84, 50))
	end
	caja(x - 0.3, alto, z - 0.3, 1.05, 0.5, 1.05, HOJA[1], { CanCollide = false })
	for k = 0, 3 do
		local dx, dz = ({ 1, -1, 0, 0 })[k + 1], ({ 0, 0, 1, -1 })[k + 1]
		for d = 1, 3 do
			caja(x + dx * d * 0.8 - 0.1, alto - d * 0.25, z + dz * d * 0.8 - 0.1, 0.65, 0.3, 0.65, HOJA[(d % 2) + 1], { CanCollide = false })
		end
	end
end

local function casa(x, z, w, d, pisos, tela)
	for p = 0, pisos - 1 do
		caja(x, p * 2, z, w, 2, d, ADOBE[p % 2 + 1])
	end
	caja(x - 0.1, pisos * 2, z - 0.1, w + 0.2, 0.25, d + 0.2, Color3.fromRGB(180, 140, 96))
	-- puerta y ventanas hacia el sur (+Z)
	caja(x + w / 2 - 0.5, 0, z + d - 0.05, 1, 1.5, 0.15, Color3.fromRGB(70, 46, 28))
	for p = 0, pisos - 1 do
		for i = 0, math.floor(w / 2) - 1 do
			if not (p == 0 and math.abs(x + 1 + i * 2 - (x + w / 2)) < 0.8) then
				caja(x + 0.6 + i * 2, p * 2 + 0.9, z + d - 0.05, 0.6, 0.6, 0.15, Color3.fromRGB(50, 36, 26))
			end
		end
	end
	-- toldo y terraza
	caja(x + w / 2 - 1, 1.6, z + d, 2, 0.15, 1, tela)
	caja(x + 0.5, pisos * 2 + 0.25, z + 0.5, 1, 0.5, 1, Color3.fromRGB(180, 110, 70))
	caja(x + w - 1.5, pisos * 2 + 0.25, z + 0.5, 1, 0.05, 1.5, tela)
end

local function puesto(x, z, tela1, tela2)
	for _, px in { 0, 2.7 } do
		for _, pz in { 0, 2.7 } do
			caja(x + px, 0, z + pz, 0.3, 2.2, 0.3, MADERA)
		end
	end
	for i = 0, 5 do
		caja(x - 0.2 + i * 0.55, 2.2, z - 0.2, 0.55, 0.2, 3.4, i % 2 == 0 and tela1 or tela2)
	end
	caja(x + 0.3, 0, z + 0.3, 2.4, 0.9, 1, MADERA)
	caja(x + 0.4, 0.9, z + 0.4, 0.5, 0.4, 0.5, Color3.fromRGB(190, 110, 60))
	caja(x + 1.1, 0.9, z + 0.4, 0.4, 0.5, 0.4, C.oro)
	caja(x + 1.8, 0.9, z + 0.4, 0.5, 0.3, 0.5, Color3.fromRGB(120, 170, 80))
	caja(x - 0.5, 0.01, z + 1.8, 3.8, 0.05, 1.6, tela2)
end

local function construir()
	local N = 22 -- el pueblo va de -22 a 22 bloques
	-- suelo de arena con calles empedradas en cruz
	for bx = -N, N - 1, 2 do
		for bz = -N, N - 1, 2 do
			local calle = math.abs(bx + 1) <= 2 or math.abs(bz + 1) <= 2
			local color = calle and PIEDRA[(bx + bz) % 3 + 1] or (((bx + bz) / 2) % 2 == 0 and Color3.fromRGB(228, 186, 120) or Color3.fromRGB(214, 170, 104))
			caja(bx, -1, bz, 2, 1, 2, Mundo.matiz(color, calle and 0.05 or 0.08))
		end
	end
	-- muralla con almenas y torres
	for i = -N, N - 1 do
		for _, borde in { -N - 1, N } do
			local puerta = borde == N and math.abs(i + 0.5) < 3
			if not puerta then
				caja(i, 0, borde, 1, 3, 1, PIEDRA[(i % 3) + 1])
				if i % 2 == 0 then
					caja(i, 3, borde, 1, 0.8, 1, PIEDRA[2])
				end
			end
			caja(borde, 0, i, 1, 3, 1, PIEDRA[(i % 3) + 1])
			if i % 2 == 0 then
				caja(borde, 3, i, 1, 0.8, 1, PIEDRA[2])
			end
		end
	end
	for _, esq in { { -N - 2, -N - 2 }, { N - 1, -N - 2 }, { -N - 2, N - 1 }, { N - 1, N - 1 } } do
		caja(esq[1], 0, esq[2], 3, 6, 3, PIEDRA[1])
		caja(esq[1] - 0.2, 6, esq[2] - 0.2, 3.4, 0.5, 3.4, C.oro)
		for k = 0, 3 do
			caja(esq[1] + (k % 2) * 2.2, 6.5, esq[2] + math.floor(k / 2) * 2.2, 0.8, 0.8, 0.8, PIEDRA[2])
		end
		caja(esq[1] + 1.35, 6.5, esq[2] + 1.35, 0.3, 3, 0.3, MADERA)
		caja(esq[1] + 1.65, 8.2, esq[2] + 1.35, 1.6, 1, 0.1, TELAS[3])
	end
	-- la gran puerta sur con estandartes y antorchas
	for _, lado in { -4, 3 } do
		caja(lado, 0, N - 0.5, 1.5, 5, 2, PIEDRA[1])
		caja(lado + 0.2, 1.5, N + 1.5, 1.1, 2.5, 0.1, TELAS[1])
		caja(lado + 0.5, 3.2, N + 1.55, 0.5, 0.5, 0.1, C.oro)
		farol(lado + 0.5, N + 2, 2)
	end
	caja(-4, 5, N - 0.5, 8.5, 1, 2, PIEDRA[2])
	caja(-3, 6, N - 0.3, 6.5, 0.4, 1.6, C.oro)
	-- plaza central: oasis con borde de piedra, palmeras y obelisco con jeroglíficos
	for bx = -5, 4 do
		for bz = -5, 4 do
			local borde = bx == -5 or bx == 4 or bz == -5 or bz == 4
			if borde then
				caja(bx, 0, bz, 1, 0.5, 1, PIEDRA[(bx + bz) % 3 + 1])
			else
				caja(bx, -0.9, bz, 1, 1, 1, Color3.fromRGB(46, 170, 190), { Transparency = 0.3, CanCollide = false })
			end
		end
	end
	caja(-0.75, -0.5, -0.75, 1.5, 5, 1.5, PIEDRA[1])
	caja(-0.5, 4.5, -0.5, 1, 1, 1, C.oro, { Material = Enum.Material.Neon })
	for k = 0, 3 do
		local lado = ({ { 0, -0.8 }, { 0, 0.72 }, { -0.8, 0 }, { 0.72, 0 } })[k + 1]
		for g = 0, 2 do
			caja(lado[1] - 0.15, 1 + g * 1.1, lado[2] - 0.15, 0.3, 0.4, 0.3, C.turquesa, { Material = Enum.Material.Neon })
		end
	end
	for _, p in { { -7, -7 }, { 6, -7 }, { -7, 6 }, { 6, 6 }, { 0, -8 }, { -8, 0 }, { 7, 0 } } do
		palmera(p[1], p[2], 5 + (p[1] + p[2]) % 2)
	end
	-- templo del Guardián (norte), con la cabeza de Sekhmaur
	for escalon = 0, 3 do
		caja(-8 + escalon, escalon * 0.5, -N + 3 + escalon * 0.5, 16 - escalon * 2, 0.5, 8 - escalon * 0.5, PIEDRA[escalon % 3 + 1])
	end
	for _, cx in { -6, -3, 2, 5 } do
		caja(cx, 2, -N + 5, 1, 5, 1, PIEDRA[1])
		caja(cx - 0.2, 7, -N + 4.8, 1.4, 0.5, 1.4, C.oro)
	end
	caja(-7, 7.5, -N + 4, 14, 1, 3, PIEDRA[2])
	caja(-2.5, 2, -N + 3.2, 5, 5, 3, C.oro)
	for k = 0, 3 do
		caja(-2.55, 2.5 + k * 1.1, -N + 3.15, 5.1, 0.45, 3.1, Color3.fromRGB(40, 70, 150))
	end
	caja(-1.5, 3, -N + 6.2, 3, 3, 0.3, Color3.fromRGB(214, 176, 110))
	caja(-1.0, 4.5, -N + 6.5, 0.5, 0.4, 0.1, C.turquesa, { Material = Enum.Material.Neon })
	caja(0.5, 4.5, -N + 6.5, 0.5, 0.4, 0.1, C.turquesa, { Material = Enum.Material.Neon })
	caja(-0.3, 7, -N + 5.8, 0.6, 1, 0.6, C.turquesa, { Material = Enum.Material.Neon })
	farol(-9, -N + 8, 2.5)
	farol(8, -N + 8, 2.5)
	-- mercado (oeste) con los puestos de Ammon y otros comerciantes
	puesto(-18, -6, TELAS[1], C.lino)
	puesto(-18, -1, TELAS[2], C.lino)
	puesto(-18, 4, TELAS[6], TELAS[5])
	puesto(-12, 9, TELAS[3], C.lino)
	farol(-14, -8, 2.5)
	farol(-14, 7, 2.5)
	for i = 0, 5 do
		caja(-12 + (i % 3) * 0.6, 0, -9 + math.floor(i / 3) * 0.6, 0.5, 0.5 + (i % 2) * 0.3, 0.5, Color3.fromRGB(170, 100, 60))
	end
	-- casas de adobe
	casa(-20, -20, 6, 4, 2, TELAS[4])
	casa(-20, 11, 5, 4, 1, TELAS[2])
	casa(14, 11, 6, 4, 2, TELAS[1])
	casa(10, -20, 5, 4, 1, TELAS[3])
	casa(-12, -20, 5, 4, 1, TELAS[5])
	-- biblioteca de Sefu (junto al templo)
	casa(11, -12, 6, 5, 1, C.lino)
	for i = 0, 2 do
		caja(11.3 + i * 1.8, 0, -7, 1.4, 2, 0.4, MADERA)
		for k = 0, 2 do
			caja(11.4 + i * 1.8, 0.3 + k * 0.6, -7.05, 1.2, 0.35, 0.15, k % 2 == 0 and C.lino or Color3.fromRGB(230, 210, 170))
		end
	end
	-- herrería de Nefra (este)
	local hx, hz = 13, -3
	for p = 0, 1 do
		caja(hx, p * 2, hz, 7, 2, 5, ADOBE[p % 2 + 1])
	end
	caja(hx - 0.1, 4, hz - 0.1, 7.2, 0.3, 5.2, Color3.fromRGB(150, 110, 76))
	caja(hx + 5, 4.3, hz + 1, 1.2, 3, 1.2, Color3.fromRGB(110, 96, 88))
	local chimenea = caja(hx + 5.1, 7.3, hz + 1.1, 1, 0.3, 1, Color3.fromRGB(60, 56, 54))
	local humo = Instance.new("Smoke")
	humo.Opacity = 0.25
	humo.RiseVelocity = 5
	humo.Size = 3
	humo.Parent = chimenea
	local horno = caja(hx + 2, 0, hz + 4.95, 3, 1.4, 0.2, Color3.fromRGB(255, 130, 40), { Material = Enum.Material.Neon })
	luz(horno, Color3.fromRGB(255, 140, 60), 30)
	caja(hx - 2, 0, hz + 5.5, 1.2, 0.7, 0.6, Color3.fromRGB(80, 76, 80))
	caja(hx - 2.3, 0.7, hz + 5.4, 1.8, 0.35, 0.8, Color3.fromRGB(60, 58, 62))
	for i = 0, 2 do
		caja(hx + 7.1, 0, hz + 1 + i * 1.3, 0.3, 2.2, 0.3, MADERA)
	end
	caja(hx + 7.1, 2.2, hz + 0.9, 0.3, 0.2, 3, MADERA)
	farol(hx - 1, hz - 1, 2.5)
	-- armería (oeste, junto a la plaza)
	local ax, az = -14, -13
	caja(ax, 0, az, 7, 2.5, 1, ADOBE[1])
	caja(ax - 0.2, 2.5, az - 0.2, 7.4, 0.3, 2.4, TELAS[2])
	caja(ax, 0, az + 1, 7, 0.2, 1.2, MADERA)
	for i, id in Armas.ORDEN do
		local soporte = bloque(Vector3.new(0.4, 0.4, 0.4), Vector3.new((ax + 0.7 + (i - 1) * 1.12) * V, 1.2 * V, (az + 1.3) * V), C.oro, { Transparency = 1 })
		Equipo.exhibir(id, soporte)
	end
	farol(ax - 1.5, az + 2, 2.5)
	-- los habitantes del Refugio
	personaje("Imani", "Capitana", Vector3.new(0, 2 * V, (-N + 9) * V), 0, Color3.fromRGB(160, 104, 66), C.rojo, C.oro, "imani")
	personaje("Sefu", "Escriba", Vector3.new(14 * V, 0, -5.5 * V), math.rad(90), Color3.fromRGB(224, 172, 126), C.lino, Color3.fromRGB(40, 80, 140), "sefu")
	personaje("Nefra", "Herrera", Vector3.new((hx + 3.5) * V, 0, (hz + 7) * V), math.pi, Color3.fromRGB(198, 140, 96), Color3.fromRGB(110, 70, 40), nil, "nefra")
	personaje("Ammon", "Comerciante", Vector3.new(-15.5 * V, 0, 5.5 * V), math.rad(-90), Color3.fromRGB(122, 78, 50), Color3.fromRGB(100, 60, 140), C.oro, "ammon")
	personaje("Tariq", "Guía de caravanas", Vector3.new(5 * V, 0, (N - 2) * V), math.pi, Color3.fromRGB(240, 200, 160), Color3.fromRGB(214, 176, 110), C.lino, "tariq")
	-- el espejo: para volver al probador y cambiar la apariencia
	local ex, ez = 8, 14
	caja(ex, 0, ez, 3, 0.4, 1, MADERA)
	caja(ex + 0.2, 0.4, ez + 0.3, 0.3, 4, 0.4, MADERA)
	caja(ex + 2.5, 0.4, ez + 0.3, 0.3, 4, 0.4, MADERA)
	caja(ex + 0.2, 4.4, ez + 0.3, 2.6, 0.4, 0.4, C.oro)
	local espejo = caja(ex + 0.5, 0.6, ez + 0.4, 2, 3.7, 0.15, Color3.fromRGB(190, 225, 240), { Material = Enum.Material.Glass, Reflectance = 0.35 })
	espejo.Name = "Espejo"
	local avisoEspejo = Instance.new("ProximityPrompt")
	avisoEspejo.Name = "CambiarApariencia"
	avisoEspejo.ActionText = "Cambiar apariencia"
	avisoEspejo.ObjectText = "Espejo"
	avisoEspejo.MaxActivationDistance = 10
	avisoEspejo.RequiresLineOfSight = false
	avisoEspejo.Parent = espejo
	-- muros invisibles altos alrededor de todo el Refugio (para no saltar afuera)
	for _, lado in { { 0, -N - 14, 2 * N + 30, 1 }, { 0, N + 14, 2 * N + 30, 1 }, { -N - 14, 0, 1, 2 * N + 30 }, { N + 14, 0, 1, 2 * N + 30 } } do
		bloque(Vector3.new(lado[3] * V, 60 * V, lado[4] * V), Vector3.new(lado[1] * V, 30 * V, lado[2] * V), C.piedra, { Transparency = 1, Name = "MuroInvisible" })
	end
	-- afuera: la caravana de camellos, dunas, palmeras y pirámides a lo lejos
	for i = 0, 2 do
		local cz = N + 5 + i * 3
		caja(-6, 1, cz, 1, 1, 2, Color3.fromRGB(200, 150, 90))
		caja(-5.9, 2, cz + 0.6, 0.8, 0.5, 0.8, Color3.fromRGB(190, 140, 80))
		caja(-5.85, 1.5, cz - 0.4, 0.4, 1.4, 0.4, Color3.fromRGB(200, 150, 90))
		caja(-5.9, 2.8, cz - 0.6, 0.5, 0.4, 0.6, Color3.fromRGB(200, 150, 90))
		caja(-6.05, 1.95, cz + 0.2, 1.1, 0.25, 1.4, TELAS[i % 3 + 1])
		for _, px in { 0, 0.7 } do
			for _, pz in { 0, 1.6 } do
				caja(-6 + px, 0, cz + pz, 0.3, 1, 0.3, Color3.fromRGB(180, 130, 80))
			end
		end
	end
	for bx = -N - 12, N + 12, 3 do
		for bz = -N - 12, N + 12, 3 do
			if math.abs(bx) > N + 2 or math.abs(bz) > N + 2 then
				local alto = 0.5 + ((bx * 7 + bz * 13) % 5) * 0.4
				caja(bx, -1, bz, 3, alto + 1, 3, ((bx + bz) % 2 == 0) and Color3.fromRGB(226, 184, 118) or Color3.fromRGB(212, 168, 102))
			end
		end
	end
	for _, p in { { -N - 6, -8 }, { N + 5, 10 }, { -N - 8, 14 }, { N + 7, -14 }, { 12, N + 7 } } do
		palmera(p[1], p[2], 5)
	end
	for _, pir in { { -60, -70, 16 }, { 30, -80, 12 }, { 70, -50, 9 } } do
		for i = 0, pir[3] - 1 do
			caja(pir[1] - (pir[3] - i), i, pir[2] - (pir[3] - i), (pir[3] - i) * 2, 1, (pir[3] - i) * 2, PIEDRA[i % 2 + 1])
		end
	end
end

-- ---------- lo que dice cada uno ----------
local DIALOGOS = {
	imani = "Bienvenido al Refugio, cazador. Sekhmaur y Kheprak rondan los desiertos; Amaru y Apu Rumi, las montañas del Inti. Y ahora despertó la Selva de Obsidiana: Camazotz en el Templo de Xibalbá, Xolotl en el Cenote Sagrado, Balam en la selva y Cipactli en los Pantanos de Aztlán. Forja tu equipo con Nefra y habla con Tariq cuando estés listo.",
	sefu = "Anoto cada cacería en mi bestiario. Tráeme noticias de Sekhmaur: dicen que al romperle la melena despierta el guardián de las pirámides.",
	ammon = "Mis pociones siempre te esperan en la fogata del campamento. Pronto tendré mercancía nueva de las otras islas.",
}

function Refugio.hablar(jugador: Player, quien: string)
	if quien == "nefra" then
		Remotos.AbrirMenu:FireClient(jugador, "forja", RunService:IsStudio())
	elseif quien == "armeria" then
		Remotos.AbrirMenu:FireClient(jugador, "armeria")
	elseif quien == "tariq" then
		Remotos.AbrirMenu:FireClient(jugador, "viaje")
	elseif quien == "imani" then
		Remotos.AbrirMenu:FireClient(jugador, "historia")
	elseif quien == "sefu" then
		Remotos.AbrirMenu:FireClient(jugador, "encargos")
	else
		Remotos.AbrirMenu:FireClient(jugador, "dialogo", DIALOGOS[quien] or "...")
	end
end

-- ---------- forjar, elegir arma y ponerse armadura ----------
-- Solo una pieza por parte del cuerpo: al ponerse una, se quita la que ocupaba ese lugar.
function Refugio.ponerPieza(p, id: string)
	local ranura = Armas.RANURA[id]
	for i = #p.equipo, 1, -1 do
		if Armas.RANURA[p.equipo[i]] == ranura then
			table.remove(p.equipo, i)
		end
	end
	table.insert(p.equipo, id)
end
local function enRefugio(jugador: Player): boolean
	return jugador:GetAttribute("Zona") == "refugio"
end

function Refugio.iniciar()
	construir()
	Remotos.Forjar.OnServerEvent:Connect(function(jugador, tipo, id)
		if not enRefugio(jugador) then
			return
		end
		local p = Perfil.de(jugador)
		local receta, lista
		if tipo == "arma" and Armas.FORJABLES[id] then
			receta, lista = Armas.FORJABLES[id].receta, p.forjadas
		elseif tipo == "pieza" and Armas.ARMADURA[id] then
			receta, lista = Armas.ARMADURA[id].receta, p.armadura
		else
			return
		end
		if table.find(lista, id) or not Perfil.puedePagar(jugador, receta) then
			return
		end
		Perfil.pagar(jugador, receta)
		table.insert(lista, id)
		if tipo == "pieza" then
			Refugio.ponerPieza(p, id)
			if jugador.Character then
				Equipo.vestir(jugador.Character, p.equipo)
			end
		end
		Perfil.guardar(jugador)
		Remotos.Anuncio:FireClient(jugador, "¡Forjaste: " .. (tipo == "arma" and Armas.DATOS[id].nombre or Armas.ARMADURA[id].nombre) .. "!", Color3.fromRGB(255, 224, 138))
	end)
	Remotos.ElegirArma.OnServerEvent:Connect(function(jugador, id)
		local p = Perfil.de(jugador)
		if not enRefugio(jugador) or not Armas.DATOS[id] then
			return
		end
		if Armas.FORJABLES[id] and not table.find(p.forjadas, id) then
			return
		end
		p.arma = id
		if jugador.Character then
			Equipo.armar(jugador.Character, id)
		end
		Perfil.guardar(jugador)
		Remotos.Anuncio:FireClient(jugador, "Llevarás: " .. Armas.DATOS[id].nombre, Color3.fromRGB(243, 214, 160))
	end)
	Remotos.AlternarPieza.OnServerEvent:Connect(function(jugador, id)
		local p = Perfil.de(jugador)
		if not enRefugio(jugador) or not table.find(p.armadura, id) then
			return
		end
		local i = table.find(p.equipo, id)
		if i then
			table.remove(p.equipo, i)
		else
			Refugio.ponerPieza(p, id)
		end
		if jugador.Character then
			Equipo.vestir(jugador.Character, p.equipo)
		end
		Perfil.guardar(jugador)
	end)
	-- solo al probar en Studio: materiales para probar la forja sin cazar
	Remotos.MaterialesPrueba.OnServerEvent:Connect(function(jugador)
		if RunService:IsStudio() then
			-- de todos los materiales que existen, para probar la forja
			local premios = { monedas = 12000 }
			for _, k in Armas.ORDEN_MATERIALES do
				premios[k] = 20
			end
			Perfil.dar(jugador, premios)
		end
	end)
end

function Refugio.aparicion(): CFrame
	return CFrame.new(Refugio.CENTRO + Vector3.new(math.random(-6, 6), 5, 64 + math.random(-4, 4)))
end

return Refugio
