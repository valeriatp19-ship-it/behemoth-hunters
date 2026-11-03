--!nonstrict
-- Las cinco armas base. Tiempos en segundos; "alcance" en metros (se multiplica por 3 al usarlo).
-- "golpe" es el momento del ataque en que se revisa si alcanzó al Behemoth.
local Armas = {}

Armas.ORDEN = { "espada", "martillo", "guadanas", "lanza", "pistolas", "punos" }

Armas.DATOS = {
	-- Guanteletes: a puño limpio, rápidos y muy buenos para aturdir y derribar (uno en cada mano)
	punos = {
		nombre = "Guanteletes del Nómada", rol = "Veloz",
		danio = 11, partes = 0.9, aturdir = 1.45, doble = true,
		combo = {
			{ anim = "jab_der", danio = 0.9, alcance = 2.3, golpe = 0.09, duracion = 0.3, paso = 0.45 },
			{ anim = "jab_izq", danio = 0.9, alcance = 2.3, golpe = 0.09, duracion = 0.3, paso = 0.45 },
			{ anim = "gancho", danio = 1.7, alcance = 2.5, golpe = 0.2, duracion = 0.45, paso = 0.6 },
		},
		fuerte = { anim = "golpe", danio = 2.9, alcance = 3.1, golpe = 0.38, duracion = 0.8, paso = 0.9, aguante = 18 },
	},
	espada = {
		nombre = "Espada del Alba", rol = "Balanceada",
		danio = 15, partes = 1.0, aturdir = 1.0,
		combo = {
			{ anim = "tajo", danio = 1.0, alcance = 2.7, golpe = 0.22, duracion = 0.5, paso = 0.5 },
			{ anim = "reves", danio = 1.1, alcance = 2.7, golpe = 0.22, duracion = 0.5, paso = 0.5 },
			{ anim = "vertical", danio = 1.8, alcance = 3.0, golpe = 0.3, duracion = 0.75, paso = 0.7 },
		},
		fuerte = { anim = "estocada", danio = 2.6, alcance = 3.4, golpe = 0.5, duracion = 0.95, paso = 2.0, aguante = 18 },
	},
	martillo = {
		nombre = "Martillo del Obelisco", rol = "Daño aturdidor",
		danio = 31, partes = 0.9, aturdir = 2.8,
		combo = {
			{ anim = "tajo", danio = 1.0, alcance = 3.0, golpe = 0.38, duracion = 0.85, paso = 0.4 },
			{ anim = "reves", danio = 1.15, alcance = 3.0, golpe = 0.38, duracion = 0.85, paso = 0.4 },
			{ anim = "vertical", danio = 2.1, alcance = 3.2, golpe = 0.5, duracion = 1.1, paso = 0.6 },
		},
		fuerte = { anim = "vertical", danio = 3.3, alcance = 3.6, golpe = 0.75, duracion = 1.35, paso = 2.2, aguante = 24 },
	},
	guadanas = {
		nombre = "Guadañas del Nómada", rol = "Daño de partes (cerca)", doble = true,
		danio = 11.5, partes = 1.9, aturdir = 0.4,
		combo = { -- tajo con la derecha, tajo con la izquierda y la vuelta de 360°
			{ anim = "tajo_der", danio = 0.9, alcance = 2.5, golpe = 0.15, duracion = 0.35, paso = 0.35 },
			{ anim = "tajo_izq", danio = 0.9, alcance = 2.5, golpe = 0.15, duracion = 0.35, paso = 0.35 },
			{ anim = "giro", danio = 0.7, alcance = 3.0, golpe = 0.2, duracion = 0.6, paso = 0.5, golpes = 3 },
		},
		fuerte = { anim = "giro", danio = 0.75, alcance = 3.2, golpe = 0.25, duracion = 0.85, paso = 2.0, aguante = 20, golpes = 4 },
	},
	lanza = {
		nombre = "Lanza del Vigía", rol = "Crea heridas", herida = true,
		danio = 16, partes = 1.0, aturdir = 0.7,
		combo = {
			{ anim = "estocada", danio = 1.0, alcance = 3.9, golpe = 0.2, duracion = 0.5, paso = 0.5 },
			{ anim = "estocada", danio = 1.05, alcance = 3.9, golpe = 0.2, duracion = 0.5, paso = 0.5 },
			{ anim = "vertical", danio = 1.6, alcance = 4.2, golpe = 0.3, duracion = 0.75, paso = 0.6 },
		},
		fuerte = { anim = "estocada", danio = 2.8, alcance = 4.8, golpe = 0.5, duracion = 1.0, paso = 2.2, aguante = 20, herida_profunda = true },
	},
	pistolas = {
		nombre = "Blásteres del Explorador", rol = "Daño de partes (distancia)", doble = true, distancia = true,
		danio = 8, partes = 1.9, aturdir = 0.2,
		combo = { -- disparan de una en una: derecha, izquierda, derecha...
			{ anim = "disparo_d", lado = 1, danio = 1.0, alcance = 40, golpe = 0.02, duracion = 0.18, paso = 0 },
			{ anim = "disparo_i", lado = -1, danio = 1.0, alcance = 40, golpe = 0.02, duracion = 0.18, paso = 0 },
		},
		fuerte = { anim = "disparo", danio = 3.4, alcance = 40, golpe = 0.05, duracion = 0.5, paso = 0, aguante = 18 },
	},
}

-- ---------- armas forjadas con materiales de Sekhmaur ----------
-- Usan los mismos movimientos que su arma base, con más daño y su propio diseño.
Armas.SEKHMAUR = {
	colmillo = { poderId = "ola", behemoth = "sekhmaur", base = "espada", nombre = "Espada del León", danio = 19,
		poder = "Tras una esquiva perfecta, tu siguiente golpe lanza una ola de arena.",
		receta = { monedas = 400, escama = 5, arena = 2, nucleo = 1 } },
	esfinge = { poderId = "arenas", behemoth = "sekhmaur", base = "martillo", nombre = "Martillo del Desierto", danio = 38,
		poder = "El golpe fuerte crea arenas movedizas que frenan al Behemoth.",
		receta = { monedas = 400, escama = 5, oro = 2, nucleo = 1 } },
	remolino = { poderId = "remolino", behemoth = "sekhmaur", base = "guadanas", nombre = "Guadañas Eternas", danio = 14,
		poder = "Los giros dejan un remolino que sigue golpeando.",
		receta = { monedas = 400, escama = 5, arena = 2, nucleo = 1 } },
	serket = { poderId = "veneno", behemoth = "sekhmaur", base = "lanza", nombre = "Lanza de las Dunas", danio = 19.5,
		poder = "Tus golpes abren heridas que además envenenan.",
		receta = { monedas = 400, escama = 5, aguijon = 2, nucleo = 1 } },
	sol_dorado = { poderId = "rayo", behemoth = "sekhmaur", base = "pistolas", nombre = "Blaster Solar", danio = 10,
		poder = "El disparo cargado es un rayo solar que atraviesa hasta 3 partes.",
		receta = { monedas = 400, escama = 5, oro = 2, nucleo = 1 } },
}
Armas.ORDEN_SEKHMAUR = { "colmillo", "esfinge", "remolino", "serket", "sol_dorado", "zarpas_leon" }

