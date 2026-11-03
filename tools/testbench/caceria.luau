--!nocheck
-- Simula una cacería completa contra un Behemoth de la selva con cazadores automáticos.
-- uso: lune run caceria.luau <Modulo> <jugadores> <segundos> <semilla> [habilidad]
local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Motor = require("./motor")
local Vector3, CFrame = roblox.Vector3, Motor.CFrame

local args = process.args
local NOMBRE = args[1] or "Camazotz"
local NJ = tonumber(args[2]) or 2
local DURACION = tonumber(args[3]) or 900
local SEMILLA = tonumber(args[4]) or 1
local HABIL = tonumber(args[5]) or 0.6 -- probabilidad de esquivar a tiempo
math.randomseed(SEMILLA)

local SRC = "src" -- se corre desde la raíz del repositorio
Motor.esServidor = true
local juego = Motor.crearJuego()
local RS = juego:GetService("ReplicatedStorage")
local SSS = juego:GetService("ServerScriptService")
local ws = Motor.workspace
Motor.carpeta(RS, "Compartido", SRC .. "/compartido")
local servidor = Motor.carpeta(SSS, "Servidor", SRC .. "/servidor")
local behemoths = Motor.Instance.new("Folder")
behemoths.Name = "Behemoths"
behemoths.Parent = ws

local Config = Motor.require(RS.Compartido.Config)
local Armas = Motor.require(RS.Compartido.Armas)
local S = Config.S

-- ---------- cazadores ----------
local Players = juego:GetService("Players")
local TIPOS = { "espada", "martillo", "guadanas", "lanza", "pistolas", "punos" }
local cazadores = {}
local stats = { danioRecibido = {}, golpesRecibidos = {}, desmayos = 0, pociones = 0, ataques = {}, golpesDados = 0, danioDado = 0, anuncios = {}, partesRotas = {}, derribos = 0, fuera = 0, alturaMin = math.huge, alturaMax = -math.huge }
local behemoth

local function suelo(x, z)
	return Config.alturaEn(x, z)
end

