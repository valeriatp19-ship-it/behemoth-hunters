--!nonstrict
-- Controles de el cazador (teclado y ratón, o mando), aguante, esquiva y ataques.
-- Mando: A saltar · B esquivar · cruceta arriba poción · X ataque · Y fuerte · L3 correr.
-- Teclado: Espacio saltar · Ctrl izq. esquivar · R poción · clic izq. ataque · clic der. fuerte · Shift correr.
-- El arma se elige en la armería del Refugio; en la cacería no se cambia.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Compartido = ReplicatedStorage:WaitForChild("Compartido")
local Config = require(Compartido.Config)
local Armas = require(Compartido.Armas)
local Remotos = require(Compartido.Remotos)
local Hud = require(script.Parent.Hud)
local Anim = require(script.Parent.Anim)
local Probador = require(script.Parent.Probador)
local Refugio = require(script.Parent.Refugio)
local SonidosCliente = require(script.Parent.SonidosCliente)
local Menu = require(script.Parent.Menu)
local AvisoInteraccion = require(script.Parent.AvisoInteraccion)
local ControlesTactiles = require(script.Parent.ControlesTactiles)
local Escala = require(script.Parent.Escala)
local Ambiente = require(script.Parent.Ambiente)
local Texturizador = require(script.Parent.Texturizador)
local ArmasPixel = require(script.Parent.ArmasPixel)
local ArmadurasPixel = require(script.Parent.ArmadurasPixel)
local Sonidos = require(Compartido.Sonidos)

local S = Config.S
local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera

local AGUANTE_MAX = 100
local estado = {
	aguante = AGUANTE_MAX,
	corriendo = false,
	correrFijo = false,
	bloqueadoHasta = 0,
	impulso = Vector3.zero,
	tImpulso = 0,
	calor = 0,
	sobrecalentado = false,
	menuAbierto = false,
	menus = {},
}

-- modificador de las piezas de armadura de la selva (1 si no lleva ninguna)
local function mod(char: Model?, clave: string): number
	local v = char and char:GetAttribute("Mod_" .. clave)
	return typeof(v) == "number" and v or 1
end

-- zonas donde se caza (cualquier isla de caza)
local function enDesierto(): boolean
	local zona = jugador:GetAttribute("Zona")
	return zona ~= nil and Config.ISLAS[zona] ~= nil
end

-- varias ventanas pueden estar abiertas (probador, Refugio, resultados)
local function menu(nombre: string, abierto: boolean)
	estado.menus[nombre] = abierto or nil
	estado.menuAbierto = next(estado.menus) ~= nil
	Hud.mostrar(enDesierto() and not estado.menus.probador)
end

local function personaje()
	local char = jugador.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then
		return char, hum, hrp
	end
	return nil
end

local function armaActual()
	local char = jugador.Character
	return Armas.DATOS[(char and char:GetAttribute("Arma")) or "espada"]
end

local function libre(): boolean
	return os.clock() >= estado.bloqueadoHasta and not estado.menuAbierto
end

-- El cazador gira hacia donde apunta la cámara al atacar: suavemente (sin saltos) y sin que
-- el giro automático de Roblox (hacia donde caminas) se pelee con el ataque.
local function mirarAlFrente(_hrp: BasePart)
	local mira = camara.CFrame.LookVector
	local plano = Vector3.new(mira.X, 0, mira.Z)
	if plano.Magnitude > 0.01 then
		estado.miraAtaque = plano.Unit
	end
end

local function girarSuave(hum: Humanoid, hrp: BasePart, dt: number)
	local atacando = estado.miraAtaque ~= nil and os.clock() < estado.bloqueadoHasta
	hum.AutoRotate = not atacando
	if not atacando then
		estado.miraAtaque = nil
		return
	end
	local actual = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if actual.Magnitude < 0.01 then
		return
	end
	actual = actual.Unit
	local deseada = estado.miraAtaque
	local angulo = math.acos(math.clamp(actual:Dot(deseada), -1, 1))
	if angulo < 0.01 then
		return
	end
	local k = math.min(1, dt * 18 / math.max(angulo, 0.3)) -- ~0.1 s para girar 90°
	local nueva = actual:Lerp(deseada, k)
	if nueva.Magnitude < 0.01 then
		nueva = deseada
	end
	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + nueva.Unit)
