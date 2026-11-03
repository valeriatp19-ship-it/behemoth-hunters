--!nonstrict
-- Ambiente cinematográfico de cada lugar: luz, neblina, brillo (Bloom), rayos de sol y un filtro
-- de color. Lo arma cada jugador en su pantalla según dónde está, y cambia suavemente al viajar.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Ambiente = {}
local jugador = Players.LocalPlayer
local rgb = Color3.fromRGB

local AJUSTES = {
	refugio = {
		hora = 16.8, brillo = 2.4, ambiente = rgb(92, 72, 62), exterior = rgb(150, 122, 100),
		niebla = { densidad = 0.28, offset = 0.2, color = rgb(255, 200, 150), decay = rgb(180, 110, 90), glare = 0.4, haze = 1.2 },
		bloom = { intensidad = 0.8, tam = 30, umbral = 1.6 }, filtro = { brillo = 0.02, contraste = 0.12, saturacion = 0.15, tinte = rgb(255, 240, 226) },
		rayos = 0.08,
	},
	desierto = {
		hora = 14.5, brillo = 2.6, ambiente = rgb(82, 70, 60), exterior = rgb(142, 122, 100),
		niebla = { densidad = 0.24, offset = 0.15, color = rgb(240, 205, 160), decay = rgb(210, 150, 100), glare = 0.5, haze = 1.4 },
		bloom = { intensidad = 0.8, tam = 30, umbral = 1.5 }, filtro = { brillo = 0.01, contraste = 0.12, saturacion = 0.2, tinte = rgb(255, 238, 215) },
		rayos = 0.1,
	},
	guardian = {
		hora = 17.8, brillo = 2.3, ambiente = rgb(90, 60, 70), exterior = rgb(150, 100, 110),
		niebla = { densidad = 0.3, offset = 0.2, color = rgb(255, 150, 110), decay = rgb(150, 90, 170), glare = 1, haze = 2 },
		bloom = { intensidad = 1.0, tam = 34, umbral = 1.4 }, filtro = { brillo = 0, contraste = 0.16, saturacion = 0.25, tinte = rgb(255, 222, 222) },
		rayos = 0.14,
	},
	cumbres = {
		hora = 13, brillo = 2.2, ambiente = rgb(70, 78, 92), exterior = rgb(120, 132, 152),
		niebla = { densidad = 0.35, offset = 0.25, color = rgb(200, 215, 235), decay = rgb(120, 140, 170), glare = 0.2, haze = 2.2 },
		bloom = { intensidad = 0.7, tam = 28, umbral = 1.6 }, filtro = { brillo = 0, contraste = 0.1, saturacion = 0.05, tinte = rgb(232, 242, 255) },
		rayos = 0.12,
	},
}
-- Desierto de Brasa: cielo cargado de humo rojizo
AJUSTES.brasa = {
	hora = 17.2, brillo = 2.2, ambiente = rgb(96, 48, 36), exterior = rgb(150, 80, 60),
	niebla = { densidad = 0.38, offset = 0.2, color = rgb(200, 90, 50), decay = rgb(120, 40, 30), glare = 0.6, haze = 2.4 },
	bloom = { intensidad = 1.0, tam = 32, umbral = 1.4 }, filtro = { brillo = 0, contraste = 0.15, saturacion = 0.2, tinte = rgb(255, 214, 196) },
	rayos = 0.06,
}
-- Cuevas del Uku Pacha: noche con niebla morada
AJUSTES.cuevas = {
	hora = 21.5, brillo = 1.6, ambiente = rgb(70, 52, 96), exterior = rgb(96, 76, 130),
	niebla = { densidad = 0.42, offset = 0.15, color = rgb(120, 80, 170), decay = rgb(50, 30, 80), glare = 0.1, haze = 2.6 },
	bloom = { intensidad = 1.1, tam = 34, umbral = 1.3 }, filtro = { brillo = 0.02, contraste = 0.14, saturacion = 0.1, tinte = rgb(226, 214, 255) },
	rayos = 0.02,
}
-- Templo de Xibalbá: noche de luna verde-azulada sobre la selva, niebla baja
AJUSTES.xibalba = {
	hora = 22.5, brillo = 1.7, ambiente = rgb(58, 70, 88), exterior = rgb(84, 104, 128),
	niebla = { densidad = 0.4, offset = 0.12, color = rgb(70, 110, 120), decay = rgb(40, 50, 80), glare = 0.1, haze = 2.4 },
	bloom = { intensidad = 1.15, tam = 34, umbral = 1.25 }, filtro = { brillo = 0.03, contraste = 0.16, saturacion = 0.12, tinte = rgb(214, 236, 255) },
	rayos = 0.02,
}
-- la Noche de Xibalbá (fase 2 de Camazotz): el cielo se tiñe de rojo sangre
AJUSTES.nocheXibalba = {
	hora = 23.5, brillo = 1.5, ambiente = rgb(84, 40, 66), exterior = rgb(120, 56, 90),
	niebla = { densidad = 0.46, offset = 0.12, color = rgb(120, 40, 70), decay = rgb(60, 20, 50), glare = 0.2, haze = 2.8 },
	bloom = { intensidad = 1.3, tam = 36, umbral = 1.15 }, filtro = { brillo = 0.02, contraste = 0.2, saturacion = 0.2, tinte = rgb(255, 214, 230) },
	rayos = 0.02,
}
-- Cenote Sagrado: tarde de tormenta, nubes bajas y verde de selva húmeda
AJUSTES.cenote = {
	hora = 16.5, brillo = 1.9, ambiente = rgb(64, 82, 84), exterior = rgb(110, 134, 136),
	niebla = { densidad = 0.38, offset = 0.2, color = rgb(150, 180, 175), decay = rgb(70, 100, 110), glare = 0.2, haze = 2.2 },
	bloom = { intensidad = 0.9, tam = 30, umbral = 1.4 }, filtro = { brillo = 0.01, contraste = 0.12, saturacion = 0.15, tinte = rgb(228, 245, 245) },
	rayos = 0.08,
}
-- la Tormenta de Tláloc (fase 2 de Xolotl): cielo negro y relámpagos
AJUSTES.tormentaTlaloc = {
	hora = 19.2, brillo = 1.4, ambiente = rgb(52, 62, 84), exterior = rgb(80, 96, 130),
	niebla = { densidad = 0.48, offset = 0.15, color = rgb(80, 100, 130), decay = rgb(40, 50, 80), glare = 0.1, haze = 2.8 },
	bloom = { intensidad = 1.2, tam = 34, umbral = 1.2 }, filtro = { brillo = 0.02, contraste = 0.2, saturacion = 0.05, tinte = rgb(214, 228, 255) },
	rayos = 0.02,
}
-- Selva de Obsidiana: mañana de neblina dorada entre los árboles
AJUSTES.selva = {
	hora = 9.5, brillo = 2.2, ambiente = rgb(70, 84, 60), exterior = rgb(120, 140, 100),
	niebla = { densidad = 0.36, offset = 0.22, color = rgb(190, 210, 150), decay = rgb(90, 120, 70), glare = 0.4, haze = 2.0 },
	bloom = { intensidad = 0.85, tam = 30, umbral = 1.5 }, filtro = { brillo = 0.01, contraste = 0.12, saturacion = 0.22, tinte = rgb(240, 255, 225) },
	rayos = 0.16,
}
-- Pantanos de Aztlán: atardecer brumoso y verdoso
AJUSTES.pantano = {
	hora = 18.2, brillo = 1.8, ambiente = rgb(76, 80, 58), exterior = rgb(130, 128, 90),
	niebla = { densidad = 0.44, offset = 0.18, color = rgb(160, 160, 110), decay = rgb(90, 80, 60), glare = 0.5, haze = 2.6 },
	bloom = { intensidad = 0.95, tam = 32, umbral = 1.4 }, filtro = { brillo = 0, contraste = 0.14, saturacion = 0.12, tinte = rgb(250, 245, 215) },
	rayos = 0.06,
}
AJUSTES.probador = AJUSTES.refugio

