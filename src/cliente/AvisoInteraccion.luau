--!nonstrict
-- El aviso para interactuar (hablar con alguien, volver en la caravana...) con el estilo del juego:
-- un cartel de pergamino con letra pixelada, la tecla en un bloque dorado y una pequeña animación.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Escala = require(script.Parent.Escala)

local AvisoInteraccion = {}
local jugador = Players.LocalPlayer

local ARENA = Color3.fromRGB(214, 180, 122)
local ARENA_CLARA = Color3.fromRGB(236, 208, 150)
local OSCURO = Color3.fromRGB(40, 28, 16)
local DORADO = Color3.fromRGB(255, 214, 120)
local TEXTO = Color3.fromRGB(255, 246, 222)

-- nombre corto de cada botón del mando
local BOTONES = {
	[Enum.KeyCode.ButtonX] = "X", [Enum.KeyCode.ButtonY] = "Y", [Enum.KeyCode.ButtonA] = "A", [Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonL1] = "LB", [Enum.KeyCode.ButtonR1] = "RB", [Enum.KeyCode.ButtonL2] = "LT", [Enum.KeyCode.ButtonR2] = "RT",
	[Enum.KeyCode.DPadUp] = "↑", [Enum.KeyCode.DPadDown] = "↓", [Enum.KeyCode.DPadLeft] = "←", [Enum.KeyCode.DPadRight] = "→",
}

local function crear(clase, props, padre)
	local x = Instance.new(clase)
	for k, v in props do
		x[k] = v
	end
	x.Parent = padre
	return x
end

local function texto(props, padre)
	local base = { BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextColor3 = TEXTO, TextStrokeTransparency = 0, TextStrokeColor3 = OSCURO, TextXAlignment = Enum.TextXAlignment.Left }
	for k, v in props do
		base[k] = v
	end
	return crear("TextLabel", base, padre)
end

local function nombreTecla(prompt: ProximityPrompt, tipo: Enum.ProximityPromptInputType): string
	if tipo == Enum.ProximityPromptInputType.Gamepad then
		return BOTONES[prompt.GamepadKeyCode] or prompt.GamepadKeyCode.Name
	elseif tipo == Enum.ProximityPromptInputType.Touch then
		return "Tocar"
	end
	return prompt.KeyboardKeyCode.Name
end

