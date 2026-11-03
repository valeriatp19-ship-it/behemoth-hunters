--!nocheck
-- Prueba cada ataque de un Behemoth de la selva: ¿golpea al cazador que se queda quieto?
-- ¿se puede esquivar saliendo del aviso rojo? uso: lune run ataques.luau <Modulo>
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Motor = require("./motor")
local Vector3, CFrame = roblox.Vector3, Motor.CFrame

local NOMBRE = process.args[1] or "Camazotz"
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
local S = Config.S

local j = Motor.Instance.new("Player")
j.Name = "Cazador"
j.Parent = juego:GetService("Players")
local char = Motor.Instance.new("Model")
local hrp = Motor.Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Parent = char
local hum = Motor.Instance.new("Humanoid")
hum.Parent = char
char.Parent = ws
j.Character = char

local recibido = {}
local servicios = {
	jugadores = function()
		return { { jugador = j, hrp = hrp, atacable = true } }
	end,
	danio = function(_, d, origen, empuje, ataque)
		table.insert(recibido, { d = d, ataque = ataque, empuje = empuje })
		return true
	end,
	anunciar = function() end,
	numero = function() end,
	recompensar = function() end,
	resultados = function() end,
}
local Modulo = Motor.require(servidor[NOMBRE])
local b = Modulo.nuevo(servicios)
local def = Modulo.def

local function enAviso(p)
	for _, a in { b.avisoCirculo, b.avisoRect, table.unpack(b.avisosExtra) } do
		if a.Transparency < 1 then
			local rel = a.CFrame:PointToObjectSpace(p)
			if a.Shape == roblox.Enum.PartType.Cylinder then
				if math.sqrt(rel.Y ^ 2 + rel.Z ^ 2) < a.Size.Y / 2 then
					return a
				end
			elseif math.abs(rel.X) < a.Size.X / 2 and math.abs(rel.Z) < a.Size.Z / 2 then
				return a
			end
		end
	end
	return nil
end

-- distancias de prueba para cada ataque (metros delante del Behemoth)
local DIST = def.distanciasPrueba or {}
local function probar(nombre, dist, lado, esquivar, preparar)
	b:reiniciar()
	b.pos = b:sueloM(table.unpack(({ cenote = { 0, 52 }, pantano = { 10, -30 } })[b.def.zona] or { 0, -30 }))
	b.yaw = 0
	b.yVisual = b.pos.Y
	b.alerta = true
	b.estado = "perseguir"
	if preparar then
		preparar(b)
	end
	local frente = b:_adelante()
	local derecha = Vector3.new(-frente.Z, 0, frente.X)
	local p = b.pos + frente * dist * S + derecha * (lado or 0) * S
	hrp.CFrame = CFrame.new(p.X, b:altura(p.X, p.Z) + 3, p.Z)
	b.objetivo = { jugador = j, hrp = hrp, atacable = true }
	b.tObjetivo = 99
	table.clear(recibido)
	b:_iniciarAtaque(nombre)
	local t, maxAlto, vio = 0, 0, false
	local huida, sigue = nil, 0
	while b.estado == "ataque" and t < 12 do
		Motor.avanzar(1 / 30)
		b.tObjetivo = 99
		local ok, err = pcall(b.paso, b, 1 / 30)
		if not ok then
			print("  ERROR:", err)
			return
		end
		t += 1 / 30
		maxAlto = math.max(maxAlto, b.raiz.Position.Y - b.pos.Y)
		local a = enAviso(hrp.Position)
		if a then
			vio = true
		end
		if esquivar and a and t > 0.3 then
			-- corre hacia afuera del aviso (y sigue corriendo un momento después)
			local centro = a.Position
			local fuera = Vector3.new(hrp.Position.X - centro.X, 0, hrp.Position.Z - centro.Z)
			if a.Shape ~= roblox.Enum.PartType.Cylinder then
				fuera = a.CFrame.RightVector * (a.CFrame:PointToObjectSpace(hrp.Position).X >= 0 and 1 or -1)
			end
			if fuera.Magnitude < 0.1 then
				fuera = derecha
			end
			huida = fuera.Unit
			sigue = 0.6
		end
		if esquivar and huida and sigue > 0 then
			sigue -= 1 / 30
			hrp.CFrame = CFrame.new(hrp.Position + huida * 26 / 30)
		end
	end
	for _ = 1, 60 do
		Motor.avanzar(1 / 30)
	end
	local total, nombres = 0, {}
	for _, r in recibido do
		total += r.d
		nombres[r.ataque] = true
	end
	local l = {}
	for k in nombres do
		table.insert(l, k)
	end
	print(("  %-10s dist %4.1f %-9s golpes %d daño %5.1f  aviso:%s  altura max %.1f  [%s]"):format(nombre, dist, esquivar and "esquiva" or "quieto", #recibido, total, vio and "sí" or "NO", maxAlto, table.concat(l, ",")))
end

print("== " .. NOMBRE .. " ==")
local PRUEBAS = {
	Camazotz = {
		{ "zarpazo", 4.5 }, { "mordida", 5 }, { "grito", 14 }, { "grito", 20, 3 }, { "onda", 6 }, { "picada", 20 },
		{ "enjambre", 10, 0, function(b) b.fase2 = true end },
	},
}
PRUEBAS.Xolotl = {
	{ "mordida", 5.5 }, { "coletazo", -4 }, { "chorro", 12 }, { "chorro", 18, 1 }, { "sumergirse", 15 }, { "rayos", 10 },
}
PRUEBAS.Balam = {
	{ "zarpazo", 4.5 }, { "mordida", 5.6 }, { "salto", 15 }, { "zigzag", 12 }, { "rugido", 6 }, { "coletazo", -4.5 },
}
PRUEBAS.Cipactli = {
	{ "embestida", 9 }, { "giro", 5 }, { "coletazo", -8 }, { "emboscada", 16 }, { "geiseres", 12 },
	{ "fauces", 0, 3.8, function(b) b.fase2 = true end },
}
local pruebas = PRUEBAS[NOMBRE] or {}
for _, x in pruebas do
	probar(x[1], x[2], x[3], false, x[4])
	probar(x[1], x[2], x[3], true, x[4])
end
print("errores:", #Motor.errores)
for _, e in Motor.errores do
	print(e)
end
