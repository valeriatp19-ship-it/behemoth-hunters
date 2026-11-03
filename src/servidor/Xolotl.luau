--!nonstrict
-- Xolotl, el Ajolote de la Tormenta (elemento Tormenta): vive en el Cenote Sagrado.
-- Un ajolote colosal con branquias en corona que acumulan rayos y las anteojeras de Tláloc.
-- Ataques: mordida, coletazo, chorro de agua, se sumerge y sale bajo tus pies y llama rayos.
-- Si dejas de presionarlo se regenera. En la Tormenta de Tláloc (fase 2) caen rayos solos.
-- Partes: branquias (ya no llama rayos y se regenera menos), cola (coletazo más corto) y aleta
-- del lomo (ya no puede sumergirse).
local Base = require(script.Parent.BehemothSelva)

local V, CF = Base.V, Base.CF
local S = Base.S
local plano = Base.plano
local rgb = Color3.fromRGB

local PIEL = rgb(34, 72, 104) -- azul de tormenta
local PIEL2 = rgb(50, 96, 130)
local PIEL3 = rgb(28, 58, 86)
local VIENTRE = rgb(150, 192, 204)
local BRANQUIA = rgb(214, 56, 118)
local BRANQUIA2 = rgb(255, 112, 164)
local RAYO = rgb(255, 236, 90)
local TURQUESA = rgb(60, 220, 200)
local MANCHA = rgb(110, 240, 255)
local ALETA = rgb(120, 176, 210)
local OJO = rgb(20, 16, 24)
local BOCA = rgb(40, 20, 34)
local AGUA = rgb(90, 190, 230)

local def = {
	nombre = "Xolotl", modelo = "Xolotl", zona = "cenote", prefijo = "xolotl_",
	vidaBase = 9400, derriboMax = 300, velVagar = 3.2, velPerseguir = 6.4, distanciaCerca = 7,
	colorTexto = rgb(110, 220, 255), colorPolvo = AGUA,
	textoFase2 = "¡Tormenta de Tláloc! Los rayos caen sobre el cenote",
	radioIsla = 92,
	evitar = { { 0, -48, 19 }, { 36, -36, 6 }, { -38, -30, 6 } }, -- el risco de las cascadas y los altares de Tláloc
	ataques = {
		mordida = { prep = 0.75, activo = 0.25, rec = 0.8, danio = 24, empuje = 10 },
		coletazo = { prep = 0.8, activo = 0.35, rec = 0.85, danio = 22, empuje = 18 },
		chorro = { prep = 1.0, activo = 0.9, rec = 0.8, danio = 20, empuje = 24 },
		sumergirse = { prep = 0.9, activo = 2.6, rec = 1.0, danio = 28, empuje = 16 },
		rayos = { prep = 1.2, activo = 0.4, rec = 0.8, danio = 22, empuje = 6 },
		panzazo = { prep = 0.9, activo = 0.2, rec = 1.0, danio = 26, empuje = 16 },
		tormenta = { prep = 0, activo = 0, rec = 0, danio = 18, empuje = 6 }, -- rayos sueltos de la fase 2
	},
	partes = {
		branquias = { nombre = "Branquias", max = 420 },
		cola = { nombre = "Cola", max = 380 },
		aleta = { nombre = "Aleta del lomo", max = 380 },
	},
	ordenPartes = { "branquias", "cola", "aleta" },
	zonas = {
		{ nombre = "cabeza", tipo = "cabeza", parte = "", pos = Vector3.new(0, 2.3, -3.9), r = 1.8 },
		{ nombre = "boca", tipo = "cabeza", parte = "", pos = Vector3.new(0, 1.5, -5.0), r = 1.3 },
		{ nombre = "branquias_i", tipo = "cabeza", parte = "branquias", pos = Vector3.new(-2.5, 3.1, -2.8), r = 1.4 },
		{ nombre = "branquias_d", tipo = "cabeza", parte = "branquias", pos = Vector3.new(2.5, 3.1, -2.8), r = 1.4 },
		{ nombre = "torso", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 2.0, -0.4), r = 2.2 },
		{ nombre = "lomo", tipo = "cuerpo", parte = "aleta", pos = Vector3.new(0, 3.5, 0.3), r = 1.5 },
		{ nombre = "vientre", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.0, 0.8), r = 1.7 },
		{ nombre = "pata_di", tipo = "pata", parte = "", pos = Vector3.new(-3.0, 0.6, -1.6), r = 1.0 },
		{ nombre = "pata_dd", tipo = "pata", parte = "", pos = Vector3.new(3.0, 0.6, -1.6), r = 1.0 },
		{ nombre = "pata_ti", tipo = "pata", parte = "", pos = Vector3.new(-3.0, 0.6, 1.7), r = 1.0 },
		{ nombre = "pata_td", tipo = "pata", parte = "", pos = Vector3.new(3.0, 0.6, 1.7), r = 1.0 },
		{ nombre = "cola1", tipo = "cola", parte = "cola", pos = Vector3.new(0, 2.0, 5.1), r = 1.2 },
		{ nombre = "cola2", tipo = "cola", parte = "cola", pos = Vector3.new(0, 2.0, 6.9), r = 1.0 },
	},
	patrulla = { Vector2.new(0, -10), Vector2.new(15, -20), Vector2.new(-18, 0), Vector2.new(40, 20), Vector2.new(-40, 30), Vector2.new(0, 45), Vector2.new(50, -50), Vector2.new(-50, -40) },
	recompensa = {
		monedas = 380, base = "piel_ajo", nombreBase = "Pieles de ajolote",
		partes = { branquias = { "branquia", "Branquias de tormenta" }, cola = { "cola_ajo", "Colas del ajolote" }, aleta = { "aleta", "Aletas del cenote" } },
	},
}

