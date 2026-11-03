--!nonstrict
-- Creador de personaje: filas con flechas para elegir pelo, piel, ojos, boca, ropa y extras.
-- Mando: cruceta ↑↓ elige fila, ←→ cambia · LB/RB giran la cámara · A (en "¡A CAZAR!") termina.
-- Teclado: flechas o WASD · Q/E giran la cámara · Enter termina. También funciona con el ratón.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Compartido = ReplicatedStorage:WaitForChild("Compartido")
local Apariencia = require(Compartido.Apariencia)
local Remotos = require(Compartido.Remotos)
local Escala = require(script.Parent.Escala)

local Probador = {}
local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera
local gui: ScreenGui
local filas = {}
local actual = {}
local seleccion = 1
local angulo = 0
local abierto = false
local alCerrar
local conexionCamara
local botonTerminar: TextButton

local ARENA = Color3.fromRGB(196, 160, 104)
local TEXTO = Color3.fromRGB(255, 244, 214)

local function crear(clase, props, padre)
	local x = Instance.new(clase)
	for k, v in props do
		x[k] = v
	end
	x.Parent = padre
	return x
end

local function marco(props, padre)
	local f = crear("Frame", props, padre)
	f.BackgroundColor3 = props.BackgroundColor3 or ARENA
	f.BorderSizePixel = 0
	crear("UIStroke", { Thickness = 3, Color = Color3.fromRGB(40, 28, 16) }, f)
	return f
end

local function etiqueta(props, padre)
	local base = { BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextColor3 = TEXTO, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(40, 28, 16), TextSize = 22 }
	for k, v in props do
		base[k] = v
	end
	return crear("TextLabel", base, padre)
end

local function boton(texto, props, padre)
	local b = crear("TextButton", {
		BackgroundTransparency = 1, Text = texto, Font = Enum.Font.Arcade, TextSize = 26,
		TextColor3 = TEXTO, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(40, 28, 16), AutoButtonColor = false,
	}, padre)
	for k, v in props do
		b[k] = v
	end
	return b
end

local function refrescar()
	for i, f in filas do
		local op = Apariencia.OPCIONES[i]
		f.texto.Text = op.nombre .. ": " .. Apariencia.texto(op, actual[op.clave])
		f.marco.BackgroundColor3 = (i == seleccion) and Color3.fromRGB(230, 190, 120) or ARENA
	end
	botonTerminar.TextColor3 = (seleccion == #filas + 1) and Color3.fromRGB(127, 255, 244) or Color3.fromRGB(120, 255, 120)
end

local function cambiar(i: number, paso: number)
	local op = Apariencia.OPCIONES[i]
	if not op then
		return
	end
	local n = Apariencia.cantidad(op)
	actual[op.clave] = (actual[op.clave] - 1 + paso) % n + 1
	refrescar()
	Remotos.Apariencia:FireServer(actual)
end

local function construir()
	gui = crear("ScreenGui", { Name = "Probador", ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false }, jugador:WaitForChild("PlayerGui"))
	-- título
	etiqueta({ Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 24), Text = "CREA TU CAZADOR", TextSize = 38, TextColor3 = Color3.fromRGB(255, 214, 120) }, gui)
	-- panel izquierdo
	local izq = marco({ Size = UDim2.fromOffset(260, 300), Position = UDim2.new(0, 40, 0.5, -150) }, gui)
	if Escala.tactil() then
		izq.Visible = false -- en celular solo cabe lo esencial
	end
	etiqueta({ Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 8), Text = "MAR DE DUNAS", TextColor3 = Color3.fromRGB(255, 230, 120) }, izq)
	etiqueta({
		Size = UDim2.new(1, -24, 0, 150), Position = UDim2.fromOffset(12, 42), TextWrapped = true, TextSize = 15, TextYAlignment = Enum.TextYAlignment.Top,
		Text = "Los cazadores del Refugio de Qamar recorren las dunas persiguiendo a los Behemoths. Elige cómo se verá el tuyo: el atuendo nómada irá encima.",
	}, izq)
	etiqueta({ Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 196), Text = "CONTROLES", TextColor3 = Color3.fromRGB(127, 255, 244), TextSize = 18 }, izq)
	etiqueta({
		Size = UDim2.new(1, -24, 0, 70), Position = UDim2.fromOffset(12, 222), TextWrapped = true, TextSize = 13, TextYAlignment = Enum.TextYAlignment.Top,
		Text = "Cruceta o flechas: elegir y cambiar\nLB/RB o Q/E: girar\nA o Enter: ¡a cazar!",
	}, izq)
	-- filas de opciones (derecha)
	local altoFilas = #Apariencia.OPCIONES * 52
	local derecha = crear("Frame", { Size = UDim2.fromOffset(330, altoFilas), Position = UDim2.new(1, -20, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 1 }, gui)
	Escala.ajustar(derecha, 330, altoFilas, 140)
	for i, op in Apariencia.OPCIONES do
		local f = marco({ Size = UDim2.fromOffset(330, 46), Position = UDim2.fromOffset(0, (i - 1) * 52) }, derecha)
		local menos = boton("<", { Size = UDim2.fromOffset(36, 46), Position = UDim2.fromOffset(4, 0) }, f)
		local mas = boton(">", { Size = UDim2.fromOffset(36, 46), Position = UDim2.new(1, -40, 0, 0) }, f)
		local texto = etiqueta({ Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(40, 0), TextSize = 20 }, f)
		menos.Activated:Connect(function()
			seleccion = i
			cambiar(i, -1)
		end)
		mas.Activated:Connect(function()
			seleccion = i
			cambiar(i, 1)
		end)
		filas[i] = { marco = f, texto = texto }
	end
	-- flechas para girar y botón para terminar
	local girarIzq = boton("<", { Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0.5, -170, 0.5, -30), TextSize = 44 }, gui)
	local girarDer = boton(">", { Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0.5, 110, 0.5, -30), TextSize = 44 }, gui)
	girarIzq.Activated:Connect(function()
		angulo -= math.rad(30)
	end)
	girarDer.Activated:Connect(function()
		angulo += math.rad(30)
	end)
	local terminar = boton("[ ¡A CAZAR! ]", { Name = "Terminar", Size = UDim2.fromOffset(320, 50), Position = UDim2.new(0.5, -160, 1, -90), TextSize = 32, TextColor3 = Color3.fromRGB(120, 255, 120) }, gui)
	botonTerminar = terminar
	terminar.Activated:Connect(function()
		Probador.cerrar()
	end)
