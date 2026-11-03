--!nonstrict
-- Terreno de bloques para cualquier isla: une en un solo bloque las columnas vecinas que tienen
-- la misma altura y el mismo color (así un mapa grande usa pocas piezas).
local Mundo = require(script.Parent.Mundo)

local Terreno = {}

-- centro: centro del mapa (studs); V: tamaño del bloque; N: bloques por lado
-- altura(x, z) -> altura en studs; color(h) -> clave, Color3 (la clave decide qué se une)
function Terreno.construir(carpeta: Folder, centro: Vector3, V: number, N: number, altura, color)
	local ORIGEN = -N * V / 2
	local BASE = centro.Y - 40
	local alto, clave, colores = {}, {}, {}
	for i = 1, N do
		alto[i], clave[i], colores[i] = {}, {}, {}
		for k = 1, N do
			local x = centro.X + ORIGEN + (i - 0.5) * V
			local z = centro.Z + ORIGEN + (k - 0.5) * V
			local h = altura(x, z)
			local c, col = color(h, x, z)
			alto[i][k] = h
			clave[i][k] = h .. c
			colores[i][k] = col
		end
	end
	local usado = {}
	for i = 1, N do
		usado[i] = {}
	end
	for k = 1, N do
		for i = 1, N do
			if not usado[i][k] then
				local c = clave[i][k]
				local ancho = 1
				while i + ancho <= N and not usado[i + ancho][k] and clave[i + ancho][k] == c do
					ancho += 1
				end
				local largo = 1
				local sigue = true
				while sigue and k + largo <= N do
					for ii = i, i + ancho - 1 do
						if usado[ii][k + largo] or clave[ii][k + largo] ~= c then
							sigue = false
							break
						end
					end
					if sigue then
						largo += 1
					end
				end
				for ii = i, i + ancho - 1 do
					for kk = k, k + largo - 1 do
						usado[ii][kk] = true
					end
				end
				local h = alto[i][k]
				Mundo.parte({
					Name = "Suelo", Size = Vector3.new(ancho * V, h - BASE, largo * V),
					Position = Vector3.new(centro.X + ORIGEN + (i - 1 + ancho / 2) * V, (h + BASE) / 2, centro.Z + ORIGEN + (k - 1 + largo / 2) * V),
					Color = Mundo.matiz(colores[i][k]), Parent = carpeta,
				})
			end
		end
	end
end

return Terreno