-- ---------- cuerpo ----------
function def.construir(self)
	local raiz = self.raiz
	local torso = self:_parte({ Name = "Torso", Size = V(3.4, 2.2, 4.8), Color = PIEL, CanCollide = true })
	self:_unir(torso, raiz, CF(0, 1.9, 0), nil, "RaizCuerpo")
	self:_pieza(torso, "Lomo", V(3.0, 0.5, 4.4), PIEL2, CF(0, 1.2, 0.1))
	self:_pieza(torso, "Vientre", V(3.0, 0.5, 4.2), VIENTRE, CF(0, -1.15, 0))
	self:_pieza(torso, "Costado", V(0.3, 1.2, 4.0), PIEL3, CF(-1.75, -0.2, 0))
	self:_pieza(torso, "Costado", V(0.3, 1.2, 4.0), PIEL3, CF(1.75, -0.2, 0))
	-- manchas que brillan (bioluminiscencia de tormenta)
	for _, m in { { -1.1, 1.46, -1.4 }, { 0.9, 1.46, -0.6 }, { -0.4, 1.46, 0.5 }, { 1.2, 1.46, 1.4 }, { -1.2, 1.46, 1.8 }, { 0.3, 1.46, -1.9 } } do
		self:_grupo("manchas", self:_pieza(torso, "Mancha", V(0.4, 0.1, 0.4), MANCHA, CF(m[1], m[2], m[3]), { Neon = true, Transparency = 0.3 }))
	end
	for _, lado in { -1, 1 } do
		for _, z in { -1.2, 0.6 } do
			self:_grupo("manchas", self:_pieza(torso, "Mancha", V(0.1, 0.35, 0.35), MANCHA, CF(lado * 1.92, 0.3, z), { Neon = true, Transparency = 0.3 }))
		end
	end
	-- aleta del lomo: una cresta de placas translúcidas con el borde eléctrico
	for i = 0, 4 do
		local z = -1.8 + i * 0.95
		local alto = 0.7 + math.sin(i / 4 * math.pi) * 0.5
		local a = self:_pieza(torso, "Aleta", V(0.18, alto, 0.9), ALETA, CF(0, 1.45 + alto / 2, z), { Transparency = 0.2 })
		self:_grupo("aleta", a)
		self:_grupo("aleta", self:_pieza(a, "Borde", V(0.2, 0.12, 0.9), RAYO, CF(0, alto / 2, 0), { Neon = true }))
	end
	-- ---------- cabeza: ancha y plana, con la sonrisa del ajolote ----------
	local cabeza = self:_parte({ Name = "Cabeza", Size = V(3.8, 1.6, 2.8), Color = PIEL })
	self:_unir(cabeza, torso, CF(0, 0.2, -2.4), CF(0, -0.1, 1.3), "Cuello")
	self:_pieza(cabeza, "Frente", V(3.4, 0.4, 2.4), PIEL2, CF(0, 0.95, 0.1))
	self:_pieza(cabeza, "Hocico", V(3.2, 0.9, 0.6), PIEL2, CF(0, -0.1, -1.6))
	self:_pieza(cabeza, "Sonrisa", V(3.0, 0.14, 0.12), BOCA, CF(0, -0.45, -1.92))
	local mandibula = self:_parte({ Name = "Mandibula", Size = V(3.4, 0.5, 2.4), Color = VIENTRE })
	self:_unir(mandibula, cabeza, CF(0, -0.95, 1.15), CF(0, 0, 1.2), "Mandibula") -- bisagra atrás
	self:_pieza(mandibula, "Lengua", V(2.2, 0.12, 1.6), rgb(220, 120, 140), CF(0, 0.28, 0))
	for _, lado in { -1, 1 } do
		-- ojitos negros con las anteojeras de Tláloc (aros de turquesa)
		self:_pieza(cabeza, "Ojo", V(0.36, 0.36, 0.2), OJO, CF(lado * 1.25, 0.55, -1.25))
		self:_pieza(cabeza, "Brillo", V(0.12, 0.12, 0.05), rgb(240, 250, 255), CF(lado * 1.2, 0.62, -1.36), { Neon = true })
		for _, r in { { 0, 0.32, 0.9, 0.16 }, { 0, -0.32, 0.9, 0.16 }, { 0.4, 0, 0.16, 0.8 }, { -0.4, 0, 0.16, 0.8 } } do
			self:_pieza(cabeza, "Anteojera", V(r[3], r[4], 0.16), TURQUESA, CF(lado * 1.25 + r[1], 0.55 + r[2], -1.32), { Neon = true })
		end
		-- las tres branquias de cada lado: tallo con filamentos y puntas que acumulan rayos
		for k = 1, 3 do
			local L = (lado < 0 and "I" or "D") .. k
			local tallo = self:_parte({ Name = "Branquia" .. L, Size = V(0.4, 2.4, 0.4), Color = BRANQUIA })
			local ang = (k - 2) * 0.55
			self:_unir(tallo, cabeza, CF(lado * 1.75, 0.45 - (k - 1) * 0.35, 0.5 + (k - 1) * 0.35) * CFrame.Angles(0.25 * (k - 1), 0, -lado * (0.9 - ang * 0.6)), CF(0, -1.2, 0), "Branquia" .. L)
			self:_grupo("branquias", tallo)
			for f = 1, 4 do
				local y = -0.9 + f * 0.5
				for _, sl in { -1, 1 } do
					self:_grupo("branquias", self:_pieza(tallo, "Filamento", V(0.6, 0.14, 0.28), f % 2 == 0 and BRANQUIA2 or BRANQUIA, CF(sl * 0.42, y, 0) * CFrame.Angles(0, 0, sl * 0.5)))
				end
			end
			local punta = self:_pieza(tallo, "Punta", V(0.5, 0.4, 0.5), RAYO, CF(0, 1.35, 0), { Neon = true })
			self:_grupo("branquias", punta)
			self:_grupo("puntas", punta)
		end
	end
	-- ---------- patas: cortas, abiertas hacia los lados, con cuatro dedos ----------
	for _, lado in { -1, 1 } do
		for _, adelante in { true, false } do
			local L = (adelante and "D" or "T") .. (lado < 0 and "I" or "D")
			local muslo = self:_parte({ Name = "Pata" .. L, Size = V(1.6, 0.8, 0.8), Color = PIEL2 })
			self:_unir(muslo, torso, CF(lado * 1.6, -0.5, adelante and -1.6 or 1.7) * CFrame.Angles(0, 0, -lado * 0.35), CF(-lado * 0.8, 0, 0), "Pata" .. L)
			local pierna = self:_parte({ Name = "Pierna" .. L, Size = V(0.7, 1.0, 0.7), Color = PIEL })
			self:_unir(pierna, muslo, CF(lado * 0.75, 0, 0) * CFrame.Angles(0, 0, lado * 0.35), CF(0, 0.4, 0), "Rodilla" .. L)
			local mano = self:_pieza(pierna, "Mano", V(1.1, 0.25, 1.0), PIEL2, CF(lado * 0.1, -0.45, -0.1))
			for d = -1.5, 1.5 do
				self:_pieza(mano, "Dedo", V(0.18, 0.18, 0.5), VIENTRE, CF(d * 0.28, 0, -0.65) * CFrame.Angles(0, d * 0.25, 0))
			end
		end
	end
	-- ---------- cola: alta y plana, con aleta arriba y abajo ----------
	local padre, z0 = torso, 2.4
	local tamanos = { { 2.2, 1.9, 1.8 }, { 1.6, 1.7, 1.8 }, { 1.0, 1.4, 1.8 }, { 0.6, 1.0, 1.8 } }
	for i, t in tamanos do
		local seg = self:_parte({ Name = "Cola" .. i, Size = V(t[1], t[2], t[3]), Color = i % 2 == 0 and PIEL2 or PIEL })
		self:_unir(seg, padre, CF(0, i == 1 and 0.1 or 0, z0), CF(0, 0, -t[3] / 2), "Cola" .. i)
		if i >= 2 then
			self:_grupo("cola", seg)
		end
		local aleta = self:_pieza(seg, "AletaCola", V(0.16, 0.7 + i * 0.12, t[3]), ALETA, CF(0, t[2] / 2 + 0.35, 0), { Transparency = 0.2 })
		self:_grupo(i >= 2 and "cola" or "aleta", aleta)
		self:_grupo(i >= 2 and "cola" or "aleta", self:_pieza(aleta, "Borde", V(0.18, 0.1, t[3]), RAYO, CF(0, (0.7 + i * 0.12) / 2, 0), { Neon = true }))
		if i >= 2 then
			self:_grupo("cola", self:_pieza(seg, "AletaBaja", V(0.14, 0.5, t[3]), ALETA, CF(0, -t[2] / 2 - 0.2, 0), { Transparency = 0.2 }))
		end
		self:_grupo(i >= 2 and "cola" or "manchas", self:_pieza(seg, "Mancha", V(0.1, 0.3, 0.3), MANCHA, CF(t[1] / 2 + 0.03, 0.2, 0), { Neon = true, Transparency = 0.3 }))
		padre, z0 = seg, t[3] / 2
	end
	-- el círculo de los rayos de la tormenta (fase 2), aparte de los avisos del ataque
	local aviso = Instance.new("Part")
	aviso.Name = "AvisoTormenta"
	aviso.Anchored = true
	aviso.CanCollide = false
	aviso.CanQuery = false
	aviso.CanTouch = false
	aviso.Material = Enum.Material.Neon
	aviso.Color = rgb(255, 230, 90)
	aviso.Transparency = 1
	aviso.Shape = Enum.PartType.Cylinder
	aviso.Size = Vector3.new(0.3, 1, 1)
	aviso.Parent = workspace
	self.avisoTormenta = aviso
