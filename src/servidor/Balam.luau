--!nonstrict
-- Balam, el Jaguar de Obsidiana (elemento Obsidiana): el jaguar sagrado de la selva maya.
-- Pelaje negro como la obsidiana, manchas de jade, púas de vidrio volcánico en el lomo.
-- Ataques: zarpazo y mordida que hacen sangrar, salto sobre su presa, carrera en zigzag, rugido
-- que aturde y coletazo. Herido (fase 2) se camufla entre la selva: casi no se ve.
-- Partes: garras (el zarpazo ya no hace sangrar), colmillos (la mordida tampoco) y cola.
local Base = require(script.Parent.BehemothSelva)

local V, CF = Base.V, Base.CF
local S = Base.S
local plano = Base.plano
local rgb = Color3.fromRGB

local PELO = rgb(22, 19, 30)
local PELO2 = rgb(36, 32, 48)
local VIENTRE = rgb(56, 50, 70)
local OBSIDIANA = rgb(12, 10, 18)
local VIOLETA = rgb(160, 96, 255)
local JADE = rgb(40, 230, 150)
local JADE2 = rgb(24, 150, 100)
local ORO = rgb(232, 178, 60)
local OJO = rgb(190, 255, 110)
local NARIZ = rgb(60, 36, 46)

local def = {
	nombre = "Balam", modelo = "Balam", zona = "selva", prefijo = "balam_",
	vidaBase = 10200, derriboMax = 300, velVagar = 3.8, velPerseguir = 7.4, distanciaCerca = 6.5,
	colorTexto = rgb(80, 230, 160), colorPolvo = rgb(70, 64, 60),
	textoFase2 = "¡Camuflaje de jade! Balam se funde con la selva",
	radioIsla = 92,
	ataques = {
		zarpazo = { prep = 0.6, activo = 0.25, rec = 0.7, danio = 24, empuje = 12 },
		mordida = { prep = 0.7, activo = 0.25, rec = 0.8, danio = 26, empuje = 8 },
		salto = { prep = 0.8, activo = 0.8, rec = 0.9, danio = 30, empuje = 16 },
		zigzag = { prep = 0.8, activo = 1.8, rec = 0.8, danio = 22, empuje = 14 },
		rugido = { prep = 0.9, activo = 0.5, rec = 0.8, danio = 14, empuje = 14 },
		coletazo = { prep = 0.7, activo = 0.35, rec = 0.8, danio = 22, empuje = 16 },
	},
	partes = {
		garras = { nombre = "Garras", max = 400 },
		colmillos = { nombre = "Colmillos", max = 380 },
		cola = { nombre = "Cola", max = 360 },
	},
	ordenPartes = { "garras", "colmillos", "cola" },
	zonas = {
		{ nombre = "hocico", tipo = "cabeza", parte = "colmillos", pos = Vector3.new(0, 3.9, -5.2), r = 1.1 },
		{ nombre = "cabeza", tipo = "cabeza", parte = "", pos = Vector3.new(0, 4.3, -3.8), r = 1.5 },
		{ nombre = "pecho", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 2.9, -2.2), r = 1.6 },
		{ nombre = "torso", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 3.0, 0.3), r = 1.9 },
		{ nombre = "vientre", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.8, 0.4), r = 1.5 },
		{ nombre = "pata_di", tipo = "pata", parte = "garras", pos = Vector3.new(-1.15, 0.8, -2.1), r = 1.0 },
		{ nombre = "pata_dd", tipo = "pata", parte = "garras", pos = Vector3.new(1.15, 0.8, -2.1), r = 1.0 },
		{ nombre = "pata_ti", tipo = "pata", parte = "", pos = Vector3.new(-1.15, 1.2, 1.8), r = 1.1 },
		{ nombre = "pata_td", tipo = "pata", parte = "", pos = Vector3.new(1.15, 1.2, 1.8), r = 1.1 },
		{ nombre = "cola1", tipo = "cola", parte = "cola", pos = Vector3.new(0, 2.6, 5.0), r = 1.0 },
		{ nombre = "cola2", tipo = "cola", parte = "cola", pos = Vector3.new(0, 2.5, 7.0), r = 0.9 },
	},
	evitar = { { 0, -84, 24 }, { -12, 34, 5 }, { 12, 34, 5 } }, -- el templo del jaguar y sus estatuas
	patrulla = { Vector2.new(0, -40), Vector2.new(45, -25), Vector2.new(-45, -20), Vector2.new(35, 35), Vector2.new(-40, 40), Vector2.new(0, 10), Vector2.new(60, 0), Vector2.new(-60, -5) },
	recompensa = {
		monedas = 420, base = "pelo_jag", nombreBase = "Pieles de jaguar",
		partes = { garras = { "garra_obs", "Garras de obsidiana" }, colmillos = { "colmillo_jade", "Colmillos de jade" }, cola = { "cola_balam", "Colas de Balam" } },
	},
}

