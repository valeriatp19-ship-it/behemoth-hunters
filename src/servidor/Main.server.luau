--!nonstrict
-- Punto de partida del servidor.
-- Según el lugar donde corre (ver Compartido > Servidores):
--   · "lobby": el Refugio de Qamar, el probador y los grupos de caza.
--   · "caceria": SOLO la isla del grupo que llega (una isla por Behemoth).
--   · "todo": todo junto en un solo servidor (en Studio): el Refugio y las cuatro islas.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Servidores = require(ReplicatedStorage.Compartido.Servidores)
local Config = require(ReplicatedStorage.Compartido.Config)
local Mundo = require(script.Parent.Mundo)
local Combate = require(script.Parent.Combate)
local Sekhmaur = require(script.Parent.Sekhmaur)
local Kheprak = require(script.Parent.Kheprak)
local Amaru = require(script.Parent.Amaru)
local ApuRumi = require(script.Parent.ApuRumi)
local MapaCumbres = require(script.Parent.MapaCumbres)
local MapaBrasa = require(script.Parent.MapaBrasa)
local MapaSelva = require(script.Parent.MapaSelva)
local Camazotz = require(script.Parent.Camazotz)
local Xolotl = require(script.Parent.Xolotl)
local Balam = require(script.Parent.Balam)
local Cipactli = require(script.Parent.Cipactli)
local Personaje = require(script.Parent.Personaje)
local Refugio = require(script.Parent.Refugio)
local Perfil = require(script.Parent.Perfil)
local Viajes = require(script.Parent.Viajes)
local Misiones = require(script.Parent.Misiones)
local Decoracion = require(script.Parent.Decoracion)
local Fauna = require(script.Parent.Fauna)

local modo = Servidores.modo()
print("Behemoth Hunters: servidor en modo " .. modo)

Perfil.iniciar()
Players.PlayerAdded:Connect(function(j)
	Perfil.cargar(j)
end)
for _, j in Players:GetPlayers() do
	task.spawn(Perfil.cargar, j)
end

local carpeta = Instance.new("Folder")
carpeta.Name = "Behemoths"
carpeta.Parent = workspace
local servicios = {
	jugadores = Combate.jugadores,
	danio = Combate.danio,
	anunciar = Combate.anunciar,
	numero = Combate.numero,
	recompensar = Combate.recompensar,
	resultados = Combate.resultados,
}
local bestias = {}
local campamentos = {} -- zona -> CFrame del campamento de esa isla

-- las caravanas de cada campamento llevan de vuelta al Refugio
local function conectarCaravana(carpetaIsla: Instance)
	for _, x in carpetaIsla:GetDescendants() do
		if x:IsA("ProximityPrompt") and x.Name == "VolverRefugio" then
			x.Triggered:Connect(function(jugador)
				if Config.ISLAS[jugador:GetAttribute("Zona")] then
					Viajes.alRefugio(jugador)
				end
			end)
		end
	end
end

-- ---------- cada isla con su Behemoth ----------
local CONSTRUIR = {
	desierto = function()
		local aparicion = Mundo.construir()
		Decoracion.dunas()
		Fauna.dunas()
		conectarCaravana(workspace:WaitForChild("MarDeDunas"))
		return aparicion.CFrame + Vector3.new(0, 4, 0), Sekhmaur.nuevo(servicios)
	end,
	brasa = function()
		local c = MapaBrasa.construir()
		Decoracion.brasa()
		Fauna.brasa()
		conectarCaravana(workspace:WaitForChild("DesiertoDeBrasa"))
		return c, Kheprak.nuevo(servicios)
	end,
	cuevas = function()
		local c = MapaCumbres.construir(Config.CUEVAS, "cuevas")
		Decoracion.cuevas()
		Fauna.cuevas()
		conectarCaravana(workspace:WaitForChild("CuevasDelUkuPacha"))
		return c, Amaru.nuevo(servicios)
	end,
	cumbres = function()
		local c = MapaCumbres.construir(Config.CUMBRES, "cumbres")
		Decoracion.cumbres()
		Fauna.cumbres()
		conectarCaravana(workspace:WaitForChild("CumbresDelInti"))
		return c, ApuRumi.nuevo(servicios)
	end,
}
-- las islas de la Selva de Obsidiana
local BESTIAS_SELVA = { xibalba = Camazotz, cenote = Xolotl, selva = Balam, pantano = Cipactli }
for zona, Modulo in BESTIAS_SELVA do
	CONSTRUIR[zona] = function()
		local c = MapaSelva.construir(zona)
		Fauna.selva(zona)
		conectarCaravana(workspace:WaitForChild(MapaSelva.NOMBRES[zona]))
		return c, Modulo.nuevo(servicios)
	end
end
local enConstruccion = {}
local function construirIsla(zona: string)
	if enConstruccion[zona] or not CONSTRUIR[zona] then
		return
	end
	enConstruccion[zona] = true
	local campamento, bestia = CONSTRUIR[zona]()
	table.insert(bestias, bestia)
	Combate.agregarObjetivo(bestia)
	campamentos[zona] = campamento
	print("Isla lista: " .. zona)
end

if modo == "todo" then
	for _, zona in { "desierto", "brasa", "cuevas", "cumbres", "xibalba", "cenote", "selva", "pantano" } do
		construirIsla(zona)
	end
elseif modo == "caceria" then
	-- se construye la isla que eligió el grupo, apenas llega el primer cazador
	local function alLlegar(j: Player)
		local datos = j:GetJoinData()
		local td = datos and datos.TeleportData
		local zona = (type(td) == "table" and Config.ISLAS[td.zona]) and td.zona or "desierto"
		task.spawn(construirIsla, zona)
	end
	Players.PlayerAdded:Connect(alLlegar)
	for _, j in Players:GetPlayers() do
		alLlegar(j)
	end
end

-- un desmayo cuenta para el Behemoth que ese cazador estaba cazando
Combate.iniciar(function(jugador)
	for _, b in bestias do
		b:desmayo(jugador)
	end
end)
Misiones.iniciar()

-- ---------- el Refugio, el probador y los viajes ----------
Viajes.iniciar(function(jugador, destino)
	Personaje.llevar(jugador, destino)
end)
local hayRefugio = modo ~= "caceria"
if hayRefugio then
	Refugio.iniciar()
	Decoracion.refugio(Refugio.CENTRO)
	Fauna.refugio(Refugio.CENTRO)
end
Personaje.iniciar(campamentos, hayRefugio and Refugio.aparicion or nil, Combate.equipar)

-- el espejo del Refugio lleva al probador para cambiar la apariencia
for _, x in workspace:GetDescendants() do
	if x:IsA("ProximityPrompt") and x.Name == "CambiarApariencia" then
		x.Triggered:Connect(function(jugador)
			Personaje.abrirProbador(jugador)
		end)
	end
end

RunService.Heartbeat:Connect(function(dt)
	for _, b in bestias do
		b:paso(math.min(dt, 0.1))
	end
end)