end

function def.ocultarExtras(self) end

-- un rayo que cae del cielo en ese punto
local function rayo(self, p: Vector3)
	local suelo = self:suelo(p)
	local largo = 40 * S
	for k = 0, 3 do
		local x = math.random(-10, 10) / 10 * S
		self:_efecto(CFrame.new(suelo + Vector3.new(x, largo * (k + 0.5) / 4, x * 0.5)) * CFrame.Angles(0, 0, math.rad(math.random(-12, 12))), Vector3.new(0.8 * S, largo / 4 + 2, 0.8 * S), RAYO, 0.25)
	end
	self:_anillo(suelo, 3.5, rgb(170, 230, 255), 0.35)
	self:_polvo(suelo, 15, rgb(200, 240, 255))
end

-- ---------- qué ataque elegir ----------
function def.elegir(self, dist, ang, o)
	if dist < 8 and ang < 0.7 then
		o("mordida", self.partes.branquias.rota and 2.6 or 2.2)
	end
	if dist < 8 and self:_hace("panzazo") > 5 then
		o("panzazo", 1.6) -- se levanta y cae de panza: aplasta a los que están cerca
	end
	if dist < 9 and ang > 1.6 then
		o("coletazo", 3) -- alguien detrás de él
	elseif dist < 7 then
		o("coletazo", 1)
	end
	if dist > 6 and dist < 24 and ang < 0.5 then
		o("chorro", 2)
	end
	if not self.partes.aleta.rota and dist > 9 and self:_hace("sumergirse") > 8 then
		o("sumergirse", 1.6)
	end
	if not self.partes.branquias.rota and dist < 32 and self:_hace("rayos") > 7 then
		o("rayos", self.fase2 and 2.2 or 1.4)
	end