-- ---------- armas de Kheprak (elemento Brasa) ----------
Armas.KHEPRAK = {
	mandibula = { poderId = "calor", behemoth = "kheprak", base = "espada", nombre = "Espada Solar", danio = 20,
		poder = "Cada golpe acumula calor; lleno, tu golpe fuerte estalla en llamas y lo quema.",
		receta = { monedas = 450, escama = 6, cuerno = 1, quitina = 1, nucleo = 1 } },
	sol_rodante = { poderId = "mini_bola", behemoth = "kheprak", base = "martillo", nombre = "Martillo Solar", danio = 39,
		poder = "El golpe fuerte suelta una mini bola solar que rueda y estalla contra el Behemoth.",
		receta = { monedas = 450, escama = 6, elitro = 1, quitina = 1, nucleo = 1 } },
	pinzas = { poderId = "linea_fuego", behemoth = "kheprak", base = "guadanas", nombre = "Guadañas de Fuego", danio = 14.5,
		poder = "Los giros dejan una línea de fuego que lo quema.",
		receta = { monedas = 450, escama = 6, cuerno = 2, nucleo = 1 } },
	hercules = { poderId = "embestida", behemoth = "kheprak", base = "lanza", nombre = "Lanza Ígnea", danio = 20,
		poder = "El ataque fuerte es una embestida que atraviesa y abre heridas ardientes.",
		receta = { monedas = 450, escama = 6, cuerno = 1, elitro = 1, nucleo = 1 } },
	brasa = { poderId = "bola_fuego", behemoth = "kheprak", base = "pistolas", nombre = "Blaster Carmesí", danio = 10.5,
		poder = "Los disparos queman; el cargado es una bola de fuego que explota en un área.",
		receta = { monedas = 450, escama = 6, quitina = 2, nucleo = 1 } },
}
Armas.ORDEN_KHEPRAK = { "mandibula", "sol_rodante", "pinzas", "hercules", "brasa", "nudillos_brasa" }

-- ---------- armas de Amaru (elemento Sombra) ----------
Armas.AMARU = {
	filo_eclipse = { poderId = "marca", behemoth = "amaru", base = "espada", nombre = "Espada Serpiente", danio = 21,
		poder = "Cada golpe deja una marca de sombra (hasta 5); el golpe fuerte las consume para hacer más daño.",
		receta = { monedas = 500, sombra = 6, cuerno_luna = 1, eclipse = 1, nucleo = 1 } },
	martillo_uku = { poderId = "pozo", behemoth = "amaru", base = "martillo", nombre = "Martillo del Abismo", danio = 41,
		poder = "El golpe fuerte abre un pozo de sombra que sigue dañando.",
		receta = { monedas = 500, sombra = 6, cuerno_luna = 1, pluma = 1, nucleo = 1 } },
	alas_amaru = { poderId = "plumas", behemoth = "amaru", base = "guadanas", nombre = "Guadañas Sombrías", danio = 15,
		poder = "Los giros lanzan plumas oscuras en círculo que alcanzan varias partes.",
		receta = { monedas = 500, sombra = 6, pluma = 2, nucleo = 1 } },
	lanza_uku = { poderId = "vampiro", behemoth = "amaru", base = "lanza", nombre = "Lanza del Uku Pacha", danio = 21,
		poder = "Tus heridas te devuelven vida con cada golpe.",
		receta = { monedas = 500, sombra = 6, cuerno_luna = 1, eclipse = 1, nucleo = 1 } },
	blasteres_eclipse = { poderId = "orbe", behemoth = "amaru", base = "pistolas", nombre = "Blaster Nocturno", danio = 11,
		poder = "El disparo cargado deja un orbe negro que estalla un instante después en un área.",
		receta = { monedas = 500, sombra = 6, pluma = 1, eclipse = 1, nucleo = 1 } },
}
Armas.ORDEN_AMARU = { "filo_eclipse", "martillo_uku", "alas_amaru", "lanza_uku", "blasteres_eclipse", "punos_eclipse" }

-- ---------- armas de Apu Rumi (elemento Sol) ----------
Armas.APU = {
	filo_inti = { poderId = "destello", behemoth = "apu_rumi", base = "espada", nombre = "Espada de Piedra", danio = 21,
		poder = "Acumula luz con cada golpe; con 4, el golpe fuerte lanza un destello que casi lo derriba.",
		receta = { monedas = 520, piedra_inti = 6, disco_solar = 1, nudillo = 1, nucleo = 1 } },
	puno_apu = { poderId = "terremoto", behemoth = "apu_rumi", base = "martillo", nombre = "Martillo de la Cima", danio = 42,
		poder = "El golpe fuerte provoca un terremoto que alcanza hasta 4 partes.",
		receta = { monedas = 520, piedra_inti = 6, nudillo = 2, nucleo = 1 } },
	hoces_granito = { poderId = "esquirlas", behemoth = "apu_rumi", base = "guadanas", nombre = "Guadañas del Alba", danio = 15,
		poder = "Los giros lanzan esquirlas de roca hacia adelante.",
		receta = { monedas = 520, piedra_inti = 6, nudillo = 1, hielo = 1, nucleo = 1 } },
	lanza_sol = { poderId = "pilar", behemoth = "apu_rumi", base = "lanza", nombre = "Lanza del Sol Naciente", danio = 21,
		poder = "El golpe fuerte levanta un pilar de piedra bajo el Behemoth.",
		receta = { monedas = 520, piedra_inti = 6, disco_solar = 1, hielo = 1, nucleo = 1 } },
	blasteres_inti = { poderId = "abanico", behemoth = "apu_rumi", base = "pistolas", nombre = "Blaster del Sol", danio = 11,
		poder = "El disparo cargado lanza tres rayos de sol en abanico.",
		receta = { monedas = 520, piedra_inti = 6, disco_solar = 2, nucleo = 1 } },
}
Armas.ORDEN_APU = { "filo_inti", "puno_apu", "hoces_granito", "lanza_sol", "blasteres_inti", "guanteletes_inti" }
-- los guanteletes de cada Behemoth (las recetas, como las de su martillo)
Armas.SEKHMAUR.zarpas_leon = { poderId = "arenas", behemoth = "sekhmaur", base = "punos", nombre = "Zarpas del León", danio = 14,
	poder = "El golpe fuerte contra el suelo crea arenas movedizas que frenan al Behemoth.", receta = table.clone(Armas.SEKHMAUR.esfinge.receta) }