local actual -- valores que se van acercando al ajuste del lugar
local efectos: { [string]: any } = {}

local function crear(clase: string, nombre: string)
	local e = Lighting:FindFirstChild(nombre) or Instance.new(clase)
	e.Name = nombre
	e.Parent = Lighting
	return e
end

local function ajusteDeAhora()
	local zona = jugador:GetAttribute("Zona") or "refugio"
	if zona == "desierto" and workspace:GetAttribute("CieloGuardian") then
		return AJUSTES.guardian
	end
	if zona == "xibalba" and workspace:GetAttribute("NocheXibalba") then
		return AJUSTES.nocheXibalba
	end
	if zona == "cenote" and workspace:GetAttribute("TormentaTlaloc") then
		return AJUSTES.tormentaTlaloc
	end
	return AJUSTES[zona] or AJUSTES.refugio
end

-- mezcla de dos valores (números o colores)
local function mezclar(a, b, k)
	if typeof(a) == "Color3" then
		return a:Lerp(b, k)
	end
	return a + (b - a) * k
end

local function mezclarTabla(a, b, k)
	local r = {}
	for clave, v in b do
		if type(v) == "table" then
			r[clave] = mezclarTabla(a[clave], v, k)
		else
			r[clave] = mezclar(a[clave], v, k)
		end
	end
	return r
end

local function aplicar(v)
	Lighting.ClockTime = v.hora
	Lighting.Brightness = v.brillo
	Lighting.Ambient = v.ambiente
	Lighting.OutdoorAmbient = v.exterior
	local n = efectos.niebla
	n.Density, n.Offset, n.Color, n.Decay, n.Glare, n.Haze = v.niebla.densidad, v.niebla.offset, v.niebla.color, v.niebla.decay, v.niebla.glare, v.niebla.haze
	local b = efectos.bloom
	b.Intensity, b.Size, b.Threshold = v.bloom.intensidad, v.bloom.tam, v.bloom.umbral
	local f = efectos.filtro
	f.Brightness, f.Contrast, f.Saturation, f.TintColor = v.filtro.brillo, v.filtro.contraste, v.filtro.saturacion, v.filtro.tinte
	efectos.rayos.Intensity = v.rayos
end

function Ambiente.iniciar()
	-- si el lugar trae su propia atmósfera, se reemplaza por la nuestra
	for _, x in Lighting:GetChildren() do
		if x:IsA("Atmosphere") and x.Name ~= "AmbienteNiebla" then
			x:Destroy()
		end
	end
	efectos.niebla = crear("Atmosphere", "AmbienteNiebla")
	efectos.bloom = crear("BloomEffect", "AmbienteBrillo")
	efectos.filtro = crear("ColorCorrectionEffect", "AmbienteFiltro")
	efectos.rayos = crear("SunRaysEffect", "AmbienteRayos")
	efectos.rayos.Spread = 0.6
	Lighting.GlobalShadows = true
	actual = ajusteDeAhora()
	aplicar(actual)
	RunService.RenderStepped:Connect(function(dt)
		local meta = ajusteDeAhora()
		actual = mezclarTabla(actual, meta, math.min(1, dt * 2)) -- ~1,5 s para cambiar
		aplicar(actual)
	end)
end

return Ambiente
