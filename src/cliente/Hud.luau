--!nonstrict
-- Interfaz de la cacería: vida, aguante, arma y pociones; el indicador de Sekhmaur estilo Dauntless
-- (retrato en un aro y corazón que se vacía), partes rompibles, avisos, números de daño y resultados.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Compartido = ReplicatedStorage:WaitForChild("Compartido")
local Config = require(Compartido.Config)
local Armas = require(Compartido.Armas)
local FICHA = {} -- datos del bestiario por nombre del Behemoth
for _, f in Armas.BESTIARIO do
	FICHA[f.nombre] = f
end
local Remotos = require(Compartido.Remotos)
local Escala = require(script.Parent.Escala)

local S = Config.S
local Hud = {}
local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera
local gui: ScreenGui
local el: { [string]: any } = {}
local temblor = 0
local alMenu

local ORO = Color3.fromRGB(243, 214, 160)

local function crear(clase: string, props: { [string]: any }, padre: Instance?): Instance
	local x = Instance.new(clase)
	for k, v in props do
		x[k] = v
	end
	x.Parent = padre
	return x
end

local function texto(props, padre)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.Arcade,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.2,
		TextSize = 18,
	}
	for k, v in props do
		base[k] = v
	end
	return crear("TextLabel", base, padre)
end

local function barra(color: Color3, tam: UDim2, pos: UDim2, padre)
	local fondo = crear("Frame", { Size = tam, Position = pos, BackgroundColor3 = Color3.fromRGB(20, 20, 30), BackgroundTransparency = 0.3, BorderSizePixel = 0 }, padre)
	crear("UIStroke", { Thickness = 2, Color = Color3.fromRGB(20, 14, 10) }, fondo)
	local relleno = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0 }, fondo)
	return fondo, relleno
end

-- El Behemoth que se muestra arriba: el que estás golpeando; si murió, el que siga vivo en tu isla
-- (primero el que elegiste con Tariq, si no el más cercano).
local function bestiaActual(posicion: Vector3?): Model?
	local carpeta = workspace:FindFirstChild("Behemoths")
	if not carpeta then
		return nil
	end
	local zonaActual = jugador:GetAttribute("Zona")
	local mapa = zonaActual ~= "desierto" and zonaActual or nil -- Sekhmaur no lleva atributo de mapa
	local enfrentando = jugador:GetAttribute("Enfrentando")
	local presa = jugador:GetAttribute("Presa")
	local candidatos = {}
	for _, b in carpeta:GetChildren() do
		if b:IsA("Model") and b.PrimaryPart and b:GetAttribute("Mapa") == mapa then
			table.insert(candidatos, b)
		end
	end
	local function buscar(nombre)
		for _, b in candidatos do
			if b.Name == nombre and not b:GetAttribute("Muerto") then
				return b
			end
		end
		return nil
	end
	local elegido = buscar(enfrentando) or buscar(presa)
	if elegido then
		return elegido
	end
	local mejor, mejorD = nil, math.huge
	for _, b in candidatos do
		local d = posicion and (b.PrimaryPart.Position - posicion).Magnitude or 0
		if b:GetAttribute("Muerto") then
			d += 1e7 -- los que están muertos solo si no queda otro
		end
		if d < mejorD then
			mejor, mejorD = b, d
		end
	end
	return mejor
end
Hud.bestiaActual = bestiaActual
local ultimaBestia