Armas.KHEPRAK.nudillos_brasa = { poderId = "calor", behemoth = "kheprak", base = "punos", nombre = "Nudillos de Brasa", danio = 15,
	poder = "Cada golpe acumula calor; al rojo vivo, el golpe fuerte estalla en llamas.", receta = table.clone(Armas.KHEPRAK.sol_rodante.receta) }
Armas.AMARU.punos_eclipse = { poderId = "marca", behemoth = "amaru", base = "punos", nombre = "Puños del Eclipse", danio = 16,
	poder = "Tus golpes dejan marcas de sombra que el golpe fuerte detona.", receta = table.clone(Armas.AMARU.martillo_uku.receta) }
Armas.APU.guanteletes_inti = { poderId = "terremoto", behemoth = "apu_rumi", base = "punos", nombre = "Guanteletes del Inti", danio = 17,
	poder = "El golpe fuerte contra el suelo provoca un terremoto.", receta = table.clone(Armas.APU.puno_apu.receta) }
-- ---------- armas de Camazotz (elemento Eco) ----------
Armas.CAMAZOTZ = {
	colmillo_xib = { poderId = "grito", behemoth = "camazotz", base = "espada", nombre = "Colmillo de Xibalbá", danio = 22,
		poder = "El golpe fuerte lanza una onda sónica en cono que alcanza hasta 3 partes y las aturde.",
		receta = { monedas = 560, pelaje_xib = 6, oreja_eco = 1, colmillo_v = 1, nucleo = 1 } },
	tambor_cam = { poderId = "tambor", behemoth = "camazotz", base = "martillo", nombre = "Tambor de Camazotz", danio = 43,
		poder = "El golpe fuerte retumba como un tambor de guerra: llena muchísimo la barra de derribo de hasta 4 partes.",
		receta = { monedas = 560, pelaje_xib = 6, oreja_eco = 2, nucleo = 1 } },
	alas_obs = { poderId = "murcielagos", behemoth = "camazotz", base = "guadanas", nombre = "Alas de Obsidiana", danio = 15.5,
		poder = "Los giros sueltan tres murciélagos que vuelan a morder las partes cercanas.",
		receta = { monedas = 560, pelaje_xib = 6, membrana = 2, nucleo = 1 } },
	aguijon_inf = { poderId = "atraviesa", behemoth = "camazotz", base = "lanza", nombre = "Aguijón del Inframundo", danio = 22,
		poder = "La estocada fuerte atraviesa en línea y alcanza hasta 3 partes.",
		receta = { monedas = 560, pelaje_xib = 6, colmillo_v = 1, membrana = 1, nucleo = 1 } },
	blasteres_eco = { poderId = "rebote", behemoth = "camazotz", base = "pistolas", nombre = "Blásteres de Eco", danio = 11.5,
		poder = "Cada disparo rebota como un eco y golpea una segunda parte cercana.",
		receta = { monedas = 560, pelaje_xib = 6, oreja_eco = 1, membrana = 1, nucleo = 1 } },
	garras_cam = { poderId = "chupasangre", behemoth = "camazotz", base = "punos", nombre = "Garras de Camazotz", danio = 17.5,
		poder = "Cada golpe te devuelve 1 de vida (3 con el golpe fuerte).",
		receta = { monedas = 560, pelaje_xib = 6, colmillo_v = 2, nucleo = 1 } },
}
Armas.ORDEN_CAMAZOTZ = { "colmillo_xib", "tambor_cam", "alas_obs", "aguijon_inf", "blasteres_eco", "garras_cam" }

-- ---------- armas de Xolotl (elemento Tormenta) ----------
Armas.XOLOTL = {
	macuahuitl = { poderId = "trueno", behemoth = "xolotl", base = "espada", nombre = "Macuahuitl del Trueno", danio = 22,
		poder = "El golpe fuerte llama un rayo sobre la parte que golpeaste.",
		receta = { monedas = 580, piel_ajo = 6, branquia = 1, aleta = 1, nucleo = 1 } },
	mazo_tlaloc = { poderId = "charco", behemoth = "xolotl", base = "martillo", nombre = "Mazo de Tláloc", danio = 43,
		poder = "El golpe fuerte deja un charco electrificado que sigue dañando.",
		receta = { monedas = 580, piel_ajo = 6, aleta = 2, nucleo = 1 } },
	branquias_ajo = { poderId = "regenera", behemoth = "xolotl", base = "guadanas", nombre = "Branquias del Ajolote", danio = 15.5,
		poder = "Como el ajolote: cada giro te regenera 4 de vida.",
		receta = { monedas = 580, piel_ajo = 6, branquia = 2, nucleo = 1 } },
	atlatl = { poderId = "jabalina", behemoth = "xolotl", base = "lanza", nombre = "Atlatl de Tormenta", danio = 22,
		poder = "El ataque fuerte lanza una jabalina eléctrica que alcanza dos partes a distancia.",
		receta = { monedas = 580, piel_ajo = 6, cola_ajo = 1, branquia = 1, nucleo = 1 } },
	blasteres_cenote = { poderId = "cadena", behemoth = "xolotl", base = "pistolas", nombre = "Blásteres del Cenote", danio = 11.5,
		poder = "El disparo cargado es un rayo en cadena que salta a 3 partes.",
		receta = { monedas = 580, piel_ajo = 6, branquia = 1, cola_ajo = 1, nucleo = 1 } },
	punos_tormenta = { poderId = "estatica", behemoth = "xolotl", base = "punos", nombre = "Puños de Tormenta", danio = 17.5,
		poder = "Cada golpe acumula estática; con 6 cargas, tu golpe fuerte suelta una descarga.",
		receta = { monedas = 580, piel_ajo = 6, cola_ajo = 2, nucleo = 1 } },
}
Armas.ORDEN_XOLOTL = { "macuahuitl", "mazo_tlaloc", "branquias_ajo", "atlatl", "blasteres_cenote", "punos_tormenta" }

