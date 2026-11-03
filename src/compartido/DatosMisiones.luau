--!nonstrict
-- Misiones de la historia (Imani) y encargos repetibles (Sefu).
-- Cada una se cumple al terminar una cacería que cumpla sus condiciones:
--   behemoth, isla, exito, minPartes (partes rotas), parte (una en particular),
--   maxDesmayos, maxTiempo (segundos) y minDerribos.
local DatosMisiones = {}

DatosMisiones.HISTORIA = {
	{ titulo = "El León de las Dunas", texto = "Sekhmaur ronda las pirámides del Mar de Dunas. Demuéstrame que puedes cazarlo.",
		objetivo = "Caza a Sekhmaur", cond = { behemoth = "Sekhmaur", exito = true },
		premio = { monedas = 300, escama = 4, xp = 100 } },
	{ titulo = "La Melena de Arena", texto = "Dicen que al romperle la melena despierta el guardián que lleva dentro. Averígualo.",
		objetivo = "Rompe la melena de Sekhmaur", cond = { behemoth = "Sekhmaur", parte = "Melena de arena" },
		premio = { monedas = 300, arena = 2, xp = 120 } },
	{ titulo = "El Rodador Solar", texto = "Un escarabajo colosal empuja el sol por las dunas. Cuidado con su bola de fuego.",
		objetivo = "Caza a Kheprak", cond = { behemoth = "Kheprak", exito = true },
		premio = { monedas = 400, elitro = 1, quitina = 1, xp = 150 } },
	{ titulo = "El Escarabajo en el Suelo", texto = "Rompe su bola solar o golpéale las patas: un Kheprak boca arriba es un Kheprak vencido.",
		objetivo = "Derriba a Kheprak 2 veces en una cacería", cond = { behemoth = "Kheprak", minDerribos = 2 },
		premio = { monedas = 400, cuerno = 2, xp = 150 } },
	{ titulo = "Viaje al Uku Pacha", texto = "Tariq abrió la ruta a las Cuevas del Uku Pacha. Ahí vive una serpiente de sombra.",
		objetivo = "Caza a Amaru", cond = { behemoth = "Amaru", exito = true },
		premio = { monedas = 500, sombra = 4, xp = 200 } },
	{ titulo = "El Guardián de la Montaña", texto = "La montaña tiembla. Un gorila de piedra con el sol en el pecho protege las terrazas.",
		objetivo = "Caza a Apu Rumi", cond = { behemoth = "Apu Rumi", exito = true },
		premio = { monedas = 600, piedra_inti = 4, disco_solar = 1, xp = 250 } },
	{ titulo = "Leyenda de las Islas", texto = "Los grandes cazadores no solo vencen: se llevan todo. Rompe cada parte de un Behemoth de las Cumbres.",
		objetivo = "Caza a Amaru o Apu Rumi rompiendo sus 3 partes", cond = { behemoths = { "Amaru", "Apu Rumi" }, exito = true, minPartes = 3 },
		premio = { monedas = 1000, nucleo = 3, xp = 400 } },
	{ titulo = "El Murciélago de Xibalbá", texto = "Tariq abrió la ruta a la Selva de Obsidiana. En el Templo de Xibalbá algo grita en la noche: Camazotz, el murciélago de la muerte.",
		objetivo = "Caza a Camazotz", cond = { behemoth = "Camazotz", exito = true },
		premio = { monedas = 700, pelaje_xib = 4, xp = 300 } },
	{ titulo = "Silencio en el Templo", texto = "Sus gritos aturden a cualquiera. Rómpele las orejas y el templo quedará en silencio.",
		objetivo = "Rompe las orejas de Camazotz", cond = { behemoth = "Camazotz", parte = "Orejas" },
		premio = { monedas = 600, oreja_eco = 2, xp = 300 } },
	{ titulo = "La Tormenta del Cenote", texto = "En el Cenote Sagrado vive Xolotl, un ajolote enorme que llama a los rayos. No dejes de golpearlo: si descansa, se cura.",
		objetivo = "Caza a Xolotl", cond = { behemoth = "Xolotl", exito = true },
		premio = { monedas = 750, piel_ajo = 4, xp = 320 } },
	{ titulo = "Sin Rayos", texto = "Sus branquias llaman a la tormenta. Rómpeselas y Tláloc lo dejará solo.",
		objetivo = "Rompe las branquias de Xolotl", cond = { behemoth = "Xolotl", parte = "Branquias" },
		premio = { monedas = 650, branquia = 2, xp = 320 } },
	{ titulo = "El Jaguar de Obsidiana", texto = "Balam caza en la selva. Salta, corre en zigzag y sus garras te hacen sangrar. Vigila sus manchas de jade.",
		objetivo = "Caza a Balam", cond = { behemoth = "Balam", exito = true },
		premio = { monedas = 850, pelo_jag = 4, xp = 360 } },
	{ titulo = "El Monstruo de la Creación", texto = "Los mexicas dicen que el mundo se hizo con el cuerpo de Cipactli. Hoy despertó en los Pantanos de Aztlán.",
		objetivo = "Caza a Cipactli", cond = { behemoth = "Cipactli", exito = true },
		premio = { monedas = 950, escama_cip = 4, xp = 400 } },
	{ titulo = "Leyenda de la Selva", texto = "Solo una leyenda vuelve de la selva con todo. Rompe las 3 partes de Balam o de Cipactli.",
		objetivo = "Caza a Balam o Cipactli rompiendo sus 3 partes", cond = { behemoths = { "Balam", "Cipactli" }, exito = true, minPartes = 3 },
		premio = { monedas = 1500, nucleo = 4, xp = 600 } },
}