-- ---------- construcción ----------
function Hud.iniciar(callbackMenu)
	alMenu = callbackMenu
	gui = crear("ScreenGui", { Name = "HudCaceria", ResetOnSpawn = false, IgnoreGuiInset = true }, jugador:WaitForChild("PlayerGui")) :: ScreenGui
	-- abajo a la izquierda
	el.arma = texto({ Size = UDim2.fromOffset(420, 28), Position = UDim2.new(0, 24, 1, -150), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 22, TextColor3 = ORO }, gui)
	local fondoEscudo, escudo = barra(Color3.fromRGB(255, 154, 46), UDim2.fromOffset(340, 7), UDim2.new(0, 24, 1, -128), gui)
	el.fondoEscudo, el.escudo = fondoEscudo, escudo
	local _, vida = barra(Color3.fromRGB(95, 191, 90), UDim2.fromOffset(340, 16), UDim2.new(0, 24, 1, -116), gui)
	el.vida = vida
	local _, aguante = barra(Color3.fromRGB(232, 195, 74), UDim2.fromOffset(340, 9), UDim2.new(0, 24, 1, -94), gui)
	el.aguante = aguante
	local fondoCalor, calor = barra(Color3.fromRGB(255, 140, 60), UDim2.fromOffset(340, 7), UDim2.new(0, 24, 1, -80), gui)
	el.fondoCalor, el.calor = fondoCalor, calor
	el.info = texto({ Size = UDim2.fromOffset(420, 24), Position = UDim2.new(0, 24, 1, -66), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 17 }, gui)
	el.aviso = texto({ Size = UDim2.fromOffset(420, 24), Position = UDim2.new(0, 24, 1, -186), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 18, TextColor3 = Color3.fromRGB(255, 200, 120), TextTransparency = 1 }, gui)
	-- ayuda de controles
	el.ayuda = texto({
		Size = UDim2.fromOffset(560, 110), Position = UDim2.new(1, -580, 1, -126), TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom, TextSize = 14, TextTransparency = 0.15,
		Text = "Mover: stick izq. / WASD · Cámara: stick der. / ratón\nAtaque: X / clic izq. · Fuerte: Y / clic der.\nSaltar: A / Espacio · Esquivar: B / Ctrl\nPoción: cruceta ↑ / R · Correr: L3 / Shift · Menú: Select / M",
	}, gui)
	-- en pantallas táctiles: barras arriba a la izquierda (el joystick está abajo) y sin ayuda de teclas
	if Escala.tactil() then
		el.ayuda.Visible = false
		local x, ancho = 16, 230
		el.arma.Position = UDim2.fromOffset(x, 58)
		el.arma.Size = UDim2.fromOffset(300, 22)
		el.arma.TextSize = 16
		el.fondoEscudo.Position = UDim2.fromOffset(x, 84)
		el.vida.Parent.Position = UDim2.fromOffset(x, 94)
		el.aguante.Parent.Position = UDim2.fromOffset(x, 114)
		el.fondoCalor.Position = UDim2.fromOffset(x, 127)
		for _, barra in { el.fondoEscudo, el.vida.Parent, el.aguante.Parent, el.fondoCalor } do
			barra.Size = UDim2.fromOffset(ancho, barra.Size.Y.Offset)
		end
		el.info.Position = UDim2.fromOffset(x, 136)
		el.info.TextSize = 14
		el.aviso.Position = UDim2.fromOffset(x, 160)
	end
	-- mira para los blásteres
	el.mira = texto({ Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, -20, 0.5, -20), Text = "+", TextSize = 30, Font = Enum.Font.Code, Visible = false }, gui)
	-- indicador de Sekhmaur: retrato en un marco cuadrado y corazón de píxeles
	local marco = crear("Frame", { Size = UDim2.fromOffset(108, 108), Position = UDim2.new(0.5, -54, 0, 16), BackgroundColor3 = Color3.fromRGB(20, 32, 58), BorderSizePixel = 0 }, gui)
	el.aro = crear("UIStroke", { Thickness = 5, Color = Color3.fromRGB(216, 221, 226) }, marco)
	el.retrato = crear("ViewportFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 190, 180), LightColor = Color3.fromRGB(255, 240, 220) }, marco)
	el.camRetrato = crear("Camera", { FieldOfView = 30 }, el.retrato)
	el.retrato.CurrentCamera = el.camRetrato
	local DIBUJO = {
		".XX...XX.",
		"XXXX.XXXX",
		"XXXXXXXXX",
		"XXXXXXXXX",
		".XXXXXXX.",
		"..XXXXX..",
		"...XXX...",
		"....X....",
	}
	local P = 7
	local corazon = crear("Frame", { Size = UDim2.fromOffset(9 * P + 4, 8 * P + 4), Position = UDim2.new(0.5, -(9 * P + 4) / 2, 0, 128), BackgroundTransparency = 1 }, gui)
	el.corazon = corazon
	el.pixeles = {}
	for fila, linea in DIBUJO do
		for col = 1, 9 do
			if string.sub(linea, col, col) == "X" then
				-- borde claro detrás de cada píxel
				crear("Frame", { Size = UDim2.fromOffset(P + 4, P + 4), Position = UDim2.fromOffset((col - 1) * P, (fila - 1) * P), BackgroundColor3 = Color3.fromRGB(230, 233, 236), BorderSizePixel = 0, ZIndex = 1 }, corazon)
			end
		end
	end
	for fila, linea in DIBUJO do
		for col = 1, 9 do
			if string.sub(linea, col, col) == "X" then
				local px = crear("Frame", { Size = UDim2.fromOffset(P, P), Position = UDim2.fromOffset((col - 1) * P + 2, (fila - 1) * P + 2), BackgroundColor3 = Color3.fromRGB(200, 48, 42), BorderSizePixel = 0, ZIndex = 2 }, corazon)
				table.insert(el.pixeles, { px, col })
			end
		end
	end
	el.estados = texto({ Size = UDim2.fromOffset(500, 22), Position = UDim2.new(0.5, -250, 0, 190), TextSize = 16, TextColor3 = Color3.fromRGB(255, 200, 150) }, gui)
	el.rastreo = texto({ Size = UDim2.fromOffset(500, 22), Position = UDim2.new(0.5, -250, 0, 212), TextSize = 17, TextColor3 = ORO }, gui)
	-- partes rompibles (arriba a la derecha)
	el.partes = texto({ Size = UDim2.fromOffset(300, 130), Position = UDim2.new(1, -320, 0, 16), TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top, TextSize = 17 }, gui)
	-- la nube de sombra de Amaru oscurece la pantalla
	el.sombra = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 4, 18), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0 }, gui)
	-- anuncios en el centro
	el.anuncio = texto({ Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0.3, 0), TextSize = 28, TextColor3 = ORO, TextTransparency = 1, TextStrokeTransparency = 1 }, gui)
	-- pantalla de resultados
	local panel = crear("Frame", { Size = UDim2.fromOffset(520, 380), Position = UDim2.new(0.5, -260, 0.5, -190), BackgroundColor3 = Color3.fromRGB(15, 26, 44), BackgroundTransparency = 0.05, Visible = false }, gui)
	crear("UIStroke", { Thickness = 4, Color = Color3.fromRGB(230, 176, 74) }, panel)
	el.panel = panel
	Escala.ajustar(panel, 520, 380)
	el.resultado = texto({ Size = UDim2.new(1, -40, 1, -90), Position = UDim2.fromOffset(20, 16), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextSize = 19, TextWrapped = true }, panel)
	local boton = crear("TextButton", { Size = UDim2.fromOffset(230, 46), Position = UDim2.new(0.5, -240, 1, -64), BackgroundColor3 = Color3.fromRGB(230, 176, 74), BorderSizePixel = 0, Text = "Seguir cazando", Font = Enum.Font.Arcade, TextSize = 18, TextColor3 = Color3.fromRGB(30, 20, 10) }, panel)
	local volver = crear("TextButton", { Size = UDim2.fromOffset(230, 46), Position = UDim2.new(0.5, 10, 1, -64), BackgroundColor3 = Color3.fromRGB(127, 220, 210), BorderSizePixel = 0, Text = "Volver al Refugio", Font = Enum.Font.Arcade, TextSize = 18, TextColor3 = Color3.fromRGB(30, 20, 10) }, panel)
	volver.Activated:Connect(function()
		Hud.cerrarResultados()
		Remotos.Viajar:FireServer("refugio")
	end)
	boton.Activated:Connect(function()
		Hud.cerrarResultados()
	end)
	el.boton = boton

	Remotos.Anuncio.OnClientEvent:Connect(function(t, color)
		Hud.anunciar(t, color)
	end)
	Remotos.Numero.OnClientEvent:Connect(Hud.numero)
	Remotos.Disparo.OnClientEvent:Connect(Hud.disparo)
	Remotos.Resultados.OnClientEvent:Connect(Hud.resultados)
	RunService:BindToRenderStep("Temblor", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if temblor > 0 then
			temblor = math.max(0, temblor - dt * 2.5)
			local k = temblor * 0.35
			camara.CFrame = camara.CFrame * CFrame.new((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0)
		end
	end)
	task.spawn(function()
		while true do
			Hud._retrato()
			task.wait(3)
		end
	end)
end

-- ---------- cada cuadro ----------
local tRetratoFase
function Hud.actualizar(d)
	el.arma.Text = d.arma.nombre .. " · " .. d.arma.rol
	el.vida.Size = UDim2.fromScale(math.clamp(d.vida, 0, 1), 1)
	el.aguante.Size = UDim2.fromScale(math.clamp(d.aguante, 0, 1), 1)
	el.fondoCalor.Visible = d.calor ~= nil
	if d.calor then
		el.calor.Size = UDim2.fromScale(math.clamp(d.calor, 0, 1), 1)
		el.calor.BackgroundColor3 = d.sobrecalentado and Color3.fromRGB(255, 70, 50) or Color3.fromRGB(255, 140, 60)
	end
	el.mira.Visible = d.calor ~= nil
	local char = jugador.Character
	local calor = char and char:GetAttribute("Calor")
	local extra = ""
	if char and char:GetAttribute("Arma") == "mandibula" then
		extra = ("   ·   Calor %d%%"):format(calor or 0)
	elseif char and char:GetAttribute("Arma") == "filo_eclipse" then
		extra = ("   ·   Marcas de sombra %d/5"):format(char:GetAttribute("Marcas") or 0)
	elseif char and char:GetAttribute("Arma") == "filo_inti" then
		extra = ("   ·   Luz %d/4"):format(char:GetAttribute("Luz") or 0)
	end
	el.info.Text = ("Nv. %d   ·   Pociones %d"):format(char and char:GetAttribute("Nivel") or 1, d.pociones) .. extra
	-- ¿está dentro de una nube de sombra? (dos piezas del Set del Eclipse la ignoran)
	local oscuro = 0
	if not (char and (char:GetAttribute("Piezas_eclipse") or 0) >= 2) then
		for _, x in workspace:GetChildren() do
			if x.Name == "NubeSombra" and x:IsA("BasePart") then
				local r = x:GetAttribute("Radio") or 50
				if (x.Position - d.posicion).Magnitude < r then
					oscuro = 0.82
				end
			end
		end
	end
	local actual = 1 - el.sombra.BackgroundTransparency
	el.sombra.BackgroundTransparency = 1 - (actual + (oscuro - actual) * 0.1)
	local maxEscudo = char and char:GetAttribute("EscudoMax") or 0
	el.fondoEscudo.Visible = maxEscudo > 0
	if maxEscudo > 0 then
		el.escudo.Size = UDim2.fromScale(math.clamp((char:GetAttribute("Escudo") or 0) / maxEscudo, 0, 1), 1)
	end
	local bestia = bestiaActual(d.posicion)
	if bestia ~= ultimaBestia then
		ultimaBestia = bestia
		Hud._retrato()
	end
	if not bestia then
		return
	end
	local vida, max = bestia:GetAttribute("Vida") or 1, bestia:GetAttribute("VidaMax") or 1
	-- el corazón se vacía columna por columna, de derecha a izquierda
	local columnas = math.clamp(vida / max, 0, 1) * 9
	for _, px in el.pixeles do
		local lleno = px[2] <= math.ceil(columnas - 0.001)
		px[1].BackgroundColor3 = lleno and Color3.fromRGB(200, 48, 42) or Color3.fromRGB(42, 22, 20)
	end
	local furioso = bestia:GetAttribute("Furioso")
	local muerto = bestia:GetAttribute("Muerto")
	local latido = (furioso and not muerto) and math.sin(os.clock() * 8) > 0.3
	el.corazon.Position = UDim2.new(0.5, -33, 0, latido and 126 or 128)
	el.aro.Color = (bestia:GetAttribute("Fase2") and not muerto) and Color3.fromRGB(127, 255, 244) or Color3.fromRGB(216, 221, 226)
	el.retrato.ImageColor3 = muerto and Color3.fromRGB(110, 110, 110) or Color3.new(1, 1, 1)
	if bestia:GetAttribute("Fase2") ~= tRetratoFase then
		tRetratoFase = bestia:GetAttribute("Fase2")
		Hud._retrato()
	end
	-- estados y rastreo
	local estados = {}
	local est = bestia:GetAttribute("Estado")
	if est == "derribado" then
		table.insert(estados, "Derribado")
	end
	if bestia:GetAttribute("Fase2") then
		local f = FICHA[bestia:GetAttribute("Nombre")]
		table.insert(estados, f and f.fase2 or "Guardián despierto")
	end
	if furioso then
		table.insert(estados, "Furioso")
	end
	if bestia:GetAttribute("Herido") then
		table.insert(estados, "Herido")
	end
	if bestia:GetAttribute("Envenenado") then
		table.insert(estados, "Envenenado")
	end
	if bestia:GetAttribute("Quemado") then
		table.insert(estados, "En llamas")
	end
	if bestia:GetAttribute("Sangrando") then
		table.insert(estados, "Sangrando")
	end
	if bestia:GetAttribute("Lento") then
		table.insert(estados, "Frenado")
	end
	el.estados.Text = table.concat(estados, "  ·  ")
	local raiz = bestia.PrimaryPart
	if raiz and not muerto then
		local dist = (Vector2.new(raiz.Position.X, raiz.Position.Z) - Vector2.new(d.posicion.X, d.posicion.Z)).Magnitude / S
		local f = FICHA[bestia:GetAttribute("Nombre")]
		local pista = f and f.pista or "sigue a los buitres"
		el.rastreo.Text = dist > 40 and ("^ %s: %d m (%s)"):format(bestia:GetAttribute("Nombre") or "?", dist, pista) or (bestia:GetAttribute("Alerta") and "" or "No te ha visto")
	else
		el.rastreo.Text = ""
	end
	local lineas = { (bestia:GetAttribute("Nombre") or "") .. " · partes" }
	local lista = {}
	for par in string.gmatch(bestia:GetAttribute("Partes") or "", "[^;]+") do
		local id, nombre = string.match(par, "([^:]+):(.+)")
		table.insert(lista, { id, nombre })
	end
	for _, p in lista do
		local v = bestia:GetAttribute("P_" .. p[1]) or 1
		local txt = v == -1 and "¡ROTA!" or (v == -2 and "oculto" or ("%d%%"):format(math.floor(v * 100 + 0.5)))
		table.insert(lineas, p[2] .. ": " .. txt)
	end
	table.insert(lineas, ("Derribo: %d%%"):format(math.floor((bestia:GetAttribute("Derribo") or 0) * 100)))
	el.partes.Text = table.concat(lineas, "\n")
end

-- Foto de la cabeza de Sekhmaur para el retrato (se toma cada pocos segundos).
function Hud._retrato()
	local char = jugador.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local bestia = bestiaActual(hrp and hrp.Position)
	if not bestia or not el.retrato then
		return
	end
	for _, h in el.retrato:GetChildren() do
		if h:IsA("Model") then
			h:Destroy()
		end
	end
	local copia = bestia:Clone()
	for _, x in copia:GetDescendants() do
		if x:IsA("ParticleEmitter") or x:IsA("Script") or x:IsA("LocalScript") then
			x:Destroy()
		end
	end
	copia.Parent = el.retrato
	local cabeza = copia:FindFirstChild("Cabeza")
	if cabeza then
		local cf = cabeza.CFrame
		local lejos = (bestia:GetAttribute("Nombre") == "Sekhmaur") and -6.5 or -9
		el.camRetrato.CFrame = CFrame.lookAt((cf * CFrame.new(2.5 * S, 0.9 * S, lejos * S)).Position, cf.Position + Vector3.new(0, 0.3 * S, 0))
	end
end

-- ---------- avisos, números y efectos ----------
function Hud.anunciar(t: string, color: Color3?)
	el.anuncio.Text = t
	el.anuncio.TextColor3 = color or ORO
	el.anuncio.TextTransparency = 0
	el.anuncio.TextStrokeTransparency = 0.3
	local id = os.clock()
	el.anuncio:SetAttribute("id", id)
	task.delay(2.2, function()
		if el.anuncio:GetAttribute("id") == id then
			TweenService:Create(el.anuncio, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

function Hud.mostrar(visible: boolean)
	if gui then
		gui.Enabled = visible
	end
end

function Hud.aviso(t: string)
	el.aviso.Text = t
	el.aviso.TextTransparency = 0
	TweenService:Create(el.aviso, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
end

function Hud.sacudir(fuerza: number)
	temblor = math.max(temblor, fuerza)
end

-- Chispas del color del golpe en el punto del impacto (y un destello en los golpes fuertes).
local function chispas(pos: Vector3, color: Color3, grande: boolean)
	local p = crear("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, Position = pos }, workspace)
	local e = crear("ParticleEmitter", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), color), LightEmission = 1, Rate = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, grande and 0.9 or 0.6), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(grande and 30 or 18, grande and 55 or 34),
		SpreadAngle = Vector2.new(180, 180), Drag = 5, Acceleration = Vector3.new(0, -30, 0), Squash = NumberSequence.new(1.5),
	}, p)
	e:Emit(grande and 28 or 14)
	if grande then
		local destello = crear("PointLight", { Color = color, Range = 18, Brightness = 4 }, p)
		TweenService:Create(destello, TweenInfo.new(0.25), { Brightness = 0 }):Play()
	end
	game:GetService("Debris"):AddItem(p, 1)
end

function Hud.numero(pos: Vector3, t: string, color: Color3, grande: boolean)
	if string.match(t, "^%d+$") then
		chispas(pos, color, grande)
	end
	local ancla = crear("Part", { Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.one, Position = pos + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 2 }, workspace)
	local cartel = crear("BillboardGui", { Size = UDim2.fromOffset(200, 50), AlwaysOnTop = true, Adornee = ancla }, ancla)
	local etiqueta = texto({ Size = UDim2.fromScale(1, 1), Text = t, TextColor3 = color, TextSize = grande and 36 or 26, TextStrokeTransparency = 0 }, cartel)
	TweenService:Create(ancla, TweenInfo.new(0.9), { Position = ancla.Position + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(etiqueta, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(ancla, 1)
end

function Hud.disparo(desde: Vector3, hasta: Vector3, cargado: boolean)
	local largo = (hasta - desde).Magnitude
	local rayo = crear("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, Material = Enum.Material.Neon,
		Color = cargado and Color3.fromRGB(255, 220, 120) or Color3.fromRGB(127, 255, 244),
		Size = Vector3.new(cargado and 0.6 or 0.25, cargado and 0.6 or 0.25, largo),
		CFrame = CFrame.lookAt((desde + hasta) / 2, hasta),
	}, workspace)
	TweenService:Create(rayo, TweenInfo.new(0.12), { Transparency = 1 }):Play()
	Debris:AddItem(rayo, 0.15)
end

function Hud.resultados(r)
	local lineas = { (r.exito and "¡CACERÍA COMPLETADA!" or "LA CACERÍA FRACASÓ") .. (r.behemoth and (" · " .. r.behemoth) or ""), "" }
	table.insert(lineas, ("Tiempo: %d:%02d"):format(r.tiempo // 60, math.floor(r.tiempo % 60)))
	table.insert(lineas, "Partes rotas: " .. (#r.partes > 0 and table.concat(r.partes, ", ") or "ninguna"))
	table.insert(lineas, ("Derribos: %d   ·   Desmayos: %d"):format(r.derribos, r.desmayos))
	if #r.recompensas > 0 then
		table.insert(lineas, "")
		table.insert(lineas, "Recompensas:")
		for _, x in r.recompensas do
			table.insert(lineas, "  " .. x)
		end
	end
	if not r.exito then
		table.insert(lineas, "")
		table.insert(lineas, (r.behemoth or "El Behemoth") .. " se recupera. Descansen en la fogata e inténtenlo de nuevo.")
	end
	el.resultado.Text = table.concat(lineas, "\n")
	el.panel.Visible = true
	if alMenu then
		alMenu(true)
	end
	game:GetService("GuiService").SelectedObject = el.boton
end

function Hud.resultadosAbiertos(): boolean
	return el.panel ~= nil and el.panel.Visible
end

function Hud.cerrarResultados()
	el.panel.Visible = false
	game:GetService("GuiService").SelectedObject = nil
	if alMenu then
		alMenu(false)
	end
end

return Hud
