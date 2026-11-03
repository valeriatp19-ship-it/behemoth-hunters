--!nonstrict
-- Grupos de caza (hasta 4 cazadores) y los viajes entre el Refugio y las cacerías.
-- Con dos lugares configurados, cada grupo viaja a su propio servidor privado de cacería.
-- En Studio (modo "todo"), el grupo simplemente viaja dentro del mismo servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Servidores = require(ReplicatedStorage.Compartido.Servidores)
local Armas = require(ReplicatedStorage.Compartido.Armas)
local Perfil = require(script.Parent.Perfil)
local Config = require(ReplicatedStorage.Compartido.Config)

local Viajes = {}
local grupos = {} -- id -> { id, lider, miembros = { Player }, isla, presa, publico, clave }
local siguienteId = 1
local llevar -- función que mueve a un cazador de zona (modo "todo")

-- Cacerías en curso. Con varios servidores se guardan en el MemoryStore (memoria compartida entre
-- todos los servidores del juego); en Studio (modo "todo") se guardan aquí mismo.
local mapaCacerias = nil
pcall(function()
	mapaCacerias = MemoryStoreService:GetSortedMap("CaceriasActivas")
end)
local caceriasLocales = {} -- modo "todo": id -> { lider, isla, presa, publico, clave, miembros }
local listaCacerias = {} -- lo que ve cada jugador (sin contraseñas)
local DURACION = 90 -- segundos que una cacería sigue en la lista si su servidor deja de avisar

local function limpiarClave(c): string?
	if type(c) ~= "string" then
		return nil
	end
	c = string.sub(string.gsub(c, "%s", ""), 1, 12)
	return c ~= "" and c or nil
end

-- nombre del modelo de cada Behemoth (sale del bestiario)
local NOMBRES = {}
for _, f in Armas.BESTIARIO do
	NOMBRES[f.id] = f.modelo
end

local function behemothValido(isla: string, presa: string)
	for _, i in Armas.ISLAS do
		if i.id == isla and i.zona then
			for _, b in i.behemoths do
				if b.id == presa and not b.proximamente then
					return i, b
				end
			end
		end
	end
	return nil
end

local function grupoDe(jugador: Player)
	for _, g in grupos do
		if table.find(g.miembros, jugador) then
			return g
		end
	end
	return nil
end

-- manda a todos la lista de grupos del Refugio
local function publicar()
	local lista = {}
	for _, g in grupos do
		local nombres, ids = {}, {}
		for _, m in g.miembros do
			table.insert(nombres, m.DisplayName)
			table.insert(ids, m.UserId)
		end
		local isla, b = behemothValido(g.isla, g.presa)
		table.insert(lista, {
			id = g.id, lider = g.lider.DisplayName, liderId = g.lider.UserId, nombres = nombres, ids = ids,
			isla = isla and isla.nombre or "?", behemoth = b and b.nombre or "?", islaId = g.isla, presa = g.presa,
			publico = g.publico, -- la contraseña nunca se envía
		})
	end
	Remotos.Grupos:FireAllClients({ grupos = lista, cacerias = listaCacerias })
end

local function salir(jugador: Player)
	local g = grupoDe(jugador)
	if not g then
		return
	end
	table.remove(g.miembros, table.find(g.miembros, jugador))
	if #g.miembros == 0 then
		grupos[g.id] = nil
	elseif g.lider == jugador then
		g.lider = g.miembros[1]
	end
end