end

local function puntoApuntado(char: Model): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local origen = camara.CFrame.Position
	local res = workspace:Raycast(origen, camara.CFrame.LookVector * 400, params)
	return res and res.Position or origen + camara.CFrame.LookVector * 400
end

local function atacar(tipo: string)
	local char, _, hrp = personaje()
	if not char or not libre() then
		return
	end
	local arma = armaActual()
	local ataque = tipo == "fuerte" and arma.fuerte or arma.combo[1]
	local costo = (ataque.aguante or 0) * ((char:GetAttribute("Lleva_guanteletes") and tipo == "fuerte") and 0.7 or 1)
	if costo > 0 and estado.aguante < costo then
		Hud.aviso("¡Sin aguante!")
		return
	end
	if arma.distancia then
		if estado.sobrecalentado then
			Hud.aviso("¡Blásteres sobrecalentados!")
			return
		end
		estado.calor += tipo == "fuerte" and 30 or 7
		if estado.calor >= 100 then
			estado.sobrecalentado = true
			Hud.aviso("¡Sobrecalentados! Espera a que se enfríen")
		end
	end
	estado.aguante -= costo
	mirarAlFrente(hrp)
	Remotos.Ataque:FireServer(tipo, arma.distancia and puntoApuntado(char) or nil)
	-- avance corto hacia adelante, frenando si el Behemoth está muy cerca
	local paso = (ataque.paso or 0) * S
	if arma.poderId == "embestida" and tipo == "fuerte" then
		paso = 7 * S -- el Cuerno de Hércules embiste
	end
	local bestia = Hud.bestiaActual(hrp.Position)
	if bestia and bestia.PrimaryPart and (bestia.PrimaryPart.Position - hrp.Position).Magnitude < 8 * S and arma.poderId ~= "embestida" then
		paso *= 0.3
	end
	if paso > 0 then
		estado.impulso = hrp.CFrame.LookVector * paso / 0.18
		estado.tImpulso = 0.18
	end
	estado.bloqueadoHasta = os.clock() + ataque.duracion * (arma.distancia and 1 or 0.7)
	Anim.local_(char, ataque.anim, ataque.duracion)
	SonidosCliente.ataque(char, tipo == "fuerte")
end

-- Impulso de esquiva y de los ataques: una restricción de velocidad que se activa un instante.
local impulsor: LinearVelocity?
local function prepararImpulso(hrp: BasePart)
	if impulsor and impulsor.Parent and impulsor.Parent.Parent == hrp then
		return impulsor
	end
	local punto = Instance.new("Attachment")
	punto.Name = "PuntoImpulso"
	punto.Parent = hrp
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = punto
	lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	lv.MaxAxesForce = Vector3.new(1e6, 0, 1e6)
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Enabled = false
	lv.Parent = punto
	impulsor = lv
	return lv
end

local function esquivar()
	if estado.menuAbierto then
		Hud.cerrarResultados()
		Refugio.cerrar()
		Menu.cerrar()
		return
	end
	if not enDesierto() then
		return
	end
	local char, hum, hrp = personaje()
	if not char or estado.menuAbierto or os.clock() < estado.bloqueadoHasta - 0.25 then
		return
	end
	local costo = ((jugador.Character and jugador.Character:GetAttribute("Lleva_grebas")) and 14 or 25) * mod(jugador.Character, "esquivaCosto")
	if estado.aguante < costo then
		Hud.aviso("¡Sin aguante!")
		return
	end
	estado.aguante -= costo
	local dir = hum.MoveDirection
	if dir.Magnitude < 0.1 then
		dir = -hrp.CFrame.LookVector
	end
	local lejos = ((jugador.Character and jugador.Character:GetAttribute("Lleva_botas_uku")) and 1.3 or 1) * mod(jugador.Character, "esquivaLejos")
	estado.impulso = Vector3.new(dir.X, 0, dir.Z).Unit * 17 * S * lejos
	estado.tImpulso = 0.3
	estado.bloqueadoHasta = os.clock() + 0.45
	Remotos.Esquivar:FireServer()
	Anim.local_(char, "rueda", 0.45)
end

