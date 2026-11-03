--!nonstrict
-- Cipactli, el Caimán de la Creación (elemento Abismo): el monstruo primordial de los mexicas.
-- Un caimán colosal con placas en el lomo que brillan con la luz del abismo y bocas en los codos y
-- las rodillas. Ataques: embestida con mordida, giro mortal, coletazo, se esconde en el barro y
-- sale mordiendo bajo tus pies y hace brotar géiseres de lodo que frenan. Con las Fauces de la
-- Creación (fase 2) se abren sus bocas y muerden a los lados.
-- Partes: placas del lomo, mandíbula (sus mordidas pegan menos) y cola (coletazo más corto).
local Base = require(script.Parent.BehemothSelva)

local V, CF = Base.V, Base.CF
local S = Base.S
local plano = Base.plano
local rgb = Color3.fromRGB

local PIEL = rgb(36, 52, 42)
local PIEL2 = rgb(50, 68, 54)
local OSCURO = rgb(22, 30, 26)
local VIENTRE = rgb(150, 146, 104)
local PLACA = rgb(28, 36, 32)
local BRILLO = rgb(40, 230, 190)
local BOCA = rgb(120, 24, 36)
local DIENTE = rgb(236, 228, 200)
local OJO = rgb(60, 255, 210)
local LODO = rgb(96, 76, 52)

local def = {
	nombre = "Cipactli", modelo = "Cipactli", zona = "pantano", prefijo = "cipactli_",
	vidaBase = 10200, derriboMax = 320, velVagar = 3.0, velPerseguir = 6.0, distanciaCerca = 8,
	colorTexto = rgb(70, 230, 190), colorPolvo = LODO,
	textoFase2 = "¡Fauces de la Creación! Se abren las bocas de Cipactli",
	radioIsla = 92,
	evitar = { { 0, -82, 24 } }, -- el templo doble
	ataques = {
		embestida = { prep = 0.9, activo = 0.5, rec = 0.9, danio = 28, empuje = 18 },
		giro = { prep = 1.1, activo = 1.2, rec = 1.1, danio = 22, empuje = 20 },
		coletazo = { prep = 0.8, activo = 0.4, rec = 0.9, danio = 24, empuje = 18 },
		emboscada = { prep = 0.8, activo = 2.2, rec = 0.9, danio = 32, empuje = 16 },
		geiseres = { prep = 1.3, activo = 0.4, rec = 0.8, danio = 16, empuje = 10 },
		fauces = { prep = 0.7, activo = 0.3, rec = 0.8, danio = 22, empuje = 10 },
	},
	partes = {
		placas = { nombre = "Placas del lomo", max = 460 },
		mandibula = { nombre = "Mandíbula", max = 420 },
		cola = { nombre = "Cola", max = 420 },
	},
	ordenPartes = { "placas", "mandibula", "cola" },
	zonas = {
		{ nombre = "hocico", tipo = "cabeza", parte = "mandibula", pos = Vector3.new(0, 1.5, -7.2), r = 1.3 },
		{ nombre = "cabeza", tipo = "cabeza", parte = "", pos = Vector3.new(0, 1.9, -4.3), r = 1.5 },
		{ nombre = "lomo_d", tipo = "cuerpo", parte = "placas", pos = Vector3.new(0.7, 2.9, -1.2), r = 1.5 },
		{ nombre = "lomo_t", tipo = "cuerpo", parte = "placas", pos = Vector3.new(-0.7, 2.9, 1.4), r = 1.5 },
		{ nombre = "torso", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 1.6, 0), r = 2.0 },
		{ nombre = "vientre", tipo = "cuerpo", parte = "", pos = Vector3.new(0, 0.8, 0), r = 1.6 },
		{ nombre = "pata_di", tipo = "pata", parte = "", pos = Vector3.new(-3.3, 0.6, -2.1), r = 1.0 },
		{ nombre = "pata_dd", tipo = "pata", parte = "", pos = Vector3.new(3.3, 0.6, -2.1), r = 1.0 },
		{ nombre = "pata_ti", tipo = "pata", parte = "", pos = Vector3.new(-3.3, 0.6, 2.0), r = 1.0 },
		{ nombre = "pata_td", tipo = "pata", parte = "", pos = Vector3.new(3.3, 0.6, 2.0), r = 1.0 },
		{ nombre = "cola1", tipo = "cola", parte = "", pos = Vector3.new(0, 1.5, 6.0), r = 1.3 },
		{ nombre = "cola2", tipo = "cola", parte = "cola", pos = Vector3.new(0, 1.5, 8.0), r = 1.1 },
		{ nombre = "cola3", tipo = "cola", parte = "cola", pos = Vector3.new(0, 1.5, 10.0), r = 0.9 },
	},
	patrulla = { Vector2.new(10, -30), Vector2.new(45, -40), Vector2.new(-40, -30), Vector2.new(40, 30), Vector2.new(-35, 40), Vector2.new(0, 5), Vector2.new(60, 0), Vector2.new(-60, 0) },
	recompensa = {
		monedas = 440, base = "escama_cip", nombreBase = "Escamas primordiales",
		partes = { placas = { "placa_cip", "Placas del lomo" }, mandibula = { "diente_cip", "Dientes de Cipactli" }, cola = { "cola_cip", "Colas del caimán" } },
	},
}