local function mostrar(prompt: ProximityPrompt, tipo: Enum.ProximityPromptInputType, pantalla: ScreenGui)
	local adorno = prompt.Parent
	if not (adorno and adorno:IsA("BasePart")) then
		adorno = prompt:FindFirstAncestorWhichIsA("BasePart")
	end
	local cartel = crear("BillboardGui", {
		Name = "AvisoBonito", Adornee = adorno, AlwaysOnTop = true, Size = UDim2.fromOffset(280, 96),
		StudsOffset = Vector3.new(0, 4, 0), LightInfluence = 0, ResetOnSpawn = false, Active = true,
	}, pantalla)
	-- en pantallas táctiles, además, un botón grande abajo (más fácil de tocar que el cartel)
	local botonTactil
	if tipo == Enum.ProximityPromptInputType.Touch or Escala.tactil() then
		botonTactil = crear("TextButton", {
			Size = UDim2.fromOffset(240, 66), Position = UDim2.new(0.5, -120, 1, -170), BackgroundColor3 = DORADO, BorderSizePixel = 0,
			Text = string.upper(prompt.ActionText) .. (prompt.ObjectText ~= "" and ("\n" .. prompt.ObjectText) or ""),
			Font = Enum.Font.Arcade, TextSize = 20, TextColor3 = OSCURO, AutoButtonColor = true,
		}, pantalla)
		crear("UIStroke", { Thickness = 3, Color = OSCURO, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, botonTactil)
		botonTactil.Activated:Connect(function()
			prompt:InputHoldBegin()
			task.delay(prompt.HoldDuration + 0.05, function()
				prompt:InputHoldEnd()
			end)
		end)
	end
	local escala = crear("UIScale", { Scale = 0.5 }, cartel)
	local cuerpo = crear("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = ARENA, BorderSizePixel = 0 }, cartel)
	crear("UIStroke", { Thickness = 3, Color = OSCURO, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, cuerpo)
	-- franja dorada arriba y pequeñas "esquinas" pixeladas
	crear("Frame", { Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = DORADO, BorderSizePixel = 0 }, cuerpo)
	for _, pos in { UDim2.new(0, 4, 1, -10), UDim2.new(1, -10, 1, -10) } do
		crear("Frame", { Size = UDim2.fromOffset(6, 6), Position = pos, BackgroundColor3 = ARENA_CLARA, BorderSizePixel = 0 }, cuerpo)
	end
	-- la tecla en un bloque dorado
	local tecla = crear("Frame", { Size = UDim2.fromOffset(58, 58), Position = UDim2.fromOffset(14, 22), BackgroundColor3 = DORADO, BorderSizePixel = 0 }, cuerpo)
	crear("UIStroke", { Thickness = 3, Color = OSCURO }, tecla)
	crear("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = Color3.fromRGB(200, 150, 70), BorderSizePixel = 0 }, tecla)
	local nombre = nombreTecla(prompt, tipo)
	texto({ Size = UDim2.fromScale(1, 1), Text = nombre, TextSize = #nombre > 2 and 16 or 28, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = OSCURO, TextStrokeTransparency = 1 }, tecla)
	-- quién o qué, y la acción
	texto({ Size = UDim2.new(1, -96, 0, 22), Position = UDim2.fromOffset(86, 20), Text = prompt.ObjectText, TextSize = 16, TextColor3 = DORADO }, cuerpo)
	texto({ Size = UDim2.new(1, -96, 0, 34), Position = UDim2.fromOffset(86, 44), Text = prompt.ActionText, TextSize = 24 }, cuerpo)
	-- barra por si hay que mantener pulsado
	local fondoBarra = crear("Frame", { Size = UDim2.new(1, -28, 0, 5), Position = UDim2.new(0, 14, 1, -9), BackgroundColor3 = OSCURO, BorderSizePixel = 0, Visible = prompt.HoldDuration > 0 }, cuerpo)
	local barra = crear("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(127, 255, 244), BorderSizePixel = 0 }, fondoBarra)
	-- en pantallas táctiles se puede tocar el cartel
	cuerpo.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end)
	cuerpo.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end)
	-- aparece con un rebote y flota suavemente
	TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local inicio = os.clock()
	local flotar = RunService.RenderStepped:Connect(function()
		cartel.StudsOffset = Vector3.new(0, 4 + math.sin((os.clock() - inicio) * 2.5) * 0.15, 0)
	end)
	local conexiones = { flotar }
	table.insert(conexiones, prompt.PromptButtonHoldBegan:Connect(function()
		barra.Size = UDim2.fromScale(0, 1)
		TweenService:Create(barra, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) }):Play()
	end))
	table.insert(conexiones, prompt.PromptButtonHoldEnded:Connect(function()
		barra.Size = UDim2.fromScale(0, 1)
	end))
	table.insert(conexiones, prompt.Triggered:Connect(function()
		-- destello al pulsar
		cuerpo.BackgroundColor3 = ARENA_CLARA
		escala.Scale = 1.12
		TweenService:Create(escala, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
		TweenService:Create(cuerpo, TweenInfo.new(0.3), { BackgroundColor3 = ARENA }):Play()
	end))
	local cerrar
	cerrar = prompt.PromptHidden:Connect(function()
		cerrar:Disconnect()
		if botonTactil then
			botonTactil:Destroy()
		end
		for _, c in conexiones do
			c:Disconnect()
		end
		local salida = TweenService:Create(escala, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.3 })
		salida:Play()
		salida.Completed:Connect(function()
			cartel:Destroy()
		end)
	end)
end

function AvisoInteraccion.iniciar()
	local pantalla = crear("ScreenGui", { Name = "AvisosInteraccion", ResetOnSpawn = false }, jugador:WaitForChild("PlayerGui"))
	-- todos los avisos del juego usan el diseño propio
	local function preparar(x: Instance)
		if x:IsA("ProximityPrompt") then
			x.Style = Enum.ProximityPromptStyle.Custom
		end
	end
	for _, x in workspace:GetDescendants() do
		preparar(x)
	end
	workspace.DescendantAdded:Connect(preparar)
	ProximityPromptService.PromptShown:Connect(function(prompt, tipo)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			mostrar(prompt, tipo, pantalla)
		end
	end)
end

return AvisoInteraccion