-- ---------- asignación de botones ----------
-- Las acciones de combate solo se usan en el desierto; en el Refugio las teclas quedan libres
-- (por ejemplo, para hablar con los personajes). B/Ctrl también cierran las ventanas.
local SIEMPRE = { Esquivar = true }
local function accion(nombre, funcion, ...)
	ContextActionService:BindActionAtPriority(nombre, function(_, estadoInput)
		if not enDesierto() and not SIEMPRE[nombre] and not estado.menuAbierto then
			return Enum.ContextActionResult.Pass
		end
		if not enDesierto() and nombre == "Esquivar" and not estado.menuAbierto then
			return Enum.ContextActionResult.Pass
		end
		if estadoInput == Enum.UserInputState.Begin then
			funcion(true)
		elseif estadoInput == Enum.UserInputState.End then
			funcion(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, ...)
end

accion("Ataque", function(apretado)
	if apretado then
		atacar("ligero")
	end
end, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonX)
accion("Fuerte", function(apretado)
	if apretado then
		atacar("fuerte")
	end
end, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonY)
accion("Esquivar", function(apretado)
	if apretado then
		esquivar()
	end
end, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)
-- Enter o A cierran la pantalla de resultados (A solo cuando está abierta; si no, salta)
ContextActionService:BindActionAtPriority("Aceptar", function(_, estadoInput)
	if Hud.resultadosAbiertos() then
		if estadoInput == Enum.UserInputState.Begin then
			Hud.cerrarResultados()
		end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Return, Enum.KeyCode.ButtonA)
accion("Pocion", function(apretado)
	if apretado and personaje() then
		Remotos.Pocion:FireServer()
	end
end, Enum.KeyCode.R, Enum.KeyCode.DPadUp)
accion("CorrerTecla", function(apretado)
	estado.corriendo = apretado
end, Enum.KeyCode.LeftShift)
accion("CorrerMando", function(apretado)
	if apretado then
		estado.correrFijo = not estado.correrFijo
	end
end, Enum.KeyCode.ButtonL3)

-- ---------- mensajes del servidor ----------
Remotos.Empuje.OnClientEvent:Connect(function(vector: Vector3, duracion: number)
	local char = personaje()
	if not char then
		return
	end
	if char:GetAttribute("Lleva_grebas_montana") then
		duracion *= 0.6
	end
	-- retroceso leve: unos pocos studs hacia atrás, sin despegar del suelo
	local plano = Vector3.new(vector.X, 0, vector.Z)
	if plano.Magnitude > 0.01 then
		plano = plano.Unit * math.min(plano.Magnitude, 5)
	end
	estado.impulso = plano / 0.2
	estado.tImpulso = 0.2
	estado.bloqueadoHasta = os.clock() + math.min(duracion, 0.45)
	Hud.sacudir(0.6)
	Anim.local_(char, "golpeado", duracion)
	SonidosCliente.tocar(Sonidos.GOLPEADO, char:FindFirstChild("HumanoidRootPart"))

end)

Remotos.Aturdir.OnClientEvent:Connect(function(duracion: number)
	local char = personaje()
	if char then
		if char:GetAttribute("Lleva_grebas_montana") then
			duracion *= 0.5
		end
		estado.bloqueadoHasta = os.clock() + duracion
		Hud.aviso("¡Estás aturdido!")
		Hud.sacudir(0.8)
	end
end)

-- avisos de los estados que dejan los Behemoths de la selva: sangrado y lodo que frena
local function vigilarEstados(char: Model)
	char:GetAttributeChangedSignal("Sangrando"):Connect(function()
		if (char:GetAttribute("Sangrando") or 0) > workspace:GetServerTimeNow() then
			Hud.aviso("¡Estás sangrando!")
		end
	end)
	char:GetAttributeChangedSignal("LentoHasta"):Connect(function()
		if (char:GetAttribute("LentoHasta") or 0) > workspace:GetServerTimeNow() then
			Hud.aviso("¡Atrapado en el lodo!")
		end
	end)
end
jugador.CharacterAdded:Connect(vigilarEstados)
if jugador.Character then
	vigilarEstados(jugador.Character)
end

Hud.iniciar(function(abierto)
	menu("resultados", abierto)
end)
Probador.iniciar(function()
	menu("probador", true)
end, function()
	menu("probador", false)
end)
Refugio.iniciar(function(abierto)
	menu("refugio", abierto)
end)
Menu.iniciar(function(abierto)
	menu("menu", abierto)
end)
task.spawn(SonidosCliente.iniciar)
AvisoInteraccion.iniciar()
Ambiente.iniciar()
Texturizador.iniciar()
ArmasPixel.iniciar()
ArmadurasPixel.iniciar()
ControlesTactiles.iniciar({
	atacar = function()
		if not estado.menuAbierto then
			atacar("ligero")
		end
	end,
	fuerte = function()
		if not estado.menuAbierto then
			atacar("fuerte")
		end
	end,
	esquivar = esquivar,
	pocion = function()
		if personaje() and not estado.menuAbierto then
			Remotos.Pocion:FireServer()
		end
	end,
	correr = function(activo)
		estado.correrFijo = activo
	end,
	menu = function()
		Menu.alternar()
	end,
})
jugador:GetAttributeChangedSignal("Zona"):Connect(function()
	menu("zona", false)
end)
menu("zona", false)
Anim.iniciar()

-- Al caminar contra un escalón de un bloque, el cazador lo sube deslizándose (sin saltar).
local subida = nil -- { falta = studs por subir, vel = studs por segundo, dir = dirección }
local tEscalon = 0
local function subirEscalon(char: Model, hum: Humanoid, hrp: BasePart, dt: number)
	-- si ya está subiendo, sigue subiendo poco a poco
	if subida then
		local paso = math.min(subida.falta, subida.vel * dt)
		subida.falta -= paso
		hrp.CFrame += Vector3.new(0, paso, 0) + subida.dir * (paso * 0.25)
		hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
		if subida.falta <= 0 then
			subida = nil
			tEscalon = 0.1
		end
		return
	end
	tEscalon -= dt
	local dir = hum.MoveDirection
	if dir.Magnitude < 0.5 or tEscalon > 0 or hum.FloorMaterial == Enum.Material.Air then
		return
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local abajo = workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
	if not abajo then
		return
	end
	local pies = abajo.Position.Y
	local frente = workspace:Raycast(Vector3.new(hrp.Position.X, pies + 0.6, hrp.Position.Z), dir * 1.8, params)
	-- solo escalones de terreno (paredes verticales) hacia donde de verdad camina
	if not frente or math.abs(frente.Normal.Y) > 0.3 or dir:Dot(-frente.Normal) < 0.7 or frente.Instance.Name ~= "Suelo" then
		return
	end
	local arriba = workspace:Raycast(frente.Position + dir * 0.6 + Vector3.new(0, Config.VOX_CUMBRES + 1.5, 0), Vector3.new(0, -(Config.VOX_CUMBRES + 2), 0), params)
	if arriba then
		local sube = arriba.Position.Y - pies
		if sube > 0.3 and sube <= Config.VOX_CUMBRES + 0.2 then
			subida = { falta = sube + 0.1, vel = (sube + 0.1) / 0.16, dir = dir }
		end
	end
end

-- El cazador nunca se tumba ni gira como trompo después de un golpe.
local estadosApagados = setmetatable({}, { __mode = "k" })
local function mantenerDePie(hum: Humanoid, hrp: BasePart)
	if not estadosApagados[hum] then
		estadosApagados[hum] = true
		for _, e in { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Physics, Enum.HumanoidStateType.PlatformStanding } do
			hum:SetStateEnabled(e, false)
		end
	end
	local giro = hrp.AssemblyAngularVelocity
	if giro.Magnitude > 0.5 then
		hrp.AssemblyAngularVelocity = Vector3.new(0, math.clamp(giro.Y, -3, 3), 0)
	end
	-- si quedó inclinado, lo endereza (conservando hacia dónde mira)
	if hrp.CFrame.UpVector.Y < 0.95 then
		local mira = hrp.CFrame.LookVector
		local plano = Vector3.new(mira.X, 0, mira.Z)
		if plano.Magnitude < 0.1 then
			plano = Vector3.new(0, 0, -1)
		end
		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + plano.Unit)
	end
