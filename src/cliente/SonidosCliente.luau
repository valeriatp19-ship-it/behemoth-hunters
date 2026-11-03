--!nonstrict
-- Hace sonar las armas de todos los cazadores y las acciones de los Behemoths.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Compartido = ReplicatedStorage:WaitForChild("Compartido")
local Sonidos = require(Compartido.Sonidos)
local Armas = require(Compartido.Armas)

local SonidosCliente = {}

function SonidosCliente.tocar(def, lugar: Instance?)
	if not def or not lugar then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = def[1]
	s.PlaybackSpeed = def[2] * (0.95 + math.random() * 0.1)
	s.Volume = def[3]
	s.RollOffMaxDistance = 260
	s.Parent = lugar
	s:Play()
	Debris:AddItem(s, 4)
end

-- sonido del ataque de un cazador (ligero o fuerte)
function SonidosCliente.ataque(char: Model, fuerte: boolean)
	local arma = char:GetAttribute("Arma")
	local defs = arma and Sonidos.ARMAS[arma]
	if not defs and arma and Armas.DATOS[arma] then
		defs = Sonidos.ARMAS[Armas.DATOS[arma].base or ""] -- las armas nuevas suenan como su tipo
	end
	if defs then
		SonidosCliente.tocar(fuerte and defs.fuerte or defs.tajo, char:FindFirstChild("HumanoidRootPart"))
	end
end

local ACCIONES_BEHEMOTH = {
	rugir = "rugir", derribado = "derribado", muerte = "derribado",
	mordida = "ataque", pisoton = "golpe", coletazo = "ataque", aguijonazo = "ataque", embestida = "ataque",
	enterrarse = "golpe", rayo_solar = "ataque", pinza = "golpe", embestida_carga = "ataque", salto = "golpe",
	bola_carga = "ataque", latigazo = "ataque", enroscarse = "ataque", planeo = "ataque", rayo = "ataque",
	plumas = "ataque", nube = "rugir", sombras = "ataque",
	punetazo = "golpe", carga = "ataque", roca = "ataque", pecho = "rugir", rayo_sol = "ataque",
	zarpazo = "golpe", grito = "rugir", onda = "ataque", picada = "ataque", enjambre = "rugir",
	chorro = "ataque", sumergirse = "golpe", rayos = "rugir", panzazo = "golpe", zigzag = "ataque", rugido = "rugir",
	giro = "ataque", emboscada = "golpe", geiseres = "rugir", fauces = "ataque",
}

local function vigilarCazador(char: Model, esLocal: boolean)
	char:GetAttributeChangedSignal("AnimT0"):Connect(function()
		local anim = char:GetAttribute("Anim")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if anim == "rueda" then
			SonidosCliente.tocar(Sonidos.ESQUIVA, hrp)
		elseif not esLocal and anim then
			-- los ataques propios suenan al instante desde los controles; los de otros, aquí
			local d = Armas.DATOS[char:GetAttribute("Arma") or ""]
			local fuerte = d and d.fuerte and math.abs((char:GetAttribute("AnimDur") or 0) - d.fuerte.duracion) < 0.01
			SonidosCliente.ataque(char, fuerte)
		end
	end)
end

function SonidosCliente.iniciar()
	local yo = Players.LocalPlayer
	local function conectar(j: Player)
		j.CharacterAdded:Connect(function(char)
			vigilarCazador(char, j == yo)
		end)
		if j.Character then
			vigilarCazador(j.Character, j == yo)
		end
	end
	Players.PlayerAdded:Connect(conectar)
	for _, j in Players:GetPlayers() do
		conectar(j)
	end
	local carpeta = workspace:WaitForChild("Behemoths", 30)
	if not carpeta then
		return
	end
	local function vigilarBestia(b: Instance)
		if not b:IsA("Model") then
			return
		end
		b:GetAttributeChangedSignal("AnimT0"):Connect(function()
			local accion = ACCIONES_BEHEMOTH[b:GetAttribute("Anim") or ""]
			local defs = Sonidos.BEHEMOTHS[b:GetAttribute("Nombre") or b.Name]
			if accion and defs then
				SonidosCliente.tocar(defs[accion], b.PrimaryPart)
			end
		end)
	end
	carpeta.ChildAdded:Connect(vigilarBestia)
	for _, b in carpeta:GetChildren() do
		vigilarBestia(b)
	end
end

return SonidosCliente