DatosMisiones.ENCARGOS = {
	rompedor = { titulo = "Rompedor", objetivo = "Rompe 3 partes en una cacería", cond = { minPartes = 3 }, premio = { monedas = 250, nucleo = 1, xp = 80 } },
	intacto = { titulo = "Sin un rasguño", objetivo = "Completa una cacería sin que nadie se desmaye", cond = { exito = true, maxDesmayos = 0 }, premio = { monedas = 250, escama = 3, xp = 80 } },
	veloz = { titulo = "Cazador veloz", objetivo = "Completa una cacería en menos de 10 minutos", cond = { exito = true, maxTiempo = 600 }, premio = { monedas = 300, xp = 100 } },
	derribador = { titulo = "Derribador", objetivo = "Derriba 2 veces a un Behemoth en una cacería", cond = { minDerribos = 2 }, premio = { monedas = 250, nucleo = 1, xp = 80 } },
	dunas = { titulo = "Rey del Desierto", objetivo = "Caza a Sekhmaur o a Kheprak", cond = { behemoths = { "Sekhmaur", "Kheprak" }, exito = true }, premio = { monedas = 200, escama = 4, xp = 60 } },
	cumbres = { titulo = "Cazador de los Andes", objetivo = "Caza a Amaru o a Apu Rumi", cond = { behemoths = { "Amaru", "Apu Rumi" }, exito = true }, premio = { monedas = 300, sombra = 2, piedra_inti = 2, xp = 90 } },
	selva = { titulo = "Señor de la Selva", objetivo = "Caza a un Behemoth de la Selva de Obsidiana", cond = { behemoths = { "Camazotz", "Xolotl", "Balam", "Cipactli" }, exito = true }, premio = { monedas = 350, pelaje_xib = 2, piel_ajo = 2, xp = 110 } },
}
DatosMisiones.ORDEN_ENCARGOS = { "rompedor", "intacto", "veloz", "derribador", "dunas", "cumbres", "selva" }
DatosMisiones.MAX_ENCARGOS = 2

local ISLA_DE = { Sekhmaur = "Mar de Dunas", Kheprak = "Desierto de Brasa", Amaru = "Cuevas del Uku Pacha", ["Apu Rumi"] = "Cumbres del Inti",
	Camazotz = "Templo de Xibalbá", Xolotl = "Cenote Sagrado", Balam = "Selva de Obsidiana", Cipactli = "Pantanos de Aztlán" }

-- ¿esta cacería cumple las condiciones?
function DatosMisiones.cumple(cond, datos): boolean
	if cond.behemoth and datos.behemoth ~= cond.behemoth then
		return false
	end
	if cond.isla and ISLA_DE[datos.behemoth] ~= cond.isla then
		return false
	end
	if cond.behemoths and not table.find(cond.behemoths, datos.behemoth) then
		return false
	end
	if cond.exito and not datos.exito then
		return false
	end
	if cond.minPartes and #datos.partes < cond.minPartes then
		return false
	end
	if cond.parte and not table.find(datos.partes, cond.parte) then
		return false
	end
	if cond.maxDesmayos and datos.desmayos > cond.maxDesmayos then
		return false
	end
	if cond.maxTiempo and datos.tiempo > cond.maxTiempo then
		return false
	end
	if cond.minDerribos and datos.derribos < cond.minDerribos then
		return false
	end
	return true
end

-- texto de una recompensa: "300 monedas · 4 Escamas de duna · 100 XP"
function DatosMisiones.textoPremio(premio, materiales): string
	local partes = {}
	if premio.monedas then
		table.insert(partes, premio.monedas .. " monedas")
	end
	for k, v in premio do
		if k ~= "monedas" and k ~= "xp" then
			table.insert(partes, v .. " " .. (materiales[k] or k))
		end
	end
	if premio.xp then
		table.insert(partes, premio.xp .. " XP")
	end
	return table.concat(partes, " · ")
end

return DatosMisiones