-- ---------- cuerpo ----------
function def.construir(self)
	local raiz = self.raiz
	local torso = self:_parte({ Name = "Torso", Size = V(2.8, 2.4, 5.2), Color = PELO, CanCollide = true })
	self:_unir(torso, raiz, CF(0, 3.0, 0.2) * CFrame.Angles(0.06, 0, 0), nil, "RaizCuerpo")
	self:_pieza(torso, "Lomo", V(2.4, 0.4, 4.6), PELO2, CF(0, 1.25, 0.1))
	self:_pieza(torso, "Pecho", V(3.0, 2.2, 1.6), PELO, CF(0, -0.2, -2.3))
	self:_pieza(torso, "Vientre", V(2.2, 0.4, 4.0), VIENTRE, CF(0, -1.25, 0.2))
	-- collar maya de oro con una placa de jade
	self:_pieza(torso, "Collar", V(3.2, 0.5, 0.6), ORO, CF(0, 0.6, -3.05))
	self:_pieza(torso, "PlacaJade", V(0.8, 0.8, 0.2), JADE2, CF(0, 0.1, -3.2))
	self:_pieza(torso, "GemaJade", V(0.4, 0.4, 0.1), JADE, CF(0, 0.1, -3.32), { Neon = true })
	-- púas de obsidiana en el lomo, con el filo violeta
	for i, alto in { 0.9, 1.3, 1.5, 1.2, 0.8 } do
		local z = -1.9 + (i - 1) * 0.95
		local pua = self:_pieza(torso, "Pua", V(0.45, alto, 0.6), OBSIDIANA, CF(0, 1.4 + alto / 2, z) * CFrame.Angles(-0.35, 0, 0))
		self:_pieza(pua, "Filo", V(0.12, alto * 0.9, 0.62), VIOLETA, CF(0, 0, 0), { Neon = true, Transparency = 0.2 })
	end
	-- manchas (rosetas) de jade: brillan más cuando se camufla
	local manchas = { { -1.42, 0.5, -1.5 }, { -1.42, -0.3, -0.4 }, { -1.42, 0.6, 0.8 }, { -1.42, -0.2, 1.8 }, { 1.42, 0.4, -1.2 }, { 1.42, -0.4, 0.1 }, { 1.42, 0.5, 1.3 }, { 1.42, -0.3, 2.1 } }
	for _, m in manchas do
		local lado = m[1] < 0 and -1 or 1
		self:_grupo("rosetas", self:_pieza(torso, "Roseta", V(0.1, 0.5, 0.5), JADE, CF(m[1] + lado * 0.03, m[2], m[3]), { Neon = true, Transparency = 0.45 }))
		self:_pieza(torso, "RosetaBorde", V(0.08, 0.7, 0.7), JADE2, CF(m[1], m[2], m[3]))
	end
	for _, m in { { -0.6, -1.0 }, { 0.5, 0.0 }, { -0.5, 1.2 }, { 0.6, 2.0 } } do
		self:_grupo("rosetas", self:_pieza(torso, "Roseta", V(0.5, 0.1, 0.5), JADE, CF(m[1], 1.47, m[2]), { Neon = true, Transparency = 0.45 }))
	end
	-- ---------- cabeza ----------
	local cabeza = self:_parte({ Name = "Cabeza", Size = V(2.3, 2.0, 2.3), Color = PELO })
	self:_unir(cabeza, torso, CF(0, 0.7, -3.0), CF(0, -0.3, 1.0), "Cuello")
	self:_pieza(cabeza, "Frente", V(2.0, 0.4, 1.8), PELO2, CF(0, 1.05, 0.1))
	local hocico = self:_pieza(cabeza, "Hocico", V(1.5, 1.0, 1.1), PELO2, CF(0, -0.35, -1.5))
	self:_pieza(hocico, "Nariz", V(0.7, 0.35, 0.3), NARIZ, CF(0, 0.35, -0.5))
	for _, lado in { -1, 1 } do
		self:_pieza(cabeza, "Ojo", V(0.5, 0.2, 0.1), OJO, CF(lado * 0.55, 0.3, -1.16), { Neon = true })
		self:_pieza(cabeza, "Ceno", V(0.7, 0.2, 0.25), OBSIDIANA, CF(lado * 0.55, 0.5, -1.1) * CFrame.Angles(0, 0, lado * 0.25))
		local oreja = self:_pieza(cabeza, "Oreja", V(0.65, 0.6, 0.3), PELO, CF(lado * 0.8, 1.25, 0.3))
		self:_pieza(oreja, "Arete", V(0.2, 0.35, 0.35), ORO, CF(lado * 0.35, -0.1, 0))
		self:_pieza(oreja, "Interior", V(0.4, 0.35, 0.1), JADE2, CF(0, 0, -0.18))
		self:_grupo("colmillos", self:_pieza(hocico, "Colmillo", V(0.26, 0.8, 0.26), JADE, CF(lado * 0.45, -0.8, -0.35), { Neon = true, Transparency = 0.1 }))
	end
	local mandibula = self:_parte({ Name = "Mandibula", Size = V(1.4, 0.45, 1.5), Color = VIENTRE })
	self:_unir(mandibula, cabeza, CF(0, -0.95, -0.35), CF(0, 0, 0.75), "Mandibula")
	for _, lado in { -1, 1 } do
		self:_grupo("colmillos", self:_pieza(mandibula, "Colmillo", V(0.2, 0.5, 0.2), JADE, CF(lado * 0.4, 0.4, -0.6), { Neon = true, Transparency = 0.1 }))
	end
	self:_pieza(mandibula, "Lengua", V(0.8, 0.1, 1.0), rgb(150, 50, 70), CF(0, 0.25, -0.1))
	-- ---------- patas ----------
	for _, lado in { -1, 1 } do
		local L = lado < 0 and "I" or "D"
		-- delanteras: con garras de obsidiana
		local brazo = self:_parte({ Name = "Brazo" .. L, Size = V(1.0, 1.4, 1.1), Color = PELO })
		self:_unir(brazo, torso, CF(lado * 1.15, -0.55, -2.1), CF(0, 0.6, 0), "Hombro" .. L)
		local ante = self:_parte({ Name = "Antebrazo" .. L, Size = V(0.75, 1.1, 0.85), Color = PELO2 })
		self:_unir(ante, brazo, CF(0, -0.6, 0), CF(0, 0.5, 0), "Codo" .. L)
		local pata = self:_pieza(ante, "Pata", V(1.15, 0.45, 1.3), PELO, CF(0, -0.6, -0.2))
		for k = -1, 1 do
			self:_grupo("garras", self:_pieza(pata, "Garra", V(0.2, 0.3, 0.55), OBSIDIANA, CF(k * 0.35, -0.05, -0.85) * CFrame.Angles(-0.4, 0, 0)))
			self:_grupo("garras", self:_pieza(pata, "FiloGarra", V(0.08, 0.32, 0.56), VIOLETA, CF(k * 0.35, -0.05, -0.85) * CFrame.Angles(-0.4, 0, 0), { Neon = true }))
		end
		-- traseras
		local muslo = self:_parte({ Name = "Muslo" .. L, Size = V(1.2, 1.5, 1.4), Color = PELO })
		self:_unir(muslo, torso, CF(lado * 1.15, -0.5, 1.9) * CFrame.Angles(0.35, 0, 0), CF(0, 0.65, 0), "Cadera" .. L)
		local pierna = self:_parte({ Name = "Pierna" .. L, Size = V(0.75, 1.1, 0.85), Color = PELO2 })
		self:_unir(pierna, muslo, CF(0, -0.7, 0) * CFrame.Angles(-0.9, 0, 0), CF(0, 0.5, 0), "Rodilla" .. L)
		local pie = self:_pieza(pierna, "Pie", V(1.1, 0.45, 1.3), PELO, CF(0, -0.55, -0.3) * CFrame.Angles(0.55, 0, 0))
		for k = -1, 1 do
			self:_pieza(pie, "Una", V(0.18, 0.2, 0.4), OBSIDIANA, CF(k * 0.35, -0.05, -0.75))
		end
	end
	-- ---------- cola: larga, con la punta de obsidiana ----------
	local padre = torso
	for i = 1, 5 do
		local grosor = 0.62 - i * 0.07
		local seg = self:_parte({ Name = "Cola" .. i, Size = V(grosor, grosor, 1.3), Color = i % 2 == 0 and PELO2 or PELO })
		local c0 = i == 1 and (CF(0, 0.7, 2.6) * CFrame.Angles(0.45, 0, 0)) or (CF(0, 0, 0.6) * CFrame.Angles(-0.18, 0, 0))
		self:_unir(seg, padre, c0, CF(0, 0, -0.6), "Cola" .. i)
		if i >= 3 then
			self:_grupo("cola", seg)
		end
		if i % 2 == 1 then
			self:_grupo(i >= 3 and "cola" or "rosetas", self:_pieza(seg, "Anillo", V(grosor + 0.06, 0.25, 0.25), JADE, CF(0, grosor / 2 - 0.08, 0.2), { Neon = true, Transparency = 0.45 }))
		end
		padre = seg
	end
	self:_grupo("cola", self:_pieza(padre, "Punta", V(0.3, 0.3, 0.9), OBSIDIANA, CF(0, 0, 0.95)))
	self:_grupo("cola", self:_pieza(padre, "FiloPunta", V(0.1, 0.32, 0.92), VIOLETA, CF(0, 0, 0.95), { Neon = true }))