-- ---------- partir de caza ----------
local function partir(g)
	local isla, b = behemothValido(g.isla, g.presa)
	if not isla then
		return
	end
	grupos[g.id] = nil
	local miembros = {}
	for _, m in g.miembros do
		if m.Parent and m:GetAttribute("Zona") == "refugio" then
			table.insert(miembros, m)
			m:SetAttribute("Presa", NOMBRES[b.id])
		end
	end
	publicar()
	if #miembros == 0 then
		return
	end
	local id = HttpService:GenerateGUID(false)
	local registro = { lider = g.lider.DisplayName, isla = isla.nombre, islaId = isla.id, zona = isla.zona, presa = NOMBRES[b.id], behemoth = b.nombre, publico = g.publico, clave = g.clave, n = #miembros }
	if Servidores.modo() == "todo" then
		registro.miembros = table.clone(miembros)
		caceriasLocales[id] = registro
		for _, m in miembros do
			llevar(m, isla.zona)
		end
		return
	end
	-- servidor privado de cacería para este grupo
	for _, m in miembros do
		Remotos.Anuncio:FireClient(m, "Preparando la caravana...", Color3.fromRGB(255, 224, 138))
		Perfil.guardarYa(m)
	end
	local ok, err = pcall(function()
		local codigo = TeleportService:ReserveServer(Servidores.CACERIA)
		registro.codigo = codigo
		if mapaCacerias then
			mapaCacerias:SetAsync(id, registro, DURACION)
		end
		local opciones = Instance.new("TeleportOptions")
		opciones.ReservedServerAccessCode = codigo
		opciones:SetTeleportData({ zona = isla.zona, presa = NOMBRES[b.id], caceria = id })
		TeleportService:TeleportAsync(Servidores.CACERIA, miembros, opciones)
	end)
	if not ok then
		warn("No se pudo viajar a la cacería: " .. tostring(err))
		for _, m in miembros do
			Remotos.Anuncio:FireClient(m, "La caravana no pudo salir. Inténtalo de nuevo.", Color3.fromRGB(255, 138, 106))
		end
	end
end

-- ---------- volver al Refugio ----------
function Viajes.alRefugio(jugador: Player)
	if Servidores.modo() ~= "caceria" then
		llevar(jugador, "refugio")
		return
	end
	Perfil.guardarYa(jugador)
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(Servidores.LOBBY, { jugador })
	end)
	if not ok then
		warn("No se pudo volver al Refugio: " .. tostring(err))
		Remotos.Anuncio:FireClient(jugador, "La caravana no pudo salir. Inténtalo de nuevo.", Color3.fromRGB(255, 138, 106))
	end
end

-- Unirse a una cacería que ya empezó (si hay lugar y, si es privada, con la contraseña).
function Viajes.unirseCaceria(jugador: Player, id: string, clave: string?)
	if type(id) ~= "string" then
		return
	end
	local registro
	if Servidores.modo() == "todo" then
		registro = caceriasLocales[id]
	elseif mapaCacerias then
		pcall(function()
			registro = mapaCacerias:GetAsync(id)
		end)
	end
	if not registro then
		Remotos.Anuncio:FireClient(jugador, "Esa cacería ya terminó", Color3.fromRGB(255, 138, 106))
		return
	end
	if registro.clave and registro.clave ~= clave then
		Remotos.Anuncio:FireClient(jugador, "Contraseña incorrecta", Color3.fromRGB(255, 138, 106))
		return
	end
	if (registro.n or 0) >= Servidores.MAX_GRUPO then
		Remotos.Anuncio:FireClient(jugador, "Esa cacería ya está llena (4/4)", Color3.fromRGB(255, 138, 106))
		return
	end
	salir(jugador)
	jugador:SetAttribute("Presa", registro.presa)
	if Servidores.modo() == "todo" then
		table.insert(registro.miembros, jugador)
		llevar(jugador, registro.zona)
		return
	end
	Remotos.Anuncio:FireClient(jugador, "Uniéndote a la cacería...", Color3.fromRGB(255, 224, 138))
	Perfil.guardarYa(jugador)
	local ok, err = pcall(function()
		local opciones = Instance.new("TeleportOptions")
		opciones.ReservedServerAccessCode = registro.codigo
		opciones:SetTeleportData({ zona = registro.zona, presa = registro.presa, caceria = id })
		TeleportService:TeleportAsync(Servidores.CACERIA, { jugador }, opciones)
	end)
	if not ok then
		warn("No se pudo unir a la cacería: " .. tostring(err))
		Remotos.Anuncio:FireClient(jugador, "No se pudo entrar a esa cacería", Color3.fromRGB(255, 138, 106))
	end
end

