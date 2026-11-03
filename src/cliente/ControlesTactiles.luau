--!nonstrict
-- Botones en pantalla para celulares y tablets: ataque, fuerte, esquivar, poción, correr y menú.
-- El joystick para moverse, el botón de saltar y la cámara con el dedo ya los pone Roblox.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Escala = require(script.Parent.Escala)
local Config = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Config"))

local ControlesTactiles = {}
local jugador = Players.LocalPlayer

local ARENA = Color3.fromRGB(214, 180, 122)
local OSCURO = Color3.fromRGB(40, 28, 16)
local DORADO = Color3.fromRGB(255, 214, 120)

local function crear(clase, props, padre)
	local x = Instance.new(clase)
	for k, v in props do
		x[k] = v
	end
	x.Parent = padre
	return x
end

local function boton(padre, texto: string, tam: number, pos: UDim2, color: Color3?)
	local b = crear("TextButton", {
		Size = UDim2.fromOffset(tam, tam), Position = pos, AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color or ARENA, BackgroundTransparency = 0.15, BorderSizePixel = 0, AutoButtonColor = true,
		Text = texto, Font = Enum.Font.Arcade, TextSize = tam > 80 and 20 or 14, TextColor3 = OSCURO, TextWrapped = true,
	}, padre)
	crear("UIStroke", { Thickness = 3, Color = OSCURO, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	crear("Frame", { Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = DORADO, BorderSizePixel = 0 }, b)
	return b
end

-- acciones: { atacar = f, fuerte = f, esquivar = f, pocion = f, correr = f(activo), menu = f }
function ControlesTactiles.iniciar(acciones)
	if not Escala.tactil() then
		return
	end
	local gui = crear("ScreenGui", { Name = "ControlesTactiles", ResetOnSpawn = false, DisplayOrder = 3 }, jugador:WaitForChild("PlayerGui"))
	-- botones de caza, en arco sobre el botón de saltar de Roblox (abajo a la derecha)
	local caza = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)
	local ataque = boton(caza, "ATAQUE", 96, UDim2.new(1, -175, 1, -110), DORADO)
	local fuerte = boton(caza, "FUERTE", 66, UDim2.new(1, -285, 1, -80))
	local esquivar = boton(caza, "ESQUIVAR", 70, UDim2.new(1, -80, 1, -170))
	local pocion = boton(caza, "POCIÓN", 58, UDim2.new(1, -265, 1, -200), Color3.fromRGB(127, 220, 210))
	local correr = boton(caza, "CORRER", 58, UDim2.new(1, -380, 1, -50))
	ataque.Activated:Connect(acciones.atacar)
	fuerte.Activated:Connect(acciones.fuerte)
	esquivar.Activated:Connect(acciones.esquivar)
	pocion.Activated:Connect(acciones.pocion)
	local corriendo = false
	correr.Activated:Connect(function()
		corriendo = not corriendo
		correr.BackgroundColor3 = corriendo and DORADO or ARENA
		acciones.correr(corriendo)
	end)
	-- botón de menú arriba a la izquierda, junto a los botones de Roblox
	local menu = boton(gui, "MENÚ", 48, UDim2.new(0, 145, 0, 28))
	menu.Activated:Connect(acciones.menu)
	local function actualizar()
		local zona = jugador:GetAttribute("Zona")
		caza.Visible = zona ~= nil and Config.ISLAS[zona] ~= nil
		menu.Visible = zona ~= "probador" and zona ~= nil
	end
	jugador:GetAttributeChangedSignal("Zona"):Connect(actualizar)
	actualizar()
	function ControlesTactiles.mostrarCaza(visible: boolean)
		local zona = jugador:GetAttribute("Zona")
		caza.Visible = visible and zona ~= nil and Config.ISLAS[zona] ~= nil
	end
end

return ControlesTactiles
