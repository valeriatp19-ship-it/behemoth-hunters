--!nonstrict
-- El Desierto de Brasa (isla de Kheprak): dunas rojizas, grietas de lava, agujas de obsidiana y humo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Compartido.Config)
local Mundo = require(script.Parent.Mundo)
local Terreno = require(script.Parent.Terreno)

local S = Config.S
local ISLA = Config.ISLAS.brasa
local O = ISLA.centro
local Mapa = {}
local carpeta: Folder

local function b(pos: Vector3, tam: Vector3, color: Color3, props)
	local t = { Name = "Brasa", Size = tam, Position = pos, Color = color, Parent = carpeta }
	for k, v in props or {} do
		t[k] = v
	end
	return Mundo.parte(t)
end

local function suelo(xm: number, zm: number): Vector3
	local x, z = O.X + xm * S, O.Z + zm * S
	return Vector3.new(x, Config.alturaEn(x, z), z)
end

local LAVA = Color3.fromRGB(255, 110, 30)

local function aguja(xm, zm, radio)
	local p = suelo(xm, zm)
	local alto = radio * 7
	for i = 0, alto - 1 do
		local ancho = math.max(1.2, (radio * 2.2) * (1 - i / alto)) * S
		b(p + Vector3.new(((i * 7) % 3 - 1) * 0.4, (i + 0.5) * S, ((i * 5) % 3 - 1) * 0.4), Vector3.new(ancho, S, ancho), i % 2 == 0 and Color3.fromRGB(28, 22, 30) or Color3.fromRGB(40, 32, 42), { CanCollide = true })
		if i % 3 == 1 then
			b(p + Vector3.new(ancho / 2, (i + 0.5) * S, 0), Vector3.new(0.4, S * 0.8, 0.8), LAVA, { Material = Enum.Material.Neon, CanCollide = false })
		end
	end
end

local function humo(xm, zm)
	local p = suelo(xm, zm)
	local grieta = b(p + Vector3.new(0, 0.2, 0), Vector3.new(4, 0.4, 4), LAVA, { Material = Enum.Material.Neon, CanCollide = false })
	local h = Instance.new("Smoke")
	h.Color = Color3.fromRGB(70, 60, 60)
	h.Size = 6
	h.RiseVelocity = 7
	h.Opacity = 0.35
	h.Parent = grieta
	local luz = Instance.new("PointLight")
	luz.Color = LAVA
	luz.Range = 18
	luz.Brightness = 1.5
	luz.Parent = grieta
end

local function arbolMuerto(xm, zm)
	local p = suelo(xm, zm)
	for i = 0, 4 do
		b(p + Vector3.new((i % 2) * 0.3, i * 1.6 + 0.8, 0), Vector3.new(0.9, 1.6, 0.9), Color3.fromRGB(50, 36, 30))
	end
	for _, r in { { 1, 5.5, 0.4 }, { -1, 6.5, -0.3 }, { 0.5, 7.2, 1 } } do
		b(p + Vector3.new(r[1] * 1.4, r[2], r[3]), Vector3.new(2.6, 0.5, 0.5), Color3.fromRGB(56, 40, 32))
	end
end

local function campamento(): CFrame
	local c = ISLA.campamento
	local p = suelo(c.X, c.Y)
	local fogata = b(p + Vector3.new(0, 0.6, 0), Vector3.new(6, 1.2, 6), Color3.fromRGB(60, 50, 46))
	b(p + Vector3.new(0, 1.8, 0), Vector3.new(3, 1.2, 3), Color3.fromRGB(255, 140, 50), { Material = Enum.Material.Neon, CanCollide = false })
	local f = Instance.new("Fire")
	f.Size = 7
	f.Parent = fogata
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 170, 90)
	luz.Range = 30
	luz.Parent = fogata
	for _, lado in { -1, 1 } do
		for n = 0, 3 do
			b(p + Vector3.new(lado * 20, 1 + n * 1.8, -9), Vector3.new(11 - n * 2.4, 1.8, 11), n % 2 == 0 and Color3.fromRGB(150, 50, 40) or Color3.fromRGB(220, 180, 120))
		end
	end
	local caravana = b(p + Vector3.new(-9, 1.8, 12), Vector3.new(3.6, 3.6, 7), Color3.fromRGB(200, 150, 90))
	caravana.Name = "Caravana"
	local volver = Instance.new("ProximityPrompt")
	volver.Name = "VolverRefugio"
	volver.ActionText = "Volver al Refugio"
	volver.ObjectText = "Caravana"
	volver.MaxActivationDistance = 12
	volver.RequiresLineOfSight = false
	volver.GamepadKeyCode = Enum.KeyCode.ButtonL1
	volver.Parent = caravana
	return CFrame.new(suelo(c.X, c.Y + 3) + Vector3.new(0, 4, 0))
end

function Mapa.construir(): CFrame
	carpeta = Instance.new("Folder")
	carpeta.Name = "DesiertoDeBrasa"
	carpeta.Parent = workspace
	-- dunas rojizas, más oscuras arriba, con grietas de lava en las zonas bajas
	local V = Config.VOX
	Terreno.construir(carpeta, O, V, 200, function(x, z)
		return Config.alturaEn(x, z)
	end, function(h, x, z)
		local nivel = math.floor(h / V)
		if h < 6 and ((math.floor(x / V) * 7 + math.floor(z / V) * 13) % 23 == 0) then
			return "lava", LAVA
		end
		if h > 40 then
			return "n" .. (nivel % 2), nivel % 2 == 0 and Color3.fromRGB(46, 30, 28) or Color3.fromRGB(58, 38, 34)
		end
		local tonos = { Color3.fromRGB(150, 70, 42), Color3.fromRGB(128, 58, 36), Color3.fromRGB(104, 48, 32) }
		return "a" .. (nivel % 3), tonos[nivel % 3 + 1]
	end)
	for _, x in carpeta:GetChildren() do
		if x.Color == LAVA then
			x.Material = Enum.Material.Neon -- las grietas de lava brillan
		end
	end
	for _, o in Config.OBSTACULOS_BRASA do
		aguja(o[1], o[2], o[3])
	end
	local rng = Random.new(61)
	for _ = 1, 9 do
		humo(rng:NextNumber(-110, 110), rng:NextNumber(-110, 60))
	end
	for _ = 1, 12 do
		arbolMuerto(rng:NextNumber(-115, 115), rng:NextNumber(-115, 70))
	end
	return campamento()
end

return Mapa