end

-- ---------- ataques ----------
function def.atacar(self, a, c)
	local fase, tf, dt = self.fase, c.tf, c.dt
	local adelante, objetivo = c.adelante, c.objetivo
	if a == "mordida" then
		local punto = self.pos + adelante * 5.5 * S
		if fase == "prep" then
			if tf < c.prep - 0.4 then
				self:_girarHacia(self:_yawHacia(objetivo), 3, dt)
			end
			self:_avisoCirculo(punto, 3.2)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(punto, 20, AGUA)
			self:_golpear(function(p)
				return plano(p, punto) < 3.2
			end, punto)
		end
	elseif a == "coletazo" then
		-- gira la cola hacia atrás y a los lados
		local radio = self.partes.cola.rota and 4.2 or 6.2
		local centro = self.pos - adelante * 4 * S
		if fase == "prep" then
			self:_avisoCirculo(centro, radio)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_anillo(centro, radio, AGUA, 0.35)
			self:_polvo(centro, 30, AGUA)
			self:_golpear(function(p)
				return plano(p, centro) < radio
			end, centro)
		end
	elseif a == "chorro" then
		-- chorro de agua a presión en línea recta: empuja lejos
		local largo = 20
		local desde = self.pos + adelante * 4.5 * S
		if fase == "prep" then
			if tf < c.prep - 0.5 then
				self:_girarHacia(self:_yawHacia(objetivo), 1.8, dt)
			end
			self:_avisoRect(desde, self.yaw, 4.5, largo)
		elseif fase == "activo" then
			if not self.hecho then
				self.hecho = true
				self:_ocultarAvisos()
				local boca = desde + Vector3.new(0, 1.4 * S, 0)
				local agua = self:_efecto(CFrame.lookAt(boca + adelante * largo / 2 * S, boca + adelante * largo * S), Vector3.new(1.6 * S, 1.6 * S, largo * S), AGUA, c.act)
				agua.Transparency = 0.35
				for k = 1, 4 do
					task.delay(k * 0.15, function()
						self:_polvo(desde + adelante * (k * largo / 4) * S, 12, AGUA)
					end)
				end
			end
			self:_golpear(function(p)
				local rel = Vector3.new(p.X - desde.X, 0, p.Z - desde.Z) / S
				local aLoLargo = rel:Dot(adelante)
				local alLado = math.abs(rel:Cross(adelante).Y)
				return aLoLargo > -1 and aLoLargo < largo and alLado < 2.25
			end, desde)
		end
	elseif a == "panzazo" then
		local radio = 6.5
		if fase == "prep" then
			self:_avisoCirculo(self.pos, radio)
			self.altoExtra = math.min(1, tf / c.prep) * 1.5 * S
		elseif fase == "activo" then
			self.altoExtra = 0
			if not self.hecho then
				self.hecho = true
				self:_ocultarAvisos()
				self:_anillo(self.pos, radio, AGUA, 0.4)
				self:_polvo(self.pos, 50, AGUA)
				self:_golpear(function(p)
					return plano(p, self.pos) < radio
				end, self.pos)
			end
		end
	elseif a == "sumergirse" then
		self:_ataqueSumergido(c, { hundir = 4.5, velocidad = 13, radio = 5, color = AGUA })
	elseif a == "rayos" then
		-- las branquias se cargan y caen rayos sobre los cazadores
		self:_lluvia(c, { cuantos = self.fase2 and 7 or 4, radio = 3, color = RAYO, alto = 30 })
		local d = self.datosAtaque
		if fase == "activo" and not d.rayosHechos then
			d.rayosHechos = true
			for _, p in d.puntos or {} do
				rayo(self, p)
			end
		end
	end
	return true
