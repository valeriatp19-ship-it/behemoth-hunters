--!nocheck
-- Prueba las armas nuevas con el Combate de verdad: cada arma ataca (ligero y fuerte) a un
-- Behemoth de la selva; revisa que no haya errores y que el daño llegue. También prueba las
-- esquivas perfectas con los sets de la selva puestos.
local roblox = require("@lune/roblox")
local Motor = require("./motor")
local Vector3, CFrame = roblox.Vector3, Motor.CFrame
local SRC = "src" -- se corre desde la raíz del repositorio
Motor.esServidor = true
local juego = Motor.crearJuego()
local RS = juego:GetService("ReplicatedStorage")
local SSS = juego:GetService("ServerScriptService")
local ws = Motor.workspace
Motor.carpeta(RS, "Compartido", SRC .. "/compartido")
local servidor = Motor.carpeta(SSS, "Servidor", SRC .. "/servidor")
local carpeta = Motor.Instance.new("Folder")
carpeta.Name = "Behemoths"
carpeta.Parent = ws
local Config = Motor.require(RS.Compartido.Config)
local Armas = Motor.require(RS.Compartido.Armas)
local Remotos = Motor.require(RS.Compartido.Remotos)
local Combate = Motor.require(servidor.Combate)
local S = Config.S
local RunService = juego:GetService("RunService")

local Players = juego:GetService("Players")
local j = Motor.Instance.new("Player")
j.Name = "Cazadora"
j.Parent = Players
local char = Motor.Instance.new("Model")
char.Name = "Cazadora"
local hrp = Motor.Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Parent = char
local hum = Motor.Instance.new("Humanoid")
hum.Parent = char
char.Parent = ws
j.Character = char

local avisos = {}
Combate.iniciar(function()
	table.insert(avisos, "desmayo")
end)

local servicios = {
	jugadores = Combate.jugadores,
	danio = Combate.danio,
	anunciar = function() end,
	numero = function() end,
	recompensar = function() end,
	resultados = function() end,
}

local function avanzar(seg)
	local n = math.floor(seg / (1 / 30))
	for _ = 1, n do
		Motor.avanzar(1 / 30)
		RunService.Heartbeat:Fire(1 / 30)
	end
end

local total = 0
for _, nombre in { "Camazotz", "Xolotl", "Balam", "Cipactli" } do
	local Modulo = Motor.require(servidor[nombre])
	local b = Modulo.nuevo(servicios)
	b.vidaMax, b.vida = 1e7, 1e7
	b.pos = b:sueloM(0, 30)
	b.yaw = 0
	b.yVisual = b.pos.Y
	b.raiz.CFrame = CFrame.new(b.pos)
	b.estado = "vagar"
	Combate.agregarObjetivo(b)
	j:SetAttribute("Zona", b.def.zona)
	local familia
	for _, f in Armas.FAMILIAS do
		if f.nombre == nombre then
			familia = f
		end
	end
	for _, id in familia.armas do
		char:SetAttribute("Arma", id)
		local arma = Armas.DATOS[id]
		-- delante de la cabeza del Behemoth, mirándola
		local zona = b:zonas()[1]
		local frente = b.pos + b:_adelante() * 7 * S
		hrp.CFrame = CFrame.lookAt(Vector3.new(frente.X, b.pos.Y + 3, frente.Z), Vector3.new(zona.pos.X, b.pos.Y + 3, zona.pos.Z))
		if not arma.distancia then
			hrp.CFrame = CFrame.lookAt(Vector3.new(zona.pos.X, b.pos.Y + 3, zona.pos.Z) + b:_adelante() * 2.5 * S, Vector3.new(zona.pos.X, b.pos.Y + 3, zona.pos.Z))
		end
		local v0 = b.vida
		local errores0 = #Motor.errores
		if os.getenv and false then end
		if not arma.distancia and id == familia.armas[1] then
			local alcance = arma.combo[1].alcance * S
			local centro = hrp.Position + hrp.CFrame.LookVector * alcance * 0.55
			for _, z in b:zonas() do
				local d = z.pos - centro
				local dist = math.sqrt(d.X * d.X + d.Z * d.Z + (d.Y * 0.35) ^ 2) - z.r
				if dist < alcance * 0.62 then
					print("    alcanza", z.zona.nombre, dist, alcance * 0.62)
				end
			end
			print("    hrp", hrp.Position - b.pos, "mira", hrp.CFrame.LookVector, "hum", hum.Health, "zona", j:GetAttribute("Zona"))
		end
		for k = 1, 8 do
			Remotos.Ataque.OnServerEvent:Fire(j, "ligero", zona.pos)
			avanzar(0.9)
		end
		for k = 1, 3 do
			Remotos.Ataque.OnServerEvent:Fire(j, "fuerte", zona.pos)
			avanzar(1.6)
		end
		avanzar(6)
		b.estado = "vagar"
		b.alerta = false
		local hecho = v0 - b.vida
		total += 1
		print(("  %-9s %-18s %-14s daño %6.0f  errores %d"):format(nombre, id, arma.poderId, hecho, #Motor.errores - errores0))
	end
	-- sets: esquiva perfecta y golpes recibidos
	local f = familia
	j:SetAttribute("Zona", b.def.zona)
	for _, pieza in f.piezas do
		char:SetAttribute("Lleva_" .. pieza, true)
	end
	char:SetAttribute("Piezas_" .. f.set, 4)
	hum.MaxHealth = 150
	hum.Health = 40
	Remotos.Esquivar.OnServerEvent:Fire(j)
	avanzar(0.05)
	Combate.danio(j, 20, b.pos, 10, f.prefijo .. "zarpazo")
	avanzar(0.6)
	Combate.danio(j, 20, b.pos, 10, f.prefijo .. "zarpazo")
	print(("  set %-9s vida tras esquivar y recibir un golpe: %.0f"):format(f.set, hum.Health))
	char:SetAttribute("Piezas_" .. f.set, 0)
	hum.Health = 150
	b.vida = 0
	b:_morir()
	avanzar(1)
end
print("armas probadas:", total, "errores:", #Motor.errores)
for _, e in Motor.errores do
	print(e)
end
