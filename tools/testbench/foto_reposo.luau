--!nocheck
-- Exporta un Behemoth en su pose de reposo (sin animar), para cualquier módulo.
-- uso: lune run foto_reposo.luau <Modulo> <salida.json>
local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Motor = require("./motor")
local CFrame = Motor.CFrame
local NOMBRE, SALIDA = process.args[1], process.args[2]
local SRC = "src" -- se corre desde la raíz del repositorio
Motor.esServidor = true
local juego = Motor.crearJuego()
local RS = juego:GetService("ReplicatedStorage")
local SSS = juego:GetService("ServerScriptService")
local ws = Motor.workspace
Motor.carpeta(RS, "Compartido", SRC .. "/compartido")
local servidor = Motor.carpeta(SSS, "Servidor", SRC .. "/servidor")
local carpeta = Motor.Instance.new("Folder"); carpeta.Name = "Behemoths"; carpeta.Parent = ws
local servicios = { jugadores = function() return {} end, danio = function() end, anunciar = function() end, numero = function() end, recompensar = function() end, resultados = function() end }
local b = Motor.require(servidor[NOMBRE]).nuevo(servicios)
local modelo = b.modelo
local mundo = { [modelo.PrimaryPart] = CFrame.new(0, 0, 0) }
local juntas = {}
for _, d in modelo:GetDescendants() do
	if d.ClassName == "Motor6D" or d.ClassName == "Weld" then table.insert(juntas, d) end
end
local cambio = true
while cambio do
	cambio = false
	for _, jt in juntas do
		if mundo[jt.Part0] and not mundo[jt.Part1] then
			mundo[jt.Part1] = mundo[jt.Part0] * jt.C0 * jt.C1:Inverse(); cambio = true
		end
	end
end
local raizCF = modelo.PrimaryPart.CFrame
local cajas = {}
for _, p in modelo:GetDescendants() do
	if p:IsA("BasePart") and p.Transparency < 0.98 then
		local cf = mundo[p] or (raizCF:Inverse() * p.CFrame)
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
		local c = p.Color
		table.insert(cajas, { c = { x, y, z }, r = { r00, r01, r02, r10, r11, r12, r20, r21, r22 }, s = { p.Size.X, p.Size.Y, p.Size.Z },
			col = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }, neon = p.Material == roblox.Enum.Material.Neon, t = p.Transparency, forma = p.Shape and p.Shape.Name or "Block" })
	end
end
-- el suelo: la parte más baja
local minY = math.huge
for _, c in cajas do minY = math.min(minY, c.c[2] - c.s[2] / 2) end
local suelo = {}
for x = -10, 10 do for z = -12, 10 do table.insert(suelo, { c = { x * 4, minY - 2, z * 4 }, s = { 4, 4, 4 } }) end end
fs.writeFile(SALIDA, serde.encode("json", { { pose = NOMBRE, cajas = cajas, suelo = suelo } }))
print(NOMBRE, "piezas:", #cajas, "errores:", #Motor.errores)
for _, e in Motor.errores do print(e) end