-- ---------- cuerpo ----------
function def.construir(self)
	local raiz = self.raiz
	local torso = self:_parte({ Name = "Torso", Size = V(3.6, 1.9, 6.0), Color = PIEL, CanCollide = true })
	self:_unir(torso, raiz, CF(0, 1.6, 0), nil, "RaizCuerpo")
	self:_pieza(torso, "Lomo", V(3.2, 0.35, 5.6), PIEL2, CF(0, 1.1, 0))
	self:_pieza(torso, "Vientre", V(3.2, 0.4, 5.6), VIENTRE, CF(0, -1.0, 0))
	for _, lado in { -1, 1 } do
		self:_pieza(torso, "Costado", V(0.25, 1.0, 5.4), OSCURO, CF(lado * 1.88, 0.1, 0))
	end
	-- placas del lomo (osteodermos) con grietas que brillan con la luz del abismo
	for fila = -1, 1, 2 do
		for i = 0, 4 do
			local z = -2.3 + i * 1.15
			local placa = self:_pieza(torso, "Placa", V(1.0, 0.5, 1.0), PLACA, CF(fila * 0.65, 1.5, z))
			self:_grupo("placas", placa)
			self:_grupo("placas", self:_pieza(placa, "Cresta", V(0.4, 0.35, 0.7), OSCURO, CF(0, 0.4, 0)))
			self:_grupo("placas", self:_pieza(placa, "Grieta", V(1.04, 0.08, 0.12), BRILLO, CF(0, 0.05, -0.45), { Neon = true }))
		end
	end
	self:_grupo("brillos", self:_pieza(torso, "Espina", V(0.25, 0.1, 5.2), BRILLO, CF(0, 1.33, 0), { Neon = true, Transparency = 0.3 }))
	-- ---------- cabeza y hocico largo ----------
	local cabeza = self:_parte({ Name = "Cabeza", Size = V(2.6, 1.4, 2.4), Color = PIEL })
	self:_unir(cabeza, torso, CF(0, 0.2, -3.0), CF(0, 0, 1.1), "Cuello")
	local hocico = self:_pieza(cabeza, "Hocico", V(2.0, 0.85, 3.6), PIEL2, CF(0, -0.15, -2.9))
	self:_pieza(hocico, "Punta", V(2.2, 0.7, 0.8), PIEL, CF(0, 0.05, -1.9))
	for _, lado in { -1, 1 } do
		self:_pieza(hocico, "Fosa", V(0.35, 0.3, 0.35), OSCURO, CF(lado * 0.45, 0.5, -1.9))
		local ceja = self:_pieza(cabeza, "Ceja", V(0.7, 0.55, 0.7), PIEL2, CF(lado * 0.8, 0.85, -0.6))
		self:_pieza(ceja, "Ojo", V(0.5, 0.25, 0.25), OJO, CF(0, 0.05, -0.33), { Neon = true })
		-- dientes de arriba
		for k = 0, 4 do
			self:_grupo("mandibula", self:_pieza(hocico, "Diente", V(0.18, 0.45, 0.18), DIENTE, CF(lado * 0.92, -0.55, -1.5 + k * 0.7)))
		end
	end
	local mandibula = self:_parte({ Name = "Mandibula", Size = V(2.0, 0.55, 5.4), Color = VIENTRE })
	self:_unir(mandibula, cabeza, CF(0, -0.85, 0.8), CF(0, 0, 2.7), "Mandibula")
	self:_pieza(mandibula, "Encia", V(1.8, 0.2, 5.0), BOCA, CF(0, 0.3, 0))
	for _, lado in { -1, 1 } do
		for k = 0, 4 do
			self:_grupo("mandibula", self:_pieza(mandibula, "Diente", V(0.18, 0.4, 0.18), DIENTE, CF(lado * 0.85, 0.45, -2.2 + k * 0.85)))
		end
	end
	-- ---------- patas abiertas, con una boca en cada codo y rodilla ----------
	for _, lado in { -1, 1 } do
		for _, delante in { true, false } do
			local L = (delante and "D" or "T") .. (lado < 0 and "I" or "D")
			local brazo = self:_parte({ Name = "Pata" .. L, Size = V(1.7, 0.75, 0.9), Color = PIEL2 })
			self:_unir(brazo, torso, CF(lado * 1.7, -0.45, delante and -2.0 or 2.1) * CFrame.Angles(0, 0, -lado * 0.2), CF(-lado * 0.85, 0, 0), "Pata" .. L)
			local pierna = self:_parte({ Name = "Pierna" .. L, Size = V(0.8, 0.9, 0.8), Color = PIEL })
			self:_unir(pierna, brazo, CF(lado * 0.85, 0, 0) * CFrame.Angles(0, 0, lado * 0.2), CF(0, 0.35, 0), "Rodilla" .. L)
			local pie = self:_pieza(pierna, "Pie", V(1.3, 0.3, 1.2), OSCURO, CF(lado * 0.1, -0.45, -0.2))
			for d = -1, 1 do
				self:_pieza(pie, "Garra", V(0.18, 0.2, 0.5), DIENTE, CF(d * 0.4, -0.05, -0.75))
			end
			-- la boca del codo: dientes y una garganta que brilla en la fase 2
			local boca = self:_pieza(pierna, "BocaCodo", V(0.9, 0.5, 0.5), OSCURO, CF(lado * 0.2, 0.35, -0.55))
			self:_grupo("bocas", self:_pieza(boca, "Garganta", V(0.6, 0.18, 0.1), BOCA, CF(0, 0, -0.26)))
			for d = -1, 1, 2 do
				self:_pieza(boca, "Diente", V(0.12, 0.2, 0.08), DIENTE, CF(d * 0.25, 0.12, -0.28))
				self:_pieza(boca, "Diente", V(0.12, 0.2, 0.08), DIENTE, CF(d * 0.12, -0.12, -0.28))
			end
		end
	end
	-- ---------- cola larga con dos filas de crestas ----------
	local padre, z0 = torso, 3.0
	local tamanos = { { 2.6, 1.6, 2.0 }, { 2.1, 1.4, 2.0 }, { 1.6, 1.2, 2.0 }, { 1.1, 0.95, 2.0 }, { 0.7, 0.65, 2.0 } }
	for i, t in tamanos do
		local seg = self:_parte({ Name = "Cola" .. i, Size = V(t[1], t[2], t[3]), Color = i % 2 == 0 and PIEL2 or PIEL })
		self:_unir(seg, padre, CF(0, i == 1 and -0.1 or 0, z0), CF(0, 0, -t[3] / 2), "Cola" .. i)
		local grupo = i >= 3 and "cola" or nil
		if grupo then
			self:_grupo(grupo, seg)
		end
		for _, lado in (i <= 3 and { -1, 1 } or { 0 }) do
			local cresta = self:_pieza(seg, "Cresta", V(0.3, 0.45, 1.4), OSCURO, CF(lado * t[1] * 0.25, t[2] / 2 + 0.2, 0))
			if grupo then
				self:_grupo(grupo, cresta)
			end
		end
		local brillo = self:_pieza(seg, "Brillo", V(0.15, 0.08, 1.6), BRILLO, CF(0, t[2] / 2 + 0.02, 0), { Neon = true, Transparency = 0.3 })
		self:_grupo(grupo or "brillos", brillo)
		if grupo then
			self:_grupo("brillos", brillo)
		end
		self:_pieza(seg, "VientreCola", V(t[1] * 0.85, 0.15, t[3]), VIENTRE, CF(0, -t[2] / 2 - 0.05, 0))
		padre, z0 = seg, t[3] / 2
	end