-- ---------- armas de Balam (elemento Obsidiana) ----------
Armas.BALAM = {
	filo_obs = { poderId = "sangrado", behemoth = "balam", base = "espada", nombre = "Filo de Obsidiana", danio = 23,
		poder = "Tus golpes abren heridas que lo hacen sangrar.",
		receta = { monedas = 620, pelo_jag = 6, garra_obs = 1, colmillo_jade = 1, nucleo = 1 } },
	mazo_jaguar = { poderId = "puas", behemoth = "balam", base = "martillo", nombre = "Mazo del Jaguar", danio = 44,
		poder = "El golpe fuerte hace brotar púas de obsidiana del suelo bajo el Behemoth.",
		receta = { monedas = 620, pelo_jag = 6, garra_obs = 2, nucleo = 1 } },
	garras_balam = { poderId = "cortes", behemoth = "balam", base = "guadanas", nombre = "Garras de Balam", danio = 16,
		poder = "Los giros lanzan tres cortes de jade en abanico que abren heridas.",
		receta = { monedas = 620, pelo_jag = 6, garra_obs = 1, cola_balam = 1, nucleo = 1 } },
	lanza_nocturna = { poderId = "acecho", behemoth = "balam", base = "lanza", nombre = "Lanza del Cazador Nocturno", danio = 23,
		poder = "Tras una esquiva perfecta, tu siguiente golpe hace el doble de daño y abre una herida.",
		receta = { monedas = 620, pelo_jag = 6, colmillo_jade = 1, cola_balam = 1, nucleo = 1 } },
	blasteres_jade = { poderId = "astillas", behemoth = "balam", base = "pistolas", nombre = "Blásteres de Jade", danio = 12,
		poder = "El disparo cargado se parte en astillas de jade que hieren hasta 4 partes.",
		receta = { monedas = 620, pelo_jag = 6, colmillo_jade = 2, nucleo = 1 } },
	zarpas_obs = { poderId = "desgarro", behemoth = "balam", base = "punos", nombre = "Zarpas de Obsidiana", danio = 18,
		poder = "Tus golpes fuertes desgarran: abren heridas que sangran.",
		receta = { monedas = 620, pelo_jag = 6, cola_balam = 2, nucleo = 1 } },
}
Armas.ORDEN_BALAM = { "filo_obs", "mazo_jaguar", "garras_balam", "lanza_nocturna", "blasteres_jade", "zarpas_obs" }

-- ---------- armas de Cipactli (elemento Abismo) ----------
Armas.CIPACTLI = {
	diente_cip = { poderId = "mordida", behemoth = "cipactli", base = "espada", nombre = "Diente de Cipactli", danio = 23,
		poder = "El golpe fuerte muerde dos veces.",
		receta = { monedas = 640, escama_cip = 6, diente_cip = 1, placa_cip = 1, nucleo = 1 } },
	mazo_pantano = { poderId = "lodo", behemoth = "cipactli", base = "martillo", nombre = "Mazo del Pantano", danio = 45,
		poder = "El golpe fuerte deja un lodazal que frena al Behemoth.",
		receta = { monedas = 640, escama_cip = 6, placa_cip = 2, nucleo = 1 } },
	hoces_creacion = { poderId = "remolino_agua", behemoth = "cipactli", base = "guadanas", nombre = "Hoces de la Creación", danio = 16,
		poder = "Los giros dejan un remolino de agua que sigue golpeando.",
		receta = { monedas = 640, escama_cip = 6, cola_cip = 2, nucleo = 1 } },
	arpon_abismo = { poderId = "arpon", behemoth = "cipactli", base = "lanza", nombre = "Arpón del Abismo", danio = 23,
		poder = "El golpe fuerte clava el arpón: herida profunda y el Behemoth se frena 3 segundos.",
		receta = { monedas = 640, escama_cip = 6, diente_cip = 1, cola_cip = 1, nucleo = 1 } },
	blasteres_abismo = { poderId = "geiser", behemoth = "cipactli", base = "pistolas", nombre = "Blásteres del Abismo", danio = 12,
		poder = "El disparo cargado hace brotar un géiser bajo el Behemoth.",
		receta = { monedas = 640, escama_cip = 6, placa_cip = 1, diente_cip = 1, nucleo = 1 } },
	fauces_cip = { poderId = "fauces", behemoth = "cipactli", base = "punos", nombre = "Fauces del Caimán", danio = 18.5,
		poder = "Cada cuarto golpe muerde: hace mucho más daño y abre una herida.",
		receta = { monedas = 640, escama_cip = 6, diente_cip = 2, nucleo = 1 } },
}
Armas.ORDEN_CIPACTLI = { "diente_cip", "mazo_pantano", "hoces_creacion", "arpon_abismo", "blasteres_abismo", "fauces_cip" }

Armas.FORJABLES = {}
for _, grupo in { Armas.CAMAZOTZ, Armas.XOLOTL, Armas.BALAM, Armas.CIPACTLI } do
	for id, x in grupo do
		Armas.FORJABLES[id] = x
	end
end
for id, x in Armas.SEKHMAUR do
	Armas.FORJABLES[id] = x
end
for id, x in Armas.KHEPRAK do
	Armas.FORJABLES[id] = x
end
for id, x in Armas.AMARU do
	Armas.FORJABLES[id] = x
end
for id, x in Armas.APU do
	Armas.FORJABLES[id] = x
end

local ELEMENTO_DE = { sekhmaur = "Arena", kheprak = "Brasa", amaru = "Sombra", apu_rumi = "Sol", camazotz = "Eco", xolotl = "Tormenta", balam = "Obsidiana", cipactli = "Abismo" }
for id, s in Armas.FORJABLES do
	local b = Armas.DATOS[s.base]
	Armas.DATOS[id] = {
		nombre = s.nombre, rol = b.rol .. " · " .. (ELEMENTO_DE[s.behemoth] or "Arena"), base = s.base,
		danio = s.danio, partes = b.partes, aturdir = b.aturdir,
		doble = b.doble, distancia = b.distancia, herida = b.herida,
		combo = b.combo, fuerte = b.fuerte, poderId = s.poderId,
	}
end
for id, d in Armas.DATOS do
	d.base = d.base or id
end

