--!nonstrict
-- Sonidos de las armas y los Behemoths.
-- Por ahora usan sonidos que vienen dentro de Roblox, con tonos distintos para que cada uno
-- suene diferente. Para cambiarlos: en Studio abre el Toolbox > Audio, busca un sonido
-- (por ejemplo "roar" o "sword swing"), copia su ID y ponlo aquí como "rbxassetid://NUMERO".
local Sonidos = {}

local TAJO = "rbxasset://sounds/swordslash.wav"
local ESTOCADA = "rbxasset://sounds/swordlunge.wav"
local GOLPE = "rbxasset://sounds/collide.wav"
local SILBIDO = "rbxasset://sounds/Rocket whoosh 01.wav"
local DISPARO = "rbxasset://sounds/Rocket shot.wav"
local CARGA = "rbxasset://sounds/Launching rocket.wav"
local AGUA = "rbxasset://sounds/impact_water.mp3"
local SALTO = "rbxasset://sounds/action_jump.mp3"
local CAIDA = "rbxasset://sounds/action_falling.mp3"
local PING = "rbxasset://sounds/electronicpingshort.wav"

-- { id, tono (1 = normal; más bajo = más grave), volumen }
Sonidos.ARMAS = {
	espada = { tajo = { TAJO, 1.0, 0.6 }, fuerte = { ESTOCADA, 1.0, 0.7 } },
	martillo = { tajo = { SILBIDO, 0.55, 0.6 }, fuerte = { GOLPE, 0.45, 0.9 } },
	guadanas = { tajo = { TAJO, 1.35, 0.5 }, fuerte = { SILBIDO, 1.4, 0.6 } },
	lanza = { tajo = { ESTOCADA, 1.2, 0.6 }, fuerte = { ESTOCADA, 0.85, 0.8 } },
	pistolas = { tajo = { DISPARO, 1.6, 0.35 }, fuerte = { DISPARO, 1.1, 0.6 } },
	punos = { tajo = { GOLPE, 1.3, 0.5 }, fuerte = { GOLPE, 0.7, 0.8 } },
	colmillo = { tajo = { TAJO, 0.9, 0.6 }, fuerte = { AGUA, 0.7, 0.7 } },
	esfinge = { tajo = { SILBIDO, 0.5, 0.6 }, fuerte = { GOLPE, 0.35, 1.0 } },
	remolino = { tajo = { TAJO, 1.5, 0.5 }, fuerte = { SILBIDO, 0.9, 0.7 } },
	serket = { tajo = { ESTOCADA, 1.35, 0.6 }, fuerte = { AGUA, 1.3, 0.7 } },
	sol_dorado = { tajo = { DISPARO, 1.8, 0.35 }, fuerte = { CARGA, 1.4, 0.6 } },
	mandibula = { tajo = { TAJO, 0.8, 0.6 }, fuerte = { CARGA, 0.8, 0.7 } },
	sol_rodante = { tajo = { SILBIDO, 0.45, 0.6 }, fuerte = { CARGA, 0.6, 0.8 } },
	pinzas = { tajo = { TAJO, 1.6, 0.5 }, fuerte = { SILBIDO, 1.6, 0.6 } },
	hercules = { tajo = { ESTOCADA, 0.95, 0.6 }, fuerte = { CARGA, 0.7, 0.8 } },
	brasa = { tajo = { DISPARO, 1.3, 0.4 }, fuerte = { CARGA, 1.0, 0.7 } },
	filo_eclipse = { tajo = { TAJO, 0.7, 0.6 }, fuerte = { PING, 0.4, 0.7 } },
	martillo_uku = { tajo = { SILBIDO, 0.4, 0.6 }, fuerte = { GOLPE, 0.3, 1.0 } },
	alas_amaru = { tajo = { TAJO, 1.2, 0.5 }, fuerte = { SILBIDO, 1.2, 0.6 } },
	lanza_uku = { tajo = { ESTOCADA, 0.75, 0.6 }, fuerte = { PING, 0.5, 0.7 } },
	blasteres_eclipse = { tajo = { DISPARO, 0.9, 0.4 }, fuerte = { PING, 0.35, 0.8 } },
	filo_inti = { tajo = { TAJO, 1.1, 0.6 }, fuerte = { PING, 1.6, 0.7 } },
	puno_apu = { tajo = { SILBIDO, 0.38, 0.6 }, fuerte = { GOLPE, 0.25, 1.0 } },
	hoces_granito = { tajo = { TAJO, 1.1, 0.5 }, fuerte = { GOLPE, 0.8, 0.7 } },
	lanza_sol = { tajo = { ESTOCADA, 1.05, 0.6 }, fuerte = { GOLPE, 0.5, 0.9 } },
	blasteres_inti = { tajo = { DISPARO, 2.0, 0.35 }, fuerte = { PING, 1.2, 0.7 } },
}
Sonidos.ESQUIVA = { SALTO, 1.3, 0.4 }
Sonidos.GOLPEADO = { CAIDA, 0.9, 0.5 }

-- Los Behemoths: un sonido para cada acción (rugido, ataques, al caer).
Sonidos.BEHEMOTHS = {
	Sekhmaur = { rugir = { CARGA, 0.35, 1.0 }, ataque = { SILBIDO, 0.4, 0.9 }, golpe = { GOLPE, 0.3, 1.0 }, derribado = { CAIDA, 0.4, 1.0 } },
	Kheprak = { rugir = { CARGA, 0.55, 1.0 }, ataque = { GOLPE, 0.5, 0.9 }, golpe = { GOLPE, 0.4, 1.0 }, derribado = { CAIDA, 0.5, 1.0 } },
	Amaru = { rugir = { PING, 0.25, 1.0 }, ataque = { SILBIDO, 0.7, 0.9 }, golpe = { AGUA, 0.4, 1.0 }, derribado = { CAIDA, 0.35, 1.0 } },
	["Apu Rumi"] = { rugir = { GOLPE, 0.2, 1.0 }, ataque = { SILBIDO, 0.3, 1.0 }, golpe = { GOLPE, 0.22, 1.0 }, derribado = { CAIDA, 0.3, 1.0 } },
	Camazotz = { rugir = { PING, 0.55, 0.9 }, ataque = { SILBIDO, 0.75, 0.9 }, golpe = { GOLPE, 0.5, 0.9 }, derribado = { CAIDA, 0.45, 1.0 } },
	Xolotl = { rugir = { AGUA, 0.6, 1.0 }, ataque = { AGUA, 0.9, 0.9 }, golpe = { GOLPE, 0.45, 1.0 }, derribado = { AGUA, 0.5, 1.0 } },
	Balam = { rugir = { CARGA, 0.45, 1.0 }, ataque = { SILBIDO, 0.85, 0.9 }, golpe = { GOLPE, 0.4, 1.0 }, derribado = { CAIDA, 0.4, 1.0 } },
	Cipactli = { rugir = { CARGA, 0.3, 1.0 }, ataque = { AGUA, 0.45, 1.0 }, golpe = { GOLPE, 0.3, 1.0 }, derribado = { CAIDA, 0.3, 1.0 } },
}

return Sonidos
