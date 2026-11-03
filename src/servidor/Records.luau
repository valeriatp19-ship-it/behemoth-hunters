--!nonstrict
-- Récord global de cada Behemoth: el menor tiempo de caza de todos los jugadores.
-- Usa un OrderedDataStore de Roblox (funciona con el juego publicado, o en Studio con el
-- acceso a la API activado). Si no está disponible, recuerda el mejor tiempo de este servidor.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Records = {}
local cache = {} -- behemoth -> { tiempo, nombre }

local function almacen(behemoth: string)
	local ok, ds = pcall(function()
		return DataStoreService:GetOrderedDataStore("Record_" .. string.gsub(behemoth, " ", ""))
	end)
	return ok and ds or nil
end

function Records.registrar(jugador: Player, behemoth: string, tiempo: number)
	tiempo = math.floor(tiempo)
	local actual = cache[behemoth]
	if not actual or tiempo < actual.tiempo then
		cache[behemoth] = { tiempo = tiempo, nombre = jugador.Name }
	end
	task.spawn(function()
		local ds = almacen(behemoth)
		if ds then
			pcall(function()
				ds:UpdateAsync(tostring(jugador.UserId), function(anterior)
					if anterior == nil or tiempo < anterior then
						return tiempo
					end
					return nil
				end)
			end)
		end
	end)
end

function Records.consultar(behemoth: string)
	local ds = almacen(behemoth)
	if ds then
		local ok, pagina = pcall(function()
			return ds:GetSortedAsync(true, 1):GetCurrentPage()
		end)
		if ok and pagina and pagina[1] then
			local mejor = pagina[1]
			local nombre = "?"
			pcall(function()
				nombre = Players:GetNameFromUserIdAsync(tonumber(mejor.key))
			end)
			local actual = cache[behemoth]
			if not actual or mejor.value <= actual.tiempo then
				cache[behemoth] = { tiempo = mejor.value, nombre = nombre }
			end
		end
	end
	return cache[behemoth]
end

return Records