-- ---------- Set del Guardián de las Dunas ----------
Armas.ARMADURA = {
	capucha = { nombre = "Capucha del Guardián", efecto = "El rugido de Sekhmaur ya no te aturde.", receta = { monedas = 150, escama = 4, oro = 1 } },
	coraza = { nombre = "Coraza de Jeroglíficos", efecto = "+20 de vida máxima.", receta = { monedas = 200, escama = 6, arena = 1 } },
	garras = { nombre = "Garras de Sekhmaur", efecto = "Tu aguante se recupera un 35% más rápido.", receta = { monedas = 150, escama = 4, aguijon = 1 } },
	grebas = { nombre = "Grebas de Arena", efecto = "Esquivar gasta menos aguante.", receta = { monedas = 150, escama = 4, arena = 1 } },
	yelmo = { nombre = "Yelmo de Cuernos", efecto = "Tus golpes a la cabeza llenan 30% más la barra de derribo.", receta = { monedas = 200, escama = 4, cuerno = 1 } },
	caparazon = { nombre = "Caparazón del Rodador", efecto = "Recibes 7% menos daño de todo.", receta = { monedas = 250, escama = 6, elitro = 1 } },
	guanteletes = { nombre = "Guanteletes de Quitina", efecto = "Tus ataques fuertes gastan 30% menos aguante.", receta = { monedas = 200, escama = 4, quitina = 1 } },
	grebas_escarabajo = { nombre = "Grebas del Escarabajo", efecto = "Correr gasta 35% menos aguante.", receta = { monedas = 200, escama = 4, quitina = 1 } },
	mascara = { nombre = "Máscara de Amaru", efecto = "La ventana de la esquiva perfecta dura 50% más.", receta = { monedas = 250, sombra = 4, cuerno_luna = 1 } },
	manto = { nombre = "Manto de Plumas", efecto = "+10 de vida máxima y 3% menos daño.", receta = { monedas = 300, sombra = 6, pluma = 1 } },
	brazales = { nombre = "Brazales de Sombra", efecto = "Cada golpe que das te cura medio punto de vida.", receta = { monedas = 250, sombra = 4, eclipse = 1 } },
	botas_uku = { nombre = "Botas del Uku Pacha", efecto = "Esquivas 30% más lejos.", receta = { monedas = 250, sombra = 4, pluma = 1 } },
	corona = { nombre = "Corona del Inti", efecto = "Tus golpes a la cabeza hacen 10% más daño.", receta = { monedas = 260, piedra_inti = 4, disco_solar = 1 } },
	coraza_granito = { nombre = "Coraza de Granito", efecto = "+15 de vida máxima y los empujones te mueven la mitad.", receta = { monedas = 300, piedra_inti = 6, nudillo = 1 } },
	punos_piedra = { nombre = "Puños de Piedra", efecto = "Tus golpes fuertes hacen 10% más daño.", receta = { monedas = 260, piedra_inti = 4, nudillo = 1 } },
	grebas_montana = { nombre = "Grebas de la Montaña", efecto = "Te recuperas más rápido de los golpes y los aturdimientos.", receta = { monedas = 260, piedra_inti = 4, hielo = 1 } },
	-- las piezas de la Selva: su efecto es una lista de modificadores ("mods") que se suman
	yelmo_xib = { nombre = "Yelmo del Murciélago", efecto = "Los gritos y ondas de Camazotz no te aturden.", mods = { sinAturdir = 1 }, receta = { monedas = 280, pelaje_xib = 4, oreja_eco = 1 } },
	coraza_xib = { nombre = "Coraza de Alas Negras", efecto = "+15 de vida máxima.", mods = { vida = 15 }, receta = { monedas = 320, pelaje_xib = 6, membrana = 1 } },
	garras_xib = { nombre = "Garras de Xibalbá", efecto = "Cada golpe que das te cura medio punto de vida.", mods = { curaGolpe = 0.5 }, receta = { monedas = 280, pelaje_xib = 4, colmillo_v = 1 } },
	grebas_xib = { nombre = "Grebas Nocturnas", efecto = "Esquivar gasta 30% menos aguante.", mods = { esquivaCosto = 0.7 }, receta = { monedas = 280, pelaje_xib = 4, membrana = 1 } },
	penacho_tla = { nombre = "Penacho de Tláloc", efecto = "Tus golpes a la cabeza hacen 10% más daño.", mods = { danioCabeza = 1.1 }, receta = { monedas = 290, piel_ajo = 4, branquia = 1 } },
	pectoral_tla = { nombre = "Pectoral del Cenote", efecto = "+10 de vida máxima y recibes 4% menos daño.", mods = { vida = 10, reduccion = 0.96 }, receta = { monedas = 330, piel_ajo = 6, aleta = 1 } },
	brazales_tla = { nombre = "Brazales de Jade", efecto = "Tu aguante se recupera 30% más rápido.", mods = { aguanteRegen = 1.3 }, receta = { monedas = 290, piel_ajo = 4, cola_ajo = 1 } },
	sandalias_tla = { nombre = "Sandalias de la Lluvia", efecto = "Correr gasta 30% menos aguante.", mods = { correrCosto = 0.7 }, receta = { monedas = 290, piel_ajo = 4, aleta = 1 } },
	yelmo_jag = { nombre = "Yelmo de Jaguar", efecto = "La ventana de la esquiva perfecta dura 40% más.", mods = { ventanaEsquiva = 1.4 }, receta = { monedas = 300, pelo_jag = 4, colmillo_jade = 1 } },
	piel_jag = { nombre = "Piel de Balam", efecto = "+15 de vida máxima.", mods = { vida = 15 }, receta = { monedas = 340, pelo_jag = 6, cola_balam = 1 } },
	garras_jag = { nombre = "Garras de Obsidiana", efecto = "Tus golpes rompen las partes 10% más rápido.", mods = { partes = 1.1 }, receta = { monedas = 300, pelo_jag = 4, garra_obs = 1 } },
	patas_jag = { nombre = "Patas del Jaguar", efecto = "Esquivas 25% más lejos.", mods = { esquivaLejos = 1.25 }, receta = { monedas = 300, pelo_jag = 4, cola_balam = 1 } },
	fauces_casco = { nombre = "Fauces de Cipactli", efecto = "Tus golpes fuertes hacen 10% más daño.", mods = { danioFuerte = 1.1 }, receta = { monedas = 310, escama_cip = 4, diente_cip = 1 } },
	caparazon_cip = { nombre = "Caparazón Primordial", efecto = "+10 de vida máxima y los empujones te mueven la mitad.", mods = { vida = 10, empuje = 0.5 }, receta = { monedas = 350, escama_cip = 6, placa_cip = 1 } },
	brazales_cip = { nombre = "Brazales de Escamas", efecto = "Tus golpes llenan 15% más la barra de derribo.", mods = { aturdir = 1.15 }, receta = { monedas = 310, escama_cip = 4, placa_cip = 1 } },
	grebas_cip = { nombre = "Grebas del Pantano", efecto = "Recibes 6% menos daño.", mods = { reduccion = 0.94 }, receta = { monedas = 310, escama_cip = 4, cola_cip = 1 } },
}
-- cada pieza pertenece a un set y ocupa una parte del cuerpo (solo una por parte)
Armas.PIEZA_SET = { capucha = "guardian", coraza = "guardian", garras = "guardian", grebas = "guardian",
	yelmo = "rodador", caparazon = "rodador", guanteletes = "rodador", grebas_escarabajo = "rodador",
	mascara = "eclipse", manto = "eclipse", brazales = "eclipse", botas_uku = "eclipse",
	corona = "apu", coraza_granito = "apu", punos_piedra = "apu", grebas_montana = "apu",
	yelmo_xib = "xibalba", coraza_xib = "xibalba", garras_xib = "xibalba", grebas_xib = "xibalba",
	penacho_tla = "tlaloc", pectoral_tla = "tlaloc", brazales_tla = "tlaloc", sandalias_tla = "tlaloc",
	yelmo_jag = "jaguar", piel_jag = "jaguar", garras_jag = "jaguar", patas_jag = "jaguar",
	fauces_casco = "cipactli", caparazon_cip = "cipactli", brazales_cip = "cipactli", grebas_cip = "cipactli" }