end

local function controles(activar: boolean)
	if not activar then
		ContextActionService:UnbindAction("ProbadorNavegar")
		return
	end
	ContextActionService:BindActionAtPriority("ProbadorNavegar", function(_, estadoInput, input)
		if estadoInput ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		local k = input.KeyCode
		if k == Enum.KeyCode.DPadUp or k == Enum.KeyCode.Up or k == Enum.KeyCode.W then
			seleccion = math.max(1, seleccion - 1)
			refrescar()
		elseif k == Enum.KeyCode.DPadDown or k == Enum.KeyCode.Down or k == Enum.KeyCode.S then
			seleccion = math.min(#filas + 1, seleccion + 1)
			refrescar()
		elseif k == Enum.KeyCode.DPadLeft or k == Enum.KeyCode.Left or k == Enum.KeyCode.A then
			cambiar(seleccion, -1)
		elseif k == Enum.KeyCode.DPadRight or k == Enum.KeyCode.Right or k == Enum.KeyCode.D then
			cambiar(seleccion, 1)
		elseif k == Enum.KeyCode.ButtonL1 or k == Enum.KeyCode.Q then
			angulo -= math.rad(30)
		elseif k == Enum.KeyCode.ButtonR1 or k == Enum.KeyCode.E then
			angulo += math.rad(30)
		elseif k == Enum.KeyCode.Return or (k == Enum.KeyCode.ButtonA and seleccion == #filas + 1) then
			Probador.cerrar()
		elseif k == Enum.KeyCode.ButtonA then
			seleccion = #filas + 1
			refrescar()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 10,
		Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight,
		Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
		Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.A, Enum.KeyCode.D,
		Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1, Enum.KeyCode.Q, Enum.KeyCode.E,
		Enum.KeyCode.Return, Enum.KeyCode.ButtonA, Enum.KeyCode.Space)
end

function Probador.abrir(ap)
	actual = Apariencia.limpiar(ap)
	seleccion = 1
	angulo = 0
	abierto = true
	gui.Enabled = true
	refrescar()
	controles(true)
	camara.CameraType = Enum.CameraType.Scriptable
	if conexionCamara then
		conexionCamara:Disconnect()
	end
	-- la cámara gira alrededor de el cazador, que mira de frente
	local suave = 0
	conexionCamara = RunService.RenderStepped:Connect(function(dt)
		local char = jugador.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		suave += (angulo - suave) * math.min(1, dt * 8)
		local centro = hrp.Position + Vector3.new(0, 0.6, 0)
		local frente = (hrp.CFrame * CFrame.Angles(0, suave, 0)).LookVector
		camara.CFrame = CFrame.lookAt(centro + frente * 11 + Vector3.new(0, 1.5, 0), centro)
	end)
end

function Probador.cerrar()
	if not abierto then
		return
	end
	abierto = false
	gui.Enabled = false
	controles(false)
	if conexionCamara then
		conexionCamara:Disconnect()
		conexionCamara = nil
	end
	Remotos.Apariencia:FireServer(actual)
	Remotos.Listo:FireServer()
	camara.CameraType = Enum.CameraType.Custom
	local char = jugador.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		camara.CameraSubject = hum
	end
	if alCerrar then
		alCerrar()
	end
end

function Probador.iniciar(alAbrir, cerrado)
	alCerrar = cerrado
	construir()
	Remotos.AbrirProbador.OnClientEvent:Connect(function(ap)
		alAbrir()
		Probador.abrir(ap)
	end)
end

return Probador
