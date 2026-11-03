--!nonstrict
-- Servidores del juego. Behemoth Hunters usa dos lugares (places) dentro del mismo juego:
--   · el Refugio de Qamar (lobby), donde se arman los grupos de hasta 4 cazadores, y
--   · la Cacería, donde cada grupo tiene su propio servidor privado.
-- Pon aquí los números (PlaceId) de tus dos lugares. Mientras CACERIA sea 0 (o al probar en
-- Studio), todo funciona en un solo servidor, como antes.
local Servidores = {}

Servidores.LOBBY = 130368892133377 -- "Lobby": el Refugio (lugar principal)
Servidores.CACERIA = 72816927144364 -- "Hunt 1": la cacería
Servidores.MAX_GRUPO = 4

-- "lobby", "caceria" o "todo" (todo junto en un solo servidor)
function Servidores.modo(): string
	-- en Studio no se puede viajar entre lugares: ahí todo funciona junto en un solo servidor
	if game:GetService("RunService"):IsStudio() then
		return "todo"
	end
	local id = game.PlaceId
	if Servidores.CACERIA ~= 0 and id == Servidores.CACERIA then
		return "caceria"
	end
	if Servidores.CACERIA ~= 0 and Servidores.LOBBY ~= 0 and id == Servidores.LOBBY then
		return "lobby"
	end
	return "todo"
end

return Servidores