end

function def.ocultarExtras(self) end

-- ---------- qué ataque elegir ----------
function def.elegir(self, dist, ang, o)
	if dist < 7 and ang < 0.8 then
		o("zarpazo", 3)
		o("mordida", 2)
	end
	if dist < 8 and ang > 1.8 then
		o("coletazo", 2.6)
	end
	if dist > 9 and dist < 26 and self:_hace("salto") > 4 then
		o("salto", 2.4)
	end
	if dist > 6 and dist < 30 and self:_hace("zigzag") > 9 then
		o("zigzag", self.fase2 and 2 or 1.3)
	end
	if dist < 12 and self:_hace("rugido") > 12 then
		o("rugido", 1.2)
	end
end

-- ---------- ataques ----------
function def.atacar(self, a, c)
	local fase, tf, dt = self.fase, c.tf, c.dt
	local adelante, objetivo = c.adelante, c.objetivo
	local d = self.datosAtaque
	if a == "zarpazo" or a == "mordida" then
		local zarpa = a == "zarpazo"
		local punto = self.pos + adelante * (zarpa and 4.5 or 5.6) * S
		local radio = zarpa and 3.6 or 3
		if fase == "prep" then
			if tf < c.prep - 0.35 then
				self:_girarHacia(self:_yawHacia(objetivo), 3.4, dt)
			end
			self:_avisoCirculo(punto, radio)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_polvo(punto, 18)
			local alcanzados = self:_golpear(function(p)
				return plano(p, punto) < radio
			end, punto)
			-- las garras y los colmillos de obsidiana abren heridas que sangran (solo si el golpe llegó)
			local sangra = zarpa and not self.partes.garras.rota or (not zarpa and not self.partes.colmillos.rota)
			if sangra and alcanzados then
				for _, j in alcanzados do
					self:_sangrar(j, zarpa and 3 or 4, 4)
				end
			end
		end
	elseif a == "salto" then
		-- se agacha, salta en arco y cae sobre su presa
		if fase == "prep" then
			self:_girarHacia(self:_yawHacia(objetivo), 4, dt)
			if tf < c.prep - 0.3 then
				d.desde = self.pos
				d.hasta = self:_limitar(objetivo)
			end
			self:_avisoCirculo(d.hasta or self.pos, 4.5)
		elseif fase == "activo" then
			local k = math.clamp(tf / c.act, 0, 1)
			self:_ponerEn(d.desde:Lerp(d.hasta, k))
			self.altoExtra = math.sin(k * math.pi) * 5 * S
			self.yVisual = self.pos.Y + self.altoExtra
			return false
		elseif not self.hecho then
			self.hecho = true
			self.altoExtra = 0
			self:_ocultarAvisos()
			self:_polvo(self.pos, 50)
			self:_anillo(self.pos, 4.5, rgb(90, 80, 70), 0.35)
			self:_golpear(function(p)
				return plano(p, self.pos) < 4.5
			end, self.pos)
		end
	elseif a == "zigzag" then
		-- tres carreras rapidísimas cambiando de dirección; el camino se marca antes con círculos
		if fase == "prep" then
			if not d.tramos then
				d.tramos = {}
				local desde = self.pos
				local lado = math.random() < 0.5 and -1 or 1
				for i = 1, 3 do
					local haciaPresa = Vector3.new(objetivo.X - desde.X, 0, objetivo.Z - desde.Z)
					local base = haciaPresa.Magnitude > 1 and haciaPresa.Unit or self:_adelante()
					local dir = (CFrame.Angles(0, lado * (i == 3 and 0.15 or 0.6), 0) * CFrame.new(base)).Position.Unit
					local hasta = self:_limitar(desde + dir * 9 * S)
					table.insert(d.tramos, { desde, hasta })
					desde = hasta
					lado = -lado
				end
				local lista = {}
				for _, t in d.tramos do
					table.insert(lista, { t[1]:Lerp(t[2], 0.35), 2.4 })
					table.insert(lista, { t[1]:Lerp(t[2], 0.85), 2.4 })
				end
				self:_avisosVarios(lista)
			end
			self:_girarHacia(self:_yawHacia(d.tramos[1][2]), 6, dt)
		elseif fase == "activo" then
			local cada = c.act / 3
			local i = math.min(3, math.floor(tf / cada) + 1)
			local t = d.tramos[i]
			local k = math.clamp((tf - (i - 1) * cada) / cada, 0, 1)
			self:_ponerEn(t[1]:Lerp(t[2], k))
			self.yaw = self:_yawHacia(t[2]) -- mira hacia donde corre
			if i ~= d.ultimoTramo then
				d.ultimoTramo = i
				self:_polvo(self.pos, 25)
			end
			self:_golpear(function(p)
				return plano(p, self.pos) < 2.6
			end, self.pos)
		elseif not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
		end
	elseif a == "rugido" then
		local radio = 9
		if fase == "prep" then
			self:_avisoCirculo(self.pos, radio)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_anillo(self.pos, radio, JADE, 0.5)
			self:_golpear(function(p)
				return plano(p, self.pos) < radio
			end, self.pos)
			self:_aturdir(self.pos, radio, 1.0)
		end
	elseif a == "coletazo" then
		local radio = self.partes.cola.rota and 3.6 or 5.4
		local centro = self.pos - adelante * 4.5 * S
		if fase == "prep" then
			self:_avisoCirculo(centro, radio)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_anillo(centro, radio, VIOLETA, 0.3)
			self:_golpear(function(p)
				return plano(p, centro) < radio
			end, centro)
		end
	end
	return true