end

-- ---------- regeneración, tormenta y partes ----------
function def.paso(self, dt)
	-- las puntas de las branquias brillan más cuando va a llamar rayos
	local cargando = self.estado == "ataque" and self.ataque == "rayos" and self.fase == "prep"
	for _, x in self.grupos.puntas or {} do
		if x[1].Transparency < 1 then
			x[1].Transparency = cargando and (0.1 * math.sin(self.reloj * 30) + 0.1) or 0
		end
	end
	if self.muerto then
		return
	end
	-- regeneración: si nadie lo golpea en 6 segundos se va curando
	if self.alerta and self.tSinGolpes > 6 and self.vida < self.vidaMax then
		local ritmo = self.partes.branquias.rota and 0.0015 or 0.0035
		self:_curar(self.vidaMax * ritmo * dt)
		self.tNumeroCura = (self.tNumeroCura or 0) - dt
		if self.tNumeroCura <= 0 then
			self.tNumeroCura = 1
			self.servicios.numero(self.raiz.Position + Vector3.new(0, 14, 0), "+" .. math.floor(self.vidaMax * ritmo), rgb(120, 255, 140))
		end
	end
	-- Tormenta de Tláloc: rayos sueltos sobre los cazadores
	local aviso = self.avisoTormenta
	if self.fase2 and self.alerta and not self.partes.branquias.rota then
		self.tTormenta = (self.tTormenta or 4) - dt
		if self.tTormenta <= 0 and not self.puntoTormenta then
			local js = {}
			for _, j in self:jugadores() do
				if j.atacable then
					table.insert(js, j)
				end
			end
			if #js > 0 then
				self.puntoTormenta = self:suelo(js[math.random(1, #js)].hrp.Position)
				self.tCaida = 1.3
				aviso.Size = Vector3.new(0.3, 3.2 * 2 * S, 3.2 * 2 * S)
				aviso.CFrame = CFrame.new(self.puntoTormenta + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
				aviso.Transparency = 0.4
			end
			self.tTormenta = math.random(50, 75) / 10
		end
	end
	if self.puntoTormenta then
		self.tCaida -= dt
		aviso.Transparency = 0.35 + 0.25 * math.sin(self.reloj * 14)
		if self.tCaida <= 0 then
			local p = self.puntoTormenta
			self.puntoTormenta = nil
			aviso.Transparency = 1
			rayo(self, p)
			local d = self.def.ataques.tormenta
			for _, j in self:jugadores() do
				if j.atacable and plano(j.hrp.Position, p) < 3.2 then
					self.servicios.danio(j.jugador, d.danio, p, d.empuje, "xolotl_tormenta")
				end
			end
		end
	end
end

function def.alFase2(self)
	for _, x in self.grupos.manchas or {} do
		x[1].Transparency = 0
		x[1].Color = rgb(190, 250, 255)
	end
	if not self.partes.branquias.rota then
		workspace:SetAttribute("TormentaTlaloc", true)
	end
end

-- calma la tormenta: sin rayo pendiente, sin círculo amarillo y con el cielo normal
local function calmar(self)
	self.puntoTormenta = nil
	if self.avisoTormenta then
		self.avisoTormenta.Transparency = 1
	end
	if workspace:GetAttribute("TormentaTlaloc") then
		workspace:SetAttribute("TormentaTlaloc", false)
	end
end

function def.alReiniciar(self)
	calmar(self)
	self.tTormenta = 4
end

function def.alMorir(self)
	calmar(self)
end

function def.alRomper(self, id)
	if id == "branquias" then
		self.servicios.anunciar("¡Xolotl ya no puede llamar a la tormenta!", def.colorTexto)
		calmar(self)
	elseif id == "aleta" then
		self.servicios.anunciar("¡Sin aleta ya no puede sumergirse!", def.colorTexto)
	end
end

-- la panza queda expuesta justo al salir del agua
function def.debil(self, z)
	return self.estado == "ataque" and self.ataque == "sumergirse" and self.fase == "rec"
end

local Xolotl = {}
function Xolotl.nuevo(servicios)
	return Base.nuevo(def, servicios)
end
Xolotl.def = def
return Xolotl
