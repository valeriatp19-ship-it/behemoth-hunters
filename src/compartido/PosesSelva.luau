--!nonstrict
-- Ayudas para armar y animar extremidades largas (alas, brazos, colas) a partir de direcciones.
-- Cada hueso cuelga a lo largo de su -Y desde su articulación. Se dice hacia dónde apunta cada
-- hueso en el espacio del cuerpo y hacia dónde queda su borde de atrás (donde va la membrana),
-- y esto calcula el C0 de cada articulación. Lo usan el servidor (pose inicial) y el cliente.
local P = {}

-- Rotación cuyo -Y apunta a d y cuyo +Z queda lo más cerca posible de "atras".
function P.orientar(d: Vector3, atras: Vector3): CFrame
	local y = -d.Unit
	local x = y:Cross(atras)
	if x.Magnitude < 1e-4 then
		x = y:Cross(Vector3.new(0, 0, 1))
		if x.Magnitude < 1e-4 then
			x = Vector3.new(1, 0, 0)
		end
	end
	x = x.Unit
	local z = x:Cross(y)
	return CFrame.fromMatrix(Vector3.zero, x, y, z)
end

-- huesos: lista ordenada de { nombre, padre (índice o 0 = cuerpo), pos (articulación en la pieza
-- padre, studs), dir (espacio del cuerpo), atras (espacio del cuerpo) }.
-- Devuelve { [nombre] = C0 }.
function P.cadena(huesos)
	local rot = { [0] = CFrame.new() }
	local c0 = {}
	for i, h in huesos do
		local r = P.orientar(h.dir, h.atras)
		rot[i] = r
		c0[h.nombre] = CFrame.new(h.pos) * (rot[h.padre]:Inverse() * r)
	end
	return c0
end

-- mezcla de dos direcciones (las normaliza)
function P.mezclar(a: Vector3, b: Vector3, k: number): Vector3
	local v = a:Lerp(b, k)
	return v.Magnitude > 1e-4 and v.Unit or a
end

-- refleja una dirección del lado derecho al izquierdo
function P.espejo(v: Vector3): Vector3
	return Vector3.new(-v.X, v.Y, v.Z)
end

-- ---------- Camazotz: las alas ----------
-- Direcciones del lado derecho, en el espacio del torso. { dirección, borde de atrás }
local v = Vector3.new
P.CAMAZOTZ = {
	hombro = v(1.45, 0.7, -1.2), -- metros, en el torso
	largos = { Brazo = 2.8, Antebrazo = 6.5, Mano = 0.9, Dedo1 = 4.4, Dedo2 = 5.0, Dedo3 = 4.0 },
	-- plegada: camina apoyado en las muñecas, con los codos por encima de la espalda
	plegada = {
		Brazo = { v(0.45, 0.88, -0.15), v(0, 0, 1) },
		Antebrazo = { v(0.06, -0.997, 0.05), v(0, 0, 1) },
		Mano = { v(0, -0.5, -0.85), v(0, 1, 0) },
		Dedo1 = { v(0.1, 0.99, -0.12), v(0, 0, 1) },
		Dedo2 = { v(0.16, 0.98, 0.02), v(0, 0, 1) },
		Dedo3 = { v(0.22, 0.95, 0.18), v(0, -0.2, 1) },
	},
	-- abierta: las alas extendidas (vuelo, grito, enjambre)
	abierta = {
		Brazo = { v(0.8, 0.32, 0.5), v(0, 0, 1) },
		Antebrazo = { v(0.95, 0.2, -0.24), v(0, 0, 1) },
		Mano = { v(0.95, 0.2, -0.24), v(0, 0, 1) },
		Dedo1 = { v(0.96, 0.18, -0.12), v(0, 0, 1) },
		Dedo2 = { v(0.76, 0.12, 0.62), v(0, 0, 1) },
		Dedo3 = { v(0.3, 0.06, 0.95), v(0, 0, 1) },
	},
	-- membranas de cada dedo: { alto relativo (0 = base, 1 = punta), ancho en metros }
	membranas = {
		Dedo1 = { { 0.17, 1.0 }, { 0.5, 2.3 }, { 0.83, 3.3 } },
		Dedo2 = { { 0.17, 0.9 }, { 0.5, 2.0 }, { 0.83, 2.8 } },
		Dedo3 = { { 0.17, 2.6 }, { 0.5, 2.6 }, { 0.83, 2.0 } },
	},
}

-- Ángulo con que se pliegan las membranas de los dedos (giran hacia la punta del dedo).
function P.pliegueCamazotz(abrir: number): number
	return (1 - abrir) * 1.25
end

-- C0 de la bisagra de una membrana de dedo (en la pieza del dedo).
function P.membranaCamazotz(largoDedo: number, alto: number, abrir: number, S: number): CFrame
	return CFrame.new(0, (0.5 - alto) * largoDedo * S, 0.15 * S) * CFrame.Angles(P.pliegueCamazotz(abrir), 0, 0)
end

-- C0 de las articulaciones de un ala. abrir: 0 plegada .. 1 abierta.
-- extra (opcional): { [hueso] = vector que se suma a su dirección } para pasos y aleteos.
function P.alaCamazotz(lado: number, abrir: number, extra, S: number)
	local C = P.CAMAZOTZ
	local L = lado < 0 and "I" or "D"
	local function dir(h)
		local a, b = C.plegada[h], C.abierta[h]
		local d = P.mezclar(a[1], b[1], abrir)
		local atras = P.mezclar(a[2], b[2], abrir)
		if extra and extra[h] then
			d = (d + extra[h]).Unit
		end
		if lado < 0 then
			d, atras = P.espejo(d), P.espejo(atras)
		end
		return d, atras
	end
	local huesos = {}
	local function hueso(nombre, padre, pos, h)
		local d, atras = dir(h)
		table.insert(huesos, { nombre = nombre .. L, padre = padre, pos = pos * S, dir = d, atras = atras })
	end
	local hombro = C.hombro
	hueso("Hombro", 0, v(hombro.X * lado, hombro.Y, hombro.Z), "Brazo")
	hueso("Codo", 1, v(0, -C.largos.Brazo / 2, 0), "Antebrazo")
	hueso("Muneca", 2, v(0, -C.largos.Antebrazo / 2, 0), "Mano")
	hueso("Dedo1", 3, v(0, 0.3, 0), "Dedo1")
	hueso("Dedo2", 3, v(0, 0.3, 0), "Dedo2")
	hueso("Dedo3", 3, v(0, 0.3, 0), "Dedo3")
	return P.cadena(huesos)
end

return P
