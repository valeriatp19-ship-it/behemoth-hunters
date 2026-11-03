--!nonstrict
-- Cuerpo de bloques igual para todos los cazadores y el probador donde se personaliza.
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(ReplicatedStorage.Compartido.Config)
local Apariencia = require(ReplicatedStorage.Compartido.Apariencia)
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Mundo = require(script.Parent.Mundo)
local Servidores = require(ReplicatedStorage.Compartido.Servidores)
local Perfil = require(script.Parent.Perfil)
local Equipo = require(script.Parent.Equipo)

local C = Config.COLORES
local Personaje = {}
local PROBADOR = Vector3.new(0, 600, 0)
local CABEZA = 1.4
-- Proporciones del cazador (más altas que el R6 clásico, como en la imagen de los sets):
-- Roblox calcula la altura de un R6 con el tamaño de la pierna, así que esto basta.
local PIERNA = 2.6
local BRAZO = 2.4
Personaje.PIERNA, Personaje.BRAZO = PIERNA, BRAZO
local apariencias = {}
local listas = {}
local almacen
pcall(function()
	almacen = DataStoreService:GetDataStore("ApariencaCazadoras")
end)

-- ---------- el cuerpo de bloques (R6) ----------
local function parte(nombre: string, tam: Vector3, modelo: Model): BasePart
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tam
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = modelo
	return p
end

local function motor(nombre: string, p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame)
	local m = Instance.new("Motor6D")
	m.Name = nombre
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.Parent = p0
end

