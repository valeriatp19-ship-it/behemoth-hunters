--!nocheck
-- Imprime dónde queda cada pieza (en metros, relativo a la raíz) en la pose de reposo, para
-- poner las zonas de golpe donde de verdad está el cuerpo. uso: lune run zonas.luau <Modulo> pieza1 pieza2 ...
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Motor = require("./motor")
local CFrame = roblox.CFrame
local SRC = "src" -- se corre desde la raíz del repositorio
Motor.esServidor = true
local juego = Motor.crearJuego()
local RS = juego:GetService("ReplicatedStorage")
local SSS = juego:GetService("ServerScriptService")
Motor.carpeta(RS, "Compartido", SRC .. "/compartido")
local servidor = Motor.carpeta(SSS, "Servidor", SRC .. "/servidor")
local Config = Motor.require(RS.Compartido.Config)
local S = Config.S
local servicios = { jugadores = function() return {} end, danio = function() end, anunciar = function() end, numero = function() end, recompensar = function() end, resultados = function() end }
local b = Motor.require(servidor[process.args[1]]).nuevo(servicios)
local AnimSelva = Motor.cargarComo(Motor.Instance.new("ModuleScript"), SRC .. "/cliente/AnimSelva.luau")
b.modelo:SetAttribute("Anim", "reposo")
b.modelo:SetAttribute("AnimT0", Motor.workspace:GetServerTimeNow())
AnimSelva.animar(b.modelo, Motor.workspace:GetServerTimeNow(), 0)
local mundo = { [b.raiz] = CFrame.new() }
local juntas = {}
for _, d in b.modelo:GetDescendants() do
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
local pedidas = {}
for i = 2, #process.args do
	pedidas[process.args[i]] = true
end
local maxY, minX, maxX, minZ, maxZ = 0, 0, 0, 0, 0
for p, cf in mundo do
	local q = cf.Position / S
	if p.Transparency < 0.98 then
		maxY = math.max(maxY, q.Y)
		minX, maxX = math.min(minX, q.X), math.max(maxX, q.X)
		minZ, maxZ = math.min(minZ, q.Z), math.max(maxZ, q.Z)
	end
	local padre = ""
	for _, jt in juntas do
		if jt.Part1 == p then
			padre = jt.Part0.Name
		end
	end
	if pedidas[p.Name] or pedidas[p.Name .. "<" .. padre] then
		print(("%-14s <%-12s  (%6.2f, %6.2f, %6.2f)  tam %s"):format(p.Name, padre, q.X, q.Y, q.Z, tostring(p.Size / S)))
	end
end
print(("alto máx %.1f m · ancho %.1f..%.1f · largo %.1f..%.1f"):format(maxY, minX, maxX, minZ, maxZ))
