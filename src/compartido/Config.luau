--!nonstrict
-- Medidas y lugares del Mar de Dunas. El juego de Godot usaba metros; aquí 1 metro = 3 studs.
local Config = {}

Config.S = 3
Config.VOX = 4 -- tamaño de cada bloque del mundo, en studs
Config.OASIS = Vector2.new(48, 22)
Config.OASIS_RADIO = 13
Config.CAMPAMENTO = Vector2.new(0, 74)
Config.RADIO_CAMPAMENTO = 18
Config.PIRAMIDES = {
	{ x = -75, z = -70, tam = 34 },
	{ x = -22, z = -108, tam = 24 },
	{ x = 82, z = -86, tam = 20 },
}
Config.OBELISCOS = { { -14, -18, 12 }, { 14, -20, 12 }, { -42, 34, 9 }, { 30, -50, 10 } }

Config.COLORES = {
	arena = Color3.fromRGB(226, 182, 118),
	piedra = Color3.fromRGB(214, 178, 122),
	oro = Color3.fromRGB(230, 176, 74),
	turquesa = Color3.fromRGB(47, 190, 180),
	lino = Color3.fromRGB(236, 224, 196),
	rojo = Color3.fromRGB(196, 58, 46),
	cuero = Color3.fromRGB(110, 70, 40),
	azul = Color3.fromRGB(31, 58, 110),
}

