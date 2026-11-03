--!nonstrict
-- Achica las ventanas grandes para que quepan en pantallas pequeñas (celulares y tablets).
local UserInputService = game:GetService("UserInputService")
local Escala = {}

-- ¿se está jugando con pantalla táctil (sin teclado)?
function Escala.tactil(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Ajusta un marco de ancho x alto (en píxeles) para que quepa en la pantalla, con margen.
function Escala.ajustar(marco: GuiObject, ancho: number, alto: number, margen: number?)
	local escala = marco:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	escala.Parent = marco
	local camara = workspace.CurrentCamera
	local function actualizar()
		local pantalla = camara.ViewportSize
		local m = margen or 24
		escala.Scale = math.min(1, (pantalla.X - m) / ancho, (pantalla.Y - m) / alto)
	end
	camara:GetPropertyChangedSignal("ViewportSize"):Connect(actualizar)
	actualizar()
end

return Escala