for i = 1, NJ do
	local j = Motor.Instance.new("Player")
	j.Name = "Cazador" .. i
	j.UserId = i
	j:SetAttribute("Zona", nil)
	j.Parent = Players
	local char = Motor.Instance.new("Model")
	char.Name = j.Name
	local hrp = Motor.Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Parent = char
	local hum = Motor.Instance.new("Humanoid")
	hum.MaxHealth = 150
	hum.Health = 150
	hum.Parent = char
	char.PrimaryPart = hrp
	char.Parent = ws
	j.Character = char
	local tipo = TIPOS[((i + SEMILLA) % #TIPOS) + 1]
	cazadores[i] = { jugador = j, char = char, hrp = hrp, hum = hum, tipo = tipo, arma = Armas.DATOS[tipo], pociones = 6, muerto = 0, combo = 0, ocupado = 0, esquivando = 0, vioAviso = 0 }
end

local isla
local function enCampamento(p)
	return Config.enCampamento(p)
end

-- ---------- servicios para el Behemoth ----------
local servicios = {}
function servicios.jugadores(zona)
	local l = {}
	for _, c in cazadores do
		if c.hum.Health > 0 then
			table.insert(l, { jugador = c.jugador, hrp = c.hrp, atacable = not enCampamento(c.hrp.Position) })
		end
	end
	return l
end
function servicios.danio(jugador, danio, origen, empuje, ataque, continuo)
	for _, c in cazadores do
		if c.jugador == jugador and c.hum.Health > 0 then
			if not continuo and c.invul and c.invul > Motor.reloj.t then
				stats.esquivasPerfectas = (stats.esquivasPerfectas or 0) + 1
				return
			end
			danio *= 1.15
			c.hum:TakeDamage(danio)
			stats.danioRecibido[ataque] = (stats.danioRecibido[ataque] or 0) + danio
			stats.golpesRecibidos[ataque] = (stats.golpesRecibidos[ataque] or 0) + 1
			-- empuje
			local lejos = Vector3.new(c.hrp.Position.X - origen.X, 0, c.hrp.Position.Z - origen.Z)
			if lejos.Magnitude > 0.01 then
				c.hrp.Position += lejos.Unit * empuje * 0.6
			end
			if c.hum.Health <= 0 then
				stats.desmayos += 1
				c.muerto = 10
				behemoth:desmayo(c.jugador)
			end
			return true
		end
	end
end
function servicios.anunciar(texto, color)
	table.insert(stats.anuncios, string.format("%6.1f %s", Motor.reloj.t - 1000, texto))
end
function servicios.numero() end
function servicios.recompensar(premios, participantes)
	stats.premios = premios
end
function servicios.resultados(participantes, datos)
	stats.resultados = datos
end

local Modulo = Motor.require(servidor[NOMBRE])
behemoth = Modulo.nuevo(servicios)
isla = behemoth.isla or Config.ISLAS[behemoth.modelo:GetAttribute("Mapa")]
local def = Modulo.def or { zona = behemoth.modelo:GetAttribute("Mapa"), prefijo = ({ ApuRumi = "apu_", Amaru = "amaru_", Kheprak = "", Sekhmaur = "" })[NOMBRE] or "" }
behemoth.avisosExtra = behemoth.avisosExtra or {}

-- los cazadores empiezan en el campamento
for i, c in cazadores do
	local p = Config.sueloIsla(def.zona, (i - 1) * 3, 80)
	c.hrp.CFrame = CFrame.new(p + Vector3.new(0, 3, 0))
	c.jugador:SetAttribute("Zona", def.zona)
end

-- ---------- golpes de los cazadores (copiado de Combate) ----------
local function distanciaAZona(centro, z)
	local d = z.pos - centro
	return math.sqrt(d.X * d.X + d.Z * d.Z + (d.Y * 0.35) ^ 2) - z.r
end
local function prioridad(o, zona)
	local p = 0
	if zona.parte and zona.parte ~= "" then
		local d = o.partes and o.partes[zona.parte]
		if not d or not d.rota then
			p += 1.5 * S
		end
	end
	if zona.tipo == "pata" or zona.tipo == "cabeza" or zona.tipo == "cola" then
		p += 0.6 * S
	end
	return p
end
local function golpear(c, ataque, fuerte)
	local arma = c.arma
	local alcance = ataque.alcance * S
	local centro = c.hrp.Position + c.hrp.CFrame.LookVector * alcance * 0.55
	local radio = alcance * 0.62
	local encontrados = {}
	for _, z in behemoth:zonas() do
		local d = distanciaAZona(centro, z)
		if d < radio then
			table.insert(encontrados, { z = z, d = d - prioridad(behemoth, z.zona) })
		end
	end
	table.sort(encontrados, function(a, b)
		return a.d < b.d
	end)
	local maximo = ataque.golpes and 3 or 1
	local n = 0
	for _, f in encontrados do
		if n >= maximo then
			break
		end
		n += 1
		local info = { danio = arma.danio * ataque.danio, partes = arma.partes, aturdir = arma.aturdir, fuerte = fuerte, herida = ataque.herida_profunda == true, duracionHerida = 12, multCabeza = 1 }
		local v0 = behemoth.vida
		behemoth:recibirGolpe(f.z.zona, info, c.jugador)
		stats.golpesDados += 1
		stats.danioDado += v0 - behemoth.vida
	end
	return n > 0
end
local function disparar(c, ataque, fuerte, zona)
	local arma = c.arma
	local info = { danio = arma.danio * ataque.danio, partes = arma.partes, aturdir = arma.aturdir, fuerte = fuerte, herida = false, duracionHerida = 12, multCabeza = 1 }
	local v0 = behemoth.vida
	behemoth:recibirGolpe(zona.zona, info, c.jugador)
	stats.golpesDados += 1
	stats.danioDado += v0 - behemoth.vida
end

-- ¿el cazador está dentro de un aviso rojo visible?
local function enPeligro(p)
	local avisos = { behemoth.avisoCirculo, behemoth.avisoRect, table.unpack(behemoth.avisosExtra) }
	for _, a in avisos do
		if a and a.Transparency < 1 then
			local rel = a.CFrame:PointToObjectSpace(p)
			if a.Shape == roblox.Enum.PartType.Cylinder then
				-- cilindro tumbado: el eje X apunta arriba
				local r = a.Size.Y / 2
				if Vector2_mag(rel.Y, rel.Z) < r + 1 then
					return a
				end
			else
				if math.abs(rel.X) < a.Size.X / 2 + 1 and math.abs(rel.Z) < a.Size.Z / 2 + 1 then
					return a
				end
			end
		end
	end
	return nil
end
function Vector2_mag(a, b)
	return math.sqrt(a * a + b * b)
end

local function moverHacia(c, meta, vel, dt)
	local p = c.hrp.Position
	local d = Vector3.new(meta.X - p.X, 0, meta.Z - p.Z)
	if d.Magnitude < 0.5 then
		return true
	end
	local paso = math.min(d.Magnitude, vel * dt)
	local n = p + d.Unit * paso
	c.hrp.CFrame = CFrame.lookAt(Vector3.new(n.X, suelo(n.X, n.Z) + 3, n.Z), Vector3.new(meta.X, suelo(n.X, n.Z) + 3, meta.Z))
	return false
end

local function mirar(c, hacia)
	local p = c.hrp.Position
	local h = Vector3.new(hacia.X, p.Y, hacia.Z)
	if (h - p).Magnitude > 0.1 then
		c.hrp.CFrame = CFrame.lookAt(p, h)
	end
end

local function elegirZona(c)
	local zs = behemoth:zonas()
	if #zs == 0 then
		return nil
	end
	-- prefiere partes sin romper y zonas a su alcance (las altas, si es lanza o blásteres)
	local mejor, mejorP = nil, -math.huge
	for _, z in zs do
		local p = math.random() * 2
		if z.zona.parte ~= "" and behemoth.partes[z.zona.parte] and not behemoth.partes[z.zona.parte].rota then
			p += 2
		end
		if z.zona.tipo == "cabeza" then
			p += 0.8
		end
		if p > mejorP then
			mejor, mejorP = z, p
		end
	end
	return mejor.zona.nombre
end

local function zonaPorNombre(n)
	for _, z in behemoth:zonas() do
		if z.zona.nombre == n then
			return z
		end
	end
	return nil
end

local function pasoCazador(c, dt)
	local t = Motor.reloj.t
	if c.muerto > 0 then
		c.muerto -= dt
		if c.muerto <= 0 then
			c.hum.Health = c.hum.MaxHealth
			c.pociones = math.max(c.pociones, 3)
			local p = Config.sueloIsla(def.zona, 0, 85)
			c.hrp.CFrame = CFrame.new(p + Vector3.new(0, 3, 0))
		end
		return
	end
	if c.hum.Health <= 0 then
		return
	end
	-- poción
	if c.hum.Health < 60 and c.pociones > 0 and t > c.ocupado then
		c.pociones -= 1
		stats.pociones += 1
		c.ocupado = t + 1.2
		c.hum.Health = math.min(c.hum.MaxHealth, c.hum.Health + 50)
	end
	if t < c.ocupado then
		return
	end
	-- esquivar avisos
	local a = enPeligro(c.hrp.Position)
	if a then
		c.vioAviso += dt
		if c.decideEsquivar == nil then
			c.decideEsquivar = math.random() < HABIL
		end
		if c.decideEsquivar and c.vioAviso > 0.3 then
			-- corre hacia fuera del aviso
			local centro = a.Position
			local fuera = Vector3.new(c.hrp.Position.X - centro.X, 0, c.hrp.Position.Z - centro.Z)
			if fuera.Magnitude < 0.1 then
				fuera = Vector3.new(1, 0, 0)
			end
			if a.Shape ~= roblox.Enum.PartType.Cylinder then
				fuera = a.CFrame.RightVector * (a.CFrame:PointToObjectSpace(c.hrp.Position).X >= 0 and 1 or -1)
			end
			moverHacia(c, c.hrp.Position + fuera.Unit * 10, 26, dt)
			return
		end
	else
		c.vioAviso = 0
		c.decideEsquivar = nil
	end
	-- ir a la zona elegida y atacar
	if not c.zona or t > (c.cambiaZona or 0) or not zonaPorNombre(c.zona) then
		c.zona = elegirZona(c)
		c.cambiaZona = t + 4 + math.random() * 4
	end
	local z = c.zona and zonaPorNombre(c.zona)
	if not z then
		-- el Behemoth está enterrado o muerto: se acerca y espera
		moverHacia(c, behemoth.pos, 16, dt)
		return
	end
	local arma = c.arma
	if arma.distancia then
		local d = (Vector3.new(z.pos.X, 0, z.pos.Z) - Vector3.new(c.hrp.Position.X, 0, c.hrp.Position.Z)).Magnitude / S
		if d > 22 then
			moverHacia(c, z.pos, 16, dt)
			return
		elseif d < 9 then
			moverHacia(c, c.hrp.Position + (c.hrp.Position - z.pos) * Vector3.new(1, 0, 1), 16, dt)
			return
		end
		mirar(c, z.pos)
		c.combo = (c.combo % #arma.combo) + 1
		local ataque = math.random() < 0.15 and arma.fuerte or arma.combo[c.combo]
		c.ocupado = t + ataque.duracion * 0.85
		disparar(c, ataque, ataque == arma.fuerte, z)
		return
	end
	local alcance = arma.combo[1].alcance
	local p = c.hrp.Position
	local rel = Vector3.new(p.X - z.pos.X, 0, p.Z - z.pos.Z)
	local dist = rel.Magnitude / S - z.r / S
	if dist > alcance * 0.7 then
		local meta = z.pos + (rel.Magnitude > 0.1 and rel.Unit or Vector3.new(1, 0, 0)) * (z.r + alcance * 0.4 * S)
		moverHacia(c, meta, dist > 12 and 26 or 16, dt)
		return
	end
	mirar(c, z.pos)
	c.combo = (c.combo % #arma.combo) + 1
	local fuerte = math.random() < 0.2
	local ataque = fuerte and arma.fuerte or arma.combo[c.combo]
	c.ocupado = t + ataque.duracion * 0.85
	local golpes = ataque.golpes or 1
	for i = 0, golpes - 1 do
		Motor.task.delay(ataque.golpe + i * 0.13, function()
			if c.hum.Health > 0 and not golpear(c, ataque, fuerte) then
				stats.fallos = (stats.fallos or 0) + 1
			end
		end)
	end
end

-- ---------- bucle ----------
local dt = 1 / 30
local pasos = math.floor(DURACION / dt)
local ultimoAtaque = nil
local tiempoFin = nil
local fueraIsla = 0
for n = 1, pasos do
	Motor.avanzar(dt)
	for _, c in cazadores do
		local ok, err = pcall(pasoCazador, c, dt)
		if not ok then
			print("error cazador", err)
			break
		end
	end
	local ok, err = pcall(behemoth.paso, behemoth, dt)
	if not ok then
		print("ERROR en paso del Behemoth:", err)
		table.insert(Motor.errores, err)
		break
	end
	if behemoth.estado == "ataque" and behemoth.ataque ~= ultimoAtaque then
		stats.ataques[behemoth.ataque] = (stats.ataques[behemoth.ataque] or 0) + 1
	end
	ultimoAtaque = behemoth.estado == "ataque" and behemoth.ataque or nil
	-- revisa que siga dentro de su isla y sobre el suelo
	local c = isla.centro
	local d = Vector2_mag(behemoth.pos.X - c.X, behemoth.pos.Z - c.Z) / S
	if d > (def.radioIsla or 100) + 1 then
		fueraIsla += 1
	end
	stats.alturaMin = math.min(stats.alturaMin, behemoth.raiz.Position.Y - suelo(behemoth.pos.X, behemoth.pos.Z))
	stats.alturaMax = math.max(stats.alturaMax, behemoth.raiz.Position.Y - suelo(behemoth.pos.X, behemoth.pos.Z))
	if behemoth.muerto and not tiempoFin then
		tiempoFin = Motor.reloj.t - 1000
	end
	if behemoth.caceria.terminada and n * dt > (tiempoFin or 0) + 2 and tiempoFin then
		break
	end
	if behemoth.caceria.terminada and not tiempoFin then
		tiempoFin = Motor.reloj.t - 1000
		print("Cacería fallida en", tiempoFin)
		break
	end
end

print(("== %s · %d cazadores (%s) · habilidad %.0f%% =="):format(NOMBRE, NJ, table.concat((function()
	local l = {}
	for _, c in cazadores do
		table.insert(l, c.tipo)
	end
	return l
end)(), ", "), HABIL * 100))
print("vida restante:", math.floor(behemoth.vida), "/", math.floor(behemoth.vidaMax), "estado:", behemoth.estado, "fin:", tiempoFin)
print("ataques usados:")
for k, v in stats.ataques do
	print(("  %-12s x%-3d golpes que dieron: %-3d daño total: %d"):format(k, v, stats.golpesRecibidos[def.prefijo .. k] or 0, math.floor(stats.danioRecibido[def.prefijo .. k] or 0)))
end
print("golpes de cazadores:", stats.golpesDados, "fallos:", stats.fallos or 0, "daño:", math.floor(stats.danioDado))
print("desmayos:", stats.desmayos, "pociones:", stats.pociones, "esquivas perfectas:", stats.esquivasPerfectas or 0)
print("fuera de la isla (pasos):", fueraIsla, ("altura sobre el suelo: %.1f .. %.1f studs"):format(stats.alturaMin, stats.alturaMax))
print("anuncios:")
for _, a in stats.anuncios do
	print("  " .. a)
end
if stats.resultados then
	print("resultado:", stats.resultados.exito, "tiempo", math.floor(stats.resultados.tiempo), "derribos", stats.resultados.derribos, "partes", table.concat(stats.resultados.partes, ", "))
end
if stats.premios then
	local l = {}
	for k, v in stats.premios do
		table.insert(l, k .. "=" .. v)
	end
	print("premios:", table.concat(l, " "))
end
print("errores:", #Motor.errores)
for _, e in Motor.errores do
	print(e)
end