end

-- Los Behemoths no chocan con la física (para que no te lancen por los aires): en su lugar,
-- si el cazador se mete en su cuerpo o debajo, se le empuja suavemente hacia afuera.
local solidos, tSolidos = {}, 0
local function separarDeBehemoths(hrp: BasePart)
	tSolidos -= 1 / 60
	if tSolidos <= 0 then
		tSolidos = 1
		solidos = {}
		local carpeta = workspace:FindFirstChild("Behemoths")
		for _, b in (carpeta and carpeta:GetChildren() or {}) do
			for _, p in b:GetDescendants() do
				if p:IsA("BasePart") and p:GetAttribute("Solido") then
					table.insert(solidos, p)
				end
			end
		end
	end
	local pos = hrp.Position
	for _, p in solidos do
		if p.Parent and p.Transparency < 1 and (p.Position - pos).Magnitude < 60 then
			local rel = p.CFrame:PointToObjectSpace(pos)
			local medio = p.Size / 2 + Vector3.new(1.6, 0, 1.6)
			-- dentro del cuerpo o debajo de él (entre el suelo y su parte de arriba)
			if math.abs(rel.X) < medio.X and math.abs(rel.Z) < medio.Z and rel.Y < medio.Y + 1 and rel.Y > -medio.Y - 12 then
				local salirX = medio.X - math.abs(rel.X)
				local salirZ = medio.Z - math.abs(rel.Z)
				local nuevo = salirX < salirZ and Vector3.new(math.sign(rel.X) * medio.X, rel.Y, rel.Z) or Vector3.new(rel.X, rel.Y, math.sign(rel.Z) * medio.Z)
				local destino = p.CFrame:PointToWorldSpace(nuevo)
				hrp.CFrame = hrp.CFrame + Vector3.new(destino.X - pos.X, 0, destino.Z - pos.Z) * 0.35
				pos = hrp.Position
			end
		end
	end