Armas.RANURA = { capucha = "cabeza", coraza = "torso", garras = "brazos", grebas = "piernas",
	yelmo = "cabeza", caparazon = "torso", guanteletes = "brazos", grebas_escarabajo = "piernas",
	mascara = "cabeza", manto = "torso", brazales = "brazos", botas_uku = "piernas",
	corona = "cabeza", coraza_granito = "torso", punos_piedra = "brazos", grebas_montana = "piernas",
	yelmo_xib = "cabeza", coraza_xib = "torso", garras_xib = "brazos", grebas_xib = "piernas",
	penacho_tla = "cabeza", pectoral_tla = "torso", brazales_tla = "brazos", sandalias_tla = "piernas",
	yelmo_jag = "cabeza", piel_jag = "torso", garras_jag = "brazos", patas_jag = "piernas",
	fauces_casco = "cabeza", caparazon_cip = "torso", brazales_cip = "brazos", grebas_cip = "piernas" }
Armas.ORDEN_APU_SET = { "corona", "coraza_granito", "punos_piedra", "grebas_montana" }
Armas.BONOS_APU = {
	"2 piezas: tus golpes rompen las partes 15% más rápido.",
	"4 piezas · Piel de Piedra: si un golpe te deja con menos del 40% de vida, te vuelves de piedra 4 s y recibes la mitad de daño (una vez por minuto).",
}
Armas.ORDEN_ECLIPSE = { "mascara", "manto", "brazales", "botas_uku" }
Armas.BONOS_ECLIPSE = {
	"2 piezas: la nube de sombra no te ciega y los ataques de Amaru te hacen 20% menos daño.",
	"4 piezas · Paso de Sombra: tras una esquiva perfecta te vuelves sombra 1 s (nada te alcanza) y tu siguiente golpe hace 20% más.",
}
Armas.ORDEN_ARMADURA = { "capucha", "coraza", "garras", "grebas" }
Armas.ORDEN_RODADOR = { "yelmo", "caparazon", "guanteletes", "grebas_escarabajo" }
Armas.ORDEN_XIBALBA = { "yelmo_xib", "coraza_xib", "garras_xib", "grebas_xib" }
Armas.ORDEN_TLALOC = { "penacho_tla", "pectoral_tla", "brazales_tla", "sandalias_tla" }
Armas.ORDEN_JAGUAR = { "yelmo_jag", "piel_jag", "garras_jag", "patas_jag" }
Armas.ORDEN_CIPACTLI_SET = { "fauces_casco", "caparazon_cip", "brazales_cip", "grebas_cip" }
Armas.BONOS_XIBALBA = {
	"2 piezas: los ataques de Camazotz te hacen 20% menos daño.",
	"4 piezas · Vuelo de Xibalbá: tras una esquiva perfecta te curas 12 de vida (cada 8 segundos).",
}
Armas.BONOS_TLALOC = {
	"2 piezas: los ataques de Xolotl te hacen 20% menos daño.",
	"4 piezas · Furia de la Tormenta: cada 10 golpes cae un rayo sobre el Behemoth.",
}
Armas.BONOS_JAGUAR = {
	"2 piezas: los ataques de Balam te hacen 20% menos daño.",
	"4 piezas · Instinto del Jaguar: tras una esquiva perfecta tus golpes hacen 20% más daño durante 5 segundos.",
}
Armas.BONOS_CIPACTLI = {
	"2 piezas: los ataques de Cipactli te hacen 20% menos daño.",
	"4 piezas · Escamas de la Creación: al bajar del 30% de vida te curas 35 (una vez por minuto).",
}
Armas.BONOS_RODADOR = {
	"2 piezas: el fuego y las quemaduras te hacen la mitad de daño.",
	"4 piezas · Caparazón Solar: una coraza absorbe 30 de daño antes que tu vida y se regenera tras 10 segundos sin golpes.",
}
Armas.BONO_2 = "2 piezas: 20% menos daño del pisotón, la embestida y cuando sale de la arena."
Armas.BONO_4 = "4 piezas · Despertar del Guardián: tras una esquiva perfecta haces 15% más daño durante 6 segundos."

-- ---------- familias: las armas y el set de cada Behemoth (para la forja, el menú y el equipo) ----------
Armas.FAMILIAS = {
	{ id = "sekhmaur", nombre = "Sekhmaur", armas = Armas.ORDEN_SEKHMAUR, set = "guardian", nombreSet = "Set del Guardián", piezas = Armas.ORDEN_ARMADURA, bonos = { Armas.BONO_2, Armas.BONO_4 } },
	{ id = "kheprak", nombre = "Kheprak", armas = Armas.ORDEN_KHEPRAK, set = "rodador", nombreSet = "Set del Rodador", piezas = Armas.ORDEN_RODADOR, bonos = Armas.BONOS_RODADOR },
	{ id = "amaru", nombre = "Amaru", armas = Armas.ORDEN_AMARU, set = "eclipse", nombreSet = "Set del Eclipse", piezas = Armas.ORDEN_ECLIPSE, bonos = Armas.BONOS_ECLIPSE },
	{ id = "apu_rumi", nombre = "Apu Rumi", armas = Armas.ORDEN_APU, set = "apu", nombreSet = "Set del Apu", piezas = Armas.ORDEN_APU_SET, bonos = Armas.BONOS_APU },
	{ id = "camazotz", nombre = "Camazotz", armas = Armas.ORDEN_CAMAZOTZ, set = "xibalba", nombreSet = "Set de Xibalbá", piezas = Armas.ORDEN_XIBALBA, bonos = Armas.BONOS_XIBALBA, prefijo = "camazotz_" },
	{ id = "xolotl", nombre = "Xolotl", armas = Armas.ORDEN_XOLOTL, set = "tlaloc", nombreSet = "Set de Tláloc", piezas = Armas.ORDEN_TLALOC, bonos = Armas.BONOS_TLALOC, prefijo = "xolotl_" },
	{ id = "balam", nombre = "Balam", armas = Armas.ORDEN_BALAM, set = "jaguar", nombreSet = "Set del Jaguar", piezas = Armas.ORDEN_JAGUAR, bonos = Armas.BONOS_JAGUAR, prefijo = "balam_" },
	{ id = "cipactli", nombre = "Cipactli", armas = Armas.ORDEN_CIPACTLI, set = "cipactli", nombreSet = "Set de Cipactli", piezas = Armas.ORDEN_CIPACTLI_SET, bonos = Armas.BONOS_CIPACTLI, prefijo = "cipactli_" },
}
Armas.SETS = {}
Armas.TODA_ARMADURA = {}
for _, f in Armas.FAMILIAS do
	table.insert(Armas.SETS, f.set)
	for _, pieza in f.piezas do
		table.insert(Armas.TODA_ARMADURA, pieza)
	end
