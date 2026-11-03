--!nonstrict
-- Opciones del creador de personaje. Todos los cazadores tienen el mismo cuerpo de bloques.
local Apariencia = {}

local rgb = Color3.fromRGB
Apariencia.PIELES = { rgb(255, 224, 196), rgb(240, 200, 160), rgb(224, 172, 126), rgb(198, 140, 96), rgb(160, 104, 66), rgb(122, 78, 50), rgb(90, 58, 40), rgb(64, 42, 30) }
Apariencia.COLORES_PELO = { rgb(30, 24, 22), rgb(74, 48, 32), rgb(128, 84, 48), rgb(230, 196, 110), rgb(186, 70, 40), rgb(236, 236, 236), rgb(47, 190, 180), rgb(130, 80, 180) }
Apariencia.COLORES_OJOS = { rgb(70, 45, 30), rgb(20, 20, 24), rgb(60, 150, 70), rgb(60, 110, 200), rgb(230, 160, 50), rgb(47, 200, 190) }
Apariencia.ROPAS = { rgb(236, 224, 196), rgb(190, 90, 60), rgb(40, 80, 140), rgb(110, 120, 60), rgb(120, 40, 50), rgb(214, 176, 110), rgb(100, 60, 140), rgb(40, 38, 42) }

Apariencia.OPCIONES = {
	{ clave = "pelo", nombre = "Pelo", etiquetas = { "Rapado", "Corto", "Flequillo", "Largo", "Coleta", "Trenzas", "Moño", "Cresta", "Rastas", "Melena", "Erizo", "Raya al lado", "Afro" } },
	{ clave = "colorPelo", nombre = "Color de pelo", n = #Apariencia.COLORES_PELO },
	{ clave = "piel", nombre = "Piel", n = #Apariencia.PIELES },
	{ clave = "ojos", nombre = "Ojos", etiquetas = { "Cuadrados", "Grandes", "Alargados", "Pestañas", "Felices" } },
	{ clave = "colorOjos", nombre = "Color de ojos", n = #Apariencia.COLORES_OJOS },
	{ clave = "boca", nombre = "Boca", etiquetas = { "Sonrisa", "Neutral", "Abierta", "Ladeada", "Seria" } },
	{ clave = "ropa", nombre = "Ropa", n = #Apariencia.ROPAS },
	{ clave = "extra", nombre = "Extra", etiquetas = { "Nada", "Pecas", "Pintura turquesa", "Cicatriz", "Marcas doradas" } },
}

function Apariencia.cantidad(op): number
	return op.etiquetas and #op.etiquetas or op.n
end

function Apariencia.texto(op, valor: number): string
	if op.etiquetas then
		return op.etiquetas[valor] or tostring(valor)
	end
	return tostring(valor)
end

function Apariencia.defecto()
	local t = {}
	for _, op in Apariencia.OPCIONES do
		t[op.clave] = 1
	end
	t.pelo = 2
	t.piel = 3
	return t
end

-- Deja solo valores válidos (lo que llega de una jugadora nunca se usa sin revisar).
function Apariencia.limpiar(t): { [string]: number }
	local limpio = Apariencia.defecto()
	if type(t) ~= "table" then
		return limpio
	end
	for _, op in Apariencia.OPCIONES do
		local v = tonumber(t[op.clave])
		if v then
			limpio[op.clave] = math.clamp(math.floor(v), 1, Apariencia.cantidad(op))
		end
	end
	return limpio
end

return Apariencia