end

-- ---------- fase 2: el camuflaje ----------
function def.paso(self, dt)
	local m = self.modelo
	if not self.fase2 or self.muerto then
		if m:GetAttribute("Camuflaje") then
			m:SetAttribute("Camuflaje", false)
		end
		return
	end
	-- 6 segundos camuflado, 8 a la vista (y siempre visible si está derribado)
	self.tCamuflaje = (self.tCamuflaje or 0) + dt
	local ciclo = self.tCamuflaje % 14
	local camuflado = ciclo < 6 and self.estado ~= "derribado" and self.estado ~= "estremecer"
	if m:GetAttribute("Camuflaje") ~= camuflado then
		m:SetAttribute("Camuflaje", camuflado)
	end
end

function def.alFase2(self)
	self.tCamuflaje = 0
	for _, x in self.grupos.rosetas or {} do
		x[1].Transparency = 0
		x[1].Color = rgb(120, 255, 190)
	end
end

function def.alReiniciar(self)
	self.tCamuflaje = 0
	self.modelo:SetAttribute("Camuflaje", false)
end

function def.alRomper(self, id)
	if id == "garras" then
		self.servicios.anunciar("¡Sus zarpazos ya no hacen sangrar!", def.colorTexto)
	elseif id == "colmillos" then
		self.servicios.anunciar("¡Sus mordidas ya no hacen sangrar!", def.colorTexto)
	end
end

-- recién aterrizado de un salto queda expuesto
function def.debil(self, z)
	return self.estado == "ataque" and self.ataque == "salto" and self.fase == "rec"
end

local Balam = {}
function Balam.nuevo(servicios)
	return Base.nuevo(def, servicios)
end
Balam.def = def
return Balam