end

-- ---------- cada cuadro ----------
RunService.RenderStepped:Connect(function(dt)
	if Escala.tactil() then
		-- en pantallas táctiles la cámara se mueve con el dedo: no se fija el ratón
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif not estado.menuAbierto then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	local char, hum, hrp = personaje()
	if not char then
		return
	end
	hum.AutoJumpEnabled = false -- en celular Roblox salta solo al chocar: lo apagamos
	mantenerDePie(hum, hrp)
	girarSuave(hum, hrp, dt)
	separarDeBehemoths(hrp)
	subirEscalon(char, hum, hrp, dt)
	local arma = armaActual()
	local moviendose = hum.MoveDirection.Magnitude > 0.1
	local corre = (estado.corriendo or estado.correrFijo) and moviendose and estado.aguante > 1 and libre()
	if not moviendose and not Escala.tactil() then
		estado.correrFijo = false
	end
	if corre then
		estado.aguante = math.max(0, estado.aguante - 16 * dt * (char:GetAttribute("Lleva_grebas_escarabajo") and 0.65 or 1) * mod(char, "correrCosto"))
	elseif libre() then
		estado.aguante = math.min(AGUANTE_MAX, estado.aguante + 30 * dt * (char:GetAttribute("Lleva_garras") and 1.35 or 1) * mod(char, "aguanteRegen"))
	end
	-- el lodo de Cipactli y otros ataques frenan al cazador un rato
	local lento = (char:GetAttribute("LentoHasta") or 0) > workspace:GetServerTimeNow()
	if not libre() and estado.tImpulso <= 0 then
		hum.WalkSpeed = 3
	else
		hum.WalkSpeed = (corre and 26 or 16) * (lento and 0.55 or 1)
	end
	local lv = prepararImpulso(hrp)
	if estado.tImpulso > 0 then
		estado.tImpulso -= dt
		lv.VectorVelocity = Vector3.new(estado.impulso.X, 0, estado.impulso.Z)
		lv.Enabled = true
	else
		lv.Enabled = false
	end
	-- calor de los blásteres
	estado.calor = math.max(0, estado.calor - (estado.sobrecalentado and 45 or 30) * dt)
	if estado.sobrecalentado and estado.calor <= 0 then
		estado.sobrecalentado = false
	end
	Hud.actualizar({
		aguante = estado.aguante / AGUANTE_MAX,
		vida = hum.Health / hum.MaxHealth,
		arma = arma,
		pociones = jugador:GetAttribute("Pociones") or 3,
		calor = arma.distancia and estado.calor / 100 or nil,
		sobrecalentado = estado.sobrecalentado,
		posicion = hrp.Position,
	})
end)