end

function def.ocultarExtras(self) end

-- ---------- qué ataque elegir ----------
function def.elegir(self, dist, ang, o)
	local mandibula = not self.partes.mandibula.rota
	if dist > 5 and dist < 15 and ang < 0.4 then
		o("embestida", mandibula and 2.6 or 1.6)
	end
	if dist < 9 then
		o("giro", self:_hace("giro") > 10 and 1.3 or 0.1)
	end
	if dist < 11 and ang > 1.7 then
		o("coletazo", 3)
	end
	if dist > 10 and self:_hace("emboscada") > 9 then
		o("emboscada", 1.8)
	end
	if dist < 30 and self:_hace("geiseres") > 10 then
		o("geiseres", self.fase2 and 2 or 1.2)
	end
	if self.fase2 and dist < 9 and ang > 0.6 and ang < 2.4 then
		o("fauces", 2.4) -- alguien a su lado
	end
end

-- ---------- ataques ----------
function def.atacar(self, a, c)
	local fase, tf, dt = self.fase, c.tf, c.dt
	local adelante, objetivo = c.adelante, c.objetivo
	local d = self.datosAtaque
	local fuerzaBoca = self.partes.mandibula.rota and 0.75 or 1
	if a == "embestida" then
		-- se lanza hacia adelante con las fauces abiertas
		local largo = 13
		if fase == "prep" then
			if tf < c.prep - 0.45 then
				self:_girarHacia(self:_yawHacia(objetivo), 1.6, dt)
			end
			d.desde = self.pos
			self:_avisoRect(self.pos + adelante * 4 * S, self.yaw, 4.5, largo)
		elseif fase == "activo" then
			self:_ocultarAvisos()
			local k = math.clamp(tf / c.act, 0, 1)
			self:_ponerEn(d.desde + adelante * 9 * S * (1 - (1 - k) * (1 - k)))
			local boca = self.pos + adelante * 6 * S
			self:_golpear(function(p)
				return plano(p, boca) < 3.4 or plano(p, self.pos + adelante * 3 * S) < 2.6
			end, boca, fuerzaBoca)
		elseif not self.hecho then
			self.hecho = true
			self:_polvo(self.pos + adelante * 6 * S, 30)
		end
	elseif a == "giro" then
		-- el giro de la muerte: rueda sobre sí mismo arrastrando todo alrededor
		local radio = 7
		if fase == "prep" then
			self:_avisoCirculo(self.pos, radio)
		elseif fase == "activo" then
			if not self.hecho then
				self.hecho = true
				self:_ocultarAvisos()
				self:_anillo(self.pos, radio, LODO, 0.5)
			end
			d.polvo = (d.polvo or 0) - dt
			if d.polvo <= 0 then
				d.polvo = 0.3
				self:_polvo(self.pos, 20)
			end
			if tf < 0.5 then
				self:_golpear(function(p)
					return plano(p, self.pos) < radio
				end, self.pos)
			end
		end
	elseif a == "coletazo" then
		local radio = self.partes.cola.rota and 4.2 or 6.4
		local centro = self.pos - adelante * 8 * S
		if fase == "prep" then
			self:_avisoCirculo(centro, radio)
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			self:_anillo(centro, radio, LODO, 0.35)
			self:_polvo(centro, 40)
			self:_golpear(function(p)
				return plano(p, centro) < radio
			end, centro)
		end
	elseif a == "emboscada" then
		-- se hunde en el barro y sale mordiendo bajo tus pies
		self:_ataqueSumergido(c, { hundir = 3.2, velocidad = 12, radio = 4.8, color = LODO, mult = fuerzaBoca })
	elseif a == "geiseres" then
		-- brotan géiseres de lodo: golpean y dejan a los cazadores frenados un momento
		self:_lluvia(c, {
			cuantos = self.fase2 and 6 or 3, radio = 3.2, color = LODO, alto = 9,
			alGolpear = function(b, j)
				b:_frenarCazador(j, 2.5)
			end,
		})
	elseif a == "fauces" then
		-- las bocas de los costados muerden a los que están a su lado
		local derecha = Vector3.new(-adelante.Z, 0, adelante.X)
		local puntos = { self.pos + derecha * 3.8 * S, self.pos - derecha * 3.8 * S }
		if fase == "prep" then
			self:_avisosVarios({ { puntos[1], 3.2 }, { puntos[2], 3.2 } })
		elseif fase == "activo" and not self.hecho then
			self.hecho = true
			self:_ocultarAvisos()
			for _, p in puntos do
				self:_polvo(p, 15, BOCA)
			end
			self:_golpear(function(p)
				return plano(p, puntos[1]) < 3.2 or plano(p, puntos[2]) < 3.2
			end, self.pos, fuerzaBoca)
		end
	end
	return true
end

-- ---------- fase 2 y partes ----------
function def.alFase2(self)
	for _, x in self.grupos.bocas or {} do
		x[1].Color = rgb(255, 120, 60)
		x[1].Material = Enum.Material.Neon
	end
	for _, x in self.grupos.brillos or {} do
		if x[1].Transparency < 1 then
			x[1].Transparency = 0
			x[1].Color = rgb(120, 255, 220)
		end
	end
end

function def.alReiniciar(self)
	for _, x in self.grupos.bocas or {} do
		x[1].Material = Enum.Material.SmoothPlastic
	end
end

function def.alRomper(self, id)
	if id == "mandibula" then
		self.servicios.anunciar("¡Sus mordidas pierden fuerza!", def.colorTexto)
	elseif id == "placas" then
		self.servicios.anunciar("¡El lomo de Cipactli quedó expuesto!", def.colorTexto)
	end
end

-- mareado después del giro de la muerte: todo su cuerpo queda expuesto
function def.debil(self, z)
	return self.estado == "ataque" and self.ataque == "giro" and self.fase == "rec"
end

local Cipactli = {}
function Cipactli.nuevo(servicios)
	return Base.nuevo(def, servicios)
end
Cipactli.def = def
return Cipactli