-- Revisa cada pocos segundos qué cacerías siguen activas (para la lista de Tariq).
local function actualizarCacerias()
	local lista = {}
	local function agregar(id, r)
		table.insert(lista, { id = id, lider = r.lider, isla = r.isla, behemoth = r.behemoth, publico = r.clave == nil, n = r.n or 1 })
	end
	if Servidores.modo() == "todo" then
		for id, r in caceriasLocales do
			local quedan = {}
			for _, m in r.miembros do
				local zona = m.Parent and m:GetAttribute("Zona")
				if zona == r.zona then
					table.insert(quedan, m)
				end
			end
			r.miembros = quedan
			r.n = #quedan
			if r.n == 0 then
				caceriasLocales[id] = nil
			else
				agregar(id, r)
			end
		end
	elseif mapaCacerias then
		pcall(function()
			for _, e in mapaCacerias:GetRangeAsync(Enum.SortDirection.Ascending, 50) do
				agregar(e.key, e.value)
			end
		end)
	end
	listaCacerias = lista
	publicar()
end

-- En un servidor de caza: avisa cuántos cazadores hay, y borra la cacería al quedar vacío.
local function avisarDesdeCaceria()
	local miId = nil
	local function revisar()
		if not miId or not mapaCacerias then
			return
		end
		local n = #Players:GetPlayers()
		pcall(function()
			if n == 0 then
				mapaCacerias:RemoveAsync(miId)
			else
				mapaCacerias:UpdateAsync(miId, function(r)
					if r then
						r.n = n
					end
					return r
				end, DURACION)
			end
		end)
	end
	Players.PlayerAdded:Connect(function(j)
		local datos = j:GetJoinData()
		local td = datos and datos.TeleportData
		if not miId and type(td) == "table" and type(td.caceria) == "string" then
			miId = td.caceria
		end
		revisar()
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(revisar)
	end)
	game:BindToClose(function()
		if miId and mapaCacerias then
			pcall(function()
				mapaCacerias:RemoveAsync(miId)
			end)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(20)
			revisar()
		end
	end)
end

function Viajes.iniciar(funcionLlevar)
	if Servidores.modo() == "caceria" then
		avisarDesdeCaceria()
	else
		task.spawn(function()
			while true do
				actualizarCacerias()
				task.wait(Servidores.modo() == "todo" and 3 or 8)
			end
		end)
	end
	llevar = funcionLlevar
	Remotos.Grupo.OnServerEvent:Connect(function(jugador, accion, a, b, extra)
		local enRefugio = jugador:GetAttribute("Zona") == "refugio"
		local g = grupoDe(jugador)
		if accion == "pedir" then
			publicar()
			return
		elseif not enRefugio then
			return
		end
		if accion == "solo" or accion == "crear" then
			if not behemothValido(a, b) then
				return
			end
			salir(jugador)
			local clave = limpiarClave(extra)
			local nuevo = { id = siguienteId, lider = jugador, miembros = { jugador }, isla = a, presa = b, publico = clave == nil, clave = clave }
			siguienteId += 1
			grupos[nuevo.id] = nuevo
			if accion == "solo" then
				partir(nuevo)
				return
			end
			Remotos.Anuncio:FireClient(jugador, "Grupo creado. Espera a tus compañeros (máx. 4).", Color3.fromRGB(127, 255, 244))
		elseif accion == "unirseCaceria" then
			Viajes.unirseCaceria(jugador, a, limpiarClave(b))
			return
		elseif accion == "unirse" then
			local destino = grupos[a]
			if destino and destino.clave and destino.clave ~= limpiarClave(b) then
				Remotos.Anuncio:FireClient(jugador, "Contraseña incorrecta", Color3.fromRGB(255, 138, 106))
				return
			end
			if destino and #destino.miembros < Servidores.MAX_GRUPO and destino ~= g then
				salir(jugador)
				table.insert(destino.miembros, jugador)
				for _, m in destino.miembros do
					Remotos.Anuncio:FireClient(m, jugador.DisplayName .. " se unió al grupo", Color3.fromRGB(127, 255, 244))
				end
			end
		elseif accion == "salir" then
			salir(jugador)
		elseif accion == "partir" then
			if g and g.lider == jugador then
				partir(g)
				return
			end
		end
		publicar()
	end)
	Players.PlayerRemoving:Connect(function(j)
		if grupoDe(j) then
			salir(j)
			publicar()
		end
	end)
	-- los viajes de vuelta (botón de resultados y otras partes del juego)
	Remotos.Viajar.OnServerEvent:Connect(function(jugador, destino)
		local zona = jugador:GetAttribute("Zona")
		if destino == "refugio" and Config.ISLAS[zona] then
			Viajes.alRefugio(jugador)
		end
	end)
end

return Viajes
