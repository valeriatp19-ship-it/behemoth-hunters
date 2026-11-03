--!nocheck
-- Arma un Behemoth, lo pone en una pose (con el animador del cliente) y exporta sus bloques
-- en coordenadas del mundo para dibujarlos con Python.
-- uso: lune run foto.luau <Modulo> <salida.json> <pose1>:<t1>[:extra] <pose2>:<t2> ...
--   extra: f2 (fase 2), rotas (todas las partes rotas), ataque=<nombre>:<seg> (simula ese ataque)
local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Motor = require("./motor")
local Vector3, CFrame = roblox.Vector3, Motor.CFrame

local args = process.args
local NOMBRE = args[1]
local SALIDA = args[2]
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

-- cazador de referencia (para ver el tamaño), a un lado
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
local servicios = {
	jugadores = function()
		return { { jugador = j, hrp = hrp, atacable = true } }
	end,
	danio = function() end,
	anunciar = function() end,
	numero = function() end,
	recompensar = function() end,
	resultados = function() end,
}
local Modulo = Motor.require(servidor[NOMBRE])
local b = Modulo.nuevo(servicios)

-- el animador del cliente (mismo código que en el juego)
local scriptAnim = Motor.Instance.new("ModuleScript")
scriptAnim.Name = "AnimSelva"
local AnimSelva = Motor.cargarComo(scriptAnim, SRC .. "/cliente/AnimSelva.luau")

local function resolver(modelo, raizCF)
	-- cinemática directa: Part1 = Part0 * C0 * Transform * C1^-1
	local mundo = {}
	mundo[modelo.PrimaryPart] = raizCF
	local juntas = {}
	for _, d in modelo:GetDescendants() do
		if d.ClassName == "Motor6D" or d.ClassName == "Weld" then
			table.insert(juntas, d)
		end
	end
	local cambio = true
	while cambio do
		cambio = false
		for _, jt in juntas do
			if mundo[jt.Part0] and not mundo[jt.Part1] then
				mundo[jt.Part1] = mundo[jt.Part0] * jt.C0 * jt.C1:Inverse()
				cambio = true
			end
		end
	end
	return mundo
end

local function caja(p, cf, dx)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local c = p.Color
	local forma = p.Shape and p.Shape.Name or "Block"
	return {
		c = { x + dx, y, z }, r = { r00, r01, r02, r10, r11, r12, r20, r21, r22 },
		s = { p.Size.X, p.Size.Y, p.Size.Z }, col = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) },
		neon = p.Material == roblox.Enum.Material.Neon, t = p.Transparency, forma = forma, n = p.Name,
	}
end

local escenas = {}
local separacion = 0
for i = 3, #args do
	local partes = string.split(args[i], ":")
	local pose, t = partes[1], tonumber(partes[2]) or 0.5
	b:reiniciar()
	b.pos = b:sueloM(table.unpack(({ cenote = { 0, 52 }, pantano = { 10, -30 } })[b.def.zona] or { 0, -30 }))
	b.yaw = 0
	b.yVisual = b.pos.Y
	for k = 3, #partes do
		local e = partes[k]
		if e == "f2" then
			b:_entrarFase2()
		elseif e == "rotas" then
			for id in b.partes do
				b:_romper(id)
			end
		end
	end
	b.estado = "perseguir"
	b.alerta = true
	-- el cazador, 7 m delante del Behemoth
	local delante = b.pos + b:_adelante() * 7 * S
	hrp.CFrame = CFrame.new(delante.X, b:altura(delante.X, delante.Z) + 3, delante.Z)
	b.objetivo = { jugador = j, hrp = hrp, atacable = true }
	-- si la pose es un ataque, se simula en el servidor hasta ese momento
	if b.def.ataques[pose] then
		b:_iniciarAtaque(pose)
		local tt = 0
		while tt < t - 1e-6 and b.estado == "ataque" do
			Motor.avanzar(1 / 60)
			b.tObjetivo = 99
			b:paso(1 / 60)
			tt += 1 / 60
		end
	else
		b:paso(1 / 60)
		b.modelo:SetAttribute("Anim", pose)
		b.modelo:SetAttribute("AnimT0", ws:GetServerTimeNow())
		b.modelo:SetAttribute("Ritmo", 1)
		Motor.avanzar(t)
		b.raiz.CFrame = CFrame.new(b.pos.X, b.pos.Y + (b.altoExtra or 0), b.pos.Z) * CFrame.Angles(0, b.yaw, 0)
	end
	local ahora = ws:GetServerTimeNow()
	AnimSelva.animar(b.modelo, ahora, ahora)
	local mundo = resolver(b.modelo, b.raiz.CFrame)
	local base = b.raiz.Position
	local cajas = {}
	local dx = 0
	for _, p in b.modelo:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.98 and mundo[p] then
			local cf = mundo[p]
			table.insert(cajas, caja(p, CFrame.new(cf.Position - base) * cf.Rotation, dx))
		end
	end
	-- avisos y murciélagos (sueltos en workspace)
	for _, p in ws:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.98 and p.Anchored and not p:IsDescendantOf(b.modelo) and p ~= hrp then
			local cf = p.CFrame
			table.insert(cajas, caja(p, CFrame.new(cf.Position - base) * cf.Rotation, dx))
		end
	end
	-- suelo alrededor
	local sueloCajas = {}
	for x = -10, 10 do
		for z = -14, 8 do
			local wx, wz = base.X + x * 4, base.Z + z * 4
			local h = b:altura(wx, wz)
			table.insert(sueloCajas, { c = { x * 4, h - 2 - base.Y, z * 4 }, s = { 4, 4, 4 } })
		end
	end
	table.insert(escenas, { pose = args[i], cajas = cajas, suelo = sueloCajas, cazador = { delante.X - base.X, b:altura(delante.X, delante.Z) - base.Y, delante.Z - base.Z } })
	Motor.reloj.t += 30
end
fs.writeFile(SALIDA, serde.encode("json", escenas))
print("escenas:", #escenas, "errores:", #Motor.errores)
for _, e in Motor.errores do
	print(e)
end