end

-- Suma los modificadores de las piezas puestas (para las piezas nuevas que usan "mods").
-- Los que multiplican empiezan en 1; los que suman, en 0.
local SUMAN = { vida = true, curaGolpe = true, sinAturdir = true }
-- todos los modificadores que existen (el equipo los pone como atributos Mod_<clave>)
Armas.CLAVES_MODS = { "vida", "curaGolpe", "sinAturdir", "esquivaCosto", "danioCabeza", "reduccion", "aguanteRegen", "correrCosto",
	"ventanaEsquiva", "partes", "esquivaLejos", "danioFuerte", "empuje", "aturdir" }
Armas.MOD_SUMA = SUMAN
function Armas.mods(lleva: { [string]: boolean })
	local m = {}
	for pieza, puesta in lleva do
		local a = puesta and Armas.ARMADURA[pieza]
		if a and a.mods then
			for k, v in a.mods do
				if SUMAN[k] then
					m[k] = (m[k] or 0) + v
				else
					m[k] = (m[k] or 1) * v
				end
			end
		end
	end
	return m
end

Armas.MATERIALES = {
	escama = "Escama de duna", arena = "Arena viva", oro = "Oro del guardián",
	aguijon = "Aguijón solar", nucleo = "Núcleo del desierto",
	cuerno = "Cuerno de Kheprak", elitro = "Élitro solar", quitina = "Quitina ardiente",
	sombra = "Escama de sombra", pluma = "Pluma nocturna", cuerno_luna = "Cuerno lunar", eclipse = "Fragmento de eclipse",
	piedra_inti = "Piedra del Inti", disco_solar = "Fragmento del disco solar", nudillo = "Nudillo de granito", hielo = "Hielo eterno",
	pelaje_xib = "Pelaje de Xibalbá", oreja_eco = "Oreja de eco", membrana = "Membrana nocturna", colmillo_v = "Colmillo vampiro",
	piel_ajo = "Piel de ajolote", branquia = "Branquia de tormenta", cola_ajo = "Cola del ajolote", aleta = "Aleta del cenote",
	pelo_jag = "Piel de jaguar", garra_obs = "Garra de obsidiana", colmillo_jade = "Colmillo de jade", cola_balam = "Cola de Balam",
	escama_cip = "Escama primordial", placa_cip = "Placa del lomo", diente_cip = "Diente de Cipactli", cola_cip = "Cola del caimán",
}
Armas.ORDEN_MATERIALES = { "escama", "arena", "oro", "aguijon", "nucleo", "cuerno", "elitro", "quitina", "sombra", "pluma", "cuerno_luna", "eclipse", "piedra_inti", "disco_solar", "nudillo", "hielo",
	"pelaje_xib", "oreja_eco", "membrana", "colmillo_v", "piel_ajo", "branquia", "cola_ajo", "aleta", "pelo_jag", "garra_obs", "colmillo_jade", "cola_balam", "escama_cip", "placa_cip", "diente_cip", "cola_cip" }

