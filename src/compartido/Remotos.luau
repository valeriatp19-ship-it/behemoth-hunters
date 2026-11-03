--!nonstrict
-- Mensajes entre el servidor y las jugadoras. El servidor los crea; las jugadoras los esperan.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NOMBRES = {
	"Ataque", "Esquivar", "Pocion", "CambiarArma", "Numero", "Anuncio", "Empuje",
	"Resultados", "Disparo", "Aturdir", "Apariencia", "Listo", "AbrirProbador",
	"Perfil", "Forjar", "ElegirArma", "AlternarPieza", "Viajar", "AbrirMenu", "MaterialesPrueba",
	"Grupo", "Grupos", "Mision", "Misiones",
}

local Remotos = {}

local carpeta
if RunService:IsServer() then
	carpeta = ReplicatedStorage:FindFirstChild("Remotos") or Instance.new("Folder")
	carpeta.Name = "Remotos"
	carpeta.Parent = ReplicatedStorage
	for _, nombre in NOMBRES do
		if not carpeta:FindFirstChild(nombre) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = nombre
			ev.Parent = carpeta
		end
	end
else
	carpeta = ReplicatedStorage:WaitForChild("Remotos")
end

if RunService:IsServer() and not carpeta:FindFirstChild("PedirBestiario") then
	local f = Instance.new("RemoteFunction")
	f.Name = "PedirBestiario"
	f.Parent = carpeta
end
table.insert(NOMBRES, "PedirBestiario")
for _, nombre in NOMBRES do
	Remotos[nombre] = carpeta:WaitForChild(nombre)
end

return Remotos
