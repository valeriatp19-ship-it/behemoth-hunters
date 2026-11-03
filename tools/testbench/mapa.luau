--!nocheck
-- Construye una isla de la selva con el motor falso y exporta sus bloques para verla.
-- uso: lune run mapa.luau <zona> <salida.json> [conBehemoth]
local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Motor = require("./motor")
local CFrame = roblox.CFrame
local ZONA = process.args[1]
local SRC = "src" -- se corre desde la raíz del repositorio
Motor.esServidor = true
local juego = Motor.crearJuego()
local RS = juego:GetService("ReplicatedStorage")
local SSS = juego:GetService("ServerScriptService")
Motor.carpeta(RS, "Compartido", SRC .. "/compartido")
local servidor = Motor.carpeta(SSS, "Servidor", SRC .. "/servidor")
local Config = Motor.require(RS.Compartido.Config)
local MapaSelva = Motor.require(servidor.MapaSelva)
local Fauna = Motor.require(servidor.Fauna)
local t0 = os.clock()
local camp = MapaSelva.construir(ZONA)
Fauna.selva(ZONA)
print("construida en", os.clock() - t0, "s")
local carpeta = Motor.workspace:FindFirstChild(MapaSelva.NOMBRES[ZONA])
local O = Config.ISLAS[ZONA].centro
local cajas = {}
local n, suelo = 0, 0
local luces = 0
for _, p in carpeta:GetDescendants() do
	if p:IsA("BasePart") then
		n += 1
		if p.Name == "Suelo" then
			suelo += 1
		end
		if p.Transparency < 0.98 then
			local cf = p.CFrame
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
			local c = p.Color
			table.insert(cajas, { c = { x - O.X, y - O.Y, z - O.Z }, r = { r00, r01, r02, r10, r11, r12, r20, r21, r22 }, s = { p.Size.X, p.Size.Y, p.Size.Z },
				col = { math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255) }, neon = p.Material == roblox.Enum.Material.Neon, t = p.Transparency, forma = p.Shape and p.Shape.Name or "Block" })
		end
	elseif p.ClassName == "PointLight" then
		luces += 1
	end
end
print("piezas:", n, "suelo:", suelo, "luces:", luces, "campamento:", camp.Position - O)
fs.writeFile(process.args[2], serde.encode("json", { { pose = ZONA, cajas = cajas } }))
print("errores:", #Motor.errores)
