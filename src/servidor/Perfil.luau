--!nonstrict
-- Progreso de cada cazador: monedas, materiales, armas forjadas y armadura.
-- Se guarda en la nube (DataStore) cuando el juego está publicado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Armas = require(ReplicatedStorage.Compartido.Armas)
local Remotos = require(ReplicatedStorage.Compartido.Remotos)

local Perfil = {}
local perfiles = {}
local pendientes = {}
local cargados = {}
local almacen
pcall(function()
	almacen = DataStoreService:GetDataStore("PerfilCazadoras")
end)

local function nuevo()
	local m = {}
	for _, k in Armas.ORDEN_MATERIALES do
		m[k] = 0
	end
	return { monedas = 100, materiales = m, arma = "espada", forjadas = {}, armadura = {}, equipo = {}, cazas = 0,
		nivel = 1, xp = 0, tiempos = {}, cazasPor = {}, misiones = { historia = 1, encargos = {} } }
end

local function completar(p)
	local base = nuevo()
	if type(p) ~= "table" then
		return base
	end
	for k, v in base do
		if p[k] == nil then
			p[k] = v
		end
	end
	for _, k in Armas.ORDEN_MATERIALES do
		p.materiales[k] = tonumber(p.materiales[k]) or 0
	end
	if not Armas.DATOS[p.arma] then
		p.arma = "espada"
	end
	return p
end

function Perfil.de(jugador: Player)
	local p = perfiles[jugador]
	if not p then
		p = nuevo()
		perfiles[jugador] = p
	end
	return p
end

function Perfil.cargar(jugador: Player)
	local p
	if almacen then
		local ok, dato = pcall(function()
			return almacen:GetAsync("perfil_" .. jugador.UserId)
		end)
		if ok then
			p = dato
		end
	end
	perfiles[jugador] = completar(p)
	cargados[jugador] = true
	Perfil.enviar(jugador)
end

-- Espera a que el perfil termine de cargarse de la nube (máximo 8 segundos).
function Perfil.esperar(jugador: Player)
	local limite = os.clock() + 8
	while not cargados[jugador] and jugador.Parent and os.clock() < limite do
		task.wait(0.1)
	end
end

function Perfil.enviar(jugador: Player)
	Remotos.Perfil:FireClient(jugador, Perfil.de(jugador))
end

-- Guarda pronto, pero sin pedirle a Roblox más de una vez cada pocos segundos.
function Perfil.guardar(jugador: Player)
	Perfil.enviar(jugador)
	if not almacen or pendientes[jugador] then
		return
	end
	pendientes[jugador] = true
	task.delay(6, function()
		pendientes[jugador] = nil
		local p = perfiles[jugador]
		if p then
			pcall(function()
				almacen:SetAsync("perfil_" .. jugador.UserId, p)
			end)
		end
	end)
end

-- Guarda ahora mismo y espera a que termine (antes de viajar a otro servidor).
function Perfil.guardarYa(jugador: Player)
	local p = perfiles[jugador]
	if almacen and p then
		pcall(function()
			almacen:SetAsync("perfil_" .. jugador.UserId, p)
		end)
	end
end

function Perfil.puedePagar(jugador: Player, receta): boolean
	local p = Perfil.de(jugador)
	for k, v in receta do
		local tiene = k == "monedas" and p.monedas or p.materiales[k] or 0
		if tiene < v then
			return false
		end
	end
	return true
end

function Perfil.pagar(jugador: Player, receta)
	local p = Perfil.de(jugador)
	for k, v in receta do
		if k == "monedas" then
			p.monedas -= v
		else
			p.materiales[k] -= v
		end
	end
end

function Perfil.dar(jugador: Player, premios)
	local p = Perfil.de(jugador)
	for k, v in premios do
		if k == "monedas" then
			p.monedas += v
		elseif p.materiales[k] then
			p.materiales[k] += v
		end
	end
	Perfil.guardar(jugador)
end

-- Experiencia: al llenar la barra se sube de nivel (cada nivel da +2 de vida máxima).
function Perfil.darXP(jugador: Player, xp: number): number
	local p = Perfil.de(jugador)
	local subio = 0
	p.xp += xp
	while p.nivel < Armas.NIVEL_MAX and p.xp >= Armas.xpParaSubir(p.nivel) do
		p.xp -= Armas.xpParaSubir(p.nivel)
		p.nivel += 1
		subio += 1
	end
	if p.nivel >= Armas.NIVEL_MAX then
		p.xp = 0
	end
	Perfil.guardar(jugador)
	return subio
end

-- Guarda el mejor tiempo del cazador contra ese Behemoth; dice si fue récord personal.
function Perfil.registrarTiempo(jugador: Player, behemoth: string, tiempo: number): boolean
	local p = Perfil.de(jugador)
	p.cazasPor[behemoth] = (p.cazasPor[behemoth] or 0) + 1
	local antes = p.tiempos[behemoth]
	if not antes or tiempo < antes then
		p.tiempos[behemoth] = math.floor(tiempo)
		return true
	end
	return false
end

function Perfil.iniciar()
	Players.PlayerRemoving:Connect(function(j)
		local p = perfiles[j]
		if almacen and p then
			pcall(function()
				almacen:SetAsync("perfil_" .. j.UserId, p)
			end)
		end
		perfiles[j] = nil
		cargados[j] = nil
	end)
end

return Perfil
