--!nonstrict
-- Ventanas del Refugio: la forja de Nefra, la armería, el viaje con Tariq y los diálogos.
-- Con el mando se navega con la cruceta, A elige y B cierra.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Compartido = ReplicatedStorage:WaitForChild("Compartido")
local Armas = require(Compartido.Armas)
local Remotos = require(Compartido.Remotos)
local DatosMisiones = require(Compartido.DatosMisiones)
local Escala = require(script.Parent.Escala)

local Refugio = {}
local jugador = Players.LocalPlayer
local perfil = nil
local gui: ScreenGui
local ventana: Frame
local recursos: TextLabel
local abierto = false
local tipoAbierto = ""
local pestana = "elegir"
local esStudio = false
local alCambiar

local ARENA = Color3.fromRGB(196, 160, 104)
local OSCURO = Color3.fromRGB(40, 28, 16)
local TEXTO = Color3.fromRGB(255, 244, 214)

local function crear(clase, props, padre)
	local x = Instance.new(clase)
	for k, v in props do
		x[k] = v
	end
	x.Parent = padre
	return x
end

local function texto(props, padre)
	local base = { BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextColor3 = TEXTO, TextStrokeTransparency = 0, TextStrokeColor3 = OSCURO, TextSize = 18, TextWrapped = true }
	for k, v in props do
		base[k] = v
	end
	return crear("TextLabel", base, padre)
end

