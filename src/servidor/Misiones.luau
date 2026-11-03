--!nonstrict
-- Revisa las misiones al terminar cada cacería y maneja los encargos que se aceptan con Sefu.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotos = require(ReplicatedStorage.Compartido.Remotos)
local Armas = require(ReplicatedStorage.Compartido.Armas)
local DatosMisiones = require(ReplicatedStorage.Compartido.DatosMisiones)
local Perfil = require(script.Parent.Perfil)

local Misiones = {}

local function estado(jugador: Player)
	local p = Perfil.de(jugador)
	p.misiones = p.misiones or { historia = 1, encargos = {} }
	p.misiones.encargos = p.misiones.encargos or {}
	return p.misiones
end

local function premiar(jugador: Player, premio)
	local materiales = {}
	for k, v in premio do
		if k ~= "xp" then
			materiales[k] = v
		end
	end
	Perfil.dar(jugador, materiales)
	if premio.xp then
		Perfil.darXP(jugador, premio.xp)
	end
end

-- Devuelve las líneas para la pantalla de resultados (misiones cumplidas).
function Misiones.evaluar(jugador: Player, datos): { string }
	local m = estado(jugador)
	local lineas = {}
	local actual = DatosMisiones.HISTORIA[m.historia]
	if actual and DatosMisiones.cumple(actual.cond, datos) then
		premiar(jugador, actual.premio)
		m.historia += 1
		table.insert(lineas, "¡Misión cumplida: " .. actual.titulo .. "! (" .. DatosMisiones.textoPremio(actual.premio, Armas.MATERIALES) .. ")")
		Remotos.Anuncio:FireClient(jugador, "¡Misión cumplida: " .. actual.titulo .. "!", Color3.fromRGB(255, 224, 138))
	end
	for i = #m.encargos, 1, -1 do
		local id = m.encargos[i]
		local e = DatosMisiones.ENCARGOS[id]
		if e and DatosMisiones.cumple(e.cond, datos) then
			premiar(jugador, e.premio)
			table.remove(m.encargos, i)
			table.insert(lineas, "¡Encargo cumplido: " .. e.titulo .. "! (" .. DatosMisiones.textoPremio(e.premio, Armas.MATERIALES) .. ")")
		end
	end
	Perfil.guardar(jugador)
	return lineas
end

function Misiones.iniciar()
	Remotos.Mision.OnServerEvent:Connect(function(jugador, accion, id)
		if jugador:GetAttribute("Zona") ~= "refugio" or not DatosMisiones.ENCARGOS[id] then
			return
		end
		local m = estado(jugador)
		local i = table.find(m.encargos, id)
		if accion == "aceptar" and not i and #m.encargos < DatosMisiones.MAX_ENCARGOS then
			table.insert(m.encargos, id)
		elseif accion == "abandonar" and i then
			table.remove(m.encargos, i)
		end
		Perfil.guardar(jugador)
	end)
end

return Misiones