local function plantilla(): Model
	local m = Instance.new("Model")
	m.Name = "StarterCharacter"
	local raiz = parte("HumanoidRootPart", Vector3.new(2, 2, 1), m)
	raiz.Transparency = 1
	raiz.CanCollide = false
	local torso = parte("Torso", Vector3.new(2, 2, 1), m)
	local cabeza = parte("Head", Vector3.new(CABEZA, CABEZA, CABEZA), m)
	local bd = parte("Right Arm", Vector3.new(1, BRAZO, 1), m)
	local bi = parte("Left Arm", Vector3.new(1, BRAZO, 1), m)
	local pd = parte("Right Leg", Vector3.new(1, PIERNA, 1), m)
	local pi = parte("Left Leg", Vector3.new(1, PIERNA, 1), m)
	local giro = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	local der = CFrame.new(0, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
	local izq = CFrame.new(0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
	motor("RootJoint", raiz, torso, giro, giro)
	motor("Neck", torso, cabeza, CFrame.new(0, 1, 0) * giro, CFrame.new(0, -CABEZA / 2, 0) * giro)
	motor("Right Shoulder", torso, bd, CFrame.new(1, 0.5, 0) * der, CFrame.new(-0.5, BRAZO / 2 - 0.5, 0) * der)
	motor("Left Shoulder", torso, bi, CFrame.new(-1, 0.5, 0) * izq, CFrame.new(0.5, BRAZO / 2 - 0.5, 0) * izq)
	motor("Right Hip", torso, pd, CFrame.new(1, -1, 0) * der, CFrame.new(0.5, PIERNA / 2, 0) * der)
	motor("Left Hip", torso, pi, CFrame.new(-1, -1, 0) * izq, CFrame.new(-0.5, PIERNA / 2, 0) * izq)
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.HipHeight = 0
	hum.Parent = m
	m.PrimaryPart = raiz
	return m
end

-- ---------- aplicar la apariencia ----------
local function pieza(carpeta: Folder, cabeza: BasePart, tam: Vector3, pos: Vector3, color: Color3, brilla: boolean?)
	local p = Instance.new("Part")
	p.Size = tam
	p.Color = color
	p.Material = brilla and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local w = Instance.new("Weld")
	w.Part0 = cabeza
	w.Part1 = p
	w.C0 = CFrame.new(pos)
	w.Parent = p
	p.CFrame = cabeza.CFrame * CFrame.new(pos)
	p.Parent = carpeta
	return p
end

function Personaje.aplicar(char: Model, ap)
	local vieja = char:FindFirstChild("Apariencia")
	if vieja then
		vieja:Destroy()
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Apariencia"
	carpeta.Parent = char
	local piel = Apariencia.PIELES[ap.piel]
	local ropa = Apariencia.ROPAS[ap.ropa]
	local pelo = Apariencia.COLORES_PELO[ap.colorPelo]
	local ojos = Apariencia.COLORES_OJOS[ap.colorOjos]
	local cabeza = char:FindFirstChild("Head") :: BasePart
	local torso = char:FindFirstChild("Torso") :: BasePart
	if not cabeza or not torso then
		return
	end
	for _, d in char:GetChildren() do
		if d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("Accessory") or d:IsA("BodyColors") then
			d:Destroy()
		end
	end
	local cara = cabeza:FindFirstChild("face")
	if cara then
		cara:Destroy()
	end
	cabeza.Color = piel
	torso.Color = ropa
	local pantalon = Color3.fromRGB(96, 72, 52)
	for _, n in { "Right Arm", "Left Arm" } do
		local b = char:FindFirstChild(n) :: BasePart
		if b then
			b.Color = piel
			pieza(carpeta, b, Vector3.new(1.04, 0.9, 1.04), Vector3.new(0, BRAZO / 2 - 0.44, 0), ropa)
		end
	end
	for _, n in { "Right Leg", "Left Leg" } do
		local p = char:FindFirstChild(n) :: BasePart
		if p then
			p.Color = pantalon
		end
	end
	local h = CABEZA
	local u = h / 8
	local z = -h / 2 - 0.02
	local negro = Color3.fromRGB(24, 20, 20)
	local blanco = Color3.fromRGB(245, 242, 235)
	-- ojos
	for _, lado in { -1, 1 } do
		local x = lado * 1.6 * u
		local y = 0.4 * u
		if ap.ojos == 1 then
			pieza(carpeta, cabeza, Vector3.new(1.2 * u, 1.2 * u, 0.05), Vector3.new(x, y, z), ojos)
		elseif ap.ojos == 2 then
			pieza(carpeta, cabeza, Vector3.new(2 * u, 2 * u, 0.05), Vector3.new(x, y, z), blanco)
			pieza(carpeta, cabeza, Vector3.new(1 * u, 1.3 * u, 0.06), Vector3.new(x - lado * 0.3 * u, y - 0.2 * u, z - 0.01), ojos)
		elseif ap.ojos == 3 then
			pieza(carpeta, cabeza, Vector3.new(2 * u, 0.8 * u, 0.05), Vector3.new(x, y, z), ojos)
		elseif ap.ojos == 4 then
			pieza(carpeta, cabeza, Vector3.new(1.2 * u, 1.2 * u, 0.05), Vector3.new(x, y, z), ojos)
			pieza(carpeta, cabeza, Vector3.new(1.9 * u, 0.4 * u, 0.06), Vector3.new(x + lado * 0.2 * u, y + 0.8 * u, z - 0.01), negro)
		else
			pieza(carpeta, cabeza, Vector3.new(0.7 * u, 0.5 * u, 0.05), Vector3.new(x - 0.5 * u, y, z), negro)
			pieza(carpeta, cabeza, Vector3.new(0.7 * u, 0.5 * u, 0.05), Vector3.new(x + 0.5 * u, y, z), negro)
			pieza(carpeta, cabeza, Vector3.new(0.6 * u, 0.5 * u, 0.05), Vector3.new(x, y + 0.45 * u, z), negro)
		end
	end
	-- boca
	local by = -1.8 * u
	local labio = Color3.fromRGB(120, 40, 40)
	if ap.boca == 1 then
		pieza(carpeta, cabeza, Vector3.new(2 * u, 0.5 * u, 0.05), Vector3.new(0, by, z), labio)
		pieza(carpeta, cabeza, Vector3.new(0.5 * u, 0.5 * u, 0.05), Vector3.new(-1.25 * u, by + 0.5 * u, z), labio)
		pieza(carpeta, cabeza, Vector3.new(0.5 * u, 0.5 * u, 0.05), Vector3.new(1.25 * u, by + 0.5 * u, z), labio)
	elseif ap.boca == 2 then
		pieza(carpeta, cabeza, Vector3.new(2.4 * u, 0.5 * u, 0.05), Vector3.new(0, by, z), labio)
	elseif ap.boca == 3 then
		pieza(carpeta, cabeza, Vector3.new(1.6 * u, 1.1 * u, 0.05), Vector3.new(0, by, z), Color3.fromRGB(90, 24, 28))
		pieza(carpeta, cabeza, Vector3.new(1.4 * u, 0.3 * u, 0.06), Vector3.new(0, by + 0.35 * u, z - 0.01), blanco)
	elseif ap.boca == 4 then
		pieza(carpeta, cabeza, Vector3.new(2 * u, 0.5 * u, 0.05), Vector3.new(0, by, z), labio)
		pieza(carpeta, cabeza, Vector3.new(0.5 * u, 0.5 * u, 0.05), Vector3.new(1.25 * u, by + 0.5 * u, z), labio)
	else
		pieza(carpeta, cabeza, Vector3.new(2 * u, 0.5 * u, 0.05), Vector3.new(0, by + 0.3 * u, z), labio)
		pieza(carpeta, cabeza, Vector3.new(0.5 * u, 0.5 * u, 0.05), Vector3.new(-1.25 * u, by - 0.2 * u, z), labio)
		pieza(carpeta, cabeza, Vector3.new(0.5 * u, 0.5 * u, 0.05), Vector3.new(1.25 * u, by - 0.2 * u, z), labio)
	end
	-- extra
	if ap.extra == 2 then
		for _, lado in { -1, 1 } do
			for k = 0, 2 do
				pieza(carpeta, cabeza, Vector3.new(0.3 * u, 0.3 * u, 0.05), Vector3.new(lado * (2.2 + (k % 2) * 0.6) * u, (-0.7 - k * 0.4) * u, z), Color3.fromRGB(170, 100, 60))
			end
		end
	elseif ap.extra == 3 then
		for _, lado in { -1, 1 } do
			pieza(carpeta, cabeza, Vector3.new(2.2 * u, 0.5 * u, 0.05), Vector3.new(lado * 1.9 * u, -0.8 * u, z), C.turquesa)
		end
	elseif ap.extra == 4 then
		for k = 0, 2 do
			pieza(carpeta, cabeza, Vector3.new(0.4 * u, 0.4 * u, 0.06), Vector3.new((1.1 + k * 0.4) * u, (1.4 - k * 0.6) * u, z - 0.01), Color3.fromRGB(170, 70, 70))
		end
	elseif ap.extra == 5 then
		for _, lado in { -1, 1 } do
			pieza(carpeta, cabeza, Vector3.new(0.35 * u, 1.3 * u, 0.05), Vector3.new(lado * 2.9 * u, -0.9 * u, z), C.oro)
		end
	end
	-- pelo (se marca para poder esconderlo bajo la capucha)
	local antesDelPelo = #carpeta:GetChildren()
	local est = ap.pelo
	if est == 1 or est == 8 then
		pieza(carpeta, cabeza, Vector3.new(h * 1.02, 0.12, h * 1.02), Vector3.new(0, h / 2 + 0.02, 0), pelo)
	else
		pieza(carpeta, cabeza, Vector3.new(h * 1.08, 0.35, h * 1.08), Vector3.new(0, h / 2 + 0.12, 0), pelo)
		pieza(carpeta, cabeza, Vector3.new(h * 1.08, h * 0.55, 0.22), Vector3.new(0, h * 0.2, h / 2 + 0.09), pelo)
		for _, lado in { -1, 1 } do
			pieza(carpeta, cabeza, Vector3.new(0.14, h * 0.35, h * 0.9), Vector3.new(lado * (h / 2 + 0.05), h * 0.3, 0.05), pelo)
		end
	end
	if est == 3 then
		pieza(carpeta, cabeza, Vector3.new(h * 0.95, 0.3, 0.14), Vector3.new(-0.08, h / 2 - 0.12, -h / 2 - 0.06), pelo)
		pieza(carpeta, cabeza, Vector3.new(h * 0.4, 0.28, 0.14), Vector3.new(-h * 0.25, h / 2 - 0.38, -h / 2 - 0.06), pelo)
	elseif est == 4 then
		pieza(carpeta, cabeza, Vector3.new(h * 1.08, h * 1.3, 0.26), Vector3.new(0, -h * 0.2, h / 2 + 0.12), pelo)
		for _, lado in { -1, 1 } do
			pieza(carpeta, cabeza, Vector3.new(0.16, h * 1.1, h * 0.5), Vector3.new(lado * (h / 2 + 0.06), -h * 0.1, h * 0.2), pelo)
		end
	elseif est == 5 then
		pieza(carpeta, cabeza, Vector3.new(0.4, 0.4, 0.5), Vector3.new(0, h * 0.25, h / 2 + 0.35), pelo)
		pieza(carpeta, cabeza, Vector3.new(0.32, 1.1, 0.32), Vector3.new(0, -h * 0.25, h / 2 + 0.55), pelo)
	elseif est == 6 then
		for _, lado in { -1, 1 } do
			for k = 0, 3 do
				pieza(carpeta, cabeza, Vector3.new(0.3, 0.32, 0.3), Vector3.new(lado * (h / 2 + 0.12), -k * 0.34, 0.2), k % 2 == 0 and pelo or pelo:Lerp(Color3.new(0, 0, 0), 0.25))
			end
		end
	elseif est == 7 then
		pieza(carpeta, cabeza, Vector3.new(0.65, 0.55, 0.65), Vector3.new(0, h / 2 + 0.45, 0.25), pelo)
	elseif est == 8 then
		-- cresta: una franja alta de adelante hacia atrás
		for k = 0, 3 do
			pieza(carpeta, cabeza, Vector3.new(0.32, 0.45 + (k == 1 and 0.15 or 0), 0.36), Vector3.new(0, h / 2 + 0.28, -h * 0.36 + k * 0.4), pelo)
		end
	elseif est == 9 then
		-- rastas colgando alrededor de la nuca
		for k = 0, 6 do
			local ang = math.rad(-80 + k * 26.7)
			local rx, rz = math.sin(ang) * (h / 2 + 0.1), math.cos(ang) * (h / 2 + 0.1)
			pieza(carpeta, cabeza, Vector3.new(0.22, 1.2 + (k % 2) * 0.3, 0.22), Vector3.new(rx, -0.25, rz), k % 2 == 0 and pelo or pelo:Lerp(Color3.new(0, 0, 0), 0.2))
		end
	elseif est == 10 then
		-- melena por los hombros con flequillo recto
		pieza(carpeta, cabeza, Vector3.new(h * 1.08, h * 0.9, 0.24), Vector3.new(0, -h * 0.05, h / 2 + 0.12), pelo)
		for _, lado in { -1, 1 } do
			pieza(carpeta, cabeza, Vector3.new(0.16, h * 0.85, h * 0.8), Vector3.new(lado * (h / 2 + 0.06), -h * 0.05, 0.1), pelo)
		end
		pieza(carpeta, cabeza, Vector3.new(h * 1.02, 0.26, 0.14), Vector3.new(0, h / 2 - 0.1, -h / 2 - 0.06), pelo)
	elseif est == 11 then
		-- erizo: puntas hacia arriba
		for _, pt in { { 0, 0 }, { -0.4, -0.3 }, { 0.4, -0.3 }, { -0.35, 0.35 }, { 0.35, 0.35 }, { 0, -0.5 } } do
			pieza(carpeta, cabeza, Vector3.new(0.3, 0.3, 0.3), Vector3.new(pt[1], h / 2 + 0.42, pt[2]), pelo)
			pieza(carpeta, cabeza, Vector3.new(0.16, 0.22, 0.16), Vector3.new(pt[1], h / 2 + 0.66, pt[2]), pelo)
		end
	elseif est == 12 then
		-- raya al lado: flequillo peinado hacia un costado
		pieza(carpeta, cabeza, Vector3.new(h * 0.75, 0.32, 0.16), Vector3.new(-h * 0.15, h / 2 - 0.08, -h / 2 - 0.07), pelo)
		pieza(carpeta, cabeza, Vector3.new(0.3, 0.5, 0.16), Vector3.new(-h * 0.42, h / 2 - 0.4, -h / 2 - 0.07), pelo)
		pieza(carpeta, cabeza, Vector3.new(0.08, 0.06, h * 0.9), Vector3.new(h * 0.18, h / 2 + 0.3, 0), pelo:Lerp(Color3.new(1, 1, 1), 0.25))
	elseif est == 13 then
		-- afro: un gran bloque redondeado de pelo
		pieza(carpeta, cabeza, Vector3.new(h * 1.4, h * 0.95, h * 1.4), Vector3.new(0, h * 0.42, 0.06), pelo)
		pieza(carpeta, cabeza, Vector3.new(h * 1.2, h * 0.25, h * 1.2), Vector3.new(0, h * 0.95, 0.06), pelo)
	end
	for i, x in carpeta:GetChildren() do
		if i > antesDelPelo then
			x:SetAttribute("Pelo", true)
		end
	end
end

-- ---------- el probador (una plataforma alejada del desierto) ----------
-- Cada jugador tiene su propio probador, separados para que nadie se cruce.
local probadores = {} -- número de probador -> jugador que lo usa
local probadorDe = {} -- jugador -> número de probador
local construidos = {}

local function origenProbador(i: number): Vector3
	return PROBADOR + Vector3.new((i - 1) * 300, 0, 0)
end

local function construirProbador(i: number)
	if construidos[i] then
		return
	end
	construidos[i] = true
	local p = origenProbador(i)
	local arena = { Color3.fromRGB(228, 186, 120), Color3.fromRGB(214, 170, 104) }
	for x = -5, 5 do
		for z = -5, 5 do
			Mundo.parte({ Name = "Probador", Size = Vector3.new(4, 4, 4), Position = p + Vector3.new(x * 4, -2, z * 4), Color = arena[(x + z) % 2 + 1] })
		end
	end
	-- pedestal de piedra con borde dorado
	Mundo.parte({ Name = "Pedestal", Size = Vector3.new(8, 1, 8), Position = p + Vector3.new(0, 0.5, 0), Color = C.piedra })
	Mundo.parte({ Name = "Pedestal", Size = Vector3.new(6, 1, 6), Position = p + Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(200, 164, 110) })
	Mundo.parte({ Name = "Borde", Size = Vector3.new(6.2, 0.3, 6.2), Position = p + Vector3.new(0, 2.05, 0), Color = C.oro, Material = Enum.Material.Neon })
	-- fondo: pirámide, obeliscos y antorchas
	for i = 0, 7 do
		local ancho = (8 - i) * 4
		Mundo.parte({ Name = "Piramide", Size = Vector3.new(ancho, 4, ancho), Position = p + Vector3.new(0, 2 + i * 4, 30), Color = i % 2 == 0 and C.piedra or Color3.fromRGB(200, 164, 110) })
	end
	for _, lado in { -1, 1 } do
		Mundo.parte({ Name = "Obelisco", Size = Vector3.new(3, 16, 3), Position = p + Vector3.new(lado * 14, 8, 12), Color = C.piedra })
		Mundo.parte({ Name = "Punta", Size = Vector3.new(1.6, 1.6, 1.6), Position = p + Vector3.new(lado * 14, 16.8, 12), Color = C.oro, Material = Enum.Material.Neon })
		Mundo.parte({ Name = "Jeroglifico", Size = Vector3.new(1, 1, 0.2), Position = p + Vector3.new(lado * 14, 10, 10.4), Color = C.turquesa, Material = Enum.Material.Neon })
		local antorcha = Mundo.parte({ Name = "Antorcha", Size = Vector3.new(0.8, 6, 0.8), Position = p + Vector3.new(lado * 7, 3, 4), Color = Color3.fromRGB(110, 75, 45) })
		local fuego = Mundo.parte({ Name = "Fuego", Size = Vector3.new(1.2, 1.2, 1.2), Position = antorcha.Position + Vector3.new(0, 3.6, 0), Color = Color3.fromRGB(255, 150, 60), Material = Enum.Material.Neon })
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 170, 90)
		luz.Range = 20
		luz.Brightness = 1.5
		luz.Parent = fuego
	end
end

-- ---------- conexión ----------
-- Carga el cuerpo de el cazador (con la función nueva de Roblox, o la antigua de respaldo).
local function cargar(jugador: Player)
	local ok = pcall(function()
		jugador:LoadCharacterAsync()
	end)
	if not ok and jugador.Parent then
		(jugador :: any):LoadCharacter()
	end
end

-- campamentos: zona de caza -> CFrame del campamento (las islas se agregan al construirse)
function Personaje.iniciar(campamentos: { [string]: CFrame }, refugioOpcional: (() -> CFrame)?, alEquipar)
	-- en un servidor de cacería no hay Refugio: por si acaso, se vuelve a algún campamento
	local refugio: () -> CFrame = refugioOpcional or function()
		local _, c = next(campamentos)
		return c or CFrame.new(0, 100, 0)
	end
	Players.CharacterAutoLoads = false
	StarterPlayer.LoadCharacterAppearance = false
	local vieja = StarterPlayer:FindFirstChild("StarterCharacter")
	if vieja then
		vieja:Destroy()
	end
	plantilla().Parent = StarterPlayer
	local modo = Servidores.modo()
	if modo ~= "caceria" then
		construirProbador(1)
	end

	local function asignarProbador(jugador: Player): Vector3
		local i = probadorDe[jugador]
		if not i then
			i = 1
			while probadores[i] do
				i += 1
			end
			probadores[i] = jugador
			probadorDe[jugador] = i
			construirProbador(i)
		end
		return origenProbador(i)
	end

	local function liberarProbador(jugador: Player)
		local i = probadorDe[jugador]
		if i then
			probadores[i] = nil
			probadorDe[jugador] = nil
		end
	end

	-- lleva al cazador a su probador (al entrar por primera vez o desde el espejo del Refugio)
	local function alProbador(jugador: Player, char: Model, ap)
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end
		jugador:SetAttribute("Zona", "probador")
		Equipo.vestir(char, {}) -- sin armadura, para ver bien la cara y el pelo
		Equipo.desarmar(char)
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(asignarProbador(jugador) + Vector3.new(0, 5 + PIERNA - 2, 0)) * CFrame.Angles(0, math.pi, 0)
		Remotos.AbrirProbador:FireClient(jugador, ap)
	end

	function Personaje.abrirProbador(jugador: Player)
		local char = jugador.Character
		if not char or jugador:GetAttribute("Zona") ~= "refugio" then
			return
		end
		listas[jugador] = false
		alProbador(jugador, char, apariencias[jugador] or Apariencia.defecto())
	end

	-- Lleva a el cazador a una zona: "refugio" (sin arma) o "desierto" (con su arma).
	function Personaje.llevar(jugador: Player, zona: string)
		local char = jugador.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not char or not hrp then
			return
		end
		if Config.ISLAS[zona] then
			-- si la isla todavía se está construyendo (servidor de caza recién abierto), se espera
			local limite = os.clock() + 20
			while not campamentos[zona] and os.clock() < limite do
				task.wait(0.2)
			end
		end
		jugador:SetAttribute("Zona", zona)
		hrp.Anchored = false
		if Config.ISLAS[zona] and campamentos[zona] then
			hrp.CFrame = campamentos[zona] + Vector3.new(math.random(-4, 4), 3, math.random(-4, 4))
		else
			hrp.CFrame = refugio()
		end
		alEquipar(jugador, char, true) -- en el Refugio también se lleva el arma (sin poder atacar)
	end

	local function alAparecer(jugador: Player, char: Model)
		local ap = apariencias[jugador] or Apariencia.defecto()
		Personaje.aplicar(char, ap)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		char:WaitForChild("HumanoidRootPart")
		hum.Died:Connect(function()
			task.delay(5, function()
				if jugador.Parent then
					cargar(jugador)
				end
			end)
		end)
		task.wait(0.1)
		if listas[jugador] then
			-- al desmayarse en una cacería se vuelve al campamento; si no, al Refugio
			local zona = jugador:GetAttribute("Zona")
			Personaje.llevar(jugador, Config.ISLAS[zona] and zona or "refugio")
		else
			alProbador(jugador, char, ap)
		end
	end

	local function conectar(jugador: Player)
		local ap = Apariencia.defecto()
		if almacen then
			local ok, guardada = pcall(function()
				return almacen:GetAsync("ap_" .. jugador.UserId)
			end)
			if ok and guardada then
				ap = Apariencia.limpiar(guardada)
				if modo ~= "caceria" then
					-- ya creó su cazador antes: directo al Refugio (puede cambiarlo en el espejo)
					listas[jugador] = true
					jugador:SetAttribute("Zona", "refugio")
				end
			end
		end
		apariencias[jugador] = ap
		local datosViaje = jugador:GetJoinData()
		if modo == "caceria" then
			-- llega desde el Refugio con su grupo: directo al campamento de la isla elegida
			local td = datosViaje and datosViaje.TeleportData
			local zona = (type(td) == "table" and Config.ISLAS[td.zona]) and td.zona or "desierto"
			listas[jugador] = true
			jugador:SetAttribute("Zona", zona)
			if type(td) == "table" and type(td.presa) == "string" then
				jugador:SetAttribute("Presa", td.presa)
			end
		elseif modo == "lobby" and datosViaje and datosViaje.SourcePlaceId == Servidores.CACERIA then
			-- vuelve de una cacería: no pasa otra vez por el probador
			listas[jugador] = true
			jugador:SetAttribute("Zona", "refugio")
		end
		jugador.CharacterAdded:Connect(function(char)
			alAparecer(jugador, char)
		end)
		Perfil.esperar(jugador) -- para aparecer ya con su arma y su armadura
		cargar(jugador)
	end
	Players.PlayerAdded:Connect(conectar)
	for _, j in Players:GetPlayers() do
		task.spawn(conectar, j)
	end
	-- si alguien se cae del Refugio o del probador, vuelve arriba (no llega al desierto)
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, j in Players:GetPlayers() do
				local zona = j:GetAttribute("Zona")
				local hrp = j.Character and j.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local cayo = hrp and ((zona == "refugio" and hrp.Position.Y < 860) or (zona == "probador" and hrp.Position.Y < PROBADOR.Y - 40))
				if hrp and cayo then
					if zona == "refugio" then
						hrp.CFrame = refugio()
					else
						hrp.CFrame = CFrame.new(asignarProbador(j) + Vector3.new(0, 5 + PIERNA - 2, 0)) * CFrame.Angles(0, math.pi, 0)
					end
					hrp.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(j)
		liberarProbador(j)
		apariencias[j] = nil
		listas[j] = nil
	end)

	Remotos.Apariencia.OnServerEvent:Connect(function(jugador, datos)
		local ap = Apariencia.limpiar(datos)
		apariencias[jugador] = ap
		if jugador.Character then
			Personaje.aplicar(jugador.Character, ap)
		end
	end)

	Remotos.Listo.OnServerEvent:Connect(function(jugador)
		if listas[jugador] then
			return
		end
		listas[jugador] = true
		local ap = apariencias[jugador]
		if almacen and ap then
			task.spawn(pcall, function()
				almacen:SetAsync("ap_" .. jugador.UserId, ap)
			end)
		end
		liberarProbador(jugador)
		Personaje.llevar(jugador, "refugio")
	end)
end

return Personaje