-- ---------- bestiario ----------
-- modelo: nombre del modelo en el juego · fase2: lo que muestra el HUD en su segunda fase · pista: cómo rastrearlo
Armas.BESTIARIO = {
	{ id = "sekhmaur", nombre = "Sekhmaur", modelo = "Sekhmaur", fase2 = "Guardián despierto", pista = "sigue a los buitres", titulo = "León de las Dunas", isla = "Mar de Dunas", elemento = "Arena", estrellas = 2,
		descripcion = "Guardián de las pirámides cubierto de arena viva. Patrulla entre las ruinas, bebe en el oasis y se entierra para emboscar. Al perder la melena despierta el guardián que lleva dentro.",
		partes = { { "Melena de arena", "Arena viva" }, { "Tocado del guardián", "Oro del guardián" }, { "Aguijón", "Aguijón solar" } } },
	{ id = "kheprak", nombre = "Kheprak", modelo = "Kheprak", fase2 = "Caparazón al rojo", pista = "sigue los surcos de fuego", titulo = "Rodador Solar", isla = "Desierto de Brasa", elemento = "Brasa", estrellas = 3,
		descripcion = "Escarabajo colosal que empuja el sol. Carga una bola de arena fundida que persigue a su presa: rómpela mientras la forma o llévala contra una roca.",
		partes = { { "Cuerno mayor", "Cuerno de Kheprak" }, { "Élitros", "Élitro solar" }, { "Patas traseras", "Quitina ardiente" } } },
	{ id = "amaru", nombre = "Amaru", modelo = "Amaru", fase2 = "Eclipse", pista = "sigue el humo oscuro", titulo = "Serpiente Alada", isla = "Cuevas del Uku Pacha", elemento = "Sombra", estrellas = 4,
		descripcion = "La serpiente del Uku Pacha, el mundo de abajo. Vive en las cuevas de la montaña, envuelve todo en sombras y aparece detrás de sus presas. Cuando pierde la cresta, se abre el eclipse.",
		partes = { { "Cuernos lunares", "Cuerno lunar" }, { "Alas", "Pluma nocturna" }, { "Cresta", "Fragmento de eclipse" } } },
	{ id = "apu_rumi", nombre = "Apu Rumi", modelo = "ApuRumi", fase2 = "Grietas de sol", pista = "sigue los temblores", titulo = "Guardián de la Montaña", isla = "Cumbres del Inti", elemento = "Sol", estrellas = 4,
		descripcion = "Un gorila de piedra con el sol atrapado en sus grietas y el disco del Inti en el pecho. Lento pero devastador: sus golpes sacuden la montaña. Cuando pierde la nieve de los hombros, la luz escapa por las grietas.",
		partes = { { "Disco solar", "Fragmento del disco solar" }, { "Puños", "Nudillo de granito" }, { "Nieve de los hombros", "Hielo eterno" } } },
	{ id = "camazotz", nombre = "Camazotz", modelo = "Camazotz", fase2 = "Noche de Xibalbá", pista = "sigue el chillido de los murciélagos", titulo = "Murciélago de Xibalbá", isla = "Templo de Xibalbá", elemento = "Eco", estrellas = 4,
		descripcion = "El murciélago del inframundo maya. Ronda la plaza del templo caminando sobre sus alas, se lanza en picada desde el cielo y grita en ondas que aturden. Su mordida le devuelve vida. Cuando cae la Noche de Xibalbá, los glifos de sus alas se encienden y llama a su enjambre.",
		partes = { { "Orejas", "Oreja de eco" }, { "Alas", "Membrana nocturna" }, { "Colmillos", "Colmillo vampiro" } } },
	{ id = "xolotl", nombre = "Xolotl", modelo = "Xolotl", fase2 = "Tormenta de Tláloc", pista = "sigue los truenos", titulo = "Ajolote de la Tormenta", isla = "Cenote Sagrado", elemento = "Tormenta", estrellas = 4,
		descripcion = "Un ajolote colosal que vive en el cenote. Sus branquias en corona acumulan rayos, se sumerge para salir bajo tus pies y se regenera si dejas de presionarlo. Rompe sus branquias para que no pueda llamar la tormenta.",
		partes = { { "Branquias", "Branquia de tormenta" }, { "Cola", "Cola del ajolote" }, { "Aleta del lomo", "Aleta del cenote" } } },
	{ id = "balam", nombre = "Balam", modelo = "Balam", fase2 = "Camuflaje de jade", pista = "sigue las huellas de garras", titulo = "Jaguar de Obsidiana", isla = "Selva de Obsidiana", elemento = "Obsidiana", estrellas = 5,
		descripcion = "El jaguar sagrado de la selva, con garras de obsidiana y manchas de jade. Salta sobre su presa, corre en zigzag y sus zarpazos hacen sangrar. Herido, sus manchas brillan y se camufla entre la selva.",
		partes = { { "Garras", "Garra de obsidiana" }, { "Colmillos", "Colmillo de jade" }, { "Cola", "Cola de Balam" } } },
	{ id = "cipactli", nombre = "Cipactli", modelo = "Cipactli", fase2 = "Fauces de la Creación", pista = "sigue las burbujas del pantano", titulo = "Caimán de la Creación", isla = "Pantanos de Aztlán", elemento = "Abismo", estrellas = 5,
		descripcion = "El monstruo primordial de la creación mexica: un caimán colosal con placas en el lomo. Se oculta en el barro, gira con su presa y hace brotar géiseres de lodo. Cuando despiertan las Fauces de la Creación, se abren bocas a lo largo de su cuerpo.",
		partes = { { "Placas del lomo", "Placa del lomo" }, { "Mandíbula", "Diente de Cipactli" }, { "Cola", "Cola del caimán" } } },
}

-- experiencia para pasar del nivel n al siguiente
Armas.NIVEL_MAX = 30
function Armas.xpParaSubir(n: number): number
	return 100 + n * 50
end

-- ---------- islas y Behemoths (para el mapa de Tariq) ----------
Armas.ISLAS = {
	{ id = "dunas", nombre = "Mar de Dunas", cultura = "Egipto", zona = "desierto", behemoths = {
		{ id = "sekhmaur", nombre = "Sekhmaur", titulo = "León de las Dunas", elemento = "Arena", estrellas = 2, pista = "sigue a los buitres" },
	} },
	{ id = "brasa", nombre = "Desierto de Brasa", cultura = "Egipto", zona = "brasa", behemoths = {
		{ id = "kheprak", nombre = "Kheprak", titulo = "Rodador Solar", elemento = "Brasa", estrellas = 3, pista = "sigue los surcos de fuego" },
	} },
	{ id = "cuevas", nombre = "Cuevas del Uku Pacha", cultura = "Incas", zona = "cuevas", behemoths = {
		{ id = "amaru", nombre = "Amaru", titulo = "Serpiente Alada", elemento = "Sombra", estrellas = 4, pista = "sigue el humo oscuro" },
	} },
	{ id = "cumbres", nombre = "Cumbres del Inti", cultura = "Incas", zona = "cumbres", behemoths = {
		{ id = "apu_rumi", nombre = "Apu Rumi", titulo = "Guardián de la Montaña", elemento = "Sol", estrellas = 4, pista = "sigue los temblores" },
	} },
	{ id = "xibalba", nombre = "Templo de Xibalbá", cultura = "Mayas", zona = "xibalba", behemoths = {
		{ id = "camazotz", nombre = "Camazotz", titulo = "Murciélago de Xibalbá", elemento = "Eco", estrellas = 4, pista = "sigue el chillido de los murciélagos" },
	} },
	{ id = "cenote", nombre = "Cenote Sagrado", cultura = "Mayas", zona = "cenote", behemoths = {
		{ id = "xolotl", nombre = "Xolotl", titulo = "Ajolote de la Tormenta", elemento = "Tormenta", estrellas = 4, pista = "sigue los truenos" },
	} },
	{ id = "selva", nombre = "Selva de Obsidiana", cultura = "Mayas", zona = "selva", behemoths = {
		{ id = "balam", nombre = "Balam", titulo = "Jaguar de Obsidiana", elemento = "Obsidiana", estrellas = 5, pista = "sigue las huellas de garras" },
	} },
	{ id = "pantano", nombre = "Pantanos de Aztlán", cultura = "Mexicas", zona = "pantano", behemoths = {
		{ id = "cipactli", nombre = "Cipactli", titulo = "Caimán de la Creación", elemento = "Abismo", estrellas = 5, pista = "sigue las burbujas del pantano" },
	} },
	{ id = "fiordos", nombre = "Fiordos Helados", cultura = "Nórdica", behemoths = {} },
	{ id = "archipielago", nombre = "Archipiélago de Fuego", cultura = "Polinesia", behemoths = {} },
	{ id = "valles", nombre = "Valles de Niebla", cultura = "Japón", behemoths = {} },
}

return Armas