local function suave(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

-- Altura del terreno en metros (la misma fórmula del juego de Godot).
function Config.alturaM(x: number, z: number): number
	local h = math.sin(x * 0.028 + 1.3) * 2.4 + math.cos(z * 0.024) * 2.1 + math.sin((x + z) * 0.055) * 0.9 + math.sin(x * 0.12 - z * 0.09) * 0.3
	local d = math.sqrt(x * x + z * z)
	h *= 0.55 + 0.45 * suave(40, 120, d)
	local dOasis = (Vector2.new(x, z) - Config.OASIS).Magnitude
	local k = 1 - suave(Config.OASIS_RADIO - 3, Config.OASIS_RADIO + 10, dOasis)
	h = h + (-1.2 - h) * k
	local dCamp = (Vector2.new(x, z) - Config.CAMPAMENTO).Magnitude
	k = 1 - suave(6, 16, dCamp)
	h = h + (0.4 - h) * k
	h += math.max(0, d - 132) * 0.4
	return h
end

-- Altura del bloque de arena que hay en esa posición (studs), redondeada a bloques.
function Config.altura(x: number, z: number): number
	local V = Config.VOX
	local cx = math.floor(x / V) * V + V / 2
	local cz = math.floor(z / V) * V + V / 2
	local h = Config.alturaM(cx / Config.S, cz / Config.S) * Config.S
	return math.floor(h / V + 0.5) * V
end

-- Punto sobre la arena, a partir de metros.
function Config.suelo(xm: number, zm: number, sobre: number?): Vector3
	local S = Config.S
	return Vector3.new(xm * S, Config.altura(xm * S, zm * S) + (sobre or 0), zm * S)
end

-- ---------- Cumbres del Inti (un mapa aparte, lejos del Mar de Dunas) ----------
Config.CUMBRES = Vector3.new(4000, 0, 0) -- centro del mapa, en studs
Config.CUMBRES_CAMPAMENTO = Vector2.new(0, 92) -- en metros, relativo al centro
Config.VOX_CUMBRES = 6

-- Terrazas escalonadas en el valle y montañas alrededor (metros, relativo al centro).
function Config.alturaCumbresM(x: number, z: number): number
	local d = math.sqrt(x * x + z * z)
	local ondas = math.sin(x * 0.035) * 3 + math.cos(z * 0.03) * 3 + math.sin((x - z) * 0.02) * 2
	local terraza = math.floor((ondas + 8) / 2.2) * 2.2 -- escalones de cultivo
	local h = terraza * (0.4 + 0.6 * suave(30, 90, d))
	h += math.min(60, math.max(0, d - 105) ^ 1.25 * 0.9) -- montañas que rodean el valle
	local dCamp = (Vector2.new(x, z) - Config.CUMBRES_CAMPAMENTO).Magnitude
	local k = 1 - suave(8, 18, dCamp)
	h = h + (4 - h) * k
	return h
end

-- Altura del bloque en una posición del mundo (studs), para una isla de montaña con ese centro.
function Config.alturaMontana(centro: Vector3, x: number, z: number): number
	local V = Config.VOX_CUMBRES
	local lx, lz = x - centro.X, z - centro.Z
	local cx = math.floor(lx / V) * V + V / 2
	local cz = math.floor(lz / V) * V + V / 2
	local h = Config.alturaCumbresM(cx / Config.S, cz / Config.S) * Config.S
	return math.floor(h / V + 0.5) * V
end

function Config.alturaCumbres(x: number, z: number): number
	return Config.alturaMontana(Config.CUMBRES, x, z)
end

function Config.sueloMontana(centro: Vector3, xm: number, zm: number, sobre: number?): Vector3
	local S = Config.S
	local x, z = centro.X + xm * S, centro.Z + zm * S
	return Vector3.new(x, Config.alturaMontana(centro, x, z) + (sobre or 0), z)
end

function Config.sueloCumbres(xm: number, zm: number, sobre: number?): Vector3
	return Config.sueloMontana(Config.CUMBRES, xm, zm, sobre)
end

-- ---------- las islas de caza: una por Behemoth ----------
-- centro (studs), tipo de terreno y campamento (metros, relativo al centro)
Config.CUEVAS = Vector3.new(4000, 0, 4000)
Config.BRASA = Vector3.new(-4000, 0, 0)
Config.ISLAS = {
	desierto = { centro = Vector3.new(0, 0, 0), tipo = "dunas", campamento = Vector2.new(0, 74) },
	brasa = { centro = Config.BRASA, tipo = "dunas", campamento = Vector2.new(0, 74) },
	cumbres = { centro = Config.CUMBRES, tipo = "montana", campamento = Vector2.new(0, 92) },
	cuevas = { centro = Config.CUEVAS, tipo = "montana", campamento = Vector2.new(0, 92) },
	-- la Selva de Obsidiana: cuatro islas mayas y mexicas (agua = nivel del agua en metros, si hay)
	xibalba = { centro = Vector3.new(-4000, 0, 4000), tipo = "selva", variante = "xibalba", campamento = Vector2.new(0, 92) },
	cenote = { centro = Vector3.new(0, 0, 4000), tipo = "selva", variante = "cenote", campamento = Vector2.new(0, 92), agua = -0.6 },
	selva = { centro = Vector3.new(0, 0, -4000), tipo = "selva", variante = "jungla", campamento = Vector2.new(0, 92) },
	pantano = { centro = Vector3.new(-4000, 0, -4000), tipo = "selva", variante = "pantano", campamento = Vector2.new(0, 92), agua = -0.4 },
}

-- ---------- terreno de la selva (metros, relativo al centro de la isla) ----------
-- xibalba: plaza del templo al centro y colinas · cenote: un gran cenote al centro con su borde
-- jungla: colinas onduladas con claros · pantano: llano bajo con canales de agua
Config.CENOTE = { centro = Vector2.new(0, -10), radio = 24 }
function Config.alturaSelvaM(variante: string, x: number, z: number): number
	local d = math.sqrt(x * x + z * z)
	local ondas = math.sin(x * 0.045 + 0.7) * 2.2 + math.cos(z * 0.038) * 2.0 + math.sin((x + z) * 0.07) * 0.5
	local h
	if variante == "xibalba" then
		h = ondas * 0.9 * suave(26, 50, d) -- la plaza del templo es plana
	elseif variante == "cenote" then
		local dc = (Vector2.new(x, z) - Config.CENOTE.centro).Magnitude
		h = ondas * 0.6 + 1.0 -- (más alto que el agua: solo el cenote se llena)
		h += 2.2 * (1 - suave(Config.CENOTE.radio + 2, Config.CENOTE.radio + 12, dc)) -- el borde del cenote, un poco alto
		local dentro = 1 - suave(Config.CENOTE.radio - 4, Config.CENOTE.radio, dc)
		h = h + (-1.8 - h) * dentro -- el fondo del cenote (poco profundo: se puede pelear dentro)
	elseif variante == "pantano" then
		local canal = math.abs(math.sin(x * 0.05 + math.sin(z * 0.03) * 1.6))
		h = ondas * 0.35 + 0.6
		h -= 2.2 * (1 - suave(0.12, 0.4, canal)) -- canales de agua que cruzan el pantano
	else
		h = ondas * 1.3 + math.sin(x * 0.11 - z * 0.08) * 0.6
	end
	h += math.min(55, math.max(0, d - 108) ^ 1.25 * 0.9) -- montañas de selva que rodean la isla
	local dCamp = (Vector2.new(x, z) - Vector2.new(0, 92)).Magnitude
	local k = 1 - suave(8, 18, dCamp)
	h = h + (1 - h) * k
	return h
end

-- Altura del bloque (studs) en una isla de selva.
function Config.alturaSelva(isla, x: number, z: number): number
	local V = Config.VOX
	local lx, lz = x - isla.centro.X, z - isla.centro.Z
	local cx = math.floor(lx / V) * V + V / 2
	local cz = math.floor(lz / V) * V + V / 2
	local h = Config.alturaSelvaM(isla.variante, cx / Config.S, cz / Config.S) * Config.S
	-- las montañas del borde van en escalones dobles (menos piezas, mismo aspecto)
	local q = h > 14 * Config.S and V * 2 or V
	return math.floor(h / q + 0.5) * q
end

function Config.sueloIsla(nombre: string, xm: number, zm: number, sobre: number?): Vector3
	local isla = Config.ISLAS[nombre]
	local x, z = isla.centro.X + xm * Config.S, isla.centro.Z + zm * Config.S
	return Vector3.new(x, Config.alturaEn(x, z) + (sobre or 0), z)
end

-- agujas de obsidiana del Desierto de Brasa: { x, z, radio } en metros, relativo al centro
Config.OBSTACULOS_BRASA = { { -30, -20, 4 }, { 25, -45, 5 }, { 52, 22, 4 }, { -55, 40, 5 }, { 12, 58, 3 }, { -70, -60, 5 }, { 80, -70, 4 }, { -95, -10, 4 } }

-- ¿en qué isla está este punto? (la de centro más cercano)
function Config.islaEn(x: number, z: number): string
	local mejor, mejorD = "desierto", math.huge
	for nombre, isla in Config.ISLAS do
		local d = (Vector2.new(x, z) - Vector2.new(isla.centro.X, isla.centro.Z)).Magnitude
		if d < mejorD then
			mejor, mejorD = nombre, d
		end
	end
	return mejor
end

-- Altura del suelo en cualquier punto, sea cual sea la isla.
function Config.alturaEn(x: number, z: number): number
	local isla = Config.ISLAS[Config.islaEn(x, z)]
	if isla.tipo == "montana" then
		return Config.alturaMontana(isla.centro, x, z)
	elseif isla.tipo == "selva" then
		return Config.alturaSelva(isla, x, z)
	end
	return Config.altura(x - isla.centro.X, z - isla.centro.Z) + isla.centro.Y
end

function Config.enCampamento(pos: Vector3): boolean
	for _, isla in Config.ISLAS do
		local c2 = Vector2.new(isla.centro.X, isla.centro.Z) + isla.campamento * Config.S
		if (Vector2.new(pos.X, pos.Z) - c2).Magnitude < Config.RADIO_CAMPAMENTO * Config.S then
			return true
		end
	end
	return false
end

function Config._enCampamentoDunas(pos: Vector3): boolean
	local c = Config.CAMPAMENTO * Config.S
	return (Vector2.new(pos.X, pos.Z) - c).Magnitude < Config.RADIO_CAMPAMENTO * Config.S
end

return Config