local primerBoton
local function boton(t, color, alPulsar, padre, props)
	local b = crear("TextButton", {
		Text = t, Font = Enum.Font.Arcade, TextSize = 17, TextColor3 = OSCURO, BackgroundColor3 = color,
		BorderSizePixel = 0, AutoButtonColor = true, Size = UDim2.fromOffset(180, 38), TextWrapped = true,
	}, padre)
	crear("UIStroke", { Thickness = 2, Color = OSCURO, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	for k, v in props or {} do
		b[k] = v
	end
	b.Activated:Connect(alPulsar)
	primerBoton = primerBoton or b
	return b
end

local function receta(r)
	local partes = {}
	if r.monedas then
		table.insert(partes, r.monedas .. " monedas")
	end
	for _, k in Armas.ORDEN_MATERIALES do
		if r[k] then
			table.insert(partes, r[k] .. " " .. Armas.MATERIALES[k])
		end
	end
	return table.concat(partes, " · ")
end

local function puedePagar(r): boolean
	if not perfil then
		return false
	end
	for k, v in r do
		local tiene = k == "monedas" and perfil.monedas or perfil.materiales[k] or 0
		if tiene < v then
			return false
		end
	end
	return true
end

local function textoRecursos(): string
	if not perfil then
		return ""
	end
	local lineas = { ("Monedas: %d"):format(perfil.monedas) }
	for _, k in Armas.ORDEN_MATERIALES do
		table.insert(lineas, ("%s: %d"):format(Armas.MATERIALES[k], perfil.materiales[k] or 0))
	end
	return table.concat(lineas, "\n")
end

-- ---------- contenido de cada ventana ----------
local mostrarViaje
local DORADO_T = Color3.fromRGB(255, 214, 120)

local function limpiar()
	for _, x in ventana:GetChildren() do
		if not x:IsA("UIStroke") then
			x:Destroy()
		end
	end
	primerBoton = nil
end

local function titulo(t)
	texto({ Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 8), Text = t, TextSize = 28, TextColor3 = Color3.fromRGB(255, 214, 120) }, ventana)
end

local function lista()
	local l = crear("ScrollingFrame", {
		Size = UDim2.new(1, -30, 1, -150), Position = UDim2.fromOffset(15, 96), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, ventana)
	crear("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, l)
	return l
end

local function fila(padre, nombre, detalle, orden)
	local f = crear("Frame", { Size = UDim2.new(1, -10, 0, 78), BackgroundColor3 = Color3.fromRGB(150, 118, 72), BorderSizePixel = 0, LayoutOrder = orden }, padre)
	crear("UIStroke", { Thickness = 2, Color = OSCURO }, f)
	texto({ Size = UDim2.new(1, -210, 0, 26), Position = UDim2.fromOffset(10, 4), Text = nombre, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 230, 150) }, f)
	texto({ Size = UDim2.new(1, -210, 0, 44), Position = UDim2.fromOffset(10, 30), Text = detalle, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, f)
	return f
end

local function cerrarBoton()
	boton("Cerrar (B)", Color3.fromRGB(200, 120, 90), function()
		Refugio.cerrar()
	end, ventana, { Position = UDim2.new(1, -195, 1, -50) })
end

local function filaArma(l, id, i)
	local s = Armas.FORJABLES[id]
	local tiene = perfil and table.find(perfil.forjadas, id)
	local detalle = ("Daño %s · base: %s\n%s\n%s"):format(tostring(s.danio), Armas.DATOS[s.base].nombre, s.poder, tiene and "Ya forjada: elígela en la armería" or receta(s.receta))
	local f = fila(l, s.nombre, detalle, i)
	if not tiene then
		local puede = puedePagar(s.receta)
		boton(puede and "Forjar" or "Faltan materiales", puede and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(140, 130, 120), function()
			if puedePagar(s.receta) then
				Remotos.Forjar:FireServer("arma", id)
			end
		end, f, { Position = UDim2.new(1, -190, 0.5, -19) })
	end
end

local function filaPieza(l, id, i)
	local a = Armas.ARMADURA[id]
	local tiene = perfil and table.find(perfil.armadura, id)
	local puesta = perfil and table.find(perfil.equipo, id)
	local f = fila(l, a.nombre, a.efecto .. "\n" .. (tiene and (puesta and "Puesta" or "Guardada") or receta(a.receta)), i)
	if tiene then
		boton(puesta and "Quitarme" or "Ponerme", ARENA, function()
			Remotos.AlternarPieza:FireServer(id)
		end, f, { Position = UDim2.new(1, -190, 0.5, -19) })
	else
		local puede = puedePagar(a.receta)
		boton(puede and "Forjar" or "Faltan materiales", puede and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(140, 130, 120), function()
			if puedePagar(a.receta) then
				Remotos.Forjar:FireServer("pieza", id)
			end
		end, f, { Position = UDim2.new(1, -190, 0.5, -19) })
	end
end

-- familias que ya se pueden forjar (las de los Behemoths que aún no llegan no salen)
local function familias()
	local l = {}
	for _, f in Armas.FAMILIAS do
		if not f.proximamente then
			table.insert(l, f)
		end
	end
	return l
end

-- las armas iniciales y todas las forjadas, en orden
local function misArmas()
	local ids = table.clone(Armas.ORDEN)
	for _, f in Armas.FAMILIAS do
		for _, id in f.armas do
			if perfil and table.find(perfil.forjadas, id) then
				table.insert(ids, id)
			end
		end
	end
	return ids
end

local function mostrarForja()
	limpiar()
	titulo("FORJA DE NEFRA")
	local tabs = { { "elegir", "Mis armas" } }
	for _, f in familias() do
		table.insert(tabs, { "f_" .. f.id, f.nombre })
	end
	if not string.find(pestana, "^f_") and pestana ~= "elegir" then
		pestana = "elegir"
	end
	local porFila = 5
	for i, t in tabs do
		local fila2 = (i - 1) // porFila
		boton(t[2], pestana == t[1] and Color3.fromRGB(255, 214, 120) or ARENA, function()
			pestana = t[1]
			mostrarForja()
		end, ventana, { Position = UDim2.fromOffset(10 + ((i - 1) % porFila) * 120, 48 + fila2 * 36), Size = UDim2.fromOffset(116, 32), TextSize = 13 })
	end
	local filas = math.ceil(#tabs / porFila)
	local l = lista()
	l.Position = UDim2.fromOffset(15, 56 + filas * 36)
	l.Size = UDim2.new(1, -30, 1, -(110 + filas * 36))
	if pestana == "elegir" then
		-- las armas iniciales y las que hayas forjado: aquí eliges cuál llevas
		for i, id in misArmas() do
			local d = Armas.DATOS[id]
			local elegida = perfil and perfil.arma == id
			local extra = Armas.FORJABLES[id] and ("\n" .. Armas.FORJABLES[id].poder) or ""
			local f = fila(l, d.nombre, ("%s · daño %s"):format(d.rol, tostring(d.danio)) .. extra, i)
			boton(elegida and "✔ La llevas" or "Elegir", elegida and Color3.fromRGB(255, 214, 120) or ARENA, function()
				Remotos.ElegirArma:FireServer(id)
			end, f, { Position = UDim2.new(1, -190, 0.5, -19) })
		end
	else
		-- la familia de un Behemoth: sus seis armas, sus cuatro piezas y los bonos del set
		local fam
		for _, f in Armas.FAMILIAS do
			if "f_" .. f.id == pestana then
				fam = f
			end
		end
		if fam then
			local orden = 0
			local function separador(t)
				orden += 1
				texto({ Size = UDim2.new(1, -10, 0, 26), Text = t, TextSize = 18, TextColor3 = DORADO_T, LayoutOrder = orden }, l)
			end
			separador("ARMAS DE " .. string.upper(fam.nombre))
			for _, id in fam.armas do
				orden += 1
				filaArma(l, id, orden)
			end
			separador(string.upper(fam.nombreSet))
			for _, id in fam.piezas do
				orden += 1
				filaPieza(l, id, orden)
			end
			local n = 0
			for _, id in fam.piezas do
				if perfil and table.find(perfil.equipo, id) then
					n += 1
				end
			end
			fila(l, ("Bonos del set (%d/4 puestas)"):format(n), (n >= 2 and "✔ " or "· ") .. fam.bonos[1] .. "\n" .. (n >= 4 and "✔ " or "· ") .. fam.bonos[2], orden + 1)
			fila(l, "Una pieza por parte del cuerpo", "Al ponerte una pieza se quita la que ocupaba ese lugar: puedes mezclar piezas de distintos sets.", orden + 2)
		end
	end
	if esStudio then
		boton("Studio: materiales de prueba", Color3.fromRGB(127, 255, 244), function()
			Remotos.MaterialesPrueba:FireServer()
		end, ventana, { Position = UDim2.new(0, 15, 1, -50), Size = UDim2.fromOffset(260, 38) })
	end
	cerrarBoton()
end

local function mostrarArmeria()
	limpiar()
	titulo("ARMERÍA")
	texto({ Size = UDim2.new(1, -30, 0, 30), Position = UDim2.fromOffset(15, 56), Text = "Elige el arma que llevarás a la cacería. Las de cada Behemoth se forjan con Nefra.", TextSize = 14 }, ventana)
	local l = lista()
	local ids = misArmas()
	for i, id in ids do
		local d = Armas.DATOS[id]
		local elegida = perfil and perfil.arma == id
		local f = fila(l, d.nombre, ("%s · daño %s"):format(d.rol, tostring(d.danio)), i)
		boton(elegida and "✔ Elegida" or "Elegir", elegida and Color3.fromRGB(255, 214, 120) or ARENA, function()
			Remotos.ElegirArma:FireServer(id)
		end, f, { Position = UDim2.new(1, -190, 0.5, -19) })
	end
	cerrarBoton()
end

-- Tariq: dos pestañas. "Nueva cacería" (isla, Behemoth, público o privado con contraseña)
-- y "Unirse" (grupos esperando en el Refugio y cacerías en curso de todo el juego).
local islaElegida = 1
local grupos = {}
local cacerias = {}
local pestanaTariq = "nueva"
local esPrivado = false
local claveNueva = ""
local claveUnirse = ""
local COLOR_ELEMENTO = { Arena = Color3.fromRGB(230, 176, 74), Brasa = Color3.fromRGB(255, 122, 58), Sombra = Color3.fromRGB(160, 76, 224), Sol = Color3.fromRGB(255, 214, 90) }

local function miGrupo()
	for _, g in grupos do
		if table.find(g.ids, jugador.UserId) then
			return g
		end
	end
	return nil
end

-- recuadro para escribir la contraseña (máx. 12 letras o números)
local function campoClave(padre, pos, tam, valor, alCambiar)
	local caja = crear("TextBox", {
		Position = pos, Size = tam, BackgroundColor3 = Color3.fromRGB(250, 236, 200), BorderSizePixel = 0,
		Text = valor, PlaceholderText = "contraseña", Font = Enum.Font.Arcade, TextSize = 16, TextColor3 = OSCURO,
		PlaceholderColor3 = Color3.fromRGB(150, 130, 100), ClearTextOnFocus = false,
	}, padre)
	crear("UIStroke", { Thickness = 2, Color = OSCURO, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, caja)
	caja:GetPropertyChangedSignal("Text"):Connect(function()
		local limpio = string.sub(string.gsub(caja.Text, "%s", ""), 1, 12)
		if limpio ~= caja.Text then
			caja.Text = limpio
		end
		alCambiar(limpio)
	end)
	return caja
end

local function panelMiGrupo(mio)
	local panel = crear("Frame", { Size = UDim2.new(1, -30, 0, 150), Position = UDim2.fromOffset(15, 380), BackgroundColor3 = Color3.fromRGB(150, 118, 72), BorderSizePixel = 0 }, ventana)
	crear("UIStroke", { Thickness = 2, Color = DORADO_T }, panel)
	texto({ Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 6), Text = ("TU GRUPO %s · %s (%s) · %d/4"):format(mio.publico and "[PÚBLICO]" or "[PRIVADO]", mio.behemoth, mio.isla, #mio.nombres), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 230, 150), TextSize = 15 }, panel)
	local lineas = {}
	for k, nombre in mio.nombres do
		table.insert(lineas, (mio.ids[k] == mio.liderId and "* " or "- ") .. nombre .. (mio.ids[k] == mio.liderId and " (líder)" or ""))
	end
	texto({ Size = UDim2.fromOffset(300, 100), Position = UDim2.fromOffset(10, 34), Text = table.concat(lineas, "\n"), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextSize = 14 }, panel)
	if mio.liderId == jugador.UserId then
		boton("¡Salir de caza!", Color3.fromRGB(120, 220, 120), function()
			Refugio.cerrar()
			Remotos.Grupo:FireServer("partir")
		end, panel, { Position = UDim2.new(1, -200, 0, 40), Size = UDim2.fromOffset(186, 40) })
	else
		texto({ Size = UDim2.fromOffset(190, 40), Position = UDim2.new(1, -200, 0, 40), Text = "Esperando al líder...", TextSize = 13 }, panel)
	end
	boton("Salir del grupo", Color3.fromRGB(200, 120, 90), function()
		Remotos.Grupo:FireServer("salir")
	end, panel, { Position = UDim2.new(1, -200, 0, 94), Size = UDim2.fromOffset(186, 40) })
end

local function tariqNueva()
	-- islas a la izquierda (en una lista que se desplaza: ya son muchas)
	local columna = crear("ScrollingFrame", {
		Size = UDim2.fromOffset(206, miGrupo() and 248 or 392), Position = UDim2.fromOffset(12, 126), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, ventana)
	crear("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, columna)
	for i, isla in Armas.ISLAS do
		local disponible = #isla.behemoths > 0
		local b = boton((i == islaElegida and "> " or "") .. isla.nombre .. (disponible and "" or " (bloq.)"), i == islaElegida and Color3.fromRGB(255, 214, 120) or (disponible and ARENA or Color3.fromRGB(140, 130, 120)), function()
			if disponible then
				islaElegida = i
				mostrarViaje()
			end
		end, columna, { Size = UDim2.fromOffset(196, 34), TextSize = 13 })
		b.LayoutOrder = i
	end
	local mio = miGrupo()
	if mio then
		panelMiGrupo(mio)
	else
		-- público o privado (con contraseña)
		boton(esPrivado and "Grupo: PRIVADO" or "Grupo: PÚBLICO", esPrivado and Color3.fromRGB(230, 150, 110) or Color3.fromRGB(127, 220, 210), function()
			esPrivado = not esPrivado
			mostrarViaje()
		end, ventana, { Position = UDim2.fromOffset(225, 90), Size = UDim2.fromOffset(180, 30), TextSize = 13 })
		if esPrivado then
			campoClave(ventana, UDim2.fromOffset(415, 90), UDim2.fromOffset(190, 30), claveNueva, function(v)
				claveNueva = v
			end)
		end
	end
	-- Behemoths de la isla elegida
	local isla = Armas.ISLAS[islaElegida]
	for i, b in isla.behemoths do
		local f = crear("Frame", { Size = UDim2.fromOffset(380, 118), Position = UDim2.fromOffset(225, 126 + (i - 1) * 124), BackgroundColor3 = Color3.fromRGB(150, 118, 72), BorderSizePixel = 0 }, ventana)
		crear("UIStroke", { Thickness = 3, Color = COLOR_ELEMENTO[b.elemento] or OSCURO }, f)
		texto({ Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 6), Text = b.nombre .. " · " .. b.titulo, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 230, 150), TextSize = 17 }, f)
		local estrellas = string.rep("*", b.estrellas) .. string.rep("-", 5 - b.estrellas)
		texto({ Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, 32), Text = "Elemento " .. b.elemento .. " · dificultad " .. estrellas .. "\nPista: " .. (b.pista or ""), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12 }, f)
		if b.proximamente then
			texto({ Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 80), Text = "Próximamente", TextXAlignment = Enum.TextXAlignment.Left }, f)
		elseif not mio then
			local function clave()
				return esPrivado and claveNueva or nil
			end
			boton("Cazar solo", Color3.fromRGB(120, 220, 120), function()
				if esPrivado and claveNueva == "" then
					return
				end
				Refugio.cerrar()
				Remotos.Grupo:FireServer("solo", isla.id, b.id, clave())
			end, f, { Position = UDim2.fromOffset(10, 76), Size = UDim2.fromOffset(170, 34), TextSize = 14 })
			boton("Crear grupo", Color3.fromRGB(127, 220, 210), function()
				if esPrivado and claveNueva == "" then
					return
				end
				Remotos.Grupo:FireServer("crear", isla.id, b.id, clave())
			end, f, { Position = UDim2.fromOffset(196, 76), Size = UDim2.fromOffset(170, 34), TextSize = 14 })
		end
	end
	if esPrivado and claveNueva == "" and not mio then
		texto({ Size = UDim2.fromOffset(380, 20), Position = UDim2.fromOffset(225, 378), Text = "Escribe una contraseña para tu grupo privado.", TextSize = 12, TextColor3 = Color3.fromRGB(255, 200, 160) }, ventana)
	end
end

local function tariqUnirse()
	local mio = miGrupo()
	if mio then
		panelMiGrupo(mio)
		texto({ Size = UDim2.new(1, -30, 0, 40), Position = UDim2.fromOffset(15, 96), Text = "Ya estás en un grupo. Sal de él para unirte a otro.", TextSize = 14 }, ventana)
		return
	end
	texto({ Size = UDim2.fromOffset(330, 30), Position = UDim2.fromOffset(15, 92), Text = "Contraseña (solo para los privados):", TextSize = 13 }, ventana)
	campoClave(ventana, UDim2.fromOffset(345, 92), UDim2.fromOffset(200, 30), claveUnirse, function(v)
		claveUnirse = v
	end)
	local l = crear("ScrollingFrame", { Size = UDim2.new(1, -30, 1, -200), Position = UDim2.fromOffset(15, 132), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, ventana)
	crear("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, l)
	local orden = 0
	local function titulo2(t)
		orden += 1
		texto({ Size = UDim2.new(1, -10, 0, 22), Text = t, TextSize = 15, TextColor3 = Color3.fromRGB(255, 214, 120), LayoutOrder = orden }, l)
	end
	local function filaGrupo(etiqueta, detalle, lleno, alUnirse)
		orden += 1
		local f = crear("Frame", { Size = UDim2.new(1, -10, 0, 48), BackgroundColor3 = Color3.fromRGB(150, 118, 72), BorderSizePixel = 0, LayoutOrder = orden }, l)
		crear("UIStroke", { Thickness = 2, Color = OSCURO }, f)
		texto({ Size = UDim2.new(1, -150, 0, 22), Position = UDim2.fromOffset(8, 3), Text = etiqueta, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 230, 150) }, f)
		texto({ Size = UDim2.new(1, -150, 0, 20), Position = UDim2.fromOffset(8, 25), Text = detalle, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, f)
		if lleno then
			texto({ Size = UDim2.fromOffset(130, 40), Position = UDim2.new(1, -138, 0, 4), Text = "Lleno", TextSize = 14 }, f)
		else
			boton("Unirse", Color3.fromRGB(127, 220, 210), alUnirse, f, { Position = UDim2.new(1, -138, 0.5, -16), Size = UDim2.fromOffset(130, 32), TextSize = 14 })
		end
	end
	titulo2("GRUPOS ESPERANDO EN EL REFUGIO")
	if #grupos == 0 then
		orden += 1
		texto({ Size = UDim2.new(1, -10, 0, 20), Text = "Ninguno por ahora.", TextSize = 12, LayoutOrder = orden }, l)
	end
	for _, g in grupos do
		filaGrupo(("%s %s"):format(g.publico and "[PÚBLICO]" or "[PRIVADO]", g.lider), ("%s · %s · %d/4"):format(g.behemoth, g.isla, #g.nombres), #g.nombres >= 4, function()
			Remotos.Grupo:FireServer("unirse", g.id, claveUnirse)
		end)
	end
	titulo2("CACERÍAS EN CURSO")
	if #cacerias == 0 then
		orden += 1
		texto({ Size = UDim2.new(1, -10, 0, 20), Text = "Ninguna por ahora.", TextSize = 12, LayoutOrder = orden }, l)
	end
	for _, c in cacerias do
		filaGrupo(("%s %s"):format(c.publico and "[PÚBLICO]" or "[PRIVADO]", c.lider), ("%s · %s · %d/4 · cazando"):format(c.behemoth, c.isla, c.n), c.n >= 4, function()
			Refugio.cerrar()
			Remotos.Grupo:FireServer("unirseCaceria", c.id, claveUnirse)
		end)
	end
end

function mostrarViaje()
	limpiar()
	titulo("TARIQ · CARAVANAS DE CAZA")
	local arma = perfil and Armas.DATOS[perfil.arma]
	texto({ Size = UDim2.new(1, -30, 0, 18), Position = UDim2.fromOffset(15, 44), Text = "Llevas: " .. (arma and arma.nombre or "?"), TextSize = 12 }, ventana)
	for i, t in { { "nueva", "Nueva cacería" }, { "unirse", ("Unirse (%d)"):format(#grupos + #cacerias) } } do
		boton(t[2], pestanaTariq == t[1] and Color3.fromRGB(255, 214, 120) or ARENA, function()
			pestanaTariq = t[1]
			mostrarViaje()
		end, ventana, { Position = UDim2.fromOffset(15 + (i - 1) * 205, 60), Size = UDim2.fromOffset(200, 26), TextSize = 13 })
	end
	if pestanaTariq == "nueva" then
		tariqNueva()
	else
		tariqUnirse()
	end
	cerrarBoton()
end

-- Imani: la historia, capítulo por capítulo
local function mostrarHistoria()
	limpiar()
	titulo("IMANI · CAPITANA")
	local m = perfil and perfil.misiones or { historia = 1, encargos = {} }
	local total = #DatosMisiones.HISTORIA
	local actual = DatosMisiones.HISTORIA[m.historia]
	if actual then
		texto({ Size = UDim2.new(1, -40, 0, 26), Position = UDim2.fromOffset(20, 56), Text = ("Capítulo %d de %d: %s"):format(m.historia, total, actual.titulo), TextSize = 19, TextColor3 = Color3.fromRGB(255, 230, 150) }, ventana)
		texto({ Size = UDim2.new(1, -40, 0, 70), Position = UDim2.fromOffset(20, 88), Text = "\"" .. actual.texto .. "\"", TextSize = 15, TextYAlignment = Enum.TextYAlignment.Top }, ventana)
		texto({ Size = UDim2.new(1, -40, 0, 60), Position = UDim2.fromOffset(20, 164), Text = "Objetivo: " .. actual.objetivo .. "\nRecompensa: " .. DatosMisiones.textoPremio(actual.premio, Armas.MATERIALES), TextSize = 15, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(150, 255, 244) }, ventana)
	else
		texto({ Size = UDim2.new(1, -40, 0, 90), Position = UDim2.fromOffset(20, 60), Text = "¡Completaste toda la historia, cazador! Las islas del norte todavía guardan secretos... pronto habrá más.", TextSize = 17, TextYAlignment = Enum.TextYAlignment.Top }, ventana)
	end
	local hechos = {}
	for i = 1, math.min(m.historia - 1, total) do
		table.insert(hechos, "✔ " .. DatosMisiones.HISTORIA[i].titulo)
	end
	texto({ Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 240), Text = "CAPÍTULOS COMPLETADOS", TextSize = 15, TextColor3 = Color3.fromRGB(255, 214, 120) }, ventana)
	texto({ Size = UDim2.new(1, -40, 0, 200), Position = UDim2.fromOffset(20, 266), Text = #hechos > 0 and table.concat(hechos, "\n") or "Todavía ninguno.", TextSize = 14, TextYAlignment = Enum.TextYAlignment.Top }, ventana)
	cerrarBoton()
end

-- Sefu: encargos repetibles (hasta 2 activos)
local function mostrarEncargos()
	limpiar()
	titulo("SEFU · ENCARGOS")
	local m = perfil and perfil.misiones or { historia = 1, encargos = {} }
	local activos = m.encargos or {}
	texto({ Size = UDim2.new(1, -30, 0, 36), Position = UDim2.fromOffset(15, 50), Text = ("Acepta hasta %d encargos. Se cumplen solos al terminar una cacería. Activos: %d/%d"):format(DatosMisiones.MAX_ENCARGOS, #activos, DatosMisiones.MAX_ENCARGOS), TextSize = 13 }, ventana)
	local l = lista()
	for i, id in DatosMisiones.ORDEN_ENCARGOS do
		local e = DatosMisiones.ENCARGOS[id]
		local activo = table.find(activos, id) ~= nil
		local f = fila(l, (activo and "[ACTIVO] " or "") .. e.titulo, e.objetivo .. "\nRecompensa: " .. DatosMisiones.textoPremio(e.premio, Armas.MATERIALES), i)
		if activo then
			boton("Abandonar", Color3.fromRGB(200, 120, 90), function()
				Remotos.Mision:FireServer("abandonar", id)
			end, f, { Position = UDim2.new(1, -190, 0.5, -19) })
		elseif #activos < DatosMisiones.MAX_ENCARGOS then
			boton("Aceptar", Color3.fromRGB(120, 220, 120), function()
				Remotos.Mision:FireServer("aceptar", id)
			end, f, { Position = UDim2.new(1, -190, 0.5, -19) })
		end
	end
	cerrarBoton()
end

local function mostrarDialogo(t)
	limpiar()
	texto({ Size = UDim2.new(1, -40, 1, -80), Position = UDim2.fromOffset(20, 20), Text = t, TextSize = 19, TextYAlignment = Enum.TextYAlignment.Top }, ventana)
	cerrarBoton()
end

local function mostrar()
	if not abierto then
		return
	end
	if tipoAbierto == "forja" then
		mostrarForja()
	elseif tipoAbierto == "armeria" then
		mostrarArmeria()
	elseif tipoAbierto == "viaje" then
		mostrarViaje()
	elseif tipoAbierto == "historia" then
		mostrarHistoria()
	elseif tipoAbierto == "encargos" then
		mostrarEncargos()
	end
	if primerBoton then
		GuiService.SelectedObject = primerBoton
	end
end

-- ---------- abrir y cerrar ----------
function Refugio.abrir(tipo, dato)
	abierto = true
	tipoAbierto = tipo
	ventana.Visible = true
	if tipo == "forja" then
		esStudio = dato == true
		pestana = "elegir"
	end
	if tipo == "viaje" then
		Remotos.Grupo:FireServer("pedir")
	end
	if tipo == "dialogo" then
		mostrarDialogo(dato)
		GuiService.SelectedObject = primerBoton
	else
		mostrar()
	end
	if alCambiar then
		alCambiar(true)
	end
end

function Refugio.cerrar()
	if not abierto then
		return
	end
	abierto = false
	ventana.Visible = false
	GuiService.SelectedObject = nil
	if alCambiar then
		alCambiar(false)
	end
end

function Refugio.estaAbierto(): boolean
	return abierto
end

function Refugio.iniciar(callback)
	alCambiar = callback
	gui = crear("ScreenGui", { Name = "Refugio", ResetOnSpawn = false, IgnoreGuiInset = true }, jugador:WaitForChild("PlayerGui"))
	ventana = crear("Frame", { Size = UDim2.fromOffset(620, 580), Position = UDim2.new(0.5, -310, 0.5, -290), BackgroundColor3 = ARENA, BorderSizePixel = 0, Visible = false }, gui)
	crear("UIStroke", { Thickness = 4, Color = OSCURO }, ventana)
	Escala.ajustar(ventana, 620, 580)
	recursos = texto({ Size = UDim2.fromOffset(260, 150), Position = UDim2.fromOffset(20, 90), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextSize = 15, Visible = false }, gui)
	Remotos.Perfil.OnClientEvent:Connect(function(p)
		perfil = p
		recursos.Text = textoRecursos()
		mostrar()
	end)
	Remotos.AbrirMenu.OnClientEvent:Connect(Refugio.abrir)
	Remotos.Grupos.OnClientEvent:Connect(function(datos)
		grupos = datos.grupos or {}
		cacerias = datos.cacerias or {}
		-- no se redibuja mientras escribes una contraseña (perderías lo escrito)
		local escribiendo = game:GetService("UserInputService"):GetFocusedTextBox() ~= nil
		if abierto and tipoAbierto == "viaje" and not escribiendo then
			mostrar()
		end
	end)
	local function zona()
		recursos.Visible = jugador:GetAttribute("Zona") == "refugio"
	end
	jugador:GetAttributeChangedSignal("Zona"):Connect(zona)
	zona()
end

return Refugio
